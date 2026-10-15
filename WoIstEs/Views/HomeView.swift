import SwiftUI
import SwiftData

enum EntryKind {
    case photo, note
}

struct EntryRequest: Identifiable {
    let id = UUID()
    let kind: EntryKind
    var preset: Item? = nil
}

struct HomeView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var router: DeepLinkRouter
    @EnvironmentObject private var lock: LockManager
    @Environment(\.modelContext) private var context
    @Environment(\.motion) private var motion
    @Query(sort: \Item.updatedAt, order: .reverse) private var items: [Item]
    @Query(sort: \Place.sortOrder) private var places: [Place]

    @State private var searchText = ""
    @FocusState private var searchFocused: Bool
    @State private var searchActive = false
    @State private var placeFilter: Place?
    @State private var pendingDelete: Item?
    @State private var showSettings = false
    @State private var showChooser = false
    @State private var pendingKind: EntryKind?
    @State private var entryRequest: EntryRequest?
    @State private var selectedItem: Item?
    @State private var showFavoritePicker = false
    @State private var plusPressed = 0

    private var favorites: [Item] {
        items.filter { $0.isFavorite }.sorted { $0.favoriteOrder < $1.favoriteOrder }
    }

    private var recent: [Item] { Array(items.prefix(4)) }

    private var isSearching: Bool { searchActive || !searchText.isEmpty }

    var body: some View {
        TimelineView(.everyMinute) { _ in
            content
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(settings)
        }
        .sheet(item: $selectedItem, onDismiss: deletePendingItem) { item in
            ItemDetailView(item: item, onDelete: { pendingDelete = item })
                .environmentObject(settings)
        }
        .sheet(isPresented: $showChooser, onDismiss: startPendingEntry) {
            NewEntryChooser { kind in
                pendingKind = kind
                showChooser = false
            }
            .environmentObject(settings)
            .presentationDetents([.height(320)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showFavoritePicker) {
            FavoritePickerView(items: items)
                .environmentObject(settings)
        }
        .fullScreenCover(item: $entryRequest) { request in
            EntryFlowView(request: request)
                .environmentObject(settings)
        }
        .onAppear(perform: handleDeepLink)
        .onChange(of: router.pending) { _, _ in handleDeepLink() }
        .onChange(of: lock.isLocked) { _, locked in if !locked { handleDeepLink() } }
        .sensoryFeedback(.impact(weight: .light), trigger: plusPressed) { _, _ in settings.haptics }
    }

    // MARK: Inhalt

    private var content: some View {
        VStack(spacing: 18) {
            header

            ZStack {
                if isSearching {
                    SearchResultsView(items: items, places: places, query: searchText, placeFilter: $placeFilter) { item in
                        selectedItem = item
                    }
                    .transition(motion.appear)
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            favoritesGrid
                            recentSection
                        }
                        .padding(.bottom, 16)
                    }
                    .scrollIndicators(.hidden)
                    .transition(motion.appear)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .safeAreaInset(edge: .bottom) {
            if !isSearching {
                addButton
                    .transition(motion.scaleFade)
            }
        }
        .background(settings.background.ignoresSafeArea())
        .animation(motion.standard, value: isSearching)
    }

    private var header: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.title3.weight(.semibold))
                TextField("", text: $searchText,
                          prompt: Text(settings.t(.search)).foregroundColor(settings.onSearchBar.opacity(0.75)))
                    .font(.title3)
                    .focused($searchFocused)
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                    .onChange(of: searchFocused) { _, focused in
                        if focused { searchActive = true }
                    }
                if isSearching {
                    Button {
                        searchText = ""
                        searchFocused = false
                        searchActive = false
                        placeFilter = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                    }
                    .accessibilityLabel(settings.t(.close))
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .foregroundStyle(settings.onSearchBar)
            .padding(.horizontal, 14)
            .frame(height: 52)
            .panel(settings.searchBar, radius: 12)
            .contentShape(Rectangle())
            .onTapGesture { searchFocused = true }

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(settings.onBackground)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(PressableStyle())
            .accessibilityLabel(settings.t(.settings))
        }
    }

    private var favoritesGrid: some View {
        let favs = favorites
        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                         spacing: 14) {
            ForEach(0..<Favorites.maxCount, id: \.self) { index in
                ZStack {
                    if index < favs.count {
                        Button {
                            selectedItem = favs[index]
                        } label: {
                            FavoriteTile(item: favs[index])
                        }
                        .buttonStyle(PressableStyle())
                        .transition(motion.scaleFade)
                    } else {
                        Button {
                            if items.isEmpty { showChooser = true } else { showFavoritePicker = true }
                        } label: {
                            EmptyFavoriteTile()
                        }
                        .buttonStyle(PressableStyle())
                        .transition(motion.scaleFade)
                    }
                }
                .animation(motion.standard, value: favs.count)
                .staggeredAppear(index)
            }
        }
    }

    private var recentSection: some View {
        VStack(spacing: 12) {
            Text(settings.t(.recentlyUsed))
                .font(.headline)
                .foregroundStyle(settings.onSearchBar)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .panel(settings.searchBar, radius: 8)
                .staggeredAppear(4)

            Rectangle()
                .fill(settings.divider)
                .frame(height: 2)
                .staggeredAppear(4)

            if recent.isEmpty {
                EmptyState(symbol: "tray", text: settings.t(.emptyRecent))
                    .staggeredAppear(5)
            } else {
                ForEach(Array(recent.enumerated()), id: \.element.persistentModelID) { index, item in
                    Button {
                        selectedItem = item
                    } label: {
                        RecentRow(item: item)
                    }
                    .buttonStyle(PressableStyle())
                    .transition(motion.listChange)
                    .staggeredAppear(5 + index)
                }
            }
        }
        .animation(motion.standard, value: recent.map(\.persistentModelID))
    }

    private var addButton: some View {
        Button {
            plusPressed += 1
            showChooser = true
        } label: {
            ZStack {
                Circle().fill(settings.accent)
                Circle().strokeBorder(Color.white, lineWidth: 4).padding(3)
                Image(systemName: "plus")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(settings.onAccent)
                    .rotationEffect(.degrees(showChooser && !motion.reduced ? 45 : 0))
                    .animation(motion.standard, value: showChooser)
            }
            .frame(width: 78, height: 78)
            .overlay(Circle().stroke(Color.black.opacity(0.6), lineWidth: 2))
            .shadow(color: settings.accent.opacity(showChooser ? 0.55 : 0), radius: 14)
            .softShadow(settings, radius: 8, y: 4)
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(settings.t(.newEntry))
        .frame(maxWidth: .infinity)
        .padding(.top, 6)
        .padding(.bottom, 4)
    }

    // MARK: Aktionen

    /// Löschen erst, wenn die Detailansicht ganz geschlossen ist.
    private func deletePendingItem() {
        guard let item = pendingDelete else { return }
        pendingDelete = nil
        ReminderManager.shared.cancel(for: item)
        context.delete(item)
        try? context.save()
        WidgetReloader.reload()
    }

    private func startPendingEntry() {
        guard let kind = pendingKind else { return }
        pendingKind = nil
        entryRequest = EntryRequest(kind: kind)
    }

    private func handleDeepLink() {
        // Gesperrt → Link bleibt gepuffert und wird nach dem Entsperren ausgeführt
        guard !lock.isLocked, let link = router.consume() else { return }
        // Offene Sheets schließen, damit das Ziel sichtbar wird
        showSettings = false
        showChooser = false
        showFavoritePicker = false
        selectedItem = nil
        switch link {
        case .item(let id):
            if let item = items.first(where: { $0.uuid == id }) { selectedItem = item }
        case .newEntry:
            showChooser = true
        case .newPhoto:
            entryRequest = EntryRequest(kind: .photo)
        case .relocate(let id):
            if let item = items.first(where: { $0.uuid == id }) {
                entryRequest = EntryRequest(kind: .note, preset: item)
            }
        }
    }
}

