import AppKit
import Carbon
import ServiceManagement
import UniformTypeIdentifiers

struct Rule: Codable, Identifiable, Hashable {
    let bundleID: String
    var appName: String
    var sourceID: String
    var id: String { bundleID }
}

struct AppInfo: Identifiable, Hashable {
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

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var rules: [Rule] { didSet { save() } }
    @Published private(set) var sources: [InputSource] = []
    @Published private(set) var runningApps: [AppInfo] = []

    private static let rulesKey = "rules"
    private var observers: [NSObjectProtocol] = []

    init() {
        rules = Self.loadRules()
        refreshSources()
        refreshRunningApps()
        observe()
        applyRuleToFrontmost()
    }

    var addableApps: [AppInfo] {
        let taken = Set(rules.map(\.bundleID))
        return runningApps.filter { !taken.contains($0.bundleID) }
    }

    var launchAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            objectWillChange.send()
            do {
                if newValue { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            } catch {
                NSLog("AppLangswitcher: launch at login toggle failed: \(error)")
            }
        }
    }

    func add(_ app: AppInfo) {
        guard !rules.contains(where: { $0.bundleID == app.bundleID }) else { return }
        let sourceID = InputSourceService.currentID() ?? sources.first?.id ?? ""
        rules = (rules + [Rule(bundleID: app.bundleID, appName: app.name, sourceID: sourceID)])
            .sorted { $0.appName.localizedCaseInsensitiveCompare($1.appName) == .orderedAscending }
    }

    func chooseApps() {
        let panel = NSOpenPanel()
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = true
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK else { return }
        panel.urls.compactMap(AppInfo.init(url:)).forEach(add)
    }

    func setSource(_ sourceID: String, for bundleID: String) {
        guard let index = rules.firstIndex(where: { $0.bundleID == bundleID }) else { return }
        rules[index].sourceID = sourceID
        applyRuleToFrontmost()
    }

    func remove(_ rule: Rule) {
        rules.removeAll { $0.bundleID == rule.bundleID }
    }

    private func applyRuleToFrontmost() {
        applyRule(for: NSWorkspace.shared.frontmostApplication?.bundleIdentifier)
    }

    private func applyRule(for bundleID: String?) {
        guard let rule = rules.first(where: { $0.bundleID == bundleID }) else { return }
        InputSourceService.select(id: rule.sourceID)
    }

    private func refreshSources() {
        sources = InputSourceService.enabledKeyboardSources()
    }

    private func refreshRunningApps() {
        runningApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular && $0.bundleIdentifier != Bundle.main.bundleIdentifier }
            .compactMap(AppInfo.init)
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func observe() {
        let workspace = NSWorkspace.shared.notificationCenter
        observers.append(workspace.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
        ) { [weak self] note in
            let bundleID = (note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)?.bundleIdentifier
            MainActor.assumeIsolated { self?.applyRule(for: bundleID) }
        })
        for name in [NSWorkspace.didLaunchApplicationNotification, NSWorkspace.didTerminateApplicationNotification] {
            observers.append(workspace.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.refreshRunningApps() }
            })
        }
        observers.append(DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name(kTISNotifyEnabledKeyboardInputSourcesChanged as String), object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.refreshSources() }
        })
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(rules) else { return }
        UserDefaults.standard.set(data, forKey: Self.rulesKey)
    }

    private static func loadRules() -> [Rule] {
        guard let data = UserDefaults.standard.data(forKey: rulesKey),
              let rules = try? JSONDecoder().decode([Rule].self, from: data)
        else { return [] }
        return rules
    }
}
