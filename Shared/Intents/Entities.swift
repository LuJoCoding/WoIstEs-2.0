import AppIntents
import SwiftData
import Foundation

// MARK: - Gegenstand (für Siri, Kurzbefehle und Widget-Konfiguration)

struct ItemEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Item")
    static var defaultQuery = ItemEntityQuery()

    var id: UUID
    var name: String
    var symbol: String?

    var displayRepresentation: DisplayRepresentation {
        if let symbol {
            return DisplayRepresentation(title: "\(name)", image: .init(systemName: symbol))
        }
        return DisplayRepresentation(title: "\(name)")
    }

    @MainActor
    init(_ item: Item) {
        id = item.stableID
        name = item.name
        symbol = item.symbol
    }
}

struct ItemEntityQuery: EntityStringQuery {
    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [ItemEntity] {
        let context = SharedStore.container.mainContext
        return identifiers.compactMap { id in
            SharedStore.fetchItem(uuid: id, context).map { ItemEntity($0) }
        }
    }

    @MainActor
    func entities(matching string: String) async throws -> [ItemEntity] {
        let context = SharedStore.container.mainContext
        let needle = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return SharedStore.fetchAllItems(context)
            .filter { needle.isEmpty || $0.name.localizedCaseInsensitiveContains(needle) }
            .map { ItemEntity($0) }
    }

    @MainActor
    func suggestedEntities() async throws -> [ItemEntity] {
        let context = SharedStore.container.mainContext
        let favorites = SharedStore.fetchFavorites(context)
        let recent = SharedStore.fetchRecent(context, limit: 8)
        var seen = Set<UUID>()
        return (favorites + recent).compactMap { item in
            let id = item.stableID
            guard !seen.contains(id) else { return nil }
            seen.insert(id)
            return ItemEntity(item)
        }
    }
}

// MARK: - Ort

struct PlaceEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Place")
    static var defaultQuery = PlaceEntityQuery()

    var id: UUID
    var name: String
    var symbol: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", image: .init(systemName: symbol))
    }

    @MainActor
    init(_ place: Place) {
        id = place.stableID
        name = place.name
        symbol = place.displaySymbol
    }
}

struct PlaceEntityQuery: EntityStringQuery {
    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [PlaceEntity] {
        let context = SharedStore.container.mainContext
        return identifiers.compactMap { id in
            SharedStore.fetchPlace(uuid: id, context).map { PlaceEntity($0) }
        }
    }

    @MainActor
    func entities(matching string: String) async throws -> [PlaceEntity] {
        let context = SharedStore.container.mainContext
        let needle = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return SharedStore.fetchPlaces(context)
            .filter { needle.isEmpty || $0.name.localizedCaseInsensitiveContains(needle) }
            .map { PlaceEntity($0) }
    }

    @MainActor
    func suggestedEntities() async throws -> [PlaceEntity] {
        SharedStore.fetchPlaces(SharedStore.container.mainContext).map { PlaceEntity($0) }
    }
}

// MARK: - Widget-Konfiguration: welcher Favorit im kleinen Widget?

struct SelectFavoriteIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Favorite"
    static var description = IntentDescription("Choose which favorite the widget shows.")

    @Parameter(title: "Favorite")
    var item: ItemEntity?

    init() {}
    init(item: ItemEntity?) { self.item = item }
}
