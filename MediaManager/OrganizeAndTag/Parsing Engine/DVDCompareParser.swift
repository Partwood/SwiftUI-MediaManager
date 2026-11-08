//
//  DVDCompareParser.swift
//  MediaManager
//
//  Copyright © 2026 JVSherwood. All rights reserved.
//

import Foundation

let bspace = "\u{08}" // backspace

/// Parses dvdcompare.net content into structured data
struct DVDCompareParser {
      static var startingEpisode: Int? = nil
   
    /// Parses raw input text into DVDCompareContent
    /// - Parameter input: Raw input text from dvdcompare.net
    /// - Returns: Parsed content with warnings for incomplete data
    static func parse(_ input: String,startingEpisode: Int? = nil) -> DVDCompareContent {
       DVDCompareParser.startingEpisode = startingEpisode
       
        let preprocessed = InputPreprocessor.preprocess(input)
        
        var content = DVDCompareContent(
            type: detectContentType(preprocessed),
            title: extractTitle(preprocessed),
            season: extractSeason(preprocessed),
            year: extractYear(preprocessed),
            plot: extractPlot(preprocessed)
        )
        
        // Parse based on content type
        switch content.type {
        case .tvShow:
            parseTVShow(from: preprocessed, into: &content)
        case .movie:
            parseMovie(from: preprocessed, into: &content)
        }
        
        return content
    }
    
    /// Detects whether content is a movie or TV show
    private static func detectContentType(_ input: String) -> MediaType {
       // TV shows typically have "Season" in the title
       if input.lowercased().contains("season") {
          return .tvShow
       }
       
       if input.lowercased().contains("series") {
          return .tvShow
       }
       
       // Movies typically have "(Year)" format
       if let _ = input.range(of: "(\\d{4})", options: .regularExpression) {
          return .movie
       }
       
       // Default to TV show if ambiguous
       return .tvShow
    }
    
    /// Extracts the title from input
    private static func extractTitle(_ input: String) -> String {
       let firstLine: String = String(input.split(separator: "\n",maxSplits: 1).first ?? "")
       
        // Remove "Season X" suffix for TV shows
        let withoutSeason = firstLine.replacingOccurrences(
            of: ": (Season|Series) \\d+",
            with: "",
            options: .regularExpression
        ).replacingOccurrences(
            of: " (Season|Series) \\d+", 
            with: "", 
            options: .regularExpression
        ).replacingOccurrences(
         of: " \\(TV\\)",// TV indicator
         with: "",
         options: .regularExpression
        ).replacingOccurrences(
         of: " \\(\\d{4}\\)",// Year, i.e. (2009)
         with: "",
         options: .regularExpression
        ).replacingOccurrences(
         of: " \\(\\d{4}\\-\\d{4}\\)",// Year, i.e. (2001-2002)
         with: "",
         options: .regularExpression
        )
        
        // Extract title (everything before "Episodes:", "Extras:", or first year pattern)
        let title = withoutSeason
            .components(separatedBy: ["Episodes", "Extras"/*, ":", " "*/])
            .first ?? withoutSeason.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return title.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Extracts season number from input
    private static func extractSeason(_ input: String) -> Int? {
        let pattern = "(Season|season|Series|series)\\s*(\\d+)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: input, range: NSRange(input.startIndex..., in: input)),
              match.range(at: 1).location != NSNotFound else {
            return nil
        }
        
        if let substring = input.subString(match.range(at: 2)),
           let season = Int(substring) {
            return season
        }
        return nil
    }
    
    /// Extracts year from input
    private static func extractYear(_ input: String) -> Int? {
        let pattern = "(\\d{4})"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: input, range: NSRange(input.startIndex..., in: input)) else {
            return nil
        }
        
        if let substring = input.subString(match.range(at: 1)),
           let year = Int(substring) {
            return year
        }
        return nil
    }
    
