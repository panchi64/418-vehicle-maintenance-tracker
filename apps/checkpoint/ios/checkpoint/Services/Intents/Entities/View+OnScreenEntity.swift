//
//  View+OnScreenEntity.swift
//  checkpoint
//
//  Tags a screen with the entity it shows, so Siri and Apple Intelligence can
//  act on "this" ("mark this done", "share this") — the SwiftUI
//  `.appEntityIdentifier` modifier (iOS 18.4), wrapped so views don't import
//  AppIntents or spell out `EntityIdentifier`. Harmless where Apple
//  Intelligence is off: the tag is metadata nothing reads.
//

import AppIntents
import SwiftUI

extension View {
    func onScreenEntity<Entity: ModelBackedEntity>(_ type: Entity.Type, id: UUID) -> some View {
        appEntityIdentifier(EntityIdentifier(for: type, identifier: id))
    }
}
