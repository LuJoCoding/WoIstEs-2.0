import Foundation
import SwiftData
import UserNotifications
import UIKit

/// Plant lokale Benachrichtigungen: „Liegt es noch da?“ und eigene Erinnerungen pro Gegenstand.
@MainActor
final class ReminderManager: NSObject, ObservableObject {
    static let shared = ReminderManager()

    static let categoryID = "WOISTES_ITEM"
    static let actionStillThere = "STILL_THERE"
    static let actionNewLocation = "NEW_LOCATION"
    static let actionOpen = "OPEN"

    @Published private(set) var authorization: UNAuthorizationStatus = .notDetermined

    /// Wird von der App gesetzt (Deep Links aus Benachrichtigungen)
    var router: DeepLinkRouter?
    weak var settings: AppSettings?
    /// Falls die App im Hintergrund gestartet wurde (Siri, Mitteilung), gelten die gespeicherten Einstellungen
    private var effectiveSettings: AppSettings { settings ?? AppSettings() }

    private let center = UNUserNotificationCenter.current()

    private override init() {
        super.init()
    }

    func configure(settings: AppSettings, router: DeepLinkRouter) {
        self.settings = settings
        self.router = router
        center.delegate = self
        registerCategories()
        refreshAuthorization()
    }

    // MARK: Berechtigung

    func refreshAuthorization() {
        center.getNotificationSettings { [weak self] s in
            Task { @MainActor in self?.authorization = s.authorizationStatus }
        }
    }

    /// Fragt erst, wenn der Nutzer die Funktion einschaltet. Gibt zurück, ob erlaubt.
    func requestAuthorization() async -> Bool {
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        authorization = await center.notificationSettings().authorizationStatus
        return granted
    }

    private func registerCategories() {
        let t = effectiveSettings.t
        let still = UNNotificationAction(identifier: Self.actionStillThere, title: t(.actionStillThere), options: [])
        let newLoc = UNNotificationAction(identifier: Self.actionNewLocation, title: t(.actionNewLocation), options: [.foreground])
        let open = UNNotificationAction(identifier: Self.actionOpen, title: t(.actionOpen), options: [.foreground])
        let category = UNNotificationCategory(identifier: Self.categoryID, actions: [still, newLoc, open],
                                              intentIdentifiers: [], options: [])
        center.setNotificationCategories([category])
    }

    /// Nach Sprachwechsel: Aktionstitel neu registrieren und alle Texte neu planen.
    func languageChanged(context: ModelContext) {
        registerCategories()
        rescheduleAll(context: context)
    }

    // MARK: Planen

    private func staleID(_ item: Item) -> String { "stale-\(item.stableID.uuidString)" }
    private func customID(_ item: Item) -> String { "custom-\(item.stableID.uuidString)" }

    /// Plant beide Erinnerungen eines Gegenstands neu (nach Speichern/Ändern).
    /// Ohne Berechtigung ist `center.add` wirkungslos – deshalb kein Status-Guard nötig.
    func schedule(for item: Item) {
        let settings = effectiveSettings
        center.removePendingNotificationRequests(withIdentifiers: [staleID(item), customID(item)])
        guard settings.remindersEnabled else { return }

        if settings.staleEnabled, !settings.remindFavoritesOnly || item.isFavorite {
            scheduleStale(for: item, settings: settings)
        }
        if let date = item.reminderDate {
            scheduleCustom(for: item, date: date, settings: settings)
        }
    }

