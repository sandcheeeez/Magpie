//
//  KeyDownEventMonitor.swift
//  Magpie
//

import Foundation
import Cocoa

class KeyDownEventMonitor: EventMonitor {
    
    init(handler: @escaping (NSEvent) -> Void) {
        super.init(eventTypeMask: .keyDown, handler: handler)
    }
}
