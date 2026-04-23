#!/usr/bin/env swift
// Generates a 1024×1024 PNG app icon for Biombo: cerulean canvas with an
// off-white "B" wordmark. Draws directly into a CGContext at pixel scale 1
// so the output is truly 1024×1024 (no Retina doubling) and fully opaque.
import AppKit
import CoreGraphics
import CoreText
import Foundation

let size = 1024
let cerulean = CGColor(red: 0x00/255.0, green: 0x33/255.0, blue: 0xBE/255.0, alpha: 1)
let offWhite = CGColor(red: 0xF5/255.0, green: 0xF0/255.0, blue: 0xDC/255.0, alpha: 1)

let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
let context = CGContext(
    data: nil,
    width: size,
    height: size,
    bitsPerComponent: 8,
    bytesPerRow: size * 4,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
)!

context.setFillColor(cerulean)
context.fill(CGRect(x: 0, y: 0, width: size, height: size))

let frameInset: CGFloat = 40
context.setStrokeColor(offWhite)
context.setLineWidth(16)
context.stroke(CGRect(
    x: frameInset,
    y: frameInset,
    width: CGFloat(size) - frameInset * 2,
    height: CGFloat(size) - frameInset * 2
))

let font = CTFontCreateWithName("Menlo-Bold" as CFString, 640, nil)
let attrs: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: NSColor(cgColor: offWhite) as Any
]
let letter = NSAttributedString(string: "B", attributes: attrs)
let line = CTLineCreateWithAttributedString(letter)
let bounds = CTLineGetImageBounds(line, context)
context.textPosition = CGPoint(
    x: (CGFloat(size) - bounds.width) / 2 - bounds.origin.x,
    y: (CGFloat(size) - bounds.height) / 2 - bounds.origin.y
)
CTLineDraw(line, context)

guard let cgImage = context.makeImage() else {
    FileHandle.standardError.write("failed to snapshot CGContext\n".data(using: .utf8)!)
    exit(1)
}

let args = CommandLine.arguments
guard args.count >= 2 else {
    FileHandle.standardError.write("usage: generate_biombo_icon.swift <output.png>\n".data(using: .utf8)!)
    exit(1)
}
let url = URL(fileURLWithPath: args[1]) as CFURL

guard let dest = CGImageDestinationCreateWithURL(url, "public.png" as CFString, 1, nil) else {
    FileHandle.standardError.write("couldn't open destination\n".data(using: .utf8)!)
    exit(2)
}
CGImageDestinationAddImage(dest, cgImage, nil)
if !CGImageDestinationFinalize(dest) {
    FileHandle.standardError.write("couldn't write png\n".data(using: .utf8)!)
    exit(3)
}

print("wrote \(args[1]) — \(cgImage.width)×\(cgImage.height)")
