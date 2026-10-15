import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case de, en

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .de: return "Deutsch"
        case .en: return "English"
        }
    }

    var locale: Locale {
        Locale(identifier: self == .de ? "de_DE" : "en_US")
    }
}

/// Alle Texte der App, des Widgets und der Siri-Dialoge.
/// Neue Sprache = neues Dictionary unten + Eintrag in `AppLanguage`.
enum Str: String {
    // Allgemein
    case search, settings, done, cancel, delete, ok, close, save, details, add, edit, back
    case recentlyUsed, emptyRecent, favoriteSlot, chooseFavorite, noFavoriteCandidates
    case favoritesFull, favoritesFullMessage, favorite
    case newEntry, photo, photoSub, note, noteSub
    case photoTitle, noteTitle, photoReady, retake
    case whichItem, itemPlaceholder, existingItems, overwriteTitle, overwriteMessage
    case whereRequired, whereOptional, wherePlaceholder, symbolOptional, noSymbol, hideKeyboard
    case whereLabel, whenLabel, seePhoto, photoOnly
    case newPhoto, newNote, editItem, deleteItem, deleteItemConfirm, addFavorite, removeFavorite
    case name, nameTaken
    case allItems, resultsCount, noResults
    case language, display, showSymbols, showSymbolsInfo, themes, colors
    case colorBackground, colorTiles, colorList, colorAccent, resetColors
    case privacyInfo, deleteAll, deleteAllConfirm
    case cameraDeniedTitle, cameraDeniedMessage, openSettings, justNow
    case saved, ago

    // Anzeige (neu)
    case haptics, reduceMotion, reduceMotionInfo

    // Orte
    case placesTitle, usePlaces, usePlacesInfo, whereQuestion, newPlace, placeName, placeNamePlaceholder
    case placeNameTaken, exactSpot, exactSpotPlaceholder, itemsAtPlace, noItemsAtPlace, deletePlace, deletePlaceConfirm
    case placesEmpty, allPlaces, noPlace, editPlace, placeColor, useThemeColor, deleteAllPlaces, deleteAllPlacesConfirm
    case itemsCount, whereOrNote, placesManage, placesManageInfo, placesSortHint
    case placeKitchen, placeLiving, placeBedroom, placeHallway, placeOffice, placeCar, placeBackpack

    // Siri & Kurzbefehle
    case siriTitle, siriInfo, siriExamples, siriExample1, siriExample2, siriExample3, siriExample4
    case siriLockedRead, siriLockedReadInfo, siriOpenShortcuts
    case siriFoundAt, siriFoundNote, siriSeePhoto, siriSaved, siriNothingAt, siriListAt, siriItemNotFound, siriPlaceNotFound
    case siriSince, siriOpenApp, siriNeedsUnlock

    // Widget
    case widgetTitle, widgetInfo, widgetShowPhotos, widgetShowPlace, widgetPrivacy, widgetPrivacyInfo
    case widgetPlaceholder, widgetNoFavorites, widgetAdd, widgetFavoriteName, widgetFavoriteDesc
    case widgetGridName, widgetGridDesc, widgetSelectFavorite, widgetHowTo

    // Erinnerungen
    case remindersTitle, remindersEnable, remindersInfo, staleReminder, staleReminderInfo, staleInterval
    case interval1w, interval1m, interval3m, interval6m, interval1y
    case remindScope, scopeFavorites, scopeAll, quietHours, quietFrom, quietTo, quietInfo
    case notifDenied, notifDeniedMessage
    case customReminder, reminderDate, reminderRepeat, repeatNone, repeatDaily, repeatWeekly, repeatMonthly
    case reminderText, reminderTextPlaceholder, removeReminder, reminderActive, reminderNone
    case notifStaleTitle, notifStaleBody, notifStaleBodyNoPlace, notifLockedBody, notifCustomTitle
    case actionStillThere, actionNewLocation, actionOpen

