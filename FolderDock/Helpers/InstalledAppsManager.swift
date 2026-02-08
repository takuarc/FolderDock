import AppKit

struct SystemApp: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let url: URL
    var icon: NSImage {
        NSWorkspace.shared.icon(forFile: url.path)
    }
}

class InstalledAppsManager {
    static func fetchApps() -> [SystemApp] {
        let fileManager = FileManager.default
        let appFolder = URL(fileURLWithPath: "/Applications")
        
        guard let files = try? fileManager.contentsOfDirectory(at: appFolder, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) else {
            return []
        }
        
        return files
            .filter { $0.pathExtension == "app" }
            .map { SystemApp(name: $0.deletingPathExtension().lastPathComponent, url: $0) }
            .sorted { $0.name < $1.name }
    }
}
