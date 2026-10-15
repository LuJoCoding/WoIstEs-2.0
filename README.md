# Wo ist's? – iOS-App (Version 2.0)

Merkt sich, wo du deine wichtigsten Sachen zuletzt abgelegt hast – per Foto oder Notiz.

## Was die App kann

**Seit Version 1.0**
- **Suche** oben: findet alle Gegenstände nach Name, Ortsbeschreibung und jetzt auch Ort. Antippen = alle Gegenstände anzeigen.
- **Zahnrad**: Sprache (Deutsch/Englisch), Farbvorlagen, eigene Farben für Hintergrund, Kacheln, Liste und Plus-Knopf, „Symbole statt Namen“.
- **4 Favoriten-Kacheln**: zeigen direkt Wo (Ort, Notiz bzw. Foto-Vorschau) und Wann. Leere Kachel antippen → Favorit wählen. In der Detailansicht per Stern an-/abwählen.
- **Zuletzt verwendet**: die letzten 4 eingetragenen Gegenstände mit Zeitangabe.
- **+ Knopf** → Auswahl *Foto* oder *Notiz*
  - **Foto**: Kamera öffnet sich, nach der Aufnahme „Wiederholen“ oder „Foto benutzen“. Danach siehst du das Foto klein oben, trägst den Gegenstand ein und tippst auf **Fertig**.
  - **Notiz**: Gegenstand + Ort/Beschreibung eintragen, **Fertig**.
- **Ein Gegenstand = ein Ort**: Unter dem Namensfeld erscheinen bereits eingetragene Gegenstände. Wählst du einen aus (oder tippst denselben Namen), wird der alte Eintrag samt Foto beim Speichern gelöscht und ersetzt.
- **Symbole**: Jedem Gegenstand kann ein Symbol gegeben werden; mit „Symbole statt Namen“ zeigt die Startseite nur das Symbol.
- **Datenschutz**: Fotos werden nur in der App-Datenbank gespeichert, nie in der Fotomediathek.

**Neu in 2.0** – alles in den Einstellungen ein-/ausschaltbar
- **Orte & Räume**: Küche, Auto, Rucksack … einmal anlegen, beim Eintragen antippen. Filter in der Suche („Was liegt alles im Auto?“), Ortsansicht in der Detailansicht, Verwaltung unter *Einstellungen → Orte*.
- **Siri & Kurzbefehle**: „Hey Siri, wo ist mein Schlüssel in Wo ist's?“, „Reisepass liegt im Schlafzimmer in Wo ist's?“, „Was liegt im Auto in Wo ist's?“, „Neuer Eintrag in Wo ist's?“ – auf Deutsch und Englisch.
- **Widgets**: Klein (1 Favorit, auswählbar), Mittel (4 Favoriten), Groß (Favoriten + Zuletzt verwendet) sowie Sperrbildschirm-Widgets – in deinen Farben. Antippen öffnet den Gegenstand.
- **Erinnerungen**: „Liegt es noch da?“ nach 1 Woche bis 1 Jahr (nur Favoriten oder alle), eigene Erinnerungen pro Gegenstand (einmalig/täglich/wöchentlich/monatlich), Ruhezeit. Direkt aus der Mitteilung: „Ja, liegt noch da“ / „Neuer Ort“.
- **App-Sperre**: Face ID / Touch ID / Code, Sperre nach sofort bis 15 Minuten, Inhalt im App-Umschalter verbergen.
- **Animationen & Feinschliff**: ruhige, weiche Übergänge in deinen Farben, dezente Haptik (abschaltbar), „Animationen reduzieren“.

## Auf das iPhone bringen – mit Mac

Du brauchst einen **Mac mit Xcode 16 oder neuer** (kostenlos im App Store).

1. Ordner entpacken und **`WoIstEs.xcodeproj`** doppelklicken.
2. Links das Projekt **WoIstEs** anklicken → Target **WoIstEs** → Reiter **Signing & Capabilities** → bei **Team** deine Apple-ID wählen. Dasselbe für das Target **WoIstEsWidget**.
   Falls Xcode meckert, dass die Bundle-ID vergeben ist: `de.lujo3d.WoIstEs` (und `.Widget`) sowie die App Group `group.de.lujo3d.WoIstEs` in beiden Targets in etwas Eigenes ändern.
3. iPhone per Kabel anschließen, oben als Ziel auswählen, **▶︎ Run** drücken.
4. Beim ersten Mal auf dem iPhone: *Einstellungen → Datenschutz & Sicherheit → Entwicklermodus* einschalten und unter *Allgemein → VPN & Geräteverwaltung* deinem Entwicklerzertifikat vertrauen.

## Ohne Mac (Windows): GitHub baut, Sideloadly installiert

