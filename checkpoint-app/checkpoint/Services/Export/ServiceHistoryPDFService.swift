//
//  ServiceHistoryPDFService.swift
//  checkpoint
//
//  Generates professional PDF documents with vehicle service history.
//  Follows brutalist aesthetic: monospace fonts, uppercase labels, sharp borders.
//

import UIKit
import PDFKit

@MainActor
final class ServiceHistoryPDFService {
    static let shared = ServiceHistoryPDFService()

    private init() {}

    // MARK: - PDF Configuration

    private enum Layout {
        static let pageSize = CGSize(width: 612, height: 792) // US Letter
        static let margin: CGFloat = 50
        static let contentWidth: CGFloat = pageSize.width - (margin * 2)
        static let borderWidth: CGFloat = 2
        static let sectionSpacing: CGFloat = 20
        static let itemSpacing: CGFloat = 8
        static let lineHeight: CGFloat = 14
    }

    private enum Colors {
        static let background = UIColor.white
        static let text = UIColor.black
        static let secondary = UIColor.darkGray
        static let accent = UIColor(red: 0/255, green: 119/255, blue: 182/255, alpha: 1) // Cerulean blue
        static let border = UIColor.lightGray
    }

    private enum Fonts {
        static let title = UIFont.monospacedSystemFont(ofSize: 22, weight: .bold)
        static let subtitle = UIFont.monospacedSystemFont(ofSize: 16, weight: .semibold)
        static let heading = UIFont.monospacedSystemFont(ofSize: 11, weight: .bold)
        static let body = UIFont.monospacedSystemFont(ofSize: 9, weight: .regular)
        static let label = UIFont.monospacedSystemFont(ofSize: 8, weight: .medium)
        static let serviceName = UIFont.monospacedSystemFont(ofSize: 10, weight: .semibold)
        static let cost = UIFont.monospacedSystemFont(ofSize: 10, weight: .medium)
    }

    // MARK: - Public API

    struct ExportOptions {
        var includeAttachments: Bool = false
        var includeTotal: Bool = true
        var includeCostPerMile: Bool = false
    }

