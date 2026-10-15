import AppIntents
import SwiftData
import SwiftUI
import UIKit

// MARK: - Hilfen

private enum IntentSupport {
    static var language: AppLanguage { SharedDefaults.language }
    static func t(_ key: Str) -> String { Strings.text(key, language: language) }
    @MainActor static var context: ModelContext { SharedStore.container.mainContext }

    /// Lesende Intents verlangen Entsperren, wenn die App-Sperre aktiv ist oder „bei gesperrtem iPhone vorlesen“ aus ist.
    static var readPolicy: IntentAuthenticationPolicy {
        (SharedDefaults.lockEnabled || !SharedDefaults.siriAllowLocked) ? .requiresAuthentication : .alwaysAllowed
    }

    static func since(_ date: Date) -> String {
        String(format: t(.siriSince), RelativeTime.string(for: date, language: language))
    }

    /// „Dein Schlüssel liegt in „Küche“ (oberste Schublade) – seit 2 Std.“
    static func describe(_ item: Item) -> String {
        let when = since(item.updatedAt)
        if SharedDefaults.usePlaces, let place = item.place {
            let detail = item.locationNote.isEmpty ? "" : " (\(item.locationNote))"
            return String(format: t(.siriFoundAt), item.name, place.name, detail, when)
        }
        if !item.locationNote.isEmpty {
            return String(format: t(.siriFoundNote), item.name, item.locationNote, when)
        }
        return String(format: t(.siriSeePhoto), item.name, when)
    }
}

/// Kleine Snippet-Ansicht in den Nutzerfarben
struct ItemSnippetView: View {
    let name: String
    let symbol: String?
    let location: String
    let when: String
    let thumbnail: Data?

    private let theme = ThemeColors.current()

    var body: some View {
        HStack(spacing: 14) {
            if let thumbnail, let image = UIImage(data: thumbnail) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous).fill(theme.tile)
                    Image(systemName: symbol ?? "shippingbox.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(theme.onTile)
                }
                .frame(width: 64, height: 64)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(name).font(.headline)
                Text(location).font(.subheadline)
                Text(when).font(.caption).opacity(0.75)
            }
            .foregroundStyle(theme.onList)
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(theme.list))
        .padding(8)
        .background(theme.background)
    }
}

// MARK: - „Wo ist …?“

struct FindItemIntent: AppIntent {
    static var title: LocalizedStringResource = "Where is…"
    static var description = IntentDescription("Tells you where an item was last put.")
    static var authenticationPolicy: IntentAuthenticationPolicy { IntentSupport.readPolicy }

    @Parameter(title: "Item")
    var item: ItemEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Where is \(\.$item)?")
    }

    init() {}
    init(item: ItemEntity) { self.item = item }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let context = IntentSupport.context
        guard let found = SharedStore.fetchItem(uuid: item.id, context) else {
            return .result(dialog: IntentDialog("\(IntentSupport.t(.siriItemNotFound))")) { AnyView(EmptyView()) }
        }
        let text = IntentSupport.describe(found)
        let location = found.locationText(fallback: IntentSupport.t(.seePhoto))
        let snippet = ItemSnippetView(name: found.name, symbol: found.symbol, location: location,
                                      when: IntentSupport.since(found.updatedAt), thumbnail: found.thumbnailData)
        return .result(dialog: IntentDialog("\(text)")) { AnyView(snippet) }
    }
}

// MARK: - „… liegt im …“ (bestehender Gegenstand, per Siri)

struct SetLocationIntent: AppIntent {
    static var title: LocalizedStringResource = "Save location"
    static var description = IntentDescription("Saves where an item is now. The previous location is replaced.")
    static var authenticationPolicy: IntentAuthenticationPolicy { .requiresAuthentication }

    @Parameter(title: "Item")
    var item: ItemEntity

    @Parameter(title: "Place")
    var place: PlaceEntity

    @Parameter(title: "Note")
    var note: String?

    static var parameterSummary: some ParameterSummary {
        Summary("\(\.$item) is in \(\.$place)") {
            \.$note
        }
    }

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = IntentSupport.context
        guard let found = SharedStore.fetchItem(uuid: item.id, context) else {
            return .result(dialog: IntentDialog("\(IntentSupport.t(.siriItemNotFound))"))
        }
        guard let target = SharedStore.fetchPlace(uuid: place.id, context) else {
            return .result(dialog: IntentDialog("\(IntentSupport.t(.siriPlaceNotFound))"))
        }
        return .result(dialog: IntentDialog("\(IntentActions.relocate(found, to: target, note: note, context: context))"))
    }
}

