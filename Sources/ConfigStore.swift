import Foundation
import Combine
import SwiftUI

/// Reads and writes ~/.config/batuta/config.json, and reloads it (and apps.json) when edited by hand.
@MainActor
final class ConfigStore: ObservableObject {
    static let shared = ConfigStore()

    static let directoryURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".config/batuta", isDirectory: true)
    static let fileURL = directoryURL.appendingPathComponent("config.json")

    /// Writes go through `update` so identical values never publish: MenuBarExtra re-sets its binding on every
    /// render, and publishing those no-op writes made SwiftUI loop forever.
    @Published private(set) var config: BatutaConfig

    func update(_ change: (inout BatutaConfig) -> Void) {
        var next = config
        change(&next)
        guard next != config else { return }
        config = next
        save()
    }

    func binding<Value>(_ keyPath: WritableKeyPath<BatutaConfig, Value>) -> Binding<Value> {
        Binding(
            get: { self.config[keyPath: keyPath] },
            set: { newValue in self.update { $0[keyPath: keyPath] = newValue } }
        )
    }

    private var directoryWatcher: DispatchSourceFileSystemObject?

    private init() {
        config = Self.readConfigFromDisk() ?? BatutaConfig()
        if !FileManager.default.fileExists(atPath: Self.fileURL.path) { save() }
        watchDirectoryForExternalEdits()
    }

    private static func readConfigFromDisk() -> BatutaConfig? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        do {
            return try JSONDecoder().decode(BatutaConfig.self, from: data)
        } catch {
            print("[Batuta] ignoring invalid \(fileURL.path): \(error)")
            return nil
        }
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        do {
            try FileManager.default.createDirectory(at: Self.directoryURL, withIntermediateDirectories: true)
            try encoder.encode(config).write(to: Self.fileURL, options: .atomic)
        } catch {
            print("[Batuta] failed to save config: \(error)")
        }
    }

    /// Editors replace the file atomically, so the directory is watched instead of the file itself.
    private func watchDirectoryForExternalEdits() {
        try? FileManager.default.createDirectory(at: Self.directoryURL, withIntermediateDirectories: true)
        let descriptor = open(Self.directoryURL.path, O_EVTONLY)
        guard descriptor >= 0 else { return }

        let watcher = DispatchSource.makeFileSystemObjectSource(fileDescriptor: descriptor, eventMask: .write, queue: .main)
        watcher.setEventHandler { [weak self] in
            MainActor.assumeIsolated {
                self?.reloadIfChangedOnDisk()
                AppSizeStore.shared.reloadIfChangedOnDisk()
            }
        }
        watcher.setCancelHandler { close(descriptor) }
        watcher.resume()
        directoryWatcher = watcher
    }

    private func reloadIfChangedOnDisk() {
        guard let fromDisk = Self.readConfigFromDisk(), fromDisk != config else { return }
        config = fromDisk
    }
}
