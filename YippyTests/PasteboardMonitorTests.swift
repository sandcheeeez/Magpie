//
//  PasteboardMonitorTests.swift
//  MagpieTests
//

import XCTest
@testable import Magpie

class PasteboardMonitorTests: XCTestCase {
    
    func testPasteboardDidChangeCalled() {
        // 1. Given a monitor that has seen the pasteboard's current contents
        let pasteboard = NSPasteboard(name: NSPasteboard.Name(rawValue: "MagpieTests.PasteboardMonitor"))
        pasteboard.clearContents()
        let expectation = self.expectation(description: "pasteboardDidChangeCalled")
        expectation.assertForOverFulfill = false
        let delegate = PasteboardMonitorDelegateMock(expectation: expectation)
        let monitor = PasteboardMonitor(pasteboard: pasteboard, changeCount: pasteboard.changeCount, delegate: delegate)
        
        // 2. Copy something, the way apps do (only clearing the pasteboard increments its change count)
        pasteboard.clearContents()
        pasteboard.setString("test", forType: .string)
        
        // 3. Assert delegate function called
        waitForExpectations(timeout: 2, handler: nil)
        withExtendedLifetime(monitor) {}
    }
}

class PasteboardMonitorDelegateMock: PasteboardMonitorDelegate {
    
    var expectation: XCTestExpectation
    
    init(expectation: XCTestExpectation) {
        self.expectation = expectation
    }
    
    func pasteboardDidChange(_ pasteboard: NSPasteboard, originBundleId: String?) {
        expectation.fulfill()
    }
}
