//
//  MagpieStatusItem.swift
//  Magpie
//

import Foundation
import Cocoa

class MagpieStatusItem {
    
    /// The clipboard from the app icon in one colour (see icons/build.py). A template image, so macOS tints it for the menu bar.
    static var statusItemButtonImage: NSImage? = {
        let image = NSImage(named: "StatusIcon")
        image?.isTemplate = true
        image?.accessibilityDescription = "Stash"
        return image
    }()
    
    static func create() -> NSStatusItem {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem.button {
            button.image = statusItemButtonImage
            button.setAccessibilityIdentifier(Accessibility.identifiers.statusItemButton)
        }
        
        return statusItem
    }
}