// MARK: - „… liegt im …“ (freier Name, für die Kurzbefehle-App – legt neue Gegenstände an)

struct SetLocationByNameIntent: AppIntent {
    static var title: LocalizedStringResource = "Save location by name"
    static var description = IntentDescription("Saves where an item is now. Creates the item if it doesn't exist yet.")
    static var authenticationPolicy: IntentAuthenticationPolicy { .requiresAuthentication }

    @Parameter(title: "Item name")
    var itemName: String

    @Parameter(title: "Place")
    var place: PlaceEntity

    @Parameter(title: "Note")
    var note: String?

    static var parameterSummary: some ParameterSummary {
        Summary("\(\.$itemName) is in \(\.$place)") {
            \.$note
        }
    }

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = IntentSupport.context
        guard let target = SharedStore.fetchPlace(uuid: place.id, context) else {
            return .result(dialog: IntentDialog("\(IntentSupport.t(.siriPlaceNotFound))"))
        }
        let name = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        // Gleicher Name (Groß-/Kleinschreibung, Akzente egal) → bestehenden Eintrag überschreiben
        let existing = SharedStore.fetchAllItems(context).first {
            $0.name.compare(name, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
        let item: Item
        if let existing {
            item = existing
        } else {
            item = Item(name: name)
            context.insert(item)
        }
        return .result(dialog: IntentDialog("\(IntentActions.relocate(item, to: target, note: note, context: context))"))
    }
}

@MainActor
enum IntentActions {
    /// Dieselbe Logik wie in der App: alter Ort (inkl. Foto) wird vollständig ersetzt.
    static func relocate(_ item: Item, to place: Place, note: String?, context: ModelContext) -> String {
        let trimmed = (note ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        item.relocate(note: trimmed, photoData: nil, thumbnailData: nil, place: place)
        try? context.save()
        ReminderManager.shared.schedule(for: item)
        WidgetReloader.reload()
        let detail = trimmed.isEmpty ? "" : " (\(trimmed))"
        return String(format: IntentSupport.t(.siriSaved), item.name, place.name, detail)
    }
}

// MARK: - „Was liegt im …?“

struct ItemsAtPlaceIntent: AppIntent {
    static var title: LocalizedStringResource = "What's in…"
    static var description = IntentDescription("Lists the items at a place.")
    static var authenticationPolicy: IntentAuthenticationPolicy { IntentSupport.readPolicy }

    @Parameter(title: "Place")
    var place: PlaceEntity

    static var parameterSummary: some ParameterSummary {
        Summary("What's in \(\.$place)?")
    }

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<[ItemEntity]> {
        let context = IntentSupport.context
        guard let target = SharedStore.fetchPlace(uuid: place.id, context) else {
            return .result(value: [ItemEntity](), dialog: IntentDialog("\(IntentSupport.t(.siriPlaceNotFound))"))
        }
        let items = target.items.sorted { $0.updatedAt > $1.updatedAt }
        if items.isEmpty {
            return .result(value: [ItemEntity](), dialog: IntentDialog("\(String(format: IntentSupport.t(.siriNothingAt), target.name))"))
        }
        let names = items.map(\.name).joined(separator: ", ")
        return .result(value: items.map { ItemEntity($0) },
                       dialog: IntentDialog("\(String(format: IntentSupport.t(.siriListAt), target.name, names))"))
    }
}

// MARK: - „Neuer Foto-Eintrag“ (öffnet die App direkt in der Kamera)

struct OpenNewPhotoIntent: AppIntent {
    static var title: LocalizedStringResource = "New photo entry"
    static var description = IntentDescription("Opens the app and starts the camera.")
    static var openAppWhenRun = true

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {
        _ = await UIApplication.shared.open(DeepLink.newPhotoURL)
        return .result()
    }
}

/// Öffnet die App im Plus-Menü (wird vom Widget-Knopf genutzt)
struct OpenNewEntryIntent: AppIntent {
    static var title: LocalizedStringResource = "New entry"
    static var description = IntentDescription("Opens the app to add a new entry.")
    static var openAppWhenRun = true

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {
        _ = await UIApplication.shared.open(DeepLink.newEntryURL)
        return .result()
    }
}
