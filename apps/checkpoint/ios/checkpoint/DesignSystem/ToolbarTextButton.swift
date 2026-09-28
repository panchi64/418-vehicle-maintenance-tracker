//
//  ToolbarTextButton.swift
//  checkpoint
//
//  A toolbar action that reads as a word today: Edit, Select, Save, Share (2).
//
//  WHY IT CARRIES A SYMBOL IT DOESN'T DRAW. Where a regular-width scene moves
//  toolbar items into a vertical bar (the foldable iPhone's inner display),
//  the system keeps only items that have BOTH a title and a system image;
//  title-only and custom-view items are dropped. So every toolbar button is a
//  `Label(title, systemImage:)`. In the ordinary horizontal bar this one is
//  drawn `.titleOnly`, so compact width looks exactly as it did with a plain
//  text button.
//
//  Icon-only toolbar buttons need nothing extra: pass a `Label` (or
//  `Button(_:systemImage:action:)`) and the toolbar draws its icon by default.
//

import SwiftUI

struct ToolbarTextButton: View {
    let title: String
    let systemImage: String
    var role: ButtonRole?
    let action: () -> Void

    init(
        _ title: String,
        systemImage: String,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.role = role
        self.action = action
    }

    var body: some View {
        Button(title, systemImage: systemImage, role: role, action: action)
            .labelStyle(.titleOnly)
    }
}
