//
//  XCUIElement+Properties.swift
//  MagpieUITests
//

import XCTest

extension XCUIElement {
    
    var isDisplayed: Bool {
        return exists && isHittable
    }
    
    /// Waits for the element to appear, allowing for the panel's slide-in animation.
    @discardableResult
    func waitUntilDisplayed(timeout: TimeInterval = 3) -> Bool {
        let predicate = NSPredicate(format: "exists == true AND hittable == true")
        return XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: self)], timeout: timeout) == .completed
    }
    
    /// Waits for the element to disappear, allowing for the panel's fade-out animation.
    @discardableResult
    func waitUntilHidden(timeout: TimeInterval = 3) -> Bool {
        let predicate = NSPredicate(format: "exists == false OR hittable == false")
        return XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: self)], timeout: timeout) == .completed
    }
}
