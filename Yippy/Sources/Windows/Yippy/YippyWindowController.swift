//
//  YippyWindowController.swift
//  Yippy
//
//  Created by Matthew Davidson on 25/9/19.
//  Copyright © 2019 MatthewDavidson. All rights reserved.
//

import Foundation
import Cocoa
import RxSwift
import RxRelay

class YippyWindowController: NSWindowController {
    
    static let cornerRadius: CGFloat = 24
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        window?.level = NSWindow.Level(NSWindow.Level.mainMenu.rawValue - 2)
        window?.setAccessibilityIdentifier(Accessibility.identifiers.yippyWindow)
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
    
    static func createYippyWindowController() -> YippyWindowController {
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let identifier = NSStoryboard.SceneIdentifier(stringLiteral: "YippyWindowController")
        guard let windowController = storyboard.instantiateController(withIdentifier: identifier) as? YippyWindowController else {
            fatalError("Failed to load YippyWindowController of type YippyWindowController from the Main storyboard.")
        }
        
        return windowController
    }
    
    private var oldApp: NSRunningApplication?
    
    private var position = PanelPosition.right
    private var targetFrame: NSRect?
    
    /// Incremented on each show, so a fade-out that finishes after the panel was reshown doesn't close it.
    private var showGeneration = 0
    
    func subscribeTo(toggle: BehaviorRelay<Bool>) -> Disposable {
        return toggle
            .subscribe(onNext: {
                [] in
                if !$0 {
                    self.hide()
                    self.oldApp?.activate()
                }
                else {
                    self.oldApp = NSWorkspace.shared.frontmostApplication
                    self.show()
                    NSApp.activate()
                }
            })
    }
    
    /// Slides and fades the panel in from its edge.
    private func show() {
        guard let window = window else { return }
        showGeneration += 1
        let frame = targetFrame ?? window.frame
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
    
    func subscribeFrameTo(position: Observable<PanelPosition>, screen: Observable<NSScreen>) -> Disposable {
        Observable.combineLatest(position, screen).subscribe(onNext: {
            (position, screen) in
            let frame = position.getFrame(forScreen: screen)
            self.position = position
            self.targetFrame = frame
            self.window?.setFrame(frame, display: true)
        })
    }
}
