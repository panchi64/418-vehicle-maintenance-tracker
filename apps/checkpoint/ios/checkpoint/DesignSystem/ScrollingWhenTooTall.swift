//
//  ScrollingWhenTooTall.swift
//  checkpoint
//
//  Onboarding surfaces are laid out to fit one screen at the default text
//  size. At accessibility sizes they can outgrow it; this keeps the fitted
//  layout when it fits and falls back to scrolling when it doesn't, instead
//  of clipping the buttons at the bottom.
//

import SwiftUI

extension View {
    func scrollingWhenTooTall() -> some View {
        ViewThatFits(in: .vertical) {
            self
            ScrollView {
                self
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}
