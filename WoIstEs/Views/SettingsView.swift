import SwiftUI
import SwiftData
import AppIntents

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.motion) private var motion
    @Query private var items: [Item]

    @State private var confirmDeleteAll = false

    var body: some View {
        NavigationStack {
            Form {
                // 1. Sprache
                Section(settings.t(.language)) {
                    Picker(settings.t(.language), selection: $settings.language) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: settings.language) { _, _ in
                        ReminderManager.shared.languageChanged(context: context)
                        WidgetReloader.reload()
                    }
                }

                // 2. Anzeige
                Section {
                    Toggle(settings.t(.showSymbols), isOn: $settings.showSymbols)
                        .onChange(of: settings.showSymbols) { _, _ in WidgetReloader.reload() }
                    Toggle(settings.t(.haptics), isOn: $settings.haptics)
                    Toggle(settings.t(.reduceMotion), isOn: $settings.reduceMotion)
                } header: {
                    Text(settings.t(.display))
                } footer: {
                    Text(settings.t(.showSymbolsInfo) + " " + settings.t(.reduceMotionInfo))
                }

                // 3. Farben
                Section(settings.t(.themes)) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(ColorTheme.all) { theme in
                                Button {
                                    withAnimation(motion.color) { settings.apply(theme) }
                                } label: {
                                    ThemeSwatch(theme: theme,
                                                title: theme.name(settings.language),
                                                isSelected: settings.isCurrent(theme))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }

                Section(settings.t(.colors)) {
                    ColorPicker(settings.t(.colorBackground), selection: settings.binding(\.backgroundHex), supportsOpacity: false)
                    ColorPicker(settings.t(.colorTiles), selection: settings.binding(\.tileHex), supportsOpacity: false)
                    ColorPicker(settings.t(.colorList), selection: settings.binding(\.listHex), supportsOpacity: false)
                    ColorPicker(settings.t(.colorAccent), selection: settings.binding(\.accentHex), supportsOpacity: false)
                    Button(settings.t(.resetColors)) {
                        withAnimation(motion.color) { settings.apply(.original) }
                    }
                }

                // 4.–8. Neue Bereiche
                Section {
                    NavigationLink {
                        PlacesSettingsView()
                    } label: {
                        Label(settings.t(.placesTitle), systemImage: "mappin.and.ellipse")
                    }
                    NavigationLink {
                        SiriSettingsView()
                    } label: {
                        Label(settings.t(.siriTitle), systemImage: "waveform")
                    }
                    NavigationLink {
                        WidgetSettingsView()
                    } label: {
                        Label(settings.t(.widgetTitle), systemImage: "square.grid.2x2")
                    }
                    NavigationLink {
                        RemindersSettingsView()
                    } label: {
                        Label(settings.t(.remindersTitle), systemImage: "bell")
                    }
                    NavigationLink {
                        SecuritySettingsView()
                    } label: {
                        Label(settings.t(.securityTitle), systemImage: "lock.shield")
                    }
                }

                // 9. Datenschutz & Löschen
                Section {
                    Label(settings.t(.privacyInfo), systemImage: "lock.shield")
                        .font(.footnote)
                }

                Section {
                    Button(settings.t(.deleteAll), role: .destructive) {
                        confirmDeleteAll = true
                    }
                    .disabled(items.isEmpty)
                }
            }
            .navigationTitle(settings.t(.settings))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(settings.t(.done)) { dismiss() }
                }
            }
            .confirmationDialog(settings.t(.deleteAllConfirm), isPresented: $confirmDeleteAll, titleVisibility: .visible) {
                Button(settings.t(.delete), role: .destructive) {
                    for item in items { context.delete(item) }
                    try? context.save()
                    ReminderManager.shared.cancelAll()
                    WidgetReloader.reload()
                }
                Button(settings.t(.cancel), role: .cancel) {}
            }
        }
        .tint(settings.tile)
        .onChange(of: settings.backgroundHex) { _, _ in WidgetReloader.reload() }
        .onChange(of: settings.tileHex) { _, _ in WidgetReloader.reload() }
        .onChange(of: settings.listHex) { _, _ in WidgetReloader.reload() }
        .onChange(of: settings.accentHex) { _, _ in WidgetReloader.reload() }
    }
}

