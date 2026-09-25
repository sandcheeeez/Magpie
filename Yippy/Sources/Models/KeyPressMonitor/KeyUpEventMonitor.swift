//
//  KeyUpEventMonitor.swift
//  Magpie
//

import Foundation
import Cocoa

class KeyUpEventMonitor: EventMonitor {
    
    init(handler: @escaping (NSEvent) -> Void) {
        super.init(eventTypeMask: .keyUp, handler: handler)
    }
}
