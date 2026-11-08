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
      preview: Bool,
        files: [FileItem],
        content: DVDCompareContent,
        basePath: URL,
        mergeStrategy: MergeStrategy = .rename
    ) -> OrganizationResults {
       var results = OrganizationResults()
       
        // Validate inputs
        guard !files.isEmpty else {
            results.warnings.append("No files found in base directory")
            return results
        }
        guard content.title.isEmpty == false else {
            results.warnings.append("Content title cannot be empty")
            return results
        }
        
        // Check disk space before proceeding
        let diskSpaceWarning = checkDiskSpace(at: basePath, required: 500_000_000) // 500MB minimum
        if let warning = diskSpaceWarning {
            results.warnings.append(warning)
        }

        // Create directory structure
       let seasonPath = basePath
//        let seasonPath = createSeasonDirectory(
//            for: content.season ?? 1,
//            at: basePath
//        )
        
       // Create extras directory
       let extrasPath = createExtrasDirectory(preview: preview,at: seasonPath)
       if !preview {
          // Create subdirectories for different extra types
          createExtraSubdirectories(at: extrasPath)
       }
       
       let startingEpisode: Int = content.episodes.min(by: { e1,e2 in e1.episodeNumber < e2.episodeNumber })?.episodeNumber ?? 1
       
        // Organize episodes
       organizeEpisodes(preview: preview,
                        files: files,
                        episodes: content.episodes,
                        startingEpisode: startingEpisode,
                        seasonPath: seasonPath,
                        mergeStrategy: mergeStrategy,
                        results: &results)
        
        // Organize extras
        organizeExtras(
         preview: preview,
            extras: content.commentaries + content.deletedScenes + content.musicVideos + content.trailers,
         files: files,
            basePath: extrasPath,
            mergeStrategy: mergeStrategy,
            results: &results
        )
       
       files.filter({ fileItem in
          !fileItem.isDirectory &&
          !results.filesMoved.contains(where: { movedFile in
             movedFile.src.url == fileItem.url
          })
       }).forEach({ remainingFile in
          let newFilename = extrasPath.appendingPathComponent(remainingFile.url.lastPathComponent)
          moveFile(preview: preview,
                   from: remainingFile.url,
                   to: newFilename,
                   mergeStrategy: mergeStrategy,
                   results: &results)
       })
        
        // Generate NFO files
        generateNFOFiles(
         preview: preview,
            episodes: content.episodes,
            showTitle: content.title,
            season: content.season ?? 1,
            basePath: seasonPath,
            mergeStrategy: mergeStrategy,
            results: &results
        )
        
        return results
    }
   
   /**
    Rework matching SecKeyAlgorithm
    Reduce set of files to the set of episodes
    Throw out outliers
    Does count of files == count of episodes, match them
    If greater take first N
    If less take first n, report gaps
    */
   private static func organizeEpisodes(preview: Bool,
                                        files: [FileItem],
                                        episodes: [Episode],
                                        startingEpisode: Int,
                                        seasonPath: URL,
                                        mergeStrategy: MergeStrategy,
                                        results: inout OrganizationResults) {
      // Filter down to mkv files of a certain size in name sorted order
      let orderedMKV = files
         .filter({ fileItem in
            // By type (mkv) duration must be some min and duration must be found in the set of episodes
            if (fileItem.contentType != .mkv) {
               return false
            }
            
            var durationsExist: Bool = false
            let exists = episodes.contains(where: { episode in
               if let episode_duration = episode.duration {
                  durationsExist = true
                  let diff = abs(episode_duration - (fileItem.durationInSeconds ?? 0))
                  return (diff < (60.0*3.0)) // Is the duration within n minutes
               } else {
                  return false
               }
            })
            
            if exists {
               return true
            } else {
               if ( !durationsExist ) {
                  return (fileItem.durationInSeconds ?? 0) >= (60.0*18.0) // n minutes or more
               } else {
                  return false
               }
            }
         })
         .sorted(by: {
            f1,f2 in f1.name < f2.name
         })
      
      if orderedMKV.count == episodes.count {
         // Exact set.
         for counter in 0..<episodes.count {
            organizeEpisode(
               preview: preview,
               minEpisodeNumber: startingEpisode,
               episode: episodes[counter],
               files: [orderedMKV[counter]],
               basePath: seasonPath,
               mergeStrategy: mergeStrategy,
               direct: true,
               results: &results
            )
         }
      } else {
         for episode in episodes {
            organizeEpisode(
               preview: preview,
               minEpisodeNumber: startingEpisode,
               episode: episode,
               files: files,
               basePath: seasonPath,
               mergeStrategy: mergeStrategy,
               direct: false,
               results: &results
            )
         }
      }
   }
    
    /// Organizes a movie according to the parsed content
    /// - Parameters:
    ///   - files: Array of files to organize
    ///   - content: Parsed DVDCompare content
    ///   - basePath: Base directory path
    ///   - mergeStrategy: How to handle existing files
    /// - Returns: Results of the organization operation
   static func organizeMovie(
      preview: Bool,
      files: [FileItem],
      content: DVDCompareContent,
      basePath: URL,
      mergeStrategy: MergeStrategy = .rename
   ) -> OrganizationResults {
      
      var results = OrganizationResults()
      
      // Create extras directory
      let extrasPath = createExtrasDirectory(preview: preview, at: basePath)
      
      // Find and move main movie (longest file)
      if let mainMovie = findMainMovie(files: files, content: content) {
         moveFile(
            preview: preview,
            from: mainMovie.url,
            to: basePath.appendingPathComponent(mainMovie.name),
            mergeStrategy: mergeStrategy,
            results: &results
         )
         
         // Generate movie NFO
         generateMovieNFO(
            preview: preview,
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
         preview: preview,
         extras: content.extras,
         files: files,
         basePath: extrasPath,
         mergeStrategy: mergeStrategy,
         results: &results
      )
      
      files.filter({ fileItem in
         !fileItem.isDirectory &&
         !results.filesMoved.contains(where: { movedFile in
            movedFile.src.url == fileItem.url
         })
      }).forEach({ remainingFile in
         let newFilename = extrasPath.appendingPathComponent(remainingFile.url.lastPathComponent)
         moveFile(preview: preview,
                  from: remainingFile.url,
                  to: newFilename,
                  mergeStrategy: mergeStrategy,
                  results: &results)
      })
      
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
   private static func createExtrasDirectory(preview: Bool,
                                             at basePath: URL) -> URL {
      let extrasPath = basePath.appendingPathComponent("extras")
      if preview {
         return extrasPath
      }
      
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
      preview: Bool,
      minEpisodeNumber: Int,
      episode: Episode,
      files: [FileItem],
      basePath: URL,
      mergeStrategy: MergeStrategy,
      direct: Bool,
      results: inout OrganizationResults
    ) {
       let fileItem: FileItem
       if !direct {
          // Find matching file
          guard let file = findMatchingFile(
            files: files,
            minEpisodeNumber: minEpisodeNumber,
            episode: episode,
          ) else {
             results.warnings.append("No matching file found for: \(episode.title)")
             return
          }
          
          fileItem = file
       } else {
          fileItem = files[0]
       }

        // Generate new filename
        let newFilename = generateEpisodeFilename(
            episode: episode,
        )
        
       // Move and rename file
       let destination = basePath.appendingPathComponent(newFilename+"."+fileItem.url.pathExtension)
       moveFile(
         preview: preview,
         from: fileItem.url,
         to: destination,
         mergeStrategy: mergeStrategy,
         results: &results
       )
    }
    
    /// Organizes extras
    private static func organizeExtras(
      preview: Bool,
        extras: [Extra],
      files: [FileItem],
        basePath: URL,
        mergeStrategy: MergeStrategy,
        results: inout OrganizationResults
    ) {
        for extra in extras {
            // Find matching file
            guard let file = findMatchingFile(
                files: files,
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
            preview: preview,
            from: file.url,
            to: destination,
            mergeStrategy: mergeStrategy,
            results: &results
           )
        }
    }
    
    /// Generates NFO files for episodes
    private static func generateNFOFiles(
      preview: Bool,
        episodes: [Episode],
        showTitle: String,
        season: Int,
        basePath: URL,
        mergeStrategy: MergeStrategy,
        results: inout OrganizationResults
    ) {
       for episode in episodes {
          let filename = "\(String(format: "%02d", episode.episodeNumber)) - \(episode.title).nfo"
          let url = basePath.appendingPathComponent(filename)
          
          do {
             // Check if NFO already exists
             if FileManager.default.fileExists(atPath: url.path) {
                switch mergeStrategy {
                case .replace:
                   try NFOGenerator.generateEpisodeNFO(
                     preview: preview,
                     episode: episode,
                     showTitle: showTitle,
                     season: season,
                     url: url
                   )
                   results.nfoFilesCreated.append(url)
                case .skip:
                   continue
                case .rename:
                   let oldURL = url
                   let newURL = url.deletingLastPathComponent()
                      .appendingPathComponent("\(url.lastPathComponent) (Old)")
                   if !preview {
                      try FileManager.default.moveItem(at: oldURL, to: newURL)
                   }
                   try NFOGenerator.generateEpisodeNFO(
                     preview: preview,
                     episode: episode,
                     showTitle: showTitle,
                     season: season,
                     url: url
                   )
                   results.nfoFilesCreated.append(url)
                case .mergeMetadata:
                   // Would merge with existing NFO
                   results.warnings.append("Merging metadata with existing NFO: \(filename)")
                }
             } else {
                try NFOGenerator.generateEpisodeNFO(
                  preview: preview,
                  episode: episode,
                  showTitle: showTitle,
                  season: season,
                  url: url
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
      preview: Bool,
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
                    _ = try NFOGenerator.generateMovieNFO(
                     preview: preview,
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
                   _ = try NFOGenerator.generateMovieNFO(
                     preview: preview,
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
               _ = try NFOGenerator.generateMovieNFO(
                  preview: preview,
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
        minEpisodeNumber: Int,
        episode: Episode,
    ) -> FileItem? {
       // Filter down to mkv files of a certain size in name sorted order
       let orderedMKV = files
          .filter({
             if ($0.contentType != .mkv) {
                return false
             }

             if let episode_duration = episode.duration {
                let diff = abs(episode_duration - ($0.durationInSeconds ?? 0))
                return (diff < (60.0*3.0)) // Is the duration within n minutes
             } else {
                return ($0.durationInSeconds ?? 0) >= (60.0*18.0) // n minutes or more
             }
          })
          .sorted(by: {
             f1,f2 in f1.name < f2.name
          })
       
       // Simple matching by title
       let lowerTitle = episode.title.lowercased()
       for file in orderedMKV {
            let lowerName = file.name.lowercased()
            
            if lowerName.contains(lowerTitle) || lowerTitle.contains(lowerName) {
                return file
            }
        }
       
       // No name match? What about order, find ordered item
       if ((episode.episodeNumber-minEpisodeNumber) < orderedMKV.count) {
          return orderedMKV[episode.episodeNumber-minEpisodeNumber]
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
        //alternativeCut: Bool? = nil
    ) -> String {
        var filename = "\(String(format: "%02d", episode.episodeNumber)) - \(episode.title)"
        
       if episode.isAlternativeCut,
          let alternativeCut = episode.alternativeCut {
            filename += " - " + alternativeCut
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
      preview: Bool,
        from source: URL,
        to destination: URL,
        mergeStrategy: MergeStrategy,
        results: inout OrganizationResults
    ) {
            // Check if destination already exists
        if FileManager.default.fileExists(atPath: destination.path) {
            switch mergeStrategy {
            case .replace:
               if !preview {
                  try? FileManager.default.removeItem(at: destination)
               }
               // Fall through to move
                break
            case .skip:
                // Skip moving
                results.warnings.append("Skipped moving: \(source.lastPathComponent) - destination exists")
                return
            case .rename:
                // Rename existing file
               if !preview {
                  let existingFile = destination.deletingLastPathComponent()
                     .appendingPathComponent("\(destination.lastPathComponent) (Old)")
                  try? FileManager.default.moveItem(at: destination, to: existingFile)
               }
                fallthrough
            case .mergeMetadata:
                // Fall through to move
                break
            }
        }
        
        do {
           if !preview {
              try FileManager.default.moveItem(at: source, to: destination)
           }
           let movedFile = OrganizationResults.MovedFile(src: FileItem(url: source),dst: FileItem(url: destination))
           results.filesMoved.append(movedFile)
        } catch {
            results.errors.append("Failed to move \(source.lastPathComponent): \(error.localizedDescription)")
        }
    }
   
   /// Check available disk space
   private static func checkDiskSpace(at url: URL, required: UInt64) -> String? {
      do {
         let resourceValues = try url.resourceValues(forKeys: [.volumeAvailableCapacityKey])
         if let available = resourceValues.volumeAvailableCapacity {
            if available < required {
               let availableMB = Double(available) / (1024 * 1024)
               return "Insufficient disk space. Available: \(String(format: "%.1f", availableMB)) MB, Required: \(required / (1024 * 1024)) MB"
            }
         }
      } catch {
         print("Failed to check disk space: \(error.localizedDescription)")
      }
      return nil
   }
}
