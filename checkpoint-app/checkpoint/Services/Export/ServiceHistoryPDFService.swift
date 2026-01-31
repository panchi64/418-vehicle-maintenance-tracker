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
        static let sectionSpacing: CGFloat = 24
        static let itemSpacing: CGFloat = 16
        static let lineHeight: CGFloat = 18
    }

    private enum Colors {
        static let background = UIColor.white
        static let text = UIColor.black
        static let secondary = UIColor.darkGray
        static let accent = UIColor(red: 232/255, green: 155/255, blue: 60/255, alpha: 1) // #E89B3C
        static let border = UIColor.lightGray
    }

    private enum Fonts {
        static let title = UIFont.monospacedSystemFont(ofSize: 24, weight: .bold)
        static let heading = UIFont.monospacedSystemFont(ofSize: 14, weight: .bold)
        static let body = UIFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        static let label = UIFont.monospacedSystemFont(ofSize: 9, weight: .medium)
        static let serviceName = UIFont.monospacedSystemFont(ofSize: 12, weight: .medium)
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
        let brandingRect = CGRect(x: Layout.margin, y: currentY, width: Layout.contentWidth, height: 30)
        let brandingAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.title,
            .foregroundColor: Colors.accent
        ]
        "CHECKPOINT".draw(in: brandingRect, withAttributes: brandingAttributes)

        currentY += 32

        // Subtitle
        let subtitleRect = CGRect(x: Layout.margin, y: currentY, width: Layout.contentWidth, height: 20)
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.label,
            .foregroundColor: Colors.secondary
        ]
        "SERVICE HISTORY REPORT".draw(in: subtitleRect, withAttributes: subtitleAttributes)

        currentY += 28

        // Divider
        currentY = drawDivider(at: currentY, in: context)

        return currentY
    }

    private func drawVehicleInfo(at y: CGFloat, vehicle: Vehicle, in context: CGContext) -> CGFloat {
        var currentY = y + Layout.sectionSpacing

        // Vehicle name (large)
        let nameRect = CGRect(x: Layout.margin, y: currentY, width: Layout.contentWidth, height: 28)
        let nameAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.title,
            .foregroundColor: Colors.text
        ]
        vehicle.displayName.draw(in: nameRect, withAttributes: nameAttributes)

        currentY += 32

        // Vehicle details grid
        let leftColumnX = Layout.margin
        let rightColumnX = Layout.margin + Layout.contentWidth / 2

        // Row 1: VIN and Current Mileage
        if let vin = vehicle.vin, !vin.isEmpty {
            currentY = drawDataRow(at: currentY, x: leftColumnX, label: "VIN", value: vin, in: context)
        }

        let mileageValue = Formatters.mileage(vehicle.effectiveMileage)
        drawDataRow(at: currentY - Layout.lineHeight - 4, x: rightColumnX, label: "CURRENT MILEAGE", value: mileageValue, in: context)

        // Row 2: Year and Make/Model
        if vehicle.year > 0 {
            currentY = drawDataRow(at: currentY, x: leftColumnX, label: "YEAR", value: "\(vehicle.year)", in: context)
        }

        if !vehicle.make.isEmpty && !vehicle.model.isEmpty {
            drawDataRow(at: currentY - Layout.lineHeight - 4, x: rightColumnX, label: "MAKE/MODEL", value: "\(vehicle.make) \(vehicle.model)", in: context)
        }

        currentY += Layout.sectionSpacing / 2

        // Divider
        currentY = drawDivider(at: currentY, in: context)

        return currentY
    }

    @discardableResult
    private func drawDataRow(at y: CGFloat, x: CGFloat, label: String, value: String, in context: CGContext) -> CGFloat {
        // Label
        let labelRect = CGRect(x: x, y: y, width: 150, height: Layout.lineHeight)
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.label,
            .foregroundColor: Colors.secondary
        ]
        label.draw(in: labelRect, withAttributes: labelAttributes)

        // Value
        let valueRect = CGRect(x: x, y: y + Layout.lineHeight, width: Layout.contentWidth / 2 - 20, height: Layout.lineHeight)
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.body,
            .foregroundColor: Colors.text
        ]
        value.draw(in: valueRect, withAttributes: valueAttributes)

        return y + Layout.lineHeight * 2 + 4
    }

    private func drawSectionHeader(at y: CGFloat, title: String, in context: CGContext) -> CGFloat {
        var currentY = y + Layout.sectionSpacing

        let headerRect = CGRect(x: Layout.margin, y: currentY, width: Layout.contentWidth, height: 20)
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.heading,
            .foregroundColor: Colors.accent
        ]
        title.draw(in: headerRect, withAttributes: headerAttributes)

        currentY += 24

        // Thin line under header
        context.setStrokeColor(Colors.border.cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: Layout.margin, y: currentY))
        context.addLine(to: CGPoint(x: Layout.margin + Layout.contentWidth, y: currentY))
        context.strokePath()

        return currentY + 8
    }

    private func drawServiceLog(at y: CGFloat, log: ServiceLog, options: ExportOptions, in context: CGContext) -> CGFloat {
        var currentY = y + Layout.itemSpacing

        // Service name
        let serviceName = log.service?.name ?? "Service"
        let nameRect = CGRect(x: Layout.margin, y: currentY, width: Layout.contentWidth, height: 18)
        let nameAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.serviceName,
            .foregroundColor: Colors.text
        ]
        serviceName.draw(in: nameRect, withAttributes: nameAttributes)

        currentY += 18

        // Date, mileage, cost on same line
        let dateStr = Formatters.mediumDate.string(from: log.performedDate)
        let mileageStr = Formatters.mileage(log.mileageAtService)
        var detailsStr = "\(dateStr)  //  \(mileageStr)"

        if let cost = log.cost, cost > 0 {
            let costStr = Formatters.currency.string(from: cost as NSDecimalNumber) ?? "$\(cost)"
            detailsStr += "  //  \(costStr)"
        }

        let detailsRect = CGRect(x: Layout.margin, y: currentY, width: Layout.contentWidth, height: Layout.lineHeight)
        let detailsAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.body,
            .foregroundColor: Colors.secondary
        ]
        detailsStr.draw(in: detailsRect, withAttributes: detailsAttributes)

        currentY += Layout.lineHeight

        // Notes (if any)
        if let notes = log.notes, !notes.isEmpty {
            currentY += 4
            let notesRect = CGRect(x: Layout.margin, y: currentY, width: Layout.contentWidth, height: 40)
            let notesAttributes: [NSAttributedString.Key: Any] = [
                .font: Fonts.body,
                .foregroundColor: Colors.secondary
            ]

            // Truncate notes if too long
            let truncatedNotes = notes.count > 200 ? String(notes.prefix(200)) + "..." : notes
            truncatedNotes.draw(in: notesRect, withAttributes: notesAttributes)

            currentY += min(40, CGFloat(notes.count / 60 + 1) * Layout.lineHeight)
        }

        // Light divider between entries
        currentY += 8
        context.setStrokeColor(Colors.border.withAlphaComponent(0.5).cgColor)
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

        // Total spent row
        let totalLabelRect = CGRect(x: Layout.margin, y: currentY, width: 150, height: 20)
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.heading,
            .foregroundColor: Colors.text
        ]
        "TOTAL SPENT".draw(in: totalLabelRect, withAttributes: labelAttributes)

        let totalValueRect = CGRect(x: Layout.margin + Layout.contentWidth - 150, y: currentY, width: 150, height: 20)
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.title,
            .foregroundColor: Colors.accent
        ]

        // Right-align the total
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right
        var rightAlignedAttributes = valueAttributes
        rightAlignedAttributes[.paragraphStyle] = paragraphStyle
        totalFormatted.draw(in: totalValueRect, withAttributes: rightAlignedAttributes)

        currentY += 28

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
        var height: CGFloat = Layout.itemSpacing + 18 + Layout.lineHeight + 8 // Name, details, divider

        if let notes = log.notes, !notes.isEmpty {
            height += 4 + min(40, CGFloat(notes.count / 60 + 1) * Layout.lineHeight)
        }

        return height
    }
}
