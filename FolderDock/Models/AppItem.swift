import Foundation
import AppKit

struct AppItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var bookmarkData: Data // Secure reference to file
    
    // Helper to resolve the URL from bookmark
    var url: URL? {
        var isStale = false
        return try? URL(resolvingBookmarkData: bookmarkData,
                        options: .withSecurityScope,
                        relativeTo: nil,
                        bookmarkDataIsStale: &isStale)
    }
    
    // Helper to get Icon
    var icon: NSImage {
        if let safeUrl = url {
            return NSWorkspace.shared.icon(forFile: safeUrl.path)
        }
        return NSImage(systemSymbolName: "questionmark.app", accessibilityDescription: nil)!
    }
}
