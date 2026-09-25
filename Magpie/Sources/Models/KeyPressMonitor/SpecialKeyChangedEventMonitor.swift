//
//  SpecialKeyChangedEventMonitor.swift
//  Magpie
//

import Foundation
import Cocoa

class SpecialKeyChangedEventMonitor: EventMonitor {
    
    init(handler: @escaping (NSEvent) -> Void) {
        super.init(eventTypeMask: .flagsChanged, handler: handler)
    }
}
