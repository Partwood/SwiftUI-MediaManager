//
//  MergeStrategy.swift
//  MediaManager
//
//  Copyright © 2026 JVSherwood. All rights reserved.
//

import Foundation

/// Strategy for handling existing files during organization
enum MergeStrategy: String, CaseIterable {
    case replace = "Replace"
    case skip = "Skip"
    case rename = "Rename"
    case mergeMetadata = "Merge Metadata"
    
    var description: String {
        switch self {
        case .replace: return "Overwrite existing files"
        case .skip: return "Leave existing files unchanged"
        case .rename: return "Rename existing files to avoid conflicts"
        case .mergeMetadata: return "Combine existing NFO data with new data"
        }
    }
}

/// Results of an organization operation
struct OrganizationResults {
    var filesMoved: [FileItem] = []
    var nfoFilesCreated: [URL] = []
    var warnings: [String] = []
    var errors: [String] = []
    
    var success: Bool {
        return errors.isEmpty
    }
    
    var summary: String {
        let movedCount = filesMoved.count
        let nfoCount = nfoFilesCreated.count
        let warningCount = warnings.count
        let errorCount = errors.count
        
        return """
        Organization Complete
        
        Files moved: \(movedCount)
        NFO files created: \(nfoCount)
        Warnings: \(warningCount)
        Errors: \(errorCount)
        """
    }
}
