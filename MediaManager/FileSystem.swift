//
//  FileSystem.swift
//  MediaManager
//
//  Copyright © 2026 JVSherwood. All rights reserved.
//

import Foundation

struct File {
   let url: URL
   let attributes: FileAttributes?
   
   var name: String {
      get {
         url.lastPathComponent
      }
   }
   
   var isDirectory: Bool {
      get {
         return attributes?.fileType == .typeDirectory
      }
   }
}

struct FileAttributes {
   let fileType: FileAttributeType
   let creationDate: Date
   let modifiedDate: Date
   let permissions: Int
   let fileSize: Int64?

   static func fileAttributes(_ attributes:[FileAttributeKey : Any]) -> FileAttributes? {
      guard let fileType = attributes[FileAttributeKey.type] as? FileAttributeType else {
         return nil
      }
      
      if let creationDate = attributes[FileAttributeKey.creationDate] as? Date,
         let modifiedDate = attributes[FileAttributeKey.modificationDate] as? Date,
         let permissions = attributes[FileAttributeKey.posixPermissions] as? Int {
         
         if ( fileType == .typeRegular) {
            if let fileSize = attributes[FileAttributeKey.size] as? Int64 {
               return FileAttributes(fileType: fileType, creationDate: creationDate, modifiedDate: modifiedDate, permissions: permissions,fileSize: fileSize)
            } else {
               return nil
            }
         } else {
            return FileAttributes(fileType: fileType, creationDate: creationDate, modifiedDate: modifiedDate, permissions: permissions,fileSize: nil)
         }
      } else {
         return nil
      }
   }
}
      
final
class FileSystem {

}

// MARK: Create directory
extension FileSystem {
   func createDir(at path: String) throws {
      // Convert the tilde path (~/) to an absolute path
      let expandedPath = NSString(string: path).expandingTildeInPath
      
      do {
         // Create the directory if it doesn't exist
         let directoryURL = URL(fileURLWithPath: expandedPath)
         try FileManager.default.createDirectory(at: directoryURL,
                                                 withIntermediateDirectories: true)
         
         debug("Successfully created '\(directoryURL.path)'")
      } catch {
         logError(error)
         throw error
      }
   }
}

// MARK: List directory contents
extension FileSystem {
   enum FileContentType: String {
      case avi
      case binary
      case html
      case jpeg
      case markdown
      case mkv
      case mp3
      case mp4
      case png
      case text
      case wav
      case unknown
   }
   
