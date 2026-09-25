//
//  AppState.swift
//  Magpie
//

import Foundation
import Cocoa
import Observation

/// App-wide state. Views observe it with `observe(_:onChange:)` or SwiftUI; settings changes are saved as they happen.
@Observable
class AppState {
    
    // MARK: - Singleton
    static let main = AppState()
    
    
    // MARK: - Attributes
    
    var isHistoryPanelShown = false
    
    var panelPosition: PanelPosition {
        didSet { Settings.main.panelPosition = panelPosition }
    }
    
    /// The screen the panel is shown on, updated just before it is shown.
    var currentScreen: NSScreen
    
    var previewHistoryItem: HistoryItem?
    
    private(set) var launchAtLogin: Bool
    
    var showsRichText: Bool {
        didSet { Settings.main.showsRichText = showsRichText }
    }
    
    var pastesRichText: Bool {
        didSet {
            Settings.main.pastesRichText = pastesRichText
            HistoryItem.pastesRichText = pastesRichText
        }
    }
    
    /// Copies made while one of these apps is frontmost are not saved.
    var excludedBundleIds: [String] {
        didSet {
            Settings.main.excludedBundleIds = excludedBundleIds
            history.excludedBundleIds = Set(excludedBundleIds)
        }
    }
    
    /// The most unpinned items the history keeps.
    var maxHistory: Int {
        didSet { history.setMaxItems(maxHistory) }
    }
    
    // History
    @ObservationIgnored var history: History!
    
    /// Monitors the pasteboard, here it can be controlled in the future if needed.
    @ObservationIgnored var pasteboardMonitor: PasteboardMonitor!
    
    
    // MARK: - Constructor
    init(settings: Settings = Settings.main) {
        panelPosition = settings.panelPosition
        currentScreen = Self.getCurrentScreen(forMouseLocation: NSEvent.mouseLocation)
        launchAtLogin = LoginItem.isEnabled
        showsRichText = settings.showsRichText
        pastesRichText = settings.pastesRichText
        excludedBundleIds = settings.excludedBundleIds
        maxHistory = settings.maxHistory
        HistoryItem.pastesRichText = settings.pastesRichText
        
        // Setup history
        history = History.load()
        history.recordPasteboardChange(withCount: settings.pasteboardChangeCount)
        history.setMaxItems(settings.maxHistory)
        history.excludedBundleIds = Set(settings.excludedBundleIds)
        
        // Setup pasteboard monitor
        pasteboardMonitor = PasteboardMonitor(pasteboard: NSPasteboard.general, changeCount: settings.pasteboardChangeCount, delegate: history)
        
        history.recognizeTextInExistingImages()
    }
    
    
    // MARK: - Methods
    
    func setLaunchAtLogin(_ enabled: Bool) {
        LoginItem.setEnabled(enabled)
        launchAtLogin = LoginItem.isEnabled
    }
    
    /// Moves the panel to the screen containing the mouse. Called just before the panel is shown, rather than polling the mouse position.
    func updateCurrentScreen() {
        let screen = Self.getCurrentScreen(forMouseLocation: NSEvent.mouseLocation)
        if screen != currentScreen {
            currentScreen = screen
        }
    }
    
    static func getCurrentScreen(forMouseLocation location: NSPoint) -> NSScreen {
        for screen in NSScreen.screens {
            if screen.frame.contains(location) {
                return screen
            }
        }
        return NSScreen.main!
    }
}
