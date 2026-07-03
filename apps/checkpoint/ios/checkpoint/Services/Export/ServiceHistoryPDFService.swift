//
//  ServiceHistoryPDFService.swift
//  checkpoint
//
//  Generates professional PDF documents with vehicle service history.
//  Follows brutalist aesthetic: monospace fonts, uppercase labels, sharp borders.
//

import UIKit
import PDFKit
import os
import SwiftUI

/// Export options for PDF generation
struct ExportOptions: Sendable {
    var includeAttachments: Bool = false
    var includeTotal: Bool = true
    var includeCostPerMile: Bool = false
}

private nonisolated let pdfLogger = Logger(category: "PDFExport")

/// Fully-resolved, `Sendable` snapshot of everything the renderer needs. All
/// `@MainActor`/SwiftData access (model properties, `Formatters`, `Theme`) happens
/// while building this on the main actor; rendering then runs off-main from values.
nonisolated struct PDFExportData: Sendable {
    nonisolated struct LogEntry: Sendable {
        let serviceName: String
        let dateString: String
        let costString: String?
        let mileageString: String
        let notes: String?
    }

    nonisolated struct AccentComponents: Sendable {
        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
        let alpha: CGFloat
    }

    let vehicleName: String
    let detailLine: String
    let logs: [LogEntry]
    let includeTotal: Bool
    let totalString: String
    let serviceCountString: String
    let generatedDateString: String
    let fileName: String
    let accent: AccentComponents
}

@MainActor
final class ServiceHistoryPDFService {
    static let shared = ServiceHistoryPDFService()

    private init() {}

    // MARK: - PDF Configuration

    private nonisolated enum Layout {
        static let pageSize = CGSize(width: 612, height: 792) // US Letter
        static let margin: CGFloat = 50
        static let contentWidth: CGFloat = pageSize.width - (margin * 2)
        static let borderWidth: CGFloat = 2
        static let sectionSpacing: CGFloat = 20
        static let itemSpacing: CGFloat = 8
        static let lineHeight: CGFloat = 14
    }

    /// Fonts are built locally inside `render` (UIFont is not `Sendable`, so they
    /// can't be shared static state) and threaded through the draw methods.
    private nonisolated struct Fonts {
        let title = UIFont.monospacedSystemFont(ofSize: 22, weight: .bold)
        let subtitle = UIFont.monospacedSystemFont(ofSize: 16, weight: .semibold)
        let heading = UIFont.monospacedSystemFont(ofSize: 11, weight: .bold)
        let body = UIFont.monospacedSystemFont(ofSize: 9, weight: .regular)
        let label = UIFont.monospacedSystemFont(ofSize: 8, weight: .medium)
        let serviceName = UIFont.monospacedSystemFont(ofSize: 10, weight: .semibold)
        let cost = UIFont.monospacedSystemFont(ofSize: 10, weight: .medium)
    }

    /// Palette is likewise built inside `render` from the snapshot's accent color.
    private nonisolated struct Palette {
        let background = UIColor.white
        let text = UIColor.black
        let secondary = UIColor.darkGray
        let border = UIColor.lightGray
        let accent: UIColor
    }

    // MARK: - Public API

    /// Generates a PDF document with the vehicle's service history using default options
    /// - Parameters:
    ///   - vehicle: The vehicle to generate the report for
    ///   - serviceLogs: The service logs to include (should be pre-sorted)
    /// - Returns: URL to the generated PDF file, or nil if generation fails
    func generatePDF(
        for vehicle: Vehicle,
        serviceLogs: [ServiceLog]
    ) async -> URL? {
        await generatePDF(for: vehicle, serviceLogs: serviceLogs, options: ExportOptions())
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
        options: ExportOptions
    ) async -> URL? {
        // Gather all model / formatter / theme inputs on the main actor…
        let data = buildExportData(for: vehicle, serviceLogs: serviceLogs, options: options)
        // …then render (drawing + file write) off the main actor.
        return await Task.detached { Self.render(data) }.value
    }

