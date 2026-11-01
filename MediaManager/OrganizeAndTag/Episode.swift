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

/// Represents an extra file (commentary, deleted scene, etc.)
struct Extra: Codable, Identifiable {
    var id: String { title }
    
    var title: String
    var duration: TimeInterval
    var extraType: ExtraType
    var episodeNumber: Int?
    var episodeTitle: String?
    var relatedEpisodeId: String?
}

/// Represents the content parsed from dvdcompare.net
struct DVDCompareContent: Codable, Identifiable {
    var id: UUID { UUID() }
    
    var type: MediaType
    var title: String
    var season: Int?
    var year: Int?
    var plot: String?
    
    // For TV Shows
    var episodes: [Episode] = []
    var commentaries: [Extra] = []
    var deletedScenes: [Extra] = []
    var musicVideos: [Extra] = []
    var trailers: [Extra] = []
    
    // For Movies
    var mainMovieDuration: TimeInterval?
    var extras: [Extra] = []
    
    // Metadata
    var director: String?
    var writers: [String] = []
    var cast: [String] = []
    var genre: [String] = []
    var rating: String?
    
    var parsingWarnings: [String] = []
}