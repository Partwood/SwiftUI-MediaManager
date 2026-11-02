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
