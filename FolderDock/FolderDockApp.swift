import SwiftUI
import AppKit

@main
struct FolderDockApp: App {
    @StateObject var store = AppStore()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .background(VisualEffectView(material: .popover, blendingMode: .behindWindow))

                // Position the popup when app becomes active (Dock icon click)
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                    if let window = NSApp.windows.first {
                        positionWindow(window)
                    }
                }

                // Persist size when user finishes resizing
                .onReceive(NotificationCenter.default.publisher(for: NSWindow.didEndLiveResizeNotification)) { _ in
                    if let window = NSApp.windows.first {
                        store.lastWindowSize = window.frame.size
                        store.saveSettings()
                    }
                }

                // Click outside => close
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
                    if let window = NSApp.windows.first {
                        store.lastWindowSize = window.frame.size
                        store.saveSettings()
                        store.isEditMode = false
                        window.orderOut(nil)
                    }
                    NSApp.hide(nil)
                }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }

    func positionWindow(_ window: NSWindow) {
        // Restore size only (not position)
        if let savedSize = store.lastWindowSize {
            var frame = window.frame
            frame.size = savedSize
            window.setFrame(frame, display: false)
        }

        guard let screen = NSScreen.main else { return }

        let mouse = NSEvent.mouseLocation
        let size = window.frame.size

        let x = mouse.x - (size.width / 2)
        let dockTop = screen.visibleFrame.minY
        let y = dockTop + 15

        window.setFrameOrigin(NSPoint(x: x, y: y))

        window.level = .floating

        // Critical: NEVER allow “move window by background”.
        // We will implement controlled dragging in ContentView via NSViewRepresentable.
        window.isMovableByWindowBackground = false

        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) { }

    // Dock-icon toggle: visible -> hide; hidden -> show/position
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if let window = sender.windows.first {
            if window.isVisible {
                window.orderOut(nil)
            } else {
                NotificationCenter.default.post(name: NSApplication.didBecomeActiveNotification, object: nil)
            }
        }
        return false
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = material
        v.blendingMode = blendingMode
        v.state = .active
        return v
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
