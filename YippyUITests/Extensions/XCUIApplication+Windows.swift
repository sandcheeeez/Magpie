//
//  XCUIApplication+Windows.swift
//  MagpieUITests
//

import XCTest

extension XCUIApplication {
    
    var welcomeWindow: XCUIElement {
        return windows[Accessibility.identifiers.welcomeWindow]
    }
    
    var helpWindow: XCUIElement {
        return windows[Accessibility.identifiers.helpWindow]
    }
    
    var aboutWindow: XCUIElement {
        return windows[Accessibility.identifiers.aboutWindow]
    }
    
    var magpieWindow: XCUIElement {
        return windows[Accessibility.identifiers.magpieWindow]
    }
}
