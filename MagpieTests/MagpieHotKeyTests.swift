//
//  MagpieHotKeyTests.swift
//  MagpieTests
//

import XCTest
import HotKey  // Normally this would be a @testable import, but this is not currently supported by the Swift Package Manager. See: https://stackoverflow.com/a/52672307
@testable import Magpie

class MagpieHotKeyTests: XCTestCase {
    
    var hotKey: HotKey!
    var magpieHotKey: MagpieHotKey!

    override func setUp() {
        hotKey = HotKey(key: .a, modifiers: .none)
        magpieHotKey = MagpieHotKey(hotKey: hotKey)
    }
    
    func testKeyUp() {
        // 1. Given a handler registered to the hot key
        let keyUpHandlerCalled = expectation(description: "keyUpHandlerCalled")
        let handler = {
            keyUpHandlerCalled.fulfill()
        }
        magpieHotKey.onUp(handler)
        
        // 2. When we have a key up event
        hotKey.simulateKeyUp()
        
        // 3. Then the handler should be called
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testKeyDown() {
        // 1. Given a handler registered to the hot key
        let keyDownHandlerCalled = expectation(description: "keyDownHandlerCalled")
        let handler = {
            keyDownHandlerCalled.fulfill()
        }
        magpieHotKey.onDown(handler)
        
        // 2. When we have a key down event
        hotKey.simulateKeyDown()
        
        // 3. Then the handler should be called
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testIsPaused() {
        // 1. Given a handler registered to the hot key
        let keyDownHandlerCalled = expectation(description: "keyDownHandlerCalled")
        keyDownHandlerCalled.isInverted = true
        let handler = {
            keyDownHandlerCalled.fulfill()
        }
        magpieHotKey.isPaused = true
        magpieHotKey.onDown(handler)
        
        // 2. When we have a key down event
        hotKey.simulateKeyDown()
        
        // 3. Then the handler should be called
        waitForExpectations(timeout: 0.5, handler: nil)
    }
    
    func testLongPress() {
        // 1. Given a handler registered to the hot key and the following long press settings
        let keyDownHandlerCalled = expectation(description: "keyDownHandlerCalled")
        keyDownHandlerCalled.expectedFulfillmentCount = 4
        let handler = {
            keyDownHandlerCalled.fulfill()
        }
        magpieHotKey.onLong(handler)
        magpieHotKey.longPressStartingInterval = 0.5
        magpieHotKey.longPressAcceleration = 2
        magpieHotKey.longPressMinInterval = 0.1
        
        // 2. When we have a long press event
        // Fires at 0.5, 0.75, 0.875 and 0.975s; the next would be at 1.075s.
        // Release midway between, so timer jitter under load can't change the count.
        hotKey.simulateKeyPress(for: 1.025)
        
        // 3. Then the handler should be called multiple times
        waitForExpectations(timeout: 2, handler: nil)
    }
}

// MARK: - Partial Hot Key Mock
// On partial mock is possible because the HotKey class is final.

extension HotKey {
    
    func simulateKeyDown() {
        if !isPaused {
            if let handler = keyDownHandler {
                handler()
            }
        }
    }
    
    func simulateKeyUp() {
        if !isPaused {
            if let handler = keyUpHandler {
                handler()
            }
        }
    }
    
    func simulateKeyPress() {
        simulateKeyDown()
        simulateKeyUp()
    }
    
    func simulateKeyPress(for interval: TimeInterval) {
        simulateKeyDown()
        Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            self.simulateKeyUp()
        }
    }
}
