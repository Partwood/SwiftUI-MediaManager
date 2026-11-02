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
        episode: Episode,
        showTitle: String,
        season: Int,
        basePath: URL
    ) throws -> URL {
        let filename = "\(episode.episodeNumber) - \(episode.title).nfo"
        let url = basePath.appendingPathComponent(filename)
        
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
        title: String,
        plot: String?,
        year: Int?,
        director: String?,
        runtime: TimeInterval?,
        basePath: URL
    ) throws -> URL {
        let filename = "\(title).nfo"
        let url = basePath.appendingPathComponent(filename)
        
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
        return url
    }
    
    /// Generates NFO content for an episode
    private static func generateEpisodeNFOContent(
        episode: Episode,
        showTitle: String,
        season: Int
    ) -> String {
       let divDuration3600 = episode.duration.truncatingRemainder(dividingBy: 3600.0)
       let divDuration60 = episode.duration.truncatingRemainder(dividingBy: 60.0)
        let runtime = episode.duration > 3600 ?
       String(format: "%d:%02d", episode.duration / 3600.0, divDuration3600 / 60.0) :
       String(format: "%02d:%02d", (episode.duration / 60.0).truncatingRemainder(dividingBy: 60.0), divDuration60)
        
        var content = """
        <?xml version="1.0" encoding="UTF-8"?>
        <episodedetails>
            <title>\(escapeXML(episode.title))</title>
            <showtitle>\(escapeXML(showTitle))</showtitle>
            <season>\(season)</season>
            <episode>\(episode.episodeNumber)</episode>
            <runtime>\(runtime)</runtime>
        </episodedetails>
        """
        
        if let alternativeCut = episode.alternativeCut {
           let cutPart = alternativeCut ? "Alternative Cut" : ""
            content += "            <title>\(escapeXML(episode.title)) - \(cutPart)</title>\n"
        }
        
        if let plot = episode.plot {
            content += "            <plot>\(escapeXML(plot))</plot>\n"
        }
        
        if let rating = episode.rating {
            content += "            <rating>\(escapeXML(rating))</rating>\n"
        }
        
        return content
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
        
        let content = """
        <?xml version="1.0" encoding="UTF-8"?>
        <movie>
            <title>\(escapeXML(title))</title>
            <plot>\(escapeXML(plot ?? ""))</plot>
            \(year.map { "            <year>\($0)</year>\n" } ?? "")
            \(director.map { "            <director>\(escapeXML($0))</director>\n" } ?? "")
            <runtime>\(runtimeStr)</runtime>
        </movie>
        """
        
        return content
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