    /// Extracts plot description (for movies)
    private static func extractPlot(_ input: String) -> String? {
        // Plot is typically the first paragraph after the title
        let lines = input.components(separatedBy: .newlines)
        
        // Find first line that looks like a plot (not a header, not an episode)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip headers and episode-like entries
            if trimmed.isEmpty ||
               trimmed.hasPrefix("Director:") ||
               trimmed.hasPrefix("Extras:") ||
               trimmed.hasPrefix("Episodes:") ||
               trimmed.hasPrefix("Commentaries:") ||
               trimmed.hasPrefix("Deleted Scenes:") ||
               trimmed.contains("Season") ||
               trimmed.contains("Episode") ||
               (trimmed.contains("(") && trimmed.contains(")")) {
                continue
            }
            
            // This might be the plot
            if trimmed.count > 10 && trimmed.count < 500 {
                return trimmed
            }
        }
        
        return nil
    }
    
    /// Parses TV show content
    private static func parseTVShow(from input: String,into content: inout DVDCompareContent) {
        // Find section headers
        let sections = [
            ("Episodes", "\\b([Ee]pisodes)(?:\\s*)?(?:\\([^)]*\\))?:?\n"),
            ("Commentaries", "\\bCommentaries?:?\n"),
            ("Deleted Scenes", "\\bDeleted\\s*Scenes?:?\n"),
            ("Music Videos", "\\bMusic\\s*Videos?:?\n"),
            ("Trailers", "\\bTrailers?:?\n"),
            ("Supplements", "\\bSupplements?:?\n")
        ]
        
       struct SectionRange {
          var section: Section
          var range: Range<String.Index>
       }
       
       var foundSections = Array<SectionRange>()
       for (sectionName, pattern) in sections {
          if let range = input.range(of: pattern, options: .regularExpression) {
             if let currentSection = Section.section(rawValue: sectionName) {
                foundSections.append(SectionRange(section: currentSection,range: range))
             }
          }
       }
       
       foundSections.sort(by: { a,b in a.range.upperBound < b.range.upperBound})

       for i in 0..<foundSections.count {
          let start = foundSections[i].range.upperBound//input.index(after: foundSections[i].range.upperBound)
          let end = ((i+1) < foundSections.count) ? foundSections[i+1].range.lowerBound : nil
          
          let delimiter: Character?
          if foundSections[i].section == .episodes {
             // Read the first line to identify episode delimiter.
             let remaining = (end == nil) ? String(input[start...]) : String(input[start..<end!])
             let startingLine: String = (remaining.components(separatedBy: .newlines).first ?? "").trimmingCharacters(in: .whitespaces)
             delimiter = startingLine.first
          } else {
             delimiter = nil
          }
          
          parseSection(from: input, startingAt: start, endingAt: end, delimiter: delimiter,
                       section: foundSections[i].section,
                       into: &content)
       }
    }
    
    /// Parses a specific section of content
   private static func parseSection(from input: String,
                                    startingAt offset: String.Index,
                                    endingAt endOffset: String.Index?,
                                    delimiter: Character?,
                                    section: Section,
                                    into content: inout DVDCompareContent,
   ) {
       let remaining = (endOffset == nil) ? String(input[offset...]) : String(input[offset..<endOffset!])
        let lines = remaining.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty lines and headers
            if trimmed.isEmpty || trimmed.hasPrefix("Episodes:") || trimmed.hasPrefix("Commentaries:") {
                continue
            }
           
           if let delimiter,
              ( trimmed.first != delimiter ) {
              break
           }
            
           if ( section == .episodes ) {
              // Parse episode entries: "- "Episode Title" (21:32)"
              if var episode = parseEpisodeLine(trimmed) {
                 if let startingEpisode = DVDCompareParser.startingEpisode {
                    episode.episodeNumber = content.episodes.count + startingEpisode
                 }
                 content.episodes.append(episode)
              }
           } else if ( section == .commentaries ) {
              // Parse commentary entries: "- "Episode Title" with ..."
              if let extra = parseCommentaryLine(trimmed) {
                 content.commentaries.append(extra)
              }
           } else if ( section == .deleted_scenes ) {
              // Parse deleted scene entries
              if let extra = parseDeletedSceneLine(trimmed) {
                 content.deletedScenes.append(extra)
              }
           } else if ( section == .supplements ) {
              // Parse standalone deleted scenes: "Scene 92 (1:31)"
              if let extra = parseStandaloneSceneLine(trimmed) {
                 content.deletedScenes.append(extra)
              }
           }
        }
    }
    
    /// Parses an episode line
    static func parseEpisodeLine(_ line: String) -> Episode? {
        // Pattern: '- "Episode Title" (MM:SS)' OR '"Episode Title" (MM:SS)'; Time could be optional
       //let pattern = "^(-\\s*)?\"?([^\"\\n]+)\"?(?:\\s*[^\\(\\n]*)?(\\((\\d{1,2}:\\d{2})\\))?"
       let titlePattern = "^(-\\s*)?\"?([^\"\\n]+)\"?(?:\\s*[^\\(\\n]*)?(\\((\\d{1,2}:\\d{2})\\))?"
       //              (prefix)   (name     )   (!'(' and !'\n'  ) (duration               )
        guard let regex = try? NSRegularExpression(pattern: titlePattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else {
            return nil
        }
        
       let title = line.string(match.range(at: 2)) ?? ""
       
       let duration: TimeInterval?
       if let split = DurationParser.splitByLastOpenParen(line) {
          let durationString = split.time
          duration = DurationParser.parse(durationString)
       } else {
          duration = nil
       }       

        // Check for alternative cuts
       let isAlternativeCut: Bool
       let alternativeCut:String?
       if line.lowercased().contains("original") {
          isAlternativeCut = true
          alternativeCut = "Original cut"
       } else if line.lowercased().contains("extended") {
          isAlternativeCut = true
          alternativeCut = "Extended cut"
       } else if line.lowercased().contains("producer") {
          isAlternativeCut = true
          alternativeCut = "Producer cut"
       } else if line.lowercased().contains("remaster") {
          isAlternativeCut = true
          alternativeCut = "Remastered cut"
       } else {
          isAlternativeCut = false
          alternativeCut = nil
       }
       
        return Episode(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            duration: duration,
            episodeNumber: 0, // Will be assigned later
            isDeletedScene: nil,
            plot: nil,
            cast: nil,
            rating: nil,
            isAlternativeCut: isAlternativeCut,
            alternativeCut: alternativeCut
        )
    }
    
    /// Parses a commentary line
    private static func parseCommentaryLine(_ line: String) -> Extra? {
       // Pattern: "- "Episode Title" with ..."
       let pattern = "^-\\s*\"?([^\"\\n]+)\"?\\s*with\\s+([^\\n]+)"
       
       guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
             let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else {
          return nil
       }
       
       let title: String = line.string(match.range(at: 1)) ?? ""
       let type = ExtraType.commentary
       
       // Try to extract episode title from the "with" part
       let episodeSubstring = line.boundedBy(lower: match.range(at: 2))
       let episodeTitle = extractEpisodeTitle(from: episodeSubstring)
       
       return Extra(
         title: title.trimmingCharacters(in: .whitespacesAndNewlines),
         duration: 0, // Duration not typically provided for commentaries
         extraType: type,
         episodeNumber: nil,
         episodeTitle: episodeTitle,
         relatedEpisodeId: episodeTitle
       )
    }
    
    /// Parses a deleted scene line
    private static func parseDeletedSceneLine(_ line: String) -> Extra? {
        // Pattern: "- "Episode Title" (HH:MM)" where line contains "Deleted Scene"
        let pattern = "^-\\s*\"?([^\"\\n]+)\"?\\s*\\((\\d{1,2}):(\\d{2})\\)"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else {
            return nil
        }
        
       let title: String = line.string(match.range(at: 1)) ?? ""
       
       let substring = line.boundedBy(lower: match.range(at: 2))
       
        let duration = DurationParser.parse(substring ?? "") ?? 0
        
        let type = ExtraType.deletedScene
        
        // Try to extract episode title
       let episodeSubstring = line.boundedBy(lower: match.range(at: 1))
       let episodeTitle = extractEpisodeTitle(from: episodeSubstring)

        return Extra(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            duration: duration,
            extraType: type,
            episodeNumber: nil,
            episodeTitle: episodeTitle,
            relatedEpisodeId: episodeTitle
        )
    }
    
    /// Parses standalone scene lines (not prefixed with "-")
    private static func parseStandaloneSceneLine(_ line: String) -> Extra? {
        // Pattern: "Scene 92 (1:31)"
        let pattern = "^Scene\\s*(\\d+(?:-\\d+)?)\\s*\\((\\d{1,2}):(\\d{2})\\)"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else {
            return nil
        }
        
        let title = line
       let substring = line.boundedBy(lower: match.range(at: 2))
        let duration = DurationParser.parse(substring ?? "") ?? 0
        
        let type = ExtraType.deletedScene
        
        return Extra(
            title: title,
            duration: duration,
            extraType: type,
            episodeNumber: nil,
            episodeTitle: nil,
            relatedEpisodeId: nil
        )
    }
    
    /// Extracts episode title from commentary/deleted scene text
    private static func extractEpisodeTitle(from: String?) -> String? {
       guard let text = from else { return nil }
       
        // Look for episode title pattern
        let patterns = [
            "\"([^\"\\n]+)\"",
            "\"?([^\"\\n]+)\"?",
            "with\\s+([^\\n]+)"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               match.range(at: 1).location != NSNotFound,
               let title = text.subString(match.range(at: 1)) {
                if !title.isEmpty && !title.contains("with") {
                    return String(title)
                }
            }
        }
        
        return nil
    }
    
    /// Parses movie content
    private static func parseMovie(from input: String, into content: inout DVDCompareContent) {
        // Extract director information
        if let directorRange = input.range(of: "Director:", options: .backwards) {
            let director = String(input[directorRange.upperBound...])
                .components(separatedBy: ["\n", " ", ":"])
                .first?.trimmingCharacters(in: .whitespacesAndNewlines)
            
            content.director = director
        }
        
        // Parse extras
        if let extrasRange = input.range(of: "Extras:", options: .backwards) {
            parseExtras(from: input, startingAt: extrasRange.upperBound, into: &content)
        }
        
        // Parse featurettes/behind the scenes
        if let featurettesRange = input.range(of: "Featurettes:", options: .backwards) {
            parseFeaturettes(from: input, startingAt: featurettesRange.upperBound, into: &content)
        }
        
        // Parse behind the scenes
        if let btsRange = input.range(of: "Behind the Scenes:", options: .backwards) {
            parseBehindTheScenes(from: input, startingAt: btsRange.upperBound, into: &content)
        }
        
        // Parse making of
        if let makingRange = input.range(of: "Making Of:", options: .backwards) {
            parseMakingOf(from: input, startingAt: makingRange.upperBound, into: &content)
        }
        
        // Parse trailers
        if let trailersRange = input.range(of: "Trailers:", options: .backwards) {
            parseTrailers(from: input, startingAt: trailersRange.upperBound, into: &content)
        }
        
        // Parse music videos
        if let musicRange = input.range(of: "Music Video:", options: .backwards) {
            parseMusicVideos(from: input, startingAt: musicRange.upperBound, into: &content)
        }
    }
    
    /// Parses extras section
    private static func parseExtras(from input: String, startingAt offset: String.Index, 
                                   into content: inout DVDCompareContent) {
        let remaining = String(input[offset...])
        let lines = remaining.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty lines and headers
            if trimmed.isEmpty || trimmed.hasPrefix("Extras:") || trimmed.hasPrefix("Director:") {
                continue
            }
            
            // Parse extra lines
            if let extra = parseExtraLine(trimmed) {
                content.extras.append(extra)
            }
        }
    }
    
    /// Parses an extra line
    private static func parseExtraLine(_ line: String) -> Extra? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check for featurette pattern: "Shooting Bond" featurettes
        if trimmed.contains("featurettes") || trimmed.contains("featurette") {
            let type = ExtraType.featurette
            
            // Extract title before "featurettes"
            let title = trimmed.split(separator: "featurettes").first?.trimmingCharacters(in: .whitespacesAndNewlines)
                ?? trimmed
            
           return Extra(
            title: title,
            duration: 0,
            extraType: type,
            episodeNumber: nil,
            episodeTitle: nil,
            relatedEpisodeId: nil
           )
        }
        
        // Check for standalone extra: "Shooting Bond" featurettes (w/ play all option) (12:25)
        if let durationMatch = trimmed.range(of: "\\((\\d{1,2}):(\\d{2})\\)", options: .regularExpression) {
            let duration = DurationParser.parse(String(trimmed[durationMatch])) ?? 0
            
            // Determine type based on keywords
            let type = detectExtraType(from: trimmed)
            
            let title = trimmed
                .replacingOccurrences(of: "\\(", with: "")
                .replacingOccurrences(of: "\\)", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            return Extra(
                title: title,
                duration: duration,
                extraType: type,
                episodeNumber: nil,
                episodeTitle: nil,
                relatedEpisodeId: nil
            )
        }
        
        return nil
    }
    
    /// Detects extra type from line content
    private static func detectExtraType(from line: String) -> ExtraType {
        let lowerLine = line.lowercased()
        
        if lowerLine.contains("commentary") {
            return .commentary
        } else if lowerLine.contains("deleted") || lowerLine.contains("scene") {
            return .deletedScene
        } else if lowerLine.contains("music video") {
            return .musicVideo
        } else if lowerLine.contains("trailer") {
            return .trailer
        } else if lowerLine.contains("featurette") {
            return .featurette
        } else if lowerLine.contains("behind") {
            return .behindTheScenes
        } else if lowerLine.contains("making") {
            return .makingOf
        } else if lowerLine.contains("interview") {
            return .interview
        } else if lowerLine.contains("documentary") {
            return .documentary
        }
        
        return .other
    }
    
    /// Parses featurettes section
    private static func parseFeaturettes(from input: String, startingAt offset: String.Index, 
                                        into content: inout DVDCompareContent) {
        let remaining = String(input[offset...])
        let lines = remaining.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmed.isEmpty || trimmed.hasPrefix("Featurettes:") || trimmed.hasPrefix("Extras:") {
                continue
            }
            
            if let extra = parseExtraLine(trimmed) {
                content.extras.append(extra)
            }
        }
    }
    
    /// Parses behind the scenes section
    private static func parseBehindTheScenes(from input: String, startingAt offset: String.Index, 
                                            into content: inout DVDCompareContent) {
        let remaining = String(input[offset...])
        let lines = remaining.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmed.isEmpty || trimmed.hasPrefix("Behind the Scenes:") {
                continue
            }
            
            if let extra = parseExtraLine(trimmed) {
                content.extras.append(extra)
            }
        }
    }
    
    /// Parses making of section
    private static func parseMakingOf(from input: String, startingAt offset: String.Index, 
                                     into content: inout DVDCompareContent) {
        let remaining = String(input[offset...])
        let lines = remaining.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmed.isEmpty || trimmed.hasPrefix("Making Of:") {
                continue
            }
            
            if let extra = parseExtraLine(trimmed) {
                content.extras.append(extra)
            }
        }
    }
    
    /// Parses trailers section
    private static func parseTrailers(from input: String, startingAt offset: String.Index, 
                                     into content: inout DVDCompareContent) {
        let remaining = String(input[offset...])
        let lines = remaining.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmed.isEmpty || trimmed.hasPrefix("Trailers:") {
                continue
            }
            
            if let extra = parseExtraLine(trimmed) {
                content.extras.append(extra)
            }
        }
    }
    
    /// Parses music videos section
    private static func parseMusicVideos(from input: String, startingAt offset: String.Index, 
                                        into content: inout DVDCompareContent) {
        let remaining = String(input[offset...])
        let lines = remaining.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmed.isEmpty || trimmed.hasPrefix("Music Video:") {
                continue
            }
            
            if let extra = parseExtraLine(trimmed) {
                content.extras.append(extra)
            }
        }
    }
    
    /// Enum representing different sections in the input
   enum Section: String, CaseIterable {
      case episodes
      case commentaries
      case deleted_scenes
      case music_videos
      case trailers
      case supplements
      
      var name: String {
         switch self {
         case .episodes: return "Episodes"
         case .commentaries: return "Commentaries"
         case .deleted_scenes: return "Deleted Scenes"
         case .music_videos: return "Music Videos"
         case .trailers: return "Trailers"
         case .supplements: return "Supplements"
         }
      }
      
      static func section(rawValue: String) -> Section? {
         let underscored = rawValue.lowercased().replacingOccurrences(of: " ", with: "_")
         return Section.allCases.first(where: { value in
            value.rawValue == underscored
         })
      }
   }
}
