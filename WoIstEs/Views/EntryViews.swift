import SwiftUI
import SwiftData
import AVFoundation
import UIKit

// MARK: - Auswahl: Foto oder Notiz

struct NewEntryChooser: View {
    var onSelect: (EntryKind) -> Void
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.motion) private var motion
    @State private var shown = false

    var body: some View {
        VStack(spacing: 18) {
            Text(settings.t(.newEntry))
                .font(.title2.bold())
                .foregroundStyle(settings.onBackground)

            HStack(spacing: 14) {
                option(.photo, icon: "camera.fill", title: .photo, subtitle: .photoSub)
                    .scaleEffect(shown || motion.reduced ? 1 : 0.96)
                    .opacity(shown ? 1 : 0)
                option(.note, icon: "square.and.pencil", title: .note, subtitle: .noteSub)
                    .scaleEffect(shown || motion.reduced ? 1 : 0.96)
                    .opacity(shown ? 1 : 0)
                    .animation(motion.stagger(1, step: 0.06), value: shown)
            }
            .animation(motion.standard, value: shown)
        }
        .padding(20)
        .padding(.top, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(settings.background.ignoresSafeArea())
        .onAppear { shown = true }
    }

    private func option(_ kind: EntryKind, icon: String, title: Str, subtitle: Str) -> some View {
        Button {
            onSelect(kind)
        } label: {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 38, weight: .semibold))
                Text(settings.t(title))
                    .font(.title3.weight(.semibold))
                Text(settings.t(subtitle))
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .opacity(0.85)
            }
            .foregroundStyle(settings.onTile)
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 160)
            .panel(settings.tile, radius: 16)
            .softShadow(settings, radius: 6, y: 3)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
    }
}

// MARK: - Ablauf (Kamera → Formular)

final class EntryDraft: ObservableObject {
    @Published var name: String
    @Published var symbol: String?
    @Published var note: String = ""
    @Published var place: Place?
    /// Bereits vorhandener Gegenstand, der überschrieben wird
    @Published var existing: Item?

    init(preset: Item?) {
        name = preset?.name ?? ""
        symbol = preset?.symbol
        place = preset?.place
        existing = preset
    }
}

struct EntryFlowView: View {
    let request: EntryRequest

    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @StateObject private var draft: EntryDraft
    @State private var image: UIImage?
    @State private var showingCamera: Bool
    @State private var cameraDenied: Bool

    init(request: EntryRequest) {
        self.request = request
        _draft = StateObject(wrappedValue: EntryDraft(preset: request.preset))
        _showingCamera = State(initialValue: request.kind == .photo)
        // .notDetermined: die Kamera fragt beim Öffnen selbst nach der Erlaubnis
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        _cameraDenied = State(initialValue: request.kind == .photo
            && UIImagePickerController.isSourceTypeAvailable(.camera)
            && (status == .denied || status == .restricted))
    }

    var body: some View {
        Group {
            if showingCamera {
                if cameraDenied {
                    CameraDeniedView(onClose: closeCamera)
                } else {
                    CameraView(
                        onCapture: { captured in
                            image = captured
                            showingCamera = false
                        },
                        onCancel: closeCamera
                    )
                    .ignoresSafeArea()
                    .background(Color.black.ignoresSafeArea())
                }
            } else {
                EntryFormView(
                    kind: request.kind,
                    image: image,
                    draft: draft,
                    onRetake: { showingCamera = true },
                    onCancel: { dismiss() },
                    onSaved: { dismiss() }
                )
            }
        }
    }

    private func closeCamera() {
        if image == nil {
            dismiss()               // ohne Foto abgebrochen → zurück zur Startseite
        } else {
            showingCamera = false   // "Neu aufnehmen" abgebrochen → altes Foto behalten
        }
    }
}

// MARK: - Kamera

/// Systemkamera. Nach der Aufnahme bietet iOS selbst "Wiederholen" oder "Foto benutzen" an.
/// Das Foto wird NICHT in der Fotomediathek gespeichert.
struct CameraView: UIViewControllerRepresentable {
    var onCapture: (UIImage) -> Void
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
            picker.cameraCaptureMode = .photo
        } else {
            // Nur im Simulator (keine Kamera): Bild aus der Mediathek wählen zum Testen
            picker.sourceType = .photoLibrary
        }
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onCapture(image)
            } else {
                parent.onCancel()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onCancel()
        }
    }
}

struct CameraDeniedView: View {
    var onClose: () -> Void
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        PermissionDeniedView(symbol: "camera.fill",
                             title: settings.t(.cameraDeniedTitle),
                             message: settings.t(.cameraDeniedMessage),
                             onClose: onClose)
    }
}

