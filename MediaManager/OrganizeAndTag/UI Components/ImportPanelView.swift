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

   @State var content: String = ""
   @State var showTitle: String = ""
   @State var selectedMediaType: MediaType = .tvShow
   @State var seasonNumber: Int = 1
   @State var episodeNumber: Int = 1
   @State var basePath: URL = URL(fileURLWithPath: "/Users")
   @State var mergeStrategy: MergeStrategy = .rename
   @State var isShowingFolderPicker: Bool = false
   
   @Binding var showOrganizePanel: Bool
   @Binding var organizationPreview: OrganizationPreview?
   @Binding var organizationResults: OrganizationResults?
   @Binding var appTab: OrganizeAndTagView.AppTab
   
   let fileSystem: FileSystem
   
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
                    TextField("Show Title", text: $showTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Stepper("Season: \(seasonNumber)", value: $seasonNumber, in: 1...10)
                   Stepper("Start Episode: \(episodeNumber)", value: $episodeNumber, in: 1...14)
                } else {
                    TextField("Movie Title", text: $showTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            
            // Base Directory
            Section(header: Text("Base Directory")) {
                VStack {
                    Text(basePath.lastPathComponent)
                    .font(.headline)
                    
                   Button("Browse...") {
                      let panel = NSOpenPanel()
                      panel.allowsMultipleSelection = false
                      panel.canChooseDirectories = true
                      panel.canChooseFiles = false
                      panel.message = "Select base directory for organization"
                      
                      if panel.runModal() == .OK, let url = panel.url {
                         basePath = url
                         isShowingFolderPicker = false
                         if showTitle.isEmpty {
                            showTitle = basePath.lastPathComponent
                         }
                      }
                   }
                    //.sheet(isPresented: $isShowingFolderPicker) {
                    //}
                       // Implement file picker
                    //}
                    .buttonStyle(.bordered)
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
                   
                   let organizeAndTagViewModel = OrganizeAndTagViewModel()
                   organizeAndTagViewModel.organizationPreview = viewModel.organizationPreview
                   
                   fileSystem.accessURL(basePath, { accessibleURL in
                      guard let url = accessibleURL else { return }
                      
                      do {
                         self.organizationResults = try organizeAndTagViewModel.executeOrganization(
                           preview: true,
                           mediaType: selectedMediaType,
                           showTitle: showTitle,
                           season: seasonNumber,
                           basePath: url,
                           mergeStrategy: mergeStrategy)
                      } catch {
                         logError(error)
                      }
                   })
                   
                   self.appTab = .preview_view
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
        }
    }
}

#Preview {
   @Previewable @State var showOrganizePanel: Bool = false
   @Previewable @State var organizationPreview: OrganizationPreview? = nil
   @Previewable @State var organizationResults: OrganizationResults? = nil
   @Previewable @State var appTab: OrganizeAndTagView.AppTab = .import_view
   
   let fileSystem = FileSystem(URL(fileURLWithPath: "/Users"))
   
   ImportPanelView(
      showOrganizePanel: $showOrganizePanel,
      organizationPreview: $organizationPreview,
      organizationResults: $organizationResults,
      appTab: $appTab,
      fileSystem: fileSystem
   )
}
