//
//  MagpieUITests.swift
//  MagpieUITests
//

import XCTest
import HotKey

/// End-to-end tests of the history panel. They run the XCTest build, which has its own settings and history, so real data is never touched.
///
/// Note: like any copy, these tests change the system clipboard.
class MagpieUITests: XCTestCase {

    var app: XCUIApplication!
    
    override func setUp() {
        continueAfterFailure = false
        
        // Pretend Accessibility access is granted, and capture simulated key presses instead of sending them.
        AccessControlMock.setControlGranted(true)
        
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
    }
    
    override func tearDown() {
        app.terminate()
    }
    
    /// Copies text the way apps do, then launches with the given history fixture ("A" is the items 1, 2, 3, 4).
    func launch(copying text: String? = "My latest copy", history fixture: String? = nil) {
        if let text = text {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
        }
        else {
            NSPasteboard.general.clearContents()
        }
        if let fixture = fixture {
            app.launchArguments.append("--test-history=\(fixture)")
        }
        app.launch()
    }
    
    func openPanel() {
        app.pressHotKey()
        XCTAssertTrue(app.magpieWindow.waitUntilDisplayed())
    }
    
    func assertCmdV() {
        let keyPress = KeyPressMock.handleKeyPress()
        // Assert there was a key press
        XCTAssertNotNil(keyPress)
        // Assert it was a c + cmd key press
        let (keyCode, flags) = keyPress!
        XCTAssertEqual(keyCode, KeyPressMock.constants.cKeyCode)
        XCTAssertEqual(flags, KeyPressMock.constants.enterEventFlags)
        // Assert there was just a single key press
        XCTAssertNil(KeyPressMock.handleKeyPress())
    }
    
    func strings() -> [String?] {
        return (0..<app.magpieTableViewItems.count).map({ app.getMagpieTableViewItemString(at: $0) })
    }
    
    // MARK: - Showing the panel
    
    func testToggleFromMenu() {
        launch()
        XCTAssertFalse(app.magpieWindow.isDisplayed)
        
        app.statusItemButton.click()
        app.toggleMagpieWindowButton.click()
        XCTAssertTrue(app.magpieWindow.waitUntilDisplayed())
        
        app.statusItemButton.click()
        app.toggleMagpieWindowButton.click()
        XCTAssertTrue(app.magpieWindow.waitUntilHidden())
    }
    
    func testHotKeyToggle() {
        launch()
        XCTAssertFalse(app.magpieWindow.isDisplayed)
        
        openPanel()
        app.pressHotKey()
        XCTAssertTrue(app.magpieWindow.waitUntilHidden())
        
        openPanel()
        app.typeKey(.escape)
        XCTAssertTrue(app.magpieWindow.waitUntilHidden())
    }
    
