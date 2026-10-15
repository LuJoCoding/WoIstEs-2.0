import Foundation

/// Relative Zeitangaben („vor 2 Std.“) – gemeinsam für App, Widget und Siri.
enum RelativeTime {
    static func string(for date: Date, language: AppLanguage) -> String {
        if abs(date.timeIntervalSinceNow) < 60 { return Strings.text(.justNow, language: language) }
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = language.locale
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: .now)
    }
}
