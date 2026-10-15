import SwiftUI

/// Alle Einstellungen der App. Werden automatisch in den geteilten UserDefaults gespeichert,
/// damit Widget und Siri dieselben Farben, Sprache und Schalter sehen.
final class AppSettings: ObservableObject {
    private let defaults = SharedDefaults.store

    // MARK: Sprache & Anzeige
    @Published var language: AppLanguage { didSet { defaults.set(language.rawValue, forKey: SharedKeys.language) } }
    @Published var backgroundHex: String { didSet { defaults.set(backgroundHex, forKey: SharedKeys.background) } }
    @Published var tileHex: String { didSet { defaults.set(tileHex, forKey: SharedKeys.tile) } }
    @Published var listHex: String { didSet { defaults.set(listHex, forKey: SharedKeys.list) } }
    @Published var accentHex: String { didSet { defaults.set(accentHex, forKey: SharedKeys.accent) } }
    /// Zeigt bei Gegenständen mit Symbol nur das Symbol statt des Namens.
    @Published var showSymbols: Bool { didSet { defaults.set(showSymbols, forKey: SharedKeys.showSymbols) } }
    @Published var haptics: Bool { didSet { defaults.set(haptics, forKey: SharedKeys.haptics) } }
    @Published var reduceMotion: Bool { didSet { defaults.set(reduceMotion, forKey: SharedKeys.reduceMotion) } }

    // MARK: Orte
    @Published var usePlaces: Bool { didSet { defaults.set(usePlaces, forKey: SharedKeys.usePlaces) } }

    // MARK: Siri
    @Published var siriAllowLocked: Bool { didSet { defaults.set(siriAllowLocked, forKey: SharedKeys.siriAllowLocked) } }

    // MARK: Widget
    @Published var widgetShowPhotos: Bool { didSet { defaults.set(widgetShowPhotos, forKey: SharedKeys.widgetShowPhotos) } }
    @Published var widgetShowPlace: Bool { didSet { defaults.set(widgetShowPlace, forKey: SharedKeys.widgetShowPlace) } }
    @Published var widgetPrivacy: Bool { didSet { defaults.set(widgetPrivacy, forKey: SharedKeys.widgetPrivacy) } }

    // MARK: Erinnerungen
    @Published var remindersEnabled: Bool { didSet { defaults.set(remindersEnabled, forKey: SharedKeys.remindersEnabled) } }
    @Published var staleEnabled: Bool { didSet { defaults.set(staleEnabled, forKey: SharedKeys.staleEnabled) } }
    @Published var staleInterval: TimeInterval { didSet { defaults.set(staleInterval, forKey: SharedKeys.staleInterval) } }
    @Published var remindFavoritesOnly: Bool { didSet { defaults.set(remindFavoritesOnly, forKey: SharedKeys.remindFavoritesOnly) } }
    @Published var quietFrom: Int { didSet { defaults.set(quietFrom, forKey: SharedKeys.quietFrom) } }
    @Published var quietTo: Int { didSet { defaults.set(quietTo, forKey: SharedKeys.quietTo) } }

    // MARK: Sicherheit
    @Published var lockEnabled: Bool { didSet { defaults.set(lockEnabled, forKey: SharedKeys.lockEnabled) } }
    @Published var lockAfter: TimeInterval { didSet { defaults.set(lockAfter, forKey: SharedKeys.lockAfter) } }
    @Published var hideInSwitcher: Bool { didSet { defaults.set(hideInSwitcher, forKey: SharedKeys.hideInSwitcher) } }

    init() {
        let d = SharedDefaults.store
        func bool(_ key: String, default value: Bool) -> Bool { (d.object(forKey: key) as? Bool) ?? value }

        language = SharedDefaults.language
        backgroundHex = d.string(forKey: SharedKeys.background) ?? ColorTheme.original.background
        tileHex = d.string(forKey: SharedKeys.tile) ?? ColorTheme.original.tile
        listHex = d.string(forKey: SharedKeys.list) ?? ColorTheme.original.list
        accentHex = d.string(forKey: SharedKeys.accent) ?? ColorTheme.original.accent
        showSymbols = bool(SharedKeys.showSymbols, default: false)
        haptics = bool(SharedKeys.haptics, default: true)
        reduceMotion = bool(SharedKeys.reduceMotion, default: false)

        usePlaces = bool(SharedKeys.usePlaces, default: true)
        siriAllowLocked = bool(SharedKeys.siriAllowLocked, default: false)

        widgetShowPhotos = bool(SharedKeys.widgetShowPhotos, default: true)
        widgetShowPlace = bool(SharedKeys.widgetShowPlace, default: true)
        let lock = bool(SharedKeys.lockEnabled, default: false)
        widgetPrivacy = bool(SharedKeys.widgetPrivacy, default: lock)

        remindersEnabled = bool(SharedKeys.remindersEnabled, default: false)
        staleEnabled = bool(SharedKeys.staleEnabled, default: true)
        let interval = d.double(forKey: SharedKeys.staleInterval)
        staleInterval = interval > 0 ? interval : StaleInterval.threeMonths.seconds
        remindFavoritesOnly = bool(SharedKeys.remindFavoritesOnly, default: true)
        quietFrom = d.object(forKey: SharedKeys.quietFrom) as? Int ?? 8
        quietTo = d.object(forKey: SharedKeys.quietTo) as? Int ?? 21

        lockEnabled = lock
        lockAfter = d.object(forKey: SharedKeys.lockAfter) as? TimeInterval ?? 0
        hideInSwitcher = bool(SharedKeys.hideInSwitcher, default: true)
    }

