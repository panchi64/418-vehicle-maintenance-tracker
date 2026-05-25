//
//  Spacing.swift
//  checkpoint
//
//  Design system spacing tokens (4pt base unit)
//

import SwiftUI

enum Spacing {
    /// 4pt - Tight gaps, icon-to-text
    static let xs: CGFloat = 4

    /// 8pt - Related elements
    static let sm: CGFloat = 8

    /// 12pt - Between list items
    static let listItem: CGFloat = 12

    /// 16pt - Standard padding, between sections
    static let md: CGFloat = 16

    /// 20pt - Screen horizontal padding
    static let screenHorizontal: CGFloat = 20

    /// 24pt - Section separation
    static let lg: CGFloat = 24

    /// 32pt - Major sections, screen padding
    static let xl: CGFloat = 32

    /// 48pt - Hero spacing, top of screen
    static let xxl: CGFloat = 48

    /// 56pt - Extra bottom clearance for tab bar overlap
    static let tabBarOffset: CGFloat = 56
}

// MARK: - Screen Padding Modifier

struct ScreenPadding: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, Spacing.screenHorizontal)
    }
}

extension View {
    func screenPadding() -> some View {
        modifier(ScreenPadding())
    }
}
