//
//  ServiceCategoryIcon.swift
//  checkpoint
//
//  The category glyph at the top of the log and visit detail headers. Shared
//  so the two headers can't drift apart. Decorative: the header's text already
//  names what the record is.
//

import SwiftUI

struct ServiceCategoryIcon: View {
    let category: CostCategory?

    var body: some View {
        Image(systemName: category?.icon ?? "wrench.and.screwdriver")
            .font(.title.weight(.medium))
            .foregroundStyle(category?.color ?? Theme.accent)
            .accessibilityHidden(true)
    }
}
