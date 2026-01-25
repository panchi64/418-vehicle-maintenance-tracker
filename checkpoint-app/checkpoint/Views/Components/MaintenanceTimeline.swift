//
//  MaintenanceTimeline.swift
//  checkpoint
//
//  Visual timeline of past/upcoming services with brutalist aesthetics.
//  2px vertical spine, 8x8 square nodes, service cards branching off.
//

import SwiftUI
import SwiftData

struct MaintenanceTimeline: View {
    let services: [Service]
    let serviceLogs: [ServiceLog]
    let vehicle: Vehicle
    let onServiceTap: (Service) -> Void

    private var calendar: Calendar { Calendar.current }

    // MARK: - Timeline Items

    private struct TimelineItem: Identifiable {
        let id: String
        let date: Date
        let type: ItemType
        let service: Service?
        let serviceLog: ServiceLog?

        enum ItemType {
            case upcoming
            case completed
        }
    }

    private var timelineItems: [TimelineItem] {
        var items: [TimelineItem] = []

        // Add upcoming services
        for service in services {
            if let dueDate = service.dueDate {
                items.append(TimelineItem(
                    id: "upcoming-\(service.id)",
                    date: dueDate,
                    type: .upcoming,
                    service: service,
                    serviceLog: nil
                ))
            } else if service.dueMileage != nil {
                // For mileage-only services, estimate date based on driving pace
                // Default to 30 days from now if no date info
                items.append(TimelineItem(
                    id: "upcoming-\(service.id)",
                    date: Date.now.addingTimeInterval(86400 * 30),
                    type: .upcoming,
                    service: service,
                    serviceLog: nil
                ))
            }
        }

        // Add completed service logs
        for log in serviceLogs {
            items.append(TimelineItem(
                id: "completed-\(log.id)",
                date: log.performedDate,
                type: .completed,
                service: log.service,
                serviceLog: log
            ))
        }

        // Sort by date descending (most recent/upcoming first)
        return items.sorted { $0.date > $1.date }
    }

    /// Group items by month
    private var groupedItems: [(month: Date, items: [TimelineItem])] {
        var groups: [Date: [TimelineItem]] = [:]

        for item in timelineItems {
            let components = calendar.dateComponents([.year, .month], from: item.date)
            if let monthStart = calendar.date(from: components) {
                groups[monthStart, default: []].append(item)
            }
        }

        return groups
            .map { ($0.key, $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.0 > $1.0 }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            if groupedItems.isEmpty {
                emptyState
            } else {
                ForEach(Array(groupedItems.enumerated()), id: \.element.month) { groupIndex, group in
                    monthSection(month: group.month, items: group.items, groupIndex: groupIndex)
                }
            }
        }
    }

    // MARK: - Month Section

    private func monthSection(month: Date, items: [TimelineItem], groupIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Month header
            Text(formatMonthYear(month))
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(2)
                .textCase(.uppercase)
                .padding(.leading, 28)
                .padding(.bottom, Spacing.sm)
                .staggeredReveal(index: groupIndex, baseDelay: 0.1)

            // Timeline items
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                timelineRow(item: item, isLast: index == items.count - 1 && groupIndex == groupedItems.count - 1)
                    .staggeredReveal(index: groupIndex * 5 + index, baseDelay: 0.15)
            }
        }
        .padding(.bottom, Spacing.md)
    }

    // MARK: - Timeline Row

    private func timelineRow(item: TimelineItem, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            // Spine with node
            VStack(spacing: 0) {
                // Node (8x8 square)
                Rectangle()
                    .fill(item.type == .completed ? Theme.statusGood : Theme.statusDueSoon)
                    .frame(width: 8, height: 8)

                // Spine line (2px width, continues down unless last)
                if !isLast {
                    Rectangle()
                        .fill(Theme.gridLine)
                        .frame(width: 2)
                }
            }
            .frame(width: 8)

            // Content card
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Status badge
                HStack(spacing: 4) {
                    Text(item.type == .completed ? "COMPLETED" : "UPCOMING")
                        .font(.brutalistLabel)
                        .foregroundStyle(item.type == .completed ? Theme.statusGood : Theme.statusDueSoon)
                        .tracking(1)
                }

                // Service name
                if let service = item.service {
                    Text(service.name)
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                }

                // Details row
                HStack(spacing: Spacing.xs) {
                    if item.type == .completed, let log = item.serviceLog {
                        Text(Formatters.mediumDate.string(from: log.performedDate))
                            .font(.brutalistSecondary)
                            .foregroundStyle(Theme.textTertiary)

                        if let cost = log.formattedCost {
                            Text("//")
                                .font(.brutalistSecondary)
                                .foregroundStyle(Theme.gridLine)

                            Text(cost)
                                .font(.brutalistSecondary)
                                .foregroundStyle(Theme.accent)
                        }
                    } else if item.type == .upcoming, let service = item.service {
                        if let description = service.primaryDescription {
                            Text(description)
                                .font(.brutalistSecondary)
                                .foregroundStyle(Theme.textSecondary)
                        } else if let dueDescription = service.dueDescription {
                            Text(dueDescription)
                                .font(.brutalistSecondary)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.md)
            .background(Theme.surfaceInstrument)
            .overlay(
                Rectangle()
                    .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
            )
            .onTapGesture {
                if let service = item.service {
                    onServiceTap(service)
                }
            }
        }
        .padding(.leading, 4)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                Rectangle()
                    .fill(Theme.accent.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(Theme.accent)
            }

            VStack(spacing: Spacing.xs) {
                Text("NO TIMELINE DATA")
                    .font(.brutalistHeading)
                    .foregroundStyle(Theme.textPrimary)

                Text("Schedule services or log\ncompleted maintenance")
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .padding(Spacing.xxl)
    }

    // MARK: - Helpers

    private func formatMonthYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    let vehicle = Vehicle(
        name: "Test Car",
        make: "Toyota",
        model: "Camry",
        year: 2022,
        currentMileage: 32500
    )

    let services = Service.sampleServices(for: vehicle)
    let logs = ServiceLog.sampleLogs(for: vehicle)

    return ZStack {
        AtmosphericBackground()

        ScrollView {
            MaintenanceTimeline(
                services: services,
                serviceLogs: logs,
                vehicle: vehicle,
                onServiceTap: { _ in }
            )
            .padding(Spacing.screenHorizontal)
        }
    }
    .preferredColorScheme(.dark)
}
