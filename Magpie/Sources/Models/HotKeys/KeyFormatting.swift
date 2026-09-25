//
//  KeyFormatting.swift
//  Magpie
//

import Foundation
import AppKit
import HotKey

// Helpers for recording and displaying keyboard shortcuts.

func filterModifiers(_ modifiers: NSEvent.ModifierFlags) -> NSEvent.ModifierFlags {
    var mods = NSEvent.ModifierFlags.init()
    
    if modifiers.contains(.command) {
        mods = mods.union(.command)
    }
    if modifiers.contains(.control) {
        mods = mods.union(.control)
    }
    if modifiers.contains(.option) {
        mods = mods.union(.option)
    }
    if modifiers.contains(.shift) {
        mods = mods.union(.shift)
    }
    
    return mods
}

func isFunctionKey(key: Key) -> Bool {
    return [.f1, .f2, .f1, .f2, .f3, .f4, .f5, .f6, .f7, .f8, .f9, .f10, .f11, .f12].contains(key)
}

func filterKeys(_ keys: [Key]) -> [Key] {
    return keys.filter {
        [
            .a,
            .s,
            .d,
            .f,
            .h,
            .g,
            .z,
            .x,
            .c,
            .v,
            .b,
            .q,
            .w,
            .e,
            .r,
            .y,
            .t,
            .one,
            .two,
            .three,
            .four,
            .six,
            .five,
            .equal,
            .nine,
            .seven,
            .minus,
            .eight,
            .zero,
            .rightBracket,
            .o,
            .u,
            .leftBracket,
            .i,
            .p,
            .l,
            .j,
            .quote,
            .k,
            .semicolon,
            .backslash,
            .comma,
            .slash,
            .n,
            .m,
            .f1,
            .f2,
            .f3,
            .f4,
            .f5,
            .f6,
            .f7,
            .f8,
            .f9,
            .f10,
            .f11,
            .f12,
            .period,
            .grave
        ].contains($0)
    }
}

func stringifyKeys(_ keys: [Key]) -> [String] {
    return keys.map { $0.title ?? "Unknown key" }
}

extension Key {
    var title: String? {
        switch self {
        case .a:
            return "A"
        case .s:
            return "S"
        case .d:
            return "D"
        case .f:
            return "F"
        case .h:
            return "H"
        case .g:
            return "G"
        case .z:
            return "Z"
        case .x:
            return "X"
        case .c:
            return "C"
        case .v:
            return "V"
        case .b:
            return "B"
        case .q:
            return "Q"
        case .w:
            return "W"
        case .e:
            return "E"
        case .r:
            return "R"
        case .y:
            return "Y"
        case .t:
            return "T"
        case .one:
            return "1"
        case .two:
            return "2"
        case .three:
            return "3"
        case .four:
            return "4"
        case .six:
            return "6"
        case .five:
            return "5"
        case .equal:
            return "="
        case .nine:
            return "9"
        case .seven:
            return "7"
        case .minus:
            return "-"
        case .eight:
            return "8"
        case .zero:
            return "0"
        case .rightBracket:
            return "]"
        case .o:
            return "O"
        case .u:
            return "U"
        case .leftBracket:
            return "["
        case .i:
            return "I"
        case .p:
            return "P"
        case .l:
            return "L"
        case .j:
            return "J"
        case .quote:
            return "\""
        case .k:
            return "K"
        case .semicolon:
            return ";"
        case .backslash:
            return "\\"
        case .comma:
            return ","
        case .slash:
            return "/"
        case .n:
            return "N"
        case .m:
            return "M"
        case .period:
            return "."
        case .return:
            return "↩"
        case .tab:
            return "⇥"
        case .space:
            return "Space"
        case .delete:
            return "⌫"
        case .escape:
            return "⎋"
        case .command:
            return nil
        case .shift:
            return nil
        case .capsLock:
            return nil
        case .option:
            return nil
        case .control:
            return nil
        case .rightCommand:
            return nil
        case .rightShift:
            return nil
        case .rightOption:
            return nil
        case .rightControl:
            return nil
        case .function:
            return "Fn"
        case .f17:
            return nil
        case .volumeUp:
            return nil
        case .volumeDown:
            return nil
        case .mute:
            return nil
        case .f18:
            return nil
        case .f19:
            return nil
        case .f20:
            return nil
        case .f5:
            return "F5"
        case .f6:
            return "F6"
        case .f7:
            return "F7"
        case .f3:
            return "F3"
        case .f8:
            return "F8"
        case .f9:
            return "F9"
        case .f11:
            return "F11"
        case .f13:
            return nil
        case .f16:
            return nil
        case .f14:
            return nil
        case .f10:
            return "F10"
        case .f12:
            return "F12"
        case .f15:
            return nil
        case .help:
            return nil
        case .home:
            return nil
        case .pageUp:
            return nil
        case .forwardDelete:
            return nil
        case .f4:
            return "F4"
        case .end:
            return nil
        case .f2:
            return "F2"
        case .pageDown:
            return nil
        case .f1:
            return "F1"
        case .leftArrow:
            return nil
        case .rightArrow:
            return nil
        case .downArrow:
            return nil
        case .upArrow:
            return nil
        case .grave:
            return "`"
        default:
            return nil
        }
    }
}
