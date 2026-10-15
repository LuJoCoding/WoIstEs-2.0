import SwiftUI
import WidgetKit
import AppIntents

// MARK: - Kleines Widget + Sperrbildschirm: EIN Favorit (konfigurierbar)

struct FavoriteEntry: TimelineEntry {
    let date: Date
    let item: WidgetItem?
    let available: Bool
    let theme: WidgetTheme
}

struct FavoriteProvider: AppIntentTimelineProvider {
    typealias Entry = FavoriteEntry
    typealias Intent = SelectFavoriteIntent

    func placeholder(in context: Context) -> FavoriteEntry {
        FavoriteEntry(date: .now, item: WidgetData.placeholderItems.first, available: true, theme: WidgetTheme())
    }

    func snapshot(for configuration: SelectFavoriteIntent, in context: Context) async -> FavoriteEntry {
        if context.isPreview { return placeholder(in: context) }
        return load(configuration)
    }

    func timeline(for configuration: SelectFavoriteIntent, in context: Context) async -> Timeline<FavoriteEntry> {
        let entry = load(configuration)
        // Relative Zeiten aktualisieren sich selbst; einmal pro Stunde den Inhalt neu laden
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now.addingTimeInterval(3600)
        return Timeline(entries: [entry], policy: .after(next))
    }

    private func load(_ configuration: SelectFavoriteIntent) -> FavoriteEntry {
        let theme = WidgetTheme()
        guard WidgetData.isAvailable else {
            return FavoriteEntry(date: .now, item: nil, available: false, theme: theme)
        }
        let item: WidgetItem?
        if let chosen = configuration.item {
            item = WidgetData.item(id: chosen.id) ?? WidgetData.favorites().first
        } else {
            item = WidgetData.favorites().first
        }
        return FavoriteEntry(date: .now, item: item, available: true, theme: theme)
    }
}

struct FavoriteWidgetView: View {
    let entry: FavoriteEntry
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        Group {
            switch family {
            case .accessoryCircular: circular
            case .accessoryRectangular: rectangular
            case .accessoryInline: inline
            default: small
            }
        }
        .widgetURL(entry.item.map { DeepLink.itemURL($0.id) } ?? DeepLink.newEntryURL)
    }

    // Homescreen klein: der ganze Container ist die Kachel (Foto als Hintergrund, wenn vorhanden)
    private var small: some View {
        Group {
            if !entry.available {
                WidgetUnavailableView(theme: entry.theme)
            } else if let item = entry.item {
                WidgetTile(item: item, theme: entry.theme, bare: true)
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "star").font(.title2)
                    Text(entry.theme.t(.widgetNoFavorites)).font(.caption).multilineTextAlignment(.center)
                }
                .foregroundStyle(entry.theme.colors.onBackground)
            }
        }
        .containerBackground(for: .widget) {
            if renderingMode != .fullColor {
                Color.clear
            } else if let item = entry.item, let data = item.thumbnail, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill().overlay(Color.black.opacity(0.45))
            } else if entry.item != nil {
                entry.theme.colors.tile
            } else {
                entry.theme.colors.background
            }
        }
    }

    // Sperrbildschirm
    private var circular: some View {
        ZStack {
            AccessoryWidgetBackground()
            Image(systemName: entry.item?.symbol ?? "mappin.and.ellipse")
                .font(.title2.weight(.semibold))
                .widgetAccentable()
        }
        .containerBackground(for: .widget) { Color.clear }
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let item = entry.item {
                HStack(spacing: 4) {
                    if let symbol = item.symbol { Image(systemName: symbol).imageScale(.small) }
                    Text(item.name).font(.headline).lineLimit(1)
                }
                .widgetAccentable()
                Text(item.locationText(fallback: entry.theme.t(.photoOnly), showPlace: entry.theme.showPlace))
                    .font(.caption)
                    .lineLimit(1)
                    .privacySensitive(entry.theme.privacy)
                entry.theme.relative(item.updatedAt)
                    .font(.caption2)
                    .opacity(0.8)
            } else {
                Text(entry.available ? entry.theme.t(.widgetNoFavorites) : entry.theme.t(.widgetPlaceholder))
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(for: .widget) { Color.clear }
    }

    private var inline: some View {
        Group {
            if let item = entry.item {
                Text("\(item.name) · \(item.locationText(fallback: entry.theme.t(.photoOnly), showPlace: entry.theme.showPlace))")
                    .privacySensitive(entry.theme.privacy)
            } else {
                Text(entry.theme.t(.widgetNoFavorites))
            }
        }
        .containerBackground(for: .widget) { Color.clear }
    }
}

struct FavoriteWidget: Widget {
    let kind = "de.lujo3d.WoIstEs.favorite"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectFavoriteIntent.self, provider: FavoriteProvider()) { entry in
            FavoriteWidgetView(entry: entry)
        }
        .configurationDisplayName("Favorite")
        .description("One favorite with place and time.")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}