   func identifyFileType(at url: URL) -> FileContentType {
      do {
         // Read the first 1024 bytes of the file to check for binary patterns or magic numbers
         let fileHandle = try FileHandle(forReadingFrom: url)
         defer { fileHandle.closeFile() }
         
         let data = fileHandle.readData(ofLength: min(1024, Int(fileHandle.seekToEndOfFile())))
         let byteArray = [UInt8](data)
         
         // Check for null bytes (indicative of binary files)
         if byteArray.contains(0x00) {
            return .binary
         }
         
         // Check for JPEG magic number: 0xFFD8FF
         if byteArray.count >= 3 && byteArray[0] == 0xFF && byteArray[1] == 0xD8 && byteArray[2] == 0xFF {
            return .jpeg
         }
         
         // Check for PNG magic number: 0x89504E47
         if byteArray.count >= 8 && byteArray[0] == 0x89 && byteArray[1] == 0x50 && byteArray[2] == 0x4E && byteArray[3] == 0x47 {
            return .png
         }
         
         // Check for MP3 ID3 tag
         if byteArray.count >= 3 && byteArray[0] == 0x49 && byteArray[1] == 0x44 && byteArray[2] == 0x33 {
            return .mp3
         }
         
         // Check for WAV file: RIFF header followed by "WAVE"
         if byteArray.count >= 12 && byteArray[0] == 0x52 && byteArray[1] == 0x49 && byteArray[2] == 0x46 && byteArray[3] == 0x46
               && byteArray[8] == 0x57 && byteArray[9] == 0x41 && byteArray[10] == 0x56 && byteArray[11] == 0x45 {
            return .wav
         }
         
         // Check for MP4 file: ftyp followed by mp41 or similar
         if byteArray.count >= 8 && byteArray[4] == 0x66 && byteArray[5] == 0x74 && byteArray[6] == 0x79 && byteArray[7] == 0x70 {
            return .mp4
         }
         
         // Check for AVI file: RIFF header followed by "AVI "
         if byteArray.count >= 8 && byteArray[0] == 0x52 && byteArray[1] == 0x49 && byteArray[2] == 0x46 && byteArray[3] == 0x46
               && byteArray[8] == 0x41 && byteArray[9] == 0x56 && byteArray[10] == 0x49 && byteArray[11] == 0x20 {
            return .avi
         }

         // Check for MKV file: EBML header (Matroska)
         if byteArray.count >= 5 && byteArray[0] == 0x46 && byteArray[1] == 0x2A && byteArray[2] == 0x41 && byteArray[3] == 0x55 && byteArray[4] == 0x20 {
            return .mkv
         }

         // Attempt to decode as UTF-8 text
         if let string = String(data: data, encoding: .utf8) {
            // Check for Markdown patterns (e.g., starts with # or ---)
            if string.hasPrefix("#") || string.hasPrefix("---") {
               return .markdown
            }
            // Check for HTML content
            if string.lowercased().hasPrefix("<html") || string.lowercased().hasPrefix("<!doctype html") {
               return .html
            }
            return .text
         }
      } catch {
         logError("Error reading file: \(error)")
      }
      
      return .unknown
   }
   
   private func getFileType(_ type: FileAttributeType) -> String {
      switch type {
      case .typeRegular:
         return "file"
      case .typeDirectory:
         return "directory"
      case .typeSymbolicLink:
         return "symbolic_link"
      default:
         return "\(type.rawValue)"
      }
   }
   
   private func getAttributes(fileManager: FileManager,decodedRoot: String,file: URL,simple: Bool) throws -> FileAttributes {
      let decodedPath: String = (file.path() as NSString).removingPercentEncoding ?? file.path()
      
      let attributes = try fileManager.attributesOfItem(atPath: decodedPath)
      
      guard let fileAttributes = FileAttributes.fileAttributes(attributes) else {
         let attributeError = FileIOError.attributes_not_found(file,nil)
         logError(attributeError)
         throw attributeError
      }
      
      return fileAttributes
   }
   
   func listDirectory(at inPath: String) throws -> Array<File> {
      let fileManager = FileManager.default
      
      let path = NSString(string: inPath).expandingTildeInPath
      let decodedRoot: String = path.removingPercentEncoding ?? path
      let pathURL = URL(fileURLWithPath: decodedRoot)
      
      var files = Array<File>()
      
      let directoryURL: URL
      
      if ( pathURL.isExisting() ) {
         do {
            if ( try pathURL.isExistingFile() ) {
               let fileAttributes = try getAttributes(fileManager: fileManager, decodedRoot: decodedRoot, file: pathURL,simple: true)
               
               files.append(File(url: pathURL, attributes: fileAttributes))
               
               return files
            }
         } catch {
            logError(error)
            throw error
         }
         
         // If we get here then it exists, but it is not a file (implies it is a directory)
         directoryURL = pathURL
      } else {
         let missing = FileIOError.directory_not_found(pathURL)
         logError(missing)
         throw missing
      }
      
      do {
         // Get contents (files and subfolders)
         let directoryContents = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
         
         files = directoryContents.compactMap { file in
            if ( file.lastPathComponent.hasPrefix(".") ) {
               // Ignore any file that starts with .
               return nil
            }
            
            do {
               let fileAttributes = try getAttributes(fileManager: fileManager, decodedRoot: decodedRoot, file: file, simple: true)
               
               return File(url: file, attributes: fileAttributes)
            } catch {
               logError(error)
               debug("Ignoring the prior error as it is on an individual file in a list of files.")
               return nil
            }
         }
      } catch {
         logError(error)
         throw error
      }
      
      return files
   }
   
