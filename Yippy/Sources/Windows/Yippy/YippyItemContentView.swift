//
//  YippyItemContentView.swift
//  Yippy
//
//  Created by Matthew Davidson on 13/10/19.
//  Copyright © 2019 MatthewDavidson. All rights reserved.
//

import Foundation
import Cocoa

/// A basic `NSView` subclass that handles updates of the system appearance (e.g. dark/light modes) and updates its `layer`'s background and border colors.
class YippyItemContentView: NSView {
    
    var usesDynamicBackgroundColor = true
    
    override func updateLayer() {
        super.updateLayer()
        
        // The card behind draws the background; only content with its own colour (e.g. colour swatches) fills this view.
        if usesDynamicBackgroundColor {
            layer?.backgroundColor = NSColor.clear.cgColor
        }
    }
}