// MARK: - Kacheln & Zeilen

struct FavoriteTile: View {
    let item: Item
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                title
                Spacer(minLength: 4)
                if let data = item.thumbnailData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 34, height: 34)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(settings.onTile.opacity(0.6), lineWidth: 1))
                }
            }
            Spacer(minLength: 0)
            if settings.usePlaces, let place = item.place {
                Label {
                    Text(place.name).lineLimit(1)
                } icon: {
                    Image(systemName: place.displaySymbol)
                }
                .font(.caption.weight(.semibold))
                if !item.locationNote.isEmpty {
                    Text(item.locationNote)
                        .font(.caption2)
                        .lineLimit(1)
                        .opacity(0.9)
                }
            } else {
                Label {
                    Text(item.locationNote.isEmpty ? settings.t(.photoOnly) : item.locationNote)
                        .lineLimit(2)
                } icon: {
                    Image(systemName: "mappin.and.ellipse")
                }
                .font(.caption)
            }

            Label {
                Text(settings.relative(item.updatedAt))
                    .contentTransition(.numericText())
            } icon: {
                Image(systemName: "clock")
            }
            .font(.caption2)
            .opacity(0.85)
        }
        .foregroundStyle(settings.onTile)
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 130, maxHeight: 130, alignment: .topLeading)
        .panel(settings.tile, radius: 16)
        .softShadow(settings, radius: 6, y: 3)
        .contentShape(Rectangle())
    }

    @ViewBuilder private var title: some View {
        if settings.showSymbols, let symbol = item.symbol {
            Image(systemName: symbol)
                .font(.system(size: 34, weight: .semibold))
                .accessibilityLabel(item.name)
        } else {
            Text(item.name)
                .font(.title3.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

struct EmptyFavoriteTile: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "plus.circle")
                .font(.system(size: 28))
            Text(settings.t(.favoriteSlot))
                .font(.subheadline.weight(.medium))
        }
        .foregroundStyle(settings.onBackground.opacity(0.75))
        .frame(maxWidth: .infinity, minHeight: 130, maxHeight: 130)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(settings.tile.opacity(0.18))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(settings.onBackground.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [7, 5]))
        )
        .contentShape(Rectangle())
    }
}