    // MARK: Farben

    var theme: ThemeColors { ThemeColors(backgroundHex: backgroundHex, tileHex: tileHex, listHex: listHex, accentHex: accentHex) }

    var background: Color { Color(hex: backgroundHex) }
    var tile: Color { Color(hex: tileHex) }
    var list: Color { Color(hex: listHex) }
    var accent: Color { Color(hex: accentHex) }
    /// Suchleiste & Überschriften: etwas dunkler als die Kacheln
    var searchBarHex: String { HexColor.scaled(tileHex, by: 0.78) }
    var searchBar: Color { Color(hex: searchBarHex) }

    var onBackground: Color { HexColor.readableText(on: backgroundHex) }
    var onTile: Color { HexColor.readableText(on: tileHex) }
    var onList: Color { HexColor.readableText(on: listHex) }
    var onAccent: Color { HexColor.readableText(on: accentHex) }
    var onSearchBar: Color { HexColor.readableText(on: searchBarHex) }

    /// Trennlinie: auf hellen Hintergründen dunkel, sonst weiß (wie im Entwurf)
    var divider: Color {
        HexColor.luminance(backgroundHex) > 0.75 ? Color.black.opacity(0.25) : Color.white.opacity(0.9)
    }

    var isDarkBackground: Bool { HexColor.luminance(backgroundHex) < 0.35 }
    var colorScheme: ColorScheme { isDarkBackground ? .dark : .light }
    /// Schattenstärke passend zur Helligkeit des Hintergrunds
    var shadow: Color { Color.black.opacity(isDarkBackground ? 0.35 : 0.18) }

    func binding(_ keyPath: ReferenceWritableKeyPath<AppSettings, String>) -> Binding<Color> {
        Binding(
            get: { Color(hex: self[keyPath: keyPath]) },
            set: { newValue in
                withAnimation(.easeInOut(duration: 0.35)) {
                    self[keyPath: keyPath] = newValue.hexString
                }
            }
        )
    }

    func apply(_ theme: ColorTheme) {
        backgroundHex = theme.background
        tileHex = theme.tile
        listHex = theme.list
        accentHex = theme.accent
    }

    func isCurrent(_ theme: ColorTheme) -> Bool {
        backgroundHex.uppercased() == theme.background.uppercased()
            && tileHex.uppercased() == theme.tile.uppercased()
            && listHex.uppercased() == theme.list.uppercased()
            && accentHex.uppercased() == theme.accent.uppercased()
    }

    /// Farbe eines Ortes: eigene Farbe oder Kachelfarbe
    func placeColorHex(_ place: Place?) -> String { place?.colorHex ?? tileHex }
    func placeColor(_ place: Place?) -> Color { Color(hex: placeColorHex(place)) }
    func onPlaceColor(_ place: Place?) -> Color { HexColor.readableText(on: placeColorHex(place)) }

    // MARK: Texte & Zeit

    func t(_ key: Str) -> String { Strings.text(key, language: language) }

    func relative(_ date: Date) -> String {
        RelativeTime.string(for: date, language: language)
    }

    func absolute(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = language.locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

/// Intervalle für „Liegt es noch da?“
enum StaleInterval: CaseIterable, Identifiable {
    case oneWeek, oneMonth, threeMonths, sixMonths, oneYear

    var id: TimeInterval { seconds }

    var seconds: TimeInterval {
        switch self {
        case .oneWeek: return 7 * 86_400
        case .oneMonth: return 30 * 86_400
        case .threeMonths: return 91 * 86_400
        case .sixMonths: return 182 * 86_400
        case .oneYear: return 365 * 86_400
        }
    }

    var key: Str {
        switch self {
        case .oneWeek: return .interval1w
        case .oneMonth: return .interval1m
        case .threeMonths: return .interval3m
        case .sixMonths: return .interval6m
        case .oneYear: return .interval1y
        }
    }
}

enum LockDelay: CaseIterable, Identifiable {
    case immediately, oneMinute, fiveMinutes, fifteenMinutes

    var id: TimeInterval { seconds }

    var seconds: TimeInterval {
        switch self {
        case .immediately: return 0
        case .oneMinute: return 60
        case .fiveMinutes: return 300
        case .fifteenMinutes: return 900
        }
    }

    var key: Str {
        switch self {
        case .immediately: return .lockImmediately
        case .oneMinute: return .lock1min
        case .fiveMinutes: return .lock5min
        case .fifteenMinutes: return .lock15min
        }
    }
}
