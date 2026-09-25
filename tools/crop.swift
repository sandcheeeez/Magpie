// Crops the top of a screenshot, optionally placing two side by side (for README images).
import AppKit
// crop.swift <in> <out> <heightFromTop> [<in2> ...]: crops top region; if two inputs, places side by side
let a = CommandLine.arguments
let ch = Int(a[3])!
let ins = [a[1]] + (a.count > 4 ? [a[4]] : [])
let reps = ins.map { NSBitmapImageRep(data: try! Data(contentsOf: URL(fileURLWithPath: $0)))! }
let w = reps[0].pixelsWide
let out = NSImage(size: NSSize(width: w * reps.count + 10 * (reps.count - 1), height: ch), flipped: false) { _ in
  for (i, rep) in reps.enumerated() {
    rep.draw(in: NSRect(x: i * (w + 10), y: 0, width: w, height: ch), from: NSRect(x: 0, y: rep.pixelsHigh - ch, width: w, height: ch), operation: .copy, fraction: 1, respectFlipped: true, hints: nil)
  }
  return true }
try! NSBitmapImageRep(data: out.tiffRepresentation!)!.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: a[2]))
