//
//  MagpieHotKeys.swift
//  Magpie
//

import Foundation

struct MagpieHotKeys {
    
    static var toggle = MagpieHotKey(key: .v, modifiers: [.command, .shift])
    static var `return` = MagpieHotKey(key: .return, modifiers: [])
    static var escape = MagpieHotKey(key: .escape, modifiers: [])
    static var downArrow = MagpieHotKey(key: .downArrow, modifiers: [])
    static var upArrow = MagpieHotKey(key: .upArrow, modifiers: [])
    static var leftArrow = MagpieHotKey(key: .leftArrow, modifiers: [])
    static var rightArrow = MagpieHotKey(key: .rightArrow, modifiers: [])
    static var pageDown = MagpieHotKey(key: .pageDown, modifiers: [])
    static var pageUp = MagpieHotKey(key: .pageUp, modifiers: [])
    static var ctrlAltCmdLeftArrow = MagpieHotKey(key: .leftArrow, modifiers: [.control, .option, .command])
    static var ctrlAltCmdRightArrow = MagpieHotKey(key: .rightArrow, modifiers: [.control, .option, .command])
    static var ctrlAltCmdDownArrow = MagpieHotKey(key: .downArrow, modifiers: [.control, .option, .command])
    static var ctrlAltCmdUpArrow = MagpieHotKey(key: .upArrow, modifiers: [.control, .option, .command])
    static var ctrlDelete = MagpieHotKey(key: .delete, modifiers: [.control])
    static var ctrlSpace = MagpieHotKey(key: .space, modifiers: [.control])
    static var cmdBackslash = MagpieHotKey(key: .backslash, modifiers: [.command])
    static var cmdReturn = MagpieHotKey(key: .return, modifiers: [.command])
    static var cmdP = MagpieHotKey(key: .p, modifiers: [.command])
    static var cmdLeftArrow = MagpieHotKey(key: .leftArrow, modifiers: [.command])
    static var cmdRightArrow = MagpieHotKey(key: .rightArrow, modifiers: [.command])
    
    static var cmd0 = MagpieHotKey(key: .zero, modifiers: [.command])
    static var cmd1 = MagpieHotKey(key: .one, modifiers: [.command])
    static var cmd2 = MagpieHotKey(key: .two, modifiers: [.command])
    static var cmd3 = MagpieHotKey(key: .three, modifiers: [.command])
    static var cmd4 = MagpieHotKey(key: .four, modifiers: [.command])
    static var cmd5 = MagpieHotKey(key: .five, modifiers: [.command])
    static var cmd6 = MagpieHotKey(key: .six, modifiers: [.command])
    static var cmd7 = MagpieHotKey(key: .seven, modifiers: [.command])
    static var cmd8 = MagpieHotKey(key: .eight, modifiers: [.command])
    static var cmd9 = MagpieHotKey(key: .nine, modifiers: [.command])
}
