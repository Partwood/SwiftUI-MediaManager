//
//  ImportPanelView.swift
//  MediaManager
//
//  Copyright © 2026 JVSherwood. All rights reserved.
//

import SwiftUI

/// Main UI panel for importing and configuring organization
struct ImportPanelView: View {
   @StateObject private var viewModel = ImportPanelViewModel()

   @State var showtitle: String = ""
   @State var selectedMediaType: MediaType = .tvShow
   @State var basePath: URL = URL(fileURLWithPath: "/Users")
   @State var mergeStrategy: MergeStrategy = .rename
   @State var isShowingFolderPicker: Bool = false
   
   @Binding var fileSystem: FileSystem
   
   @Binding var seasonNumber: Int
   @Binding var episodeNumber: Int
   @Binding var showOrganizePanel: Bool
   @Binding var organizationPreview: OrganizationPreview?
   @Binding var organizationResults: OrganizationResults?
   @Binding var appTab: OrganizeAndTagView.AppTab
   @Binding var content: String
   
    var body: some View {
        Form {
            // Content Type Selection
            Section(header: Text("Content Type")) {
                Picker("Type", selection: $selectedMediaType) {
                    Text("TV Show").tag(MediaType.tvShow)
                    Text("Movie").tag(MediaType.movie)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Show Information
            Section(header: Text("Show Information")) {
                if selectedMediaType == .tvShow {
                    TextField("Show Title", text: $showtitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Stepper("Season: \(seasonNumber)", value: $seasonNumber, in: 1...10)
                   Stepper("Start Episode: \(episodeNumber)", value: $episodeNumber, in: 1...31)
                } else {
                    TextField("Movie Title", text: $showtitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            
            // Base Directory
            Section(header: Text("Base Directory")) {
                VStack {
                   Text(basePath.filePath)
                      .font(.headline)
                   
                   Button("Cleanup Directory") {
                      cleanup()
                   }
                }
            }
            
            // Merge Strategy
            Section(header: Text("Merge Strategy")) {
                Picker("How to handle existing files", selection: $mergeStrategy) {
                    ForEach(MergeStrategy.allCases, id: \.self) { strategy in
                        Text(strategy.rawValue).tag(strategy)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Paste Content
            Section(header: Text("Paste Content")) {
                TextEditor(text: $content)
                    .frame(minHeight: 300)
            }
            
            // Actions
            Section {
                Button("Parse & Preview") {
                   viewModel.parse(content: content, mediaType: selectedMediaType, startingEpisode: episodeNumber)
                   self.organizationPreview = viewModel.organizationPreview
                   
                   if (self.organizationPreview == nil) {
                      // No preview
                      var results = OrganizationResults()

                      viewModel.parsingWarnings.forEach({ warning in
                         results.errors.append(warning)
                      })

                      self.organizationResults = results
                      
                      self.appTab = .results
                   } else {
                      let organizeAndTagViewModel = OrganizeAndTagViewModel()
                      organizeAndTagViewModel.organizationPreview = viewModel.organizationPreview
                      
                      fileSystem.accessURL(basePath, { accessibleURL in
                         guard let url = accessibleURL else { return }
                         
                         do {
                            self.organizationResults = try organizeAndTagViewModel.executeOrganization(
                              fileSystem: fileSystem,
                              preview: true,
                              basePath: url,
                              mergeStrategy: mergeStrategy)
                         } catch {
                            logError(error)
                            
                            var results = OrganizationResults()
                            results.errors.append(error.localizedDescription)
                            self.organizationResults = results
                         }
                      })
                      self.appTab = .preview_view
                   }
                   
                   debug("Parsed")
                }
                .buttonStyle(.borderedProminent)
                
                Button("Cancel") {
                    // Cancel action
                   showOrganizePanel = false
                }
                .buttonStyle(.bordered)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Import Metadata")
        .onAppear {
            viewModel.loadSampleContent()
           searchEpisodeNumbers()
        }
    }

   /**
     Get the content of parent in sorted order
     Find dir before 'here'
     Read the nfo files if present, get season and highest episode number
     Set season and highest+1
    */
   private func searchEpisodeNumbers() {
      fileSystem.accessURL(basePath, { inPath in
         guard let currentPath = inPath else {
            // No path
            return
         }
         
         do {
            let parentPath = currentPath.deletingLastPathComponent()
            let siblings = try fileSystem.listDirectory(at: parentPath.filePath)
            let sortedSiblings = siblings.sorted(by: { s1,s2 in s1.name < s2.name })
            if let myIndex = sortedSiblings.firstIndex(where: { file in file.name == currentPath.lastPathComponent }) {
               if myIndex == sortedSiblings.startIndex {
                  // We are the first directory.
                  return
               }
               
               let priorIndex = sortedSiblings.index(before: myIndex)
               let prior = sortedSiblings[priorIndex]
               
               let siblingContent = try fileSystem.listDirectory(at: prior.url.filePath)
               
               var highestSeason: Int = 1
               var highestEpisode: Int = 1
               
               siblingContent.forEach({ siblingContentFile in
                  if siblingContentFile.url.pathExtension != "nfo" {
                     return
                  }
                  
                  do {
                     let metadata = try NFOParser().parseNFOMetadata(fileSystem, siblingContentFile.url)
                     
                     highestSeason = max(highestSeason, metadata.metadata.seasonNumber ?? 1)
                     highestEpisode = max(highestEpisode, metadata.metadata.episodeNumber ?? 1)
                  } catch {
                     logError(error)
                  }
               })
               
               self.seasonNumber = highestSeason
               self.episodeNumber = highestEpisode+1
            }
         } catch {
            logError(error)
         }
      })
   }
   
   private func cleanup() {
      debug("Cleanup")
      fileSystem.accessURL(basePath, { inPath in
         guard let cleanupPath = inPath else {
            return
         }
         
         do {
            let contents = try fileSystem.listDirectory(at: cleanupPath.filePath)
            if contents.count == 1,
               let content = contents.first {
               if ( content.isDirectory && (content.name == "Disc01" || content.name == "Disc 01" || content.name == "Disc_01" )) {
                  let children = try fileSystem.listDirectory(at: content.url.filePath)
                  children.forEach({ child in
                     let dst: URL = cleanupPath.appending(path: child.url.lastPathComponent)
                     do {
                        try fileSystem.moveFile(src: child.url, dst: dst)
                     } catch {
                        logError(error)
                     }
                  })
                  
                  let remainingChildren = try fileSystem.listDirectory(at: content.url.filePath)
                  if ( remainingChildren.count == 0 ) {
                     try fileSystem.delete(src: content.url)
                  }
               }
            }
         } catch {
            logError(error)
         }
         
         showOrganizePanel = false
      })
   }
}

#Preview {
   @Previewable @State var seasonNumber: Int = 1
   @Previewable @State var episodeNumber: Int = 1
   @Previewable @State var showOrganizePanel: Bool = false
   @Previewable @State var organizationPreview: OrganizationPreview? = nil
   @Previewable @State var organizationResults: OrganizationResults? = nil
   @Previewable @State var appTab: OrganizeAndTagView.AppTab = .import_view
   @Previewable @State var content: String = ""
   
   @Previewable @State var fileSystem = FileSystem(URL(fileURLWithPath: "/Users"))
   
   ImportPanelView(
      fileSystem: $fileSystem,
      seasonNumber: $seasonNumber,
      episodeNumber: $episodeNumber,
      showOrganizePanel: $showOrganizePanel,
      organizationPreview: $organizationPreview,
      organizationResults: $organizationResults,
      appTab: $appTab,
      content: $content,
   )
}
