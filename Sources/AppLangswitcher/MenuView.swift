import SwiftUI

struct MenuView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Keyboard layout per app").font(.headline)

            if model.rules.isEmpty {
                Text("No apps yet.").foregroundStyle(.secondary)
            } else {
                ForEach(model.rules) { RuleRow(rule: $0) }
            }

            Menu("Add app") {
                ForEach(model.addableApps) { app in
                    Button(app.name) { model.add(app) }
                }
                if !model.addableApps.isEmpty { Divider() }
                Button("Choose from Applications…") { model.chooseApps() }
            }

            Divider()

            HStack {
                Toggle("Launch at login", isOn: $model.launchAtLogin)
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
            }
        }
        .padding(12)
        .frame(width: 380)
    }
}

private struct RuleRow: View {
    @EnvironmentObject private var model: AppModel
    let rule: Rule

    var body: some View {
        HStack(spacing: 8) {
            Image(nsImage: appIcon)
                .resizable()
                .frame(width: 20, height: 20)
            Text(rule.appName).lineLimit(1)
            Spacer()
            Picker("Layout", selection: Binding(
                get: { rule.sourceID },
                set: { model.setSource($0, for: rule.bundleID) }
            )) {
                ForEach(model.sources) { Text($0.name).tag($0.id) }
                if !model.sources.contains(where: { $0.id == rule.sourceID }) {
                    Text("Unavailable").tag(rule.sourceID)
                }
            }
            .labelsHidden()
            .fixedSize()
            Button { model.remove(rule) } label: {
                Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .help("Remove \(rule.appName)")
            .accessibilityLabel("Remove \(rule.appName)")
        }
    }

    private var appIcon: NSImage {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: rule.bundleID) else {
            return NSWorkspace.shared.icon(for: .application)
        }
        return NSWorkspace.shared.icon(forFile: url.path)
    }
}
