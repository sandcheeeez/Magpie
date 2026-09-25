//
//  HistoryItem+YippyItem.swift
//  Magpie
//

import Foundation

extension HistoryItem {
    
    func getTableViewItemType() -> YippyItem.Type {
        if getFileUrl() != nil {
            if getThumbnailImage() != nil {
                return YippyFileThumbnailCellView.self
            }
            else {
                return YippyFileIconCellView.self
            }
        }
        else if getColor() != nil {
            return YippyColorCellView.self
        }
        else if types.contains(.tiff) || types.contains(.png) {
            return YippyTiffCellView.self
        }
        else {
            return YippyTextCellView.self
        }
    }
}
