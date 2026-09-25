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
    
    func getMagpieTableViewCell(at i: Int) -> XCUIElement {
        return magpieTableViewItems.element(boundBy: i)
    }
    
    func getMagpieTableViewCellTextView(at i: Int) -> XCUIElement {
        return getMagpieTableViewCell(at: i).children(matching: .textView).matching(identifier: Accessibility.identifiers.magpieItemTextView).element
    }
    
    func getMagpieTableViewItemString(at i: Int) -> String? {
        return getMagpieTableViewCellTextView(at: i).value as? String
    }
    
    var searchField: XCUIElement {
        return magpieWindow.textFields[Accessibility.identifiers.searchField]
    }
    
    func filterChip(_ title: String) -> XCUIElement {
        return magpieWindow.buttons["filterChip.\(title)"]
    }
    
    func getMagpieTableViewCellType(at i: Int) -> String {
        return getMagpieTableViewCell(at: i).label
    }
}
