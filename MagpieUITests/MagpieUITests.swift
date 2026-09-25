//
//  MagpieUITests.swift
//  MagpieUITests
//

import XCTest
import HotKey

class MagpieUITests: XCTestCase {

    var app: XCUIApplication!
    
    override func setUp() {
        // Nothing to clean up after a failure
        continueAfterFailure = false
        
        // Set full access control
        AccessControlMock.setControlGranted(true)
        
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launchEnvironment["SRCROOT"] = ProcessInfo.processInfo.environment["SRCROOT"]
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
    
    func testYippyToggle() {
        // Launch app
        app.launch()
        
        // Check window isn't displayed
        XCTAssertFalse(app.magpieWindow.exists)
        
        // Toggle window
        app.statusItemButton.click()
        app.toggleYippyWindowButton.click()
        
        // Check window is displayed
        XCTAssertTrue(app.magpieWindow.exists)
        
        // Toggle window
        app.statusItemButton.click()
        app.toggleYippyWindowButton.click()
        
        // Check window isn't displayed
        XCTAssertFalse(app.magpieWindow.exists)
    }
    
    func testHotKeyToggle() {
        // Launch app
        app.launch()
        
        // Check window isn't displayed
        XCTAssertFalse(app.magpieWindow.isDisplayed)
        
        // HotKey toggle
        app.pressHotKey()
        
        // Check window is displayed
        XCTAssertTrue(app.magpieWindow.isDisplayed)
        
        // HotKey toggle
        app.pressHotKey()
        
        // Check window isn't displayed
        XCTAssertFalse(app.magpieWindow.isDisplayed)
        
        // HotKey toggle
        app.pressHotKey()
        
        // Check window is displayed
        XCTAssertTrue(app.magpieWindow.isDisplayed)
        
        // Type escape
        app.typeKey(XCUIKeyboardKey.escape)
        
        // Check window isn't displayed
        XCTAssertFalse(app.magpieWindow.isDisplayed)
    }
    
    func testYippyWindowPositions() {
        // Launch app
        app.launch()
        
        // Check window isn't displayed
        XCTAssertFalse(app.magpieWindow.exists)
        
        // HotKey toggle
        app.pressHotKey()
        
        // Check window is displayed
        XCTAssertTrue(app.magpieWindow.exists)
        
        // Check window location is .right
        XCTAssertEqual(app.magpieWindow.frame.midX, PanelPosition.right.getFrame(forScreen: NSScreen.main!).midX)
        
        // Change to position left
        app.statusItemButton.click()
        app.positionButton.click()
        app.positionLeftButton.click()
        
        // Check window location is .left
        XCTAssertEqual(app.magpieWindow.frame.midX, PanelPosition.left.getFrame(forScreen: NSScreen.main!).midX)
        
        // Change to position bottom
        app.statusItemButton.click()
        app.positionButton.click()
        app.positionBottomButton.click()
        
        // Check window location is .bottom
        let statusBarHeight = NSScreen.main!.frame.height - NSScreen.main!.visibleFrame.height
        XCTAssertEqual(app.magpieWindow.frame.midY, NSScreen.main!.visibleFrame.height + statusBarHeight - Constants.panel.menuHeight/2)
        
        // Change to position top
        app.statusItemButton.click()
        app.positionButton.click()
        app.positionTopButton.click()
        
        // Check window location is .top
        XCTAssertEqual(app.magpieWindow.frame.midY, Constants.panel.menuHeight/2)
        
        // Change back to position right
        app.statusItemButton.click()
        app.positionButton.click()
        app.positionRightButton.click()
        
        // Check window location is .right
        XCTAssertEqual(app.magpieWindow.frame.midX, PanelPosition.right.getFrame(forScreen: NSScreen.main!).midX)
    }
    
    func testEmptyYippyHistory() {
        // Empty app support directory
        app.launchArguments.append("--test-dir=Empty")
        
        // Test no contents on pasteboard
        NSPasteboard.general.clearContents()
        
        // Launch app
        app.launch()
        
        // Open Yippy window
        app.pressHotKey()
        
        // Check Yippy window displayed with no cells
        XCTAssertTrue(app.magpieTableView.isDisplayed)
        XCTAssertEqual(app.magpieTableViewItems.count, 0)
        
        // Close Yippy window
        app.pressHotKey()
        
        // Copy something
        NSPasteboard.general.declareTypes([.string], owner: nil)
        NSPasteboard.general.setString("My first test!", forType: .string)
        
        // Show the Yippy window
        app.pressHotKey()
        
        // Check Yippy window displayed with 1 cell
        XCTAssertTrue(app.magpieTableView.isDisplayed)
        XCTAssertEqual(app.magpieTableViewItems.count, 1)
        XCTAssertEqual(app.getYippyTableViewItemString(at: 0), "My first test!")
    }
    
    func testLoadFromDefinedSettings() {
        // Copy something
        NSPasteboard.general.declareTypes([.string], owner: nil)
        NSPasteboard.general.setString("My latest copy", forType: .string)
        
        // Set settings environment
        app.launchArguments.append("--Settings.testData=a")
        
        // Basic app support directory
        app.launchArguments.append("--test-dir=A")
        
        // Launch app
        app.launch()
        
        // Open Yippy window
        app.pressHotKey()
        
        // Check Yippy window displayed with correct number of cells
        XCTAssertTrue(app.magpieTableView.isDisplayed)
        XCTAssertEqual(app.magpieTableViewItems.count, 5)
    }
    
    func testEnterToPaste() {
        // Copy something
        NSPasteboard.general.declareTypes([.string], owner: nil)
        NSPasteboard.general.setString("My latest copy", forType: .string)
        
        // Set settings environment
        app.launchArguments.append("--Settings.testData=a")
        
        // Basic app support directory
        app.launchArguments.append("--test-dir=A")
        
        // Launch app
        app.launch()
        
        // Open Yippy window
        app.pressHotKey()
        app.typeKey(.return)
        
        // Assert item was pasted
        assertCmdV()
        
        // Assert the Yippy window is closed
        XCTAssertFalse(app.magpieWindow.isDisplayed)
    }
    
    func testPasteFromHistory() {
        // Copy something
        NSPasteboard.general.declareTypes([.string], owner: nil)
        NSPasteboard.general.setString("My latest copy", forType: .string)
        
        // Set settings environment
        app.launchArguments.append("--Settings.testData=a")
        
        // Basic app support directory
        app.launchArguments.append("--test-dir=A")
        
        // Launch app
        app.launch()
        
        // Open Yippy window
        app.pressHotKey()
        // Select index 2
        app.getYippyTableViewCell(at: 2).click()
        app.typeKey(.return)
        
        // Assert item was pasted
        assertCmdV()
        
        // Assert the Yippy window is closed
        XCTAssertFalse(app.magpieWindow.isDisplayed)
        
        // Assert the pasteboard now contains the index 2 text (index 1 in history)
        XCTAssertEqual(NSPasteboard.general.string(forType: .string), "2")
        
        // Open Yippy window
        app.pressHotKey()
        
        // Check that the items have been shuffled
        XCTAssertEqual(app.getYippyTableViewItemString(at: 0), "2")
        XCTAssertEqual(app.getYippyTableViewItemString(at: 1), "My latest copy")
        XCTAssertEqual(app.getYippyTableViewItemString(at: 2), "1")
    }
    
    func testPasteFromShortcut() {
        // Copy something
        NSPasteboard.general.declareTypes([.string], owner: nil)
        NSPasteboard.general.setString("My latest copy", forType: .string)
        
        // Set settings environment
        app.launchArguments.append("--Settings.testData=a")
        
        // Basic app support directory
        app.launchArguments.append("--test-dir=A")
        
        // Launch app
        app.launch()
        
        // Open Yippy window
        app.pressHotKey()
        // Use short cut for item index 2 (⌘ + 2)
        app.typeKey("2", modifierFlags: .command)
        
        // Assert item was pasted
        assertCmdV()
        
        // Assert the Yippy window is closed
        XCTAssertFalse(app.magpieWindow.isDisplayed)
        
        // Assert the pasteboard now contains the index 2 text (index 1 in history)
        XCTAssertEqual(NSPasteboard.general.string(forType: .string), "2")
        
        // Open Yippy window
        app.pressHotKey()
        
        // Check that the items have been shuffled
        XCTAssertEqual(app.getYippyTableViewItemString(at: 0), "2")
        XCTAssertEqual(app.getYippyTableViewItemString(at: 1), "My latest copy")
        XCTAssertEqual(app.getYippyTableViewItemString(at: 2), "1")
    }
    
    func testDelete() {
        // Copy something
        NSPasteboard.general.declareTypes([.string], owner: nil)
        NSPasteboard.general.setString("My latest copy", forType: .string)
        
        // Set settings environment
        app.launchArguments.append("--Settings.testData=a")
        
        // Basic app support directory
        app.launchArguments.append("--test-dir=A")
        
        // Launch app
        app.launch()
        
        // Open Yippy window
        app.pressHotKey()
        // Select index 2
        app.getYippyTableViewCell(at: 2).click()
        // Delete
        app.typeKey(.delete, modifierFlags: .command)
        
        // Check that the item is gone
        XCTAssertEqual(app.magpieTableViewItems.count, 4)
        XCTAssertEqual(app.getYippyTableViewItemString(at: 0), "My latest copy")
        XCTAssertEqual(app.getYippyTableViewItemString(at: 1), "1")
        XCTAssertEqual(app.getYippyTableViewItemString(at: 2), "3")
        XCTAssertEqual(app.getYippyTableViewItemString(at: 3), "4")
        
        // Delete again
        app.typeKey(.delete, modifierFlags: .command)
        app.typeKey(.delete, modifierFlags: .command)
        
        // Check that the items are gone
        XCTAssertEqual(app.magpieTableViewItems.count, 2)
        XCTAssertEqual(app.getYippyTableViewItemString(at: 0), "My latest copy")
        XCTAssertEqual(app.getYippyTableViewItemString(at: 1), "1")
        
        // Delete first item
        app.getYippyTableViewCell(at: 0).click()
        app.typeKey(.delete, modifierFlags: .command)
        
        // Check that the item is gone
        XCTAssertEqual(app.magpieTableViewItems.count, 1)
        XCTAssertEqual(app.getYippyTableViewItemString(at: 0), "1")
        
        // Delete final item
        app.typeKey(.delete, modifierFlags: .command)
        
        // Check all items gone
        XCTAssertEqual(app.magpieTableViewItems.count, 0)
        
        // Check pasteboard is empty
        XCTAssertTrue(NSPasteboard.general.types?.isEmpty ?? true)
    }
    
    func testTypes() {
        // Copy something
        NSPasteboard.general.declareTypes([.string], owner: nil)
        NSPasteboard.general.setString("My latest copy", forType: .string)
        
        // Basic app support directory
        app.launchArguments.append("--test-dir=Big")
        
        // Launch app
        app.launch()
        
        // Open Yippy window
        app.pressHotKey()
        
        // Assert the types of items: Text, icon, thumbnail, tiff
        XCTAssertEqual(app.getYippyTableViewCellType(at: 0), Accessibility.identifiers.magpieTextCellView)
        XCTAssertEqual(app.getYippyTableViewCellType(at: 1), Accessibility.identifiers.magpieColorCellView)
        XCTAssertEqual(app.getYippyTableViewCellType(at: 2), Accessibility.identifiers.magpieFileIconCellView)
        XCTAssertEqual(app.getYippyTableViewCellType(at: 4), Accessibility.identifiers.magpieTiffCellView)
    }
}
