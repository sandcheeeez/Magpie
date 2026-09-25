//
//  ArrayFileManager.swift
//  Magpie
//

import Foundation

class ArrayFileManager {
    
    var url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    func write(_ array: NSArray) throws {
        try Self.write(array, toUrl: url)
    }
    
    func read() -> NSArray? {
        Self.read(fromUrl: url)
    }
    
    static func write(_ array: NSArray, toUrl url: URL) throws {
        try array.write(to: url)
    }
    
    static func read(fromUrl url: URL) -> NSArray? {
        return NSArray(contentsOf: url)
    }
}
