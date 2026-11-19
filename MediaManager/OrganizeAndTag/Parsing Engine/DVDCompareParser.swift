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

   class SectionParser {
      struct SectionRange {
         var section: Section
         var range: Range<String.Index>
      }
      
      let sectionRanges: Array<SectionRange>
      
      init(from: String) {
         self.sectionRanges = SectionParser.findSections(from: from)
      }
      
      private static func findSections(from input: String) -> Array<SectionRange> {
         // Find section headers
         let sections = [
            ("Episodes", "\\b([Ee]pisodes)(?:\\s*)?(?:\\([^)]*\\))?:?\n"),// TV Show Only
            ("Commentaries", "\\b[Cc]ommentaries?:?\n"),
            ("Deleted Scenes", "\\b[Dd]eleted\\s*[Ss]cenes?:?\n"),
            ("Music Videos", "\\b[Mm]usic\\s*[Vv]ideos?:?\n"),
            ("Trailers", "\\b[Tt]railers?:?\n"),
            ("Supplements", "\\b[Ss]upplements?:?\n"),
            ("Featurettes", "\\b[Ff]eaturettes?:?\n"),
            ("Behind the Scenes", "\\b[Bb]ehind the [Ss]cenes?:?\n"),
            ("Making Of", "\\b[Mm]aking [Oo]f:?\n"),
            ("Interviews", "\\b[Ii]nterviews?:?\n"),
            ("Documentaries", "\\b[Dd]ocumentaries?:?\n"),
         ]
         
         var foundSections = Array<SectionRange>()
         for (sectionName, pattern) in sections {
            if let range = input.range(of: pattern, options: .regularExpression) {
               if let currentSection = Section.section(rawValue: sectionName) {
                  foundSections.append(SectionRange(section: currentSection,range: range))
               }
            }
         }
         
         foundSections.sort(by: { a,b in a.range.upperBound < b.range.upperBound})
         
         return foundSections
      }
      
      func processSections(processor: (Section,String.Index,String.Index?)->Void) {
         for i in 0..<sectionRanges.count {
            let start = sectionRanges[i].range.upperBound
            let end = ((i+1) < sectionRanges.count) ? sectionRanges[i+1].range.lowerBound : nil
            processor(sectionRanges[i].section,start,end)
         }
      }
      
      func processSections(from input: String,processor: (Section,Array<String>)->Void) {
         for i in 0..<sectionRanges.count {
            let sOffset = sectionRanges[i].range.upperBound
            let eOffset = ((i+1) < sectionRanges.count) ? sectionRanges[i+1].range.lowerBound : nil

            let remaining = (eOffset == nil) ? String(input[sOffset...]) : String(input[sOffset..<eOffset!])
            let lines = remaining.components(separatedBy: .newlines)

            processor(sectionRanges[i].section,lines)
         }

      }
   }
   
    /// Parses TV show content
    private static func parseTVShow(from input: String,into content: inout DVDCompareContent) {
       let parser = SectionParser(from: input)
       
       parser.processSections(processor: { section,start,end in
          let delimiter: Character?
          if section == .episodes {
             // Read the first line to identify episode delimiter.
             let remaining = (end == nil) ? String(input[start...]) : String(input[start..<end!])
             let startingLine: String = (remaining.components(separatedBy: .newlines).first ?? "").trimmingCharacters(in: .whitespaces)

             // Check if the first line starts with a number followed by a period (numbered episode format)
             // e.g., "1. a", "13. d" - in this case, there's no delimiter, the number is the episode number
             let trimmedStartingLine = startingLine.trimmingCharacters(in: .whitespaces)
             let isNumberedEpisode = trimmedStartingLine.range(of: "^\\d+\\.", options: .regularExpression) != nil
             
             if isNumberedEpisode {
                delimiter = nil // No delimiter, the number is part of the episode number
             } else {
                delimiter = startingLine.first
             }


             //delimiter = startingLine.first
          } else {
             delimiter = nil
          }
          
          parseSection(from: input, startingAt: start, endingAt: end, delimiter: delimiter,
                       section: section,
                       into: &content)
       })
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
    /// Parses an episode line
    static func parseEpisodeLine(_ line: String) -> Episode? {
        // Pattern: '- "Episode Title" (MM:SS)' OR '"Episode Title" (MM:SS)' OR '1. "Episode Title" (MM:SS)'
        //              (prefix)   (name     )   (!'(' and !'\n'  ) (duration               )
        // Also handles numbered episodes like "1. a" or "13. d"
        let titlePattern = "^(-\\s*)?(\\d+\\.?)?\\s*\"?([^\"\\n]+)\"?(?:\\s*[^\\(\\n]*)?(\\((\\d{1,2}:\\d{2})\\))?"
        //                   (prefix)(number  )        (name     )   (!'(' and !'\n'  ) (duration               )
        guard let regex = try? NSRegularExpression(pattern: titlePattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else {
            return nil
        }
        
        let title = line.string(match.range(at: 3)) ?? ""
        
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
        
        // Extract episode number from the numbered format if present
        var episodeNumber: Int = 0
        if let numberString = line.string(match.range(at: 2)) {
            if let parsedNumber = Int(numberString) {
                episodeNumber = parsedNumber
            }
        }
        
        return Episode(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            duration: duration,
            episodeNumber: episodeNumber, // Will be assigned later if startingEpisode is set
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
               
       let parser = SectionParser(from: input)
       parser.processSections(from: input, processor: { section, lines in
          let suggestedType: ExtraType?
          if let extraType = ExtraType.extraType(section: section) {
             suggestedType = extraType
          } else {
             suggestedType = nil
          }
          
          for line in lines {
             let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
             
             // Skip empty lines
             if trimmed.isEmpty {
                continue
             }
             
             // Parse extra lines
             if let extra = parseExtraLine(trimmed,suggestedType: suggestedType) {
                content.extras.append(extra)
             }
          }
       })
    }
    
   /// Parses an extra line
   private static func parseExtraLine(_ line: String,suggestedType: ExtraType?) -> Extra? {
       var titleCandidate: String = line.trimmingCharacters(in: .whitespacesAndNewlines)
       if ( titleCandidate.isEmpty ) {
          return nil
       }
       
       let duration: TimeInterval
       if let results = DurationParser.parse(duration: titleCandidate) {
          // We have a duration
          duration = results.duration
          titleCandidate = String(titleCandidate[..<results.start])
       } else {
          duration = 0
       }
       
      let type: ExtraType?
       if let results = detectExtraType(from: titleCandidate) {
          type = results.extraType
          titleCandidate = String(titleCandidate[..<results.index])
       } else {
          type = suggestedType
       }
      
      guard let type else { return nil }
       
       let title = titleCandidate
          .trimmingCharacters(in: .whitespacesAndNewlines)
          .trimmingCharacters(in: CharacterSet(charactersIn: "\""))

       return Extra(
         title: title,
         duration: duration,
         extraType: type,
         episodeNumber: nil,
         episodeTitle: nil,
         relatedEpisodeId: nil
       )
    }
    
    /// Detects extra type from line content
   private static func detectExtraType(from line: String) -> (extraType: ExtraType,index: String.Index)? {
      let lowerLine = line.lowercased()
      
      if let startIndex = lowerLine.index(of: "commentary") {
         return (.commentary,startIndex)
      } else if let startIndex = lowerLine.index(of: "deleted") {
         return (.deletedScene,startIndex)
      } else if let startIndex = lowerLine.index(of: "scene") {
         return (.deletedScene,startIndex)
      } else if let startIndex = lowerLine.index(of: "music video") {
         return (.musicVideo,startIndex)
      } else if let startIndex = lowerLine.index(of: "trailer") {
         return (.trailer,startIndex)
      } else if let startIndex = lowerLine.index(of: "feature") {
         return (.featurette,startIndex)
      } else if let startIndex = lowerLine.index(of: "behind") {
         return (.behindTheScenes,startIndex)
      } else if let startIndex = lowerLine.index(of: "making") {
         return (.makingOf,startIndex)
      } else if let startIndex = lowerLine.index(of: "interview") {
         return (.interview,startIndex)
      } else if let startIndex = lowerLine.index(of: "documentary") {
         return (.documentary,startIndex)
      } else {
         return nil
      }
   }
    
    /// Enum representing different sections in the input
   enum Section: String, CaseIterable {
      /*
       ("Episodes", "\\b([Ee]pisodes)(?:\\s*)?(?:\\([^)]*\\))?:?\n"),// TV Show Only
       ("Commentaries", "\\b[Cc]ommentaries?:?\n"),
       ("Deleted Scenes", "\\b[Dd]eleted\\s*[Ss]cenes?:?\n"),
       ("Music Videos", "\\b[Mm]usic\\s*[Vv]ideos?:?\n"),
       ("Trailers", "\\b[Tt]railers?:?\n"),
       ("Supplements", "\\b[Ss]upplements?:?\n"),
       ("Featurettes", "\\b[Ff]eaturettes?:?\n"),
       ("Behind the Scenes", "\\b[Bb]ehind the [Ss]cenes?:?\n"),
       ("Making Of", "\\b[Mm]aking [Oo]f:?\n"),
       ("Interviews", "\\b[Ii]nterviews?:?\n"),
       ("Documentaries", "\\b[Dd]ocumentaries?:?\n"),
       */
      case episodes
      case commentaries
      case deleted_scenes
      case music_videos
      case trailers
      case supplements
      case featurettes
      case behind_the_scenes
      case making_of
      case interviews
      case documentaries
      
      var name: String {
         switch self {
         case .episodes: return "Episodes"
         case .commentaries: return "Commentaries"
         case .deleted_scenes: return "Deleted Scenes"
         case .music_videos: return "Music Videos"
         case .trailers: return "Trailers"
         case .supplements: return "Supplements"
         case .featurettes: return "Featurettes"
         case .behind_the_scenes: return "Behind the Scenes"
         case .making_of: return "Making Of"
         case .interviews: return "Interviews"
         case .documentaries: return "Documentaries"
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
