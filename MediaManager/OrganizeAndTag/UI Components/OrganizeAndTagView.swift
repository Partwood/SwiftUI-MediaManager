//
//  OrganizeAndTagView.swift
//  MediaManager
//
//  Copyright © 2026 JVSherwood. All rights reserved.
//

import SwiftUI

/// Main view for the Organize and Tag feature
struct OrganizeAndTagView: View {
   enum AppTab: Hashable {
      case import_view
      case preview_view
      case results
   }

   @StateObject private var viewModel = OrganizeAndTagViewModel()
   @State private var content: String = ""
   @State private var showTitle: String = ""
   @State private var selectedMediaType: MediaType = .tvShow
   @State private var seasonNumber: Int = 1
   @State private var episodeNumber: Int = 1
   @State private var mergeStrategy: MergeStrategy = .rename
   @State private var isShowingFolderPicker: Bool = false
   @State private var showConfirmationDialog: Bool = false
   @State private var processingState: ProcessingState = .idle
   @State private var errorMessages: [String] = []
   @State private var activeTab: AppTab = .import_view
    
   let basePath: URL
   
    var body: some View {
        TabView(selection: $activeTab) {
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
                organizationPreview: $viewModel.organizationPreview,
                appTab: $activeTab
            )
            .tabItem {
               Label("Import", systemImage: "tag")
            }
            .tag(AppTab.import_view)

            // MARK: Preview Tab
           if let preview = viewModel.organizationPreview {
              OrganizationPreviewView(appTab: $activeTab, preview: preview,basePath: basePath,mergeStrategy: mergeStrategy)
                    .tabItem {
                        Label("Preview", systemImage: "eye")
                    }
                    .tag(AppTab.preview_view)
            } else {
                EmptyView()
            }
            
            // MARK: Results Tab
            if let results = viewModel.organizationResults {
                ResultsView(results: results)
                    .tabItem {
                        Label("Results", systemImage: "checkmark.circle")
                    }
                    .tag(AppTab.results)
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
    OrganizeAndTagView(basePath: URL(fileURLWithPath: "/Users"))
}
