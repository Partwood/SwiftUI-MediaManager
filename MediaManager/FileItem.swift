//
//  FileItem.swift
//  MediaManager
//
//  Created by Joshua V Sherwood on 10/26/26.
//

import Foundation

struct FileItem: Identifiable {
   let id = UUID()
   let url: URL
   let name: String
   let isDirectory: Bool
   let path: String
   let size: Int64
   let type: String // Directory, File, Symbolic Link
   let creationDate: Date?
   let modifiedDate: Date?
   let contentType: FileSystem.FileContentType
   let durationInSeconds: Double?
   
   // Helper to format the byte count into readable sizes (KB, MB, etc.)
   var formattedSize: String {
      if isDirectory { return "--" }
      return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
   }
   
   var formattedDuration: String {
      if let durationInSeconds {
         let hours = Int(durationInSeconds) / 3600
         let minutes = (Int(durationInSeconds) % 3600) / 60
         let secs = Int(durationInSeconds) % 60
         
         if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
         } else {
            return String(format: "%02d:%02d", minutes, secs)
         }
      } else {
         return "--"
      }
   }
   
   var formattedContentType: String {
      if type == "Folder" {
         return type
      } else {
         return contentType.description
      }
   }
   
   init(url: URL, name: String, isDirectory: Bool, path: String, size: Int64, type: String, creationDate: Date?, modifiedDate: Date?, contentType: FileSystem.FileContentType, durationInSeconds: Double?) {
      self.url = url
      self.name = name
      self.isDirectory = isDirectory
      self.path = path
      self.size = size
      self.type = type
      self.creationDate = creationDate
      self.modifiedDate = modifiedDate
      self.contentType = contentType
      self.durationInSeconds = durationInSeconds
   }

   init(url: URL) {
      self.url = url
      self.name = url.lastPathComponent
      self.isDirectory = false
      self.path = ""
      self.size = 0
      self.type = ""
      self.creationDate = nil
      self.modifiedDate = nil
      self.contentType = .unknown
      self.durationInSeconds = 0
   }
}
