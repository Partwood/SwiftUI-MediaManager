//
//  NFO.swift
//  MediaManager
//
//  Created by Joshua V Sherwood on 10/27/26.
//

import Foundation

// NFO Metadata structures for Jellyfin/NFO file support
struct NFOMetadata: Identifiable {
   let id = UUID()
   var title: String?
   var plot: String?
   var year: String?
   var director: String?
   var writer: String?
   var actors: [String] = []
   var rating: String?
   var genre: String?
   var runtime: String?
   var studio: String?
   var tagline: String?
   var imdbId: String?
   var tvdbId: String?
   var omdbId: String?
   var network: String?
   var status: String?
   var aired: String?
   var episodeCount: Int?
   var seasonNumber: Int?
   var episodeNumber: Int?
   var languages: [String] = []
   var countries: [String] = []
   var aspectRatio: String?
   var resolution: String?
   var cast: [(name: String, role: String)] = []
   
   // Image references
   var poster: String?
   var fanart: String?
   var screenshots: [String] = []
   
   // Additional fields
   var additionalInfo: [String: String] = [:]
}

struct NFOSection {
   let title: String
   let content: String
}

class NFOParser {
   func parseNFOMetadata(_ fileSystem: FileSystem,_ url: URL) throws -> (metadata: NFOMetadata,sections: [NFOSection]) {
      var contentError: Error? = nil
      var results: (NFOMetadata, [NFOSection])?
      
      fileSystem.accessURL(url, { url in
         if let url {
            // Read the NFO file content
            let fileHandle: FileHandle
            do {
               fileHandle = try FileHandle(forReadingFrom: url)
            } catch {
               contentError = FileIOError.read_error(url, error)
               return
            }
            defer { fileHandle.closeFile() }
            
            let min = min(1024 * 100, Int(fileHandle.seekToEndOfFile())) // Read up to 100KB
            do {
               try fileHandle.seek(toOffset: 0)
            } catch {
               contentError = FileIOError.read_error(url, error)
               return
            }
            let data = fileHandle.readData(ofLength: min)
            
            guard let content = String(data: data, encoding: .utf8) else {
               contentError = FileIOError.read_error(url)
               return
            }
            
            // Parse XML content
            results = self.parseNFOContent(content, url: url)
         }
      })
      
      if let contentError {
         throw contentError
      }
      
      if let results {
         return results
      } else {
         throw FileIOError.read_error(url)
      }
   }
   
   private func parseNFOContent(_ content: String, url: URL) -> (NFOMetadata, [NFOSection]) {
      var metadata = NFOMetadata()
      var sections: [NFOSection] = []
      
      // Remove XML declaration if present
      let cleanedContent: String = content.replacingOccurrences(of: "<?xml.*?>", with: "", options: .regularExpression)
      
      // Split content into sections based on XML tags
      let pattern = "<([^/!]?[^/][^>]*)>.*?</\\1>"
      let sectionsRegex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
      //let sectionsRegex = try! NSRegularExpression(pattern: "<[^/!]?[^/][^>]*>.*?</\\1>", options: .caseInsensitive)
      let matches = sectionsRegex.matches(in: cleanedContent, options: [], range: NSRange(cleanedContent.startIndex..., in: cleanedContent))
      
      for match in matches {
         if let range = Range(match.range, in: cleanedContent) {
            let sectionContent = String(cleanedContent[range])
            let subrange = cleanedContent[match.range.lowerBound..<match.range.upperBound]
            let title = extractTagName(from: String(subrange))
            let content = extractTextContent(from: sectionContent)
            
            if !title.isEmpty || !content.isEmpty {
               sections.append(NFOSection(title: title, content: content))
            }
         }
      }
      
      // Extract specific metadata fields
      extractMovieMetadata(from: content, into: &metadata)
      extractTVMetadata(from: content, into: &metadata)
      extractCastMetadata(from: content, into: &metadata)
      
      return (metadata, sections)
   }
   
   private func extractTagName(from xml: String) -> String {
      let start = xml.firstIndex(of: "<") ?? xml.startIndex
      let end = xml.firstIndex(of: ">") ?? xml.endIndex
      let tag = String(xml[start..<end]).replacingOccurrences(of: "<", with: "").replacingOccurrences(of: ">", with: "")
      let components = tag.components(separatedBy: " ")
      return components.first ?? ""
   }
   
