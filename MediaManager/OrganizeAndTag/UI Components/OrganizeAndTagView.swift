//
//  OrganizeAndTagView.swift
//  MediaManager
//
//  Copyright © 2026 JVSherwood. All rights reserved.
//

import SwiftUI

/// Main view for the Organize and Tag feature
struct OrganizeAndTagView: View {
    @StateObject private var viewModel = OrganizeAndTagViewModel()
    @State private var content: String = ""
    @State private var showTitle: String = ""
    @State private var selectedMediaType: MediaType = .tvShow
    @State private var seasonNumber: Int = 1
    @State private var episodeNumber: Int = 1
    @State private var basePath: URL = URL(fileURLWithPath: "/Users")
    @State private var mergeStrategy: MergeStrategy = .rename
    @State private var isShowingFolderPicker: Bool = false
    @State private var organizationPreview: OrganizationPreview? = nil
    @State private var showConfirmationDialog: Bool = false
    @State private var processingState: ProcessingState = .idle
    @State private var errorMessages: [String] = []
    
    var body: some View {
        TabView {
            // Import Panel Tab
            ImportPanelView(
                content: content,
                showTitle: showTitle,
                selectedMediaType: selectedMediaType,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber,
                basePath: basePath,
                mergeStrategy: mergeStrategy,
                isShowingFolderPicker: isShowingFolderPicker,
                organizationPreview: organizationPreview
            )
                .tabItem {
                    Label("Import", systemImage: "tag")
                }
            
            // Preview Tab
            if let preview = organizationPreview {
               OrganizationPreviewView(preview: preview,basePath: basePath,mergeStrategy: mergeStrategy)
                    .tabItem {
                        Label("Preview", systemImage: "eye")
                    }
            } else {
                EmptyView()
            }
            
            // Results Tab
            if let results = viewModel.organizationResults {
                ResultsView(results: results)
                    .tabItem {
                        Label("Results", systemImage: "checkmark.circle")
                    }
            } else {
                EmptyView()
            }
        }
        .navigationTitle("Organize & Tag")
        .sheet(isPresented: $showConfirmationDialog) {
            ConfirmationDialog(
                results: viewModel.organizationResults ?? OrganizationResults(),
                mediaType: selectedMediaType,
                title: showTitle
            )
        }
        .alert("Processing Error", isPresented: .constant(!errorMessages.isEmpty)) {
            ForEach(errorMessages, id: \.self) { error in
                Button(error) { }
            }
            Button("OK") {
                errorMessages = []
            }
        } message: {
            Text(errorMessages.joined(separator: "\n"))
        }
        //.onAppear {
           //viewModel.loadSampleContent()
        //}
    }
}

// MARK: - Preview
#Preview {
    OrganizeAndTagView()
}
