//
//  NSEdgeInset+Convenience.swift
//  Magpie
//

import Foundation
import Cocoa

extension NSEdgeInsets {
    
    var yTotal: CGFloat {
        return top + bottom
    }
    
    var xTotal: CGFloat {
        return left + right
    }
}
