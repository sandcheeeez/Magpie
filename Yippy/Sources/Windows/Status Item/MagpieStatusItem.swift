//
//  MagpieStatusItem.swift
//  Magpie
//

import Foundation
import Cocoa

class MagpieStatusItem {
    
    static var statusItemButtonImage = NSImage(systemSymbolName: "bird", accessibilityDescription: "Magpie")
    
    static func create() -> NSStatusItem {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem.button {
            button.image = statusItemButtonImage
            button.setAccessibilityIdentifier(Accessibility.identifiers.statusItemButton)
        }
        
        return statusItem
    }
}
