import AppKit

struct Screenshot: Identifiable, Hashable {
    let url: URL
    let date: Date

    var id: URL { url }
    var name: String { url.deletingPathExtension().lastPathComponent }
    var isVideo: Bool { ["mov", "mp4", "m4v"].contains(url.pathExtension.lowercased()) }
}

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var items: [Screenshot] = []
    @Published private(set) var folder: URL = ScreenshotFolder.current()
    @Published private(set) var reloadToken = UUID()
    @Published private(set) var copiedID: URL?
    @Published private(set) var launchAtLogin = false

    var onHover: (URL?) -> Void = { _ in }
    var onDismiss: () -> Void = {}

    /// Row under the mouse. Published so rows can highlight without @State (the CLT toolchain lacks SwiftUI's macro plugin).
    @Published private(set) var hovered: URL?

    func reload() {
        folder = ScreenshotFolder.current()
        let keys: [URLResourceKey] = [.creationDateKey, .contentModificationDateKey, .isRegularFileKey]
        let urls = (try? FileManager.default.contentsOfDirectory(
            at: folder, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles])) ?? []

        items = urls.compactMap { url in
            guard let values = try? url.resourceValues(forKeys: Set(keys)), values.isRegularFile == true else { return nil }
            return Screenshot(url: url, date: values.creationDate ?? values.contentModificationDate ?? .distantPast)
        }
        .sorted { $0.date > $1.date }
        reloadToken = UUID()
    }

    func hover(_ url: URL, inside: Bool) {
        if inside {
            hovered = url
            onHover(url)
        } else if hovered == url {
            hovered = nil
            // Short delay so moving between rows doesn't flicker the preview.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
                guard let self, self.hovered == nil else { return }
                self.onHover(nil)
            }
        }
    }

    func copy(_ item: Screenshot) {
        Clipboard.copy(item.url)
        copiedID = item.id
        hovered = nil
        onHover(nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.onDismiss()
            self?.copiedID = nil
        }
    }

    func dragStarted() {
        hovered = nil
        onHover(nil)
    }

    func openFolder() {
        NSWorkspace.shared.open(folder)
        onDismiss()
    }

    func setLaunchAtLogin(_ on: Bool) {
        LoginItem.set(on)
        refreshLoginState()
    }

    func refreshLoginState() {
        launchAtLogin = LoginItem.isEnabled
    }

    func quit() {
        NSApp.terminate(nil)
    }
}

enum ScreenshotFolder {
    /// The folder macOS saves screenshots to (Screenshot app > Options > Save to), falling back to the Desktop.
    static func current() -> URL {
        if let path = UserDefaults(suiteName: "com.apple.screencapture")?.string(forKey: "location"), !path.isEmpty {
            return URL(fileURLWithPath: (path as NSString).expandingTildeInPath, isDirectory: true)
        }
        return FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0]
    }
}
