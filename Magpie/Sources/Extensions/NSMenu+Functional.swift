//
//  NSMenu+Functional.swift
//  Magpie
//

import Cocoa

extension NSMenu {
    
    func with(menuItem: NSMenuItem) -> NSMenu {
        self.addItem(menuItem)
        return self
    }
}
