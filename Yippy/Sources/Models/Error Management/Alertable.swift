//
//  Alertable.swift
//  Magpie
//

import Foundation
import Cocoa

protocol Alertable {
    
    func createAlert() -> NSAlert
    
    func show(with alerter: Alerter)
}

extension Alertable {
    
    func show(with alerter: Alerter) {
        alerter.show(self)
    }
}
