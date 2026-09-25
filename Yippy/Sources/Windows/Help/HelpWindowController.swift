//
//  HelpWindowController.swift
//  Magpie
//

import Foundation
import Cocoa

class HelpWindowController: NSWindowController {
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        window?.setAccessibilityIdentifier(Accessibility.identifiers.helpWindow)
    }
    
    static func createHelpWindowController() -> HelpWindowController {
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let identifier = NSStoryboard.SceneIdentifier(stringLiteral: "HelpWindowController")
        guard let windowController = storyboard.instantiateController(withIdentifier: identifier) as? HelpWindowController else {
            fatalError("Failed to load HelpWindowController of type HelpWindowController from the Main storyboard.")
        }
        
        return windowController
    }
}
