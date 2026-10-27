//
//  extURL.swift
//  MediaManager
//
//  Created by Joshua V Sherwood on 10/17/26.
//

import Cocoa

extension URL {
   /// Returns true if this URL is contained within the other URL
   func isContained(in parentURL: URL) -> Bool {
      // Standardize both URLs by resolving symlinks and getting absolute paths
      let standardizedSelf = self.resolvingSymlinksInPath().standardizedFileURL
      let standardizedParent = parentURL.resolvingSymlinksInPath().standardizedFileURL
      
      // Check if the path starts with the parent's path
      return standardizedSelf.path.starts(with: standardizedParent.path)
   }
   
   /// Given the current url and a sourceURL that is expected to be a child, return a copy of the
   func append(from sourceURL: URL) -> URL? {
      // Standardize both URLs by resolving symlinks and getting absolute paths
      let standardizedSelf = self.resolvingSymlinksInPath().standardizedFileURL
      let standardizedSource = sourceURL.resolvingSymlinksInPath().standardizedFileURL
      
      // Check if the path starts with the parent's path
      if ( !standardizedSource.path.starts(with: standardizedSelf.path) ) {
         // Not contained
         return nil
      }
      
      let selfPath = self.pathComponents
      let sourcePath = sourceURL.pathComponents
      
      var result: URL = self
      
      for pathComponent in sourcePath.enumerated() {
         if ( pathComponent.offset < selfPath.count ) {
            continue
         } else {
            // Must have accessed url securely
            result.append(path: pathComponent.element)
         }
      }
      
      return result
   }
   
   public
   static func getFilePath(_ inPath: String) -> String {
      let path = NSString(string: inPath).expandingTildeInPath
      return path.removingPercentEncoding ?? path
   }
   
   public
   var filePath: String {
      return URL.getFilePath(self.path(percentEncoded: false))
   }
   
   public
   func isExisting() -> Bool {
      return FileManager.default.fileExists(atPath: self.filePath)
   }
   
   public
   func isExistingFile() throws -> Bool {
      let urlExists = FileManager.default.fileExists(atPath: self.filePath)
      if ( !urlExists ) { return false }
      
      return try !isDirectory()
   }
   
   public
   func isExistingDirectory() throws -> Bool {
      let urlExists = FileManager.default.fileExists(atPath: self.filePath)
      if ( !urlExists ) { return false }
      
      return try isDirectory()
   }
   
   private func isDirectory() throws -> Bool {
      do {
         let resourceValues = try self.resourceValues(forKeys: [.isDirectoryKey])
         if resourceValues.isDirectory == true {
            return true
         } else {
            return false
         }
      } catch {
         if error.localizedDescription.contains("there is no such file") {
            throw URLError.does_not_exist(self)
         } else {
            logError(error)
            return false
         }
      }
   }
}
