import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
   func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
      return true
   }
}

@main struct MyApp: App {
   @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
   
    var body: some Scene {
        WindowGroup {
            //ContentView()
           FileBrowserView()
        }
    }
}
