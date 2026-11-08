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
       let pattern = "^\\s*(?:\\()?(\\d+):(\\d{2})(?:\\))?\\s*$"
       guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
             let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)) else {
          return nil
       }

       let hours:Int = 0
       let minutes:Int = Int(trimmed.string(match.range(at: 1)) ?? "") ?? 0
       let seconds:Int = Int(trimmed.string(match.range(at: 2)) ?? "") ?? 0

       return TimeInterval(hours * (60*60) + minutes * 60 + seconds)
    }
    
    /// Formats a TimeInterval to HH:MM or MM:SS format
    static func format(_ duration: TimeInterval?) -> String {
       guard let duration else {
          return "00:00"
       }
       
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
   
   /// Splits a string by the last open paren, returning the parenthesized time portion
   /// - Parameter input: Input string that may contain time in parentheses at the end
   /// - Returns: Tuple of (prefix without time, time in parentheses) or (original, nil) if not found
   static func splitByLastOpenParen(_ input: String) -> (prefix: String, time: String)? {
      guard let lastOpenParenIndex = input.lastIndex(of: "(") else {
         return nil
      }
      
      let timePortion = String(input[input.index(before: lastOpenParenIndex)...])
      let prefix = String(input.prefix(upTo: lastOpenParenIndex))
      
      // Verify the time portion matches the expected format (MM:SS or HH:MM)
      guard timePortion.contains(":") else {
         return nil
      }
      
      return (prefix, timePortion)
   }
}
