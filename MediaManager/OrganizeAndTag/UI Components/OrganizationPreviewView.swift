//
//  OrganizationPreviewView.swift
//  MediaManager
//
//  Copyright © 2026 JVSherwood. All rights reserved.
//

import SwiftUI
import Combine

/// Preview view showing what will be organized
struct OrganizationPreviewView: View {
   @State private var showConfirmationDialog: Bool = false
   @State private var selectedMediaType: MediaType = .tvShow
   @State private var showTitle: String = ""
   @State private var seasonNumber: Int = 1
   @State private var isShowingFolderPicker: Bool = false
   
   @Binding var appTab: OrganizeAndTagView.AppTab
   
   let preview: OrganizationPreview
   let basePath: URL
   let mergeStrategy: MergeStrategy
   let results: OrganizationResults

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
         
         // Configuration
         Form {
            // Show Information
            Section(header: Text("Show Information")) {
               // Preview Content
               if preview.episodes.isEmpty && preview.extras.isEmpty {
                  // If tv show then needs episodes, if movie then needs extras (otherwise nothing to move)
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
            }
            
            Section(header: Text("Merge Strategy")) {
               Text("\(mergeStrategy.description)")
            }
            
            // Base Directory
            Section(header: Text("Base Directory")) {
               VStack {
                  Text(basePath.lastPathComponent)
                     .font(.headline)
               }
            }
         }
         .frame(width: 400)
         
         // Summary
         HStack(spacing: 12) {
            Button("Back") {
               // Navigate back
               self.appTab = .import_view
            }
            .buttonStyle(.bordered)
            
            Button("Confirm & Organize") {
               showConfirmationDialog = true
            }
            .buttonStyle(.borderedProminent)
         }
      }
      .padding()
      .sheet(isPresented: $showConfirmationDialog) {
         ConfirmationDialog(
            results: results,
            mediaType: selectedMediaType,
            title: showTitle
         )
      }
   }
}

#Preview {
   @Previewable @State var appTab: OrganizeAndTagView.AppTab = .import_view
   
   let preview = OrganizationPreview(
      mediaType: .tvShow,
      title: "Test Show",
      mainMovieDuration: nil,
      season: 1,
      episodes: [],
      commentaries: [],
      deletedScenes: [],
      musicVideos: [],
      trailers: [],
      extras: [],
      director: nil,
      year: nil
   )
   
   let results = OrganizationResults(filesMoved: [], nfoFilesCreated: [], warnings: [], errors: [])
   
   OrganizationPreviewView(appTab: $appTab,
                           preview: preview,
                           basePath: URL(fileURLWithPath: "/Users"),
                           mergeStrategy: .rename,
                           results: results)
}
