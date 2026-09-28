import CoreGraphics
import Foundation

/// Where the map's words go so none covers another: which pins drop their
/// label, which pins sharing one spot fan out, and which area tags step off a pin.
nonisolated struct MapLabelLayout: Hashable, Sendable {
    /// Pins drawn without their word. The pin keeps its shape and glyph, and
    /// VoiceOver and the sheet still say the answer.
    let hiddenLabels: Set<String>
    /// Area tags moved clear of a pin, as a vertical offset in points.
    let tagOffsets: [String: Double]
    /// Pins that share a spot with another, stacked as a vertical offset in points.
    let pinOffsets: [String: Double]

    nonisolated static let empty = MapLabelLayout(hiddenLabels: [], tagOffsets: [:], pinOffsets: [:])
}

/// A greedy collision pass in screen points. Pins are always drawn, so they
/// are obstacles first (pins on one spot fan out so each stays tappable);
/// then area tags (outages outrank everyday answers) pick the first clear
/// spot of centre, below or above; then pin labels are placed by priority at
/// their own width, and a label that would overlap anything is dropped.
nonisolated struct MapLabelPlacer: Sendable {
    /// The visible span and the map's size in points.
    struct Viewport: Hashable, Sendable {
        var latitudeDelta: Double
        var longitudeDelta: Double
        var width: Double
        var height: Double
    }

    var pinSize = 34.0
    /// A pin label's footprint when its width isn't given.
    var labelSize = CGSize(width: 64, height: 20)
    /// An area tag names its source too ("LUMA · Sin luz").
    var tagSize = CGSize(width: 120, height: 22)
    var vantageSize = 24.0
    /// Pins closer than this many points count as one spot.
    var sameSpot = 4.0

    /// `labelWidths` gives each pin label's width in points, by mark id.
    func layout(
        marks: [MapMark], areas: [AreaStatus], vantage: GeoPoint, selectedID: String?,
        viewport: Viewport, labelWidths: [String: Double] = [:]
    ) -> MapLabelLayout {
        guard viewport.width > 0, viewport.height > 0, viewport.latitudeDelta > 0, viewport.longitudeDelta > 0 else {
            return .empty
        }
        func point(_ geo: GeoPoint) -> CGPoint {
            CGPoint(
                x: geo.longitude / viewport.longitudeDelta * viewport.width,
                y: -geo.latitude / viewport.latitudeDelta * viewport.height
            )
        }

        let pinOffsets = fanOut(marks, point: point)
        func pinPoint(_ mark: MapMark) -> CGPoint {
            let base = point(mark.anchor)
            return CGPoint(x: base.x, y: base.y + (pinOffsets[mark.id] ?? 0))
        }

        var occupied = marks.map { pinRect($0.layer, at: pinPoint($0)) }
        let dot = point(vantage)
        occupied.append(CGRect(x: dot.x - vantageSize / 2, y: dot.y - vantageSize / 2, width: vantageSize, height: vantageSize))

        var offsets: [String: Double] = [:]
        for status in areas.sorted(by: { $0.id < $1.id }) {
            let center = point(status.anchor)
            let offset = [0, pinSize, -pinSize, pinSize * 2].first { dy in
                !occupied.contains { $0.intersects(tagRect(center, dy: dy)) }
            } ?? pinSize
            if offset != 0 { offsets[status.id] = offset }
            occupied.append(tagRect(center, dy: offset))
        }

        var hidden: Set<String> = []
        for mark in marks.sorted(by: { rank($0, selectedID) < rank($1, selectedID) }) {
            guard case .pin = mark else { continue }
            let pin = pinRect(mark.layer, at: pinPoint(mark))
            let width = labelWidths[mark.id] ?? labelSize.width
            let label = CGRect(x: pin.maxX + 2, y: pin.midY - labelSize.height / 2, width: width, height: labelSize.height)
            if occupied.contains(where: { $0.intersects(label) }) {
                hidden.insert(mark.id)
            } else {
                occupied.append(label)
            }
        }
        return MapLabelLayout(hiddenLabels: hidden, tagOffsets: offsets, pinOffsets: pinOffsets)
    }

    /// Pins on one spot (a barrio's power, water and signal answers) stack
    /// in a column centred on the spot, in layer order, so each keeps its
    /// label room to the right.
    private func fanOut(_ marks: [MapMark], point: (GeoPoint) -> CGPoint) -> [String: Double] {
        var groups: [[MapMark]] = []
        for mark in marks.sorted(by: { ($0.layer.order, $0.id) < ($1.layer.order, $1.id) }) {
            let spot = point(mark.anchor)
            if let index = groups.firstIndex(where: { group in
                let other = point(group[0].anchor)
                return abs(other.x - spot.x) < sameSpot && abs(other.y - spot.y) < sameSpot
            }) {
                groups[index].append(mark)
            } else {
                groups.append([mark])
            }
        }
        var offsets: [String: Double] = [:]
        for group in groups where group.count > 1 {
            let step = pinSize + 4
            for (index, mark) in group.enumerated() {
                offsets[mark.id] = (Double(index) - Double(group.count - 1) / 2) * step
            }
        }
        return offsets
    }

    /// Teardrops stand on their tip; every other pin is centred on its point.
    private func pinRect(_ layer: Layer, at point: CGPoint) -> CGRect {
        let top = layer == .gas ? point.y - pinSize * 0.91 : point.y - pinSize / 2
        return CGRect(x: point.x - pinSize / 2, y: top, width: pinSize, height: pinSize)
    }

    private func tagRect(_ center: CGPoint, dy: Double) -> CGRect {
        CGRect(x: center.x - tagSize.width / 2, y: center.y + dy - tagSize.height / 2, width: tagSize.width, height: tagSize.height)
    }

    /// The selection first, then problems before everyday answers, then layer order.
    private func rank(_ mark: MapMark, _ selectedID: String?) -> (Int, Int, Int, String) {
        let isProblem = if case .pin(let answer) = mark, case .status = answer.value { !answer.layer.readsAsPlace } else { false }
        return (mark.id == selectedID ? 0 : 1, isProblem ? 0 : 1, mark.layer.order, mark.id)
    }
}

private extension Layer {
    nonisolated var order: Int { Layer.allCases.firstIndex(of: self) ?? 0 }
}
