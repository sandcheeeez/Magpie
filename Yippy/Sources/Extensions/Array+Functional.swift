//
//  Array+Functional.swift
//  Magpie
//

import Foundation

extension Array {
    
    func with(elementAppened element: Element) -> Array {
        var copy = self
        copy.append(element)
        return copy
    }
    
    func with(element: Element, insertedAt i: Int) -> Array {
        var copy = self
        copy.insert(element, at: i)
        return copy
    }
    
    func without(elementAt i: Int) -> Array {
        var copy = self
        copy.remove(at: i)
        return copy
    }
}