    func cancel(for item: Item) {
        center.removePendingNotificationRequests(withIdentifiers: [staleID(item), customID(item)])
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    func rescheduleAll(context: ModelContext) {
        cancelAll()
        guard effectiveSettings.remindersEnabled else { return }
        for item in SharedStore.fetchAllItems(context) { schedule(for: item) }
    }

    private func scheduleStale(for item: Item, settings: AppSettings) {
        var fire = item.updatedAt.addingTimeInterval(settings.staleInterval)
        if fire < .now { fire = Date.now.addingTimeInterval(120) }   // längst überfällig → bald, aber nicht sofort
        fire = Self.movedIntoQuietHours(fire, from: settings.quietFrom, to: settings.quietTo)

        let content = UNMutableNotificationContent()
        content.title = settings.t(.notifStaleTitle)
        content.body = staleBody(for: item, fire: fire, settings: settings)
        content.sound = .default
        content.categoryIdentifier = Self.categoryID
        content.userInfo = ["item": item.stableID.uuidString]
        content.threadIdentifier = item.stableID.uuidString

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        center.add(UNNotificationRequest(identifier: staleID(item), content: content, trigger: trigger))
    }

    private func staleBody(for item: Item, fire: Date, settings: AppSettings) -> String {
        if settings.lockEnabled {
            return String(format: settings.t(.notifLockedBody), item.name)
        }
        // Relativ zum Zeitpunkt der Mitteilung („vor 3 Monaten“), nicht zum Zeitpunkt des Planens
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = settings.language.locale
        formatter.unitsStyle = .full
        let when = formatter.localizedString(for: item.updatedAt, relativeTo: fire)
        if let place = item.place {
            return String(format: settings.t(.notifStaleBody), item.name, place.name, when)
        }
        let note = item.locationNote.isEmpty ? settings.t(.seePhoto) : item.locationNote
        return String(format: settings.t(.notifStaleBodyNoPlace), item.name, note, when)
    }

    private func scheduleCustom(for item: Item, date: Date, settings: AppSettings) {
        let repeatMode = ReminderRepeat(rawValue: item.reminderRepeat ?? "") ?? .never
        let content = UNMutableNotificationContent()
        content.title = String(format: settings.t(.notifCustomTitle), item.name)
        if settings.lockEnabled {
            content.body = item.reminderNote?.isEmpty == false ? item.reminderNote! : String(format: settings.t(.notifLockedBody), item.name)
        } else {
            let location = item.locationText(fallback: settings.t(.seePhoto))
            content.body = item.reminderNote?.isEmpty == false ? "\(item.reminderNote!) · \(location)" : location
        }
        content.sound = .default
        content.categoryIdentifier = Self.categoryID
        content.userInfo = ["item": item.stableID.uuidString]
        content.threadIdentifier = item.stableID.uuidString

        let calendar = Calendar.current
        let trigger: UNNotificationTrigger
        switch repeatMode {
        case .never:
            guard date > .now else { return }
            let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        case .daily:
            let comps = calendar.dateComponents([.hour, .minute], from: date)
            trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        case .weekly:
            let comps = calendar.dateComponents([.weekday, .hour, .minute], from: date)
            trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        case .monthly:
            let comps = calendar.dateComponents([.day, .hour, .minute], from: date)
            trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        }
        center.add(UNNotificationRequest(identifier: customID(item), content: content, trigger: trigger))
    }

    /// Verschiebt einen Zeitpunkt auf den nächsten erlaubten Zeitpunkt innerhalb der Ruhezeit-Grenzen.
    static func movedIntoQuietHours(_ date: Date, from: Int, to: Int) -> Date {
        guard from != to else { return date }
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let allowed: Bool = from < to ? (hour >= from && hour < to) : (hour >= from || hour < to)
        if allowed { return date }
        // Nächster Start der erlaubten Zeit
        var comps = calendar.dateComponents([.year, .month, .day], from: date)
        comps.hour = from
        comps.minute = 0
        guard var next = calendar.date(from: comps) else { return date }
        if next <= date { next = calendar.date(byAdding: .day, value: 1, to: next) ?? next }
        return next
    }
}

// MARK: - Antworten auf Benachrichtigungen

extension ReminderManager: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            didReceive response: UNNotificationResponse) async {
        let idString = response.notification.request.content.userInfo["item"] as? String
        let action = response.actionIdentifier
        await MainActor.run {
            guard let idString, let id = UUID(uuidString: idString) else { return }
            switch action {
            case Self.actionStillThere:
                let context = SharedStore.container.mainContext
                if let item = SharedStore.fetchItem(uuid: id, context) {
                    item.updatedAt = .now          // Ort bleibt, nur „zuletzt bestätigt“ wird aktualisiert
                    try? context.save()
                    self.schedule(for: item)
                    WidgetReloader.reload()
                }
            case Self.actionNewLocation:
                self.router?.open(.relocate(id))
            default:
                self.router?.open(.item(id))
            }
        }
    }
}

// MARK: - Widget neu laden

import WidgetKit

enum WidgetReloader {
    static func reload() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
