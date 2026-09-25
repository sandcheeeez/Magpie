//
//  SettingsTests.swift
//  MagpieTests
//

import Testing
import Foundation
@testable import Magpie

@Suite struct SettingsTests {
    
    @Test func roundTrips() throws {
        var settings = Settings.default
        settings.panelPosition = .left
        settings.maxHistory = 200
        settings.excludedBundleIds = ["com.example.app"]
        let decoded = try JSONDecoder().decode(Settings.self, from: JSONEncoder().encode(settings))
        #expect(decoded == settings)
    }
    
    @Test func olderSavedSettingsGetDefaultsForNewFields() throws {
        // Saved before excluded apps existed.
        let json = #"{"panelPosition":1,"pasteboardChangeCount":7,"maxHistory":100,"showsRichText":false,"pastesRichText":true}"#
        let decoded = try JSONDecoder().decode(Settings.self, from: Data(json.utf8))
        #expect(decoded.panelPosition == .left)
        #expect(decoded.maxHistory == 100)
        #expect(decoded.showsRichText == false)
        #expect(decoded.toggleHotKey == Settings.default.toggleHotKey)
        #expect(decoded.excludedBundleIds == Settings.defaultExcludedBundleIds)
    }
}
