import SwiftUI
import Foundation
import UniformTypeIdentifiers

struct ModifierKeys {
   var shift: Bool
   var option: Bool
   var command: Bool
   
   var none: Bool {
      get {
         return (!shift && !option && !command)
      }
   }
}

// Add columns for attributes in the table view
// Implementsorting functionality
// Add this to the top of the file

struct FileBrowserView: View {
   @State private var initialPath: String = ""
   @State private var currentPath: String = ""
   @State private var items: [FileItem] = []

   @State private var showMetadataPanel = false
   @State private var metadataViewModel: FileMetadataViewModel? = nil

   // New Folder functionality
   @State private var showNewFolderDialog = false
   
   @State private var sortOrder = [KeyPathComparator(\FileItem.name)]
   @State private var isShowingFolderPicker = false
   @State private var selectedDirectoryName: String = "No directory selected"
   @State private var isMultiselectEnabled = false   // For multiselect support
   @State private var selectedFiles: [FileItem] = []

   @State var selectedFileID: FileItem.ID? = nil
   @State var selectedFileIDs: Set<FileItem.ID> = []

   // Persist the exact security-scoped URL the user initially chose
   @State private var rootDirectoryURL: URL? = nil
   
   private var KrausValue: CGFloat { .infinity }

   @State var modifierKeys: ModifierKeys = ModifierKeys(shift: false, option: false, command: false)
   
   // Cut/Paste functionality
   @State private var cutPasteViewModel: CutPasteViewModel? = nil
   @State private var showConflictResolution = false
   @State private var conflictItem: CutBufferItem? = nil
   @State private var proposedNewFileName: String = ""
   @State var showPasteProgress: Bool = false
      
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
            
            // Multiselect indicator
            if selectedFileIDs.count > 0 {
               Text("\(selectedFileIDs.count) selected")
                  .font(.caption)
                  .foregroundColor(.secondary)
                  .padding(.leading, 8)
            }
            
