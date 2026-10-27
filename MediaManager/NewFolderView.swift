//
//  NewFolderView.swift
//  MediaManager
//
//  Created by Joshua V Sherwood on 10/26/26.
//

import SwiftUI

struct NewFolderView: View {
   @Binding var showNewFolderDialog: Bool
   //@Binding var newFolderParentPath: String
   @Binding var rootDirectoryURL: URL?
   
   let currentPath: String
   @State private var newFolderName: String = ""
   
   // Create new folder functionality
   @State private var createFolderError: String?

   var body: some View {
      VStack(alignment: .leading, spacing: 16) {
         HStack {
            Image(systemName: "folder.badge.plus")
               .foregroundColor(.blue)
            Text("Create New Folder")
               .font(.headline)
         }
         
         Text("Enter a name for the new folder:")
            .foregroundColor(.secondary)
         
         TextField("Folder Name", text: $newFolderName)
            .textFieldStyle(.roundedBorder)
         
         if let error = createFolderError {
            Text(error)
               .foregroundColor(.red)
               .frame(maxWidth: .infinity, alignment: .leading)
         }
         
         HStack(spacing: 12) {
            Button("Create") {
               createNewFolder()
            }
            .buttonStyle(.borderedProminent)
            .disabled(newFolderName.isEmpty)
            
            Button("Cancel") {
               showNewFolderDialog = false
               newFolderName = ""
               createFolderError = nil
            }
            .buttonStyle(.plain)
         }
      }
      .padding()
      .frame(width: 400)
   }
   
   // Create new folder functionality
   func createNewFolder() {
      guard !newFolderName.isEmpty else {
         createFolderError = "Folder name cannot be empty"
         return
      }
      
      // Check if folder name already exists
      let parentURL: URL = URL(fileURLWithPath: currentPath)
      let folderURL: URL = parentURL.appendingPathComponent(newFolderName)

      let fileSystem = FileSystem(rootDirectoryURL)
      
      let exists = folderURL.isExisting()
      
      if exists {
         createFolderError = "A folder or file with this name already exists"
         return
      }
      
      createFolderError = nil
      
      fileSystem.accessURL(parentURL, { url in
         do {
            // Create the folder
            try fileSystem.createDir(at: folderURL.path)
            
            // Close the dialog
            showNewFolderDialog = false
            newFolderName = ""
            
            // Reload the directory contents upon return (showNewFolderDialog change)
         } catch {
            logError(error)
            createFolderError = "Failed to create folder: \(error.localizedDescription)"
         }
      })
   }
}
