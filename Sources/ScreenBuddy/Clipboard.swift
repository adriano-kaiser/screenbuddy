import AppKit

enum Clipboard {
    /// Puts the file reference and the image data on the clipboard as one item, so apps pick whichever they understand.
    static func copy(_ url: URL) {
        let item = NSPasteboardItem()
        item.setString(url.absoluteString, forType: .fileURL)

        if let data = try? Data(contentsOf: url), let image = NSImage(data: data), let tiff = image.tiffRepresentation {
            if url.pathExtension.lowercased() == "png" {
                item.setData(data, forType: .png)
            } else if let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) {
                item.setData(png, forType: .png)
            }
            item.setData(tiff, forType: .tiff)
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([item])
    }
}
