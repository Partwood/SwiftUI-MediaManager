//
//  RenameView.swift
//  MediaManager
//
//  Copyright © 2026 JVSherwood. All rights reserved.
//

import SwiftUI

struct RenameView: View {
   @Binding var showRenameDialog: Bool
   @Binding var rootDirectoryURL: URL?
   @Binding var needsRefresh: Bool
   
   @State private var proposedNewName: String = ""
   @State private var renameError: String?
   
   let currentPath: String
   let item: FileItem

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "pencil")
                    .foregroundColor(.blue)
                Text("Rename")
                    .font(.headline)
            }
            
            Text("Enter a new name for '\(item.name)':")
                .foregroundColor(.secondary)
            
            TextField("New Name", text: $proposedNewName)
                .textFieldStyle(.roundedBorder)
            
            if let error = renameError {
                Text(error)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            HStack(spacing: 12) {
                Button("Rename") {
                    renameItem()
                }
                .buttonStyle(.borderedProminent)
                .disabled(proposedNewName.isEmpty)
                
                Button("Cancel") {
                    showRenameDialog = false
                    proposedNewName = item.name
                    renameError = nil
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .frame(width: 400)
    }
    
    func renameItem() {
        guard !proposedNewName.isEmpty else {
            renameError = "New name cannot be empty"
            return
        }
        
        // Check if new name already exists
        let parentURL: URL = URL(fileURLWithPath: currentPath)
        let itemURL: URL = parentURL.appendingPathComponent(item.name)
        let newURL: URL = parentURL.appendingPathComponent(proposedNewName)
        
        let fileSystem = FileSystem(rootDirectoryURL)
        
        // Check if target already exists
        if newURL.isExisting() {
            renameError = "A file or folder with this name already exists"
            return
        }
        
        renameError = nil
        
        fileSystem.accessURL(parentURL) { url in
            do {
                try fileSystem.moveFile(src: itemURL, dst: newURL)
                
                proposedNewName = item.name
                
               // Reload directory contents
               needsRefresh = true
               
               // Complete, close
               showRenameDialog = false
            } catch {
                logError(error)
                renameError = "Failed to rename: \(error.localizedDescription)"
            }
        }
    }
}
