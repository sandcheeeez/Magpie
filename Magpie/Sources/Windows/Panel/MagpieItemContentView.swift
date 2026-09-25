//
//  MagpieItemContentView.swift
//  Magpie
//

import Foundation
import Cocoa

/// A basic `NSView` subclass that handles updates of the system appearance (e.g. dark/light modes) and updates its `layer`'s background and border colors.
class MagpieItemContentView: NSView {
    
    var usesDynamicBackgroundColor = true
    
    override func updateLayer() {
        super.updateLayer()
        
        // The card behind draws the background; only content with its own colour (e.g. colour swatches) fills this view.
        if usesDynamicBackgroundColor {
            layer?.backgroundColor = NSColor.clear.cgColor
        }
    }
}