            // Cut/Paste Controls
            if let viewModel = cutPasteViewModel {
               CutPasteControls(viewModel: viewModel,
                                selectedFileIDs: $selectedFileIDs,
                                currentPath: $currentPath,
                                showPasteProgress: $showPasteProgress,
                                fileBrowserView: self)
            }
         }
         .padding([.horizontal, .top])
         
         HStack {
            // The Table to display the directory contents
            Table(items, selection: $selectedFileIDs, sortOrder: $sortOrder) {
               TableColumn("Name", value: \.name) { file in
                  HStack {
                     Image(systemName: file.isDirectory ? "folder.fill" : "doc.fill")
                        .foregroundColor(file.isDirectory ? .red : .secondary)
                     Text(file.name)
                  }
                  // Handle double-click natively on the cell view
                  .contextClickModifier(outerView: self,file: file, action: navigateTo)
                  // Add context menu for right-click
                  .contextMenu {
                      Button(action: {
                          showNewFolderDialog = true
                      }) {
                          Label("New Folder", systemImage: "folder.badge.plus")
                      }
                  }
                  .onModifierKeysChanged(mask: [.option,.shift]) { old, new in
                     let optionKey = new.contains(.option)
                     let shiftKey = new.contains(.shift)
                     let commandKey = new.contains(.command)
                     self.modifierKeys = ModifierKeys(shift: shiftKey, option: optionKey, command: commandKey)
                  }
               }
               .width(min: 200, ideal: 300)

               TableColumn("Type", value: \.formattedContentType)
               
               TableColumn("Duration", value: \.formattedDuration)

               TableColumn("Size", value: \.size) { file in
                  // Right-align numeric sizes for better table aesthetics
                  Text(file.formattedSize)
                     .frame(maxWidth: .infinity, alignment: .trailing)
               }
               .width(100)
               
               TableColumn("Path", value: \.path)
            }
            .onChange(of: sortOrder, { _,newOrder in
               items.sort(using: newOrder)
            })
            .onChange(of: selectedFileIDs) { _,newSelection in
               handleMultiselectChanges()
            }
            .onChange(of: showNewFolderDialog) {
               if ( !showNewFolderDialog ) {
                  loadDirectoryContents(at: URL(fileURLWithPath: currentPath))
               }
            }

            // File Metadata Side Panel
            if showMetadataPanel, let viewModel = metadataViewModel {
               if let _ = selectedFileIDs.first {
                  FileMetadataView(viewModel: viewModel, selectedFileID: $selectedFileID, showMetadataPanel: $showMetadataPanel)
                     .frame(width: 400)
                     .transition(.move(edge: .trailing).combined(with: .opacity))
               }
            }
         }
         
         // Show conflict resolution dialog
         if showConflictResolution, let item = conflictItem {
            ConflictResolutionView(viewModel: cutPasteViewModel!, existingFileName: item.file.name, proposedNewFileName: proposedNewFileName)
               .frame(width: 400, height: 350)
         }
         // Show new folder dialog
         if showNewFolderDialog {
            NewFolderView(showNewFolderDialog: $showNewFolderDialog,
                          rootDirectoryURL: $rootDirectoryURL,
                          currentPath: currentPath)
         }
         
         // Cut/Paste Progress View
         if ( showPasteProgress ) {
            if let viewModel = cutPasteViewModel {
               PasteProgressView(viewModel: viewModel)
                  .padding()
            }
         }
      }
      // Attach the native file/folder picker modifier
      .fileImporter(
         isPresented: $isShowingFolderPicker,
         allowedContentTypes: [.folder], // Restrict picker to folders only
         allowsMultipleSelection: false
      ) { result in
         switch result {
         case .success(let urls):
            if let url = urls.first {
               self.currentPath = url.filePath
               self.rootDirectoryURL = url
               loadDirectoryContents(at: url)
            }
         case .failure(let error):
            print("Error selecting directory: \(error.localizedDescription)")
         }
      }
    }
   
   // Handles entering a directory if double-clicked
   private func navigateTo(file: FileItem) {
      if file.isDirectory {
         loadDirectoryContents(at: file.url)
      }
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
          currentPath = url.filePath
       } catch {
          logError(error)
       }
    }
    
    // Initialize Cut/Paste ViewModel
    func initializeCutPasteViewModel() {
       if selectedFiles.isEmpty {
          cutPasteViewModel = nil
       } else if ( cutPasteViewModel == nil ) {
          cutPasteViewModel = CutPasteViewModel(rootDirectoryURL)
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
   
    // Handle multiselect changes
    func handleMultiselectChanges() {
       // Update selectedFiles array based on selectedFileIDs
       selectedFiles = items.filter { selectedFileIDs.contains($0.id) }
       
       // If multiple files are selected, clear the single selection
       if selectedFileIDs.count > 1 {
          selectedFileID = nil
       }
       // If one file is selected, set it as the single selection
       else if selectedFileIDs.count == 1 {
          selectedFileID = selectedFileIDs.first
          handleFileSelectionChanged()
       }
       else {
          selectedFileID = nil
       }
       
       initializeCutPasteViewModel()
    }
}

extension View {
   func contextClickModifier(outerView: FileBrowserView,file: FileItem, action: @escaping (FileItem) -> Void) -> some View {
      // Making the whole cell area interactive instead of just the text bounds
      self
         .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
         .contentShape(Rectangle())
         .onTapGesture(count: 2) {
            action(file)
         }
         .onTapGesture(count: 1) {
            let existed = outerView.selectedFileIDs.contains(file.id)
            if outerView.modifierKeys.none {
               outerView.selectedFileIDs.removeAll()
               if ( !existed ) {
                  outerView.selectedFileIDs.insert(file.id)
               }
            } else {
               // Should do a range if using shift
               if ( !existed ) {
                  outerView.selectedFileIDs.insert(file.id)
               } else {
                  outerView.selectedFileIDs.remove(file.id)
               }
            }
         }
   }
}

// MARK: - FileBrowserView Extension

extension FileBrowserView {
   func getSelectedFiles() -> [FileItem]? {
      guard !selectedFileIDs.isEmpty else { return nil }
      return items.filter { selectedFileIDs.contains($0.id) }
   }
}
