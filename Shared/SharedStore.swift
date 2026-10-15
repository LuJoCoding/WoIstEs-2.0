import Foundation
import SwiftData

// MARK: - Geteilte Schlüssel & UserDefaults (App, Widget, Siri)

enum SharedKeys {
    static let language = "settings.language"
    static let background = "settings.backgroundHex"
    static let tile = "settings.tileHex"
    static let list = "settings.listHex"
    static let accent = "settings.accentHex"
    static let showSymbols = "settings.showSymbols"
    static let haptics = "settings.haptics"
    static let reduceMotion = "settings.reduceMotion"

    static let usePlaces = "places.enabled"
    static let defaultPlacesSeeded = "places.seeded"

    static let siriAllowLocked = "siri.allowLocked"

    static let widgetShowPhotos = "widget.showPhotos"
    static let widgetShowPlace = "widget.showPlace"
    static let widgetPrivacy = "widget.privacy"

    static let remindersEnabled = "reminders.enabled"
    static let staleEnabled = "reminders.stale"
    static let staleInterval = "reminders.staleInterval"      // Sekunden
    static let remindFavoritesOnly = "reminders.favoritesOnly"
    static let quietFrom = "reminders.quietFrom"              // Stunde 0–23
    static let quietTo = "reminders.quietTo"                  // Stunde 0–23

    static let lockEnabled = "lock.enabled"
    static let lockAfter = "lock.after"                       // Sekunden
    static let hideInSwitcher = "lock.hideInSwitcher"

    static let storeMigrated = "store.migratedToGroup"
    static let settingsMigrated = "settings.migratedToGroup"
}

enum SharedDefaults {
    static let appGroupID = "group.de.lujo3d.WoIstEs"

    /// Geteilte UserDefaults der App Group; Fallback auf Standard, falls die Gruppe nicht verfügbar ist
    /// (z. B. Sideload mit kostenloser Apple-ID ohne App-Group-Berechtigung).
    static let store: UserDefaults = {
        if SharedStore.groupContainerURL != nil, let suite = UserDefaults(suiteName: appGroupID) {
            // Einstellungen von 1.0 nur aus dem App-Prozess übernehmen – das Widget hat eigene, leere Standardwerte
            if !SharedStore.isExtension { migrateIfNeeded(into: suite) }
            return suite
        }
        return .standard
    }()

    /// Übernimmt einmalig alle bekannten Einstellungen aus UserDefaults.standard (Version 1.0).
    private static func migrateIfNeeded(into suite: UserDefaults) {
        guard !suite.bool(forKey: SharedKeys.settingsMigrated) else { return }
        let old = UserDefaults.standard
        for key in [SharedKeys.language, SharedKeys.background, SharedKeys.tile,
                    SharedKeys.list, SharedKeys.accent, SharedKeys.showSymbols] {
            if suite.object(forKey: key) == nil, let value = old.object(forKey: key) {
                suite.set(value, forKey: key)
            }
        }
        suite.set(true, forKey: SharedKeys.settingsMigrated)
    }

    static var language: AppLanguage {
        if let raw = store.string(forKey: SharedKeys.language), let lang = AppLanguage(rawValue: raw) {
            return lang
        }
        return (Locale.preferredLanguages.first?.hasPrefix("de") ?? true) ? .de : .en
    }

    static func t(_ key: Str) -> String { Strings.text(key, language: language) }

    static var usePlaces: Bool { (store.object(forKey: SharedKeys.usePlaces) as? Bool) ?? true }
    static var lockEnabled: Bool { store.bool(forKey: SharedKeys.lockEnabled) }
    static var siriAllowLocked: Bool { store.bool(forKey: SharedKeys.siriAllowLocked) }
    static var widgetShowPhotos: Bool { (store.object(forKey: SharedKeys.widgetShowPhotos) as? Bool) ?? true }
    static var widgetShowPlace: Bool { (store.object(forKey: SharedKeys.widgetShowPlace) as? Bool) ?? true }
    static var widgetPrivacy: Bool { (store.object(forKey: SharedKeys.widgetPrivacy) as? Bool) ?? lockEnabled }
}

