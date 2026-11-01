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
    @State private var basePath: URL = URL(fileURLWithPath: "/Users")
    @State private var mergeStrategy: MergeStrategy = .rename
    
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
                        // Implement file picker
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
                    viewModel.parse(content: content, title: showTitle, mediaType: selectedMediaType)
                }
                .buttonStyle(.borderedProminent)
                
                Button("Cancel") {
                    // Cancel action
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
    ImportPanelView()
}
