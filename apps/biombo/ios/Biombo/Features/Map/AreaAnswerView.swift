import SwiftUI

/// The area's answer, first and heaviest in the sheet (§3). At peek the area
/// name is a quiet SF line; from summary it becomes the postcard line. The
/// trust line under the answer belongs to its first fact; in crisis each of
/// the two clauses carries its own source (V2-Crisis). Everything wraps.
struct AreaAnswerView: View {
    let nearby: NearbyDigest
    let now: Date
    let tier: DisclosureTier

    @Environment(\.locale) private var locale
    @Environment(\.priceUnit) private var unit

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            if !nearby.areaName.isEmpty {
                if tier == .peek {
                    Text(areaTitle)
                        .textRole(.subheadline)
                        .foregroundStyle(Color(.ink2))
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    PostcardStrip(title: Text(areaTitle), motif: nearby.areaRegion.map(PlateMotif.init(region:)))
                }
            }
            VStack(alignment: .leading, spacing: Spacing.s1) {
                ForEach(Array(nearby.facts.enumerated()), id: \.offset) { index, fact in
                    fact.sentence(now: now, unit: unit, locale: locale)
                        .textRole(index == 0 ? .answer : .answerSmall)
                        .foregroundStyle(Color(index == 0 ? .ink : .ink2))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, index > 0 && nearby.isCrisis ? Spacing.s2 : 0)
                    if index == 0 || nearby.isCrisis, let trust = TrustSuffix(fact, now: now) {
                        TrustSuffixLabel(suffix: trust)
                            .padding(.top, 2)
                    }
                }
            }
            .accessibilityElement(children: .combine)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var areaTitle: LocalizedStringResource {
        LocalizedStringResource("\(nearby.areaName) y alrededores", comment: "The area the home answer covers, e.g. 'Guaynabo y alrededores'")
    }
}