   private func extractTextContent(from xml: String) -> String {
      // Remove opening and closing tags
      let start = xml.firstIndex(of: "<") ?? xml.endIndex
      let end = xml.lastIndex(of: ">") ?? xml.startIndex
      
      // Handle self-closing tags
      if xml.contains(" /") {
         return ""
      }
      
      let content = String(xml[start..<end])
      // Remove nested tags
      var cleaned = content
      while let nestedTag = cleaned.firstIndex(of: "<") {
         let endTag = cleaned[nestedTag..<cleaned.endIndex].firstIndex(of: ">")
         if let endTag = endTag, nestedTag != endTag {
            let sIndex = nestedTag
            let eIndex = cleaned.index(cleaned.index(endTag, offsetBy: 1),offsetBy: 0, limitedBy: cleaned.endIndex)!
            cleaned.replaceSubrange(sIndex..<eIndex, with: "")
            //cleaned.replaceSubrange(nestedTag...cleaned.index(cleaned.index(endTag, offsetBy: 1), limitedBy: cleaned.endIndex)!) with: "")
         } else {
            break
         }
      }
      return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
   }
   
   //      private func extractTagName(from xml: String) -> String {
   //         let start = xml.firstIndex(of: "<") ?? xml.startIndex
   //         let end = xml.firstIndex(of: ">") ?? xml.endIndex
   //         let tag = String(xml[start..<end]).replacingOccurrences(of: "<", with: "").replacingOccurrences(of: ">", with: "")
   //         let components = tag.components(separatedBy: " ")
   //         return components.first ?? ""
   //      }
   //
   //      private func extractTextContent(from xml: String) -> String {
   //         // Remove opening and closing tags
   //         let start = xml.firstIndex(of: "<") ?? xml.endIndex
   //         let end = xml.lastIndex(of: ">") ?? xml.startIndex
   //
   //         // Handle self-closing tags
   //         if xml.contains(" /") {
   //            return ""
   //         }
   //
   //         let content = String(xml[start..<end])
   //         // Remove nested tags
   //         var cleaned = content
   //         while let nestedTag = cleaned.firstIndex(of: "<") {
   //            let endTag = cleaned[nestedTag..<cleaned.endIndex].firstIndex(of: ">")
   //            if let endTag = endTag, nestedTag != endTag {
   //               cleaned.replaceSubrange(nestedTag...cleaned.index(cleaned.index(endTag, offsetBy: 1), limitedBy: cleaned.endIndex)!) with: "")
   //            } else {
   //               break
   //            }
   //         }
   //         return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
   //      }
   
