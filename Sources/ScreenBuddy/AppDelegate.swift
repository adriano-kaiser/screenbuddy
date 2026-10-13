import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private let model = AppModel()
    private let preview = PreviewPanel()
    private var outsideClickMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "photo.stack", accessibilityDescription: "ScreenBuddy")
            button.target = self
            button.action = #selector(togglePopover(_:))
        }

        model.onHover = { [weak self] url in self?.updatePreview(url) }
        model.onDismiss = { [weak self] in self?.popover.performClose(nil) }

        popover.contentViewController = NSHostingController(rootView: ScreenshotListView(model: model))
        popover.contentSize = NSSize(width: ScreenshotListView.width, height: ScreenshotListView.height)
        popover.behavior = .transient
        popover.delegate = self

        LoginItem.enableOnFirstRun()
        model.refreshLoginState()
    }

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
            return
        }
        model.reload()
        NSApp.activate()
        popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
        // A menu bar app often can't become active (macOS 14+ activation is cooperative),
        // and then .transient never sees clicks elsewhere. Clicks in other apps arrive
        // here instead; mouse events need no extra permission. Drags out of the list start
        // inside this app, so they don't trigger it.
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] _ in
            MainActor.assumeIsolated { self?.popover.performClose(nil) }
        }
    }

    private func updatePreview(_ url: URL?) {
        guard let url, popover.isShown, let anchor = popover.contentViewController?.view.window?.frame else {
            preview.hide()
            return
        }
        preview.show(url: url, beside: anchor, mouseY: NSEvent.mouseLocation.y)
    }

    func popoverDidClose(_ notification: Notification) {
        preview.hide()
        if let monitor = outsideClickMonitor {
            NSEvent.removeMonitor(monitor)
            outsideClickMonitor = nil
        }
    }
}
