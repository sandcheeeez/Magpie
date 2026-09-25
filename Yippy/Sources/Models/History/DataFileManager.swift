//
//  DataFileManager.swift
//  Magpie
//

import Foundation

class DataFileManager {
    
    func loadData(contentsOf url: URL) throws -> Data {
        return try Data(contentsOf: url)
    }
    
    func writeData(_ data: Data, to url: URL, options: Data.WritingOptions = []) throws {
        try data.write(to: url, options: options)
    }
}
