//
//  XCUIApplication+Magpie.swift
//  MagpieUITests
//

import XCTest

extension XCUIApplication {
    
    var magpieTableView: XCUIElement {
        return magpieWindow.tables[Accessibility.identifiers.magpieTableView]
    }
    
    var magpieTableViewItems: XCUIElementQuery {
        return magpieTableView.cells
    }
    
    func getYippyTableViewCell(at i: Int) -> XCUIElement {
        return magpieTableViewItems.element(boundBy: i)
    }
    
    func getYippyTableViewCellTextView(at i: Int) -> XCUIElement {
        return getYippyTableViewCell(at: i).children(matching: .textView).matching(identifier: Accessibility.identifiers.magpieItemTextView).element
    }
    
    func getYippyTableViewItemString(at i: Int) -> String? {
        return getYippyTableViewCellTextView(at: i).value as? String
    }
    
    func getYippyTableViewCellType(at i: Int) -> String {
        return getYippyTableViewCell(at: i).label
    }
}
