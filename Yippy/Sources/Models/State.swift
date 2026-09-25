//
//  State.swift
//  Yippy
//
//  Created by Matthew Davidson on 7/8/19.
//  Copyright © 2019 MatthewDavidson. All rights reserved.
//

import Foundation
import Cocoa
import RxRelay
import RxSwift

class State {
    
    // MARK: - Singleton
    static var main = State()
    
    
    // MARK: - Attributes
    // RxSwift
    var isHistoryPanelShown: BehaviorRelay<Bool>
    
    var panelPosition: BehaviorRelay<PanelPosition>
    
    var currentScreen: BehaviorRelay<NSScreen>
    
    var previewHistoryItem: BehaviorRelay<HistoryItem?>
    
    var launchAtLogin: BehaviorRelay<Bool>
    
    var showsRichText: BehaviorRelay<Bool>
    
    var pastesRichText: BehaviorRelay<Bool>
    
    var excludedBundleIds: BehaviorRelay<[String]>
    
    var disposeBag: DisposeBag
    
    // History
    var historyCache: HistoryCache!
    var history: History!
    
    /// Monitors the pasteboard, here it can be controlled in the future if needed.
    var pasteboardMonitor: PasteboardMonitor!
    
    
    // MARK: - Constructor
    init(settings: Settings = Settings.main, disposeBag: DisposeBag = DisposeBag()) {
        // Setup RxSwift attributes
        self.isHistoryPanelShown = BehaviorRelay<Bool>(value: false)
        self.panelPosition = BehaviorRelay<PanelPosition>(value: settings.panelPosition)
        self.previewHistoryItem = BehaviorRelay<HistoryItem?>(value: nil)
        self.launchAtLogin = BehaviorRelay<Bool>(value: LoginItem.isEnabled)
        self.showsRichText = BehaviorRelay<Bool>(value: settings.showsRichText)
        self.pastesRichText = BehaviorRelay<Bool>(value: settings.pastesRichText)
        self.excludedBundleIds = BehaviorRelay<[String]>(value: settings.excludedBundleIds)
        self.currentScreen = BehaviorRelay<NSScreen>(value: Self.getCurrentScreen(forMouseLocation: NSEvent.mouseLocation))
        self.disposeBag = disposeBag
        
        // Setup history
        self.historyCache = HistoryCache()
        self.history = History.load(cache: historyCache)
        self.history.recordPasteboardChange(withCount: settings.pasteboardChangeCount)
        self.history.setMaxItems(settings.maxHistory)
        
        // Bind settings to state
        Self.bind(settings: settings, toState: self, disposeBag: disposeBag)
        
        // Setup pasteboard monitor
        self.pasteboardMonitor = PasteboardMonitor(pasteboard: NSPasteboard.general, changeCount: settings.pasteboardChangeCount, delegate: self.history)
        
        Self.monitorPastesRichText(state: self)
        
        self.excludedBundleIds.subscribe(onNext: { [history] in
            history?.excludedBundleIds = Set($0)
        }).disposed(by: disposeBag)
        
        self.history.recognizeTextInExistingImages()
    }
    
    // MARK: - Constructor Helpers
    
    static func bind(settings: Settings, toState state: State, disposeBag: DisposeBag) {
        settings.bindPasteboardChangeCountTo(state: state.history!.observableLastRecordedChangeCount).disposed(by: disposeBag)
        settings.bindPanelPositionTo(state: state.panelPosition).disposed(by: disposeBag)
        settings.bindMaxHistoryTo(state: state.history.maxItems).disposed(by: disposeBag)
        settings.bindShowsRichTextTo(state: state.showsRichText.asObservable()).disposed(by: disposeBag)
        settings.bindPastesRichTextTo(state: state.pastesRichText.asObservable()).disposed(by: disposeBag)
        settings.bindExcludedBundleIdsTo(state: state.excludedBundleIds.asObservable()).disposed(by: disposeBag)
    }
    
    static func monitorPastesRichText(state: State) {
        state.pastesRichText.distinctUntilChanged().subscribe(onNext: {
            HistoryItem.pastesRichText = $0
        }).disposed(by: state.disposeBag)
    }
    
    /// Moves the panel to the screen containing the mouse. Called just before the panel is shown, rather than polling the mouse position.
    func updateCurrentScreen() {
        let screen = Self.getCurrentScreen(forMouseLocation: NSEvent.mouseLocation)
        if screen != currentScreen.value {
            currentScreen.accept(screen)
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