/// Hinweis bei verweigerter Berechtigung (Kamera, Mitteilungen) mit Link zu den iPhone-Einstellungen.
struct PermissionDeniedView: View {
    let symbol: String
    let title: String
    let message: String
    var onClose: () -> Void
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: symbol)
                .font(.system(size: 48))
            Text(title)
                .font(.title2.bold())
            Text(message)
                .multilineTextAlignment(.center)
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text(settings.t(.openSettings))
                    .font(.headline)
                    .foregroundStyle(settings.onTile)
                    .padding(.horizontal, 24)
                    .frame(height: 50)
                    .panel(settings.tile, radius: 12)
            }
            .buttonStyle(PressableStyle())
            Button(settings.t(.cancel), action: onClose)
                .font(.headline)
        }
        .foregroundStyle(settings.onBackground)
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(settings.background.ignoresSafeArea())
    }
}

// MARK: - Formular

struct EntryFormView: View {
    let kind: EntryKind
    let image: UIImage?
    @ObservedObject var draft: EntryDraft
    var onRetake: () -> Void
    var onCancel: () -> Void
    var onSaved: () -> Void

    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context
    @Environment(\.motion) private var motion
    @Query(sort: \Item.updatedAt, order: .reverse) private var items: [Item]
    @Query(sort: \Place.sortOrder) private var places: [Place]
    @FocusState private var focused: Field?
    @State private var showNewPlace = false
    @State private var showConfirmation = false
    @State private var saveCount = 0

    enum Field: Hashable { case name, note }

    private var trimmedName: String { draft.name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedNote: String { draft.note.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var placesActive: Bool { settings.usePlaces }
    private var selectedPlace: Place? { placesActive ? draft.place : nil }

    /// Foto: nur Name nötig. Notiz: Name + (Ort ODER Notiz).
    private var canSave: Bool {
        guard !trimmedName.isEmpty else { return false }
        if image != nil { return true }
        return !trimmedNote.isEmpty || selectedPlace != nil
    }

    /// Zuletzt verwendete Orte zuerst, dann die restlichen in Sortierreihenfolge
    private var orderedPlaces: [Place] {
        var seen = Set<PersistentIdentifier>()
        var result: [Place] = []
        for item in items.prefix(12) {
            if let p = item.place, !seen.contains(p.persistentModelID) {
                seen.insert(p.persistentModelID)
                result.append(p)
            }
        }
        for p in places where !seen.contains(p.persistentModelID) {
            result.append(p)
        }
        return result
    }

    private var suggestions: [Item] {
        let list = trimmedName.isEmpty
            ? items
            : items.filter { $0.name.localizedCaseInsensitiveContains(trimmedName) }
        return Array(list.prefix(6))
    }

    /// Der Gegenstand, der beim Speichern überschrieben wird (ausgewählt oder gleicher Name).
    private var matchedItem: Item? {
        if let existing = draft.existing { return existing }
        guard !trimmedName.isEmpty else { return nil }
        return items.first {
            $0.name.compare(trimmedName, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if let image {
                        photoHeader(image)
                    }
                    itemSection
                    if !suggestions.isEmpty {
                        suggestionSection
                    }
                    if let match = matchedItem {
                        overwriteHint(match)
                            .transition(motion.appear)
                    }
                    if placesActive {
                        placeSection
                    }
                    noteSection
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel(key: .symbolOptional)
                        SymbolPicker(selection: $draft.symbol)
                    }
                }
                .padding(20)
                .animation(motion.standard, value: matchedItem?.persistentModelID)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(settings.background.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) { doneButton }
            .navigationTitle(settings.t(kind == .photo ? .photoTitle : .noteTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(settings.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(settings.t(.cancel), action: onCancel)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button {
                        focused = nil
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                    }
                    .accessibilityLabel(settings.t(.hideKeyboard))
                }
            }
            .overlay {
                if showConfirmation {
                    ZStack {
                        settings.background.opacity(0.6).ignoresSafeArea()
                        SaveConfirmation()
                    }
                    .transition(motion.scaleFade)
                }
            }
            .animation(motion.standard, value: showConfirmation)
            .sheet(isPresented: $showNewPlace) {
                PlaceEditorView(place: nil) { created in
                    draft.place = created
                }
                .environmentObject(settings)
            }
        }
        .tint(settings.onBackground)
        .sensoryFeedback(.success, trigger: saveCount) { _, _ in settings.haptics }
        .task {
            // Bei Notizen direkt das passende Feld fokussieren
            guard kind == .note else { return }
            try? await Task.sleep(for: .milliseconds(450))
            focused = draft.existing == nil ? .name : .note
        }
    }

    // MARK: Abschnitte

    private func photoHeader(_ image: UIImage) -> some View {
        HStack(spacing: 16) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.black.opacity(0.35), lineWidth: 1.5)
                )
                .softShadow(settings, radius: 6, y: 3)
            VStack(alignment: .leading, spacing: 10) {
                Label(settings.t(.photoReady), systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(settings.onBackground)
                Button(action: onRetake) {
                    Label(settings.t(.retake), systemImage: "arrow.counterclockwise")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(settings.onList)
                        .padding(.horizontal, 12)
                        .frame(height: 38)
                        .panel(settings.list, radius: 10)
                }
                .buttonStyle(PressableStyle())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var itemSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(key: .whichItem)
            TextField("", text: $draft.name,
                      prompt: Text(settings.t(.itemPlaceholder)).foregroundColor(settings.onList.opacity(0.5)))
                .font(.title3)
                .focused($focused, equals: .name)
                .textInputAutocapitalization(.sentences)
                .submitLabel(.next)
                .onSubmit { focused = .note }
                .foregroundStyle(settings.onList)
                .padding(14)
                .panel(settings.list, radius: 10)
                .onChange(of: draft.name) { _, newValue in
                    // Name geändert → Auswahl eines bestehenden Gegenstands aufheben
                    if let existing = draft.existing, existing.name != newValue {
                        draft.existing = nil
                    }
                }
        }
    }

    private var suggestionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(settings.t(.existingItems))
                .font(.footnote.weight(.semibold))
                .foregroundStyle(settings.onBackground.opacity(0.85))

            ForEach(suggestions) { item in
                let selected = matchedItem?.persistentModelID == item.persistentModelID
                Button {
                    select(item)
                } label: {
                    HStack(spacing: 12) {
                        ItemThumb(item: item, size: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name).font(.headline)
                            Text(settings.relative(item.updatedAt) + " · "
                                 + item.locationText(fallback: settings.t(.seePhoto)))
                                .font(.caption)
                                .lineLimit(1)
                                .opacity(0.75)
                        }
                        Spacer(minLength: 8)
                        Image(systemName: selected ? "checkmark.circle.fill" : "arrow.triangle.2.circlepath")
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .foregroundStyle(selected ? settings.onTile : settings.onList)
                    .padding(10)
                    .panel(selected ? settings.tile : settings.list, radius: 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressableStyle())
            }
        }
    }

