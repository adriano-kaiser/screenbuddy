import SwiftUI

struct ScreenshotListView: View {
    static let width: CGFloat = 340
    static let height: CGFloat = 480

    @ObservedObject var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if model.items.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(model.items) { item in
                            ScreenshotRow(item: item, model: model)
                        }
                    }
                    .padding(6)
                }
                .id(model.reloadToken) // jump back to the top each time the dropdown opens
            }
            Divider()
            footer
        }
        .frame(width: Self.width, height: Self.height)
    }

    private var header: some View {
        HStack {
            Text(model.folder.lastPathComponent).font(.headline)
            Spacer()
            Text("\(model.items.count) files").font(.caption).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "photo.on.rectangle.angled").font(.largeTitle).foregroundStyle(.tertiary)
            Text("No screenshots yet").foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Button("Open Folder") { model.openFolder() }
            Toggle("Start at Login", isOn: Binding(
                get: { model.launchAtLogin },
                set: { model.setLaunchAtLogin($0) }))
                .toggleStyle(.checkbox)
            Spacer()
            Button("Quit") { model.quit() }
        }
        .buttonStyle(.borderless)
        .font(.callout)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

struct ScreenshotRow: View {
    let item: Screenshot
    @ObservedObject var model: AppModel
    private var isHovered: Bool { model.hovered == item.id }
    private var isCopied: Bool { model.copiedID == item.id }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isCopied ? "checkmark.circle.fill" : (item.isVideo ? "video" : "photo"))
                .foregroundStyle(isCopied ? Color.green : Color.secondary)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.name).lineLimit(1).truncationMode(.middle)
                Text(isCopied ? "Copied to clipboard" : RelativeDate.string(for: item.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Color.accentColor.opacity(0.18) : Color.clear))
        .contentShape(Rectangle())
        .onHover { inside in model.hover(item.url, inside: inside) }
        .onTapGesture { model.copy(item) }
        .onDrag {
            model.dragStarted()
            return NSItemProvider(object: item.url as NSURL)
        }
    }
}

enum RelativeDate {
    private static let relative: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .full
        return f
    }()

    private static let absolute: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("EEE d MMM HH:mm")
        return f
    }()

    static func string(for date: Date) -> String {
        let age = Date().timeIntervalSince(date)
        if age < 60 { return "just now" }
        if age < 12 * 3600 { return relative.localizedString(for: date, relativeTo: Date()) }
        return absolute.string(from: date)
    }
}
