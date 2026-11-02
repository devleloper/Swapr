#!/usr/bin/env swift
// Renders the Swapr app icon into Swapr/Resources/Assets.xcassets/AppIcon.appiconset.
// Usage: swift scripts/make-icon.swift
import AppKit

let canvas: CGFloat = 1024

func renderIcon() -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(canvas), pixelsHigh: Int(canvas),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    // macOS icon grid: 824 pt body centered on a 1024 canvas.
    let body = NSRect(x: 100, y: 100, width: 824, height: 824)
    let shape = NSBezierPath(roundedRect: body, xRadius: 185, yRadius: 185)

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
    shadow.shadowOffset = NSSize(width: 0, height: -10)
    shadow.shadowBlurRadius = 24
    shadow.set()
    NSColor.black.setFill()
    shape.fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGradient(
        starting: NSColor(srgbRed: 0.40, green: 0.47, blue: 1.00, alpha: 1),
        ending: NSColor(srgbRed: 0.27, green: 0.18, blue: 0.80, alpha: 1)
    )!.draw(in: shape, angle: -90)

    drawKeycap(letter: "A", center: NSPoint(x: 400, y: 600), tint: .white)
    drawKeycap(letter: "Я", center: NSPoint(x: 624, y: 424), tint: NSColor(srgbRed: 0.93, green: 0.94, blue: 1, alpha: 1))

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

func drawKeycap(letter: String, center: NSPoint, tint: NSColor) {
    let size: CGFloat = 300
    let rect = NSRect(x: center.x - size / 2, y: center.y - size / 2, width: size, height: size)
    let cap = NSBezierPath(roundedRect: rect, xRadius: 64, yRadius: 64)

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor(srgbRed: 0.10, green: 0.05, blue: 0.40, alpha: 0.45)
    shadow.shadowOffset = NSSize(width: 0, height: -18)
    shadow.shadowBlurRadius = 30
    shadow.set()
    tint.setFill()
    cap.fill()
    NSGraphicsContext.restoreGraphicsState()

    let font = NSFont.systemFont(ofSize: 180, weight: .bold)
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor(srgbRed: 0.27, green: 0.20, blue: 0.82, alpha: 1),
    ]
    let text = NSAttributedString(string: letter, attributes: attributes)
    let bounds = text.size()
    text.draw(at: NSPoint(x: center.x - bounds.width / 2, y: center.y - bounds.height / 2 + 4))
}

let output = URL(fileURLWithPath: "Swapr/Resources/Assets.xcassets/AppIcon.appiconset", isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

let master = renderIcon()
let entries: [(points: Int, scale: Int)] = [(16, 1), (16, 2), (32, 1), (32, 2), (128, 1), (128, 2), (256, 1), (256, 2), (512, 1), (512, 2)]
var images: [[String: String]] = []

for entry in entries {
    let pixels = entry.points * entry.scale
    let name = "icon_\(entry.points)x\(entry.points)\(entry.scale == 2 ? "@2x" : "").png"
    let scaled = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: scaled)
    NSGraphicsContext.current?.imageInterpolation = .high
    master.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels))
    NSGraphicsContext.restoreGraphicsState()
    try scaled.representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent(name))
    images.append(["idiom": "mac", "size": "\(entry.points)x\(entry.points)", "scale": "\(entry.scale)x", "filename": name])
}

let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
let json = try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
try json.write(to: output.appendingPathComponent("Contents.json"))
print("Wrote \(images.count) icons to \(output.path)")
