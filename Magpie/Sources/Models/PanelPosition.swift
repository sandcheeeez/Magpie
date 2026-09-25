//
//  PanelPosition.swift
//  Magpie
//

import Foundation
import Cocoa

enum PanelPosition: Int, Codable, CaseIterable {
    case right = 0
    case left = 1
    case top = 2
    case bottom = 3
    case centerExtraSmall = 8
    case centerSmall = 4
    case centerMedium = 5
    case centerLarge = 6
    case fullScreen = 7
    
    /// Gap between the floating panel and the edges of the screen's visible area.
    static let margin: CGFloat = 8
    
    public func getFrame(forScreen screen: NSScreen) -> NSRect {
        // Edge panels float inside the visible area, clear of the menu bar and Dock.
        let area = screen.visibleFrame.insetBy(dx: Self.margin, dy: Self.margin)
        switch self {
        case .right:
            return NSRect(x: area.maxX - Constants.panel.menuWidth, y: area.minY, width: Constants.panel.menuWidth, height: area.height)
        case .left:
            return NSRect(x: area.minX, y: area.minY, width: Constants.panel.menuWidth, height: area.height)
        case .top:
            return NSRect(x: area.minX, y: area.maxY - Constants.panel.menuHeight, width: area.width, height: Constants.panel.menuHeight)
        case .bottom:
            return NSRect(x: area.minX, y: area.minY, width: area.width, height: Constants.panel.menuHeight)
        case .centerExtraSmall:
            let size = NSSize(width: screen.frame.width / 3, height: screen.frame.height / 3)
            return Self.centerRect(ofSize: size, inRect: screen.frame)
        case .centerSmall:
            let size = NSSize(width: screen.frame.width / 2, height: screen.frame.height / 2)
            return Self.centerRect(ofSize: size, inRect: screen.frame)
        case .centerMedium:
            let size = NSSize(width: screen.frame.width * 0.7, height: screen.frame.height * 0.7)
            return Self.centerRect(ofSize: size, inRect: screen.frame)
        case .centerLarge:
            let size = NSSize(width: screen.frame.width * 0.85, height: screen.frame.height * 0.85)
            return Self.centerRect(ofSize: size, inRect: screen.frame)
        case .fullScreen:
            return screen.visibleFrame.insetBy(dx: Self.margin, dy: Self.margin)
        }
    }
    
    /// The direction the panel slides in from when shown.
    var slideOffset: NSPoint {
        switch self {
        case .right: return NSPoint(x: 24, y: 0)
        case .left: return NSPoint(x: -24, y: 0)
        case .top: return NSPoint(x: 0, y: 24)
        case .bottom: return NSPoint(x: 0, y: -24)
        default: return NSPoint(x: 0, y: -12)
        }
    }
    
    private static func centerRect(ofSize size: NSSize, inRect rect: NSRect) -> NSRect {
        return NSRect(origin: NSPoint(x: (rect.width - size.width) / 2 + rect.minX, y: (rect.height - size.height) / 2 + rect.minY), size: size)
    }
    
    var title: String {
        switch self {
        case .right:
            return "Right"
        case .left:
            return "Left"
        case .top:
            return "Top"
        case .bottom:
            return "Bottom"
        case .centerExtraSmall:
            return "Center (Extra Small)"
        case .centerSmall:
            return "Center (Small)"
        case .centerMedium:
            return "Center (Medium)"
        case .centerLarge:
            return "Center (Large)"
        case .fullScreen:
            return "Full Screen"
        }
    }
    
    var identifier: String {
        switch self {
        case .right:
            return Accessibility.identifiers.positionRightButton
        case .left:
            return Accessibility.identifiers.positionLeftButton
        case .top:
            return Accessibility.identifiers.positionTopButton
        case .bottom:
            return Accessibility.identifiers.positionBottomButton
        case.centerExtraSmall:
            return Accessibility.identifiers.positionCenterExtraSmall
        case .centerSmall:
            return Accessibility.identifiers.positionCenterSmall
        case .centerMedium:
            return Accessibility.identifiers.positionCenterMedium
        case .centerLarge:
            return Accessibility.identifiers.positionCenterLarge
        case .fullScreen:
            return Accessibility.identifiers.positionFullScreen
        }
    }
}
