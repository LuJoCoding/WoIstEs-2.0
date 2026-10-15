import Foundation
import SwiftData
import SwiftUI
import WidgetKit

/// Schlanker Schnappschuss eines Gegenstands für das Widget (kein Zugriff auf SwiftData in der Ansicht).
struct WidgetItem: Identifiable, Hashable {
    let id: UUID
    let name: String
    let symbol: String?
    let placeName: String?
    let placeSymbol: String?
    let placeColorHex: String?
    let note: String
    let updatedAt: Date
    let thumbnail: Data?

    /// Ortstext passend zu den Widget-Einstellungen
    func locationText(fallback: String, showPlace: Bool) -> String {
        if showPlace, let placeName {
            return note.isEmpty ? placeName : "\(placeName) · \(note)"
        }
        return note.isEmpty ? fallback : note
    }
}

/// Lädt Favoriten & letzte Einträge aus dem gemeinsamen Speicher.
enum WidgetData {
    /// App Group verfügbar UND die App hat die gemeinsame Datenbank schon angelegt – sonst Platzhalter anzeigen
    static var isAvailable: Bool { SharedStore.groupStoreExists }

    static func snapshot(of item: Item, includePhoto: Bool) -> WidgetItem {
        WidgetItem(id: item.uuid ?? UUID(),
                   name: item.name,
                   symbol: item.symbol,
                   placeName: SharedDefaults.usePlaces ? item.place?.name : nil,
                   placeSymbol: SharedDefaults.usePlaces ? item.place?.displaySymbol : nil,
                   placeColorHex: item.place?.colorHex,
                   note: item.locationNote,
                   updatedAt: item.updatedAt,
                   thumbnail: includePhoto ? item.thumbnailData : nil)
    }

    static func favorites() -> [WidgetItem] {
        guard isAvailable else { return [] }
        let context = ModelContext(SharedStore.container)
        let photos = SharedDefaults.widgetShowPhotos
        return SharedStore.fetchFavorites(context).map { snapshot(of: $0, includePhoto: photos) }
    }

    static func recent(limit: Int = 4) -> [WidgetItem] {
        guard isAvailable else { return [] }
        let context = ModelContext(SharedStore.container)
        return SharedStore.fetchRecent(context, limit: limit).map { snapshot(of: $0, includePhoto: false) }
    }

    static func item(id: UUID) -> WidgetItem? {
        guard isAvailable else { return nil }
        let context = ModelContext(SharedStore.container)
        return SharedStore.fetchItem(uuid: id, context).map { snapshot(of: $0, includePhoto: SharedDefaults.widgetShowPhotos) }
    }

    static var placeholderItems: [WidgetItem] {
        let now = Date.now
        return [
            WidgetItem(id: UUID(), name: "Keys", symbol: "key.fill", placeName: "Kitchen", placeSymbol: "fork.knife",
                       placeColorHex: nil, note: "", updatedAt: now.addingTimeInterval(-7200), thumbnail: nil),
            WidgetItem(id: UUID(), name: "Wallet", symbol: "wallet.pass.fill", placeName: "Hallway", placeSymbol: "door.left.hand.open",
                       placeColorHex: nil, note: "", updatedAt: now.addingTimeInterval(-86400), thumbnail: nil),
            WidgetItem(id: UUID(), name: "Passport", symbol: "person.text.rectangle.fill", placeName: "Office", placeSymbol: "desktopcomputer",
                       placeColorHex: nil, note: "", updatedAt: now.addingTimeInterval(-3 * 86400), thumbnail: nil),
            WidgetItem(id: UUID(), name: "Headphones", symbol: "headphones", placeName: "Backpack", placeSymbol: "backpack.fill",
                       placeColorHex: nil, note: "", updatedAt: now.addingTimeInterval(-600), thumbnail: nil),
        ]
    }
}

// MARK: - Gemeinsame Bausteine

struct WidgetTheme {
    let colors = ThemeColors.current()
    let language = SharedDefaults.language
    let showPlace = SharedDefaults.widgetShowPlace
    let privacy = SharedDefaults.widgetPrivacy

    func t(_ key: Str) -> String { Strings.text(key, language: language) }

    /// „vor 2 Std.“ / „2 hr ago“ – aktualisiert sich im Widget selbstständig
    @ViewBuilder
    func relative(_ date: Date) -> some View {
        if language == .de {
            Text("\(t(.ago)) \(Text(date, style: .relative))")
        } else {
            Text("\(Text(date, style: .relative)) \(t(.ago))")
        }
    }
}

/// Eine Kachel wie auf der Startseite der App.
struct WidgetTile: View {
    let item: WidgetItem
    let theme: WidgetTheme
    var compact = false
    /// Ohne eigenen Hintergrund/Rand (kleines Widget: der Container ist die Kachel)
    var bare = false

    @Environment(\.widgetRenderingMode) private var renderingMode

    private var fill: Color {
        renderingMode == .fullColor ? theme.colors.tile : Color.white.opacity(0.12)
    }
    private var text: Color {
        renderingMode == .fullColor ? theme.colors.onTile : .white
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if !bare, renderingMode == .fullColor, let data = item.thumbnail, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .overlay(Color.black.opacity(0.45))
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    if let symbol = item.symbol {
                        Image(systemName: symbol).imageScale(.small).widgetAccentable()
                    }
                    Text(item.name)
                        .font(compact ? .caption.weight(.semibold) : .subheadline.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Spacer(minLength: 0)
                HStack(spacing: 3) {
                    Image(systemName: theme.showPlace ? (item.placeSymbol ?? "mappin.and.ellipse") : "mappin.and.ellipse")
                        .imageScale(.small)
                    Text(item.locationText(fallback: theme.t(.photoOnly), showPlace: theme.showPlace))
                        .lineLimit(compact ? 1 : 2)
                }
                .font(.caption2)
                .privacySensitive(theme.privacy)
                theme.relative(item.updatedAt)
                    .font(.caption2)
                    .opacity(0.8)
                    .lineLimit(1)
            }
            .foregroundStyle(item.thumbnail != nil && renderingMode == .fullColor ? Color.white : text)
            .padding(bare ? 0 : (compact ? 8 : 10))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(bare ? Color.clear : fill)
        .clipShape(RoundedRectangle(cornerRadius: bare ? 0 : 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.black.opacity(bare ? 0 : 0.25), lineWidth: 1)
        )
    }
}

struct WidgetEmptyTile: View {
    let theme: WidgetTheme
    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "star")
            Text(theme.t(.favoriteSlot)).font(.caption2)
        }
        .foregroundStyle((renderingMode == .fullColor ? theme.colors.onBackground : .white).opacity(0.6))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder((renderingMode == .fullColor ? theme.colors.onBackground : .white).opacity(0.3),
                              style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
        )
    }
}

struct WidgetUnavailableView: View {
    let theme: WidgetTheme

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "mappin.and.ellipse").font(.title2)
            Text(theme.t(.widgetPlaceholder))
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(theme.colors.onBackground)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
