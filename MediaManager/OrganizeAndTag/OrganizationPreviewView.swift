//
//  OrganizationPreviewView.swift
//  MediaManager
//
//  Copyright © 2026 JVSherwood. All rights reserved.
//

import SwiftUI

/// Preview view showing what will be organized
struct OrganizationPreviewView: View {
    let preview: OrganizationPreview
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("\(preview.mediaType.displayName): \(preview.title)")
                    .font(.headline)
                
                if let season = preview.season {
                    Text("Season \(season)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Preview Content
            if preview.episodes.isEmpty && preview.extras.isEmpty {
                Text("No content to organize")
                    .foregroundColor(.secondary)
            } else {
                // Episodes
                if !preview.episodes.isEmpty {
                    Section("Episodes") {
                        ForEach(preview.episodes) { episode in
                            HStack {
                                Text("Episode \(episode.episodeNumber): \(episode.title)")
                                Spacer()
                                Text(DurationParser.format(episode.duration))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Commentaries
                if !preview.commentaries.isEmpty {
                    Section("Commentaries") {
                        ForEach(preview.commentaries) { commentary in
                            Text("Commentary - \(commentary.title)")
                        }
                    }
                }
                
                // Deleted Scenes
                if !preview.deletedScenes.isEmpty {
                    Section("Deleted Scenes") {
                        ForEach(preview.deletedScenes) { scene in
                            Text("Deleted Scene - \(scene.title)")
                        }
                    }
                }
                
                // Music Videos
                if !preview.musicVideos.isEmpty {
                    Section("Music Videos") {
                        ForEach(preview.musicVideos) { video in
                            Text(video.title)
                        }
                    }
                }
                
                // Trailers
                if !preview.trailers.isEmpty {
                    Section("Trailers") {
                        ForEach(preview.trailers) { trailer in
                            Text(trailer.title)
                        }
                    }
                }
                
                // Extras
                if !preview.extras.isEmpty {
                    Section("Extras") {
                        ForEach(preview.extras) { extra in
                            Text("\(extra.extraType.displayName) - \(extra.title)")
                        }
                    }
                }
                
                // Movie Info
                if preview.mediaType == .movie, let director = preview.director {
                    Section("Movie Information") {
                        HStack {
                            Text("Director: \(director)")
                            Spacer()
                            if let year = preview.year {
                                Text("Year: \(year)")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            
            // Summary
            HStack(spacing: 12) {
                Button("Back") {
                    // Navigate back
                }
                .buttonStyle(.bordered)
                
                Button("Confirm & Organize") {
                    // Navigate to confirmation
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

#Preview {
    OrganizationPreviewView(preview: OrganizationPreview(
        mediaType: .tvShow,
        title: "Test Show",
        season: 1,
        episodes: [],
        commentaries: [],
        deletedScenes: [],
        musicVideos: [],
        trailers: [],
        extras: [],
        director: nil,
        year: nil
    ))
}

/// Preview data structure
struct OrganizationPreview {
   let mediaType: MediaType
   let title: String
   let season: Int?
   let episodes: [Episode]
   let commentaries: [Extra]
   let deletedScenes: [Extra]
   let musicVideos: [Extra]
   let trailers: [Extra]
   let extras: [Extra]
   let director: String?
   let year: Int?
}
