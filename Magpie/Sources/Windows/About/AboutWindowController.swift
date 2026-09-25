//
//  AboutWindowController.swift
//  Magpie
//

import Foundation
import Cocoa

class AboutWindowController: NSWindowController {
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        window?.setAccessibilityIdentifier(Accessibility.identifiers.aboutWindow)
    }
    
    static func createAboutWindowController() -> AboutWindowController {
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let identifier = NSStoryboard.SceneIdentifier(stringLiteral: "AboutWindowController")
        guard let windowController = storyboard.instantiateController(withIdentifier: identifier) as? AboutWindowController else {
            fatalError("Failed to load AboutWindowController of type AboutWindowController from the Main storyboard.")
        }
        return windowController
    }
}
