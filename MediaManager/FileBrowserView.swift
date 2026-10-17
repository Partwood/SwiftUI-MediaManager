import SwiftUI
import Foundation
import UniformTypeIdentifiers

// Add columns for attributes in the table view
// Implement sorting functionality
// Add this to the top of the file

struct FileBrowserView: View {
   @State private var initialPath: String = ""
   @State private var currentPath: String = ""
   @State private var items: [FileItem] = []
   
   @State private var sortOrder = [KeyPathComparator(\FileItem.name)]
   @State private var isShowingFolderPicker = false
   @State private var selectedDirectoryName: String = "No directory selected"
   @State private var selectedFileID: FileItem.ID? = nil

   // NEW: Persist the exact security-scoped URL the user initially chose
   @State private var rootDirectoryURL: URL? = nil

   var body: some View {
      VStack(alignment: .leading, spacing: 12) {
         // Header controls
         HStack {
            Button(action: { isShowingFolderPicker = true }) {
               Label("Select Directory", systemImage: "folder.badge.plus")
               //Label("Select Directory", systemName: "folder.badge.plus")
            }
            .buttonStyle(.borderedProminent)
            
            Text(selectedDirectoryName)
               .font(.callout)
               .foregroundColor(.secondary)
               .lineLimit(1)
         }
         .padding([.horizontal, .top])
         
         // The Table to display the directory contents
         Table(items, selection: $selectedFileID, sortOrder: $sortOrder) {
            TableColumn("Name", value: \.name) { file in
               HStack {
                  Image(systemName: file.isDirectory ? "folder.fill" : "doc.fill")
                     .foregroundColor(file.isDirectory ? .red : .secondary)
                  Text(file.name)
               }
               // Handle double-click natively on the cell view
               .contextClickModifier(file: file, action: navigateTo)

            }
            .width(min: 200, ideal: 300)
            
            TableColumn("Type", value: \.type)
            
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
      
      //      NavigationView {
//         // Modify the List to Table view
//         Table(items) {
//            TableColumn("Name", value: \.name)
//            //TableColumn("Name", value: $0)
//         }
//      }.navigationTitle("File Browser")
//      Table(files) {
////         TableColumn("Name", value: $0.name)
////         TableColumn("Type", value: $0.type)
////         TableColumn("Size", value: $0.size)
////         TableColumn("Modified", value: $0.modifiedDate)
//      }
//      .navigationTitle("File Browser")
//      .onChange(of: sortColumn) { newColumn in
//         // Implement sorting logic here
//      }
//      
//      // Update the file query to use MCP
//      .onAppear {
//         // Fetch files using MCP filesystem tool
//         // Example: mcp_SwagenticMCP_filesystem(operation: "list", path: "./", name: "")
//      }    // Add this inside the FileBrowserView struct
//      
//      // Update the onAppear to fetch files
//      .onAppear {
//         // Use MCP to list files and populate the files array
//         // Example: mcp_SwagenticMCP_filesystem(operation: "list", path: "./", name: "")
//         // Process the response to populate files array
//      }
//      
//      // Add this to handle file selection
//      .onChange(of: selectedFile) { newFile in
//         if let newFile = newFile, !newFile.isDirectory {
//            // Use MCP to get file attributes
//            // Example: mcp_SwagenticMCP_filesystem(operation: "info", path: newFile, name: "")
//            // Update fileAttributes dictionary
//         }
//      }    // Implement sorting logic in onChange
//      .onChange(of: sortColumn) { newColumn in
//         files.sort {
//            switch newColumn {
//            case "name":
//               return $0.name < $1.name
//            case "type":
//               return $0.type < $1.type
//            case "size":
//               return Int($0.size)! < Int($1.size)!
//            case "modified":
//               return $0.modifiedDate < $1.modifiedDate
//            default:
//               return false
//            }
//         }
//      }
//      
//      // Implement MCP file listing in onAppear
//      .onAppear {
//         FileSystem().listDirectory(at: "./") { result in
//            // Process directory listing and populate files array
//            // This would require a completion handler implementation
//         }
//      }
//      
//      // Implement file attribute lookup on selection
//      .onChange(of: selectedFile) { newFile in
//         if let newFile = newFile, !newFile.isDirectory {
//            FileSystem().info(at: newFile, name: "") { result in
//               // Parse attributes and update fileAttributes dictionary
//               // This would require a completion handler implementation
//            }
//         }
//      }
      
//      NavigationView {
//          List {
//
////             ForEach(files) { file in
////                if file.isDirectory {
////                   NavigationLink(destination: FileBrowserView()) {
////                      Text(file.name)
////                   }
////                } else {
////                   Button(action: {
////                      selectedFile = file.path
////                      // Query file attributes using MCP tool
////                      // Example: mcp_SwagenticMCP_filesystem(operation: "info", path: file.path, name: file.name)
////                   }) {
////                      Text(file.name)
////                   }
////                }
////             }
//          }
//          .navigationTitle("File Browser")
//          
////          if let selectedFile = selectedFile {
////             VStack {
////                Text("File Attributes:")
////                ForEach(fileAttributes.keys.sorted()) { key in
////                   Text("$key",<#label#>: $fileAttributes[key]!)
////                }
////             }
////             .padding()
////          }
//       }
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
          let result = try FileSystem().listDirectory(at: url.path)
          
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
             
             return FileItem(url: item.url,name: item.name, isDirectory: item.isDirectory, path: currentPath + "/" + item.name, size: item.attributes?.fileSize ?? 0, type: fileType)
          }
          
          if ( url != securityRoot ) {
             items.insert(FileItem(url: url.deletingLastPathComponent(),name: "..", isDirectory: true, path: "", size: 0, type: "Folder"), at: 0)
          }
          
          selectedDirectoryName = url.lastPathComponent
       } catch {
          logError(error)
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
   // Helper to format the byte count into readable sizes (KB, MB, etc.)
   var formattedSize: String {
      if isDirectory { return "--" }
      return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
   }
}

struct UIFileAttributes {
   let name: String
   let type: String
   let size: String
   let modifiedDate: String
}

extension View {
   func contextClickModifier(file: FileItem, action: @escaping (FileItem) -> Void) -> some View {
      self
         .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
      // Making the whole cell area interactive instead of just the text bounds
         .contentShape(Rectangle())
         .onTapGesture(count: 2) {
            action(file)
         }
   }
}
