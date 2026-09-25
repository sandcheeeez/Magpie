//
//  DevSnapshot.swift
//  Magpie
//

#if XCTEST
import Foundation
import Cocoa

/// Development aid, compiled only into the XCTest configuration (which has its own bundle id and data): `--snapshot=<dir>` fills the history with sample items, shows the panel, renders it to PNGs in light and dark appearance, then quits.
enum DevSnapshot {
    
    static var outputDirectory: URL? {
        guard let arg = CommandLine.arguments.first(where: { $0.hasPrefix("--snapshot=") }) else { return nil }
        return URL(fileURLWithPath: String(arg.dropFirst("--snapshot=".count)), isDirectory: true)
    }
    
    static func prepare() {
        precondition(Bundle.main.bundleIdentifier?.hasSuffix("XCTest") == true, "Snapshots must not touch real user data")
        Helper.accessControlHelper = AccessControlHelperMock()
        Helper.keyPressHelper = KeyPressHelperMock()
        try? FileManager.default.removeItem(at: Constants.urls.yippyAppSupport)
    }
    
    static func run(outputDirectory: URL) {
        let history = AppState.main.history!
        history.clear()
        for (i, sample) in samples().enumerated().reversed() {
            let item = HistoryItem(unsavedData: sample.data, cache: history.cache)
            item.metadata = HistoryItemMetadata(copiedAt: Date().addingTimeInterval(-sample.age), sourceBundleId: sample.app, isPinned: sample.pinned, recognizedText: sample.pinned ? nil : "")
            history.insertItem(item, at: 0)
            _ = i
        }
        
        Controller.main.togglePopover()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Select the image, whose content runs to the card's edges.
            (Controller.main.yippyWindowController.contentViewController as? YippyViewController)?.selected = 3
        }
        try? FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            render(to: outputDirectory.appendingPathComponent("panel-light.png"), appearance: .aqua)
            render(to: outputDirectory.appendingPathComponent("panel-dark.png"), appearance: .darkAqua)
            NSApp.appearance = NSAppearance(named: .aqua)
            Controller.main.showSettings()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if let view = Controller.main.settingsWindowController.window?.contentView {
                    renderView(view, to: outputDirectory.appendingPathComponent("settings.png"))
                }
                NSApp.terminate(nil)
            }
        }
    }
    
    private struct Sample {
        let data: [NSPasteboard.PasteboardType: Data]
        let app: String?
        let age: TimeInterval
        var pinned = false
    }
    
    private static func text(_ s: String) -> [NSPasteboard.PasteboardType: Data] {
        return [.string: s.data(using: .utf8)!]
    }
    
    private static func samples() -> [Sample] {
        let color = NSColor(srgbRed: 0.35, green: 0.55, blue: 0.95, alpha: 1)
        let colorData = try! NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false)
        
        let image = NSImage(size: NSSize(width: 320, height: 160), flipped: false) { rect in
            NSGradient(starting: .systemPink, ending: .systemOrange)!.draw(in: rect, angle: 30)
            NSAttributedString(string: "Screenshot", attributes: [.font: NSFont.boldSystemFont(ofSize: 28), .foregroundColor: NSColor.white]).draw(at: NSPoint(x: 24, y: 60))
            return true
        }
        
        return [
            Sample(data: text("let greeting = \"Hello, Apple silicon!\"\nprint(greeting)"), app: "com.apple.dt.Xcode", age: 20),
            Sample(data: text("https://github.com/sandcheeeez/Magpie"), app: "com.apple.Safari", age: 300),
            Sample(data: text("Meeting notes: ship the glass redesign, then pinning and OCR search."), app: "com.apple.Notes", age: 3600, pinned: true),
            Sample(data: [.tiff: image.tiffRepresentation!], app: "com.apple.Preview", age: 7200),
            Sample(data: [.color: colorData], app: "com.apple.DigitalColorMeter", age: 86400),
            Sample(data: [.fileURL: URL(fileURLWithPath: "/System/Applications/Calculator.app").dataRepresentation], app: "com.apple.finder", age: 172800),
        ]
    }
    
    private static func renderView(_ view: NSView, to url: URL) {
        view.layoutSubtreeIfNeeded()
        view.displayIfNeeded()
        guard let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
        view.cacheDisplay(in: view.bounds, to: rep)
        try? rep.representation(using: .png, properties: [:])?.write(to: url)
    }
    
    /// Renders the panel's contents over a colourful backdrop standing in for the desktop. The glass itself is drawn by the window server, so it isn't captured.
    private static func render(to url: URL, appearance: NSAppearance.Name) {
        guard let window = Controller.main.yippyWindowController.window, let view = window.contentView else { return }
        NSApp.appearance = NSAppearance(named: appearance)
        view.layoutSubtreeIfNeeded()
        Controller.main.yippyWindowController.contentViewController?.view.needsDisplay = true
        view.displayIfNeeded()
        
        guard let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
        view.cacheDisplay(in: view.bounds, to: rep)
        
        let dark = appearance == .darkAqua
        let image = NSImage(size: view.bounds.size, flipped: false) { rect in
            let backdrop = NSBezierPath(roundedRect: rect, xRadius: YippyWindowController.cornerRadius, yRadius: YippyWindowController.cornerRadius)
            NSGradient(starting: dark ? NSColor(white: 0.16, alpha: 1) : NSColor(white: 0.95, alpha: 1),
                       ending: dark ? NSColor(white: 0.10, alpha: 1) : NSColor(white: 0.88, alpha: 1))!.draw(in: backdrop, angle: -90)
            rep.draw(in: rect)
            return true
        }
        guard let tiff = image.tiffRepresentation, let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) else { return }
        try? png.write(to: url)
    }
}
#endif