    func testWindowPositions() {
        launch()
        openPanel()
        
        // XCUITest frames have their origin at the top left of the main screen; AppKit's is at the bottom left.
        let screen = NSScreen.screens[0]
        func expected(_ position: PanelPosition) -> CGRect {
            let frame = position.getFrame(forScreen: screen)
            return CGRect(x: frame.minX, y: screen.frame.height - frame.maxY, width: frame.width, height: frame.height)
        }
        func move(to position: PanelPosition, button: XCUIElement) {
            app.statusItemButton.click()
            app.positionButton.click()
            button.click()
            // Allow for the frame change.
            _ = XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "frame == %@", NSValue(rect: expected(position))), object: app.magpieWindow)], timeout: 2)
            XCTAssertEqual(app.magpieWindow.frame.midX, expected(position).midX, accuracy: 1)
            XCTAssertEqual(app.magpieWindow.frame.midY, expected(position).midY, accuracy: 1)
        }
        
        XCTAssertEqual(app.magpieWindow.frame.midX, expected(.right).midX, accuracy: 1)
        move(to: .left, button: app.positionLeftButton)
        move(to: .bottom, button: app.positionBottomButton)
        move(to: .top, button: app.positionTopButton)
        move(to: .right, button: app.positionRightButton)
    }
    
    // MARK: - History
    
    func testEmptyHistory() {
        launch(copying: nil)
        openPanel()
        XCTAssertEqual(app.magpieTableViewItems.count, 0)
        app.pressHotKey()
        XCTAssertTrue(app.magpieWindow.waitUntilHidden())
        
        // Copy something while Magpie is running.
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString("My first test!", forType: .string)
        // Magpie checks the clipboard four times a second.
        Thread.sleep(forTimeInterval: 0.6)
        
        openPanel()
        XCTAssertEqual(app.magpieTableViewItems.count, 1)
        XCTAssertEqual(app.getMagpieTableViewItemString(at: 0), "My first test!")
    }
    
    func testLoadsHistoryAndLatestCopy() {
        app.launchArguments.append("--Settings.testData=a")
        launch(history: "A")
        openPanel()
        XCTAssertEqual(strings(), ["My latest copy", "1", "2", "3", "4"])
    }
    
    func testEnterToPaste() {
        launch(history: "A")
        openPanel()
        app.typeKey(.return)
        
        assertCmdV()
        XCTAssertTrue(app.magpieWindow.waitUntilHidden())
    }
    
    func testPasteFromHistory() {
        launch(history: "A")
        openPanel()
        app.getMagpieTableViewCell(at: 2).click()
        app.typeKey(.return)
        
        assertCmdV()
        XCTAssertTrue(app.magpieWindow.waitUntilHidden())
        XCTAssertEqual(NSPasteboard.general.string(forType: .string), "2")
        
        // The pasted item moves to the top.
        openPanel()
        XCTAssertEqual(Array(strings().prefix(3)), ["2", "My latest copy", "1"])
    }
    
    func testPasteFromShortcut() {
        launch(history: "A")
        openPanel()
        app.typeKey("2", modifierFlags: .command)
        
        assertCmdV()
        XCTAssertTrue(app.magpieWindow.waitUntilHidden())
        XCTAssertEqual(NSPasteboard.general.string(forType: .string), "2")
        
        openPanel()
        XCTAssertEqual(Array(strings().prefix(3)), ["2", "My latest copy", "1"])
    }
    
    func testDelete() {
        launch(history: "A")
        openPanel()
        app.getMagpieTableViewCell(at: 2).click()
        app.typeKey(.delete, modifierFlags: .control)
        XCTAssertEqual(strings(), ["My latest copy", "1", "3", "4"])
        
        app.typeKey(.delete, modifierFlags: .control)
        app.typeKey(.delete, modifierFlags: .control)
        XCTAssertEqual(strings(), ["My latest copy", "1"])
        
        app.getMagpieTableViewCell(at: 0).click()
        app.typeKey(.delete, modifierFlags: .control)
        XCTAssertEqual(strings(), ["1"])
        
        app.typeKey(.delete, modifierFlags: .control)
        XCTAssertEqual(app.magpieTableViewItems.count, 0)
        
        // Deleting the current clipboard item clears the clipboard.
        XCTAssertTrue(NSPasteboard.general.types?.isEmpty ?? true)
    }
    
    func testCellTypes() {
        launch(history: "Types")
        openPanel()
        XCTAssertEqual(app.getMagpieTableViewCellType(at: 0), Accessibility.identifiers.magpieTextCellView)
        XCTAssertEqual(app.getMagpieTableViewCellType(at: 1), Accessibility.identifiers.magpieColorCellView)
        XCTAssertEqual(app.getMagpieTableViewCellType(at: 2), Accessibility.identifiers.magpieFileIconCellView)
        XCTAssertEqual(app.getMagpieTableViewCellType(at: 3), Accessibility.identifiers.magpieTextCellView)
        XCTAssertEqual(app.getMagpieTableViewCellType(at: 4), Accessibility.identifiers.magpieTiffCellView)
    }
    
    // MARK: - Search, filters and pins
    
    func testSearch() {
        launch(history: "A")
        openPanel()
        app.typeKey("\\", modifierFlags: .command)
        app.searchField.typeText("latest")
        XCTAssertEqual(strings(), ["My latest copy"])
        
        // Deleting a search result deletes that item, not the one at the same position in the full history.
        app.typeKey(.delete, modifierFlags: .control)
        app.searchField.doubleClick()
        app.searchField.typeKey(.delete, modifierFlags: [])
        XCTAssertEqual(strings(), ["1", "2", "3", "4"])
    }
    
    func testFilterChips() {
        launch(history: "Types")
        openPanel()
        XCTAssertEqual(app.magpieTableViewItems.count, 5)
        
        app.filterChip("Code").click()
        XCTAssertEqual(app.magpieTableViewItems.count, 1)
        
        app.filterChip("Colors").click()
        XCTAssertEqual(app.magpieTableViewItems.count, 1)
        
        app.typeKey(.rightArrow, modifierFlags: .command)
        app.typeKey(.rightArrow, modifierFlags: .command)
        // Wrapped round from Colors to All, then on to Pinned.
        XCTAssertEqual(app.magpieTableViewItems.count, 0)
        
        app.filterChip("All").click()
        XCTAssertEqual(app.magpieTableViewItems.count, 5)
    }
    
    func testPinning() {
        launch(history: "A")
        openPanel()
        app.getMagpieTableViewCell(at: 3).click()
        app.typeKey("p", modifierFlags: .command)
        
        app.filterChip("Pinned").click()
        XCTAssertEqual(strings(), ["3"])
        
        // Pinned items survive clearing the history.
        app.typeKey(.escape)
        XCTAssertTrue(app.magpieWindow.waitUntilHidden())
        app.statusItemButton.click()
        app.menuItems["Clear history"].click()
        openPanel()
        app.filterChip("All").click()
        XCTAssertEqual(strings(), ["3"])
    }
}
