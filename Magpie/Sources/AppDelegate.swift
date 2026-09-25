//
//  AppDelegate.swift
//  Magpie
//

import Cocoa
import HotKey

class AppDelegate: NSObject, NSApplicationDelegate {
    

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        checkBuildFlags()
        checkLaunchArgs()
        #if XCTEST
        let snapshotDirectory = DevSnapshot.outputDirectory
        if snapshotDirectory != nil {
            DevSnapshot.prepare()
        }
        #endif
        Controller.main = Controller(state: AppState.main, settings: Settings.main)
        #if XCTEST
        if let snapshotDirectory = snapshotDirectory {
            setupHotKey()
            DevSnapshot.run(outputDirectory: snapshotDirectory)
            return
        }
        #endif
        
        showWelcomeIfNeeded()

        setupHotKey()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }
    
    func checkLaunchArgs() {
        if CommandLine.arguments.contains("--uitesting") {
            do {
                try UITesting.setupUITestEnvironment(launchArgs: CommandLine.arguments, environment: ProcessInfo.processInfo.environment)
            }
            catch {
                NSAlert(error: error).runModal()
            }
        }
    }
    
    func checkBuildFlags() {
        #if BETA
        MagpieStatusItem.statusItemButtonImage = NSImage(systemSymbolName: "bird.fill", accessibilityDescription: "Magpie Beta")
        #endif
    }
    
    func showWelcomeIfNeeded() {
        // If the user has enabled access we don't need to do anything
        if Helper.isControlGranted(showPopup: false) {
            return
        }
        
        // Otherwise we should show a popup detailing why access is required.
        Controller.main.welcomeWindowController.showWindow(nil)
        
        // Bring the window to front
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func setupHotKey() {
        MagpieHotKeys.toggle.changeHotKey(keyCombo: Settings.main.toggleHotKey)
        MagpieHotKeys.toggle.onDown {
            Controller.main.togglePopover()
        }
    }
}
