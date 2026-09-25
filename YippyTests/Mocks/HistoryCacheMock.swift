//
//  HistoryCacheMock.swift
//  MagpieTests
//

import XCTest
@testable import Magpie

class HistoryCacheMock: HistoryCache {
    
    var data: Data?
    
    var dataCallCount = 0
    
    override func data(withId id: UUID, forType type: NSPasteboard.PasteboardType) -> Data? {
        dataCallCount += 1
        return data
    }
}
