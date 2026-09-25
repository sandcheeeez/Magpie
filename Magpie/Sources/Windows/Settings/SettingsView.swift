//
//  SettingsView.swift
//  Magpie
//

import SwiftUI
import AppKit
import HotKey
import UniformTypeIdentifiers

/// Settings window behaviour that isn't app state: recording a new shortcut and choosing apps to exclude.
///
/// Everything else binds directly to `AppState`.
@Observable
final class SettingsModel {
    
    let state = AppState.main
    
    var toggleHotKey: KeyCombo

    /// A shortcut being recorded, shown until saved.
    var recordedHotKey: KeyCombo?

    var isRecording = false {
        didSet {
            keyPressMonitor.isPaused = !isRecording
            if !isRecording { recordedHotKey = nil }
        }
    }

    @ObservationIgnored private let keyPressMonitor = KeyPressMonitor()

    init() {
        toggleHotKey = Settings.main.toggleHotKey

        keyPressMonitor.isPaused = true
        keyPressMonitor.subscribeToKeyDown { [weak self] keys, modifiers in
            guard let self = self, self.isRecording else { return }
            self.recordedHotKey = Self.makeHotKey(keys: keys, modifiers: modifiers)
        }
    }

    func saveRecordedHotKey() {
        guard let hotKey = recordedHotKey else { return }
        MagpieHotKeys.toggle.changeHotKey(keyCombo: hotKey)
        Settings.main.toggleHotKey = hotKey
        toggleHotKey = hotKey
        isRecording = false
    }

    private static func makeHotKey(keys: [Key], modifiers: NSEvent.ModifierFlags) -> KeyCombo? {
        let modifiers = filterModifiers(modifiers)
        let keys = filterKeys(keys)
        guard keys.count == 1, !modifiers.isEmpty || isFunctionKey(key: keys[0]) else {
            return nil
        }
        return KeyCombo(key: keys[0], modifiers: modifiers)
    }

    static func format(_ hotKey: KeyCombo) -> String {
        return (hotKey.modifiers.toStringCharacters() + stringifyKeys([hotKey.key].compactMap({ $0 }))).joined()
    }

    func addExcludedApps() {
        let panel = NSOpenPanel()
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = true
        panel.prompt = "Exclude"
        panel.message = "Copies made in these apps won't be saved to your history."
        guard panel.runModal() == .OK else { return }
        let ids = panel.urls.compactMap({ Bundle(url: $0)?.bundleIdentifier }).filter({ !state.excludedBundleIds.contains($0) })
        state.excludedBundleIds.append(contentsOf: ids)
    }
}

struct GeneralSettingsView: View {

    @Bindable var model: SettingsModel

    var body: some View {
        @Bindable var state = model.state
        Form {
            Section {
                Toggle("Open Magpie when you log in", isOn: Binding(get: { state.launchAtLogin }, set: { state.setLaunchAtLogin($0) }))
            }
            Section("Panel") {
                Picker("Position", selection: $state.panelPosition) {
                    ForEach([PanelPosition.right, .left, .top, .bottom], id: \.self) { Text($0.title).tag($0) }
                    Divider()
                    ForEach([PanelPosition.centerExtraSmall, .centerSmall, .centerMedium, .centerLarge, .fullScreen], id: \.self) { Text($0.title).tag($0) }
                }
            }
            Section {
                Picker("Keep up to", selection: $state.maxHistory) {
                    ForEach(Constants.settings.maxHistoryItemsOptions, id: \.self) { option in
                        Text(option == Constants.settings.unlimitedHistory ? "Unlimited" : "\(option.formatted()) items").tag(option)
                    }
                }
            } header: {
                Text("History")
            } footer: {
                Text("Pinned items are kept in addition to this limit.")
                    .foregroundStyle(.secondary)
            }
            Section("Formatting") {
                Toggle("Show formatting in the history", isOn: $state.showsRichText)
                Toggle("Paste with formatting", isOn: $state.pastesRichText)
            }
        }
        .formStyle(.grouped)
    }
}

struct ShortcutsSettingsView: View {

    @Bindable var model: SettingsModel

    private let panelShortcuts: [(String, String)] = [
        ("Paste selected item", "↩"),
        ("Paste as plain text", "⌥↩"),
        ("Paste item 0–9", "⌘0 – ⌘9"),
        ("Pin or unpin", "⌘P"),
        ("Previous / next filter", "⌘← ⌘→"),
        ("Search", "⌘\\"),
        ("Preview", "⌃Space"),
        ("Delete", "⌃⌫"),
        ("Move panel", "⌃⌥⌘ + arrow"),
        ("Close", "⎋"),
    ]