1. Auf github.com ein **öffentliches** Repository anlegen (öffentlich = Build-Minuten kostenlos).
2. Den **Inhalt** dieses Ordners hochladen – inklusive `.github`, `Shared`, `WoIstEs`, `WoIstEsWidget` und `WoIstEs.xcodeproj`.
3. Im Repo auf **Actions → Build IPA → Run workflow** klicken. Nach ca. 5–8 Minuten unten bei *Artifacts* die **WoIstEs-ipa** herunterladen und entpacken. Im Schritt „Inhalt prüfen“ siehst du, ob das Widget enthalten ist.
4. Auf dem PC **iTunes direkt von apple.com** installieren (nicht die Microsoft-Store-Version) und **Sideloadly** von sideloadly.io.
5. iPhone per Kabel anschließen, in Sideloadly auswählen, Apple-ID eintragen, `WoIstEs.ipa` hineinziehen.
   **Wichtig:** In den *Advanced Options* die Option **„Remove app extensions“ NICHT aktivieren** – sonst fehlt das Widget. Dann **Start**.
6. Auf dem iPhone: *Einstellungen → Datenschutz & Sicherheit → Entwicklermodus* an, und unter *Allgemein → VPN & Geräteverwaltung* der eigenen Apple-ID vertrauen.

Mit kostenloser Apple-ID läuft die App 7 Tage, danach in Sideloadly erneut installieren (App vorher **nicht** löschen, sonst sind die Einträge weg). Beim Update von 1.0 auf 2.0 bleiben alle Gegenstände, Fotos, Favoriten und Einstellungen erhalten.

## Berechtigungen (werden erst gefragt, wenn du die Funktion nutzt)

| Funktion | Berechtigung | Wann gefragt |
|---|---|---|
| Foto-Eintrag | Kamera | beim ersten Foto |
| Erinnerungen | Mitteilungen | beim Einschalten in den Einstellungen |
| App-Sperre | Face ID / Touch ID | beim Einschalten in den Einstellungen |

Siri und Widgets brauchen keine Berechtigung.

## Hinweise zur kostenlosen Apple-ID

- Widget und Siri teilen sich die Datenbank mit der App über eine **App Group**. Sideloadly richtet sie normalerweise ein. Falls das mit deiner Apple-ID nicht klappt, läuft die App trotzdem ganz normal weiter (alte Daten bleiben erhalten) – nur das Widget zeigt dann „Öffne Wo ist's?, um das Widget zu aktivieren“. Siri funktioniert trotzdem, weil die Siri-Befehle direkt in der App laufen.
- Die App Group wird beim ersten Start von 2.0 befüllt: Die 1.0-Datenbank wird **kopiert** (nicht verschoben) und geprüft. Das Original bleibt als Sicherung liegen.
- Pro Woche erlaubt Apple mit kostenloser ID nur wenige App-IDs; App + Widget sind zwei davon.

## Aufbau

```
.github/workflows/build-ipa.yml   GitHub baut App + Widget → IPA
Shared/                            Von App UND Widget genutzt
├─ Item.swift, Place.swift         Datenmodell (SwiftData)
├─ SharedStore.swift               Gemeinsame Datenbank (App Group), Migration von 1.0
├─ Localization.swift              Alle Texte (Deutsch/Englisch)
├─ ColorTools.swift                Farben, Farbvorlagen, Theme fürs Widget
├─ DeepLink.swift, RelativeTime.swift
├─ Localizable.xcstrings           Texte für Siri-Intents (System-Lokalisierung)
└─ Intents/Entities.swift          Gegenstand/Ort für Siri + Widget-Konfiguration
WoIstEs/                           Die App
├─ App/WoIstEsApp.swift            Einstieg, Sperre, Deep Links
├─ Settings/AppSettings.swift      Alle Einstellungen (automatisch gespeichert)
├─ Services/                       Erinnerungen, App-Sperre, Deep-Link-Router
├─ Intents/                        Siri-Intents, Siri-Sätze (AppShortcuts.xcstrings)
├─ Views/                          Startseite, Eingabe, Detail, Orte, Einstellungen, Animationen (Motion.swift)
├─ Info.plist                      URL-Schema woistes://
└─ WoIstEs.entitlements            App Group
WoIstEsWidget/                     Widget-Erweiterung (Homescreen + Sperrbildschirm)
```

Weitere Symbole: in `Components.swift` → `SymbolCatalog.all` bzw. `SymbolCatalog.places` beliebige SF-Symbol-Namen ergänzen (App „SF Symbols“ von Apple zum Nachschlagen).

## Falls sich das Projekt nicht öffnen lässt

Neues Projekt in Xcode anlegen (*iOS → App*, Name `WoIstEs`, Interface **SwiftUI**, Storage **None**), die automatisch erzeugten `ContentView.swift` und `WoIstEsApp.swift` löschen, die Ordner `WoIstEs/` und `Shared/` hineinziehen. Dann *File → New → Target → Widget Extension* (`WoIstEsWidget`, ohne Configuration-Intent-Vorlage), deren erzeugte Swift-Dateien löschen und den Inhalt von `WoIstEsWidget/` hineinziehen; `Shared/` zusätzlich dem Widget-Target zuordnen. In beiden Targets unter *Signing & Capabilities* die App Group `group.de.lujo3d.WoIstEs` hinzufügen, beim App-Target unter *Info* das URL-Schema `woistes` sowie *Privacy – Camera Usage Description* und *Privacy – Face ID Usage Description* ergänzen. iOS-Mindestversion: 17.0.
