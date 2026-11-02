//
//  Episode.swift
//  MediaManager
//
//  Copyright © 2026 JVSherwood. All rights reserved.
//

import Foundation

/// Represents a single episode of a TV show
struct Episode: Codable, Identifiable {
    var id: String { title }
    
    var title: String
    var duration: TimeInterval
    var episodeNumber: Int
    var alternativeCut: Bool?
    var isDeletedScene: Bool?
    var plot: String?
    var cast: [String]?
    var rating: String?
}
