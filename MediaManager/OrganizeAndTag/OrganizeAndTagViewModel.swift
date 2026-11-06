//
//  OrganizeAndTagViewModel.swift
// MdiaManager
//
//  Copyright © 2026 JVSherwood. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

/// ViewModel for coordinating the organize and tag operations
class OrganizeAndTagViewModel: ObservableObject {
    
   @Published var organizationPreview: OrganizationPreview?
   
   /// Progress tracking for operations
   @Published var progress: Int = 0
   @Published var operationStatus: String = ""
   @Published var isProcessing: Bool = false
   @Published var retryCount: [String: Int] = [:]
   
   private var retryQueue: [(error: Error, operation: String)] = []
   
   @Published var organizationResults: OrganizationResults?
   @Published var parsingWarnings: [String] = []
   @Published var processingState: ProcessingState = .idle
   @Published var errorMessages: [String] = []
   
   private var cancellables = Set<AnyCancellable>()

   /// Retry mechanism for failed operations
   /// Validate input before processing
   /// Initialize with parsed content
   func initialize(with content: String, mediaType: MediaType, startingEpisode: Int? = nil) {
      // Validate input first
      guard validateInput(content: content, mediaType: mediaType) else {
         processingState = .error
         errorMessages.append("Invalid input provided")
         return
      }
      
      let viewModel = ImportPanelViewModel()
      viewModel.parse(content: content, mediaType: mediaType, startingEpisode: startingEpisode)
      
      DispatchQueue.main.async {
         self.organizationPreview = viewModel.organizationPreview
         self.parsingWarnings = viewModel.parsingWarnings
      }
   }
   
   /// Execute the organization operation with progress tracking
   func executeOrganization(
      fileSystem: FileSystem,
      preview: Bool,
      basePath: URL,
      mergeStrategy: MergeStrategy
   ) throws -> OrganizationResults {
      processingState = .processing
      progress = 0
      operationStatus = "Starting organization..."
      isProcessing = true
      retryCount = [:]
      
      do {
         // Check disk space
         let diskSpaceWarning = checkDiskSpace(at: basePath, required: 1_000_000_000) // 1GB minimum
         if let warning = diskSpaceWarning {
            DispatchQueue.main.async {
               self.operationStatus = warning
            }
         }
         
         // Get files from the base path
         let files = try getFiles(fileSystem: fileSystem,at: basePath)
         
         var results: OrganizationResults
         
         guard let organization_preview = organizationPreview else {
            throw OrganizeAndTagError.missingPreview
         }
         
         if organization_preview.mediaType == .tvShow {
            results = FileOrganizer.organizeTVShow(
               preview: preview,
               files: files,
               content: createContent(from: organization_preview),
               basePath: basePath,
               mergeStrategy: mergeStrategy
            )
         } else {
            results = FileOrganizer.organizeMovie(
               preview: preview,
               files: files,
               content: createContent(from: organization_preview),
               basePath: basePath,
               mergeStrategy: mergeStrategy
            )
         }
         
         // Update progress
         let totalOperations = results.filesMoved.count + results.nfoFilesCreated.count
         progress = totalOperations > 0 ? 100 : 0
         
         organizationResults = results
         processingState = .completed
         isProcessing = false
         
         // Show any warnings
         if !results.warnings.isEmpty {
            DispatchQueue.main.async {
               self.errorMessages = results.warnings
            }
         }
         
         // Show success summary
         DispatchQueue.main.async {
            self.operationStatus = "Organization complete! \(results.filesMoved.count) files moved, \(results.nfoFilesCreated.count) NFO files created."
         }
         
         return results
         
      } catch {
         logError(error)
         
         // Handle retryable errors
         if let retryableError = error as? OrganizeAndTagError, retryableError.isRetryable {
            self.retryQueue.append((error, "organization"))
            processingState = .error
            isProcessing = false
            
            DispatchQueue.main.async {
               self.operationStatus = "Operation failed. Retry available."
            }
            
            throw throwRetryableError(error)
         }
         
         processingState = .error
         isProcessing = false
         progress = 0
         
         errorMessages.append("Organization failed: \(error.localizedDescription)")
         
         DispatchQueue.main.async {
            self.organizationResults = OrganizationResults()
         }
         
         throw error
      }
   }
    
   /// Check available disk space
   private func checkDiskSpace(at url: URL, required: UInt64) -> String? {
      do {
         let resourceValues = try url.resourceValues(forKeys: [.volumeAvailableCapacityKey])
         if let available = resourceValues.volumeAvailableCapacity {
            if available < required {
               let availableMB = Double(available) / (1024 * 1024)
               return "Insufficient disk space. Available: \(String(format: "%.1f", availableMB)) MB, Required: \(required / (1024 * 1024)) MB"
            }
         }
      } catch {
         logError(error)
      }
      return nil
   }
    
