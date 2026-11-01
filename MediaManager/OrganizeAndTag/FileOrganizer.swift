//
//  FileOrganizer.swift
//  MediaManager
//
//  Copyright © 2026 JVSherwood. All rights reserved.
//

import Foundation
import AppKit

/// Organizes files according to parsed DVDCompare content
struct FileOrganizer {
    
    /// Organizes a TV show according to the parsed content
    /// - Parameters:
    ///   - files: Array of files to organize
    ///   - content: Parsed DVDCompare content
    ///   - basePath: Base directory path
    ///   - mergeStrategy: How to handle existing files
    /// - Returns: Results of the organization operation
    static func organizeTVShow(
        files: [FileItem],
        content: DVDCompareContent,
        basePath: URL,
        mergeStrategy: MergeStrategy = .rename
    ) -> OrganizationResults {
        
        var results = OrganizationResults()
        
        // Create directory structure
        let seasonPath = createSeasonDirectory(
            for: content.season ?? 1,
            at: basePath
        )
        
        // Create extras directory
        let extrasPath = createExtrasDirectory(at: seasonPath)
        
        // Create subdirectories for different extra types
        createExtraSubdirectories(at: extrasPath)
        
        // Organize episodes
        for episode in content.episodes {
            organizeEpisode(
                episode: episode,
                files: files,
                basePath: seasonPath,
                mergeStrategy: mergeStrategy,
                results: &results
            )
        }
        
        // Organize extras
        organizeExtras(
            extras: content.commentaries + content.deletedScenes + content.musicVideos + content.trailers,
            basePath: extrasPath,
            mergeStrategy: mergeStrategy,
            results: &results
        )
        
        // Generate NFO files
        generateNFOFiles(
            episodes: content.episodes,
            showTitle: content.title,
            season: content.season ?? 1,
            basePath: seasonPath,
            mergeStrategy: mergeStrategy,
            results: &results
        )
        
        return results
    }
    
    /// Organizes a movie according to the parsed content
    /// - Parameters:
    ///   - files: Array of files to organize
    ///   - content: Parsed DVDCompare content
    ///   - basePath: Base directory path
    ///   - mergeStrategy: How to handle existing files
    /// - Returns: Results of the organization operation
    static func organizeMovie(
        files: [FileItem],
        content: DVDCompareContent,
        basePath: URL,
        mergeStrategy: MergeStrategy = .rename
    ) -> OrganizationResults {
        
        var results = OrganizationResults()
        
        // Create extras directory
        let extrasPath = createExtrasDirectory(at: basePath)
        
        // Find and move main movie (longest file)
        if let mainMovie = findMainMovie(files: files, content: content) {
            moveFile(
                from: mainMovie.url,
                to: basePath.appendingPathComponent(mainMovie.name),
                mergeStrategy: mergeStrategy,
                results: &results
            )
            
            // Generate movie NFO
            generateMovieNFO(
                title: content.title,
                plot: content.plot,
                year: content.year,
                director: content.director,
                runtime: content.mainMovieDuration,
                basePath: basePath,
                mergeStrategy: mergeStrategy,
                results: &results
            )
        }
        
        // Organize extras
        organizeExtras(
            extras: content.extras,
            basePath: extrasPath,
            mergeStrategy: mergeStrategy,
            results: &results
        )
        
        return results
    }
    
    /// Creates a season directory
    private static func createSeasonDirectory(
        for season: Int,
        at basePath: URL
    ) -> URL {
        let seasonName = "Season \(season)"
        let seasonPath = basePath.appendingPathComponent(seasonName)
        
        do {
            try FileManager.default.createDirectory(
                at: seasonPath,
                withIntermediateDirectories: true
            )
            return seasonPath
        } catch {
            logError(error)
            return basePath
        }
    }
    
    /// Creates the extras directory
    private static func createExtrasDirectory(at basePath: URL) -> URL {
        let extrasPath = basePath.appendingPathComponent("extras")
        
        do {
            try FileManager.default.createDirectory(
                at: extrasPath,
                withIntermediateDirectories: true
            )
            return extrasPath
        } catch {
            logError(error)
            return basePath
        }
    }
    
