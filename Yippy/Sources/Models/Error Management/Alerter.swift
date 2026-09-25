//
//  Alerter.swift
//  Magpie
//

import Foundation
import Cocoa

class Alerter {
    
    static var general = Alerter()
    
    func show(_ alertable: Alertable) {
        DispatchQueue.main.async {
            alertable.createAlert().runModal()
        }
    }
}
