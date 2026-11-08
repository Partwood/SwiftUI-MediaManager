//
//  Extra.swift
//  MediaManager
//
//  Copyright © 2026 JVSherwood. All rights reserved.
//

import Foundation

/// Represents an extra file (commentary, deleted scene, etc.)
struct Extra: Codable, Identifiable {
   var id: UUID { UUID() }
   //var id: String { title }
    
    var title: String
    var duration: TimeInterval
    var extraType: ExtraType
    var episodeNumber: Int?
    var episodeTitle: String?
    var relatedEpisodeId: String?
}
