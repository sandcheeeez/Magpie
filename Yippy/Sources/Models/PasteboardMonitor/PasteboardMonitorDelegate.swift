//
//  PasteboardMonitorDelegate.swift
//  Magpie
//

import Foundation
import Cocoa

protocol PasteboardMonitorDelegate {
    
    /**
     Called when the pasteboard changes.
     
     - Parameter pasteboard: The pasteboard that changed.
     */
    func pasteboardDidChange(_ pasteboard: NSPasteboard, originBundleId: String?)
}
