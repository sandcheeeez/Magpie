//
//  LoginItem.swift
//  Magpie
//

import Foundation
import ServiceManagement

/// Registers Yippy as a login item using `SMAppService`.
enum LoginItem {
    
    static var isEnabled: Bool {
        return SMAppService.mainApp.status == .enabled
    }
    
    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            }
            else {
                try SMAppService.mainApp.unregister()
            }
            return true
        }
        catch {
            YippyError(localizedDescription: "Failed to \(enabled ? "enable" : "disable") launch at login: \(error.localizedDescription)").log(with: ErrorLogger.general)
            return false
        }
    }
}
