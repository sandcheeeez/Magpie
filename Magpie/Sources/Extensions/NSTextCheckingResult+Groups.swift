//
//  NSTextCheckingResult+Groups.swift
//  Magpie
//

import Foundation
import Cocoa

extension NSTextCheckingResult {
    
    /// https://stackoverflow.com/a/51384977
    func groups(testedString:String) -> [String] {
        var groups = [String]()
        for i in  0 ..< self.numberOfRanges
        {
            let group = String(testedString[Range(self.range(at: i), in: testedString)!])
            groups.append(group)
        }
        return groups
    }
}
