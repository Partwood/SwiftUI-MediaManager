//
//  MyApp.swift
//  MediaManager
//
//  Copyright © 2026 JVSherwood. All rights reserved.
//

import SwiftUI
import AppKit
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
   func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
      return true
   }
}

@main struct MyApp: App {
   @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
   
   @State var needsRefresh: Bool = false
   
   var body: some Scene {
        // Main file browser window
      WindowGroup("File Browser", id: "mmgr.filebrowser") {
           FileBrowserView(
            needsRefresh: $needsRefresh
           )
        }
        
      // Organize & Tag window (opened programmatically)
      WindowGroup("Organize & Tag", id: "mmgr.organizer", for: PopupContext.self) { $context in
         OrganizeAndTagWindow(
            popupContext: context,
            needsRefresh: $needsRefresh,
         )
      }
      //.windowStyle(.plain)
      .windowLevel(.floating)
      .defaultPosition(.center)
      .defaultLaunchBehavior(.suppressed)
      // Note you may need to do Cmd+Q to save as closed (if you didnt do this first) then clean build then run it to see the effect
      .restorationBehavior(.disabled)
   }
}

// Make CGRect Hashable & Codable (or wrap it in a custom Codable struct)
struct PopupContext: Hashable, Codable {
   let root: URL
   let basePath: URL

   let x: Double
   let y: Double
   let width: Double
   let height: Double
   
   var frame: CGRect {
      CGRect(x: x, y: y, width: width, height: height)
   }
   
   init(_ rect: CGRect,_ root: URL,_ basePath: URL) {
      self.x = rect.origin.x
      self.y = rect.origin.y
      self.width = rect.size.width
      self.height = rect.size.height
      
      self.root = root
      self.basePath = basePath
   }
}

struct WindowPositioner: NSViewRepresentable {
   let parentFrame: CGRect?
   
   func makeNSView(context: Context) -> NSView {
      let view = NSView()
      DispatchQueue.main.async {
         guard let window = view.window,
               let parent = parentFrame,
               parent != .zero else { return }
         
         let size = window.frame.size
         let x = parent.midX - (size.width / 2)
         let y = parent.midY - (size.height / 2)
         window.setFrameOrigin(NSPoint(x: x, y: y))
      }
      return view
   }
   
   func updateNSView(_ nsView: NSView, context: Context) {}
}

/// Window containing the Organize & Tag functionality
struct OrganizeAndTagWindow: View {
   @Environment(\.dismissWindow) private var dismissWindow
   
   let popupContext: PopupContext?

   @State var cancelled: Bool = false
   @State var completed: Bool = false
   
   @Binding var needsRefresh: Bool
   
   var body: some View {
      OrganizeAndTagView(
         fileSystem: FileSystem(popupContext?.root),
         cancelled: $cancelled,
         completed: $completed,
         needsRefresh: $needsRefresh,
         basePath: popupContext?.basePath ?? URL(filePath: "/User")
      )
      .frame(minWidth: 600, minHeight: 400)
      //.padding()
      //.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
      .background(WindowPositioner(parentFrame: popupContext?.frame))
      //.overlay(
      // RoundedRectangle(cornerRadius: 14)
      //    .strokeBorder(.separator, lineWidth: 1)
      //)
      .shadow(color: .black.opacity(0.25), radius: 16, y: 8)
      .gesture(WindowDragGesture())
      .onChange(of: cancelled, {
         dismissWindow(id: "mmgr.organizer")
      })
      .onChange(of: completed, {
         dismissWindow(id: "mmgr.organizer")
      })
   }
}
