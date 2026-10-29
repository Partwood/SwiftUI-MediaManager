//
//  CutPasteViewModel.swift
//  MediaManager
//
//  Copyright © 2026 JVSherwood. All rights reserved.
//

import SwiftUI
import Foundation
import Combine

//    cut buffer and paste operations for file moving
class CutPasteViewModel: ObservableObject {
   //let objectWillChange: ObservableObjectPublisher
   
    @Published var cutBuffer: [CutBufferItem] = []
    @Published var isCutMode = false
    @Published var isPasteInProgress = false
    @Published var pasteResults: [PasteResult] = []
    @Published var pasteSuccessCount = 0
    @Published var pasteFailedCount = 0
    @Published var pasteSkippedCount = 0
    @Published var pasteCancelled = false
    @Published var pasteComplete = false
    
    let fileSystem: FileSystem
    
    init(_ rootURL: URL?) {
        self.fileSystem = FileSystem(rootURL)
    }
    
    /// Cut the selected files into the cut buffer
    func cut(files: [FileItem]) {
       debug("Cut")
        cutBuffer.removeAll()
        pasteResults.removeAll()
        pasteSuccessCount = 0
        pasteFailedCount = 0
        pasteSkippedCount = 0
        pasteCancelled = false
        pasteComplete = false
        
        for file in files {
            cutBuffer.append(CutBufferItem(
                id: file.id,
                file: file,
                originalPath: file.url,
                isCancelled: false
            ))
        }
        
        isCutMode = true
        isPasteInProgress = false
        pasteResults = []
    }
    
    /// Cancel the current cut operation
    func cancelCut() {
        cutBuffer.removeAll()
        isCutMode = false
        pasteResults.removeAll()
        pasteSuccessCount = 0
        pasteFailedCount = 0
        pasteSkippedCount = 0
        pasteCancelled = false
        pasteComplete = false
    }
    
    /// Start a paste operation to the specified directory
    func startPaste(at destinationPath: String) {
        isPasteInProgress = true
        pasteResults = []
        pasteSuccessCount = 0
        pasteFailedCount = 0
        pasteSkippedCount = 0
        pasteCancelled = false
        pasteComplete = false
        
        Task {
            await performPaste(at: destinationPath)
        }
    }
    
    /// Cancel the paste operation
    func cancelPaste() {
        pasteCancelled = true
        pasteComplete = true
    }
    
    /// Perform the paste operation (async)
    private func performPaste(at destinationPath: String) async {
        guard !pasteCancelled else { return }
        
        let destinationURL = URL(fileURLWithPath: destinationPath)
        
        for item in cutBuffer {
            guard !item.isCancelled else { continue }
            guard !pasteCancelled else { break }
            
            let result = await pasteFile(item, to: destinationURL)
            pasteResults.append(result)
            
            switch result {
            case .success:
                pasteSuccessCount += 1
            case .skipped:
                pasteSkippedCount += 1
            case .failed:
                pasteFailedCount += 1
            case .conflictResolved:
                pasteSuccessCount += 1
            }
        }
        
        isPasteInProgress = false
        pasteComplete = true
    }
    
    /// Paste a single file to the destination
    private func pasteFile(_ item: CutBufferItem, to destinationURL: URL) async -> PasteResult {
        let fileName = item.file.name
        let destinationFileURL = destinationURL.appendingPathComponent(fileName)
        
        // Check if file already exists
        if destinationFileURL.isExisting() {
            // Conflict exists, show options
            let resolution = await requestConflictResolution(for: item, at: destinationFileURL)
            
            switch resolution {
            case .replace:
                // Overwrite existing file
                do {
                    try FileManager.default.moveItem(at: item.originalPath, to: destinationFileURL)
                    return .success
                } catch {
                    return .failed(error)
                }
                
            case .keepBoth:
                // Rename destination file
                let newFileName = generateUniqueFileName(fileName: fileName, in: destinationURL)
                let newDestinationURL = destinationURL.appendingPathComponent(newFileName)
                
                do {
                    try FileManager.default.moveItem(at: item.originalPath, to: newDestinationURL)
                    return .conflictResolved(newFileName)
                } catch {
                    return .failed(error)
                }
                
            case .skip:
                return .skipped
            }
        }
        
        // No conflict, just move the file
       var result: PasteResult = .skipped
        self.fileSystem.accessURL(item.originalPath) { url in
              if let _ = url {
                 do {
                    try FileManager.default.moveItem(at: item.originalPath, to: destinationFileURL)
                    result = .success
                 } catch {
                    logError(error)
                    result = .failed(error)
                 }
              }
           }
       return result
    }
    
