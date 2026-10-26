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
   @State private var isMultiselectEnabled = false   // For multiselect support
   @State private var selectedFiles: [FileItem] = []

   @State var selectedFileID: FileItem.ID? = nil
   @State var selectedFileIDs: Set<FileItem.ID> = []

   // NEW: Persist the exact security-scoped URL the user initially chose
   @State private var rootDirectoryURL: URL? = nil
   
   private var KrausValue: CGFloat { .infinity }

   @State var modifierKeys: ModifierKeys = ModifierKeys(shift: false, option: false, command: false)
   
   // Cut/Paste functionality
   @State private var cutPasteViewModel: CutPasteViewModel? = nil
   @State private var showConflictResolution = false
   @State private var conflictItem: CutBufferItem? = nil
   @State private var proposedNewFileName: String = ""
      
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
               CutPasteControls(viewModel: viewModel, selectedFileIDs: $selectedFileIDs, currentPath: $currentPath, fileBrowserView: self)
                  //.padding([.horizontal, .top])
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
            
            // Cut/Paste Progress View
            if let viewModel = cutPasteViewModel {
                if viewModel.isPasteInProgress || viewModel.pasteComplete {
                    PasteProgressView(viewModel: viewModel)
                        .padding()
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

    // Handle cut operation
    func handleCut() {
        guard !selectedFileIDs.isEmpty else { return }
        let selectedFiles = items.filter { selectedFileIDs.contains($0.id) }
        cutPasteViewModel?.cut(files: selectedFiles)
    }
    
    // Handle paste operation
    func handlePaste() {
        guard let viewModel = cutPasteViewModel, !viewModel.cutBuffer.isEmpty else { return }
        
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.title = "Select Paste Destination"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                viewModel.startPaste(at: url.path)
            }
        }
    }
    
    // Handle conflict resolution
    func handleConflict(_ resolution: ConflictResolution) {
        if let item = conflictItem {
            switch resolution {
            case .replace:
                // Replace existing file (handled in viewModel)
                break
            case .keepBoth:
                // Keep both - the viewModel already renamed the file
                break
            case .skip:
                // Skip this file - mark it as cancelled
                //item.isCancelled = true
                break
            }
        }
        showConflictResolution = false
        conflictItem = nil
        proposedNewFileName = ""
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
      if type == "Folder" {
         return type
      } else {
         return contentType.description
      }
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