struct ThemeSwatch: View {
    let theme: ColorTheme
    let title: String
    let isSelected: Bool
    @Environment(\.motion) private var motion

    var body: some View {
        VStack(spacing: 6) {
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3).fill(Color(hex: theme.tile))
                    RoundedRectangle(cornerRadius: 3).fill(Color(hex: theme.tile))
                }
                .frame(height: 22)
                RoundedRectangle(cornerRadius: 2).fill(Color(hex: theme.list)).frame(height: 6)
                RoundedRectangle(cornerRadius: 2).fill(Color(hex: theme.list)).frame(height: 6)
                Circle().fill(Color(hex: theme.accent)).frame(width: 12, height: 12)
            }
            .padding(7)
            .frame(width: 64, height: 80)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(hex: theme.background)))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor : Color.black.opacity(0.2), lineWidth: isSelected ? 3 : 1)
            )
            .scaleEffect(isSelected && !motion.reduced ? 1.04 : 1)
            .animation(motion.standard, value: isSelected)
            Text(title)
                .font(.caption2)
        }
    }
}

// MARK: - Siri & Kurzbefehle

struct SiriSettingsView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        Form {
            Section {
                Text(settings.t(.siriInfo))
                    .font(.footnote)
            }
            Section(settings.t(.siriExamples)) {
                ForEach([Str.siriExample1, .siriExample2, .siriExample3, .siriExample4], id: \.rawValue) { key in
                    Label(settings.t(key), systemImage: "quote.bubble")
                        .font(.subheadline)
                }
            }
            Section {
                Toggle(settings.t(.siriLockedRead), isOn: $settings.siriAllowLocked)
            } footer: {
                Text(settings.t(.siriLockedReadInfo))
            }
            Section {
                SiriTipView(intent: FindItemIntent())
                    .siriTipViewStyle(.automatic)
                ShortcutsLink()
                    .shortcutsLinkStyle(.automatic)
            }
        }
        .navigationTitle(settings.t(.siriTitle))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Widget

struct WidgetSettingsView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        Form {
            Section {
                Text(settings.t(.widgetInfo)).font(.footnote)
                Text(settings.t(.widgetHowTo)).font(.footnote).foregroundStyle(.secondary)
            }
            Section {
                Toggle(settings.t(.widgetShowPhotos), isOn: $settings.widgetShowPhotos)
                Toggle(settings.t(.widgetShowPlace), isOn: $settings.widgetShowPlace)
                Toggle(settings.t(.widgetPrivacy), isOn: $settings.widgetPrivacy)
            } footer: {
                Text(settings.t(.widgetPrivacyInfo))
            }
        }
        .navigationTitle(settings.t(.widgetTitle))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: settings.widgetShowPhotos) { _, _ in WidgetReloader.reload() }
        .onChange(of: settings.widgetShowPlace) { _, _ in WidgetReloader.reload() }
        .onChange(of: settings.widgetPrivacy) { _, _ in WidgetReloader.reload() }
    }
}

// MARK: - Erinnerungen

