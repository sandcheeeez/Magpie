//
//  Controller.swift
//  Magpie
//

import Foundation
import Cocoa

class Controller {
    
    // MARK: - Singleton
    
    static var main: Controller!
    
    
    // MARK: - Attributes
    
    var state: AppState
    
    /// Must exist for the duration of the application so that the status bar does not disappear.
    var statusItem: NSStatusItem!
    
    // Window Controllers
    var magpieWindowController: MagpieWindowController!
    var previewWindowController: PreviewWindowController!
    
    lazy var welcomeWindowController: WelcomeWindowController = {
        return WelcomeWindowController.createWelcomeWindowController()
    }()
    
    lazy var helpWindowController: HelpWindowController = {
        return HelpWindowController.createHelpWindowController()
    }()
    
    lazy var aboutWindowController: AboutWindowController = {
        return AboutWindowController.createAboutWindowController()
    }()
    
    lazy var settingsWindowController: SettingsWindowController = {
        return SettingsWindowController.createSettingsWindowController()
    }()
    
    
    // MARK: - Constructor
    
    init(state: AppState, settings: Settings) {
        self.state = state
        // Setup status item
        self.statusItem = MagpieStatusItem.create()
        self.statusItem.menu = Self.createMenu(settings: settings, state: state, target: self)
        
        // Create yippy window controller
        self.magpieWindowController = Self.createYippyWindowController(state: state)
       
        // Create preview window controllers
        self.previewWindowController = Self.createPreviewWindowController(state: state)
    }
    
    
    // MARK: - Constructor Helpers
    
