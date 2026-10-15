import Foundation
import SwiftUI

/// Verteilt Deep Links an die Startseite. Links, die ankommen, bevor die Oberfläche bereit ist,
/// werden gepuffert und beim nächsten Erscheinen ausgeführt.
@MainActor
final class DeepLinkRouter: ObservableObject {
    @Published var pending: DeepLink?

    func open(_ link: DeepLink) { pending = link }
    func open(_ url: URL) {
        if let link = DeepLink(url: url) { pending = link }
    }
    func consume() -> DeepLink? {
        defer { pending = nil }
        return pending
    }
}
