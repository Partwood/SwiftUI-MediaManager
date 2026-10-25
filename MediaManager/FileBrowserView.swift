import SwiftUI
//import AVFoundation
//import Combine
//import UniformTypeIdentifiers
//import os.log
//import SwiftUI
import Foundation
import UniformTypeIdentifiers

// Add columns for attributes in the table view
// Implement sorting functionality
// Add this to the top of the file

struct FileBrowserView: View {
   @State private var initialPath: String = ""
   @State private var currentPath: String = ""
   @State private var items: [FileItem] = []

   @State private var showMetadataPanel = false
   @State private var metadataViewModel: FileMetadataViewModel? = nil
   
   @State private var sortOrder = [KeyPathComparator(\FileItem.name)]
   @State private var isShowingFolderPicker = false
   @State private var selectedDirectoryName: String = "No directory selected"
   @State var selectedFileID: FileItem.ID? = nil

   // NEW: Persist the exact security-scoped URL the user initially chose
   @State private var rootDirectoryURL: URL? = nil

   var body: some View {
      VStack(alignment: .leading, spacing: 12) {
         // Header controls
         HStack {
            Button(action: { isShowingFolderPicker = true }) {
               Label("Select Directory", systemImage: "folder.badge.plus")
            }
            .buttonStyle(.borderedProminent)
            
            Text(selectedDirectoryName)
               .font(.callout)
               .foregroundColor(.secondary)
               .lineLimit(1)
         }
         .padding([.horizontal, .top])
         
         HStack {
            // The Table to display the directory contents
            Table(items, selection: $selectedFileID, sortOrder: $sortOrder) {
               TableColumn("Name", value: \.name) { file in
                  HStack {
                     Image(systemName: file.isDirectory ? "folder.fill" : "doc.fill")
                        .foregroundColor(file.isDirectory ? .red : .secondary)
                     Text(file.name)
                  }
                  // Handle double-click natively on the cell view
                  .contextClickModifier(outerView: self,file: file, action: navigateTo)
                  
               }
               .width(min: 200, ideal: 300)
               
               TableColumn("Type", value: \.type)

               TableColumn("Content Type", value: \.formattedContentType)
               
               TableColumn("Duration", value: \.formattedDuration)

               TableColumn("Size", value: \.size) { file in
                  Text(file.formattedSize)
                  // Right-align numeric sizes for better table aesthetics
                     .frame(maxWidth: .infinity, alignment: .trailing)
               }
               .width(100)
               
               TableColumn("Path", value: \.path)
            }
            .onChange(of: sortOrder) { newOrder in
               items.sort(using: newOrder)
            }
            // Observe selection changes
            .onChange(of: selectedFileID) { newValue in
               handleFileSelectionChanged()
            }
            
            // File Metadata Side Panel
            if showMetadataPanel, let viewModel = metadataViewModel {
               FileMetadataView(viewModel: viewModel, selectedFileID: $selectedFileID)
                  .frame(width: 400)
                  .transition(.move(edge: .trailing).combined(with: .opacity))
            }
         }
      }
      // 2. Attach the native file/folder picker modifier
      .fileImporter(
         isPresented: $isShowingFolderPicker,
         allowedContentTypes: [.folder], // Restrict picker to folders only
         allowsMultipleSelection: false
      ) { result in
         switch result {
         case .success(let urls):
            if let url = urls.first {
               self.rootDirectoryURL = url
               loadDirectoryContents(at: url)
            }
         case .failure(let error):
            print("Error selecting directory: \(error.localizedDescription)")
         }
      }
    }
   
   // NEW: Handles entering a directory if double-clicked
   private func navigateTo(file: FileItem) {
      if file.isDirectory {
         loadDirectoryContents(at: file.url)
      }
   }
   
    func selectDirectory() {
       let panel = NSOpenPanel()
       panel.canChooseFiles = false
       panel.canChooseDirectories = true
       panel.allowsMultipleSelection = false
       if panel.runModal() == .OK {
          if let url = panel.url {
             currentPath = url.path
             initialPath = currentPath
             loadDirectoryContents(at: url)
          }
       }
    }

   func goBack() {
      let url = URL(fileURLWithPath: currentPath)
      let parentURL = url.deletingLastPathComponent()
      currentPath = parentURL.path
      loadDirectoryContents(at: parentURL)
   }

