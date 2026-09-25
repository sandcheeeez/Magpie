//
//  XCUIApplication+StaticTexts.swift
//  MagpieUITests
//

import XCTest

extension XCUIApplication {
    
    var waitingForControlLabel: XCUIElement {
        return helpWindow.staticTexts[Accessibility.identifiers.waitingForControlLabel]
    }
    
    var howToUseLabel: XCUIElement {
        return helpWindow.staticTexts[Accessibility.identifiers.howToUseLabel]
    }
}