   func info(at inPath: String,name: String) throws -> FileAttributes {
      let fileManager = FileManager.default
      
      let path = NSString(string: inPath).expandingTildeInPath
      let decodedRoot: String = path.removingPercentEncoding ?? path
      let pathURL = URL(fileURLWithPath: decodedRoot).appendingPathComponent(name)
      
      if ( !pathURL.isExisting() ) {
         let missing = FileIOError.directory_not_found(pathURL)
         logError(missing)
         throw missing
      }
      
      do {
         let value = try getAttributes(fileManager: fileManager, decodedRoot: decodedRoot, file: pathURL,simple: false)
         return value
      } catch {
         logError(error)
         throw error
      }
   }
}

// MARK: Find file or directory
extension FileSystem {
   private func matchesWildcard(_ filename: String, pattern: String) throws -> Bool {
      // Convert wildcard pattern to a regular expression
      let regexPattern = pattern
         .replacingOccurrences(of: ".", with: "\\.")
         .replacingOccurrences(of: "*", with: ".*")
      
      do {
         let regex = try NSRegularExpression(pattern: regexPattern)
         let range = NSRange(location: 0, length: filename.utf16.count)
         return regex.firstMatch(in: filename, options: [], range: range) != nil
      } catch {
         logError(error)
         
         let invalidPatternError = RegExError.invalid_pattern(pattern)
         
         logError(invalidPatternError)
         throw invalidPatternError
      }
   }
   
   func find(in rootPath: String,named pattern: String,directory: Bool) throws -> Array<File> {
      let expandedRootPath = NSString(string: rootPath).expandingTildeInPath
      let fileManager = FileManager.default
      var foundFiles = Array<File>()
      
      do {
         // Get the contents of the root directory
         let rootURL = URL(fileURLWithPath: expandedRootPath)
         let contents = try fileManager.contentsOfDirectory(at: rootURL, includingPropertiesForKeys: nil)
         
         for item in contents {
            let isDirectory = (try? item.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            
            if ( directory == isDirectory ) {
               let matches: Bool = try matchesWildcard(item.lastPathComponent,pattern: pattern)
               if ( matches ) {
                  // Found the file/directory directly in the root
                  foundFiles.append(File(url: item,attributes: nil))
               }
            }
            
            if isDirectory {
               // Recursively search in subdirectories
               let foundInSubdirs = try findChild(in: item.path, named: pattern,directory: directory)
               for foundItem in foundInSubdirs {
                  foundFiles.append(foundItem)
               }
            }
         }
      } catch {
         logError(error)
         throw error
      }
      
      return foundFiles
   }
   
   private func findChild(in directoryPath: String, named pattern: String,directory: Bool) throws -> Array<File> {
      let fileManager = FileManager.default
      var foundItems = Array<File>()
      
      do {
         let directoryURL = URL(fileURLWithPath: directoryPath)
         let contents = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
         
         for item in contents {
            let isDirectory = (try? item.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            
            if ( directory == isDirectory ) {
               let matches: Bool = try matchesWildcard(item.lastPathComponent,pattern: pattern)
               if ( matches ) {
                  foundItems.append(File(url: item,attributes: nil))
               }
            }
            
            if isDirectory {
               // Recursively search in subdirectories
               let foundInSubdirs = try findChild(in: item.path, named: pattern,directory: directory)
               for foundItem in foundInSubdirs {
                  foundItems.append(foundItem)
               }
            }
         }
      } catch {
         logError(error)
         throw error
      }
      
      return foundItems
   }
}
