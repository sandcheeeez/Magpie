//
//  NSMenuItem+Functional.swift
//  Magpie
//

import Cocoa

extension NSMenuItem {
    
    @discardableResult
    func with(submenu: NSMenu) -> NSMenuItem {
        self.submenu = submenu
        return self
    }
    
    func with(state: NSControl.StateValue) -> NSMenuItem {
        self.state = state
        return self
    }
    
    func with(tag: Int) -> NSMenuItem {
        self.tag = tag
        return self
    }
    
    func with(accessibilityIdentifier: String) -> NSMenuItem {
        self.setAccessibilityIdentifier(accessibilityIdentifier)
        return self
    }
    
    func with(isEnabled: Bool) -> NSMenuItem {
        self.isEnabled = isEnabled
        return self
    }
}