    // MARK: - Snapshot Building (MainActor)

    private func buildExportData(
        for vehicle: Vehicle,
        serviceLogs: [ServiceLog],
        options: ExportOptions
    ) -> PDFExportData {
        let sortedLogs = serviceLogs.sorted { $0.performedDate > $1.performedDate }

        // Vehicle detail line
        var detailParts: [String] = []
        if vehicle.year > 0 {
            detailParts.append("\(vehicle.year)")
        }
        if !vehicle.make.isEmpty && !vehicle.model.isEmpty {
            detailParts.append("\(vehicle.make) \(vehicle.model)")
        }
        if let licensePlate = vehicle.licensePlate, !licensePlate.isEmpty {
            detailParts.append("Plate: \(licensePlate)")
        }
        if let vin = vehicle.vin, !vin.isEmpty {
            detailParts.append("VIN: \(vin)")
        }
        detailParts.append(Formatters.mileage(vehicle.effectiveMileage))

        // Per-log entries (dates/costs/mileage formatted here on the main actor)
        let logs: [PDFExportData.LogEntry] = sortedLogs.map { log in
            var costString: String?
            if let cost = log.cost, cost > 0 {
                costString = Formatters.currency.string(from: cost as NSDecimalNumber) ?? "$\(cost)"
            }
            return PDFExportData.LogEntry(
                serviceName: log.service?.name ?? "Service",
                dateString: Formatters.mediumDate.string(from: log.performedDate),
                costString: costString,
                mileageString: Formatters.mileage(log.mileageAtService),
                notes: log.notes
            )
        }

        // Total. Uses honestTotalCost() so a Service Visit holding four services
        // contributes its real total once, not four divided shares (the original bug).
        let totalCost = sortedLogs.honestTotalCost()
        let totalString = Formatters.currency.string(from: totalCost as NSDecimalNumber) ?? "$0.00"
        let serviceCountString = "\(sortedLogs.count) service\(sortedLogs.count == 1 ? "" : "s") recorded"

        // Accent color resolved on main (Theme reads ThemeManager.shared).
        let accentColor = UIColor(Theme.accent)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        accentColor.getRed(&r, green: &g, blue: &b, alpha: &a)

        return PDFExportData(
            vehicleName: vehicle.displayName,
            detailLine: detailParts.joined(separator: "  •  "),
            logs: logs,
            includeTotal: options.includeTotal,
            totalString: totalString,
            serviceCountString: serviceCountString,
            generatedDateString: Formatters.mediumDate.string(from: Date()),
            fileName: "\(Self.sanitizeFileName(vehicle.displayName))_Service_History.pdf",
            accent: PDFExportData.AccentComponents(red: r, green: g, blue: b, alpha: a)
        )
    }

