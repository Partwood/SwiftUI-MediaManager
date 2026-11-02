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
    
    @State private var content: String = ""
    @State private var showTitle: String = ""
    @State private var selectedMediaType: MediaType = .tvShow
    @State private var seasonNumber: Int = 1
   @State private var episodeNumber: Int = 1
    @State private var basePath: URL = URL(fileURLWithPath: "/Users")
    @State private var mergeStrategy: MergeStrategy = .rename
   @State private var isShowingFolderPicker: Bool = false
   @State private var organizationPreview: OrganizationPreview? = nil
    
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
                   self.organizationPreview = nil
                   viewModel.parse(content: content, mediaType: selectedMediaType, startingEpisode: episodeNumber)
                   self.organizationPreview = viewModel.organizationPreview
                   debug("Parsed")
                }
                .buttonStyle(.borderedProminent)
                
                Button("Cancel") {
                    // Cancel action
                }
                .buttonStyle(.bordered)
            }
           
           if let organizationPreview = self.organizationPreview {
              OrganizationPreviewView(preview: organizationPreview)
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
    ImportPanelView()
}