    static func createMenu(settings: Settings, state: AppState, target: AnyObject?) -> NSMenu {
        let menu = NSMenu()
            .with(menuItem: NSMenuItem(title: "About Magpie", action: #selector(showAboutWindow), keyEquivalent: "")
                .with(accessibilityIdentifier: Accessibility.identifiers.aboutButton)
            )
            .with(menuItem: NSMenuItem(title: "Magpie Help", action: #selector(showHelpWindow), keyEquivalent: "")
                .with(accessibilityIdentifier: Accessibility.identifiers.helpButton)
            )
            .with(menuItem: NSMenuItem.separator())
            .with(menuItem: NSMenuItem(title: "Settings…", action: #selector(showSettings), keyEquivalent: ",")
                .with(accessibilityIdentifier: "")
            )
            .with(menuItem: NSMenuItem.separator())
            .with(menuItem: NSMenuItem(title: "Toggle Window", action: #selector(togglePopover), keyEquivalent: "V")
                .with(accessibilityIdentifier: Accessibility.identifiers.toggleYippyWindowButton)
            )
            .with(menuItem: NSMenuItem(title: "Launch at Login", action: #selector(launchAtLogin), keyEquivalent: "")
                .with(accessibilityIdentifier: Accessibility.identifiers.launchAtLoginButton)
            )
            .with(menuItem: NSMenuItem(title: "Delete Selected", action: #selector(deleteSelectedClicked), keyEquivalent: Constants.statusItemMenu.deleteKeyEquivalent)
                .with(state: .off)
            )
            .with(menuItem: NSMenuItem(title: "Clear history", action: #selector(clearHistoryClicked), keyEquivalent: ""))
            .with(menuItem: NSMenuItem(title: "Position", action: nil, keyEquivalent: "")
                .with(accessibilityIdentifier: Accessibility.identifiers.positionButton)
                .with(submenu: createWindowPositionSubmenu(settings: settings))
            )
            .with(menuItem: NSMenuItem.separator())
            .with(menuItem: NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "")
                .with(accessibilityIdentifier: Accessibility.identifiers.quitButton)
        )
        menu.autoenablesItems = false
        
        Self.setMenuItemsTarget(target: target, menu: menu)
        
        observe({ state.launchAtLogin }) { launchAtLogin in
            menu.item(withTitle: "Launch at Login")?.state = launchAtLogin ? .on : .off
        }
        
        observe({ state.panelPosition }) { next in
            PanelPosition.allCases.forEach { pos in
                menu.item(withTitle: "Position")?.submenu?.item(withTag: pos.rawValue)?.state = next == pos ? .on : .off
            }
        }
        
        observe({ state.isHistoryPanelShown }) { isShown in
            // Arrow key equivalents for moving the panel only apply while it is shown.
            let arrows: [(PanelPosition, String)] = [
                (.left, Constants.statusItemMenu.leftArrowKeyEquivalent),
                (.right, Constants.statusItemMenu.rightArrowKeyEquivalent),
                (.top, Constants.statusItemMenu.upArrowKeyEquivalent),
                (.bottom, Constants.statusItemMenu.downArrowKeyEquivalent),
            ]
            for (position, key) in arrows {
                let item = menu.item(withTitle: "Position")?.submenu?.item(withTag: position.rawValue)
                item?.keyEquivalent = isShown ? key : ""
                item?.keyEquivalentModifierMask = [.control, .option, .command]
            }
            menu.item(withTitle: "Delete Selected")?.isEnabled = isShown
            menu.item(withTitle: "Delete Selected")?.keyEquivalentModifierMask = .control
        }
        
        return menu
    }
    
    static func createWindowPositionSubmenu(settings: Settings) -> NSMenu {
        let menu = NSMenu(title: "")
        menu.items = PanelPosition.allCases.map({pos in
            return NSMenuItem(title: pos.title, action: #selector(panelPositionSelected(_:)), keyEquivalent: "")
                .with(accessibilityIdentifier: pos.identifier)
                .with(state: settings.panelPosition == pos ? .on : .off)
                .with(tag: pos.rawValue)
        })
        return menu
    }
    
    static func setMenuItemsTarget(target: AnyObject?, menu: NSMenu) {
        for item in menu.items {
            item.target = target
            if let subMenu = item.submenu {
                setMenuItemsTarget(target: target, menu: subMenu)
            }
        }
    }
    
    static func createYippyWindowController(state: AppState) -> MagpieWindowController {
        let controller = MagpieWindowController.createYippyWindowController()
        controller.observe(state: state)
        return controller
    }
    
    static func createPreviewWindowController(state: AppState) -> PreviewWindowController {
        let controller = PreviewWindowController.create()
        controller.observe(state: state)
        return controller
    }
    
    
    // MARK: - Methods
    @objc func panelPositionSelected(_ sender: NSMenuItem) {
        if let position = PanelPosition(rawValue: sender.tag) {
            state.panelPosition = position
        }
        else {
            MagpieError(localizedDescription: "Received invalid panel position from \(sender)").log(with: ErrorLogger.general)
        }
    }

    @objc func togglePopover() {
        if !state.isHistoryPanelShown {
            state.updateCurrentScreen()
        }
        state.isHistoryPanelShown.toggle()
    }
    
    @objc func deleteSelectedClicked() {
        MagpieHotKeys.ctrlDelete.simulateOnDown()
    }
    
    @objc func clearHistoryClicked() {
        state.history.clear()
    }
    
    @objc func showHelpWindow() {
        // If the window isn't visible, show it
        if !self.helpWindowController.window!.isVisible {
            self.helpWindowController.showWindow(nil)
            self.helpWindowController.window?.center()
        }
        
        // Bring the window to front
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func showAboutWindow() {
        // If the window isn't visible, show it
        if !self.aboutWindowController.window!.isVisible {
            self.aboutWindowController.showWindow(nil)
            self.aboutWindowController.window?.center()
        }
        
        // Bring the window to front
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func showSettings() {
        // If the window isn't visible, show it
        if !self.settingsWindowController.window!.isVisible {
            self.settingsWindowController.showWindow(nil)
            self.settingsWindowController.window?.center()
        }
        
        // Bring the window to front
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(self)
    }
    
    @objc func launchAtLogin() {
        state.setLaunchAtLogin(!state.launchAtLogin)
    }
}
