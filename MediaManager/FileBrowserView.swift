import SwiftUI

struct FileBrowserView: View {
   @State private var initialPath: String = ""
   @State private var currentPath: String = ""
   @State private var items: [FileItem] = []

    var body: some View {
       VStack {
          HStack {
             if currentPath != initialPath {
                Button(action: goBack) {
                   Image(systemName: "arrow.up.left")
                }
             }
             Button("Select Directory") {
                selectDirectory()
             }
          }
          List(items) { item in
             if item.isDirectory {
                Button(item.name) {
                   currentPath = item.path
                   loadDirectoryContents()
                }
             } else {
                Text(item.name)
             }
          }
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
             loadDirectoryContents()
          }
       }
    }

   func goBack() {
      let url = URL(fileURLWithPath: currentPath)
      let parentURL = url.deletingLastPathComponent()
      currentPath = parentURL.path
      loadDirectoryContents()
   }

    func loadDirectoryContents() {
       do {
          let result = try FileSystem().listDirectory(at: currentPath)
          
          items = result.map { item in
             FileItem(name: item.name, isDirectory: item.isDirectory, path: currentPath + "/" + item.name)
          }
       } catch {
          logError(error)
       }
    }
}

struct FileItem: Identifiable {
    let id = UUID()
    let name: String
    let isDirectory: Bool
    let path: String
}

