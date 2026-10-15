import Foundation
import LocalAuthentication
import SwiftUI
import UIKit

/// App-Sperre mit Face ID / Touch ID / Geräte-Code.
@MainActor
final class LockManager: ObservableObject {
    @Published var isLocked = false
    /// Deckt den Inhalt im App-Umschalter ab
    @Published var isCovered = false
    @Published var lastError: String?
    @Published private(set) var isAuthenticating = false

    private var backgroundedAt: Date?
    weak var settings: AppSettings?

    /// Gerät hat Code/Face ID/Touch ID eingerichtet?
    static var deviceCanAuthenticate: Bool {
        var error: NSError?
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    static var biometryName: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        default: return "Code"
        }
    }

    func configure(settings: AppSettings) {
        self.settings = settings
        if settings.lockEnabled { isLocked = true }
    }

    // MARK: Szenen-Wechsel

    func scenePhaseChanged(_ phase: ScenePhase) {
        guard let settings else { return }
        switch phase {
        case .background:
            backgroundedAt = .now
            if settings.lockEnabled, settings.lockAfter == 0 { isLocked = true }
            isCovered = settings.lockEnabled && settings.hideInSwitcher
        case .inactive:
            // Kurze Systemdialoge (Kamera, Face ID) lösen keine Sperre aus – nur die Abdeckung
            if settings.lockEnabled, settings.hideInSwitcher, !isAuthenticating { isCovered = true }
        case .active:
            isCovered = false
            if settings.lockEnabled, let since = backgroundedAt,
               Date.now.timeIntervalSince(since) >= settings.lockAfter {
                isLocked = true
            }
            backgroundedAt = nil
            if isLocked { Task { await authenticate() } }
        @unknown default:
            break
        }
    }

    // MARK: Authentifizierung

    @discardableResult
    func authenticate(reason: String? = nil) async -> Bool {
        guard !isAuthenticating else { return false }
        isAuthenticating = true
        defer { isAuthenticating = false }
        let context = LAContext()
        context.localizedCancelTitle = settings?.t(.cancel)
        let text = reason ?? settings?.t(.faceIDReason) ?? "Unlock"
        do {
            let ok = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: text)
            if ok {
                lastError = nil
                isLocked = false
            }
            return ok
        } catch {
            lastError = settings?.t(.unlockFailed)
            return false
        }
    }

    /// Einschalten der Sperre erfordert eine erfolgreiche Authentifizierung.
    func enableLock() async -> Bool {
        let ok = await authenticate()
        if ok { settings?.lockEnabled = true }
        return ok
    }

    func disableLock() {
        settings?.lockEnabled = false
        isLocked = false
        isCovered = false
    }
}

// MARK: - Eigenes Fenster für Sperre/Abdeckung (liegt über Sheets und Vollbild-Ansichten)

@MainActor
final class OverlayWindow {
    static let shared = OverlayWindow()
    private var window: UIWindow?

    func show<Content: View>(animated: Bool, @ViewBuilder content: () -> Content) {
        let host = UIHostingController(rootView: content())
        host.view.backgroundColor = .clear
        if let window {
            window.rootViewController = host
            window.isHidden = false
            window.alpha = 1
            return
        }
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive })
            ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else { return }
        let w = UIWindow(windowScene: scene)
        w.windowLevel = .alert + 1
        w.rootViewController = host
        w.backgroundColor = .clear
        w.alpha = animated ? 0 : 1
        w.isHidden = false
        window = w
        if animated {
            UIView.animate(withDuration: 0.25) { w.alpha = 1 }
        }
    }

    func hide(animated: Bool) {
        guard let w = window else { return }
        window = nil
        if animated {
            UIView.animate(withDuration: 0.3, animations: { w.alpha = 0 }) { _ in
                w.isHidden = true
                w.rootViewController = nil
            }
        } else {
            w.isHidden = true
            w.rootViewController = nil
        }
    }
}

// MARK: - Sperrbildschirm & Abdeckung

struct LockScreenView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var lock: LockManager
    @Environment(\.motion) private var motion
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(settings.tile)
                    .frame(width: 110, height: 110)
                    .softShadow(settings, radius: 14, y: 8)
                Image(systemName: "lock.fill")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(settings.onTile)
                    .contentTransition(.symbolEffect(.replace))
            }
            Text(settings.t(.lockedTitle))
                .font(.title2.bold())
                .foregroundStyle(settings.onBackground)
            if let error = lock.lastError {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(settings.onBackground.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .transition(motion.appear)
            }
            Button {
                Task { await lock.authenticate() }
            } label: {
                Label(settings.t(.unlock), systemImage: LockManager.biometryName == "Face ID" ? "faceid" : "touchid")
                    .font(.headline)
                    .foregroundStyle(settings.onTile)
                    .padding(.horizontal, 28)
                    .frame(height: 52)
                    .panel(settings.tile, radius: 14)
            }
            .buttonStyle(PressableStyle())
            .disabled(lock.isAuthenticating)
            Spacer()
            Spacer()
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(settings.background.ignoresSafeArea())
        .task {
            // Nur im Vordergrund abfragen – im Hintergrund würde Face ID sofort fehlschlagen
            guard scenePhase == .active, lock.isLocked, !lock.isAuthenticating else { return }
            await lock.authenticate()
        }
    }
}

/// Blur + Hintergrundfarbe über dem Inhalt (App-Umschalter / während der Sperre).
struct PrivacyCover: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial)
            settings.background.opacity(0.92)
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(settings.onBackground.opacity(0.5))
        }
        .ignoresSafeArea()
    }
}
