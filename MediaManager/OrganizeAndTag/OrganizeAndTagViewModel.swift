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
      preview: Bool,
      mediaType: MediaType,
      showTitle: String,
      season: Int?,
      basePath: URL,
      mergeStrategy: MergeStrategy
   ) async throws -> OrganizationResults {
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
         let files = try getFiles(at: basePath)
         
         var results: OrganizationResults
         
         guard let organization_preview = organizationPreview else {
            throw OrganizeAndTagError.noPreview
         }
         if mediaType == .tvShow {
            results = FileOrganizer.organizeTVShow(
               preview: preview,
               files: files,
               content: createContent(from: organization_preview, showTitle: showTitle),
               basePath: basePath,
               mergeStrategy: mergeStrategy
            )
         } else {
            results = FileOrganizer.organizeMovie(
               preview: preview,
               files: files,
               content: createContent(from: organization_preview, showTitle: showTitle),
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
    
    /// Initialize with parsed content
//    func initialize(with content: String, mediaType: MediaType, startingEpisode: Int? = nil) {
//        let viewModel = ImportPanelViewModel()
//        viewModel.parse(content: content, mediaType: mediaType, startingEpisode: startingEpisode)
//        
//        DispatchQueue.main.async {
//            self.organizationPreview = viewModel.organizationPreview
//            self.parsingWarnings = viewModel.parsingWarnings
//        }
//    }
    
    /// Execute the organization operation
//    func executeOrganization(
//        mediaType: MediaType,
//        showTitle: String,
//        season: Int?,
//        basePath: URL,
//        mergeStrategy: MergeStrategy
//    ) async throws -> OrganizationResults {
//        processingState = .processing
//        
//        do {
//            // Get files from the base path
//            let files = try getFiles(at: basePath)
//            
//            var results: OrganizationResults
//            
//            if mediaType == .tvShow {
//                guard let preview = organizationPreview else {
//                    throw OrganizeAndTagError.noPreview
//                }
//                
//                results = FileOrganizer.organizeTVShow(
//                    files: files,
//                    content: createContent(from: preview, showTitle: showTitle),
//                    basePath: basePath,
//                    mergeStrategy: mergeStrategy
//                )
//            } else {
//                results = FileOrganizer.organizeMovie(
//                    files: files,
//                    content: createContent(from: organizationPreview ?? OrganizationPreview(), showTitle: showTitle),
//                    basePath: basePath,
//                    mergeStrategy: mergeStrategy
//                )
//            }
//            
//            organizationResults = results
//            processingState = .completed
//            
//            // Show any warnings
//            if !results.warnings.isEmpty {
//                DispatchQueue.main.async {
//                    self.errorMessages = results.warnings
//                }
//            }
//            
//            return results
//            
//        } catch {
//           logError(error)
//           
//            processingState = .error
//            errorMessages.append(error.localizedDescription)
//            
//            DispatchQueue.main.async {
//                self.organizationResults = OrganizationResults()
//            }
//            
//           throw error
//        }
//    }
    
   /// Get all files from a directory recursively
   private func getFiles(at url: URL) throws -> [FileItem] {
      var files: [FileItem] = []
      
      /*try*/ FileManager.default.enumerator(
         at: url,
         includingPropertiesForKeys: [.isRegularFileKey],
         options: [.skipsHiddenFiles]
      )?.forEach({ item in
         if let fileURL = item as? URL {
            let fileItem = FileItem(url: fileURL)
            files.append(fileItem)
         }
         //guard let fileItem = FileItem(url: item!.asURL) else { return }
         //files.append(fileItem)
      })
//        )?.enumerateDirectoryContents { item in
//            guard let fileItem = FileItem(url: item!.asURL) else { return }
//            files.append(fileItem)
//        }
      
      return files
   }

   /// Create DVDCompareContent from preview
   private func createContent(from preview: OrganizationPreview, showTitle: String) -> DVDCompareContent {
      var content = DVDCompareContent(type: preview.mediaType, title: showTitle)
      content.type = preview.mediaType
      content.title = showTitle
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
    case noPreview
    case invalidInput
    case fileOperationFailed
    
    var errorDescription: String? {
        switch self {
        case .noPreview:
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
