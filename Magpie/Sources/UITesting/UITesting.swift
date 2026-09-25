//
//  UITesting.swift
//  Magpie
//

import Foundation
import AppKit

/// Sets up the app for UI tests: `--uitesting` mocks system access and resets settings and history; `--test-history=<name>` fills the history with a fixture.
///
/// Only the XCTest build (its own bundle id and data) honours this, so real history can never be wiped by a test.
struct UITesting {
    
    static var isTestBuild: Bool {
        return Bundle.main.bundleIdentifier?.hasSuffix("XCTest") == true
    }
    
    static func setupUITestEnvironment(launchArgs: [String]) {
        guard isTestBuild else {
            NSLog("Magpie: ignoring --uitesting outside the XCTest build")
            return
        }
        
        // Mock the access control and key pressing
        Helper.accessControlHelper = AccessControlHelperMock()
        Helper.keyPressHelper = KeyPressHelperMock()
        
        // Remove the settings and history
        _ = UserDefaults.standard.blank()
        try? FileManager.default.removeItem(at: Constants.urls.magpieAppSupport)
        
        if let test = launchArgs.first(where: { $0.hasPrefix("--Settings.testData=") }), let settings = Settings.testData.from(test) {
            Settings.main = settings
        }
        
        if let name = launchArgs.first(where: { $0.hasPrefix("--test-history=") })?.dropFirst("--test-history=".count) {
            seedHistory(fixture: String(name))
        }
    }
    
    /// Writes a fixture into the history store before the app loads it. Items are listed newest first.
    private static func seedHistory(fixture: String) {
        let items: [[NSPasteboard.PasteboardType: Data]]
        switch fixture {
        case "A":
            items = ["1", "2", "3", "4"].map({ [.string: Data($0.utf8)] })
        case "Types":
            let color = try! NSKeyedArchiver.archivedData(withRootObject: NSColor.systemBlue, requiringSecureCoding: false)
            let missingFile = URL(fileURLWithPath: "/tmp/magpie-ui-test-missing-file.xyz")
            let image = NSImage(size: NSSize(width: 40, height: 20), flipped: false) { rect in
                NSColor.systemPink.setFill()
                rect.fill()
                return true
            }
            items = [
                [.color: color],
                [.fileURL: missingFile.dataRepresentation],
                [.string: Data("func greet(name: String) -> String {\n    return \"Hello \\(name)\"\n}".utf8)],
                [.tiff: image.tiffRepresentation!],
            ]
        default:
            items = []
        }
        guard let container = try? HistoryStore.makeContainer() else { return }
        let history = History(container: container, persistsSettings: false)
        for data in items.reversed() {
            history.insert(data: data, sourceBundleId: nil)
        }
    }
}
