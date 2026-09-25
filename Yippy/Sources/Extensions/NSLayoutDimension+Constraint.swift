//
//  NSLayoutDimension+Constraint.swift
//  Magpie
//

import Foundation
import Cocoa

extension NSLayoutDimension {
    
    // https://stackoverflow.com/a/39111696
    
    @objc func constraint(equalToConstant constant: CGFloat, withIdentifier identifier: String) -> NSLayoutConstraint! {
        let constraint = self.constraint(equalToConstant: constant)
        constraint.identifier = identifier
        return constraint
    }
}