// MARK: - Gemeinsamer SwiftData-Speicher

/// Erzeugt genau EINEN ModelContainer pro Prozess – genutzt von App, Siri-Intents und Widget.
enum SharedStore {
    static let schema = Schema([Item.self, Place.self])
    static let storeName = "default.store"

    /// Läuft dieser Code in einer Erweiterung (Widget) statt in der App?
    static let isExtension: Bool = Bundle.main.bundleURL.pathExtension == "appex"

    /// App-Group-Container oder nil, wenn nicht verfügbar.
    static let groupContainerURL: URL? = {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SharedDefaults.appGroupID)
    }()

    /// Speicherort der 1.0-Datenbank (SwiftData-Standard).
    static var legacyStoreURL: URL {
        URL.applicationSupportDirectory.appending(path: storeName)
    }

    /// Speicherort in der App Group (falls verfügbar).
    static var groupStoreURL: URL? {
        guard let base = groupContainerURL else { return nil }
        let dir = base.appending(path: "Library/Application Support", directoryHint: .isDirectory)
        return dir.appending(path: storeName)
    }

    /// Der gemeinsame Container. Fällt bei jedem Problem auf den bisherigen Speicherort zurück.
    static let container: ModelContainer = {
        if let url = resolvedStoreURL() {
            if let c = try? ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url)]) {
                return c
            }
        }
        // Fallback 1: Standardort (wie Version 1.0)
        if let c = try? ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema)]) {
            return c
        }
        // Fallback 2: Nur-Speicher, damit die App nie abstürzt
        return try! ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
    }()

    /// Wo liegt die Datenbank tatsächlich? (für Anzeige/Diagnose)
    private(set) static var usesGroupContainer = false

    /// Gibt es die gemeinsame Datenbank schon? (Das Widget legt nie selbst eine an.)
    static var groupStoreExists: Bool {
        guard let url = groupStoreURL else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }

    /// Ermittelt den Speicherort und migriert die 1.0-Datenbank bei Bedarf in die App Group.
    /// Nur der App-Prozess migriert oder legt eine neue Datenbank an; eine Erweiterung liest nur.
    private static func resolvedStoreURL() -> URL? {
        guard let groupURL = groupStoreURL else { return nil }
        let fm = FileManager.default

        if isExtension {
            return fm.fileExists(atPath: groupURL.path) ? groupURL : nil
        }

        try? fm.createDirectory(at: groupURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let legacy = legacyStoreURL
        let migrated = SharedDefaults.store.bool(forKey: SharedKeys.storeMigrated)

        // 1.0-Datenbank vorhanden und noch nicht übernommen → kopieren (ersetzt eine evtl. leere Gruppen-Datenbank)
        if fm.fileExists(atPath: legacy.path), !migrated {
            if copyLegacyStore(from: legacy, to: groupURL) {
                usesGroupContainer = true
                SharedDefaults.store.set(true, forKey: SharedKeys.storeMigrated)
                return groupURL
            }
            // Kopieren fehlgeschlagen → weiter mit alter Datenbank
            return nil
        }

        if fm.fileExists(atPath: groupURL.path) {
            usesGroupContainer = true
            return groupURL
        }

        // Frische Installation: direkt in der Gruppe anlegen
        SharedDefaults.store.set(true, forKey: SharedKeys.storeMigrated)
        usesGroupContainer = true
        return groupURL
    }

    /// Kopiert Datenbank + Begleitdateien (-wal, -shm) + externe Fotodaten (.default_SUPPORT)
    /// und prüft die Kopie, bevor sie verwendet wird. Das Original bleibt als Sicherung erhalten.
    private static func copyLegacyStore(from legacy: URL, to target: URL) -> Bool {
        let fm = FileManager.default
        let srcDir = legacy.deletingLastPathComponent()
        let dstDir = target.deletingLastPathComponent()
        let base = legacy.deletingPathExtension().lastPathComponent   // "default"
        let candidates = [
            "\(base).store", "\(base).store-wal", "\(base).store-shm",
            ".\(base)_SUPPORT",
        ]
        var copied: [URL] = []
        do {
            for name in candidates {
                let src = srcDir.appending(path: name)
                let dst = dstDir.appending(path: name)
                guard fm.fileExists(atPath: src.path) else { continue }
                if fm.fileExists(atPath: dst.path) { try fm.removeItem(at: dst) }
                try fm.copyItem(at: src, to: dst)
                copied.append(dst)
            }
            // Kopie prüfen: beide Datenbanken öffnen und Anzahl der Gegenstände vergleichen
            let oldCount = try itemCount(at: legacy)
            let newCount = try itemCount(at: target)
            guard oldCount == newCount else { throw CocoaError(.fileReadCorruptFile) }
            return true
        } catch {
            for url in copied { try? fm.removeItem(at: url) }
            return false
        }
    }

    private static func itemCount(at url: URL) throws -> Int {
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url)])
        let context = ModelContext(container)
        return try context.fetchCount(FetchDescriptor<Item>())
    }

    // MARK: Vorbereitung beim App-Start

    /// Trägt fehlende IDs nach (1.0-Einträge) und legt einmalig Standard-Orte an.
    @MainActor
    static func prepare(language: AppLanguage) {
        let context = container.mainContext
        var changed = false

        if let items = try? context.fetch(FetchDescriptor<Item>()) {
            var seen = Set<UUID>()
            for item in items {
                if let id = item.uuid, !seen.contains(id) {
                    seen.insert(id)
                } else {
                    item.uuid = UUID()
                    changed = true
                }
            }
        }
        if let places = try? context.fetch(FetchDescriptor<Place>()) {
            var seen = Set<UUID>()
            for place in places {
                if let id = place.uuid, !seen.contains(id) {
                    seen.insert(id)
                } else {
                    place.uuid = UUID()
                    changed = true
                }
            }
            let defaults = SharedDefaults.store
            if places.isEmpty, !defaults.bool(forKey: SharedKeys.defaultPlacesSeeded) {
                for (index, entry) in DefaultPlaces.all.enumerated() {
                    context.insert(Place(name: Strings.text(entry.key, language: language),
                                         symbol: entry.symbol, sortOrder: index))
                }
                defaults.set(true, forKey: SharedKeys.defaultPlacesSeeded)
                changed = true
            }
        }
        if changed { try? context.save() }
    }

    // MARK: Abfragen für Widget & Siri

    static func fetchFavorites(_ context: ModelContext) -> [Item] {
        let descriptor = FetchDescriptor<Item>(predicate: #Predicate<Item> { $0.isFavorite },
                                               sortBy: [SortDescriptor(\.favoriteOrder)])
        return (try? context.fetch(descriptor)) ?? []
    }

    static func fetchRecent(_ context: ModelContext, limit: Int = 4) -> [Item] {
        var descriptor = FetchDescriptor<Item>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        descriptor.fetchLimit = limit
        return (try? context.fetch(descriptor)) ?? []
    }

    static func fetchItem(uuid: UUID, _ context: ModelContext) -> Item? {
        let descriptor = FetchDescriptor<Item>(predicate: #Predicate<Item> { $0.uuid == uuid })
        return try? context.fetch(descriptor).first
    }

    static func fetchPlace(uuid: UUID, _ context: ModelContext) -> Place? {
        let descriptor = FetchDescriptor<Place>(predicate: #Predicate<Place> { $0.uuid == uuid })
        return try? context.fetch(descriptor).first
    }

    static func fetchPlaces(_ context: ModelContext) -> [Place] {
        (try? context.fetch(FetchDescriptor<Place>(sortBy: [SortDescriptor(\.sortOrder)]))) ?? []
    }

    static func fetchAllItems(_ context: ModelContext) -> [Item] {
        (try? context.fetch(FetchDescriptor<Item>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]))) ?? []
    }
}
