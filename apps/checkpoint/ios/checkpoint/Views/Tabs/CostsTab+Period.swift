//
//  CostsTab+Period.swift
//  checkpoint
//
//  The Costs tab's chart view state. The period — the one control, which
//  scopes every number on the screen — is `CostPeriod` (Models/), shared with
//  the App Intents that answer spending questions. See
//  tools/sketchpad/src/screens/CostsTab.tsx for the rationale.
//

import Foundation

extension CostsTab {

    /// What the one chart section draws. Plain chips, not a second segmented
    /// control: the period changes every number, this changes one picture.
    enum ChartMode: CaseIterable, Identifiable {
        case trend
        case category

        var id: Self { self }

        var label: String {
            switch self {
            case .trend: return L10n.costsChartTrend
            case .category: return L10n.costsChartCategory
            }
        }
    }
}
