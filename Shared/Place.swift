import Foundation
import SwiftData

/// Ein Ort/Raum (Küche, Auto, Rucksack …). Gegenstände verweisen optional auf genau einen Ort.
@Model
final class Place {
    var uuid: UUID?
    var name: String = ""
    /// SF-Symbol-Name (optional)
    var symbol: String?
    /// Eigene Farbe als Hex (#RRGGBB); nil = Kachelfarbe des Themes
    var colorHex: String?
    var sortOrder: Int = 0
    var createdAt: Date = Date.now

    /// Beim Löschen eines Ortes bleiben die Gegenstände erhalten und verlieren nur den Ort.
    @Relationship(deleteRule: .nullify, inverse: \Item.place)
    var items: [Item] = []

    init(name: String, symbol: String? = nil, colorHex: String? = nil, sortOrder: Int = 0) {
        self.uuid = UUID()
        self.name = name
        self.symbol = symbol
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.createdAt = .now
    }

    var stableID: UUID {
        if let uuid { return uuid }
        let fresh = UUID()
        uuid = fresh
        return fresh
    }

    var displaySymbol: String { symbol ?? "mappin.and.ellipse" }
}

/// Standard-Orte beim ersten Start von 2.0 (nur wenn noch keine Orte existieren).
enum DefaultPlaces {
    static let all: [(key: Str, symbol: String)] = [
        (.placeKitchen, "fork.knife"),
        (.placeLiving, "sofa.fill"),
        (.placeBedroom, "bed.double.fill"),
        (.placeHallway, "door.left.hand.open"),
        (.placeOffice, "desktopcomputer"),
        (.placeCar, "car.fill"),
        (.placeBackpack, "backpack.fill"),
    ]
}
