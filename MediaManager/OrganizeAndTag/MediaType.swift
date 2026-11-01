//
//  MediaType.swift
//  MediaManager
//
//  Copyright © 2026 JVSherwood. All rights reserved.
//

import Foundation

/// Represents the type of media content being processed
enum MediaType: String, Codable, CaseIterable {
    case movie
    case tvShow
    
    var displayName: String {
        switch self {
        case .movie:
            return "Movie"
        case .tvShow:
            return "TV Show"
        }
    }
}