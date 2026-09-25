//
//  MagpieItem.swift
//  Magpie
//

import Foundation
import Cocoa

protocol MagpieItem {
    
    static var identifier: NSUserInterfaceItemIdentifier { get }
    
    static func getItemHeight(withYippyTableView magpieTableView: MagpieTableView, forHistoryItem historyItem: HistoryItem) -> CGFloat
    
    func setHighlight(isSelected: Bool)
    
    func setupCell(withYippyTableView magpieTableView: MagpieTableView, forHistoryItem historyItem: HistoryItem, at i: Int)
    
    static func makeItem() -> MagpieItem
}
