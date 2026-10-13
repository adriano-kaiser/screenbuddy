import AppKit
import QuickLookThumbnailing

@MainActor
final class Thumbnails {
    static let shared = Thumbnails()
    private let cache = NSCache<NSURL, NSImage>()

    func image(for url: URL, side: CGFloat, completion: @escaping (NSImage?) -> Void) {
        if let cached = cache.object(forKey: url as NSURL) {
            completion(cached)
            return
        }
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: CGSize(width: side, height: side),
            scale: NSScreen.main?.backingScaleFactor ?? 2,
            representationTypes: .thumbnail)
        QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { rep, _ in
            let image = rep?.nsImage
            DispatchQueue.main.async {
                if let image { self.cache.setObject(image, forKey: url as NSURL) }
                completion(image)
            }
        }
    }
}

/// Floating, click-through window that shows a larger thumbnail next to the dropdown.
@MainActor
final class PreviewPanel {
    private let panel: NSPanel
    private let imageView = NSImageView()
    private var currentURL: URL?
    private let maxSide: CGFloat = 320
    private let padding: CGFloat = 8
    private let gap: CGFloat = 8

    init() {
        panel = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .popUpMenu
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let background = NSVisualEffectView()
        background.material = .popover
        background.state = .active
        background.wantsLayer = true
        background.layer?.cornerRadius = 10
        background.layer?.masksToBounds = true

        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.wantsLayer = true
        imageView.layer?.cornerRadius = 5
        imageView.layer?.masksToBounds = true
        background.addSubview(imageView)
        panel.contentView = background
    }

    func show(url: URL, beside anchor: NSRect, mouseY: CGFloat) {
        currentURL = url
        Thumbnails.shared.image(for: url, side: maxSide) { [weak self] image in
            guard let self, self.currentURL == url, let image else { return }
            self.present(image, beside: anchor, mouseY: mouseY)
        }
    }

    func hide() {
        currentURL = nil
        panel.orderOut(nil)
    }

    private func present(_ image: NSImage, beside anchor: NSRect, mouseY: CGFloat) {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return }
        let scale = maxSide / max(size.width, size.height)
        let content = NSSize(width: (size.width * scale).rounded(), height: (size.height * scale).rounded())
        let frameSize = NSSize(width: content.width + 2 * padding, height: content.height + 2 * padding)

        let screen = NSScreen.screens.first { $0.frame.intersects(anchor) } ?? NSScreen.main
        let visible = screen?.visibleFrame ?? anchor

        // Prefer the left side (menu bar icons sit on the right); flip if there's no room.
        var x = anchor.minX - gap - frameSize.width
        if x < visible.minX { x = anchor.maxX + gap }
        let y = min(max(mouseY - frameSize.height / 2, visible.minY), visible.maxY - frameSize.height)

        panel.setFrame(NSRect(x: x, y: y, width: frameSize.width, height: frameSize.height), display: true)
        imageView.frame = NSRect(x: padding, y: padding, width: content.width, height: content.height)
        imageView.image = image
        panel.orderFront(nil)
    }
}
