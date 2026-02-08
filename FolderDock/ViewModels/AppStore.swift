import SwiftUI
import AppKit
import Combine
import UniformTypeIdentifiers

class AppStore: ObservableObject {
    @Published var apps: [AppItem] = []
    @Published var iconSize: CGFloat = 64
    @Published var isListView: Bool = false
    @Published var lastWindowSize: CGSize?
    @Published var systemApps: [SystemApp] = []
    @Published var isEditMode: Bool = false
    
    // DYNAMIC KEYS: Based on the actual filename of the .app
    private var saveKey: String {
        return "saved_apps_\(ProcessInfo.processInfo.processName)"
    }
    
    private var settingsKey: String {
        return "saved_settings_\(ProcessInfo.processInfo.processName)"
    }
    
    init() {
        loadData()
    }
    
    func loadSystemApps() {
         DispatchQueue.global(qos: .userInitiated).async {
             let apps = InstalledAppsManager.fetchApps()
             DispatchQueue.main.async { self.systemApps = apps }
         }
    }
    
    func isAppSelected(_ systemApp: SystemApp) -> Bool {
        return apps.contains { $0.name == systemApp.name }
    }
    
    func toggleApp(_ systemApp: SystemApp) {
        if let index = apps.firstIndex(where: { $0.name == systemApp.name }) {
            apps.remove(at: index)
        } else {
            if let bookmark = try? systemApp.url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil) {
                let newItem = AppItem(name: systemApp.name, bookmarkData: bookmark)
                apps.append(newItem)
            }
        }
        saveApps()
    }
    
    func moveApp(from source: IndexSet, to destination: Int) {
        apps.move(fromOffsets: source, toOffset: destination)
        saveApps()
    }
    
    func moveApp(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex != destinationIndex else { return }
        let item = apps.remove(at: sourceIndex)
        apps.insert(item, at: destinationIndex)
        saveApps()
    }
    
    func saveSettings() {
        var sizeDict: [String: CGFloat] = [:]
        if let size = lastWindowSize {
            sizeDict["width"] = size.width
            sizeDict["height"] = size.height
        }
        
        let settings: [String: Any] = [
            "iconSize": iconSize,
            "isListView": isListView,
            "lastWindowSize": sizeDict
        ]
        UserDefaults.standard.set(settings, forKey: settingsKey)
    }
    
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([AppItem].self, from: data) {
            self.apps = decoded
        }
        
        if let settings = UserDefaults.standard.dictionary(forKey: settingsKey) {
            if let size = settings["iconSize"] as? CGFloat { self.iconSize = size }
            if let list = settings["isListView"] as? Bool { self.isListView = list }
            
            if let sizeDict = settings["lastWindowSize"] as? [String: CGFloat],
               let w = sizeDict["width"], let h = sizeDict["height"] {
                self.lastWindowSize = CGSize(width: w, height: h)
            }
        }
    }
    
    func launch(_ app: AppItem) {
        if let url = app.url {
            let access = url.startAccessingSecurityScopedResource()
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            NSWorkspace.shared.openApplication(at: url, configuration: config) { _, _ in
                DispatchQueue.main.async { NSApp.hide(nil) }
            }
            if access { url.stopAccessingSecurityScopedResource() }
        }
    }
    
    func removeApp(id: UUID) {
        apps.removeAll { $0.id == id }
        saveApps()
    }
    
    func saveApps() {
        if let encoded = try? JSONEncoder().encode(apps) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
}
