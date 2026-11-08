//
//  Cache.swift
//  Magpie
//

import Foundation

/// Cell heights by item, kept separately for each context (such as the column width), so switching between contexts doesn't throw the others away.
///
/// The table's width changes whenever the vertical scroller appears or disappears, e.g. when a filter leaves only a few items. Keeping one context at a time meant every such change re-measured the whole history.
class Cache<Value, ID: Hashable, Context: Hashable> {
    
    private var heights = [Context: [ID: Value]]()
    
    func cellHeight(forId id: ID, withContext context: Context) -> Value? {
        return heights[context]?[id]
    }
    
    func storeCellHeight(_ height: Value, forId id: ID, withContext context: Context) {
        heights[context, default: [:]][id] = height
    }
    
    func removeCellHeight(forId id: ID) {
        for context in heights.keys {
            heights[context]?.removeValue(forKey: id)
        }
    }
    
    func clearCache() {
        heights.removeAll()
    }
}
