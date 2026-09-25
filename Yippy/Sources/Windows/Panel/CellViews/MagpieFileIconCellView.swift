//
//  MagpieFileIconCellView.swift
//  Magpie
//

import Foundation
import Cocoa

class MagpieFileIconCellView: MagpieItemBaseCellView, MagpieItem {
    
    override class var identifier: NSUserInterfaceItemIdentifier {
        NSUserInterfaceItemIdentifier(Accessibility.identifiers.magpieFileIconCellView)
    }
    static let textContainerInset = NSEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
    static let iconViewPadding = NSEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
    static let iconSize = NSSize(width: 32, height: 32)
    
    var iconView: NSImageView!
    
    override func commonInit() {
        super.commonInit()
        
        iconView = NSImageView(frame: .zero)
        contentView.addSubview(iconView)
        
        setupIconView()
        setupItemTextView()
    }
    
    func setupIconView() {
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.widthAnchor.constraint(equalToConstant: Self.iconSize.width).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: Self.iconSize.height).isActive = true
        iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        contentView.addConstraint(NSLayoutConstraint(item: iconView!, attribute: .leading, relatedBy: .equal, toItem: contentView, attribute: .leading, multiplier: 1, constant: Self.iconViewPadding.left))
    }
    
    func setupItemTextView() {
        itemTextView.translatesAutoresizingMaskIntoConstraints = false
        itemTextView.usingEdgeInsets = true
        itemTextView.textInset = Self.textContainerInset
        itemTextView.textContainer?.lineFragmentPadding = 0
        itemTextView.isVerticallyResizable = false
        itemTextView.isHorizontallyResizable = false
        contentView.addConstraint(NSLayoutConstraint(item: itemTextView!, attribute: .leading, relatedBy: .equal, toItem: iconView, attribute: .trailing, multiplier: 1, constant: Self.iconViewPadding.right))
        contentView.addConstraint(NSLayoutConstraint(item: contentView!, attribute: .trailing, relatedBy: .equal, toItem: itemTextView, attribute: .trailing, multiplier: 1, constant: 0))
        itemTextView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        itemTextView.heightAnchor.constraint(equalToConstant: 0, withIdentifier: "height")?.isActive = true
    }
    
    func setupCell(withYippyTableView magpieTableView: MagpieTableView, forHistoryItem historyItem: HistoryItem, at i: Int) {
        iconView.image = historyItem.getFileIcon()
        setupShortcutTextView(at: i)
        setupFooter(for: historyItem)
        itemTextView.attributedText = formatFileUrl(historyItem.getFileUrl()!)
        itemTextView.constraint(withIdentifier: "height")?.constant = Self.getFileNameTextViewHeight(withCellWidth: floor(magpieTableView.cellWidth), forHistoryItem: historyItem)
        setHighlight(isSelected: magpieTableView.isRowSelected(i))
    }
    
    static func getItemHeight(withYippyTableView magpieTableView: MagpieTableView, forHistoryItem historyItem: HistoryItem) -> CGFloat {
        // Calculate the width of the cell
        let cellWidth = floor(magpieTableView.cellWidth)
        
        // Calculate the text view height
        let textViewHeight = getFileNameTextViewHeight(withCellWidth: cellWidth, forHistoryItem: historyItem)
        
        // Calculate minimum cell height
        let minCellHeight = iconSize.height + contentViewInsets.yTotal + iconViewPadding.yTotal
        
        // Add the padding back to get the height of the cell
        let height = max(textViewHeight + contentViewInsets.yTotal, minCellHeight)
        
        return ceil(height)
    }
    
    static func getFileNameTextViewHeight(withCellWidth cellWidth: CGFloat, forHistoryItem historyItem: HistoryItem) -> CGFloat {
        // Calculate the width of the text container
        let width = cellWidth - contentViewInsets.xTotal - iconSize.width - textContainerInset.xTotal - iconViewPadding.xTotal
        
        // Create an attributed string of the text
        let attrStr = formatFileUrl(historyItem.getFileUrl()!)
        
        // Get the max height of the text container
        let maxTextContainerHeight = Constants.panel.maxCellHeight - contentViewInsets.yTotal - textContainerInset.yTotal
        
        // Determine the height of the text view (capping the cell height)
        let estHeight = attrStr.calculateSize(withMaxWidth: width).height
        
        return min(estHeight, maxTextContainerHeight) + textContainerInset.yTotal
    }
    
    static func makeItem() -> MagpieItem {
        return MagpieFileIconCellView(frame: .zero)
    }
}
