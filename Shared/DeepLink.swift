import Foundation

/// Ziel eines Deep Links (Widget, Benachrichtigung, Siri).
enum DeepLink: Equatable {
    /// Detailansicht eines Gegenstands
    case item(UUID)
    /// Plus-Menü öffnen
    case newEntry
    /// Direkt die Kamera öffnen
    case newPhoto
    /// Neuen Ort für einen bestehenden Gegenstand eintragen (Notiz-Formular)
    case relocate(UUID)

    /// URL-Schema: woistes://item/<uuid> · woistes://new · woistes://photo · woistes://relocate/<uuid>
    init?(url: URL) {
        guard url.scheme == "woistes" else { return nil }
        let host = url.host() ?? ""
        let path = url.pathComponents.filter { $0 != "/" }
        switch host {
        case "item":
            guard let id = path.first.flatMap(UUID.init(uuidString:)) else { return nil }
            self = .item(id)
        case "new": self = .newEntry
        case "photo": self = .newPhoto
        case "relocate":
            guard let id = path.first.flatMap(UUID.init(uuidString:)) else { return nil }
            self = .relocate(id)
        default: return nil
        }
    }

    static func itemURL(_ id: UUID) -> URL { URL(string: "woistes://item/\(id.uuidString)")! }
    static let newEntryURL = URL(string: "woistes://new")!
    static let newPhotoURL = URL(string: "woistes://photo")!
}
