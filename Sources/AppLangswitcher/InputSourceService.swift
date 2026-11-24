import Carbon
import OSLog

struct InputSource: Identifiable {
    let id: String
    let name: String
}

enum InputSourceService {
    static func enabledKeyboardSources() -> [InputSource] {
        sources(matching: [
            kTISPropertyInputSourceCategory as String: kTISCategoryKeyboardInputSource as String,
            kTISPropertyInputSourceIsSelectCapable as String: true,
        ]).compactMap { source in
            guard let id: String = property(source, kTISPropertyInputSourceID),
                  let name: String = property(source, kTISPropertyLocalizedName)
            else { return nil }
            return InputSource(id: id, name: name)
        }
    }

    static func currentID() -> String? {
        property(TISCopyCurrentKeyboardInputSource().takeRetainedValue(), kTISPropertyInputSourceID)
    }

    static func select(id: String) {
        guard id != currentID() else { return }
        guard let source = sources(matching: [kTISPropertyInputSourceID as String: id]).first else {
            Logger.app.notice("Input source \(id, privacy: .public) is not enabled")
            return
        }
        let status = TISSelectInputSource(source)
        if status != noErr {
            Logger.app.error("Selecting \(id, privacy: .public) failed with OSStatus \(status)")
        }
    }

    private static func sources(matching filter: [String: Any]) -> [TISInputSource] {
        TISCreateInputSourceList(filter as CFDictionary, false)?.takeRetainedValue() as? [TISInputSource] ?? []
    }

    private static func property<T>(_ source: TISInputSource, _ key: CFString) -> T? {
        guard let ptr = TISGetInputSourceProperty(source, key) else { return nil }
        return Unmanaged<AnyObject>.fromOpaque(ptr).takeUnretainedValue() as? T
    }
}
