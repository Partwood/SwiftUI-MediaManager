//
//  Markov.swift
//  MediaManager
//
//  Created by Joshua V Sherwood on 10/25/26.
//

// https://www.matroska.org/technical/elements.html

import Foundation

struct MKVMetadata {
   let title: String?
   let writingApp: String?
   let durationInSeconds: Double
   //let version: Int
}

// MARK: - EBML IDs
enum EBMLID {
   // Hex markers for MKV elements
   static let ebmlHeader: [UInt8]         = [0x1A, 0x45, 0xDF, 0xA3]
   static let segment: [UInt8]            = [0x18, 0x53, 0x80, 0x67]
   static let info: [UInt8]               = [0x15, 0x49, 0xA9, 0x66]
   static let title: [UInt8]              = [0x7B, 0xA9]
   static let muxingApp: [UInt8]          = [0x4D, 0xBB]
   static let writingApp: [UInt8]         = [0x57, 0x41]
   static let timestampScale: [UInt8]     = [0x2A, 0xD7, 0xB1]
   static let duration: [UInt8]           = [0x44, 0x89]
}

// MARK: - MKV Parser Error
enum MKVParserError: Error {
   case fileOpenFailure
   case invalidMKVHeader
   case parsingError
}

// MARK: - Usage Execution Example
//do {
//   let mkvURL = URL(fileURLWithPath: "/path/to/your/video.mkv")
//   let parser = try DirectMKVParser(fileURL: mkvURL)
//   let content = try parser.parseContent()
//
//   print("--- Extracted MKV Metadata ---")
//   print("duration (mins):\(content.durationInSeconds/60)")
//} catch {
//   print("Failed to read MKV binary stream: \(error)")
//}

// MARK: - Core Parser
class DirectMKVParser {
   private let url: URL
   private let fileHandle: FileHandle
   
   init(fileURL: URL) throws {
      // Open a file handle to avoid loading the whole movie into memory
      guard let handle = try? FileHandle(forReadingFrom: fileURL) else {
         throw MKVParserError.fileOpenFailure
      }
      self.url = fileURL
      self.fileHandle = handle
   }
   
   deinit {
      try? fileHandle.close()
   }
   
   func getMatroskaVersion() -> Int? {
      // Read the first 2KB, which is more than enough for the EBML header
      guard let data = try? fileHandle.read(upToCount: 2048) else { return nil }
      
      let bytes = [UInt8](data)
      
      // 1. Verify it's a valid EBML/Matroska file by checking for the EBML Header ID (1A 45 DF A3)
      let ebmlHeaderID: [UInt8] = [0x1A, 0x45, 0xDF, 0xA3]
      guard let _ = bytes.firstRange(of: ebmlHeaderID)?.lowerBound else {
         print("Not a valid EBML/Matroska file.")
         return nil
      }
      
      // 2. Search for the DocTypeVersion ID (42 87)
      let docTypeVersionID: [UInt8] = [0x42, 0x87]
      guard let idIndex = bytes.firstRange(of: docTypeVersionID)?.lowerBound else {
         print("DocTypeVersion ID not found in the header prefix.")
         return nil
      }
      
      // 3. Parse the VINT size that follows the ID
      // In EBML, the size of the element follows the ID. For a version integer,
      // the size is almost always 1 byte (represented as 0x81 in VINT format).
      let sizeIndex = idIndex + docTypeVersionID.count
      guard sizeIndex < bytes.count else { return nil }
      
      let sizeByte = bytes[sizeIndex]
      // Clear the VINT marker bit (the highest bit) to get the actual data length
      let dataLength = Int(sizeByte & 0x7F)
      
      // 4. Read the version value
      let valueIndex = sizeIndex + 1
      guard valueIndex + dataLength <= bytes.count else { return nil }
      
      let versionBytes = bytes[valueIndex..<(valueIndex + dataLength)]
      
      // Convert the bytes to an integer
      var version = 0
      for byte in versionBytes {
         version = (version << 8) | Int(byte)
      }
      
      return version
   }
   