    var body: some View {
        Form {
            Section("Show Magpie") {
                LabeledContent("Shortcut") {
                    if model.isRecording {
                        HStack {
                            Text(model.recordedHotKey.map(SettingsModel.format) ?? "Type a shortcut…")
                                .foregroundStyle(model.recordedHotKey == nil ? .secondary : .primary)
                                .monospaced()
                            Button("Cancel") { model.isRecording = false }
                            Button("Save") { model.saveRecordedHotKey() }
                                .disabled(model.recordedHotKey == nil)
                                .keyboardShortcut(.defaultAction)
                        }
                    }
                    else {
                        HStack {
                            Text(SettingsModel.format(model.toggleHotKey)).monospaced()
                            Button("Change…") { model.isRecording = true }
                        }
                    }
                }
            }
            Section("In the panel") {
                ForEach(panelShortcuts, id: \.0) { name, keys in
                    LabeledContent(name) {
                        Text(keys).monospaced().foregroundStyle(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onDisappear { model.isRecording = false }
    }
}

struct PrivacySettingsView: View {

    @Bindable var model: SettingsModel
    @State private var selection = Set<String>()

    var body: some View {
        Form {
            Section {
                List(selection: $selection) {
                    ForEach(model.state.excludedBundleIds, id: \.self) { bundleId in
                        HStack(spacing: 8) {
                            if let icon = AppInfo.icon(forBundleId: bundleId) {
                                Image(nsImage: icon).resizable().frame(width: 20, height: 20)
                            }
                            else {
                                Image(systemName: "app.dashed").frame(width: 20, height: 20)
                            }
                            Text(AppInfo.name(forBundleId: bundleId) ?? bundleId)
                            if AppInfo.name(forBundleId: bundleId) == nil {
                                Text("Not installed").font(.caption).foregroundStyle(.tertiary)
                            }
                        }
                        .tag(bundleId)
                    }
                }
                .frame(minHeight: 200)
                HStack {
                    Button("Add App…", systemImage: "plus") { model.addExcludedApps() }
                    Button("Remove", systemImage: "minus") {
                        model.state.excludedBundleIds.removeAll(where: { selection.contains($0) })
                        selection.removeAll()
                    }
                    .disabled(selection.isEmpty)
                    Spacer()
                    Button("Restore Defaults") { model.state.excludedBundleIds = Settings.defaultExcludedBundleIds }
                }
            } header: {
                Text("Don't save copies from these apps")
            } footer: {
                Text("Items that apps mark as passwords or temporary are never saved, whatever app they come from.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}


/// Space used by the history, for the Storage settings.
@Observable
final class StorageModel {
    
    struct KindUsage: Identifiable {
        let kind: HistoryItemKind
        let count: Int
        let bytes: Int
        var id: HistoryItemKind { kind }
    }
    
    private(set) var totalBytes = 0
    private(set) var itemCount = 0
    private(set) var byKind = [KindUsage]()
    private(set) var largest = [HistoryItem]()
    
    @ObservationIgnored private let history = AppState.main.history!
    
    init() {
        refresh()
        // Keep the numbers current while the window is open, e.g. as new items are copied.
        history.subscribe { [weak self] _, _ in self?.refresh() }
    }
    
    func refresh() {
        let items = history.items
        totalBytes = items.reduce(0, { $0 + $1.byteCount })
        itemCount = items.count
        byKind = Dictionary(grouping: items, by: \.kind)
            .map({ KindUsage(kind: $0.key, count: $0.value.count, bytes: $0.value.reduce(0, { $0 + $1.byteCount })) })
            .sorted(by: { $0.bytes > $1.bytes })
        largest = Array(items.sorted(by: { $0.byteCount > $1.byteCount }).prefix(15))
    }
    
    func delete(_ item: HistoryItem) {
        history.delete(items: [item])
    }
    
    /// Deletes all unpinned items of a kind.
    func clear(_ kind: HistoryItemKind) {
        history.delete(items: history.items.filter({ $0.kind == kind && !$0.isPinned }))
    }
    
    static func format(_ bytes: Int) -> String {
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
}

struct StorageSettingsView: View {
    
    @State private var model = StorageModel()
    @State private var kindToClear: HistoryItemKind?
    
    var body: some View {
        Form {
            Section {
                LabeledContent("History") {
                    Text("\(StorageModel.format(model.totalBytes)) in \(model.itemCount.formatted()) items")
                }
                LabeledContent("Location") {
                    Button("Show in Finder") {
                        NSWorkspace.shared.activateFileViewerSelecting([Constants.urls.historyStore])
                    }
                }
            } footer: {
                Text("Your history is stored only on this Mac. Magpie never sends it anywhere.")
                    .foregroundStyle(.secondary)
            }
            
            Section("By type") {
                ForEach(model.byKind) { usage in
                    LabeledContent {
                        HStack {
                            Text(StorageModel.format(usage.bytes)).monospacedDigit().foregroundStyle(.secondary)
                            Button("Clear…") { kindToClear = usage.kind }
                        }
                    } label: {
                        Label("\(HistoryFilter.kind(usage.kind).title) (\(usage.count.formatted()))", systemImage: HistoryFilter.kind(usage.kind).symbolName)
                    }
                }
            }
            
            Section {
                ForEach(model.largest, id: \.id) { item in
                    HStack(spacing: 8) {
                        Image(systemName: HistoryFilter.kind(item.kind).symbolName)
                            .frame(width: 18)
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.displayTitle).lineLimit(1)
                            Text(item.copiedAt, style: .date).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(StorageModel.format(item.byteCount)).monospacedDigit().foregroundStyle(.secondary)
                        if item.isPinned {
                            Image(systemName: "pin.fill").foregroundStyle(.orange).help("Pinned items are kept. Unpin it to delete it.")
                        }
                        else {
                            Button {
                                model.delete(item)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                            .help("Delete this item")
                        }
                    }
                }
            } header: {
                Text("Largest items")
            }
        }
        .formStyle(.grouped)
        .onAppear { model.refresh() }
        .confirmationDialog(
            "Delete all \(kindToClear.map({ HistoryFilter.kind($0).title.lowercased() }) ?? "") from your history?",
            isPresented: Binding(get: { kindToClear != nil }, set: { if !$0 { kindToClear = nil } })
        ) {
            Button("Delete", role: .destructive) {
                if let kind = kindToClear { model.clear(kind) }
                kindToClear = nil
            }
        } message: {
            Text("Pinned items are kept. This can't be undone.")
        }
    }
}
