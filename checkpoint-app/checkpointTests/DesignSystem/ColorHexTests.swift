//
//  ColorHexTests.swift
//  checkpointTests
//

import XCTest
import SwiftUI
@testable import checkpoint

final class ColorHexTests: XCTestCase {

    // Helper to extract RGBA components from a Color
    private func components(of color: Color) -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b, a)
    }

    func testHex6WithHash() {
        let color = Color(hex: "#FF0000")
        let c = components(of: color)
        XCTAssertEqual(c.r, 1.0, accuracy: 0.01)
        XCTAssertEqual(c.g, 0.0, accuracy: 0.01)
        XCTAssertEqual(c.b, 0.0, accuracy: 0.01)
        XCTAssertEqual(c.a, 1.0, accuracy: 0.01)
    }

    func testHex6WithoutHash() {
        let color = Color(hex: "00FF00")
        let c = components(of: color)
        XCTAssertEqual(c.r, 0.0, accuracy: 0.01)
        XCTAssertEqual(c.g, 1.0, accuracy: 0.01)
        XCTAssertEqual(c.b, 0.0, accuracy: 0.01)
    }

    func testHex8WithAlpha() {
        let color = Color(hex: "#FF000080")
        let c = components(of: color)
        XCTAssertEqual(c.r, 1.0, accuracy: 0.01)
        XCTAssertEqual(c.a, 128.0/255.0, accuracy: 0.02)
    }

    func testHex8WithoutHash() {
        let color = Color(hex: "0000FF80")
        let c = components(of: color)
        XCTAssertEqual(c.b, 1.0, accuracy: 0.01)
        XCTAssertEqual(c.a, 128.0/255.0, accuracy: 0.02)
    }

    func testBlack() {
        let color = Color(hex: "#000000")
        let c = components(of: color)
        XCTAssertEqual(c.r, 0.0, accuracy: 0.01)
        XCTAssertEqual(c.g, 0.0, accuracy: 0.01)
        XCTAssertEqual(c.b, 0.0, accuracy: 0.01)
    }

    func testWhite() {
        let color = Color(hex: "#FFFFFF")
        let c = components(of: color)
        XCTAssertEqual(c.r, 1.0, accuracy: 0.01)
        XCTAssertEqual(c.g, 1.0, accuracy: 0.01)
        XCTAssertEqual(c.b, 1.0, accuracy: 0.01)
    }
}
