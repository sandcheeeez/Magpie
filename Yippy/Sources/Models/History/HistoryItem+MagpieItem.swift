//
//  HistoryItem+MagpieItem.swift
//  Magpie
//

import Foundation

extension HistoryItem {
    
    func getTableViewItemType() -> MagpieItem.Type {
        if getFileUrl() != nil {
            if getThumbnailImage() != nil {
                return MagpieFileThumbnailCellView.self
            }
            else {
                return MagpieFileIconCellView.self
            }
        }
        else if getColor() != nil {
            return MagpieColorCellView.self
        }
        else if types.contains(.tiff) || types.contains(.png) {
            return MagpieTiffCellView.self
        }
        else {
            return MagpieTextCellView.self
        }
    }
}
