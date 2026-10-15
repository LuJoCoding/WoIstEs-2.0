import AppIntents

/// Siri-Sätze. Die deutschen Übersetzungen stehen in `AppShortcuts.xcstrings`.
struct WoIstEsShortcuts: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor = .teal

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: FindItemIntent(),
            phrases: [
                "Where is my \(\.$item) in \(.applicationName)",
                "Where are my \(\.$item) in \(.applicationName)",
                "Where did I put my \(\.$item) in \(.applicationName)",
                "Find \(\.$item) in \(.applicationName)",
            ],
            shortTitle: "Where is…",
            systemImageName: "magnifyingglass"
        )
        AppShortcut(
            intent: SetLocationIntent(),
            phrases: [
                "\(\.$item) has a new place in \(.applicationName)",
                "Move \(\.$item) in \(.applicationName)",
                "Save a place for \(\.$item) in \(.applicationName)",
            ],
            shortTitle: "Save location",
            systemImageName: "mappin.and.ellipse"
        )
        AppShortcut(
            intent: ItemsAtPlaceIntent(),
            phrases: [
                "What's in \(\.$place) in \(.applicationName)",
                "What is in \(\.$place) in \(.applicationName)",
                "Show \(\.$place) in \(.applicationName)",
            ],
            shortTitle: "What's in…",
            systemImageName: "tray.full"
        )
        AppShortcut(
            intent: OpenNewPhotoIntent(),
            phrases: [
                "New entry in \(.applicationName)",
                "New photo in \(.applicationName)",
                "Take a photo in \(.applicationName)",
            ],
            shortTitle: "New entry",
            systemImageName: "camera"
        )
    }
}
