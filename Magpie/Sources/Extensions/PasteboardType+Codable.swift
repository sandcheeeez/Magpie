//
//  PasteboardType+Codable.swift
//  Magpie
//

import Foundation
import Cocoa

extension NSPasteboard.PasteboardType: Codable {
    // Literally don't need to do anything
}

extension NSPasteboard.PasteboardType {
    
    static var defaultTypes: [NSPasteboard.PasteboardType] {
        return [.color, .fileContents, .fileURL, .fileURL, .findPanelSearchOptions, .font, .html, .multipleTextSelection, .pdf, .png, .rtf, .rtfd, .ruler, .sound, .string, .tabularText, .textFinderOptions, .tiff, .URL]
    }
}
