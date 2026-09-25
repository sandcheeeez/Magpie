//
//  SettingsView.swift
//  Yippy
//

import SwiftUI
import AppKit
import RxSwift
import HotKey
import UniformTypeIdentifiers

/// Bridges the app's Rx state to SwiftUI for the settings window.
@Observable
final class SettingsModel {

    var launchAtLogin: Bool {
        didSet {
            guard launchAtLogin != State.main.launchAtLogin.value else { return }
            LoginItem.setEnabled(launchAtLogin)
            State.main.launchAtLogin.accept(LoginItem.isEnabled)
        }
    }

    var panelPosition: PanelPosition {
        didSet { if panelPosition != State.main.panelPosition.value { State.main.panelPosition.accept(panelPosition) } }
    }

    var maxHistory: Int {
        didSet { State.main.history.setMaxItems(maxHistory) }
    }

    var showsRichText: Bool {
        didSet { if showsRichText != State.main.showsRichText.value { State.main.showsRichText.accept(showsRichText) } }
    }

    var pastesRichText: Bool {
        didSet { if pastesRichText != State.main.pastesRichText.value { State.main.pastesRichText.accept(pastesRichText) } }
    }

    var excludedBundleIds: [String] {
        didSet { if excludedBundleIds != State.main.excludedBundleIds.value { State.main.excludedBundleIds.accept(excludedBundleIds) } }
    }

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
    @ObservationIgnored private let disposeBag = DisposeBag()

    init() {
        let state = State.main
        launchAtLogin = LoginItem.isEnabled
        panelPosition = state.panelPosition.value
        maxHistory = Settings.main.maxHistory
        showsRichText = state.showsRichText.value
        pastesRichText = state.pastesRichText.value
        excludedBundleIds = state.excludedBundleIds.value
        toggleHotKey = Settings.main.toggleHotKey

        // Keep in sync with changes made from the status menu.
        state.panelPosition.subscribe(onNext: { [weak self] in self?.panelPosition = $0 }).disposed(by: disposeBag)
        state.launchAtLogin.subscribe(onNext: { [weak self] in self?.launchAtLogin = $0 }).disposed(by: disposeBag)

        keyPressMonitor.isPaused = true
        keyPressMonitor.subscribeToKeyDown { [weak self] keys, modifiers in
            guard let self = self, self.isRecording else { return }
            self.recordedHotKey = Self.makeHotKey(keys: keys, modifiers: modifiers)
        }
    }

    func saveRecordedHotKey() {
        guard let hotKey = recordedHotKey else { return }
        YippyHotKeys.toggle.changeHotKey(keyCombo: hotKey)
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
        let ids = panel.urls.compactMap({ Bundle(url: $0)?.bundleIdentifier }).filter({ !excludedBundleIds.contains($0) })
        excludedBundleIds.append(contentsOf: ids)
    }
}

struct GeneralSettingsView: View {

    @Bindable var model: SettingsModel

    var body: some View {
        Form {
            Section {
                Toggle("Open Yippy when you log in", isOn: $model.launchAtLogin)
            }
            Section("Panel") {
                Picker("Position", selection: $model.panelPosition) {
                    ForEach([PanelPosition.right, .left, .top, .bottom], id: \.self) { Text($0.title).tag($0) }
                    Divider()
                    ForEach([PanelPosition.centerExtraSmall, .centerSmall, .centerMedium, .centerLarge, .fullScreen], id: \.self) { Text($0.title).tag($0) }
                }
            }
            Section {
                Picker("Keep up to", selection: $model.maxHistory) {
                    ForEach(Constants.settings.maxHistoryItemsOptions, id: \.self) { Text("\($0) items").tag($0) }
                }
            } header: {
                Text("History")
            } footer: {
                Text("Pinned items are kept in addition to this limit.")
                    .foregroundStyle(.secondary)
            }
            Section("Formatting") {
                Toggle("Show formatting in the history", isOn: $model.showsRichText)
                Toggle("Paste with formatting", isOn: $model.pastesRichText)
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
            Section("Show Yippy") {
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
                    ForEach(model.excludedBundleIds, id: \.self) { bundleId in
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
                        model.excludedBundleIds.removeAll(where: { selection.contains($0) })
                        selection.removeAll()
                    }
                    .disabled(selection.isEmpty)
                    Spacer()
                    Button("Restore Defaults") { model.excludedBundleIds = Settings.defaultExcludedBundleIds }
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