    /// Generates a PDF document with the vehicle's service history
    /// - Parameters:
    ///   - vehicle: The vehicle to generate the report for
    ///   - serviceLogs: The service logs to include (should be pre-sorted)
    ///   - options: Export configuration options
    /// - Returns: URL to the generated PDF file, or nil if generation fails
    func generatePDF(
        for vehicle: Vehicle,
        serviceLogs: [ServiceLog],
        options: ExportOptions = ExportOptions()
    ) -> URL? {
        let sortedLogs = serviceLogs.sorted { $0.performedDate > $1.performedDate }

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: Layout.pageSize))

        let data = renderer.pdfData { context in
            var currentY: CGFloat = 0
            var pageNumber = 1

            // Start first page
            context.beginPage()
            currentY = Layout.margin

            // Draw header
            currentY = drawHeader(at: currentY, vehicle: vehicle, in: context.cgContext)

            // Draw vehicle info section
            currentY = drawVehicleInfo(at: currentY, vehicle: vehicle, in: context.cgContext)

            // Draw service history section
            currentY = drawSectionHeader(at: currentY, title: "SERVICE HISTORY", in: context.cgContext)

            if sortedLogs.isEmpty {
                currentY = drawEmptyState(at: currentY, in: context.cgContext)
            } else {
                for log in sortedLogs {
                    // Check if we need a new page
                    let estimatedHeight = estimateLogHeight(log, options: options)
                    if currentY + estimatedHeight > Layout.pageSize.height - Layout.margin - 40 {
                        // Draw page number before starting new page
                        drawPageNumber(pageNumber, in: context.cgContext)
                        pageNumber += 1
                        context.beginPage()
                        currentY = Layout.margin
                    }

                    currentY = drawServiceLog(at: currentY, log: log, options: options, in: context.cgContext)
                }
            }

            // Draw totals section
            if options.includeTotal && !sortedLogs.isEmpty {
                let totalHeight: CGFloat = 60
                if currentY + totalHeight > Layout.pageSize.height - Layout.margin - 40 {
                    drawPageNumber(pageNumber, in: context.cgContext)
                    pageNumber += 1
                    context.beginPage()
                    currentY = Layout.margin
                }
                currentY = drawTotals(at: currentY, serviceLogs: sortedLogs, vehicle: vehicle, options: options, in: context.cgContext)
            }

            // Draw footer and final page number
            drawFooter(in: context.cgContext)
            drawPageNumber(pageNumber, in: context.cgContext)
        }

        // Save to temporary file
        let fileName = "\(vehicle.displayName.replacingOccurrences(of: " ", with: "_"))_Service_History.pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("Failed to write PDF: \(error)")
            return nil
        }
    }

    // MARK: - Drawing Methods

    private func drawHeader(at y: CGFloat, vehicle: Vehicle, in context: CGContext) -> CGFloat {
        var currentY = y

        // App branding
        let brandingRect = CGRect(x: Layout.margin, y: currentY, width: Layout.contentWidth, height: 26)
        let brandingAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.title,
            .foregroundColor: Colors.accent
        ]
        "CHECKPOINT".draw(in: brandingRect, withAttributes: brandingAttributes)

        currentY += 26

        // Subtitle
        let subtitleRect = CGRect(x: Layout.margin, y: currentY, width: Layout.contentWidth, height: 14)
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.label,
            .foregroundColor: Colors.secondary
        ]
        "SERVICE HISTORY REPORT".draw(in: subtitleRect, withAttributes: subtitleAttributes)

        currentY += 20

        // Divider
        currentY = drawDivider(at: currentY, in: context)

        return currentY
    }

    private func drawVehicleInfo(at y: CGFloat, vehicle: Vehicle, in context: CGContext) -> CGFloat {
        var currentY = y + Layout.sectionSpacing

        // Vehicle name (large)
        let nameRect = CGRect(x: Layout.margin, y: currentY, width: Layout.contentWidth, height: 20)
        let nameAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.subtitle,
            .foregroundColor: Colors.text
        ]
        vehicle.displayName.draw(in: nameRect, withAttributes: nameAttributes)

        currentY += 22

        // Vehicle details on single line
        var detailParts: [String] = []

        if vehicle.year > 0 {
            detailParts.append("\(vehicle.year)")
        }
        if !vehicle.make.isEmpty && !vehicle.model.isEmpty {
            detailParts.append("\(vehicle.make) \(vehicle.model)")
        }
        if let vin = vehicle.vin, !vin.isEmpty {
            detailParts.append("VIN: \(vin)")
        }

        let mileageValue = Formatters.mileage(vehicle.effectiveMileage)
        detailParts.append(mileageValue)

        let detailsStr = detailParts.joined(separator: "  •  ")
        let detailsRect = CGRect(x: Layout.margin, y: currentY, width: Layout.contentWidth, height: Layout.lineHeight)
        let detailsAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.body,
            .foregroundColor: Colors.secondary
        ]
        detailsStr.draw(in: detailsRect, withAttributes: detailsAttributes)

        currentY += Layout.lineHeight + 12

        // Divider
        currentY = drawDivider(at: currentY, in: context)

        return currentY
    }

    private func drawSectionHeader(at y: CGFloat, title: String, in context: CGContext) -> CGFloat {
        var currentY = y + Layout.sectionSpacing

        let headerRect = CGRect(x: Layout.margin, y: currentY, width: Layout.contentWidth, height: 14)
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.heading,
            .foregroundColor: Colors.accent
        ]
        title.draw(in: headerRect, withAttributes: headerAttributes)

        currentY += 16

        // Thin line under header
        context.setStrokeColor(Colors.border.cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: Layout.margin, y: currentY))
        context.addLine(to: CGPoint(x: Layout.margin + Layout.contentWidth, y: currentY))
        context.strokePath()

        return currentY + 6
    }

    private func drawServiceLog(at y: CGFloat, log: ServiceLog, options: ExportOptions, in context: CGContext) -> CGFloat {
        var currentY = y + Layout.itemSpacing

        // Row 1: Service name (left), date (center-right), cost (right)
        let serviceName = log.service?.name ?? "Service"
        let nameRect = CGRect(x: Layout.margin, y: currentY, width: Layout.contentWidth - 170, height: Layout.lineHeight)
        let nameAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.serviceName,
            .foregroundColor: Colors.text
        ]
        serviceName.draw(in: nameRect, withAttributes: nameAttributes)

        // Date in the middle-right area
        let dateStr = Formatters.mediumDate.string(from: log.performedDate)
        let dateRect = CGRect(x: Layout.margin + Layout.contentWidth - 165, y: currentY, width: 95, height: Layout.lineHeight)
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.body,
            .foregroundColor: Colors.secondary
        ]
        dateStr.draw(in: dateRect, withAttributes: dateAttributes)

        // Cost aligned right
        if let cost = log.cost, cost > 0 {
            let costStr = Formatters.currency.string(from: cost as NSDecimalNumber) ?? "$\(cost)"
            let costRect = CGRect(x: Layout.margin + Layout.contentWidth - 65, y: currentY, width: 65, height: Layout.lineHeight)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .right
            let costAttributes: [NSAttributedString.Key: Any] = [
                .font: Fonts.cost,
                .foregroundColor: Colors.accent,
                .paragraphStyle: paragraphStyle
            ]
            costStr.draw(in: costRect, withAttributes: costAttributes)
        }

        currentY += Layout.lineHeight + 2

        // Row 2: Mileage and notes (more space for description)
        let mileageStr = Formatters.mileage(log.mileageAtService)
        var detailsStr = mileageStr

        // Add truncated notes inline if present - now with more space
        if let notes = log.notes, !notes.isEmpty {
            let maxNotesLength = 80
            let truncatedNotes = notes.count > maxNotesLength ? String(notes.prefix(maxNotesLength)) + "..." : notes
            detailsStr += "  •  \(truncatedNotes)"
        }

        let detailsRect = CGRect(x: Layout.margin, y: currentY, width: Layout.contentWidth, height: Layout.lineHeight)
        let detailsAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.body,
            .foregroundColor: Colors.secondary
        ]
        detailsStr.draw(in: detailsRect, withAttributes: detailsAttributes)

        currentY += Layout.lineHeight

        // Light divider between entries
        currentY += 6
        context.setStrokeColor(Colors.border.withAlphaComponent(0.4).cgColor)
        context.setLineWidth(0.5)
        context.move(to: CGPoint(x: Layout.margin, y: currentY))
        context.addLine(to: CGPoint(x: Layout.margin + Layout.contentWidth, y: currentY))
        context.strokePath()

        return currentY
    }

    private func drawEmptyState(at y: CGFloat, in context: CGContext) -> CGFloat {
        let currentY = y + Layout.sectionSpacing

        let messageRect = CGRect(x: Layout.margin, y: currentY, width: Layout.contentWidth, height: 40)
        let messageAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.body,
            .foregroundColor: Colors.secondary
        ]
        "No service records found for this vehicle.".draw(in: messageRect, withAttributes: messageAttributes)

        return currentY + 40
    }

    private func drawTotals(at y: CGFloat, serviceLogs: [ServiceLog], vehicle: Vehicle, options: ExportOptions, in context: CGContext) -> CGFloat {
        var currentY = y + Layout.sectionSpacing

        // Divider before totals
        currentY = drawDivider(at: currentY, in: context)
        currentY += Layout.itemSpacing

        // Calculate total
        let totalCost = serviceLogs.reduce(Decimal.zero) { $0 + ($1.cost ?? 0) }
        let totalFormatted = Formatters.currency.string(from: totalCost as NSDecimalNumber) ?? "$0.00"

        // Total spent row - more compact
        let totalLabelRect = CGRect(x: Layout.margin, y: currentY, width: 100, height: 16)
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.heading,
            .foregroundColor: Colors.text
        ]
        "TOTAL SPENT".draw(in: totalLabelRect, withAttributes: labelAttributes)

        let totalValueRect = CGRect(x: Layout.margin + Layout.contentWidth - 120, y: currentY, width: 120, height: 20)
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.subtitle,
            .foregroundColor: Colors.accent
        ]

        // Right-align the total
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right
        var rightAlignedAttributes = valueAttributes
        rightAlignedAttributes[.paragraphStyle] = paragraphStyle
        totalFormatted.draw(in: totalValueRect, withAttributes: rightAlignedAttributes)

        currentY += 20

        // Service count
        let countStr = "\(serviceLogs.count) service\(serviceLogs.count == 1 ? "" : "s") recorded"
        let countRect = CGRect(x: Layout.margin, y: currentY, width: Layout.contentWidth, height: Layout.lineHeight)
        let countAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.body,
            .foregroundColor: Colors.secondary
        ]
        countStr.draw(in: countRect, withAttributes: countAttributes)

        return currentY + Layout.lineHeight
    }

    private func drawDivider(at y: CGFloat, in context: CGContext) -> CGFloat {
        context.setStrokeColor(Colors.border.cgColor)
        context.setLineWidth(Layout.borderWidth)
        context.move(to: CGPoint(x: Layout.margin, y: y))
        context.addLine(to: CGPoint(x: Layout.margin + Layout.contentWidth, y: y))
        context.strokePath()
        return y + Layout.borderWidth
    }

    private func drawFooter(in context: CGContext) {
        let footerY = Layout.pageSize.height - Layout.margin + 10

        let dateStr = Formatters.mediumDate.string(from: Date())
        let footerText = "Generated by Checkpoint  //  \(dateStr)"

        let footerRect = CGRect(x: Layout.margin, y: footerY, width: Layout.contentWidth, height: Layout.lineHeight)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.label,
            .foregroundColor: Colors.secondary
        ]
        footerText.draw(in: footerRect, withAttributes: footerAttributes)
    }

    private func drawPageNumber(_ number: Int, in context: CGContext) {
        let pageY = Layout.pageSize.height - Layout.margin + 10
        let pageText = "PAGE \(number)"

        let pageRect = CGRect(x: Layout.margin + Layout.contentWidth - 60, y: pageY, width: 60, height: Layout.lineHeight)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right

        let pageAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.label,
            .foregroundColor: Colors.secondary,
            .paragraphStyle: paragraphStyle
        ]
        pageText.draw(in: pageRect, withAttributes: pageAttributes)
    }

    private func estimateLogHeight(_ log: ServiceLog, options: ExportOptions) -> CGFloat {
        // Compact layout: name row + details row + spacing + divider
        return Layout.itemSpacing + Layout.lineHeight + 2 + Layout.lineHeight + 6
    }
}
