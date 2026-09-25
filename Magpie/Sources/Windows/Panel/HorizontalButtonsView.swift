//
//  HorizontalButtonsView.swift
//  Magpie
//

import Foundation
import Cocoa

class HorizontalButtonsView: NSScrollView {
    
    private var buttons = [NSButton]()
    private var buttonsDocumentView = NSView(frame: .zero)
    
    var leftPadding: CGFloat = 20
    var rightPadding: CGFloat = 20
    var innerPadding: CGFloat = 10
    
    /// Called with the index of the button the user clicked.
    var onSelect: ((Int) -> Void)?
    
    /// SF Symbol names for each button. Unselected buttons show only their symbol when one is given, to save space.
    var symbolNames = [String]()
    
    private var titles = [String]()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        commonInit()
    }
    
    private func commonInit() {
        horizontalScrollElasticity = .automatic
        verticalScrollElasticity = .none
        drawsBackground = false
        contentView.drawsBackground = false
    }
    
    /// Replaces the buttons with one per title.
    func setTitles(_ titles: [String]) {
        self.titles = titles
        buttons = createButtons(data: titles)
        buttonsDocumentView = NSView()
        buttons.forEach({ buttonsDocumentView.addSubview($0) })
        layoutButtons()
    }
    
    func select(_ index: Int) {
        updateSelected(index)
    }
    
    /// Changes one button's title, e.g. to show the chosen tag.
    func setTitle(_ title: String, at index: Int) {
        guard index < titles.count else { return }
        titles[index] = title
        buttons[index].toolTip = title
        updateSelected(selectedIndex)
    }
    
    func button(at index: Int) -> NSButton? {
        return index < buttons.count ? buttons[index] : nil
    }
    
    private func createButtons(data: [String]) -> [NSButton] {
        return data.enumerated().map({
            let button = ChipButton(title: $1, target: self, action: #selector(buttonHandler(_:)))
            button.tag = $0
            button.toolTip = $1
            button.setAccessibilityLabel($1)
            if $0 < symbolNames.count {
                button.image = NSImage(systemSymbolName: symbolNames[$0], accessibilityDescription: $1)
            }
            return button
        })
    }
    
    private func getWidth(buttons: [NSButton]) -> CGFloat {
        return buttons.reduce(0, {$0 + $1.frame.width}) + CGFloat(buttons.count - 1) * innerPadding
    }
    
    private func layoutButtons() {
        let buttonWidth = getWidth(buttons: buttons)
        let totalWidth = buttonWidth + leftPadding + rightPadding
        let documentViewWidth = totalWidth < contentView.frame.width ? contentView.frame.width : totalWidth
        self.buttonsDocumentView.frame = CGRect(x: 0, y: 0, width: documentViewWidth, height: contentView.frame.height)
        
        var x: CGFloat = leftPadding
        if totalWidth < contentView.frame.width {
            x = contentView.frame.midX - buttonWidth/2
        }
        
        for button in buttons {
            button.setFrameOrigin(NSPoint(x: x, y: (contentView.frame.height - button.frame.height) / 2))
            x += button.frame.width + innerPadding
        }
        
        self.documentView = buttonsDocumentView
    }
    
    private var selectedIndex: Int?
    
    private func updateSelected(_ selected: Int?) {
        selectedIndex = selected
        for (i, button) in buttons.enumerated() {
            guard let chip = button as? ChipButton else { continue }
            let isSelected = i == selected
            chip.title = isSelected || chip.image == nil ? titles[i] : ""
            chip.isChipSelected = isSelected
        }
        layoutButtons()
    }
    
    @objc private func buttonHandler(_ sender: NSButton) {
        updateSelected(sender.tag)
        onSelect?(sender.tag)
    }
    
    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        
        layoutButtons()
    }
}

protocol HorizontalButtonsViewDelegate {
    
    func horizontalButtonsView(_ horizontalButtonsView: HorizontalButtonsView, didClickButtonAt i: Int)
    
}

/// A capsule shaped filter chip. Unselected chips show just their symbol; the selected chip is filled with the accent colour and shows its title.
class ChipButton: NSButton {
    
    static let height: CGFloat = 26
    
    var isChipSelected = false {
        didSet {
            updateAppearance()
        }
    }
    
    override var title: String {
        didSet {
            imagePosition = title.isEmpty ? .imageOnly : .imageLeading
            updateAppearance()
        }
    }
    
    convenience init(title: String, target: AnyObject?, action: Selector?) {
        self.init(frame: .zero)
        self.title = title
        self.target = target
        self.action = action
        isBordered = false
        wantsLayer = true
        layer?.cornerCurve = .continuous
        font = .systemFont(ofSize: 12, weight: .semibold)
        imageHugsTitle = true
        symbolConfiguration = .init(pointSize: 12, weight: .semibold)
        focusRingType = .none
        updateAppearance()
    }
    
    override var wantsUpdateLayer: Bool {
        return true
    }
    
    override func updateLayer() {
        super.updateLayer()
        effectiveAppearance.performAsCurrentDrawingAppearance {
            layer?.backgroundColor = (isChipSelected ? NSColor.controlAccentColor : NSColor.quaternarySystemFill).cgColor
        }
        layer?.cornerRadius = bounds.height / 2
    }
    
    private func updateAppearance() {
        contentTintColor = isChipSelected ? .white : .secondaryLabelColor
        attributedTitle = NSAttributedString(string: title, attributes: [
            .font: font ?? .systemFont(ofSize: 12),
            .foregroundColor: isChipSelected ? NSColor.white : NSColor.secondaryLabelColor,
        ])
        let contentWidth = title.isEmpty ? 16 : attributedTitle.size().width + (image == nil ? 0 : 20)
        setFrameSize(NSSize(width: ceil(contentWidth) + 16, height: Self.height))
        needsDisplay = true
    }
}
