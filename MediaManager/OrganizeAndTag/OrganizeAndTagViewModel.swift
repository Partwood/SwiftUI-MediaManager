//
//  OrganizeAndTagViewModel.swift
//  MediaManager
//
//  Copyright © 2026 JVSherwood. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

/// ViewModel for coordinating the organize and tag operations
class OrganizeAndTagViewModel: ObservableObject {
    
    @Published var organizationPreview: OrganizationPreview?
    @Published var organizationResults: OrganizationResults?
    @Published var parsingWarnings: [String] = []
    @Published var processingState: ProcessingState = .idle
    @Published var errorMessages: [String] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    /// Initialize with parsed content
    func initialize(with content: String, mediaType: MediaType, startingEpisode: Int? = nil) {
        let viewModel = ImportPanelViewModel()
        viewModel.parse(content: content, mediaType: mediaType, startingEpisode: startingEpisode)
        
        DispatchQueue.main.async {
            self.organizationPreview = viewModel.organizationPreview
            self.parsingWarnings = viewModel.parsingWarnings
        }
    }
    
    /// Execute the organization operation
    func executeOrganization(
        mediaType: MediaType,
        showTitle: String,
        season: Int?,
        basePath: URL,
        mergeStrategy: MergeStrategy
    ) async throws -> OrganizationResults {
        processingState = .processing
        
        do {
            // Get files from the base path
            let files = try getFiles(at: basePath)
            
            var results: OrganizationResults
            
            if mediaType == .tvShow {
                guard let preview = organizationPreview else {
                    throw OrganizeAndTagError.noPreview
                }
                
                results = FileOrganizer.organizeTVShow(
                    files: files,
                    content: createContent(from: preview, showTitle: showTitle),
                    basePath: basePath,
                    mergeStrategy: mergeStrategy
                )
            } else {
                results = FileOrganizer.organizeMovie(
                    files: files,
                    content: createContent(from: organizationPreview ?? OrganizationPreview(), showTitle: showTitle),
                    basePath: basePath,
                    mergeStrategy: mergeStrategy
                )
            }
            
            organizationResults = results
            processingState = .completed
            
            // Show any warnings
            if !results.warnings.isEmpty {
                DispatchQueue.main.async {
                    self.errorMessages = results.warnings
                }
            }
            
            return results
            
        } catch {
           logError(error)
           
            processingState = .error
            errorMessages.append(error.localizedDescription)
            
            DispatchQueue.main.async {
                self.organizationResults = OrganizationResults()
            }
            
           throw error
        }
    }
    
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
}
