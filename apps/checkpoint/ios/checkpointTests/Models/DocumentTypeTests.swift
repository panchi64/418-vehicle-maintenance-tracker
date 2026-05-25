//
//  DocumentTypeTests.swift
//  checkpointTests
//
//  Tests for DocumentType enum, filename heuristic, list order.
//

import XCTest
@testable import checkpoint

final class DocumentTypeTests: XCTestCase {

    // MARK: - Filename Heuristic

    func testSuggestedType_RegistrationKeywords() {
        XCTAssertEqual(DocumentType.suggestedType(forFileName: "registration_2026.pdf"), .registration)
        XCTAssertEqual(DocumentType.suggestedType(forFileName: "DMV-Renewal.pdf"), .registration)
        XCTAssertEqual(DocumentType.suggestedType(forFileName: "marbete-pr-2026.jpg"), .registration)
    }

    func testSuggestedType_InsuranceKeywords() {
        XCTAssertEqual(DocumentType.suggestedType(forFileName: "insurance_card.jpg"), .insurance)
        XCTAssertEqual(DocumentType.suggestedType(forFileName: "POLICY-12345.pdf"), .insurance)
        XCTAssertEqual(DocumentType.suggestedType(forFileName: "declarations-page.pdf"), .insurance)
        XCTAssertEqual(DocumentType.suggestedType(forFileName: "seguro-vehicular.pdf"), .insurance)
    }

    func testSuggestedType_TitleKeywords() {
        XCTAssertEqual(DocumentType.suggestedType(forFileName: "vehicle_title.pdf"), .title)
        XCTAssertEqual(DocumentType.suggestedType(forFileName: "lien_release.pdf"), .title)
        XCTAssertEqual(DocumentType.suggestedType(forFileName: "titulo-original.jpg"), .title)
    }

    func testSuggestedType_InspectionKeywords() {
        XCTAssertEqual(DocumentType.suggestedType(forFileName: "annual-inspection.pdf"), .inspection)
        XCTAssertEqual(DocumentType.suggestedType(forFileName: "smog-cert.jpg"), .inspection)
        XCTAssertEqual(DocumentType.suggestedType(forFileName: "emissions-2025.pdf"), .inspection)
    }

    func testSuggestedType_WarrantyKeywords() {
        XCTAssertEqual(DocumentType.suggestedType(forFileName: "extended_warranty.pdf"), .warranty)
        XCTAssertEqual(DocumentType.suggestedType(forFileName: "garantia.pdf"), .warranty)
    }

    func testSuggestedType_ManualKeywords() {
        XCTAssertEqual(DocumentType.suggestedType(forFileName: "owner_manual.pdf"), .manual)
        XCTAssertEqual(DocumentType.suggestedType(forFileName: "service-guide.pdf"), .manual)
    }

    func testSuggestedType_ReceiptKeywords() {
        XCTAssertEqual(DocumentType.suggestedType(forFileName: "shop-receipt.jpg"), .receipt)
        XCTAssertEqual(DocumentType.suggestedType(forFileName: "INVOICE_2024.pdf"), .receipt)
        XCTAssertEqual(DocumentType.suggestedType(forFileName: "recibo.pdf"), .receipt)
        XCTAssertEqual(DocumentType.suggestedType(forFileName: "factura-taller.pdf"), .receipt)
    }

    func testSuggestedType_UnrecognizedFallsBackToOther() {
        XCTAssertEqual(DocumentType.suggestedType(forFileName: "IMG_4093.jpg"), .other)
        XCTAssertEqual(DocumentType.suggestedType(forFileName: "scan-2024-03.pdf"), .other)
        XCTAssertEqual(DocumentType.suggestedType(forFileName: ""), .other)
    }

    func testSuggestedType_CaseInsensitive() {
        XCTAssertEqual(DocumentType.suggestedType(forFileName: "REGISTRATION.PDF"), .registration)
        XCTAssertEqual(DocumentType.suggestedType(forFileName: "Insurance_Card.JPG"), .insurance)
    }

    // MARK: - List Order

    func testListOrder_CoversEveryCase() {
        let listed = Set(DocumentType.listOrder)
        let all = Set(DocumentType.allCases)
        XCTAssertEqual(listed, all, "listOrder must include every DocumentType case")
    }

    func testListOrder_RegistrationFirst() {
        // Registration is the most "carry-this-with-you" doc — should lead.
        XCTAssertEqual(DocumentType.listOrder.first, .registration)
    }

    // MARK: - Identifiable + Codable

    func testIdentifiable_IDMatchesRawValue() {
        for type in DocumentType.allCases {
            XCTAssertEqual(type.id, type.rawValue)
        }
    }

    func testCodable_RoundTrip() throws {
        for type in DocumentType.allCases {
            let encoded = try JSONEncoder().encode(type)
            let decoded = try JSONDecoder().decode(DocumentType.self, from: encoded)
            XCTAssertEqual(decoded, type)
        }
    }
}
