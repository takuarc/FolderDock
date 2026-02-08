import SwiftUI
import AppKit

@main
struct FolderDockApp: App {
    @StateObject var store = AppStore()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var colorScheme: ColorScheme? {
        switch store.theme {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .preferredColorScheme(colorScheme)
                .background(VisualEffectView(material: .popover, blendingMode: .behindWindow))
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                    if let window = NSApp.windows.first { positionWindow(window) }
                }
                .onReceive(NotificationCenter.default.publisher(for: NSWindow.didEndLiveResizeNotification)) { _ in
                    if let window = NSApp.windows.first {
                        store.lastWindowSize = window.frame.size
                        store.saveSettings()
                    }
                }
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
        .commands { CommandGroup(replacing: .newItem) {} }
    }
    
    func positionWindow(_ window: NSWindow) {
        if let savedSize = store.lastWindowSize {
            var currentFrame = window.frame
            currentFrame.size = savedSize
            window.setFrame(currentFrame, display: false)
        }
        guard let screen = NSScreen.main else { return }
        let mouseLocation = NSEvent.mouseLocation
        let windowSize = window.frame.size
        let xPos = mouseLocation.x - (windowSize.width / 2)
        let dockTopEdge = screen.visibleFrame.minY
        let finalY = dockTopEdge + 15
        window.setFrameOrigin(NSPoint(x: xPos, y: finalY))
        window.level = .floating
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

// --- REQUIRED HELPER CLASSES BELOW ---

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {}
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if let window = sender.windows.first {
            if window.isVisible { window.orderOut(nil) }
            else { NotificationCenter.default.post(name: NSApplication.didBecomeActiveNotification, object: nil) }
        }
        return false
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
