//
//  PasteboardMonitor.swift
//  Yippy
//
//  Created by Matthew Davidson on 17/9/19.
//  Copyright © 2019 MatthewDavidson. All rights reserved.
//

import Foundation
import Cocoa

class PasteboardMonitor {
    
    /// `NSPasteboard` has no change notification, so it must be polled. 0.25s is imperceptible for copy/paste, and the tolerance lets the system coalesce wake-ups to save energy.
    let intervalInSeconds: TimeInterval = 0.25
    
    private var timer: Timer!
    private var lastChangeCount: Int!
    
    var pasteboard: NSPasteboard!
    var delegate: PasteboardMonitorDelegate!
    
    private var frontmostApp: String? = nil
    
    init(pasteboard: NSPasteboard, changeCount: Int = -1, delegate: PasteboardMonitorDelegate) {
        self.pasteboard = pasteboard
        self.delegate = delegate
        self.lastChangeCount = changeCount
        self.frontmostApp = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        
        // Registers if any application becomes active (or comes frontmost) and calls a method if it's the case.
        // https://stackoverflow.com/a/49402868
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(activeApp(sender:)), name: NSWorkspace.didActivateApplicationNotification, object: nil)
        
        // TODO: Is it best to do a check straight away?
        self.checkIfPasteboardChanged()
        self.timer = Timer.scheduledTimer(withTimeInterval: intervalInSeconds, repeats: true) { (t) in
            self.checkIfPasteboardChanged()
        }
        self.timer.tolerance = 0.1
    }
    
    // Called by NSWorkspace when any application becomes active or comes frontmost.
    @objc private func activeApp(sender: NSNotification) {
        if let info = sender.userInfo,
            let content = info[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
            let bundle = content.bundleIdentifier
        {
            frontmostApp = bundle
        }
    }
    
    private func checkIfPasteboardChanged() {
        if lastChangeCount != pasteboard.changeCount  {
            lastChangeCount = self.pasteboard.changeCount
            delegate.pasteboardDidChange(pasteboard, originBundleId: frontmostApp)
        }
    }
}