struct RecentRow: View {
    let item: Item
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        HStack(spacing: 8) {
            ItemTitle(item: item, symbolFont: .title3)
                .font(.title3.weight(.medium))
            Image(systemName: item.thumbnailData == nil ? "note.text" : "camera.fill")
                .font(.caption)
                .opacity(0.55)
            if settings.usePlaces, let place = item.place {
                PlaceTag(place: place, compact: true)
                    .font(.caption)
                    .opacity(0.7)
            }
            Spacer(minLength: 8)
            Text(settings.relative(item.updatedAt))
                .font(.subheadline)
                .opacity(0.75)
                .contentTransition(.numericText())
        }
        .foregroundStyle(settings.onList)
        .padding(.horizontal, 14)
        .frame(minHeight: 44)
        .panel(settings.list, radius: 8)
        .contentShape(Rectangle())
    }
}

/// Einheitliche Ergebniszeile (Suche, Ortsansicht, Favoriten-Auswahl)
struct ItemRow: View {
    let item: Item
    var trailingSymbol: String? = nil
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        HStack(spacing: 12) {
            ItemThumb(item: item, size: 48)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name).font(.headline)
                HStack(spacing: 4) {
                    if settings.usePlaces, let place = item.place {
                        PlaceTag(place: place)
                        if !item.locationNote.isEmpty { Text("·") }
                    }
                    if !item.locationNote.isEmpty || item.place == nil || !settings.usePlaces {
                        Text(item.locationNote.isEmpty ? settings.t(.seePhoto) : item.locationNote)
                    }
                }
                .font(.caption)
                .lineLimit(1)
                .opacity(0.8)
            }
            Spacer(minLength: 8)
            if let trailingSymbol {
                Image(systemName: trailingSymbol)
            } else {
                Text(settings.relative(item.updatedAt))
                    .font(.caption)
                    .opacity(0.75)
                    .contentTransition(.numericText())
            }
        }
        .foregroundStyle(settings.onList)
        .padding(10)
        .panel(settings.list, radius: 10)
        .contentShape(Rectangle())
    }
}

// MARK: - Suche

struct SearchResultsView: View {
    let items: [Item]
    let places: [Place]
    let query: String
    @Binding var placeFilter: Place?
    var onSelect: (Item) -> Void

