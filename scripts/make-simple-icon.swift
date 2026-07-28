#!/usr/bin/env swift
// Bake the standard macOS rounded-panel shape into the simple app icon once (T-178),
// so the app doesn't have to round it at every launch. Reads the square master
// Bundle/simple.png and writes the rounded, padded, transparent-field resource
// Bundle/AppIcon-simple.png. Re-run this if simple.png changes.
//
//   swift scripts/make-simple-icon.swift
import AppKit

let root = FileManager.default.currentDirectoryPath
let src = URL(fileURLWithPath: "\(root)/Bundle/simple.png")
let dst = URL(fileURLWithPath: "\(root)/Bundle/AppIcon-simple.png")

guard let raw = NSImage(contentsOf: src) else {
    FileHandle.standardError.write(Data("error: cannot read Bundle/simple.png\n".utf8)); exit(1)
}

// Apple's icon grid: ~824/1024 body with ~185/1024 corner radius, centered on a
// transparent 1024 canvas.
let canvas: CGFloat = 1024, inset: CGFloat = 100
let panel = NSRect(x: inset, y: inset, width: canvas - 2 * inset, height: canvas - 2 * inset)
let radius = 185.0 * (panel.width / 824.0)

let out = NSImage(size: NSSize(width: canvas, height: canvas))
out.lockFocus()
NSBezierPath(roundedRect: panel, xRadius: radius, yRadius: radius).addClip()
raw.draw(in: panel, from: .zero, operation: .sourceOver, fraction: 1)
out.unlockFocus()

guard let tiff = out.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write(Data("error: PNG encode failed\n".utf8)); exit(1)
}
try png.write(to: dst)
print("wrote \(dst.path)")
