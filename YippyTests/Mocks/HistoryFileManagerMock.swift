//
//  HistoryFileManagerMock.swift
//  MagpieTests
//

import XCTest
@testable import Magpie

class HistoryFileManagerMock: HistoryFileManager {
    
    var dataCallCount = 0
    var data = [UUID: [NSPasteboard.PasteboardType: Data]]()
    
    override func loadData(forItemWithId id: UUID, andType type: NSPasteboard.PasteboardType) -> Data? {
        dataCallCount += 1
        if let d = data[id]?[type] {
            return d
        }
        return nil
    }
}
