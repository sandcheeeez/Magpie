//
//  DataFileManagerMock.swift
//  MagpieTests
//

import XCTest
@testable import Magpie

class DataFileManagerMock: DataFileManager {
    
    var writeDataSucceeds = [URL: Bool]()
    var loadData = [URL: Data]()
    
    override func writeData(_ data: Data, to url: URL, options: Data.WritingOptions = []) throws {
        if writeDataSucceeds[url] == nil || writeDataSucceeds[url] == false {
            throw NSError(domain: "FileManagerTests", code: 0)
        }
    }
    
    override func loadData(contentsOf url: URL) throws -> Data {
        if let data = loadData[url] {
            return data
        }
        throw NSError(domain: "FileManagerTests", code: 0)
    }
}
