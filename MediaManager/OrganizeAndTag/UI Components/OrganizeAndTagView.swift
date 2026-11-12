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
   @State private var showtitle: String = ""
   @State private var selectedMediaType: MediaType = .tvShow
   @State private var seasonNumber: Int = 1
   @State private var episodeNumber: Int = 1
   @State private var mergeStrategy: MergeStrategy = .rename
   @State private var isShowingFolderPicker: Bool = false
   @State private var showConfirmationDialog: Bool = false
   @State private var processingState: ProcessingState = .idle
   @State private var errorMessages: [String] = []
   @State private var activeTab: AppTab = .import_view

   @State var startOrganization: Bool = false
   
   @State var fileSystem: FileSystem

   @Binding var showOrganizePanel: Bool
   @Binding var organized: Bool
    
   let basePath: URL
   
    var body: some View {
        TabView(selection: $activeTab) {
            // Import Panel Tab
            ImportPanelView(
               showtitle: showtitle,
               selectedMediaType: selectedMediaType,
               basePath: basePath,
               mergeStrategy: mergeStrategy,
               isShowingFolderPicker: isShowingFolderPicker,
               fileSystem: $fileSystem,
               seasonNumber: $seasonNumber,
               episodeNumber: $episodeNumber,
               showOrganizePanel: $showOrganizePanel,
               organizationPreview: $viewModel.organizationPreview,
               organizationResults: $viewModel.organizationResults,
               appTab: $activeTab,
               content: $content
            )
            .tabItem {
               Label("Import", systemImage: "tag")
            }
            .tag(AppTab.import_view)

            // MARK: Preview Tab
           if let preview = viewModel.organizationPreview,
              let results = viewModel.organizationResults {
              OrganizationPreviewView(
               appTab: $activeTab,
               startOrganization: $startOrganization,
               preview: preview,
               basePath: basePath,
               mergeStrategy: mergeStrategy,
               results: results)
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
        .onChange(of: startOrganization, {
           if startOrganization {
              organize()
              organized = true
           } else {
              activeTab = .import_view
           }
        })
        .navigationTitle("Organize & Tag")
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
    }
   
   private func organize() {
      let importViewModel = ImportPanelViewModel()
      
      importViewModel.parse(content: content, mediaType: selectedMediaType, startingEpisode: episodeNumber)
      
      let organizeAndTagViewModel = OrganizeAndTagViewModel()
      organizeAndTagViewModel.organizationPreview = importViewModel.organizationPreview
      
      fileSystem.accessURL(basePath, { accessibleURL in
         guard let url = accessibleURL else { return }
         
         do {
            let organizationResults = try organizeAndTagViewModel.executeOrganization(
               fileSystem: fileSystem,
               preview: false,
               basePath: url,
               mergeStrategy: mergeStrategy)
            
            viewModel.organizationResults = organizationResults
         } catch {
            logError(error)
            
            var results = OrganizationResults()
            results.errors.append(error.localizedDescription)
            viewModel.organizationResults = results
         }
      })
      
      self.activeTab = .results
      debug("Organized")
   }
}

// MARK: - Preview
#Preview {
   @Previewable @State var showOrganizePanel: Bool = false
   @Previewable @State var organized: Bool = false
   
   let fileSystem = FileSystem(URL(fileURLWithPath: "/Users"))
   
   OrganizeAndTagView(fileSystem: fileSystem,
                      showOrganizePanel: $showOrganizePanel,
                      organized: $organized,
                      basePath: URL(fileURLWithPath: "/Users"))
}