    /// Creates subdirectories for different extra types
    private static func createExtraSubdirectories(at basePath: URL) {
        let extraTypes = [
            ExtraType.musicVideo,
            ExtraType.trailer,
            ExtraType.deletedScene,
            ExtraType.commentary
        ]
        
        for extraType in extraTypes {
            let subpath = basePath.appendingPathComponent(extraType.subdirectory)
            
            do {
                try FileManager.default.createDirectory(
                    at: subpath,
                    withIntermediateDirectories: true
                )
            } catch {
                // Ignore errors for subdirectories
            }
        }
    }
    
    /// Finds the main movie (longest file)
    private static func findMainMovie(
        files: [FileItem],
        content: DVDCompareContent
    ) -> FileItem? {
        // Sort files by duration (longest first)
       let sortedFiles = files.sorted(by: {a,b in (a.durationInSeconds ?? 0) > (b.durationInSeconds ?? 0) })
        
        // Return the longest file
        return sortedFiles.first
    }
    
    /// Organizes a single episode
    private static func organizeEpisode(
        episode: Episode,
        files: [FileItem],
        basePath: URL,
        mergeStrategy: MergeStrategy,
        results: inout OrganizationResults
    ) {
        // Find matching file
        guard let file = findMatchingFile(
            files: files,
            episode: episode,
            alternativeCut: episode.alternativeCut
        ) else {
            results.warnings.append("No matching file found for: \(episode.title)")
            return
        }
        
        // Generate new filename
        let newFilename = generateEpisodeFilename(
            episode: episode,
            alternativeCut: episode.alternativeCut
        )
        
        // Move and rename file
        let destination = basePath.appendingPathComponent(newFilename)
        moveFile(
            from: file.url,
            to: destination,
            mergeStrategy: mergeStrategy,
            results: &results
        )
        
        results.filesMoved.append(file)
    }
    
    /// Organizes extras
    private static func organizeExtras(
        extras: [Extra],
        basePath: URL,
        mergeStrategy: MergeStrategy,
        results: inout OrganizationResults
    ) {
        for extra in extras {
            // Find matching file
            guard let file = findMatchingFile(
                files: [], // Would need to scan directory
                extra: extra
            ) else {
                results.warnings.append("No matching file found for extra: \(extra.title)")
                continue
            }
            
            // Generate new filename
            let newFilename = generateExtraFilename(extra: extra)
            
            // Move and rename file
            let destination = basePath.appendingPathComponent(newFilename)
            moveFile(
                from: file.url,
                to: destination,
                mergeStrategy: mergeStrategy,
                results: &results
            )
            
            results.filesMoved.append(file)
        }
    }
    
    /// Generates NFO files for episodes
    private static func generateNFOFiles(
        episodes: [Episode],
        showTitle: String,
        season: Int,
        basePath: URL,
        mergeStrategy: MergeStrategy,
        results: inout OrganizationResults
    ) {
        for episode in episodes {
            let filename = "\(episode.episodeNumber) - \(episode.title).nfo"
            let url = basePath.appendingPathComponent(filename)
            
            do {
                // Check if NFO already exists
                if FileManager.default.fileExists(atPath: url.path) {
                    switch mergeStrategy {
                    case .replace:
                        let url = try NFOGenerator.generateEpisodeNFO(
                            episode: episode,
                            showTitle: showTitle,
                            season: season,
                            basePath: basePath
                        )
                        results.nfoFilesCreated.append(url)
                    case .skip:
                        continue
                    case .rename:
                        let oldURL = url
                        let newURL = url.deletingLastPathComponent()
                            .appendingPathComponent("\(url.lastPathComponent) (Old)")
                        try FileManager.default.moveItem(at: oldURL, to: newURL)
                       let url = try NFOGenerator.generateEpisodeNFO(
                            episode: episode,
                            showTitle: showTitle,
                            season: season,
                            basePath: basePath
                        )
                        results.nfoFilesCreated.append(url)
                    case .mergeMetadata:
                        // Would merge with existing NFO
                        results.warnings.append("Merging metadata with existing NFO: \(filename)")
                    }
                } else {
                   let url = try NFOGenerator.generateEpisodeNFO(
                        episode: episode,
                        showTitle: showTitle,
                        season: season,
                        basePath: basePath
                    )
                    results.nfoFilesCreated.append(url)
                }
            } catch {
                results.errors.append("Failed to create NFO: \(filename) - \(error.localizedDescription)")
            }
        }
    }
    
