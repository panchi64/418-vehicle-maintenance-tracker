import SwiftUI

/// "Detalles de…" (PRODUCT.md §3 depth): what makes the answer complete.
/// The price chart and DACO's reference with its source line for stations,
/// the 90-day record for chargers, polygon confidence for areas, then what
/// the owner posted, the reports behind the answer and, on request, older ones.
struct PlaceDepthView: View {
    let detail: PlaceDetail

    @State private var isStaleRevealed = false
    @Environment(\.locale) private var locale
    @Environment(\.priceUnit) private var unit

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s8) {
                if let trend = detail.trend {
                    SectionGroup(title: LocalizedStringResource("Precio en 30 días", comment: "Depth section: the station's price chart")) {
                        PriceTrendChart(trend: trend).padding(.vertical, Spacing.s3)
                    }
                }
                if let reference = detail.ladder?.reference {
                    DacoReferenceGroup(reference: reference)
                }
                if let tally = detail.tally {
                    SectionGroup(title: LocalizedStringResource("Confiabilidad", comment: "Depth section: the charger's 90-day record")) {
                        card(
                            Text("\(tally.works) de \(tally.reports) reportes dicen que funcionaba", comment: "Charger record: how many of the reports said it worked"),
                            note: Text("En los últimos 90 días, según vecinos. No usamos datos de la red de carga.", comment: "Charger record source: community reports only, no network data")
                        )
                    }
                }
                if let area = detail.area {
                    SectionGroup(title: LocalizedStringResource("Qué tan seguro es", comment: "Depth section: how sure the outage area is")) {
                        card(Text(area.confidenceLine))
                    }
                }
                if let timeline = detail.timeline, timeline.entries.count > 1 {
                    AreaTimelineGroup(timeline: timeline, now: detail.now)
                }
                reports(detail.ownerReports, title: LocalizedStringResource("Lo que publica el negocio", comment: "Depth section: what the verified owner posted"))
                // Only what the full tier didn't list, so depth never repeats it.
                reports(
                    detail.depthCommunityReports,
                    title: detail.fullNeighbourReports.isEmpty
                        ? LocalizedStringResource("Lo que dicen los vecinos", comment: "Section: what community reports say")
                        : LocalizedStringResource("Más reportes de vecinos", comment: "Depth section: community reports past the ones the detail already lists")
                )
                if !detail.stale.isEmpty {
                    StaleReportsGroup(stale: detail.stale, now: detail.now, isRevealed: $isStaleRevealed)
                }
            }
            .padding(.horizontal, Spacing.gutter)
            .padding(.vertical, Spacing.s4)
        }
        .navigationTitle(Text("Detalles de \(detail.name)", comment: "Depth screen title: details of a place"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }

    /// One statement across the group's full width, with an optional source line.
    private func card(_ text: Text, note: Text? = nil) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            text.textRole(.body).foregroundStyle(Color(.ink))
            if let note {
                note.textRole(.footnote).foregroundStyle(Color(.ink3))
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, Spacing.s3)
    }

    @ViewBuilder
    private func reports(_ answers: [PlaceAnswer], title: LocalizedStringResource) -> some View {
        if !answers.isEmpty {
            SectionGroup(title: title) {
                RowList(elements: answers) { answer in
                    ReportRow(answer: answer, now: detail.now, isDetail: true)
                }
            }
        }
    }
}

extension AreaStatus {
    /// Polygon confidence, always in words (§7).
    var confidenceLine: LocalizedStringResource {
        if let agency = area.officialAgency {
            return LocalizedStringResource("Oficial: el área viene de \(agency.displayName).", comment: "Area confidence: the area comes from an agency")
        }
        let devices = area.evidence.distinctDevices
        switch confidence {
        case .high: return LocalizedStringResource("Confianza alta: lo reportaron \(devices) teléfonos distintos.", comment: "Area confidence high, with how many distinct phones reported")
        case .medium: return LocalizedStringResource("Confianza media: lo reportaron \(devices) teléfonos distintos.", comment: "Area confidence medium, with how many distinct phones reported")
        default: return LocalizedStringResource("Confianza baja: pocos reportes (\(devices) teléfonos).", comment: "Area confidence low, with how many distinct phones reported")
        }
    }
}
