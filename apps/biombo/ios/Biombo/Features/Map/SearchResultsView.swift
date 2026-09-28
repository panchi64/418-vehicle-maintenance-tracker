import SwiftUI

/// Search results: municipios, then places with their current answer.
struct SearchResultsView: View {
    let query: String
    let places: [Place]
    let digest: HomeDigest
    /// Picking a place to watch says so before anything is typed.
    var isPickingWatch = false
    let onChoose: (PlaceSearch.Result) -> Void

    @Environment(\.locale) private var locale
    @Environment(\.priceUnit) private var unit
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let results = PlaceSearch().results(for: query, in: places, near: digest.vantage)
        if query.trimmingCharacters(in: .whitespaces).isEmpty {
            if isPickingWatch {
                Label {
                    Text("Busca la casa de alguien, un barrio o una estación. Al escogerlo, eliges qué vigilar.", comment: "Search prompt when picking a place to watch")
                } icon: {
                    Image(systemName: "eye").accessibilityHidden(true)
                }
                .textRole(.body)
                .foregroundStyle(Color(.ink2))
                .fixedSize(horizontal: false, vertical: true)
            }
        } else if results.isEmpty {
            VStack(spacing: Spacing.s3) {
                InkVignette(image: .vignetteCoqui)
                Text("Sin resultados para “\(query)”", comment: "Search: nothing matched the query")
                    .textRole(.body)
                    .foregroundStyle(Color(.ink2))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        } else {
            VStack(spacing: 0) {
                ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                    if index > 0 { RowDivider() }
                    Button { onChoose(result) } label: { label(for: result) }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .combine)
                }
            }
            .insetGroup()
        }
    }

    private func label(for result: PlaceSearch.Result) -> some View {
        HStack(spacing: Spacing.s3) {
            switch result {
            case .municipio(let name, _):
                Image(systemName: "mappin.and.ellipse")
                    .frame(width: Size.listPin, height: Size.listPin)
                    .foregroundStyle(Color(.ink2))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: name).textRole(.body).foregroundStyle(Color(.ink))
                    Text("Municipio", comment: "Search result kind: a municipality").textRole(.footnote).foregroundStyle(Color(.ink3))
                }
            case .place(let place):
                // A barrio with an open outage shows the outage, which choosing it opens.
                let status = digest.area(covering: place)
                let answer = status == nil ? digest.answer(forPlace: place.id) : nil
                let value = status?.word ?? answer?.valueText(unit: unit, locale: locale)
                let isStacked = dynamicTypeSize.isAccessibilitySize
                LayerPin(layer: status?.layer ?? answer?.layer ?? place.kind.layer, glyph: status?.glyph ?? answer?.glyph)
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: place.name).textRole(.body).foregroundStyle(Color(.ink))
                    Text(verbatim: place.municipio).textRole(.footnote).foregroundStyle(Color(.ink3))
                    // At accessibility sizes the value moves under the name, so neither breaks mid-word.
                    if isStacked, let value {
                        Text(value).textRole(.value).foregroundStyle(Color(.ink))
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: Spacing.s2)
                // The one trailing value, flush to the trailing edge in every row.
                if !isStacked, let value {
                    Text(value)
                        .textRole(.value)
                        .foregroundStyle(Color(.ink))
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: Size.target, alignment: .leading)
        .padding(.vertical, Spacing.s1)
        .contentShape(.rect)
    }
}