   private func extractMovieMetadata(from content: String, into metadata: inout NFOMetadata) {
      // Extract title
      if let titleRange = content.range(of: "<title>") {
         let endRange = content.range(of: "</title>")
         if let endRange = endRange, endRange.lowerBound > titleRange.upperBound {
            metadata.title = String(content[titleRange.upperBound..<endRange.lowerBound])
               .trimmingCharacters(in: .whitespacesAndNewlines)
         }
      }
      
      // Extract plot
      if let plotRange = content.range(of: "<plot>") {
         let endRange = content.range(of: "</plot>")
         if let endRange = endRange, endRange.lowerBound > plotRange.upperBound {
            metadata.plot = String(content[plotRange.upperBound..<endRange.lowerBound])
               .trimmingCharacters(in: .whitespacesAndNewlines)
         }
      }
      
      // Extract year
      if let yearRange = content.range(of: "<year>") {
         let endRange = content.range(of: "</year>")
         if let endRange = endRange, endRange.lowerBound > yearRange.upperBound {
            metadata.year = String(content[yearRange.upperBound..<endRange.lowerBound])
               .trimmingCharacters(in: .whitespacesAndNewlines)
         }
      }
      
      // Extract director
      if let directorRange = content.range(of: "<director>") {
         let endRange = content.range(of: "</director>")
         if let endRange = endRange, endRange.lowerBound > directorRange.upperBound {
            metadata.director = String(content[directorRange.upperBound..<endRange.lowerBound])
               .trimmingCharacters(in: .whitespacesAndNewlines)
         }
      }
      
      // Extract writer
      if let writerRange = content.range(of: "<writer>") {
         let endRange = content.range(of: "</writer>")
         if let endRange = endRange, endRange.lowerBound > writerRange.upperBound {
            metadata.writer = String(content[writerRange.upperBound..<endRange.lowerBound])
               .trimmingCharacters(in: .whitespacesAndNewlines)
         }
      }
      
      // Extract rating
      if let ratingRange = content.range(of: "<rating>") {
         let endRange = content.range(of: "</rating>")
         if let endRange = endRange, endRange.lowerBound > ratingRange.upperBound {
            metadata.rating = String(content[ratingRange.upperBound..<endRange.lowerBound])
               .trimmingCharacters(in: .whitespacesAndNewlines)
         }
      }
      
      // Extract genre
      if let genreRange = content.range(of: "<genre>") {
         let endRange = content.range(of: "</genre>")
         if let endRange = endRange, endRange.lowerBound > genreRange.upperBound {
            metadata.genre = String(content[genreRange.upperBound..<endRange.lowerBound])
               .trimmingCharacters(in: .whitespacesAndNewlines)
         }
      }
      
      // Extract runtime
      if let runtimeRange = content.range(of: "<runtime>") {
         let endRange = content.range(of: "</runtime>")
         if let endRange = endRange, endRange.lowerBound > runtimeRange.upperBound {
            metadata.runtime = String(content[runtimeRange.upperBound..<endRange.lowerBound])
               .trimmingCharacters(in: .whitespacesAndNewlines)
         }
      }
      
      // Extract studio
      if let studioRange = content.range(of: "<studio>") {
         let endRange = content.range(of: "</studio>")
         if let endRange = endRange, endRange.lowerBound > studioRange.upperBound {
            metadata.studio = String(content[studioRange.upperBound..<endRange.lowerBound])
               .trimmingCharacters(in: .whitespacesAndNewlines)
         }
      }
      
      // Extract tagline
      if let taglineRange = content.range(of: "<tagline>") {
         let endRange = content.range(of: "</tagline>")
         if let endRange = endRange, endRange.lowerBound > taglineRange.upperBound {
            metadata.tagline = String(content[taglineRange.upperBound..<endRange.lowerBound])
               .trimmingCharacters(in: .whitespacesAndNewlines)
         }
      }
      
      // Extract IMDB ID
      if let imdbRange = content.range(of: "<imdb>") {
         let endRange = content.range(of: "</imdb>")
         if let endRange = endRange, endRange.lowerBound > imdbRange.upperBound {
            metadata.imdbId = String(content[imdbRange.upperBound..<endRange.lowerBound])
               .trimmingCharacters(in: .whitespacesAndNewlines)
         }
      }
      
      // Extract TVDB ID
      if let tvdbRange = content.range(of: "<tvdb>") {
         let endRange = content.range(of: "</tvdb>")
         if let endRange = endRange, endRange.lowerBound > tvdbRange.upperBound {
            metadata.tvdbId = String(content[tvdbRange.upperBound..<endRange.lowerBound])
               .trimmingCharacters(in: .whitespacesAndNewlines)
         }
      }
      
      // Extract OMDB ID
      if let omdbRange = content.range(of: "<omdb>") {
         let endRange = content.range(of: "</omdb>")
         if let endRange = endRange, endRange.lowerBound > omdbRange.upperBound {
            metadata.omdbId = String(content[omdbRange.upperBound..<endRange.lowerBound])
               .trimmingCharacters(in: .whitespacesAndNewlines)
         }
      }
      
      // Extract poster
      if let posterRange = content.range(of: "<poster>") {
         let endRange = content.range(of: "</poster>")
         if let endRange = endRange, endRange.lowerBound > posterRange.upperBound {
            metadata.poster = String(content[posterRange.upperBound..<endRange.lowerBound])
               .trimmingCharacters(in: .whitespacesAndNewlines)
         }
      }
      
      // Extract fanart
      if let fanartRange = content.range(of: "<fanart>") {
         let endRange = content.range(of: "</fanart>")
         if let endRange = endRange, endRange.lowerBound > fanartRange.upperBound {
            metadata.fanart = String(content[fanartRange.upperBound..<endRange.lowerBound])
               .trimmingCharacters(in: .whitespacesAndNewlines)
         }
      }
   }
   
