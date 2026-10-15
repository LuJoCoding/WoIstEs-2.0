import SwiftUI
import UIKit

// MARK: - Farben (Hex) – wird von App und Widget genutzt

enum HexColor {
    static func rgb(_ hex: String) -> (r: Double, g: Double, b: Double) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard cleaned.count == 6, let value = UInt64(cleaned, radix: 16) else { return (0.5, 0.5, 0.5) }
        return (Double((value >> 16) & 0xFF) / 255,
                Double((value >> 8) & 0xFF) / 255,
                Double(value & 0xFF) / 255)
    }

    static func luminance(_ hex: String) -> Double {
        let c = rgb(hex)
        return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b
    }

    /// Schwarz oder Weiß – je nachdem, was auf der Farbe besser lesbar ist.
    static func readableText(on hex: String) -> Color {
        luminance(hex) > 0.5 ? Color.black : Color.white
    }

    static func scaled(_ hex: String, by factor: Double) -> String {
        let c = rgb(hex)
        return make(c.r * factor, c.g * factor, c.b * factor)
    }

    /// Mischt die Farbe mit Weiß (amount 0…1).
    static func lightened(_ hex: String, by amount: Double) -> String {
        let c = rgb(hex)
        return make(c.r + (1 - c.r) * amount, c.g + (1 - c.g) * amount, c.b + (1 - c.b) * amount)
    }

    static func make(_ r: Double, _ g: Double, _ b: Double) -> String {
        func byte(_ v: Double) -> Int { Int((min(max(v, 0), 1) * 255).rounded()) }
        return String(format: "#%02X%02X%02X", byte(r), byte(g), byte(b))
    }
}

extension Color {
    init(hex: String) {
        let c = HexColor.rgb(hex)
        self.init(.sRGB, red: c.r, green: c.g, blue: c.b, opacity: 1)
    }

    var hexString: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return HexColor.make(Double(r), Double(g), Double(b))
    }
}

// MARK: - Farbvorlagen

struct ColorTheme: Identifiable {
    let id: String
    let nameDE: String
    let nameEN: String
    let background: String
    let tile: String
    let list: String
    let accent: String

    func name(_ language: AppLanguage) -> String { language == .de ? nameDE : nameEN }

    static let original = ColorTheme(id: "original", nameDE: "Original", nameEN: "Original",
                                     background: "#8A8A8A", tile: "#17607F", list: "#A9CDEB", accent: "#3A3A3A")
    static let night = ColorTheme(id: "night", nameDE: "Nacht", nameEN: "Night",
                                  background: "#1C1C1E", tile: "#2C4A6E", list: "#3A3A3C", accent: "#0A84FF")
    static let forest = ColorTheme(id: "forest", nameDE: "Wald", nameEN: "Forest",
                                   background: "#DDE5D6", tile: "#3F6B4A", list: "#B7CDB0", accent: "#2C4A33")
    static let sand = ColorTheme(id: "sand", nameDE: "Sand", nameEN: "Sand",
                                 background: "#EFE6D8", tile: "#B5703A", list: "#E8CDA9", accent: "#7A4A24")
    static let berry = ColorTheme(id: "berry", nameDE: "Beere", nameEN: "Berry",
                                  background: "#F3E7EE", tile: "#8E3B6B", list: "#E3BFD3", accent: "#5C2445")
    static let ocean = ColorTheme(id: "ocean", nameDE: "Ozean", nameEN: "Ocean",
                                  background: "#0E2A3B", tile: "#1F7A8C", list: "#BFDBF7", accent: "#E1A33B")

    static let all: [ColorTheme] = [.original, .night, .forest, .sand, .berry, .ocean]
}

// MARK: - Aktuelles Farbschema (aus den geteilten Einstellungen; Widget + Intents)

/// Schlanke, wertbasierte Sicht auf die Nutzerfarben. Die App selbst nutzt `AppSettings`,
/// Widget und Siri-Snippets lesen die Farben hierüber aus den geteilten UserDefaults.
struct ThemeColors {
    var backgroundHex: String
    var tileHex: String
    var listHex: String
    var accentHex: String

    static func current(from defaults: UserDefaults = SharedDefaults.store) -> ThemeColors {
        ThemeColors(
            backgroundHex: defaults.string(forKey: SharedKeys.background) ?? ColorTheme.original.background,
            tileHex: defaults.string(forKey: SharedKeys.tile) ?? ColorTheme.original.tile,
            listHex: defaults.string(forKey: SharedKeys.list) ?? ColorTheme.original.list,
            accentHex: defaults.string(forKey: SharedKeys.accent) ?? ColorTheme.original.accent
        )
    }

    var background: Color { Color(hex: backgroundHex) }
    var tile: Color { Color(hex: tileHex) }
    var list: Color { Color(hex: listHex) }
    var accent: Color { Color(hex: accentHex) }
    var searchBarHex: String { HexColor.scaled(tileHex, by: 0.78) }
    var searchBar: Color { Color(hex: searchBarHex) }

    var onBackground: Color { HexColor.readableText(on: backgroundHex) }
    var onTile: Color { HexColor.readableText(on: tileHex) }
    var onList: Color { HexColor.readableText(on: listHex) }
    var onAccent: Color { HexColor.readableText(on: accentHex) }
    var onSearchBar: Color { HexColor.readableText(on: searchBarHex) }

    var isDark: Bool { HexColor.luminance(backgroundHex) < 0.35 }
    /// Schattenstärke passend zur Helligkeit des Hintergrunds
    var shadowOpacity: Double { isDark ? 0.35 : 0.18 }
}