    /// Strips path-hostile characters so a name like "Front/Rear" can't turn the
    /// filename into a bogus subpath (which silently fails the write).
    nonisolated static func sanitizeFileName(_ raw: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\:?%*|\"<>").union(.controlCharacters)
        let cleaned = raw.components(separatedBy: invalid).joined(separator: "-")
        let underscored = cleaned.replacingOccurrences(of: " ", with: "_")
        let trimmed = underscored.trimmingCharacters(
            in: CharacterSet(charactersIn: "._-").union(.whitespaces)
        )
        let bounded = String(trimmed.prefix(100))
        return bounded.isEmpty ? "Vehicle" : bounded
    }

    // MARK: - Rendering (off-main)

    private nonisolated static func render(_ data: PDFExportData) -> URL? {
        let fonts = Fonts()
        let palette = Palette(
            accent: UIColor(
                red: data.accent.red,
                green: data.accent.green,
                blue: data.accent.blue,
                alpha: data.accent.alpha
            )
        )

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: Layout.pageSize))

        let pdfData = renderer.pdfData { context in
            var currentY: CGFloat = 0
            var pageNumber = 1

            // Start first page
            context.beginPage()
            currentY = Layout.margin

            // Draw header
            currentY = drawHeader(at: currentY, in: context.cgContext, fonts: fonts, palette: palette)

            // Draw vehicle info section
            currentY = drawVehicleInfo(at: currentY, data: data, in: context.cgContext, fonts: fonts, palette: palette)

            // Draw service history section
            currentY = drawSectionHeader(at: currentY, title: "SERVICE HISTORY", in: context.cgContext, fonts: fonts, palette: palette)

            if data.logs.isEmpty {
                currentY = drawEmptyState(at: currentY, in: context.cgContext, fonts: fonts, palette: palette)
            } else {
                for log in data.logs {
                    // Check if we need a new page
                    let estimatedHeight = estimateLogHeight()
                    if currentY + estimatedHeight > Layout.pageSize.height - Layout.margin - 40 {
                        // Draw page number before starting new page
                        drawPageNumber(pageNumber, in: context.cgContext, fonts: fonts, palette: palette)
                        pageNumber += 1
                        context.beginPage()
                        currentY = Layout.margin
                    }

                    currentY = drawServiceLog(at: currentY, log: log, in: context.cgContext, fonts: fonts, palette: palette)
                }
            }

            // Draw totals section
            if data.includeTotal && !data.logs.isEmpty {
                let totalHeight: CGFloat = 60
                if currentY + totalHeight > Layout.pageSize.height - Layout.margin - 40 {
                    drawPageNumber(pageNumber, in: context.cgContext, fonts: fonts, palette: palette)
                    pageNumber += 1
                    context.beginPage()
                    currentY = Layout.margin
                }
                currentY = drawTotals(at: currentY, data: data, in: context.cgContext, fonts: fonts, palette: palette)
            }

            // Draw footer and final page number
            drawFooter(generatedDateString: data.generatedDateString, in: context.cgContext, fonts: fonts, palette: palette)
            drawPageNumber(pageNumber, in: context.cgContext, fonts: fonts, palette: palette)
        }

        // Save to temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(data.fileName)

        do {
            try pdfData.write(to: tempURL)
            return tempURL
        } catch {
            pdfLogger.error("Failed to write PDF: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Drawing Methods

    private nonisolated static func drawHeader(at y: CGFloat, in context: CGContext, fonts: Fonts, palette: Palette) -> CGFloat {
        var currentY = y

        // App branding
        let brandingRect = CGRect(x: Layout.margin, y: currentY, width: Layout.contentWidth, height: 26)
        let brandingAttributes: [NSAttributedString.Key: Any] = [
            .font: fonts.title,
            .foregroundColor: palette.accent
        ]
        "CHECKPOINT".draw(in: brandingRect, withAttributes: brandingAttributes)

        currentY += 26

        // Subtitle
        let subtitleRect = CGRect(x: Layout.margin, y: currentY, width: Layout.contentWidth, height: 14)
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: fonts.label,
            .foregroundColor: palette.secondary
        ]
        "SERVICE HISTORY REPORT".draw(in: subtitleRect, withAttributes: subtitleAttributes)

        currentY += 20

        // Divider
        currentY = drawDivider(at: currentY, in: context, palette: palette)

        return currentY
    }

    private nonisolated static func drawVehicleInfo(at y: CGFloat, data: PDFExportData, in context: CGContext, fonts: Fonts, palette: Palette) -> CGFloat {
        var currentY = y + Layout.sectionSpacing

        // Vehicle name (large)
        let nameRect = CGRect(x: Layout.margin, y: currentY, width: Layout.contentWidth, height: 20)
        let nameAttributes: [NSAttributedString.Key: Any] = [
            .font: fonts.subtitle,
            .foregroundColor: palette.text
        ]
        data.vehicleName.draw(in: nameRect, withAttributes: nameAttributes)

        currentY += 22

        // Vehicle details on single line
        let detailsRect = CGRect(x: Layout.margin, y: currentY, width: Layout.contentWidth, height: Layout.lineHeight)
        let detailsAttributes: [NSAttributedString.Key: Any] = [
            .font: fonts.body,
            .foregroundColor: palette.secondary
        ]
        data.detailLine.draw(in: detailsRect, withAttributes: detailsAttributes)

        currentY += Layout.lineHeight + 12

        // Divider
        currentY = drawDivider(at: currentY, in: context, palette: palette)

        return currentY
    }

    private nonisolated static func drawSectionHeader(at y: CGFloat, title: String, in context: CGContext, fonts: Fonts, palette: Palette) -> CGFloat {
        var currentY = y + Layout.sectionSpacing

        let headerRect = CGRect(x: Layout.margin, y: currentY, width: Layout.contentWidth, height: 14)
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: fonts.heading,
            .foregroundColor: palette.accent
        ]
        title.draw(in: headerRect, withAttributes: headerAttributes)

        currentY += 16

        // Thin line under header
        context.setStrokeColor(palette.border.cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: Layout.margin, y: currentY))
        context.addLine(to: CGPoint(x: Layout.margin + Layout.contentWidth, y: currentY))
        context.strokePath()

        return currentY + 6
    }

    private nonisolated static func drawServiceLog(at y: CGFloat, log: PDFExportData.LogEntry, in context: CGContext, fonts: Fonts, palette: Palette) -> CGFloat {
        var currentY = y + Layout.itemSpacing

        // Row 1: Service name (left), date (center-right), cost (right)
        let nameRect = CGRect(x: Layout.margin, y: currentY, width: Layout.contentWidth - 170, height: Layout.lineHeight)
        let nameAttributes: [NSAttributedString.Key: Any] = [
            .font: fonts.serviceName,
            .foregroundColor: palette.text
        ]
        log.serviceName.draw(in: nameRect, withAttributes: nameAttributes)

        // Date in the middle-right area
        let dateRect = CGRect(x: Layout.margin + Layout.contentWidth - 165, y: currentY, width: 95, height: Layout.lineHeight)
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: fonts.body,
            .foregroundColor: palette.secondary
        ]
        log.dateString.draw(in: dateRect, withAttributes: dateAttributes)

        // Cost aligned right
        if let costString = log.costString {
            let costRect = CGRect(x: Layout.margin + Layout.contentWidth - 65, y: currentY, width: 65, height: Layout.lineHeight)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .right
            let costAttributes: [NSAttributedString.Key: Any] = [
                .font: fonts.cost,
                .foregroundColor: palette.accent,
                .paragraphStyle: paragraphStyle
            ]
            costString.draw(in: costRect, withAttributes: costAttributes)
        }

        currentY += Layout.lineHeight + 2

        // Row 2: Mileage and notes (more space for description)
        var detailsStr = log.mileageString

        // Add truncated notes inline if present - now with more space
        if let notes = log.notes, !notes.isEmpty {
            let maxNotesLength = 80
            let truncatedNotes = notes.count > maxNotesLength ? String(notes.prefix(maxNotesLength)) + "..." : notes
            detailsStr += "  •  \(truncatedNotes)"
        }

        let detailsRect = CGRect(x: Layout.margin, y: currentY, width: Layout.contentWidth, height: Layout.lineHeight)
        let detailsAttributes: [NSAttributedString.Key: Any] = [
            .font: fonts.body,
            .foregroundColor: palette.secondary
        ]
        detailsStr.draw(in: detailsRect, withAttributes: detailsAttributes)

        currentY += Layout.lineHeight

        // Light divider between entries
        currentY += 6
        context.setStrokeColor(palette.border.withAlphaComponent(0.4).cgColor)
        context.setLineWidth(0.5)
        context.move(to: CGPoint(x: Layout.margin, y: currentY))
        context.addLine(to: CGPoint(x: Layout.margin + Layout.contentWidth, y: currentY))
        context.strokePath()

        return currentY
    }

    private nonisolated static func drawEmptyState(at y: CGFloat, in context: CGContext, fonts: Fonts, palette: Palette) -> CGFloat {
        let currentY = y + Layout.sectionSpacing

        let messageRect = CGRect(x: Layout.margin, y: currentY, width: Layout.contentWidth, height: 40)
        let messageAttributes: [NSAttributedString.Key: Any] = [
            .font: fonts.body,
            .foregroundColor: palette.secondary
        ]
        "No service records found for this vehicle.".draw(in: messageRect, withAttributes: messageAttributes)

        return currentY + 40
    }

    private nonisolated static func drawTotals(at y: CGFloat, data: PDFExportData, in context: CGContext, fonts: Fonts, palette: Palette) -> CGFloat {
        var currentY = y + Layout.sectionSpacing

        // Divider before totals
        currentY = drawDivider(at: currentY, in: context, palette: palette)
        currentY += Layout.itemSpacing

        // Total spent row - more compact
        let totalLabelRect = CGRect(x: Layout.margin, y: currentY, width: 100, height: 16)
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: fonts.heading,
            .foregroundColor: palette.text
        ]
        "TOTAL SPENT".draw(in: totalLabelRect, withAttributes: labelAttributes)

        let totalValueRect = CGRect(x: Layout.margin + Layout.contentWidth - 120, y: currentY, width: 120, height: 20)
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: fonts.subtitle,
            .foregroundColor: palette.accent
        ]

        // Right-align the total
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right
        var rightAlignedAttributes = valueAttributes
        rightAlignedAttributes[.paragraphStyle] = paragraphStyle
        data.totalString.draw(in: totalValueRect, withAttributes: rightAlignedAttributes)

        currentY += 20

        // Service count
        let countRect = CGRect(x: Layout.margin, y: currentY, width: Layout.contentWidth, height: Layout.lineHeight)
        let countAttributes: [NSAttributedString.Key: Any] = [
            .font: fonts.body,
            .foregroundColor: palette.secondary
        ]
        data.serviceCountString.draw(in: countRect, withAttributes: countAttributes)

        return currentY + Layout.lineHeight
    }

    private nonisolated static func drawDivider(at y: CGFloat, in context: CGContext, palette: Palette) -> CGFloat {
        context.setStrokeColor(palette.border.cgColor)
        context.setLineWidth(Layout.borderWidth)
        context.move(to: CGPoint(x: Layout.margin, y: y))
        context.addLine(to: CGPoint(x: Layout.margin + Layout.contentWidth, y: y))
        context.strokePath()
        return y + Layout.borderWidth
    }

    private nonisolated static func drawFooter(generatedDateString: String, in context: CGContext, fonts: Fonts, palette: Palette) {
        let footerY = Layout.pageSize.height - Layout.margin + 10

        let footerText = "Generated by Checkpoint  //  \(generatedDateString)"

        let footerRect = CGRect(x: Layout.margin, y: footerY, width: Layout.contentWidth, height: Layout.lineHeight)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: fonts.label,
            .foregroundColor: palette.secondary
        ]
        footerText.draw(in: footerRect, withAttributes: footerAttributes)
    }

    private nonisolated static func drawPageNumber(_ number: Int, in context: CGContext, fonts: Fonts, palette: Palette) {
        let pageY = Layout.pageSize.height - Layout.margin + 10
        let pageText = "PAGE \(number)"

        let pageRect = CGRect(x: Layout.margin + Layout.contentWidth - 60, y: pageY, width: 60, height: Layout.lineHeight)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right

        let pageAttributes: [NSAttributedString.Key: Any] = [
            .font: fonts.label,
            .foregroundColor: palette.secondary,
            .paragraphStyle: paragraphStyle
        ]
        pageText.draw(in: pageRect, withAttributes: pageAttributes)
    }

    private nonisolated static func estimateLogHeight() -> CGFloat {
        // Compact layout: name row + details row + spacing + divider
        return Layout.itemSpacing + Layout.lineHeight + 2 + Layout.lineHeight + 6
    }
}
