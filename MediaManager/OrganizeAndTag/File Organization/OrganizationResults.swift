//
//  OrganizationResults.swift
//  MediaManager
//
//  Copyright © 2026 JVSherwood. All rights reserved.
//

import Foundation

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
