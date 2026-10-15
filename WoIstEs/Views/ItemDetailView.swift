import SwiftUI
import SwiftData

struct ItemDetailView: View {
    let item: Item
    /// Wird aufgerufen, bevor die Ansicht schließt – gelöscht wird danach von der Startseite.
    var onDelete: () -> Void = {}

    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var router: DeepLinkRouter
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.motion) private var motion
    @Query private var allItems: [Item]

    @State private var entryRequest: EntryRequest?
    @State private var showEdit = false
    @State private var showReminder = false
    @State private var showPlace = false
    @State private var confirmDelete = false
    @State private var favoritesFull = false
    @State private var showFullPhoto = false
    @State private var appeared = false
    @State private var starBounce = 0

    var body: some View {
        NavigationStack {
            TimelineView(.everyMinute) { _ in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        titleRow.staggeredAppear(0)
                        photo.staggeredAppear(1)
                        whereCard.staggeredAppear(2)
                        infoCard(icon: "clock",
                                 title: settings.t(.whenLabel),
                                 text: settings.relative(item.updatedAt) + " · " + settings.absolute(item.updatedAt))
                            .staggeredAppear(3)
                        if settings.remindersEnabled {
                            reminderCard.staggeredAppear(4)
                        }
                        actions.staggeredAppear(5)
                    }
                    .padding(20)
                }
            }
            .background(settings.background.ignoresSafeArea())
            .navigationTitle(settings.t(.details))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(settings.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        toggleFavorite()
                    } label: {
                        Image(systemName: item.isFavorite ? "star.fill" : "star")
                            .symbolEffect(.bounce, value: starBounce)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .accessibilityLabel(settings.t(item.isFavorite ? .removeFavorite : .addFavorite))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(settings.t(.done)) { dismiss() }
                }
            }
            .alert(settings.t(.favoritesFull), isPresented: $favoritesFull) {
                Button(settings.t(.ok), role: .cancel) {}
            } message: {
                Text(settings.t(.favoritesFullMessage))
            }
            .confirmationDialog(settings.t(.deleteItemConfirm), isPresented: $confirmDelete, titleVisibility: .visible) {
                Button(settings.t(.delete), role: .destructive) { deleteItem() }
                Button(settings.t(.cancel), role: .cancel) {}
            }
            .sheet(isPresented: $showEdit) {
                ItemEditView(item: item)
                    .environmentObject(settings)
            }
            .sheet(isPresented: $showReminder) {
                ReminderEditorView(item: item)
                    .environmentObject(settings)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showPlace) {
                if let place = item.place {
                    PlaceItemsView(place: place) { other in
                        // Anderen Gegenstand öffnen: Ortsansicht schließen, dann die Startseite per Deep Link umschalten
                        let id = other.stableID
                        showPlace = false
                        Task {
                            try? await Task.sleep(for: .milliseconds(450))
                            router.open(.item(id))
                        }
                    }
                    .environmentObject(settings)
                }
            }
            .fullScreenCover(item: $entryRequest) { request in
                EntryFlowView(request: request)
                    .environmentObject(settings)
            }
            .fullScreenCover(isPresented: $showFullPhoto) {
                PhotoViewer(data: item.photoData)
                    .environmentObject(settings)
            }
        }
        .tint(settings.onBackground)
        .sensoryFeedback(.selection, trigger: starBounce) { _, _ in settings.haptics }
    }

    // MARK: Teile

    private var titleRow: some View {
        HStack(spacing: 14) {
            SymbolBadge(symbol: item.symbol, size: 58)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.title.bold())
                    .lineLimit(2)
                if item.isFavorite {
                    Label(settings.t(.favorite), systemImage: "star.fill")
                        .font(.caption.weight(.semibold))
                        .transition(motion.appear)
                }
            }
            .foregroundStyle(settings.onBackground)
        }
        .animation(motion.standard, value: item.isFavorite)
    }

    @ViewBuilder private var photo: some View {
        if let data = item.photoData, let image = UIImage(data: data) {
            Button {
                showFullPhoto = true
            } label: {
                Color.clear
                    .frame(height: 260)
                    .frame(maxWidth: .infinity)
                    .overlay(
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.black.opacity(0.35), lineWidth: 1.5)
                    )
                    .softShadow(settings, radius: 8, y: 4)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressableStyle())
        }
    }

    @ViewBuilder private var whereCard: some View {
        if settings.usePlaces, let place = item.place {
            Button {
                showPlace = true
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    SymbolBadge(symbol: place.displaySymbol, size: 44, fill: settings.placeColor(place))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(settings.t(.whereLabel))
                            .font(.caption.weight(.semibold))
                            .textCase(.uppercase)
                            .opacity(0.7)
                        Text(place.name)
                            .font(.title3.weight(.semibold))
                        if !item.locationNote.isEmpty {
                            Text(item.locationNote)
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                        } else if item.photoData != nil {
                            Text(settings.t(.seePhoto)).font(.body).opacity(0.8)
                        }
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .opacity(0.6)
                }
                .foregroundStyle(settings.onList)
                .padding(14)
                .panel(settings.list, radius: 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(PressableStyle())
        } else {
            infoCard(icon: "mappin.and.ellipse",
                     title: settings.t(.whereLabel),
                     text: item.locationNote.isEmpty ? settings.t(.seePhoto) : item.locationNote)
        }
    }

    private var repeatMode: ReminderRepeat {
        ReminderRepeat(rawValue: item.reminderRepeat ?? "") ?? .never
    }

    private var reminderCard: some View {
        Button {
            showReminder = true
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: item.reminderDate == nil ? "bell" : "bell.badge.fill")
                    .font(.title3)
                    .frame(width: 28)
                    .contentTransition(.symbolEffect(.replace))
                VStack(alignment: .leading, spacing: 4) {
                    Text(settings.t(.customReminder))
                        .font(.caption.weight(.semibold))
                        .textCase(.uppercase)
                        .opacity(0.7)
                    if let date = item.reminderDate {
                        Text(settings.absolute(date) + repeatMode.suffix(settings))
                            .font(.body)
                        if let note = item.reminderNote, !note.isEmpty {
                            Text(note).font(.caption).opacity(0.8)
                        }
                    } else {
                        Text(settings.t(.reminderNone)).font(.body).opacity(0.8)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .opacity(0.6)
            }
            .foregroundStyle(settings.onList)
            .padding(14)
            .panel(settings.list, radius: 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
    }

    private func infoCard(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .opacity(0.7)
                Text(text)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.numericText())
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(settings.onList)
        .padding(14)
        .panel(settings.list, radius: 12)
    }

    private var actions: some View {
        VStack(spacing: 10) {
            actionButton(icon: "camera.fill", title: .newPhoto) {
                entryRequest = EntryRequest(kind: .photo, preset: item)
            }
            actionButton(icon: "square.and.pencil", title: .newNote) {
                entryRequest = EntryRequest(kind: .note, preset: item)
            }
            actionButton(icon: item.isFavorite ? "star.slash" : "star",
                         title: item.isFavorite ? .removeFavorite : .addFavorite) {
                toggleFavorite()
            }
            actionButton(icon: "pencil", title: .editItem) {
                showEdit = true
            }
            Button {
                confirmDelete = true
            } label: {
                Label(settings.t(.deleteItem), systemImage: "trash")
                    .font(.headline)
                    .foregroundStyle(Color.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .panel(settings.list, radius: 12)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressableStyle())
            .padding(.top, 6)
        }
        .padding(.top, 6)
    }

    private func actionButton(icon: String, title: Str, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon).frame(width: 26).contentTransition(.symbolEffect(.replace))
                Text(settings.t(title)).font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .opacity(0.6)
            }
            .foregroundStyle(settings.onTile)
            .padding(.horizontal, 16)
            .frame(height: 52)
            .panel(settings.tile, radius: 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
    }

    // MARK: Aktionen

    private func toggleFavorite() {
        if item.isFavorite {
            Favorites.remove(item)
        } else if !Favorites.add(item, among: allItems) {
            favoritesFull = true
            return
        }
        starBounce += 1
        try? context.save()
        ReminderManager.shared.schedule(for: item)
        WidgetReloader.reload()
    }

    private func deleteItem() {
        onDelete()
        dismiss()
    }
}

extension ReminderRepeat {
    func suffix(_ settings: AppSettings) -> String {
        switch self {
        case .never: return ""
        case .daily: return " · " + settings.t(.repeatDaily)
        case .weekly: return " · " + settings.t(.repeatWeekly)
        case .monthly: return " · " + settings.t(.repeatMonthly)
        }
    }

    func key() -> Str {
        switch self {
        case .never: return .repeatNone
        case .daily: return .repeatDaily
        case .weekly: return .repeatWeekly
        case .monthly: return .repeatMonthly
        }
    }
}

// MARK: - Erinnerung bearbeiten

struct ReminderEditorView: View {
    let item: Item

    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var date: Date
    @State private var repeatMode: ReminderRepeat
    @State private var text: String

    init(item: Item) {
        self.item = item
        _date = State(initialValue: item.reminderDate ?? Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now)
        _repeatMode = State(initialValue: ReminderRepeat(rawValue: item.reminderRepeat ?? "") ?? .never)
        _text = State(initialValue: item.reminderNote ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(settings.t(.reminderDate), selection: $date, in: Date.now...,
                               displayedComponents: [.date, .hourAndMinute])
                        .environment(\.locale, settings.language.locale)
                    Picker(settings.t(.reminderRepeat), selection: $repeatMode) {
                        ForEach(ReminderRepeat.allCases) { mode in
                            Text(settings.t(mode.key())).tag(mode)
                        }
                    }
                }
                Section(settings.t(.reminderText)) {
                    TextField(settings.t(.reminderTextPlaceholder), text: $text)
                }
                if item.reminderDate != nil {
                    Section {
                        Button(settings.t(.removeReminder), role: .destructive) {
                            item.reminderDate = nil
                            item.reminderRepeat = nil
                            item.reminderNote = nil
                            try? context.save()
                            ReminderManager.shared.schedule(for: item)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(settings.t(.customReminder))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(settings.t(.cancel)) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(settings.t(.save)) {
                        item.reminderDate = date
                        item.reminderRepeat = repeatMode.rawValue
                        item.reminderNote = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        try? context.save()
                        ReminderManager.shared.schedule(for: item)
                        dismiss()
                    }
                }
            }
        }
        .tint(settings.tile)
    }
}

// MARK: - Name & Symbol bearbeiten

struct ItemEditView: View {
    let item: Item

    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var allItems: [Item]

    @State private var name: String
    @State private var symbol: String?

    init(item: Item) {
        self.item = item
        _name = State(initialValue: item.name)
        _symbol = State(initialValue: item.symbol)
    }

    private var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var nameTaken: Bool {
        allItems.contains {
            $0.persistentModelID != item.persistentModelID
                && $0.name.compare(trimmed, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel(key: .name)
                        TextField("", text: $name)
                            .font(.title3)
                            .foregroundStyle(settings.onList)
                            .padding(14)
                            .panel(settings.list, radius: 10)
                        if nameTaken {
                            Label(settings.t(.nameTaken), systemImage: "exclamationmark.triangle.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.red)
                        }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel(key: .symbolOptional)
                        SymbolPicker(selection: $symbol)
                    }
                }
                .padding(20)
            }
            .background(settings.background.ignoresSafeArea())
            .navigationTitle(settings.t(.editItem))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(settings.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(settings.t(.cancel)) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(settings.t(.save)) {
                        item.name = trimmed
                        item.symbol = symbol
                        try? context.save()
                        ReminderManager.shared.schedule(for: item)
                        WidgetReloader.reload()
                        dismiss()
                    }
                    .disabled(trimmed.isEmpty || nameTaken)
                }
            }
        }
        .tint(settings.onBackground)
    }
}

// MARK: - Foto groß

struct PhotoViewer: View {
    let data: Data?
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.motion) private var motion
    @State private var scale: CGFloat = 1
    @State private var shown = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            if let data, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale * (shown || motion.reduced ? 1 : 0.94))
                    .opacity(shown ? 1 : 0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .gesture(
                        MagnifyGesture()
                            .onChanged { value in scale = max(1, value.magnification) }
                            .onEnded { _ in withAnimation(motion.standard) { scale = 1 } }
                    )
            }

            Button {
                withAnimation(motion.quick) { shown = false }
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 34))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.white, Color.white.opacity(0.25))
            }
            .padding(16)
            .accessibilityLabel(settings.t(.close))
        }
        .onAppear { withAnimation(motion.gentle) { shown = true } }
    }
}
