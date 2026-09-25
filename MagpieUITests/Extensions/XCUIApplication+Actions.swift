//
//  XCUIApplication+Actions.swift
//  MagpieUITests
//

import XCTest

extension XCUIApplication {
    
    func quit() {
        statusItemButton.click()
        quitButton.click()
    }
    
    func pressHotKey() {
        typeKey("v", modifierFlags: .init(arrayLiteral: .command, .shift))
    }
    
    func typeKey(_ key: XCUIKeyboardKey) {
        typeKey(key, modifierFlags: .init())
    }
}
