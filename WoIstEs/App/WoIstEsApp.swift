import SwiftUI
import SwiftData

@main
struct WoIstEsApp: App {
    @StateObject private var settings: AppSettings
    @StateObject private var router: DeepLinkRouter
    @StateObject private var lock: LockManager
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    init() {
        let settings = AppSettings()
        let router = DeepLinkRouter()
        let lock = LockManager()
        _settings = StateObject(wrappedValue: settings)
        _router = StateObject(wrappedValue: router)
        _lock = StateObject(wrappedValue: lock)

        // IDs nachtragen, Standard-Orte anlegen (einmalig) – noch bevor eine Ansicht erscheint
        SharedStore.prepare(language: settings.language)
        // Sperre und Mitteilungs-Delegate müssen VOR dem ersten Bild stehen
        // (Start aus einer Mitteilung / Siri im Hintergrund, kein unverschlüsselter erster Frame)
        lock.configure(settings: settings)
        ReminderManager.shared.configure(settings: settings, router: router)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .environmentObject(router)
                .environmentObject(lock)
                .environment(\.motion, Motion(reduced: systemReduceMotion || settings.reduceMotion))
                .preferredColorScheme(settings.colorScheme)
                .onOpenURL { url in router.open(url) }
                .onChange(of: scenePhase) { _, phase in
                    lock.scenePhaseChanged(phase)
                    if phase == .active { WidgetReloader.reload() }
                }
        }
        .modelContainer(SharedStore.container)
    }
}

/// Startseite + App-Sperre + Abdeckung im App-Umschalter.
/// Sperrbildschirm und Abdeckung liegen in einem eigenen Fenster über ALLEM – auch über Sheets und Vollbild-Ansichten.
struct RootView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var lock: LockManager
    @Environment(\.motion) private var motion

    var body: some View {
        HomeView()
            .blur(radius: lock.isLocked && !motion.reduced ? 18 : 0)
            .allowsHitTesting(!lock.isLocked)
            .accessibilityHidden(lock.isLocked)
            .animation(motion.gentle, value: lock.isLocked)
            .onAppear { updateOverlay() }
            .onChange(of: lock.isLocked) { _, _ in updateOverlay() }
            .onChange(of: lock.isCovered) { _, _ in updateOverlay() }
            .animation(motion.color, value: settings.backgroundHex)
        .animation(motion.color, value: settings.tileHex)
        .animation(motion.color, value: settings.listHex)
        .animation(motion.color, value: settings.accentHex)
    }

    private func updateOverlay() {
        if lock.isLocked {
            OverlayWindow.shared.show(animated: !motion.reduced) {
                LockScreenView()
                    .environmentObject(settings)
                    .environmentObject(lock)
                    .environment(\.motion, motion)
                    .preferredColorScheme(settings.colorScheme)
            }
        } else if lock.isCovered {
            OverlayWindow.shared.show(animated: false) {
                PrivacyCover()
                    .environmentObject(settings)
                    .preferredColorScheme(settings.colorScheme)
            }
        } else {
            OverlayWindow.shared.hide(animated: !motion.reduced)
        }
    }
}
