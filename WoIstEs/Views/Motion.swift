import SwiftUI

/// Zentrale Animations-Konstanten. Ruhig, weich, nicht hektisch.
/// Bei reduzierter Bewegung (System oder App-Einstellung) werden Bewegungen zu Überblendungen.
struct Motion {
    let reduced: Bool

    /// Standard für Layout-Wechsel
    var standard: Animation { reduced ? .easeInOut(duration: 0.2) : .spring(response: 0.42, dampingFraction: 0.88) }
    /// Größere Übergänge
    var gentle: Animation { reduced ? .easeInOut(duration: 0.25) : .spring(response: 0.55, dampingFraction: 0.92) }
    /// Druck-Feedback
    var quick: Animation { .easeOut(duration: 0.18) }
    /// Farbwechsel
    var color: Animation { .easeInOut(duration: 0.35) }

    /// Verzögerung für gestaffeltes Einblenden
    func stagger(_ index: Int, step: Double = 0.04) -> Animation {
        reduced ? .easeInOut(duration: 0.2) : standard.delay(Double(index) * step)
    }

    /// Einblend-Übergang: leichter Versatz nach oben + Opazität; reduziert: nur Opazität
    var appear: AnyTransition {
        reduced ? .opacity : .opacity.combined(with: .offset(y: 10))
    }

    var scaleFade: AnyTransition {
        reduced ? .opacity : .opacity.combined(with: .scale(scale: 0.96))
    }

    var listChange: AnyTransition {
        reduced ? .opacity : .opacity.combined(with: .move(edge: .top))
    }

    static let none = Motion(reduced: true)
}

private struct MotionKey: EnvironmentKey {
    static let defaultValue = Motion(reduced: false)
}

extension EnvironmentValues {
    var motion: Motion {
        get { self[MotionKey.self] }
        set { self[MotionKey.self] = newValue }
    }
}

/// Blendet Inhalte beim ersten Erscheinen gestaffelt ein (nur einmal, nicht bei jeder Rückkehr).
struct StaggeredAppear: ViewModifier {
    let index: Int
    @Environment(\.motion) private var motion
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown || motion.reduced ? 0 : 10)
            .onAppear {
                guard !shown else { return }
                withAnimation(motion.stagger(index)) { shown = true }
            }
    }
}

extension View {
    func staggeredAppear(_ index: Int) -> some View { modifier(StaggeredAppear(index: index)) }
}
