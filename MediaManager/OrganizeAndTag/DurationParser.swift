//
//  DurationParser.swift
//  MediaManager
//
//  Copyright © 2026 JVSherwood. All rights reserved.
//

import Foundation

/// Parses duration strings from various formats
struct DurationParser {
    
    /// Converts a duration string to TimeInterval
    /// - Parameter duration: Duration string in formats like "21:32", "M:SS", "MM:SS"
    /// - Returns: TimeInterval in seconds, or nil if parsing fails
    static func parse(_ duration: String) -> TimeInterval? {
        let trimmed = duration.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        
        // Pattern for MM:SS or M:SS
        //let pattern = "^\\s*(\\d+):([0-5]?\\d)(?::([0-5]?\\d))?\\s*$"
       let pattern = "^\\s*(\\d+):(\\d{2})\\s*$"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)) else {
            return nil
        }
        
       let hours:Int = 0//Int(match.range(at: 1).lowerBound)
       let minutes:Int = Int(trimmed.string(match.range(at: 1)) ?? "") ?? 0//Int(match.range(at: 2).lowerBound)
        let seconds:Int = Int(trimmed.string(match.range(at: 2)) ?? "") ?? 0//Int(match.range(at: 2).lowerBound)//match.range(at: 3).lowerBound > 0 ? Int(match.range(at: 3).lowerBound) : 0
        
        return TimeInterval(hours * (60*60) + minutes * 60 + seconds)
    }
    
    /// Formats a TimeInterval to HH:MM or MM:SS format
    static func format(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d", hours, minutes)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
