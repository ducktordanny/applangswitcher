import AppKit

struct Rule: Codable, Identifiable {
    let bundleID: String
    var appName: String
    var sourceID: String
    var id: String { bundleID }
}

struct AppInfo: Identifiable {
    let bundleID: String
    let name: String
    var id: String { bundleID }
}

extension AppInfo {
    init?(_ app: NSRunningApplication) {
        guard let bundleID = app.bundleIdentifier else { return nil }
        self.init(bundleID: bundleID, name: app.localizedName ?? bundleID)
    }

    init?(url: URL) {
        guard let bundleID = Bundle(url: url)?.bundleIdentifier else { return nil }
        var name = FileManager.default.displayName(atPath: url.path)
        if name.hasSuffix(".app") { name = String(name.dropLast(4)) }
        self.init(bundleID: bundleID, name: name)
    }
}
