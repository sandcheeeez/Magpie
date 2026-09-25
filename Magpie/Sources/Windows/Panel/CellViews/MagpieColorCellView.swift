//
//  MagpieColorCellView.swift
//  Magpie
//

import Foundation
import Cocoa

class MagpieColorCellView: MagpieTextCellView {
    
    override class var identifier: NSUserInterfaceItemIdentifier {
        return NSUserInterfaceItemIdentifier(Accessibility.identifiers.magpieColorCellView)
    }
    
    override func commonInit() {
        super.commonInit()
        
        contentView.usesDynamicBackgroundColor = false
    }
    
    override func setupCell(withYippyTableView magpieTableView: MagpieTableView, forHistoryItem historyItem: HistoryItem, at i: Int) {
        super.setupCell(withYippyTableView: magpieTableView, forHistoryItem: historyItem, at: i)
        
        if let color = historyItem.getColor()?.withAlphaComponent(1) {
            contentView.layer?.backgroundColor = color.cgColor
        }
    }
    
    override class func makeItem() -> MagpieItem {
        return MagpieColorCellView(frame: .zero)
    }
}
