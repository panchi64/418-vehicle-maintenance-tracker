//
//  ReceiptFixtures.swift
//  checkpointTests
//
//  OCR transcripts of realistic shop receipts, as Vision returns them: one
//  printed line per line, top to bottom. US and Puerto Rico, English and
//  Spanish, and the awkward cases — tax on two lines (state and municipal
//  IVU), a "next service" mileage that must not be read as the odometer, a
//  discount, quantities, no TOTAL label at all.
//

import Foundation
@testable import checkpoint

enum ReceiptFixtures {

    /// A national chain in the US. Sales tax on one line, card payment.
    static let firestone = """
        FIRESTONE COMPLETE AUTO CARE #0421
        1450 E Colonial Dr, Orlando FL 32803
        Tel (407) 555-0133
        INVOICE 0421-88213
        DATE: 03/14/2026
        MILEAGE IN: 45,210
        LUBE OIL FILTER SYNTHETIC    39.99
        MOBIL 1 5W-30 5 QT           32.45
        OIL FILTER                    9.99
        TIRE ROTATION                19.99
        SUBTOTAL                    102.42
        SALES TAX 6.5%                6.66
        TOTAL                       109.08
        VISA ************4417       109.08
        NEXT SERVICE DUE AT 50,210 MI
        """

    /// A Puerto Rico taller, in Spanish: day-first date (14 > 12), "gomas",
    /// state and municipal IVU on separate lines, ATH Móvil payment.
    static let tallerRivera = """
        TALLER HERMANOS RIVERA
        Carr. 2 Km 14.5 Bayamón PR 00959
        Tel. 787-555-0199
        FACTURA #10233
        Fecha: 14/03/2026
        Millaje: 45,210
        Cambio de aceite y filtro 39.99
        Aceite sintético 5 qts 32.45
        Filtro de aceite 9.99
        Rotación de gomas 20.00
        Subtotal 102.43
        IVU Estatal 10.5% 10.76
        IVU Municipal 1% 1.02
        TOTAL A PAGAR $114.21
        ATH Móvil 114.21
        ¡Gracias por su visita!
        """

    /// A dealer repair order: month-name date, mileage in and out, a
    /// quantity line, shop supplies, a discount, and AMOUNT DUE.
    static let dealer = """
        Toyota de Puerto Rico - Service
        RO# 553201
        Date: Mar 3, 2026
        Mileage In 44,980 Mileage Out 44,982
        LOF SYNTHETIC 0W-20 49.99
        WIPER BLADE 2 @ 12.50 25.00
        SHOP SUPPLIES 4.95
        LOYALTY DISCOUNT -10.00
        SALES TAX 4.90
        AMOUNT DUE 74.84
        Recommended next service at 49,980 miles
        """

    /// A parts counter slip with no TOTAL label: the fallback reads the
    /// largest amount, at low confidence, and the items adding up to it
    /// raise it.
    static let partsCounter = """
        PEP BOYS
        09/20/2026
        DIEHARD BATTERY H6 149.99
        BATTERY CORE CHARGE 18.00
        TAX 16.50
        184.49
        """

    /// Spanish long-form date and a European decimal comma.
    static let spanishLongDate = """
        Servicentro La Cumbre
        14 de marzo de 2026
        Alineación 45,00
        Total 45,00
        """

    /// Nothing a receipt reader can use.
    static let garbled = """
        ~~ ## ~~
        thank you
        """

    static func scan(_ transcript: String) -> ReceiptScan {
        ReceiptScan(transcript: transcript)
    }

    /// 2026-09-26 noon, the day these tests are pinned to.
    static let now: Date = date(2026, 9, 26)

    static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    static func context(
        services: [String] = ["Oil Change", "Tire Rotation", "Brake Inspection", "Air Filter", "Cabin Air Filter",
                              "Transmission Fluid", "Coolant Flush", "Spark Plugs", "Battery Check", "Wiper Blades"],
        lastOdometer: Int? = 40_000
    ) -> ReceiptContext {
        ReceiptContext(knownServiceNames: services, lastOdometer: lastOdometer, now: now)
    }
}
