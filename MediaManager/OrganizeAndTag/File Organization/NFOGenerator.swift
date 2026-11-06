//
//  NFOGenerator.swift
//  MediaManager
//
//  Copyright © 2026 JVSherwood. All rights reserved.
//

import Foundation

/// Generates NFO files for movies and TV episodes following Jellyfin standards
struct NFOGenerator {
    
    /// Generates an episode NFO file
    /// - Parameters:
    ///   - episode: Episode data
    ///   - showTitle: Title of the TV show
    ///   - season: Season number
    ///   - basePath: Base directory path
    /// - Returns: URL to the generated NFO file
    static func generateEpisodeNFO(
      preview: Bool,
        episode: Episode,
        showTitle: String,
        season: Int,
        basePath: URL
    ) throws -> URL {
        let filename = "\(episode.episodeNumber) - \(episode.title).nfo"
        let url = basePath.appendingPathComponent(filename)
        
       if !preview {
          // Create parent directory if needed
          try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
          )
          
          let content = generateEpisodeNFOContent(
            episode: episode,
            showTitle: showTitle,
            season: season
          )
          
          try content.write(to: url, atomically: true, encoding: .utf8)
       }
       
        return url
    }
    
    /// Generates a movie NFO file
    /// - Parameters:
    ///   - title: Movie title
    ///   - plot: Plot description
    ///   - year: Release year
    ///   - director: Director name
    ///   - runtime: Runtime in minutes
    ///   - basePath: Base directory path
    /// - Returns: URL to the generated NFO file
    static func generateMovieNFO(
      preview: Bool,
        title: String,
        plot: String?,
        year: Int?,
        director: String?,
        runtime: TimeInterval?,
        basePath: URL
    ) throws -> URL {
        let filename = "\(title).nfo"
        let url = basePath.appendingPathComponent(filename)
        
       if !preview {
          // Create parent directory if needed
          try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
          )
          
          let content = generateMovieNFOContent(
            title: title,
            plot: plot,
            year: year,
            director: director,
            runtime: runtime
          )
          
          try content.write(to: url, atomically: true, encoding: .utf8)
       }
        return url
    }
   
   /// Generates NFO content for a movie
   private static func generateMovieNFOContent(
      title: String,
      plot: String?,
      year: Int?,
      director: String?,
      runtime: TimeInterval?
   ) -> String {
      let runtimeStr = runtime.map {
         Int($0) > 0 ? String($0) : ""
      } ?? ""
      
      var content = """
        <?xml version="1.0" encoding="UTF-8"?>
        <movie>
            <title>\(escapeXML(title))</title>
            <plot>\(escapeXML(plot ?? ""))</plot>
            <runtime>\(runtimeStr)</runtime>
        </movie>
        """
      
      if let year = year {
         content = """
            <?xml version="1.0" encoding="UTF-8"?>
            <movie>
                <title>\(escapeXML(title))</title>
                <plot>\(escapeXML(plot ?? ""))</plot>
                <year>\(year)</year>
                <runtime>\(runtimeStr)</runtime>
            </movie>
            """
      }
      
      if let director = director {
         content = """
            <?xml version="1.0" encoding="UTF-8"?>
            <movie>
                <title>\(escapeXML(title))</title>
                <plot>\(escapeXML(plot ?? ""))</plot>
                \(year.map { "                <year>\($0)</year>\n" } ?? "")
                <director>\(escapeXML(director))</director>
                <runtime>\(runtimeStr)</runtime>
            </movie>
            """
      }
      
      return content
   }
   
    /// Generates NFO content for an episode
    private static func generateEpisodeNFOContent(
        episode: Episode,
        showTitle: String,
        season: Int
    ) -> String {
       
       let runtime: String
       if let duration = episode.duration {
          let divDuration3600 = duration.truncatingRemainder(dividingBy: 3600.0)
          let divDuration60 = duration.truncatingRemainder(dividingBy: 60.0)
          runtime = duration > 3600 ?
          String(format: "%d:%02d", duration / 3600.0, divDuration3600 / 60.0) :
          String(format: "%02d:%02d", (duration / 60.0).truncatingRemainder(dividingBy: 60.0), divDuration60)
       } else {
          runtime = "0:00"
       }
       
       let episodeTitle: String
       if let alternativeCut = episode.alternativeCut {
          let cutPart = alternativeCut ? "Alternative Cut" : ""
          episodeTitle = "\(escapeXML(episode.title)) - \(cutPart)"
       } else {
          episodeTitle = escapeXML(episode.title)
       }

       let plot: String
       if let episodePlot = episode.plot {
          //content += "            <plot>\(escapeXML(plot))</plot>\n"
          plot = "    \(escapeXML(episodePlot))"
       } else {
          plot = ""
       }

       let rating: String
       if let episodeRating = episode.rating {
          //content += "            <rating>\(escapeXML(rating))</rating>\n"
          rating = "    \(escapeXML(episodeRating))"
       } else {
          rating = ""
       }

       let content =
               """
               <?xml version="1.0" encoding="UTF-8"?>
               <episodedetails>
                   <showtitle>\(escapeXML(showTitle))</showtitle>
                   <title>\(episodeTitle)</title>
               \(plot)
                   <season>\(season)</season>
                   <episode>\(episode.episodeNumber)</episode>
                   <runtime>\(runtime)</runtime>
               \(rating)
               </episodedetails>
               """
       
       return content
    }
    
    /// Generates NFO content for a deleted scene extra
    private static func generateDeletedSceneNFOContent(
        episodeTitle: String?,
        sceneDescription: String,
        duration: TimeInterval
    ) -> String {
        let runtime = formatDuration(duration)
        let title = episodeTitle != nil ? "Deleted Scene - \(escapeXML(episodeTitle!)) - \(escapeXML(sceneDescription))" : "Deleted Scene - \(escapeXML(sceneDescription))"
        let content = """
        <?xml version="1.0" encoding="UTF-8"?>
        <episodedetails>
            <title>\(title)</title>
            <plot>\(escapeXML(sceneDescription))</plot>
            <runtime>\(runtime)</runtime>
        </episodedetails>
        """
        return content
    }
    
    /// Generates NFO content for a music video extra
    private static func generateMusicVideoNFOContent(
        artist: String,
        title: String,
        duration: TimeInterval
    ) -> String {
        let runtime = formatDuration(duration)
        let content = """
        <?xml version="1.0" encoding="UTF-8"?>
        <episodedetails>
            <title>\(escapeXML(artist)) - \(escapeXML(title))</title>
            <plot>Music video featuring \(escapeXML(artist))</plot>
            <runtime>\(runtime)</runtime>
        </episodedetails>
        """
        return content
    }
    
    /// Generates NFO content for a trailer extra
    private static func generateTrailerNFOContent(
        title: String,
        duration: TimeInterval
    ) -> String {
        let runtime = formatDuration(duration)
        let content = """
        <?xml version="1.0" encoding="UTF-8"?>
        <episodedetails>
            <title>Trailer - \(escapeXML(title))</title>
            <plot>Official trailer for \(escapeXML(title))</plot>
            <runtime>\(runtime)</runtime>
        </episodedetails>
        """
        return content
    }
    
    /// Generates NFO content for a featurette extra
    private static func generateFeaturetteNFOContent(
        title: String,
        description: String,
        duration: TimeInterval
    ) -> String {
        let runtime = formatDuration(duration)
        let content = """
        <?xml version="1.0" encoding="UTF-8"?>
        <episodedetails>
            <title>Featurette - \(escapeXML(title))</title>
            <plot>\(escapeXML(description))</plot>
            <runtime>\(runtime)</runtime>
        </episodedetails>
        """
        return content
    }
    
    /// Generates NFO for commentary tracks
    static func generateCommentaryNFO(
      title: String,
        plot: String,
        duration: TimeInterval,
        basePath: URL
    ) throws -> URL {
        let filename = "Commentary - \(escapeFilename(title)).nfo"
        let url = basePath.appendingPathComponent(filename)
        
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        
        let content = generateCommentaryNFOContent(
            title: title,
            plot: plot,
            duration: duration
        )
        
        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

   /// Generates NFO content for a commentary extra
   private static func generateCommentaryNFOContent(
      title: String,
      plot: String,
      duration: TimeInterval
   ) -> String {
      let runtime = formatDuration(duration)
      let content = """
        <?xml version="1.0" encoding="UTF-8"?>
        <episodedetails>
            <title>Featurette - \(escapeXML(title))</title>
            <plot>\(escapeXML(plot))</plot>
            <runtime>\(runtime)</runtime>
        </episodedetails>
        """
      return content
   }

    /// Generates NFO for deleted scenes
    static func generateDeletedSceneNFO(
        episodeTitle: String?,
        sceneDescription: String,
        duration: TimeInterval,
        basePath: URL
    ) throws -> URL {
        let filename = "Deleted Scene - \(escapeFilename(sceneDescription)).nfo"
        let url = basePath.appendingPathComponent(filename)
        
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        
        let content = generateDeletedSceneNFOContent(
            episodeTitle: episodeTitle,
            sceneDescription: sceneDescription,
            duration: duration
        )
        
        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
    
    /// Generates NFO for music videos
    static func generateMusicVideoNFO(
        artist: String,
        title: String,
        duration: TimeInterval,
        basePath: URL
    ) throws -> URL {
        let filename = "\(escapeFilename(artist)) - \(escapeFilename(title)).nfo"
        let url = basePath.appendingPathComponent(filename)
        
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        
        let content = generateMusicVideoNFOContent(
            artist: artist,
            title: title,
            duration: duration
        )
        
        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
    
    /// Generates NFO for trailers
    static func generateTrailerNFO(
        title: String,
        duration: TimeInterval,
        basePath: URL
    ) throws -> URL {
        let filename = "Trailer - \(escapeFilename(title)).nfo"
        let url = basePath.appendingPathComponent(filename)
        
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        
        let content = generateTrailerNFOContent(
            title: title,
            duration: duration
        )
        
        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
    
    /// Generates NFO for featurettes
    static func generateFeaturetteNFO(
        title: String,
        description: String,
        duration: TimeInterval,
        basePath: URL
    ) throws -> URL {
        let filename = "Featurette - \(escapeFilename(title)).nfo"
        let url = basePath.appendingPathComponent(filename)
        
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        
        let content = generateFeaturetteNFOContent(
            title: title,
            description: description,
            duration: duration
        )
        
        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
    
    /// Formats duration in seconds to HH:MM or MM:SS format
    private static func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration.truncatingRemainder(dividingBy: 3600)) / 60
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        
        if hours > 0 {
            return String(format: "%d:%02d", hours, minutes)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    /// Escapes special characters in filenames
    private static func escapeFilename(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: "\\", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: "|", with: "-")
            .replacingOccurrences(of: "?", with: "-")
            .replacingOccurrences(of: "*", with: "-")
            .replacingOccurrences(of: "<", with: "-")
            .replacingOccurrences(of: ">", with: "-")
            .replacingOccurrences(of: "\"", with: "-")
            .replacingOccurrences(of: "'", with: "-")
            .replacingOccurrences(of: " ", with: "-")
    }
    
    /// Escapes special XML characters
    private static func escapeXML(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "'", with: "&apos;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