    /// Generates movie NFO
    private static func generateMovieNFO(
        title: String,
        plot: String?,
        year: Int?,
        director: String?,
        runtime: TimeInterval?,
        basePath: URL,
        mergeStrategy: MergeStrategy,
        results: inout OrganizationResults
    ) {
        let filename = "\(title).nfo"
        let url = basePath.appendingPathComponent(filename)
        
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                switch mergeStrategy {
                case .replace:
                    try NFOGenerator.generateMovieNFO(
                        title: title,
                        plot: plot,
                        year: year,
                        director: director,
                        runtime: runtime,
                        basePath: basePath
                    )
                    results.nfoFilesCreated.append(url)
                case .skip:
                    break
                case .rename:
                    let oldURL = url
                    let newURL = url.deletingLastPathComponent()
                        .appendingPathComponent("\(url.lastPathComponent) (Old)")
                    try FileManager.default.moveItem(at: oldURL, to: newURL)
                    try NFOGenerator.generateMovieNFO(
                        title: title,
                        plot: plot,
                        year: year,
                        director: director,
                        runtime: runtime,
                        basePath: basePath
                    )
                    results.nfoFilesCreated.append(url)
                case .mergeMetadata:
                    results.warnings.append("Merging metadata with existing NFO: \(filename)")
                }
            } else {
                try NFOGenerator.generateMovieNFO(
                    title: title,
                    plot: plot,
                    year: year,
                    director: director,
                    runtime: runtime,
                    basePath: basePath
                )
                results.nfoFilesCreated.append(url)
            }
        } catch {
            results.errors.append("Failed to create movie NFO: \(filename) - \(error.localizedDescription)")
        }
    }
    
    /// Finds a matching file for an episode
    private static func findMatchingFile(
        files: [FileItem],
        episode: Episode,
        alternativeCut: Bool? = nil
    ) -> FileItem? {
        // Simple matching by title
        let lowerTitle = episode.title.lowercased()
        
        for file in files {
            let lowerName = file.name.lowercased()
            
            if lowerName.contains(lowerTitle) || lowerTitle.contains(lowerName) {
                return file
            }
        }
        
        return nil
    }
    
    /// Finds a matching file for an extra
    private static func findMatchingFile(
        files: [FileItem],
        extra: Extra
    ) -> FileItem? {
        let lowerTitle = extra.title.lowercased()
        
        for file in files {
            let lowerName = file.name.lowercased()
            
            if lowerName.contains(lowerTitle) || lowerTitle.contains(lowerName) {
                return file
            }
        }
        
        return nil
    }
    
    /// Generates filename for an episode
    private static func generateEpisodeFilename(
        episode: Episode,
        alternativeCut: Bool? = nil
    ) -> String {
        var filename = "\(String(format: "%02d", episode.episodeNumber)) - \(episode.title)"
        
        if let alternativeCut = alternativeCut, alternativeCut {
            filename += " - Alternative Cut"
        }
        
        return filename
    }
    
    /// Generates filename for an extra
    private static func generateExtraFilename(extra: Extra) -> String {
        let prefix = extra.extraType.displayName.lowercased().replacingOccurrences(of: " ", with: "- ")
        let filename = "\(prefix) - \(extra.title)"
        
        return filename
    }
    
    /// Moves a file with optional rename
    private static func moveFile(
        from source: URL,
        to destination: URL,
        mergeStrategy: MergeStrategy,
        results: inout OrganizationResults
    ) {
        // Check if destination already exists
        if FileManager.default.fileExists(atPath: destination.path) {
            switch mergeStrategy {
            case .replace:
                try? FileManager.default.removeItem(at: destination)
                fallthrough
            case .skip:
                // Skip moving
                results.warnings.append("Skipped moving: \(source.lastPathComponent) - destination exists")
                return
            case .rename:
                // Rename existing file
                let existingFile = destination.deletingLastPathComponent()
                    .appendingPathComponent("\(destination.lastPathComponent) (Old)")
                try? FileManager.default.moveItem(at: destination, to: existingFile)
                fallthrough
            case .mergeMetadata:
                // Fall through to move
                break
            }
        }
        
        do {
            try FileManager.default.moveItem(at: source, to: destination)
            results.filesMoved.append(FileItem(url: source))
        } catch {
            results.errors.append("Failed to move \(source.lastPathComponent): \(error.localizedDescription)")
        }
    }
}