    private func overwriteHint(_ item: Item) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.headline)
            VStack(alignment: .leading, spacing: 4) {
                Text(settings.t(.overwriteTitle))
                    .font(.subheadline.weight(.semibold))
                Text(String(format: settings.t(.overwriteMessage), item.name, settings.relative(item.updatedAt)))
                    .font(.caption)
            }
        }
        .foregroundStyle(settings.onSearchBar)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .panel(settings.searchBar, radius: 10)
    }

    private var placeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(key: .whereQuestion)
            PlaceChipsRow(places: orderedPlaces, selection: $draft.place, onAdd: { showNewPlace = true })
            if kind == .note, selectedPlace == nil, trimmedNote.isEmpty {
                Text(settings.t(.whereOrNote))
                    .font(.caption)
                    .foregroundStyle(settings.onBackground.opacity(0.7))
            }
        }
    }

    private var noteSection: some View {
        let hasPlace = selectedPlace != nil
        let label: Str = hasPlace ? .exactSpot : (kind == .note ? .whereRequired : .whereOptional)
        let placeholder: Str = hasPlace ? .exactSpotPlaceholder : .wherePlaceholder
        return VStack(alignment: .leading, spacing: 8) {
            SectionLabel(key: label)
                .animation(nil, value: hasPlace)
            TextField("", text: $draft.note,
                      prompt: Text(settings.t(placeholder)).foregroundColor(settings.onList.opacity(0.5)),
                      axis: .vertical)
                .lineLimit(kind == .note && !hasPlace ? 5...10 : 2...6)
                .focused($focused, equals: .note)
                .foregroundStyle(settings.onList)
                .padding(14)
                .panel(settings.list, radius: 10)
        }
    }

    private var doneButton: some View {
        Button(action: save) {
            Text(settings.t(.done))
                .font(.headline)
                .foregroundStyle(settings.onTile)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .panel(settings.tile, radius: 14)
                .softShadow(settings, radius: 6, y: 3)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .disabled(!canSave || showConfirmation)
        .opacity(canSave ? 1 : 0.45)
        .animation(motion.quick, value: canSave)
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(settings.background.ignoresSafeArea(edges: .bottom))
    }

    // MARK: Aktionen

    private func select(_ item: Item) {
        draft.existing = item
        draft.name = item.name
        draft.symbol = item.symbol
        draft.place = item.place
        focused = nil
    }

    private func save() {
        guard canSave else { return }
        let photo = image.flatMap { ImageTools.jpegData($0, maxDimension: 1600) }
        let thumbnail = image.flatMap { ImageTools.jpegData($0, maxDimension: 240) }
        let place = selectedPlace

        let saved: Item
        if let item = matchedItem {
            // Gegenstand existiert schon → alter Ort wird komplett ersetzt
            item.name = trimmedName
            item.symbol = draft.symbol
            item.relocate(note: trimmedNote, photoData: photo, thumbnailData: thumbnail, place: place)
            saved = item
        } else {
            let item = Item(name: trimmedName,
                            symbol: draft.symbol,
                            locationNote: trimmedNote,
                            photoData: photo,
                            thumbnailData: thumbnail)
            context.insert(item)
            item.place = place   // Beziehung erst nach dem Einfügen setzen (SwiftData-Stabilität)
            saved = item
        }
        try? context.save()
        ReminderManager.shared.schedule(for: saved)
        WidgetReloader.reload()
        saveCount += 1
        focused = nil
        showConfirmation = true
        Task {
            try? await Task.sleep(for: .milliseconds(motion.reduced ? 350 : 650))
            onSaved()
        }
    }
}