   func parseContent() -> MKVMetadata? {
      guard let stream = InputStream(url: self.url) else { return nil }
      stream.open()
      defer { stream.close() }
      
      let bufferSize = 4096
      var buffer = [UInt8](repeating: 0, count: bufferSize)
      var fileData = Data()
      
      // Read chunks of the file into a working Data buffer
      while stream.hasBytesAvailable {
         let numberOfBytesRead = stream.read(&buffer, maxLength: bufferSize)
         if numberOfBytesRead < 0 { return nil }
         if numberOfBytesRead == 0 { break }
         
         fileData.append(buffer, count: numberOfBytesRead)
         
         // Optimization: Segment info is usually at the very beginning of the file.
         
         let title: String? = extractTitle(from: fileData)
         let writingApp: String? = extractWritingApp(from: fileData)
         let duration = extractDuration(from: fileData)
         
         if let duration {
            // If we find the Duration ID, we can stop reading early.
            return MKVMetadata(
               title: title,
               writingApp: writingApp,
               durationInSeconds: duration
            )
         }
         
         // Keep memory low by managing the buffer size
         if fileData.count > 1024 * 1024 { // Cap at 1MB of lookahead
            break
         }
      }
      
      return nil
   }
   
   private func extractTitle(from data: Data) -> String? {
      // 1. Find Segment Info Container
      guard let infoRange = data.range(of: Data(EBMLID.info)) else { return nil }
      let searchArea = data.subdata(in: infoRange.upperBound..<data.count)
      
      guard let titleRange = searchArea.range(of: Data(EBMLID.title)) else {
         return nil
      }
      
      let start = titleRange.upperBound
      let vint = parseVINT(from: searchArea, at: start)
      let valueStart = start + vint.bytesRead
      let valueData = searchArea.subdata(in: valueStart..<(valueStart + vint.valueSize))
      
      return String(data:valueData,encoding: .utf8)
   }

   private func extractWritingApp(from data: Data) -> String? {
      // 1. Find Segment Info Container
      guard let infoRange = data.range(of: Data(EBMLID.info)) else { return nil }
      let searchArea = data.subdata(in: infoRange.upperBound..<data.count)
      
      guard let range = searchArea.range(of: Data(EBMLID.writingApp)) else {
         return nil
      }
      
      let start = range.upperBound
      let vint = parseVINT(from: searchArea, at: start)
      let valueStart = start + vint.bytesRead
      let valueData = searchArea.subdata(in: valueStart..<(valueStart + vint.valueSize))
      
      return String(data:valueData,encoding: .utf8)
   }

   private func extractDuration(from data: Data) -> Double? {
      // 1. Find Segment Info Container
      guard let infoRange = data.range(of: Data(EBMLID.info)) else { return nil }
      let searchArea = data.subdata(in: infoRange.upperBound..<data.count)
      
      // 2. Extract TimestampScale (Defaults to 1,000,000 ns if not explicitly defined)
      var timestampScale: UInt64 = 1_000_000
      if let tsRange = searchArea.range(of: Data(EBMLID.timestampScale)) {
         let start = tsRange.upperBound
         // Parse EBML Variable Size Integer (VINT) to get length
         let vint = parseVINT(from: searchArea, at: start)
         let valueStart = start + vint.bytesRead
         let valueData = searchArea.subdata(in: valueStart..<(valueStart + vint.valueSize))
         
         timestampScale = valueData.reduce(0) { ($0 << 8) | UInt64($1) }
      }
      
      // 3. Extract Duration
      guard let durationRange = searchArea.range(of: Data(EBMLID.duration)) else { return nil }
      let start = durationRange.upperBound
      let vint = parseVINT(from: searchArea, at: start)
      let valueStart = start + vint.bytesRead
      let valueData = searchArea.subdata(in: valueStart..<(valueStart + vint.valueSize))
      
      // MKV Floats are either 4 bytes (Float) or 8 bytes (Double)
      var durationRaw: Double = 0.0
      if vint.valueSize == 4 {
         let rawBits = valueData.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
         durationRaw = Double(Float(bitPattern: rawBits))
      } else if vint.valueSize == 8 {
         let rawBits = valueData.withUnsafeBytes { $0.load(as: UInt64.self).bigEndian }
         durationRaw = Double(bitPattern: rawBits)
      } else {
         return nil
      }
      
      // Final calculation: (Duration * TimestampScale) / 1,000,000,000 to get seconds
      return (durationRaw * Double(timestampScale)) / 1_000_000_000.0
   }
   
   // Helper to decode EBML Variable Length Integers (VINT)
   private func parseVINT(from data: Data, at index: Int) -> (valueSize: Int, bytesRead: Int) {
      let firstByte = data[index]
      var mask: UInt8 = 0x80
      var length = 1
      
      while (firstByte & mask) == 0 && mask > 0 {
         length += 1
         mask >>= 1
      }
      
      // Strip the VINT marker bit from the size calculation if reading the value,
      // but here we just need to know how many bytes the payload is.
      var size: Int = Int(firstByte & ~mask)
      for i in 1..<length {
         size = (size << 8) | Int(data[index + i])
      }
      
      return (valueSize: size, bytesRead: length)
   }
}
