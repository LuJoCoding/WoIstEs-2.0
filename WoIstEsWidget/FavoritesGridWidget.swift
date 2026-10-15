import SwiftUI
import WidgetKit

// MARK: - Mittel: 4 Favoriten · Groß: Favoriten + Zuletzt verwendet

struct GridEntry: TimelineEntry {
    let date: Date
    let favorites: [WidgetItem]
    let recent: [WidgetItem]
    let available: Bool
    let theme: WidgetTheme
}

struct GridProvider: TimelineProvider {
    func placeholder(in context: Context) -> GridEntry {
        let items = WidgetData.placeholderItems
        return GridEntry(date: .now, favorites: items, recent: items, available: true, theme: WidgetTheme())
    }

    func getSnapshot(in context: Context, completion: @escaping (GridEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : load())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GridEntry>) -> Void) {
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now.addingTimeInterval(3600)
        completion(Timeline(entries: [load()], policy: .after(next)))
    }

    private func load() -> GridEntry {
        let theme = WidgetTheme()
        guard WidgetData.isAvailable else {
            return GridEntry(date: .now, favorites: [], recent: [], available: false, theme: theme)
        }
        return GridEntry(date: .now, favorites: WidgetData.favorites(), recent: WidgetData.recent(), available: true, theme: theme)
    }
}

struct FavoritesGridView: View {
    let entry: GridEntry
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var renderingMode

    private var theme: WidgetTheme { entry.theme }
    private var isLarge: Bool { family == .systemLarge }

    var body: some View {
        Group {
            if !entry.available {
                WidgetUnavailableView(theme: theme)
            } else {
                VStack(spacing: 8) {
                    grid
                    if isLarge {
                        recentList
                    }
                }
                .padding(10)
            }
        }
        .containerBackground(for: .widget) {
            if renderingMode == .fullColor { theme.colors.background } else { Color.clear }
        }
        .widgetURL(DeepLink.newEntryURL)
    }

    private var grid: some View {
        let favs = entry.favorites
        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
            ForEach(0..<4, id: \.self) { index in
                if index < favs.count {
                    Link(destination: DeepLink.itemURL(favs[index].id)) {
                        WidgetTile(item: favs[index], theme: theme, compact: !isLarge)
                    }
                } else {
                    Link(destination: DeepLink.newEntryURL) {
                        WidgetEmptyTile(theme: theme)
                    }
                }
            }
        }
    }

    private var recentList: some View {
        VStack(spacing: 5) {
            HStack {
                Text(theme.t(.recentlyUsed))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(renderingMode == .fullColor ? theme.colors.onBackground : .white)
                Spacer()
                Link(destination: DeepLink.newEntryURL) {
                    Label(theme.t(.widgetAdd), systemImage: "plus")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(renderingMode == .fullColor ? theme.colors.onAccent : .white)
                        .padding(.horizontal, 8)
                        .frame(height: 22)
                        .background(Capsule().fill(renderingMode == .fullColor ? theme.colors.accent : Color.white.opacity(0.2)))
                }
            }
            ForEach(entry.recent) { item in
                Link(destination: DeepLink.itemURL(item.id)) {
                    HStack(spacing: 6) {
                        if let symbol = item.symbol { Image(systemName: symbol).imageScale(.small).widgetAccentable() }
                        Text(item.name).font(.caption.weight(.medium)).lineLimit(1)
                        if theme.showPlace, let placeSymbol = item.placeSymbol {
                            Image(systemName: placeSymbol).imageScale(.small).opacity(0.7)
                                .privacySensitive(theme.privacy)
                        }
                        Spacer(minLength: 4)
                        theme.relative(item.updatedAt).font(.caption2).opacity(0.75)
                    }
                    .foregroundStyle(renderingMode == .fullColor ? theme.colors.onList : .white)
                    .padding(.horizontal, 8)
                    .frame(height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(renderingMode == .fullColor ? theme.colors.list : Color.white.opacity(0.12))
                    )
                }
            }
            if entry.recent.isEmpty {
                Text(theme.t(.emptyRecent))
                    .font(.caption2)
                    .foregroundStyle((renderingMode == .fullColor ? theme.colors.onBackground : .white).opacity(0.7))
            }
        }
    }
}

struct FavoritesGridWidget: Widget {
    let kind = "de.lujo3d.WoIstEs.favorites"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GridProvider()) { entry in
            FavoritesGridView(entry: entry)
        }
        .configurationDisplayName("Favorites")
        .description("Your 4 favorites and the latest entries.")
        .supportedFamilies([.systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}