    /// Request user to resolve a naming conflict
    @MainActor
    private func requestConflictResolution(for item: CutBufferItem, at destinationURL: URL) -> ConflictResolution {
        let alert = NSAlert()
        alert.messageText = "File Conflict"
        alert.informativeText = "A file named \"\(item.file.name)\" already exists in the destination. What would you like to do?"
        alert.alertStyle = .warning
        
        let replaceButton = alert.addButton(withTitle: "Replace")
        let keepBothButton = alert.addButton(withTitle: "Keep Both")
        let skipButton = alert.addButton(withTitle: "Skip")
        
        let response = alert.runModal()
        
        switch response {
        case .alertFirstButtonReturn:
            return .replace
        case .alertSecondButtonReturn:
            return .keepBoth
        case .alertThirdButtonReturn:
            return .skip
        default:
            return .skip
        }
    }
   
   /// Request user to resolve a naming conflict
//   @MainActor
//   private func requestConflictResolution(for item: CutBufferItem, at destinationURL: URL) -> ConflictResolution {
//      let alert = NSAlert()
//      alert.messageText = "File Conflict"
//      alert.informativeText = "A file named \"\(item.file.name)\" already exists in the destination. What would you like to do?"
//      alert.alertStyle = .warning
//      
//      // Generate the proposed new filename for "Keep Both" option
//      let proposedNewFileName = generateUniqueFileName(fileName: item.file.name, in: destinationURL)
//      
//      let replaceButton = alert.addButton(withTitle: "Replace")
//      let keepBothButton = alert.addButton(withTitle: "Keep Both")
//      let skipButton = alert.addButton(withTitle: "Skip")
//      
//      let response = alert.runModal()
//      
//      switch response {
//      case .alertFirstButtonReturn:
//         return .replace
//      case .alertSecondButtonReturn:
//         return .keepBoth
//      case .alertThirdButtonReturn:
//         return .skip
//      default:
//         return .skip
//      }
//   }

    /// Generate a unique filename by appending timestamp and counter
    private func generateUniqueFileName(fileName: String, in directoryURL: URL) -> String {
       //var baseName = fileName
       let fileURL = URL(fileURLWithPath: fileName)
       let extensionPart:String = fileURL.pathExtension
       var nameWithoutExt = fileName
       nameWithoutExt.removeLast(extensionPart.count)
       //let nameWithoutExt = (!extensionPart.isEmpty) ? baseName.removeLast(extensionPart.count) : baseName
        
        let timestamp = Date().timeIntervalSince1970
        let counter = 1
        
        let newFileName = "\(nameWithoutExt)_\(timestamp)_\(counter).\(extensionPart)"
       
       debug("extensionPart:\(extensionPart) newFileName:\(newFileName)")
        return newFileName
    }
//   /// Generate a unique filename by appending timestamp and counter
//   private func generateUniqueFileName(fileName: String, in directoryURL: URL) -> String {
//      let baseName = fileName
//      let extensionPart = URL(fileURLWithPath: fileName).pathExtension
//      let nameWithoutExt = baseName.hasExtension ? baseName.deletingPathExtension() : baseName
//      
//      let timestamp = Date().timeIntervalSince1970
//      let counter = 1
//      
//      let newFileName = "\(nameWithoutExt)_\(timestamp)_\(counter).\(extensionPart)"
//      return newFileName
//   }
   

   /// Manages the
   
   /// Handle conflict resolution choice from UI
   @MainActor
   func handleConflict(_ resolution: ConflictResolution) {
      // The conflict resolution is handled in the ViewModel's pasteFile method
      // This method is called from the UI when user clicks a button
      // We just need to ensure the UI state is updated
   }
   
   /// Handle conflict resolution choice from UI
   @MainActor
   func handleConflict(_ resolution: ConflictResolution, for item: CutBufferItem) {
      switch resolution {
      case .replace:
         // Replace will be handled when we retry the paste operation
         // Mark the item for replacement
         break
      case .keepBoth:
         // Keep both - we'll handle this by renaming
         break
      case .skip:
         // Skip this file - mark it as cancelled
         //item.isCancelled = true
         break
      }
   }
}

/// Item in the cut buffer
struct CutBufferItem: Identifiable {
    let id: UUID
    let file: FileItem
    let originalPath: URL
    var isCancelled: Bool
}

/// Result of a paste operation
enum PasteResult {
    case success
    case skipped
    case failed(Error)
    case conflictResolved(String)
}

/// User's choice for resolving a file naming conflict
enum ConflictResolution {
    case replace
    case keepBoth
    case skip
}
