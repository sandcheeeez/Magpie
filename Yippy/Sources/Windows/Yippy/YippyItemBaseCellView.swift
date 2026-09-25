//
//  YippyItemBaseCellView.swift
//  Yippy
//
//  Created by Matthew Davidson on 13/10/19.
//  Copyright © 2019 MatthewDavidson. All rights reserved.
//

import Foundation
import Cocoa

/// Abstract base class for all Yippy collection view items.
///
/// Each item is drawn as a rounded card. Subclasses lay out their content in `contentView`, which fills the card above the footer. The footer shows the source app, when the item was copied and whether it is pinned.
///
/// Handles highlight changes.
class YippyItemBaseCellView: NSTableCellView {

    /// Gap between the card and the edges of the row.
    static let cardInsets = NSEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)

    static let footerHeight: CGFloat = 24

    static let cardCornerRadius: CGFloat = 14

    /// Insets of `contentView` from the row. The bottom includes the footer, so subclasses' height calculations account for it.
    static let contentViewInsets = NSEdgeInsets(top: cardInsets.top, left: cardInsets.left, bottom: cardInsets.bottom + footerHeight, right: cardInsets.right)

    class var identifier: NSUserInterfaceItemIdentifier {
        NSUserInterfaceItemIdentifier("YippyItemBaseCellView")
    }

    var cardView: NSView!
    var contentView: YippyItemContentView!
    var shortcutTextView: YippyItemCellTextView!
    var itemTextView: YippyItemCellTextView!

    private var footerAppIcon: NSImageView!
    private var footerLabel: NSTextField!
    private var footerPinIcon: NSImageView!

    private var isSelected = false

    override var wantsUpdateLayer: Bool {
        return true
    }

    override func updateLayer() {
        super.updateLayer()
        applyColors()
    }

    /// Layer colours are `CGColor`s, which don't follow appearance changes, so they are re-applied here and on selection changes.
    private func applyColors() {
        effectiveAppearance.performAsCurrentDrawingAppearance {
            let accent = NSColor.controlAccentColor
            cardView.layer?.backgroundColor = (isSelected
                ? accent.withAlphaComponent(0.14)
                : NSColor.textBackgroundColor.withAlphaComponent(0.55)).cgColor
            cardView.layer?.borderColor = (isSelected ? accent : NSColor.separatorColor.withAlphaComponent(0.25)).cgColor
            cardView.layer?.borderWidth = isSelected ? 2 : 1
            shortcutTextView.backgroundColor = isSelected ? accent : NSColor.tertiarySystemFill
            shortcutTextView.textColor = isSelected ? .white : .secondaryLabelColor
        }
    }

    static let shortcutStringAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 11, weight: .semibold).rounded,
        .foregroundColor: NSColor.secondaryLabelColor
    ]

    func setHighlight(isSelected: Bool) {
        self.isSelected = isSelected
        applyColors()
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        commonInit()
    }

    func commonInit() {
        wantsLayer = true

        cardView = NSView(frame: .zero)
        cardView.wantsLayer = true
        cardView.layer?.cornerRadius = Self.cardCornerRadius
        cardView.layer?.cornerCurve = .continuous
        cardView.layer?.masksToBounds = true
        addSubview(cardView)

        contentView = YippyItemContentView(frame: .zero)
        addSubview(contentView)
        itemTextView = YippyItemCellTextView(frame: .zero)
        contentView.addSubview(itemTextView)
        shortcutTextView = YippyItemCellTextView(frame: .zero)
        cardView.addSubview(shortcutTextView)

        itemTextView.drawsBackground = false
        itemTextView.setAccessibilityIdentifier(Accessibility.identifiers.yippyItemTextView)

        setupCardView()
        setupContentView()
        setupShortcutTextView()
        setupFooter()
        applyColors()
    }

    func setupCardView() {
        cardView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.cardInsets.left),
            cardView.topAnchor.constraint(equalTo: topAnchor, constant: Self.cardInsets.top),
            trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: Self.cardInsets.right),
            bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: Self.cardInsets.bottom),
        ])
    }

    func setupContentView() {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.wantsLayer = true
        // Round only the top corners, matching the card, so image and colour content fills the card neatly.
        contentView.layer?.cornerRadius = Self.cardCornerRadius
        contentView.layer?.cornerCurve = .continuous
        contentView.layer?.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        contentView.layer?.masksToBounds = true

        addConstraint(NSLayoutConstraint(item: contentView!, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: Self.contentViewInsets.left))
        addConstraint(NSLayoutConstraint(item: contentView!, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: Self.contentViewInsets.top))
        addConstraint(NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: contentView, attribute: .trailing, multiplier: 1, constant: Self.contentViewInsets.right))
        addConstraint(NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: contentView, attribute: .bottom, multiplier: 1, constant: Self.contentViewInsets.bottom))
    }

    func setupShortcutTextView() {
        shortcutTextView.translatesAutoresizingMaskIntoConstraints = false
        shortcutTextView.wantsLayer = true
        shortcutTextView.isSelectable = false
        shortcutTextView.textContainer?.lineFragmentPadding = 0
        shortcutTextView.alignment = .center
        shortcutTextView.textContainerInset = NSSize(width: 6, height: 1)
        shortcutTextView.layer?.cornerRadius = 6
        shortcutTextView.layer?.cornerCurve = .continuous
        shortcutTextView.isHorizontallyResizable = false
        shortcutTextView.isVerticallyResizable = false
        shortcutTextView.layer?.zPosition = 1

        // Sits at the trailing end of the footer, so it never covers the item's content.
        shortcutTextView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -8).isActive = true
        shortcutTextView.centerYAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -Self.footerHeight / 2).isActive = true
        shortcutTextView.widthAnchor.constraint(equalToConstant: 0, withIdentifier: "width")?.isActive = true
        shortcutTextView.heightAnchor.constraint(equalToConstant: 0, withIdentifier: "height")?.isActive = true
    }

    private func setupFooter() {
        footerAppIcon = NSImageView(frame: .zero)
        footerAppIcon.imageScaling = .scaleProportionallyUpOrDown

        footerLabel = NSTextField(labelWithString: "")
        footerLabel.font = .systemFont(ofSize: 11)
        footerLabel.textColor = .secondaryLabelColor
        footerLabel.lineBreakMode = .byTruncatingTail
        footerLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        footerPinIcon = NSImageView(image: NSImage(systemSymbolName: "pin.fill", accessibilityDescription: "Pinned")!)
        footerPinIcon.symbolConfiguration = .init(pointSize: 10, weight: .semibold)
        footerPinIcon.contentTintColor = .systemOrange

        for view in [footerAppIcon!, footerLabel!, footerPinIcon!] {
            view.translatesAutoresizingMaskIntoConstraints = false
            cardView.addSubview(view)
        }

        let footerCenterY = footerLabel.centerYAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -Self.footerHeight / 2)
        NSLayoutConstraint.activate([
            footerAppIcon.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            footerAppIcon.centerYAnchor.constraint(equalTo: footerLabel.centerYAnchor),
            footerAppIcon.widthAnchor.constraint(equalToConstant: 14),
            footerAppIcon.heightAnchor.constraint(equalToConstant: 14),
            footerLabel.leadingAnchor.constraint(equalTo: footerAppIcon.trailingAnchor, constant: 6),
            footerCenterY,
            footerPinIcon.leadingAnchor.constraint(greaterThanOrEqualTo: footerLabel.trailingAnchor, constant: 6),
            footerPinIcon.trailingAnchor.constraint(equalTo: shortcutTextView.leadingAnchor, constant: -6),
            footerPinIcon.centerYAnchor.constraint(equalTo: footerLabel.centerYAnchor),
        ])
    }

    private static let relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()

    /// Shows the source app, copy time and pinned state. Called by subclasses from `setupCell`.
    func setupFooter(for historyItem: HistoryItem) {
        let metadata = historyItem.metadata
        var parts = [String]()
        if let bundleId = metadata.sourceBundleId, let name = AppInfo.name(forBundleId: bundleId) {
            parts.append(name)
            footerAppIcon.image = AppInfo.icon(forBundleId: bundleId)
            footerAppIcon.contentTintColor = nil
        }
        else {
            footerAppIcon.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: nil)
            footerAppIcon.contentTintColor = .tertiaryLabelColor
        }
        let age = Date().timeIntervalSince(metadata.copiedAt)
        parts.append(age < 60 ? "Just now" : Self.relativeDateFormatter.localizedString(for: metadata.copiedAt, relativeTo: Date()))
        footerLabel.stringValue = parts.joined(separator: " · ")
        footerPinIcon.isHidden = !metadata.isPinned
    }

    func getShortcutTextViewSize() -> NSSize {
        // Determine the size of the text in one line
        let bRect = shortcutTextView.attributedString().getSingleLineSize()
        return NSSize(width: bRect.width + shortcutTextView.textContainer!.lineFragmentPadding + shortcutTextView.textContainerInset.width * 2, height: bRect.height + shortcutTextView.textContainerInset.height * 2)
    }

    func updateShortcutTextViewContraints() {
        let size = getShortcutTextViewSize()
        shortcutTextView.constraint(withIdentifier: "width")?.constant = ceil(size.width)
        shortcutTextView.constraint(withIdentifier: "height")?.constant = ceil(size.height)
    }

    func setupShortcutTextView(at i: Int) {
        let shortcutStr = NSAttributedString(string: i < 10 ? "⌘\(i)" : "", attributes: Self.shortcutStringAttributes)
        shortcutTextView.attributedText = shortcutStr
        shortcutTextView.isHidden = i >= 10
        updateShortcutTextViewContraints()
        if i >= 10 {
            shortcutTextView.constraint(withIdentifier: "width")?.constant = 0
        }
        applyColors()
    }
}

extension NSFont {

    /// The same font using the rounded system design, if available.
    var rounded: NSFont {
        guard let descriptor = fontDescriptor.withDesign(.rounded) else { return self }
        return NSFont(descriptor: descriptor, size: pointSize) ?? self
    }
}
