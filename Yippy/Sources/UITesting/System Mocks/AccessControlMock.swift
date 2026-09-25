//
//  AccessControlMock.swift
//  Magpie
//

import Foundation
import Cocoa

struct AccessControlMock {
    
    static let pasteboard = NSPasteboard(name: NSPasteboard.Name(rawValue: "Magpie.UITesting.AccessControl"))
    
    static func setControlGranted(_ access: Bool) {
        pasteboard.declareTypes([.string], owner: nil)
        let str = access ? "true" : "false"
        pasteboard.setString(str, forType: .string)
    }
    
    static func isControlGranted() -> Bool {
        return pasteboard.string(forType: .string) == "true"
    }
}
