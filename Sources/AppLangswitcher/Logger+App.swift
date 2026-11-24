import OSLog

extension Logger {
    static let app = Logger(subsystem: Bundle.main.bundleIdentifier ?? "AppLangswitcher", category: "app")
}
