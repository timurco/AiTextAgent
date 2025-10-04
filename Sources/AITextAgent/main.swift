import AppKit
import Foundation

/// Main application delegate managing menu bar and lifecycle
class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarController: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize menu bar controller
        menuBarController = MenuBarController()

        print("✅ AITextAgent started successfully!")
        print("💡 Usage: Copy text (⌘C), then press ⌘⇧Space to process with AI")
    }

    func applicationWillTerminate(_ notification: Notification) {
        print("AITextAgent shutting down...")
    }
}

/// Application entry point
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
