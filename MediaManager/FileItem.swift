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
   let type: String
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
}
