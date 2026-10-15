import SwiftUI
import SwiftData

// MARK: - Ort anlegen / bearbeiten

struct PlaceEditorView: View {
    /// nil = neuer Ort
    let place: Place?
    var onCreated: ((Place) -> Void)? = nil

    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Place.sortOrder) private var allPlaces: [Place]

    @State private var name: String
    @State private var symbol: String?
    @State private var useCustomColor: Bool
    @State private var color: Color
    @FocusState private var nameFocused: Bool

    init(place: Place?, onCreated: ((Place) -> Void)? = nil) {
        self.place = place
        self.onCreated = onCreated
        _name = State(initialValue: place?.name ?? "")
        _symbol = State(initialValue: place?.symbol)
        _useCustomColor = State(initialValue: place?.colorHex != nil)
        _color = State(initialValue: Color(hex: place?.colorHex ?? ColorTheme.original.tile))
    }

    private var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var nameTaken: Bool {
        allPlaces.contains {
            $0.persistentModelID != place?.persistentModelID
                && $0.name.compare(trimmed, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
    }

    private var previewColor: Color { useCustomColor ? color : settings.tile }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 14) {
                        SymbolBadge(symbol: symbol ?? "mappin.and.ellipse", size: 58, fill: previewColor)
                        Text(trimmed.isEmpty ? settings.t(.newPlace) : trimmed)
                            .font(.title2.bold())
                            .foregroundStyle(settings.onBackground)
                            .lineLimit(1)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel(key: .placeName)
                        TextField("", text: $name,
                                  prompt: Text(settings.t(.placeNamePlaceholder)).foregroundColor(settings.onList.opacity(0.5)))
                            .font(.title3)
                            .focused($nameFocused)
                            .textInputAutocapitalization(.sentences)
                            .foregroundStyle(settings.onList)
                            .padding(14)
                            .panel(settings.list, radius: 10)
                        if nameTaken {
                            Label(settings.t(.placeNameTaken), systemImage: "exclamationmark.triangle.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.red)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel(key: .symbolOptional)
                        SymbolPicker(selection: $symbol, catalog: SymbolCatalog.places)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel(key: .placeColor)
                        Toggle(isOn: $useCustomColor) {
                            Text(useCustomColor ? settings.t(.placeColor) : settings.t(.useThemeColor))
                                .foregroundStyle(settings.onList)
                        }
                        .tint(settings.tile)
                        .padding(.horizontal, 14)
                        .frame(height: 48)
                        .panel(settings.list, radius: 10)
                        if useCustomColor {
                            ColorPicker(selection: $color, supportsOpacity: false) {
                                Text(settings.t(.placeColor)).foregroundStyle(settings.onList)
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 48)
                            .panel(settings.list, radius: 10)
                        }
                    }
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(settings.background.ignoresSafeArea())
            .navigationTitle(settings.t(place == nil ? .newPlace : .editPlace))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(settings.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(settings.t(.cancel)) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(settings.t(.save), action: save)
                        .disabled(trimmed.isEmpty || nameTaken)
                }
            }
        }
        .tint(settings.onBackground)
        .task {
            guard place == nil else { return }
            try? await Task.sleep(for: .milliseconds(400))
            nameFocused = true
        }
    }

    private func save() {
        let hex: String? = useCustomColor ? color.hexString : nil
        if let place {
            place.name = trimmed
            place.symbol = symbol
            place.colorHex = hex
            try? context.save()
        } else {
            let next = (allPlaces.map(\.sortOrder).max() ?? -1) + 1
            let created = Place(name: trimmed, symbol: symbol, colorHex: hex, sortOrder: next)
            context.insert(created)
            try? context.save()
            onCreated?(created)
        }
        WidgetReloader.reload()
        dismiss()
    }
}

// MARK: - Orte verwalten (Einstellungen)

struct PlacesSettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context
    @Environment(\.motion) private var motion
    @Query(sort: \Place.sortOrder) private var places: [Place]

    @State private var editing: Place?
    @State private var showNew = false
    @State private var pendingDelete: Place?
    @State private var confirmDeleteAll = false
    @State private var editMode: EditMode = .inactive

    var body: some View {
        List {
            Section {
                Toggle(settings.t(.usePlaces), isOn: $settings.usePlaces)
            } footer: {
                Text(settings.t(.usePlacesInfo))
            }

            Section {
                if places.isEmpty {
                    Text(settings.t(.placesEmpty)).foregroundStyle(.secondary)
                }
                ForEach(places) { place in
                    Button {
                        editing = place
                    } label: {
                        HStack(spacing: 12) {
                            SymbolBadge(symbol: place.displaySymbol, size: 36, fill: settings.placeColor(place))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(place.name).foregroundStyle(.primary)
                                Text(String(format: settings.t(.itemsCount), place.items.count))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(.tertiary)
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            pendingDelete = place
                        } label: {
                            Label(settings.t(.delete), systemImage: "trash")
                        }
                    }
                }
                .onMove(perform: move)

                Button {
                    showNew = true
                } label: {
                    Label(settings.t(.newPlace), systemImage: "plus.circle.fill")
                }
            } header: {
                Text(settings.t(.placesManage))
            } footer: {
                Text(settings.t(.placesManageInfo) + " " + settings.t(.placesSortHint))
            }

            Section {
                Button(settings.t(.deleteAllPlaces), role: .destructive) { confirmDeleteAll = true }
                    .disabled(places.isEmpty)
            }
        }
        .environment(\.editMode, $editMode)
        .navigationTitle(settings.t(.placesTitle))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(settings.t(editMode == .active ? .done : .edit)) {
                    withAnimation(motion.standard) { editMode = editMode == .active ? .inactive : .active }
                }
                .disabled(places.count < 2)
            }
        }
        .sheet(item: $editing) { place in
            PlaceEditorView(place: place).environmentObject(settings)
        }
        .sheet(isPresented: $showNew) {
            PlaceEditorView(place: nil).environmentObject(settings)
        }
        .confirmationDialog(settings.t(.deletePlaceConfirm), isPresented: Binding(
            get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }
        ), titleVisibility: .visible) {
            Button(settings.t(.delete), role: .destructive) {
                if let place = pendingDelete {
                    pendingDelete = nil
                    delete(place)
                }
            }
            Button(settings.t(.cancel), role: .cancel) { pendingDelete = nil }
        }
        .confirmationDialog(settings.t(.deleteAllPlacesConfirm), isPresented: $confirmDeleteAll, titleVisibility: .visible) {
            Button(settings.t(.delete), role: .destructive) {
                for place in places { delete(place) }
            }
            Button(settings.t(.cancel), role: .cancel) {}
        }
        .animation(motion.standard, value: places.map(\.persistentModelID))
    }

    private func move(from source: IndexSet, to destination: Int) {
        var ordered = places
        ordered.move(fromOffsets: source, toOffset: destination)
        for (index, place) in ordered.enumerated() { place.sortOrder = index }
        try? context.save()
    }

    private func delete(_ place: Place) {
        // Gegenstände behalten, nur Ort entfernen (deleteRule .nullify) – Erinnerungstexte neu planen
        let affected = place.items
        for item in affected { item.place = nil }
        context.delete(place)
        try? context.save()
        for item in affected { ReminderManager.shared.schedule(for: item) }
        WidgetReloader.reload()
    }
}