   private func extractTVMetadata(from content: String, into metadata: inout NFOMetadata) {
      // Extract network
      if let networkRange = content.range(of: "<network>") {
         let endRange = content.range(of: "</network>")
         if let endRange = endRange, endRange.lowerBound > networkRange.upperBound {
            metadata.network = String(content[networkRange.upperBound..<endRange.lowerBound])
               .trimmingCharacters(in: .whitespacesAndNewlines)
         }
      }
      
      // Extract status
      if let statusRange = content.range(of: "<status>") {
         let endRange = content.range(of: "</status>")
         if let endRange = endRange, endRange.lowerBound > statusRange.upperBound {
            metadata.status = String(content[statusRange.upperBound..<endRange.lowerBound])
               .trimmingCharacters(in: .whitespacesAndNewlines)
         }
      }
      
      // Extract aired
      if let airedRange = content.range(of: "<aired>") {
         let endRange = content.range(of: "</aired>")
         if let endRange = endRange, endRange.lowerBound > airedRange.upperBound {
            metadata.aired = String(content[airedRange.upperBound..<endRange.lowerBound])
               .trimmingCharacters(in: .whitespacesAndNewlines)
         }
      }
      
      // Extract episode count
      if let epCountRange = content.range(of: "<episodes>") {
         let endRange = content.range(of: "</episodes>")
         if let endRange = endRange, endRange.lowerBound > epCountRange.upperBound {
            if let count = Int(String(content[epCountRange.upperBound..<endRange.lowerBound])) {
               metadata.episodeCount = count
            }
         }
      }
      
      // Extract season number
      if let seasonRange = content.range(of: "<season>") {
         let endRange = content.range(of: "</season>")
         if let endRange = endRange, endRange.lowerBound > seasonRange.upperBound {
            if let season = Int(String(content[seasonRange.upperBound..<endRange.lowerBound])) {
               metadata.seasonNumber = season
            }
         }
      }
      
      if let epNumberRange = content.range(of: "<episode>") {
         let endRange = content.range(of: "</episode>")
         if let endRange = endRange, endRange.lowerBound > epNumberRange.upperBound {
            if let number = Int(String(content[epNumberRange.upperBound..<endRange.lowerBound])) {
               metadata.episodeNumber = number
            }
         }
      }
   }
   
   private func extractCastMetadata(from content: String, into metadata: inout NFOMetadata) {
      // Extract actors
      if let actorsRange = content.range(of: "<actors>") {
         let endRange = content.range(of: "</actors>")
         if let endRange = endRange, endRange.lowerBound > actorsRange.upperBound {
            let actorContent = String(content[actorsRange.upperBound..<endRange.lowerBound])
            let actors = actorContent.components(separatedBy: ",").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            metadata.actors = actors
         }
      }
      
      // Extract cast with roles
      if let castRange = content.range(of: "<cast>") {
         let endRange = content.range(of: "</cast>")
         if let endRange = endRange, endRange.lowerBound > castRange.upperBound {
            let castContent = String(content[castRange.upperBound..<endRange.lowerBound])
            let roles = parseCastRoles(from: castContent)
            metadata.cast = roles
         }
      }
      
      // Extract languages
      if let languagesRange = content.range(of: "<languages>") {
         let endRange = content.range(of: "</languages>")
         if let endRange = endRange, endRange.lowerBound > languagesRange.upperBound {
            let langContent = String(content[languagesRange.upperBound..<endRange.lowerBound])
            let languages = langContent.components(separatedBy: ",").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            metadata.languages = languages
         }
      }
      
      // Extract countries
      if let countriesRange = content.range(of: "<countries>") {
         let endRange = content.range(of: "</countries>")
         if let endRange = endRange, endRange.lowerBound > countriesRange.upperBound {
            let countryContent = String(content[countriesRange.upperBound..<endRange.lowerBound])
            let countries = countryContent.components(separatedBy: ",").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            metadata.countries = countries
         }
      }
   }
   
   private func parseCastRoles(from content: String) -> [(name: String, role: String)] {
      var roles: [(name: String, role: String)] = []
      
      // Split by newlines to get individual cast entries
      let lines = content.components(separatedBy: .newlines)
      for line in lines {
         let trimmed = line.trimmingCharacters(in: .whitespaces)
         if trimmed.isEmpty || trimmed.hasPrefix("<") {
            continue
         }
         
         let parts = trimmed.components(separatedBy: ":")
         if parts.count >= 2 {
            let name = parts[0].trimmingCharacters(in: .whitespaces)
            let role = parts[1].trimmingCharacters(in: .whitespaces)
            roles.append((name: name, role: role))
         }
      }
      
      return roles
   }
}

extension String {
   subscript(bounds: CountableRange<Int>) -> Substring {
      let start = index(startIndex, offsetBy: max(0, bounds.lowerBound))
      let end = index(startIndex, offsetBy: min(count, bounds.upperBound))
      return self[start..<end]
   }
}