   func loadDirectoryContents(at url: URL) {
      // 1. We must authorize access using the user-selected ROOT directory
      guard let securityRoot = rootDirectoryURL else { return }
      guard securityRoot.startAccessingSecurityScopedResource() else { return }
      
      // 2. Ensure we release access to the root when done reading
      defer { securityRoot.stopAccessingSecurityScopedResource() }
      
       do {
          let fileSystem = FileSystem(securityRoot)
          let result = try fileSystem.listDirectory(at: url.path)
          
          items = result.map { item in
             let fileType: String
             if let attributes = item.attributes {
                switch(attributes.fileType) {
                case .typeDirectory:
                   fileType = "Folder"
                case .typeRegular:
                   fileType = ""
                default:
                   fileType = ""
                }
                
             } else {
                fileType = ""
             }
             
             let contentType = fileSystem.identifyFileType(at: item.url)
             
             let durationInSeconds: Double?
             if ( contentType == .mkv ) {
                do {
                   let mkvParser = try DirectMKVParser(fileURL: item.url)
                   if let metadata = mkvParser.parseContent() {
                      durationInSeconds = metadata.durationInSeconds
                   } else {
                      durationInSeconds = nil
                   }
                } catch {
                   logError(error)
                   durationInSeconds = nil
                }
             } else {
                durationInSeconds = nil
             }
             
             return FileItem(url: item.url,name: item.name, isDirectory: item.isDirectory, path: currentPath + "/" + item.name, size: item.attributes?.fileSize ?? 0, type: fileType, creationDate: nil, modifiedDate: nil, contentType: contentType, durationInSeconds: durationInSeconds)
          }
          
          if ( url != securityRoot ) {
             items.insert(FileItem(url: url.deletingLastPathComponent(),name: "..", isDirectory: true, path: "", size: 0, type: "Folder", creationDate: nil, modifiedDate: nil, contentType: .unknown, durationInSeconds: nil), at: 0)
          }
          
          selectedDirectoryName = url.lastPathComponent
       } catch {
          logError(error)
       }
    }
    
    // Handle file selection changes to update metadata
    func handleFileSelectionChanged() {
       // 1. We must authorize access using the user-selected ROOT directory
       guard let securityRoot = rootDirectoryURL else { return }
       guard securityRoot.startAccessingSecurityScopedResource() else { return }
       
       // 2. Ensure we release access to the root when done reading
       defer {
          securityRoot.stopAccessingSecurityScopedResource()
       }

       if let selectedID = selectedFileID, let index = items.firstIndex(where: { $0.id == selectedID }) {
            let selectedFile = items[index]
            showMetadataPanel = true
            metadataViewModel = FileMetadataViewModel(rootDirectoryURL)
            metadataViewModel?.updateMetadata(for: selectedFile)
        } else {
            showMetadataPanel = false
            metadataViewModel = nil
        }
    }
    
}

struct FileItem: Identifiable {
   let id = UUID()
   let url: URL
   let name: String
   let isDirectory: Bool
   let path: String
   let size: Int64
   let type: String
   let creationDate: Date?
   let modifiedDate: Date?
   let contentType: FileSystem.FileContentType
   let durationInSeconds: Double?
   
   // Helper to format the byte count into readable sizes (KB, MB, etc.)
   var formattedSize: String {
      if isDirectory { return "--" }
      return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
   }
   
   var formattedDuration: String {
      if let durationInSeconds {
         let hours = Int(durationInSeconds) / 3600
         let minutes = (Int(durationInSeconds) % 3600) / 60
         let secs = Int(durationInSeconds) % 60
         
         if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
         } else {
            return String(format: "%02d:%02d", minutes, secs)
         }
      } else {
         return "--"
      }
   }
   
   var formattedContentType: String {
      switch contentType {
      case .mkv: return "Matroska (MKV)"
      case .mp4: return "MPEG-4"
      case .avi: return "AVI"
      case .mp3, .wav, .jpeg, .png: return "N/A"
      case .html: return "HTML"
      case .text: return "Text"
      default: return "N/A"
      }
   }
}

struct UIFileAttributes {
   let name: String
   let type: String
   let size: String
   let modifiedDate: String
}

extension View {
   func contextClickModifier(outerView: FileBrowserView,file: FileItem, action: @escaping (FileItem) -> Void) -> some View {
      self
         .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
      // Making the whole cell area interactive instead of just the text bounds
         .contentShape(Rectangle())
         .onTapGesture(count: 2) {
            action(file)
         }
         .onTapGesture(count: 1) {
            outerView.selectedFileID = file.id
            outerView.handleFileSelectionChanged()
         }
   }
}