    // Sicherheit
    case securityTitle, appLock, appLockInfo, lockAfter, lockImmediately, lock1min, lock5min, lock15min
    case hideInSwitcher, hideInSwitcherInfo, noPasscode, lockedTitle, unlock, unlockFailed, faceIDReason
}

enum Strings {
    static func text(_ key: Str, language: AppLanguage) -> String {
        let table = language == .de ? de : en
        return table[key] ?? de[key] ?? key.rawValue
    }

    static let de: [Str: String] = [
        .search: "Suche",
        .settings: "Einstellungen",
        .done: "Fertig",
        .cancel: "Abbrechen",
        .delete: "Löschen",
        .ok: "OK",
        .close: "Schließen",
        .save: "Speichern",
        .details: "Details",
        .add: "Hinzufügen",
        .edit: "Bearbeiten",
        .back: "Zurück",

        .recentlyUsed: "Zuletzt verwendet",
        .emptyRecent: "Noch nichts eingetragen – tippe unten auf +",
        .favoriteSlot: "Favorit wählen",
        .chooseFavorite: "Favorit wählen",
        .noFavoriteCandidates: "Alle eingetragenen Gegenstände sind schon Favoriten. Trage zuerst einen neuen Gegenstand ein.",
        .favoritesFull: "Favoriten voll",
        .favoritesFullMessage: "Du kannst maximal 4 Favoriten haben. Entferne zuerst einen anderen Favoriten.",
        .favorite: "Favorit",

        .newEntry: "Neuer Eintrag",
        .photo: "Foto",
        .photoSub: "Ort fotografieren",
        .note: "Notiz",
        .noteSub: "Ort beschreiben",

        .photoTitle: "Foto-Eintrag",
        .noteTitle: "Notiz-Eintrag",
        .photoReady: "Foto aufgenommen",
        .retake: "Neu aufnehmen",

        .whichItem: "Welcher Gegenstand?",
        .itemPlaceholder: "z. B. Schlüssel",
        .existingItems: "Schon eingetragen – antippen zum Aktualisieren",
        .overwriteTitle: "Alter Ort wird ersetzt",
        .overwriteMessage: "„%@“ ist schon eingetragen (%@). Beim Speichern wird der alte Eintrag gelöscht – ein Gegenstand kann nur an einem Ort sein.",
        .whereRequired: "Wo liegt es?",
        .whereOptional: "Notiz (optional)",
        .wherePlaceholder: "z. B. Küche, oberste Schublade links",
        .symbolOptional: "Symbol (optional)",
        .noSymbol: "Kein Symbol",
        .hideKeyboard: "Tastatur ausblenden",

        .whereLabel: "Wo",
        .whenLabel: "Wann",
        .seePhoto: "Siehe Foto",
        .photoOnly: "Foto",

        .newPhoto: "Neues Foto vom Ort",
        .newNote: "Neue Notiz zum Ort",
        .editItem: "Name & Symbol ändern",
        .deleteItem: "Gegenstand löschen",
        .deleteItemConfirm: "Diesen Gegenstand wirklich löschen?",
        .addFavorite: "Als Favorit",
        .removeFavorite: "Kein Favorit mehr",

        .name: "Name",
        .nameTaken: "Diesen Namen gibt es schon.",

        .allItems: "Alle Gegenstände",
        .resultsCount: "%ld Treffer",
        .noResults: "Nichts gefunden",

        .language: "Sprache",
        .display: "Anzeige",
        .showSymbols: "Symbole statt Namen",
        .showSymbolsInfo: "Gegenstände mit Symbol werden auf der Startseite nur mit ihrem Symbol angezeigt.",
        .themes: "Farbvorlagen",
        .colors: "Eigene Farben",
        .colorBackground: "Hintergrund",
        .colorTiles: "Kacheln & Suche",
        .colorList: "Liste & Felder",
        .colorAccent: "Plus-Knopf",
        .resetColors: "Standardfarben wiederherstellen",

        .privacyInfo: "Fotos werden nur in dieser App gespeichert – nicht in deiner Fotomediathek.",
        .deleteAll: "Alle Einträge löschen",
        .deleteAllConfirm: "Wirklich alle Gegenstände und Fotos löschen? Orte bleiben erhalten.",

        .cameraDeniedTitle: "Kein Kamerazugriff",
        .cameraDeniedMessage: "Erlaube den Kamerazugriff in den iPhone-Einstellungen, um Orte zu fotografieren.",
        .openSettings: "Einstellungen öffnen",
        .justNow: "gerade eben",
        .saved: "Gespeichert",
        .ago: "vor",

        .haptics: "Haptisches Feedback",
        .reduceMotion: "Animationen reduzieren",
        .reduceMotionInfo: "Ersetzt Bewegungen durch einfache Überblendungen – unabhängig von der iPhone-Einstellung.",

        // Orte
        .placesTitle: "Orte",
        .usePlaces: "Orte verwenden",
        .usePlacesInfo: "Lege Räume und Orte einmal an und wähle sie beim Eintragen mit einem Tipp. Ausgeschaltet verhält sich die App wie vorher; gespeicherte Orte bleiben erhalten.",
        .whereQuestion: "Wo?",
        .newPlace: "Neuer Ort",
        .placeName: "Name des Ortes",
        .placeNamePlaceholder: "z. B. Küche",
        .placeNameTaken: "Diesen Ort gibt es schon.",
        .exactSpot: "Genaue Stelle (optional)",
        .exactSpotPlaceholder: "z. B. oberste Schublade links",
        .itemsAtPlace: "Gegenstände hier",
        .noItemsAtPlace: "Hier liegt gerade nichts.",
        .deletePlace: "Ort löschen",
        .deletePlaceConfirm: "Ort wirklich löschen? Die Gegenstände bleiben erhalten und verlieren nur den Ort.",
        .placesEmpty: "Noch keine Orte – lege den ersten an.",
        .allPlaces: "Alle",
        .noPlace: "Ohne Ort",
        .editPlace: "Ort bearbeiten",
        .placeColor: "Eigene Farbe",
        .useThemeColor: "Farbe der Kacheln verwenden",
        .deleteAllPlaces: "Alle Orte löschen",
        .deleteAllPlacesConfirm: "Wirklich alle Orte löschen? Gegenstände bleiben erhalten.",
        .itemsCount: "%ld Gegenstände",
        .whereOrNote: "Wähle einen Ort oder beschreibe die Stelle.",
        .placesManage: "Orte verwalten",
        .placesManageInfo: "Zum Sortieren oben auf „Bearbeiten“ tippen, zum Löschen nach links wischen.",
        .placesSortHint: "Reihenfolge wie in der Auswahl beim Eintragen.",
        .placeKitchen: "Küche",
        .placeLiving: "Wohnzimmer",
        .placeBedroom: "Schlafzimmer",
        .placeHallway: "Flur",
        .placeOffice: "Büro",
        .placeCar: "Auto",
        .placeBackpack: "Rucksack",

        // Siri
        .siriTitle: "Siri & Kurzbefehle",
        .siriInfo: "Frag Siri, wo etwas liegt, oder trage einen neuen Ort per Sprache ein – ohne die App zu öffnen. Die Sätze funktionieren auf Deutsch und Englisch.",
        .siriExamples: "Beispiele",
        .siriExample1: "„Hey Siri, wo ist mein Schlüssel in Wo ist's?“",
        .siriExample2: "„Hey Siri, Reisepass liegt im Schlafzimmer in Wo ist's?“",
        .siriExample3: "„Hey Siri, was liegt im Auto in Wo ist's?“",
        .siriExample4: "„Hey Siri, neuer Eintrag in Wo ist's?“",
        .siriLockedRead: "Orte auch bei gesperrtem iPhone vorlesen",
        .siriLockedReadInfo: "Ausgeschaltet muss das iPhone entsperrt sein, bevor Siri einen Ort nennt. Bei aktiver App-Sperre ist das Entsperren immer nötig.",
        .siriOpenShortcuts: "Kurzbefehle anzeigen",
        .siriFoundAt: "Dein %@ liegt in „%@“%@ – %@.",
        .siriFoundNote: "Dein %@: %@ – %@.",
        .siriSeePhoto: "Dein %@: siehe Foto in der App – %@.",
        .siriSaved: "Gespeichert: %@ liegt jetzt in „%@“%@.",
        .siriNothingAt: "In „%@“ liegt gerade nichts.",
        .siriListAt: "In „%@“: %@.",
        .siriItemNotFound: "Diesen Gegenstand kenne ich nicht.",
        .siriPlaceNotFound: "Diesen Ort kenne ich nicht.",
        .siriSince: "seit %@",
        .siriOpenApp: "In der App öffnen",
        .siriNeedsUnlock: "Bitte entsperre dein iPhone.",

        // Widget
        .widgetTitle: "Widget",
        .widgetInfo: "Zeigt deine Favoriten auf dem Homescreen und Sperrbildschirm – in deinen Farben.",
        .widgetShowPhotos: "Fotos im Widget zeigen",
        .widgetShowPlace: "Ort im Widget zeigen",
        .widgetPrivacy: "Datenschutz-Modus",
        .widgetPrivacyInfo: "Orte werden im Widget nur angezeigt, wenn das iPhone entsperrt ist.",
        .widgetPlaceholder: "Öffne Wo ist's?, um das Widget zu aktivieren",
        .widgetNoFavorites: "Noch keine Favoriten",
        .widgetAdd: "Eintrag",
        .widgetFavoriteName: "Favorit",
        .widgetFavoriteDesc: "Ein Favorit mit Ort und Zeit.",
        .widgetGridName: "Favoriten",
        .widgetGridDesc: "Deine 4 Favoriten und die letzten Einträge.",
        .widgetSelectFavorite: "Favorit",
        .widgetHowTo: "Homescreen gedrückt halten → „+“ → „Wo ist's?“ suchen. Für den Sperrbildschirm: Sperrbildschirm gedrückt halten → „Anpassen“.",

        // Erinnerungen
        .remindersTitle: "Erinnerungen",
        .remindersEnable: "Erinnerungen",
        .remindersInfo: "Mitteilungen kommen nur von dieser App und werden lokal auf dem iPhone geplant.",
        .staleReminder: "„Liegt es noch da?“",
        .staleReminderInfo: "Erinnert dich, wenn ein Gegenstand lange nicht aktualisiert wurde.",
        .staleInterval: "Nach",
        .interval1w: "1 Woche",
        .interval1m: "1 Monat",
        .interval3m: "3 Monate",
        .interval6m: "6 Monate",
        .interval1y: "1 Jahr",
        .remindScope: "Gilt für",
        .scopeFavorites: "Nur Favoriten",
        .scopeAll: "Alle Gegenstände",
        .quietHours: "Ruhezeit",
        .quietFrom: "Mitteilungen ab",
        .quietTo: "bis",
        .quietInfo: "Mitteilungen außerhalb dieser Zeit werden auf den nächsten erlaubten Zeitpunkt verschoben.",
        .notifDenied: "Keine Mitteilungen erlaubt",
        .notifDeniedMessage: "Erlaube Mitteilungen in den iPhone-Einstellungen, damit Erinnerungen ankommen.",
        .customReminder: "Erinnerung",
        .reminderDate: "Zeitpunkt",
        .reminderRepeat: "Wiederholen",
        .repeatNone: "Nie",
        .repeatDaily: "Täglich",
        .repeatWeekly: "Wöchentlich",
        .repeatMonthly: "Monatlich",
        .reminderText: "Text (optional)",
        .reminderTextPlaceholder: "z. B. Schlüssel mitnehmen",
        .removeReminder: "Erinnerung entfernen",
        .reminderActive: "Erinnerung aktiv",
        .reminderNone: "Keine Erinnerung",
        .notifStaleTitle: "Liegt es noch da?",
        .notifStaleBody: "Liegt dein %@ noch in „%@“? Zuletzt %@ eingetragen.",
        .notifStaleBodyNoPlace: "Liegt dein %@ noch da (%@)? Zuletzt %@ eingetragen.",
        .notifLockedBody: "Erinnerung zu: %@",
        .notifCustomTitle: "Erinnerung: %@",
        .actionStillThere: "Ja, liegt noch da",
        .actionNewLocation: "Neuer Ort",
        .actionOpen: "Öffnen",

        // Sicherheit
        .securityTitle: "Sicherheit",
        .appLock: "App-Sperre",
        .appLockInfo: "Schützt die App mit Face ID, Touch ID oder deinem iPhone-Code.",
        .lockAfter: "Sperren nach",
        .lockImmediately: "Sofort",
        .lock1min: "1 Minute",
        .lock5min: "5 Minuten",
        .lock15min: "15 Minuten",
        .hideInSwitcher: "Inhalt im App-Umschalter verbergen",
        .hideInSwitcherInfo: "In der App-Übersicht wird statt der Orte nur die Hintergrundfarbe gezeigt.",
        .noPasscode: "Richte zuerst einen Code auf deinem iPhone ein, um die App-Sperre zu nutzen.",
        .lockedTitle: "Wo ist's? ist gesperrt",
        .unlock: "Entsperren",
        .unlockFailed: "Entsperren fehlgeschlagen. Bitte erneut versuchen.",
        .faceIDReason: "Entsperre Wo ist's?",
    ]

