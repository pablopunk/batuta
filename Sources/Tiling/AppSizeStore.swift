import Foundation
import Combine

/// Learned app sizes for each kind of screen, as stored in apps.json.
struct SavedAppSizes: Codable, Equatable {
    var laptop: [String: UnitRect] = [:]
    var external: [String: UnitRect] = [:]

    var isEmpty: Bool { laptop.isEmpty && external.isEmpty }

    subscript(usesLaptopList usesLaptopList: Bool) -> [String: UnitRect] {
        get { usesLaptopList ? laptop : external }
        set { if usesLaptopList { laptop = newValue } else { external = newValue } }
    }
}

/// Keeps learned app sizes in ~/.config/batuta/apps.json, next to config.json, so the config stays about settings.
@MainActor
final class AppSizeStore: ObservableObject {
    static let shared = AppSizeStore()
    static let fileURL = ConfigStore.directoryURL.appendingPathComponent("apps.json")

    @Published private(set) var sizes: SavedAppSizes

    /// External screens use the Laptop list unless they have their own tiling settings.
    func sizes(onBuiltInScreen: Bool) -> [String: UnitRect] {
        sizes[usesLaptopList: ConfigStore.shared.config.usesLaptopTiling(onBuiltInScreen: onBuiltInScreen)]
    }

    func set(_ rect: UnitRect?, for bundleID: String, onBuiltInScreen: Bool) {
        let usesLaptopList = ConfigStore.shared.config.usesLaptopTiling(onBuiltInScreen: onBuiltInScreen)
        var next = sizes
        next[usesLaptopList: usesLaptopList][bundleID] = rect
        guard next != sizes else { return }
        sizes = next
        save()
    }

    func reloadIfChangedOnDisk() {
        let fromDisk = Self.readFromDisk()
        if fromDisk != sizes { sizes = fromDisk }
    }

    private init() {
        sizes = Self.readFromDisk()
    }

    private static func readFromDisk() -> SavedAppSizes {
        guard let data = try? Data(contentsOf: fileURL) else { return SavedAppSizes() }
        return (try? JSONDecoder().decode(SavedAppSizes.self, from: data)) ?? SavedAppSizes()
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        do {
            try FileManager.default.createDirectory(at: ConfigStore.directoryURL, withIntermediateDirectories: true)
            try encoder.encode(sizes).write(to: Self.fileURL, options: .atomic)
        } catch {
            print("[Batuta] failed to save app sizes: \(error)")
        }
    }
}
