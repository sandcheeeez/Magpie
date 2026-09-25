//
//  Settings.swift
//  Yippy
//
//  Created by Matthew Davidson on 6/8/19.
//  Copyright © 2019 MatthewDavidson. All rights reserved.
//

import Foundation
import Default
import RxSwift
import RxRelay
import HotKey

struct Settings: Codable, DefaultStorable {
    
    // MARK: - Singleton
    
    private init(
        panelPosition: PanelPosition,
        pasteboardChangeCount: Int,
        toggleHotKey: KeyCombo,
        maxHistory: Int,
        showsRichText: Bool,
        pastesRichText: Bool
    ) {
        self.panelPosition = panelPosition
        self.pasteboardChangeCount = pasteboardChangeCount
        self.toggleHotKey = toggleHotKey
        self.maxHistory = maxHistory
        self.showsRichText = showsRichText
        self.pastesRichText = pastesRichText
    }
    
    static var main: Settings! {
        get {
            let settings = Settings.read(forKey: "settings")
            if settings != nil {
                return settings
            }
            return Settings.default
        }
        set (main) {
            main.write(withKey: "settings")
        }
    }
    
    // MARK: - Default
    
    static let `default` = Settings(
        panelPosition: .right,
        pasteboardChangeCount: -1,
        toggleHotKey: KeyCombo(key: .v, modifiers: [.command, .shift]),
        maxHistory: Constants.settings.maxHistoryItemsDefault,
        showsRichText: true,
        pastesRichText: true
    )
    
    /// Password managers are excluded by default. Most mark their copies as concealed anyway, but not all do.
    static let defaultExcludedBundleIds = [
        "com.apple.Passwords",
        "com.apple.keychainaccess",
        "com.1password.1password",
        "com.agilebits.onepassword7",
        "com.bitwarden.desktop",
        "org.keepassxc.keepassxc",
        "com.lastpass.LastPass",
        "com.dashlane.dashlanephonefinal",
    ]
    
    // MARK: - Settings
    
    var panelPosition: PanelPosition
    
    var pasteboardChangeCount: Int
    
    var toggleHotKey: KeyCombo
    
    var maxHistory: Int
    
    var showsRichText: Bool
    
    var pastesRichText: Bool
    
    /// Bundle ids of apps whose copies are never saved to the history.
    var excludedBundleIds = Settings.defaultExcludedBundleIds
    
    
    // MARK: - Decoding
    
    /// Decodes settings, using defaults for any settings missing from older saved versions.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Settings.default
        panelPosition = try container.decodeIfPresent(PanelPosition.self, forKey: .panelPosition) ?? defaults.panelPosition
        pasteboardChangeCount = try container.decodeIfPresent(Int.self, forKey: .pasteboardChangeCount) ?? defaults.pasteboardChangeCount
        toggleHotKey = try container.decodeIfPresent(KeyCombo.self, forKey: .toggleHotKey) ?? defaults.toggleHotKey
        maxHistory = try container.decodeIfPresent(Int.self, forKey: .maxHistory) ?? defaults.maxHistory
        showsRichText = try container.decodeIfPresent(Bool.self, forKey: .showsRichText) ?? defaults.showsRichText
        pastesRichText = try container.decodeIfPresent(Bool.self, forKey: .pastesRichText) ?? defaults.pastesRichText
        excludedBundleIds = try container.decodeIfPresent([String].self, forKey: .excludedBundleIds) ?? defaults.excludedBundleIds
    }
    
    
    // MARK: - State Binding Methods
    
    func bindPanelPositionTo(state: BehaviorRelay<PanelPosition>) -> Disposable {
        return state.bind { (x) in
            Settings.main.panelPosition = x
        }
    }
    
    func bindPasteboardChangeCountTo(state: Observable<Int>) -> Disposable {
        return state.bind { (x) in
            Settings.main.pasteboardChangeCount = x
        }
    }
    
    func bindMaxHistoryTo(state: Observable<Int>) -> Disposable {
        return state.bind { (x) in
            Settings.main.maxHistory = x
        }
    }
    
    func bindShowsRichTextTo(state: Observable<Bool>) -> Disposable {
        return state.bind { (x) in
            Settings.main.showsRichText = x
        }
    }
    
    func bindPastesRichTextTo(state: Observable<Bool>) -> Disposable {
        return state.bind { (x) in
            Settings.main.pastesRichText = x
        }
    }
    
    func bindExcludedBundleIdsTo(state: Observable<[String]>) -> Disposable {
        return state.bind { (x) in
            Settings.main.excludedBundleIds = x
        }
    }
}

extension Settings {
    
    struct testData {
        static var a: Settings {
            var settings = Settings.default
            settings.panelPosition = .left
            return settings
        }
        
        static func from(_ str: String) -> Settings? {
            switch str {
            case "--Settings.testData=a":
                return a
            default:
                return nil
            }
        }
    }
}

extension Settings: Equatable {
    
}
