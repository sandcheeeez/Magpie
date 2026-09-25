//
//  NSMenuFunctionalTests.swift
//  MagpieTests
//

import XCTest
@testable import Magpie

class NSMenuFunctionalTests: XCTestCase {

    var menu: NSMenu!
    
    override func setUp() {
        menu = NSMenu(title: "TestMenu")
    }

    func testWithSingleItem() {
        // 1. Given a single item
        let item = NSMenuItem(title: "TestItem", action: nil, keyEquivalent: "")
        
        // 2. Then adding a single item
        menu = menu.with(menuItem: item)
        
        // 3. The menu then contains the single item
        XCTAssert(menu.items.contains(item))
        XCTAssertEqual(menu.items.count, 1)
    }
    
    func testWithMultipleItems() {
        // 1. Given multiple items
        let item1 = NSMenuItem(title: "Item 1", action: nil, keyEquivalent: "")
        let item2 = NSMenuItem(title: "Item 2", action: nil, keyEquivalent: "")
        let item3 = NSMenuItem(title: "Item 3", action: nil, keyEquivalent: "")
        
        // 2. Then adding the items
        menu = menu
            .with(menuItem: item1)
            .with(menuItem: item2)
            .with(menuItem: item3)
        
        // 3. The menu should contain the exact 3 items in the specified order
        XCTAssertEqual(menu.items, [item1, item2, item3])
    }
}
