//
//  ExtraType.swift
//  MediaManager
//
//  Copyright © 2026 JVSherwood. All rights reserved.
//

import Foundation

/// Represents the type of extra content (commentary, deleted scene, etc.)
enum ExtraType: String, Codable, CaseIterable {
    case commentary = "Commentary"
    case deletedScene = "Deleted Scene"
    case musicVideo = "Music Video"
    case trailer = "Trailer"
    case featurette = "Featurette"
    case behindTheScenes = "Behind the Scenes"
    case makingOf = "Making Of"
    case interview = "Interview"
    case documentary = "Documentary"
    case other = "Other"
    
    var displayName: String {
        return rawTitle.capitalized
    }
    
    private var rawTitle: String {
        switch self {
        case .commentary: return "commentary"
        case .deletedScene: return "deleted scene"
        case .musicVideo: return "music video"
        case .trailer: return "trailer"
        case .featurette: return "featurette"
        case .behindTheScenes: return "behind the scenes"
        case .makingOf: return "making of"
        case .interview: return "interview"
        case .documentary: return "documentary"
        case .other: return "other"
        }
    }
    
    /// Subdirectory name for this extra type
    var subdirectory: String {
        switch self {
        case .musicVideo:
            return "Music Videos"
        case .trailer:
            return "Trailers"
        case .deletedScene:
            return "Deleted Scenes"
        case .commentary:
            return "Commentaries"
        default:
            return "extras"
        }
    }
    
    /// Keywords to help identify this type in input text
    var keywords: [String] {
        switch self {
        case .commentary:
            return ["commentary", "commentary by", "audio commentary", "text commentary"]
        case .deletedScene:
            return ["deleted scene", "deleted scenes", "scene"]
        case .musicVideo:
            return ["music video", "music videos"]
        case .trailer:
            return ["trailer", "trailers", "rob reiner theatrical trailers"]
        case .featurette:
            return ["featurette", "featurettes", "shooting", "behind the wheel"]
        case .behindTheScenes:
            return ["behind the scenes", "behind"]
        case .makingOf:
            return ["making of", "making", "the good the bad"]
        case .interview:
            return ["interview", "with"]
        case .documentary:
            return ["documentary", "documentaries"]
        case .other:
            return ["promotional", "soundtrack"]
        }
    }
   
   static func extraType(section: DVDCompareParser.Section) -> ExtraType? {
      switch section {
      case .episodes:
         return nil
      case .commentaries:
         return .commentary
      case .deleted_scenes:
         return .deletedScene
      case .music_videos:
         return .musicVideo
      case .trailers:
         return .trailer
      case .supplements:
         return nil
      case .featurettes:
         return .featurette
      case .behind_the_scenes:
         return .behindTheScenes
      case .making_of:
         return .makingOf
      case .interviews:
         return .interview
      case .documentaries:
         return .documentary
      }
   }
}
