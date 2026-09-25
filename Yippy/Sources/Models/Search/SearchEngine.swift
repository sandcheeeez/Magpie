//
//  SearchEngine.swift
//  Yippy
//
//  Created by Matthew Davidson on 6/9/20.
//  Copyright © 2020 MatthewDavidson. All rights reserved.
//

import Foundation
import Cocoa

/// A quick filter shown above the history.
enum HistoryFilter: Int, CaseIterable {
    case all
    case pinned
    case text
    case links
    case images
    case files
    case colors
    
    var title: String {
        switch self {
        case .all: return "All"
        case .pinned: return "Pinned"
        case .text: return "Text"
        case .links: return "Links"
        case .images: return "Images"
        case .files: return "Files"
        case .colors: return "Colors"
        }
    }
    
    var symbolName: String {
        switch self {
        case .all: return "square.stack"
        case .pinned: return "pin"
        case .text: return "text.alignleft"
        case .links: return "link"
        case .images: return "photo"
        case .files: return "doc"
        case .colors: return "paintpalette"
        }
    }
    
    func includes(_ item: HistoryItem) -> Bool {
        switch self {
        case .all: return true
        case .pinned: return item.metadata.isPinned
        case .text: return item.kind == .text
        case .links: return item.kind == .link
        case .images: return item.kind == .image
        case .files: return item.kind == .file
        case .colors: return item.kind == .color
        }
    }
}

/// Filters and ranks history items for a search query.
class SearchEngine {
    
    private let queue = DispatchQueue(label: "SearchEngineQueue", qos: .userInitiated)
    
    /// Incremented for every search, so that results of superseded searches are dropped.
    private var generation = 0
    
    /// Searches `items` in the background and calls `completion` on the main queue, unless a newer search has started.
    ///
    /// Items matching every word keep their history order and come before fuzzy matches, which are ordered by how tightly they matched.
    func search(query rawQuery: String, filter: HistoryFilter, items: [HistoryItem], completion: @escaping ([HistoryItem]) -> Void) {
        generation += 1
        let thisGeneration = generation
        
        let candidates = items.filter({ filter.includes($0) })
        let query = HistoryItem.foldForSearch(rawQuery.trimmingCharacters(in: .whitespacesAndNewlines))
        if query.isEmpty {
            completion(candidates)
            return
        }
        
        // Read everything that touches item data on the main queue.
        let haystacks = candidates.map({ item -> String in
            var text = item.searchableText
            if let recognized = item.metadata.recognizedText, !recognized.isEmpty {
                text += "\n" + HistoryItem.foldForSearch(recognized)
            }
            if let bundleId = item.metadata.sourceBundleId, let name = AppInfo.name(forBundleId: bundleId) {
                text += "\n" + HistoryItem.foldForSearch(name)
            }
            return text
        })
        
        queue.async {
            let words = query.split(separator: " ")
            let matches = haystacks.enumerated().compactMap({ (i, haystack) -> (Int, SearchMatch)? in
                searchMatch(query: query, words: words, haystack: haystack).map({ (i, $0) })
            })
            let ranked = matches
                .sorted(by: { $0.1 != $1.1 ? $0.1 < $1.1 : $0.0 < $1.0 })
                .map({ candidates[$0.0] })
            
            DispatchQueue.main.async {
                if thisGeneration == self.generation {
                    completion(ranked)
                }
            }
        }
    }
}

/// Looks up and caches app names and icons from bundle ids.
enum AppInfo {
    
    private static var names = [String: String?]()
    private static var icons = [String: NSImage?]()
    
    static func url(forBundleId bundleId: String) -> URL? {
        return NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId)
    }
    
    static func name(forBundleId bundleId: String) -> String? {
        if let name = names[bundleId] {
            return name
        }
        let name = url(forBundleId: bundleId).map({ FileManager.default.displayName(atPath: $0.path).replacingOccurrences(of: ".app", with: "") })
        names[bundleId] = name
        return name
    }
    
    static func icon(forBundleId bundleId: String) -> NSImage? {
        if let icon = icons[bundleId] {
            return icon
        }
        let icon = url(forBundleId: bundleId).map({ NSWorkspace.shared.icon(forFile: $0.path) })
        icons[bundleId] = icon
        return icon
    }
}
