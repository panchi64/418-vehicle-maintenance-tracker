//
//  ServiceDetailView+Sections.swift
//  checkpoint
//
//  Service Detail's readout sections: schedule, history, insights.
//

import SwiftUI

extension ServiceDetailView {

    // MARK: - Schedule

    var scheduleSection: some View {
        InstrumentSection(title: L10n.servicesDetailSchedule) {
            VStack(spacing: 0) {
                if let dueDate = service.dueDate {
                    dataRow(L10n.formDueDate, Formatters.mediumDate.string(from: dueDate))
                }
                if let dueMileage = service.dueMileage {
                    dataRow(L10n.formDueMileage, Formatters.mileage(dueMileage))
                }
                if service.hasIntervalPolicy,
                   let interval = Formatters.serviceInterval(months: service.intervalMonths, miles: service.intervalMiles) {
                    dataRow(L10n.servicesDetailRepeats, interval)
                }
                if let notes = service.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(L10n.formNotes.uppercased())
                            .font(.brutalistLabel)
                            .foregroundStyle(Theme.textTertiary)
                            .tracking(1)
                        Text(notes.brutalistMarkdownAttributed)
                            .font(.brutalistBody)
                            .foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.md)
                }
            }
        }
    }

    /// A data row with the rule beneath it; the section's border closes the
    /// last one.
    private func dataRow(_ label: String, _ value: String) -> some View {
        VStack(spacing: 0) {
            BrutalistDataRow(label: label, value: value, padding: Spacing.md)
            ListDivider()
        }
    }

    // MARK: - History

    /// The same event row as the Services tab's history. The service name is
    /// this screen's title, so the row leads with the date instead.
    func historySection(_ logs: [ServiceLog]) -> some View {
        InstrumentSection(title: L10n.servicesDetailHistory) {
            VStack(spacing: 0) {
                ForEach(logs) { log in
                    let date = Formatters.mediumDate.string(from: log.performedDate)
                    // A visit's total belongs to the visit, not this service.
                    let metadata: [ServiceEventRow.Metadatum] = log.visit != nil
                        ? [.detail(Formatters.mileage(log.mileageAtService)),
                           .tag(L10n.servicesDetailPartOfVisit.uppercased(), color: Theme.textTertiary)]
                        : [.detail(Formatters.mileage(log.mileageAtService))]

                    ServiceEventRow(
                        indicator: log.visit != nil ? .bundledVisit(Theme.accent) : .completed(),
                        title: date,
                        metadata: metadata,
                        amount: log.visit != nil ? nil : log.formattedCost.map { .init(text: $0, color: Theme.accent) },
                        accessibilityLabelText: L10n.readoutEvent(service.name, L10n.spokenDate(log.performedDate)),
                        onTap: {
                            if let visit = log.visit {
                                appState.push(.visit(visit))
                            } else {
                                appState.push(.serviceLog(log))
                            }
                        }
                    )
                    .padding(.horizontal, Spacing.md)
                    // Toasts render above everything, so the delete can be
                    // undone rather than confirmed.
                    .serviceLogDeleteMenu { ServiceLogDeleteAction.perform(log, offerUndo: true) }

                    if log.id != logs.last?.id {
                        ListDivider()
                    }
                }
            }
        }
    }

    // MARK: - Insights

    func insightsSection(_ logs: [ServiceLog], mileage: MileageEstimate) -> some View {
        InstrumentSection(title: L10n.servicesDetailInsights) {
            VStack(spacing: 0) {
                if let last = logs.first {
                    dataRow(L10n.servicesDetailTimeSinceLast, TimeSinceFormatter.full(from: last.performedDate))

                    let distanceSince = mileage.effective - last.mileageAtService
                    if distanceSince >= 0 {
                        dataRow(L10n.servicesDetailDistanceSinceLast, Formatters.mileage(distanceSince))
                    }
                }

                // Standalone logs only: attributing an un-itemized visit's
                // total to one of its services would be misleading.
                if let average = service.averageCost(from: logs),
                   let formatted = Formatters.currency.string(from: average as NSDecimalNumber) {
                    dataRow(L10n.servicesDetailAverageCost, formatted)
                }

                let visitCount = Set(logs.compactMap { $0.visit?.id }).count
                if visitCount > 0 {
                    dataRow(L10n.servicesDetailVisitCount, visitCount.formatted())
                }

                BrutalistDataRow(
                    label: L10n.servicesDetailTimesServiced,
                    value: logs.count.formatted(),
                    padding: Spacing.md
                )
            }
        }
    }
}
