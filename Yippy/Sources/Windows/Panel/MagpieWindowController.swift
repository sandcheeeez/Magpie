//
//  MagpieWindowController.swift
//  Magpie
//

import Foundation
import Cocoa

class MagpieWindowController: NSWindowController {
    
    static let cornerRadius: CGFloat = 24
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        window?.level = NSWindow.Level(NSWindow.Level.mainMenu.rawValue - 2)
        window?.setAccessibilityIdentifier(Accessibility.identifiers.magpieWindow)
        window?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        wrapContentInGlass()
    }
    
    /// Puts the history view on a Liquid Glass surface with rounded corners, floating over a clear window.
    private func wrapContentInGlass() {
        guard let window = window, let content = contentViewController?.view else { return }
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        
        let glass = NSGlassEffectView()
        glass.cornerRadius = Self.cornerRadius
        window.contentView = glass
        glass.contentView = content
    }
    
    static func createYippyWindowController() -> MagpieWindowController {
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let identifier = NSStoryboard.SceneIdentifier(stringLiteral: "MagpieWindowController")
        guard let windowController = storyboard.instantiateController(withIdentifier: identifier) as? MagpieWindowController else {
            fatalError("Failed to load MagpieWindowController of type MagpieWindowController from the Main storyboard.")
        }
        
        return windowController
    }
    
    private var oldApp: NSRunningApplication?
    
    private weak var state: AppState?
    
    /// Incremented on each show, so a fade-out that finishes after the panel was reshown doesn't close it.
    private var showGeneration = 0
    
    /// Shows or hides the panel, and keeps its frame in place, as the state changes.
    func observe(state: AppState) {
        self.state = state
        Magpie.observe({ state.isHistoryPanelShown }) { isShown in
            if isShown {
                self.oldApp = NSWorkspace.shared.frontmostApplication
                self.show()
                NSApp.activate()
            }
            else if self.window?.isVisible == true {
                self.hide()
                self.oldApp?.activate()
            }
        }
        observeAll({ (state.panelPosition, state.currentScreen) }) { position, screen in
            self.window?.setFrame(position.getFrame(forScreen: screen), display: true)
        }
    }
    
    /// Slides and fades the panel in from its edge.
    private func show() {
        guard let window = window else { return }
        showGeneration += 1
        // Computed here rather than relying on the frame observer, which may not have run yet.
        let position = state?.panelPosition ?? .right
        let frame = state.map({ position.getFrame(forScreen: $0.currentScreen) }) ?? window.frame
        let offset = position.slideOffset
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        
        window.setFrame(reduceMotion ? frame : frame.offsetBy(dx: offset.x, dy: offset.y), display: false)
        window.alphaValue = 0
        showWindow(nil)
        window.makeKey()
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = reduceMotion ? 0.12 : 0.28
            // Slight overshoot gives a spring-like settle.
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 0.9, 0.25, 1.08)
            window.animator().setFrame(frame, display: true)
            window.animator().alphaValue = 1
        }
    }
    
    private func hide() {
        guard let window = window, window.isVisible else {
            close()
            return
        }
        let generation = showGeneration
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.12
            window.animator().alphaValue = 0
        }, completionHandler: {
            if generation == self.showGeneration {
                self.close()
            }
        })
    }
}
