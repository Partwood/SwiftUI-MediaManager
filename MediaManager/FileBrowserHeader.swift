//
//  FileBrowserHeader.swift
//  MediaManager
//
//  Copyright © 2026 JVSherwood. All rights reserved.
//


import SwiftUI
import Foundation
import UniformTypeIdentifiers
import Combine
import SwiftUI

struct FileBrowserHeader: View {
   @Environment(\.openWindow) private var openWindow

   @Binding var rootDirectoryURL: URL?
   @Binding var currentPath: String
   
   @Binding var isShowingFolderPicker: Bool
   @Binding var selectedDirectoryName: String
   @Binding var selectedFileIDs: Set<FileItem.ID>
   @Binding var cutPasteViewModel: CutPasteViewModel?
   @Binding var showPasteProgress: Bool
   @Binding var needsRefresh: Bool
   
   let fileBrowserView: FileBrowserView
   
   var body: some View {
      // Header controls
      HStack {
         HStack {
            // Current directory
            Text(selectedDirectoryName)
               .font(.callout)
               .foregroundColor(.secondary)
               .lineLimit(1)
            
            // Multiselect indicator
            if selectedFileIDs.count > 0 {
               Text("\(selectedFileIDs.count) selected")
                  .font(.caption)
                  .foregroundColor(.secondary)
                  .padding(.leading, 8)
            }
         }
         
         Spacer()
         
         HStack {
            Button(action: { isShowingFolderPicker = true }) {
               Label("Select Directory", systemImage: "folder.badge.plus")
            }
            .buttonStyle(.borderedProminent)
            
            if let rootURL = self.rootDirectoryURL {
               let organizationPath: URL = URL(filePath: self.currentPath)
               Button(action: {
                  let callerFrame = NSApp.keyWindow?.frame ?? .zero
                  openWindow(id: "mmgr.organizer",value: PopupContext(callerFrame,rootURL,organizationPath))
               }) {
                  Label("Organize & Tag", systemImage: "tag.fill")
               }
               .buttonStyle(.bordered)
            }
            
            // Cut/Paste Controls
            if let viewModel = cutPasteViewModel {
               CutPasteControls(viewModel: viewModel,
                                selectedFileIDs: $selectedFileIDs,
                                currentPath: $currentPath,
                                showPasteProgress: $showPasteProgress,
                                needsRefresh: $needsRefresh,
                                fileBrowserView: fileBrowserView)
            }
         }
      }.padding([.horizontal, .top])
   }
}
