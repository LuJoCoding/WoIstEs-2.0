import Foundation
import SwiftData

/// Ein Gegenstand hat immer genau EINEN aktuellen Ort.
/// Wird ein neuer Ort eingetragen, wird der alte vollständig ersetzt (Ort, Notiz, Foto, Zeitpunkt).
@Model
final class Item {
    /// Stabile ID für Deep Links, Siri und Erinnerungen. Optional, damit die 1.0-Datenbank
    /// ohne Datenverlust migriert wird – fehlende IDs werden beim Start nachgetragen (`SharedStore.prepare`).
    var uuid: UUID?
    var name: String = ""
    /// SF-Symbol-Name, z. B. "key.fill" (optional)
    var symbol: String?
    var locationNote: String = ""
    @Attribute(.externalStorage) var photoData: Data?
    @Attribute(.externalStorage) var thumbnailData: Data?
    var updatedAt: Date = Date.now
    var createdAt: Date = Date.now
    var isFavorite: Bool = false
    var favoriteOrder: Int = 0

    /// Raum/Ort (Update 2.0, optional – alte Einträge haben keinen)
    var place: Place?

    /// Eigene Erinnerung (Update 2.0, alles optional)
    var reminderDate: Date?
    /// "never" | "daily" | "weekly" | "monthly"
    var reminderRepeat: String?
    var reminderNote: String?

    init(name: String,
         symbol: String? = nil,
         locationNote: String = "",
         photoData: Data? = nil,
         thumbnailData: Data? = nil,
         place: Place? = nil) {
        self.uuid = UUID()
        self.name = name
        self.symbol = symbol
        self.locationNote = locationNote
        self.photoData = photoData
        self.thumbnailData = thumbnailData
        self.place = place
        self.updatedAt = .now
        self.createdAt = .now
    }

    /// Garantiert eine ID (wird für alte Einträge beim ersten Start gesetzt).
    var stableID: UUID {
        if let uuid { return uuid }
        let fresh = UUID()
        uuid = fresh
        return fresh
    }

    /// Überschreibt den bisherigen Ort komplett – der alte Eintrag (inkl. Foto) wird gelöscht.
    func relocate(note: String, photoData: Data?, thumbnailData: Data?, place: Place?) {
        self.locationNote = note
        self.photoData = photoData
        self.thumbnailData = thumbnailData
        self.place = place
        self.updatedAt = .now
    }

    /// Kurzbeschreibung des Ortes: Ort + Notiz, nur Notiz oder nur Ort.
    func locationText(fallback: String) -> String {
        switch (place?.name, locationNote.isEmpty) {
        case (let p?, false): return "\(p) · \(locationNote)"
        case (let p?, true): return p
        case (nil, false): return locationNote
        case (nil, true): return fallback
        }
    }
}

enum ReminderRepeat: String, CaseIterable, Identifiable {
    case never, daily, weekly, monthly
    var id: String { rawValue }
}

enum Favorites {
    static let maxCount = 4

    /// Fügt einen Favoriten hinzu. Gibt `false` zurück, wenn schon 4 Favoriten existieren.
    @discardableResult
    static func add(_ item: Item, among all: [Item]) -> Bool {
        if item.isFavorite { return true }
        let current = all.filter { $0.isFavorite }
        guard current.count < maxCount else { return false }
        item.favoriteOrder = (current.map { $0.favoriteOrder }.max() ?? -1) + 1
        item.isFavorite = true
        return true
    }

    static func remove(_ item: Item) {
        item.isFavorite = false
    }
}