struct RemindersSettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context
    @ObservedObject private var manager = ReminderManager.shared
    @State private var showDenied = false

    private var denied: Bool { manager.authorization == .denied }

    var body: some View {
        Form {
            Section {
                Toggle(settings.t(.remindersEnable), isOn: Binding(
                    get: { settings.remindersEnabled },
                    set: { newValue in
                        if newValue {
                            Task {
                                let ok = await manager.requestAuthorization()
                                if ok {
                                    settings.remindersEnabled = true
                                    manager.rescheduleAll(context: context)
                                } else {
                                    settings.remindersEnabled = false
                                    showDenied = true
                                }
                            }
                        } else {
                            settings.remindersEnabled = false
                            manager.cancelAll()
                        }
                    }
                ))
            } footer: {
                Text(settings.t(.remindersInfo))
            }

            if settings.remindersEnabled {
                Section {
                    Toggle(settings.t(.staleReminder), isOn: $settings.staleEnabled)
                    if settings.staleEnabled {
                        Picker(settings.t(.staleInterval), selection: $settings.staleInterval) {
                            ForEach(StaleInterval.allCases) { interval in
                                Text(settings.t(interval.key)).tag(interval.seconds)
                            }
                        }
                        Picker(settings.t(.remindScope), selection: $settings.remindFavoritesOnly) {
                            Text(settings.t(.scopeFavorites)).tag(true)
                            Text(settings.t(.scopeAll)).tag(false)
                        }
                    }
                } footer: {
                    Text(settings.t(.staleReminderInfo))
                }

                Section {
                    Picker(settings.t(.quietFrom), selection: $settings.quietFrom) {
                        ForEach(0..<24, id: \.self) { hour in Text(hourLabel(hour)).tag(hour) }
                    }
                    Picker(settings.t(.quietTo), selection: $settings.quietTo) {
                        ForEach(0..<24, id: \.self) { hour in Text(hourLabel(hour)).tag(hour) }
                    }
                } header: {
                    Text(settings.t(.quietHours))
                } footer: {
                    Text(settings.t(.quietInfo))
                }
            }

            if denied {
                Section {
                    Label(settings.t(.notifDeniedMessage), systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                    Button(settings.t(.openSettings)) {
                        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                    }
                }
            }
        }
        .navigationTitle(settings.t(.remindersTitle))
        .navigationBarTitleDisplayMode(.inline)
        .alert(settings.t(.notifDenied), isPresented: $showDenied) {
            Button(settings.t(.openSettings)) {
                if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
            }
            Button(settings.t(.ok), role: .cancel) {}
        } message: {
            Text(settings.t(.notifDeniedMessage))
        }
        .onAppear { manager.refreshAuthorization() }
        .onChange(of: settings.staleEnabled) { _, _ in manager.rescheduleAll(context: context) }
        .onChange(of: settings.staleInterval) { _, _ in manager.rescheduleAll(context: context) }
        .onChange(of: settings.remindFavoritesOnly) { _, _ in manager.rescheduleAll(context: context) }
        .onChange(of: settings.quietFrom) { _, _ in manager.rescheduleAll(context: context) }
        .onChange(of: settings.quietTo) { _, _ in manager.rescheduleAll(context: context) }
    }

    private func hourLabel(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = settings.language.locale
        formatter.setLocalizedDateFormatFromTemplate("j")
        var comps = DateComponents()
        comps.hour = hour
        let date = Calendar.current.date(from: comps) ?? .now
        return formatter.string(from: date)
    }
}

// MARK: - Sicherheit

struct SecuritySettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var lock: LockManager
    @Environment(\.modelContext) private var context

    private var canUse: Bool { LockManager.deviceCanAuthenticate }

    var body: some View {
        Form {
            Section {
                Toggle(settings.t(.appLock), isOn: Binding(
                    get: { settings.lockEnabled },
                    set: { newValue in
                        if newValue {
                            Task {
                                if await lock.enableLock() {
                                    settings.widgetPrivacy = true
                                    ReminderManager.shared.rescheduleAll(context: context)
                                    WidgetReloader.reload()
                                }
                            }
                        } else {
                            lock.disableLock()
                            ReminderManager.shared.rescheduleAll(context: context)
                            WidgetReloader.reload()
                        }
                    }
                ))
                .disabled(!canUse)
            } footer: {
                Text(canUse ? settings.t(.appLockInfo) : settings.t(.noPasscode))
            }

            if settings.lockEnabled {
                Section {
                    Picker(settings.t(.lockAfter), selection: $settings.lockAfter) {
                        ForEach(LockDelay.allCases) { delay in
                            Text(settings.t(delay.key)).tag(delay.seconds)
                        }
                    }
                    Toggle(settings.t(.hideInSwitcher), isOn: $settings.hideInSwitcher)
                } footer: {
                    Text(settings.t(.hideInSwitcherInfo))
                }
            }
        }
        .navigationTitle(settings.t(.securityTitle))
        .navigationBarTitleDisplayMode(.inline)
    }
}