   /// Throw retryable errors
   private func throwRetryableError(_ error: Error) -> Error {
      guard let queueItem = retryQueue.first else { return error }
      
      let (error, operation) = queueItem
      retryCount[operation] = (retryCount[operation] ?? 0) + 1
      
      DispatchQueue.main.async {
         self.operationStatus = "Retry \(self.retryCount[operation] ?? 1) for \(operation)"
      }
      
      // Clear queue after attempt
      retryQueue.removeFirst()
      
      return error
   }

   private func validateInput(content: String, mediaType: MediaType) -> Bool {
      guard !content.isEmpty else {
         parsingWarnings.append("Content cannot be empty")
         return false
      }
      
      // Check for basic structure
      let hasEpisodes = mediaType == .tvShow ? content.contains("Episode") || content.contains("episodes") : false
      let hasExtras = content.contains("Extras") || content.contains("extras")
      
      if mediaType == .tvShow && !hasEpisodes {
         parsingWarnings.append("No episodes found in content for TV show")
      }
      if mediaType == .movie && !hasExtras {
         parsingWarnings.append("No extras found in content for movie")
      }
      
      return true
   }
    
   /// Get all files from a directory recursively
   private func getFiles(fileSystem: FileSystem,at url: URL) throws -> [FileItem] {
      var files: [FileItem] = []
      
      if let enumerator = FileManager.default.enumerator(
         at: url,
         includingPropertiesForKeys: [.isRegularFileKey],
         options: [.skipsHiddenFiles]
      ) {
         enumerator.forEach({ item in
            guard let fileURL = item as? URL else {
               return
            }
            
            let durationInSeconds: Double? = getDurationInSeconds(fileURL)
            
            let fileType: String
            let isDirectory: Bool
            do {
               let type = try fileSystem.info(fileURL).fileType
               isDirectory = (type == .typeDirectory)
               fileType = type.rawValue
            } catch {
               logError(error)
               fileType = ""
               isDirectory = false
            }
            
            let fileItem = FileItem(
               url: fileURL,
               name: fileURL.lastPathComponent,
               isDirectory: isDirectory,
               path: fileURL.filePath,
               size: 0,
               type: fileType,
               creationDate: nil,
               modifiedDate: nil,
               contentType: fileSystem.identifyFileType(at: fileURL),
               durationInSeconds: durationInSeconds
            )
            
            files.append(fileItem)
         })
      } else {
         logWarn("No enumerator")
      }
      
      return files
   }
   
   private func getDurationInSeconds(_ url: URL) -> Double? {
      let durationInSeconds: Double?
      
      if DirectMKVParser.isMKV(url) {
         do {
            let mkvParser = try DirectMKVParser(fileURL: url)
            if let metadata = mkvParser.parseContent() {
               durationInSeconds = metadata.durationInSeconds
            } else {
               durationInSeconds = nil
            }
         } catch {
            logError(error)
            durationInSeconds = nil
         }
      } else {
         durationInSeconds = nil
      }
      
      return durationInSeconds
   }

   /// Create DVDCompareContent from preview
   private func createContent(from preview: OrganizationPreview) -> DVDCompareContent {
      var content = DVDCompareContent(type: preview.mediaType, title: preview.title)
      content.type = preview.mediaType
      content.title = preview.title
      content.season = preview.season
      
      content.episodes = preview.episodes
      content.commentaries = preview.commentaries
      content.deletedScenes = preview.deletedScenes
      content.musicVideos = preview.musicVideos
      content.trailers = preview.trailers
      content.extras = preview.extras
      
      if preview.mediaType == .movie {
         content.mainMovieDuration = preview.mainMovieDuration
      }
      
      content.director = preview.director
      content.year = preview.year
      
      return content
   }
}

/// Processing state for UI updates
enum ProcessingState {
    case idle
    case processing
    case completed
    case error
}

/// Errors for the organize and tag feature
enum OrganizeAndTagError: LocalizedError {
    case missingPreview
    case invalidInput
    case fileOperationFailed
    
    var errorDescription: String? {
        switch self {
        case .missingPreview:
            return "No preview data available"
        case .invalidInput:
            return "Invalid input provided"
        case .fileOperationFailed:
            return "Failed to perform file operation"
        }
    }
   
   var isRetryable: Bool {
      get {
         return false
      }
   }
}
