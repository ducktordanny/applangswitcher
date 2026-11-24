import SwiftUI

@main
struct AppLangswitcherApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra("AppLangswitcher", systemImage: "keyboard") {
            MenuView().environmentObject(model)
        }
        .menuBarExtraStyle(.window)
    }
}
