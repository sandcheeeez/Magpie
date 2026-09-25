//
//  MagpieTiffCellView.swift
//  Magpie
//

import Foundation
import Cocoa

class MagpieTiffCellView: MagpieItemBaseCellView, MagpieItem {
    
    override class var identifier: NSUserInterfaceItemIdentifier {
        NSUserInterfaceItemIdentifier(Accessibility.identifiers.magpieTiffCellView)
    }
    
    static let imagePadding = NSEdgeInsetsZero
    
    var tiffView: NSImageView!
    
    override func commonInit() {
        super.commonInit()
        
        tiffView = NSImageView(frame: .zero)
        contentView.addSubview(tiffView)
        
        setupTiffView()
    }
    
    func setupTiffView() {
        tiffView.translatesAutoresizingMaskIntoConstraints = false
        tiffView.imageAlignment = .alignCenter
        contentView.addConstraint(NSLayoutConstraint(item: tiffView!, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1, constant: Self.imagePadding.top))
        contentView.addConstraint(NSLayoutConstraint(item: tiffView!, attribute: .leading, relatedBy: .equal, toItem: contentView, attribute: .leading, multiplier: 1, constant: Self.imagePadding.left))
        contentView.addConstraint(NSLayoutConstraint(item: contentView!, attribute: .trailing, relatedBy: .equal, toItem: tiffView, attribute: .trailing, multiplier: 1, constant: Self.imagePadding.right))
        contentView.addConstraint(NSLayoutConstraint(item: contentView!, attribute: .bottom, relatedBy: .equal, toItem: tiffView, attribute: .bottom, multiplier: 1, constant: Self.imagePadding.bottom))
    }
    
    func setupCell(withYippyTableView magpieTableView: MagpieTableView, forHistoryItem historyItem: HistoryItem, at i: Int) {
        setupShortcutTextView(at: i)
        setupFooter(for: historyItem)
        setHighlight(isSelected: magpieTableView.isRowSelected(i))
        tiffView.image = historyItem.getImage()
    }
    
    static func getItemHeight(withYippyTableView magpieTableView: MagpieTableView, forHistoryItem historyItem: HistoryItem) -> CGFloat {
        // Calculate the width of the cell
        let cellWidth = floor(magpieTableView.cellWidth)
        
        // TODO: Need placeholder or something
        guard let image = historyItem.getImage() else {
            return 50
        }
        
        let imageWidth = cellWidth - imagePadding.xTotal - contentViewInsets.xTotal
        
        // Get max image height based on pixels
        let maxImageHeight = image.size.height
        // Calcalute image height
        let imageHeight = min(image.size.height * imageWidth / image.size.width, maxImageHeight)
        
        // Get max height of cell based on visible on visible height
        let maxHeight = magpieTableView.visibleRect.height
        // Calculate cell height
        let height = min(imageHeight + imagePadding.yTotal + contentViewInsets.xTotal, maxHeight)
        
        return ceil(height)
    }
    
    static func makeItem() -> MagpieItem {
        return MagpieTiffCellView(frame: .zero)
    }
}
