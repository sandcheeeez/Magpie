//
//  XCUIElement+Properties.swift
//  MagpieUITests
//

import XCTest

extension XCUIElement {
    
    var isDisplayed: Bool {
        return exists && isHittable
    }
}