    @EnvironmentObject private var settings: AppSettings
    @Environment(\.motion) private var motion

    private var placesWithItems: [Place] { places.filter { !$0.items.isEmpty } }

    private var results: [Item] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        var list = items
        if let placeFilter {
            list = list.filter { $0.place?.persistentModelID == placeFilter.persistentModelID }
        }
        guard !q.isEmpty else { return list }
        return list.filter {
            $0.name.localizedCaseInsensitiveContains(q)
                || $0.locationNote.localizedCaseInsensitiveContains(q)
                || ($0.place?.name.localizedCaseInsensitiveContains(q) ?? false)
        }
    }

    var body: some View {
        let found = results
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                if settings.usePlaces, !placesWithItems.isEmpty {
                    PlaceChipsRow(places: placesWithItems, selection: $placeFilter, leadingLabel: settings.t(.allPlaces))
                }

                Text(query.isEmpty && placeFilter == nil
                     ? settings.t(.allItems)
                     : String(format: settings.t(.resultsCount), found.count))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(settings.onBackground)
                    .contentTransition(.numericText())

                if found.isEmpty {
                    EmptyState(symbol: query.isEmpty ? "tray" : "magnifyingglass",
                               text: settings.t(query.isEmpty && placeFilter == nil ? .emptyRecent : .noResults))
                        .transition(motion.appear)
                }

                ForEach(found) { item in
                    Button {
                        onSelect(item)
                    } label: {
                        ItemRow(item: item)
                    }
                    .buttonStyle(PressableStyle())
                    .transition(motion.listChange)
                }
            }
            .padding(.bottom, 20)
            .animation(motion.standard, value: found.map(\.persistentModelID))
        }
        .scrollDismissesKeyboard(.immediately)
    }
}

// MARK: - Ortsansicht („Was liegt alles im Auto?“)

struct PlaceItemsView: View {
    let place: Place
    var onSelect: (Item) -> Void

    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    private var sorted: [Item] { place.items.sorted { $0.updatedAt > $1.updatedAt } }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 10) {
                    HStack(spacing: 14) {
                        SymbolBadge(symbol: place.displaySymbol, size: 58, fill: settings.placeColor(place))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(place.name).font(.title2.bold())
                            Text(String(format: settings.t(.itemsCount), sorted.count)).font(.caption).opacity(0.75)
                        }
                        .foregroundStyle(settings.onBackground)
                        Spacer()
                    }
                    .padding(.bottom, 6)

                    if sorted.isEmpty {
                        EmptyState(symbol: "tray", text: settings.t(.noItemsAtPlace))
                    }
                    ForEach(sorted) { item in
                        Button {
                            onSelect(item)
                        } label: {
                            ItemRow(item: item)
                        }
                        .buttonStyle(PressableStyle())
                    }
                }
                .padding(20)
            }
            .background(settings.background.ignoresSafeArea())
            .navigationTitle(settings.t(.itemsAtPlace))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(settings.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(settings.t(.done)) { dismiss() }
                }
            }
        }
        .tint(settings.onBackground)
    }
}

// MARK: - Favorit wählen

struct FavoritePickerView: View {
    let items: [Item]

    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    private var candidates: [Item] { items.filter { !$0.isFavorite } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    if candidates.isEmpty {
                        Text(settings.t(.noFavoriteCandidates))
                            .foregroundStyle(settings.onBackground)
                            .multilineTextAlignment(.center)
                            .padding(.top, 30)
                    }
                    ForEach(candidates) { item in
                        Button {
                            Favorites.add(item, among: items)
                            try? context.save()
                            ReminderManager.shared.schedule(for: item)
                            WidgetReloader.reload()
                            dismiss()
                        } label: {
                            ItemRow(item: item, trailingSymbol: "star")
                        }
                        .buttonStyle(PressableStyle())
                    }
                }
                .padding(20)
            }
            .background(settings.background.ignoresSafeArea())
            .navigationTitle(settings.t(.chooseFavorite))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(settings.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(settings.t(.cancel)) { dismiss() }
                }
            }
        }
        .tint(settings.onBackground)
    }
}
