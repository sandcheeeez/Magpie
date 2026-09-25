//
//  SearchEngine.swift
//  Magpie
//

import Foundation
import Cocoa

/// A quick filter shown above the history: everything, pinned items, one kind of content, or a detected tag.
enum HistoryFilter: Hashable {
    case all
    case pinned
    case kind(HistoryItemKind)
    case tag(String)
    
    /// The filters shown as chips, in order. Tags are chosen from a menu after these.
    static let chips: [HistoryFilter] = [.all, .pinned, .kind(.text), .kind(.code), .kind(.link), .kind(.image), .kind(.file), .kind(.color)]
    
    var title: String {
        switch self {
        case .all: return "All"
        case .pinned: return "Pinned"
        case .kind(.text): return "Text"
        case .kind(.code): return "Code"
        case .kind(.link): return "Links"
        case .kind(.image): return "Images"
        case .kind(.file): return "Files"
        case .kind(.color): return "Colors"
        case .tag(let tag): return tag
        }
    }
    
    var symbolName: String {
        switch self {
        case .all: return "square.stack"
        case .pinned: return "pin"
        case .kind(.text): return "text.alignleft"
        case .kind(.code): return "chevron.left.forwardslash.chevron.right"
        case .kind(.link): return "link"
        case .kind(.image): return "photo"
        case .kind(.file): return "doc"
        case .kind(.color): return "paintpalette"
        case .tag: return "tag"
        }
    }
    
    func includes(_ item: HistoryItem) -> Bool {
        switch self {
        case .all: return true
        case .pinned: return item.isPinned
        case .kind(let kind): return item.kind == kind
        case .tag(let tag): return item.tags.contains(tag)
        }
    }
    
    /// The tags present in `items`, most common first.
    static func tags(in items: [HistoryItem]) -> [(tag: String, count: Int)] {
        var counts = [String: Int]()
        for item in items {
            for tag in item.tags {
                counts[tag, default: 0] += 1
            }
        }
        return counts.map({ ($0.key, $0.value) }).sorted(by: { $0.count != $1.count ? $0.count > $1.count : $0.tag < $1.tag })
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
            if let recognized = item.recognizedText, !recognized.isEmpty {
                text += "\n" + HistoryItem.foldForSearch(recognized)
            }
            if let bundleId = item.sourceBundleId, let name = AppInfo.name(forBundleId: bundleId) {
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