    static let en: [Str: String] = [
        .search: "Search",
        .settings: "Settings",
        .done: "Done",
        .cancel: "Cancel",
        .delete: "Delete",
        .ok: "OK",
        .close: "Close",
        .save: "Save",
        .details: "Details",
        .add: "Add",
        .edit: "Edit",
        .back: "Back",

        .recentlyUsed: "Recently used",
        .emptyRecent: "Nothing saved yet – tap + below",
        .favoriteSlot: "Pick favorite",
        .chooseFavorite: "Pick favorite",
        .noFavoriteCandidates: "All saved items are already favorites. Add a new item first.",
        .favoritesFull: "Favorites full",
        .favoritesFullMessage: "You can have up to 4 favorites. Remove another favorite first.",
        .favorite: "Favorite",

        .newEntry: "New entry",
        .photo: "Photo",
        .photoSub: "Take a photo of the spot",
        .note: "Note",
        .noteSub: "Describe the spot",

        .photoTitle: "Photo entry",
        .noteTitle: "Note entry",
        .photoReady: "Photo taken",
        .retake: "Retake",

        .whichItem: "Which item?",
        .itemPlaceholder: "e.g. Keys",
        .existingItems: "Already saved – tap to update",
        .overwriteTitle: "Old location will be replaced",
        .overwriteMessage: "“%@” is already saved (%@). Saving deletes the old entry – an item can only be in one place.",
        .whereRequired: "Where is it?",
        .whereOptional: "Note (optional)",
        .wherePlaceholder: "e.g. kitchen, top drawer on the left",
        .symbolOptional: "Symbol (optional)",
        .noSymbol: "No symbol",
        .hideKeyboard: "Hide keyboard",

        .whereLabel: "Where",
        .whenLabel: "When",
        .seePhoto: "See photo",
        .photoOnly: "Photo",

        .newPhoto: "New photo of the spot",
        .newNote: "New note for the spot",
        .editItem: "Change name & symbol",
        .deleteItem: "Delete item",
        .deleteItemConfirm: "Really delete this item?",
        .addFavorite: "Make favorite",
        .removeFavorite: "Remove favorite",

        .name: "Name",
        .nameTaken: "This name already exists.",

        .allItems: "All items",
        .resultsCount: "%ld results",
        .noResults: "Nothing found",

        .language: "Language",
        .display: "Display",
        .showSymbols: "Symbols instead of names",
        .showSymbolsInfo: "Items with a symbol are shown only by their symbol on the home screen.",
        .themes: "Color presets",
        .colors: "Custom colors",
        .colorBackground: "Background",
        .colorTiles: "Tiles & search",
        .colorList: "List & fields",
        .colorAccent: "Plus button",
        .resetColors: "Restore default colors",

        .privacyInfo: "Photos are stored only inside this app – not in your photo library.",
        .deleteAll: "Delete all entries",
        .deleteAllConfirm: "Really delete all items and photos? Places are kept.",

        .cameraDeniedTitle: "No camera access",
        .cameraDeniedMessage: "Allow camera access in the iPhone settings to take photos of places.",
        .openSettings: "Open Settings",
        .justNow: "just now",
        .saved: "Saved",
        .ago: "ago",

        .haptics: "Haptic feedback",
        .reduceMotion: "Reduce animations",
        .reduceMotionInfo: "Replaces motion with simple fades – independent of the iPhone setting.",

        // Places
        .placesTitle: "Places",
        .usePlaces: "Use places",
        .usePlacesInfo: "Set up rooms and places once and pick them with one tap when saving. Turned off, the app behaves as before; saved places are kept.",
        .whereQuestion: "Where?",
        .newPlace: "New place",
        .placeName: "Place name",
        .placeNamePlaceholder: "e.g. Kitchen",
        .placeNameTaken: "This place already exists.",
        .exactSpot: "Exact spot (optional)",
        .exactSpotPlaceholder: "e.g. top drawer on the left",
        .itemsAtPlace: "Items here",
        .noItemsAtPlace: "Nothing here right now.",
        .deletePlace: "Delete place",
        .deletePlaceConfirm: "Really delete this place? Items are kept and only lose the place.",
        .placesEmpty: "No places yet – create the first one.",
        .allPlaces: "All",
        .noPlace: "No place",
        .editPlace: "Edit place",
        .placeColor: "Custom color",
        .useThemeColor: "Use tile color",
        .deleteAllPlaces: "Delete all places",
        .deleteAllPlacesConfirm: "Really delete all places? Items are kept.",
        .itemsCount: "%ld items",
        .whereOrNote: "Pick a place or describe the spot.",
        .placesManage: "Manage places",
        .placesManageInfo: "Tap “Edit” above to reorder, swipe left to delete.",
        .placesSortHint: "Same order as in the picker when saving.",
        .placeKitchen: "Kitchen",
        .placeLiving: "Living room",
        .placeBedroom: "Bedroom",
        .placeHallway: "Hallway",
        .placeOffice: "Office",
        .placeCar: "Car",
        .placeBackpack: "Backpack",

        // Siri
        .siriTitle: "Siri & Shortcuts",
        .siriInfo: "Ask Siri where something is, or save a new spot by voice – without opening the app. Phrases work in English and German.",
        .siriExamples: "Examples",
        .siriExample1: "“Hey Siri, where are my keys in Wo ist's?”",
        .siriExample2: "“Hey Siri, passport is in the bedroom in Wo ist's?”",
        .siriExample3: "“Hey Siri, what's in the car in Wo ist's?”",
        .siriExample4: "“Hey Siri, new entry in Wo ist's?”",
        .siriLockedRead: "Read locations while iPhone is locked",
        .siriLockedReadInfo: "Turned off, the iPhone must be unlocked before Siri names a location. With app lock enabled, unlocking is always required.",
        .siriOpenShortcuts: "Show shortcuts",
        .siriFoundAt: "Your %@ is in “%@”%@ – %@.",
        .siriFoundNote: "Your %@: %@ – %@.",
        .siriSeePhoto: "Your %@: see the photo in the app – %@.",
        .siriSaved: "Saved: %@ is now in “%@”%@.",
        .siriNothingAt: "Nothing is in “%@” right now.",
        .siriListAt: "In “%@”: %@.",
        .siriItemNotFound: "I don't know that item.",
        .siriPlaceNotFound: "I don't know that place.",
        .siriSince: "since %@",
        .siriOpenApp: "Open in app",
        .siriNeedsUnlock: "Please unlock your iPhone.",

        // Widget
        .widgetTitle: "Widget",
        .widgetInfo: "Shows your favorites on the Home Screen and Lock Screen – in your colors.",
        .widgetShowPhotos: "Show photos in widget",
        .widgetShowPlace: "Show place in widget",
        .widgetPrivacy: "Privacy mode",
        .widgetPrivacyInfo: "Places are only shown in the widget while the iPhone is unlocked.",
        .widgetPlaceholder: "Open Wo ist's? to activate the widget",
        .widgetNoFavorites: "No favorites yet",
        .widgetAdd: "Entry",
        .widgetFavoriteName: "Favorite",
        .widgetFavoriteDesc: "One favorite with place and time.",
        .widgetGridName: "Favorites",
        .widgetGridDesc: "Your 4 favorites and the latest entries.",
        .widgetSelectFavorite: "Favorite",
        .widgetHowTo: "Press and hold the Home Screen → “+” → search “Wo ist's?”. For the Lock Screen: press and hold it → “Customize”.",

        // Reminders
        .remindersTitle: "Reminders",
        .remindersEnable: "Reminders",
        .remindersInfo: "Notifications come only from this app and are scheduled locally on your iPhone.",
        .staleReminder: "“Is it still there?”",
        .staleReminderInfo: "Reminds you when an item hasn't been updated for a while.",
        .staleInterval: "After",
        .interval1w: "1 week",
        .interval1m: "1 month",
        .interval3m: "3 months",
        .interval6m: "6 months",
        .interval1y: "1 year",
        .remindScope: "Applies to",
        .scopeFavorites: "Favorites only",
        .scopeAll: "All items",
        .quietHours: "Quiet hours",
        .quietFrom: "Notifications from",
        .quietTo: "until",
        .quietInfo: "Notifications outside this window are moved to the next allowed time.",
        .notifDenied: "Notifications not allowed",
        .notifDeniedMessage: "Allow notifications in the iPhone settings so reminders can arrive.",
        .customReminder: "Reminder",
        .reminderDate: "Time",
        .reminderRepeat: "Repeat",
        .repeatNone: "Never",
        .repeatDaily: "Daily",
        .repeatWeekly: "Weekly",
        .repeatMonthly: "Monthly",
        .reminderText: "Text (optional)",
        .reminderTextPlaceholder: "e.g. take the keys",
        .removeReminder: "Remove reminder",
        .reminderActive: "Reminder set",
        .reminderNone: "No reminder",
        .notifStaleTitle: "Is it still there?",
        .notifStaleBody: "Is your %@ still in “%@”? Last saved %@.",
        .notifStaleBodyNoPlace: "Is your %@ still there (%@)? Last saved %@.",
        .notifLockedBody: "Reminder for: %@",
        .notifCustomTitle: "Reminder: %@",
        .actionStillThere: "Yes, still there",
        .actionNewLocation: "New location",
        .actionOpen: "Open",

        // Security
        .securityTitle: "Security",
        .appLock: "App lock",
        .appLockInfo: "Protects the app with Face ID, Touch ID or your iPhone passcode.",
        .lockAfter: "Lock after",
        .lockImmediately: "Immediately",
        .lock1min: "1 minute",
        .lock5min: "5 minutes",
        .lock15min: "15 minutes",
        .hideInSwitcher: "Hide content in app switcher",
        .hideInSwitcherInfo: "The app switcher shows only the background color instead of your places.",
        .noPasscode: "Set up a passcode on your iPhone first to use the app lock.",
        .lockedTitle: "Wo ist's? is locked",
        .unlock: "Unlock",
        .unlockFailed: "Unlock failed. Please try again.",
        .faceIDReason: "Unlock Wo ist's?",
    ]
}
