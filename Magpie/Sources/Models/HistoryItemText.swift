//
//  HistoryItemText.swift
//  Magpie
//

import Foundation
import Cocoa

struct HistoryItemText {
    
    static let itemStringAttributes: [NSAttributedString.Key: Any] = [
        .font: Constants.fonts.magpiePlainText,
        .foregroundColor: NSColor.textColor
    ]
    
    static func getString(forItem item: HistoryItem) -> String {
        if let plainStr = item.getPlainString() {
            return plainStr
        }
        else if let attrStr = item.getRtfAttributedString() {
            return attrStr.string
        }
        else if let htmlStr = item.getHtmlRawString() {
            return htmlStr
        }
        else if let url = item.getFileUrl() {
            return url.path
        }
        else if let color = item.getColor()?.usingColorSpace(.sRGB) {
            return String(format: "#%02X%02X%02X", Int(round(color.redComponent * 255)), Int(round(color.greenComponent * 255)), Int(round(color.blueComponent * 255)))
        }
        else {
            return "Unknown format"
        }
    }
    
    static func getAttributedString(forItem item: HistoryItem, usingItemRtf: Bool = true) -> NSAttributedString {
        if usingItemRtf {
            if let attrStr = item.getRtfAttributedString() {
                return attrStr
            }
        }
        
        return NSAttributedString(string: getString(forItem: item), attributes: itemStringAttributes)
    }
}
