//
//  SettingsWindowController.swift
//  Magpie
//

import Foundation
import AppKit
import SwiftUI

class SettingsWindowController: NSWindowController {
    
    static func createSettingsWindowController() -> SettingsWindowController {
        let model = SettingsModel()
        let tabs = NSTabViewController()
        tabs.tabStyle = .toolbar
        tabs.addTabViewItem(tab("General", symbol: "gearshape", view: GeneralSettingsView(model: model)))
        tabs.addTabViewItem(tab("Shortcuts", symbol: "command", view: ShortcutsSettingsView(model: model)))
        tabs.addTabViewItem(tab("Privacy", symbol: "hand.raised", view: PrivacySettingsView(model: model)))
        tabs.addTabViewItem(tab("Storage", symbol: "internaldrive", view: StorageSettingsView()))
        
        let window = NSWindow(contentViewController: tabs)
        window.styleMask = [.titled, .closable]
        window.toolbarStyle = .preference
        window.isReleasedWhenClosed = false
        return SettingsWindowController(window: window)
    }
    
    private static func tab<V: View>(_ label: String, symbol: String, view: V) -> NSTabViewItem {
        let controller = NSHostingController(rootView: view.frame(width: 500, height: 440))
        controller.title = label
        let item = NSTabViewItem(viewController: controller)
        item.label = label
        item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: label)
        return item
    }
}
