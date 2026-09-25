//
//  ArrayFileManagerMock.swift
//  MagpieTests
//

import XCTest
@testable import Magpie

class ArrayFileManagerMock: ArrayFileManager {
    
    var order: NSArray?
    var shouldReadSucceed = true
    var shouldWriteSucceed = true
    
    override func read() -> NSArray? {
        if shouldReadSucceed {
            return order
        }
        else {
            return nil
        }
    }
    
    override func write(_ array: NSArray) throws {
        if shouldWriteSucceed {
            order = array
        }
        else {
            throw NSError(domain: "Testing skrt", code: 0, userInfo: [:])
        }
    }
}
