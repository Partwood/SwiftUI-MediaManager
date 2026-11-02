//
//  DVDCompareContent.swift
//  MediaManager
//
//  Copyright © 2026 JVSherwood. All rights reserved.
//

import Foundation

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
