import SwiftUI

/// The five levels as ink sketches (direction §1.1 "C · Papel y tinta",
/// DirC-Progress): a reached level's sketch has its wash, the next one
/// fills from the bottom as points come in, the rest are line only. The
/// shape carries it and a word says it (Logrado / Siguiente), never colour
/// alone. Reduce Motion skips the fill animation; crisis shows no art.
struct LevelLadder: View {
    let progress: Progress

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .caption) private var size: CGFloat = 52

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.s2) {
            ForEach(Progress.Level.allCases, id: \.self) { level in
                VStack(spacing: Spacing.s1) {
                    sketch(level)
                        .frame(width: min(size, 72), height: min(size, 72))
                    Text("Nivel \(level.rawValue)", comment: "A level's number under its sketch")
                        .textRole(.caption)
                        .foregroundStyle(Color(level <= progress.level ? .ink : .ink3))
                        .fontWeight(level == progress.level ? .semibold : .regular)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(level.title))
                .accessibilityValue(Text(state(level)))
            }
        }
    }

    @ViewBuilder
    private func sketch(_ level: Progress.Level) -> some View {
        let image = Image(level.vignette).resizable().scaledToFit()
        if level <= progress.level {
            image
        } else {
            let fill = level == progress.level.next ? progress.levelFraction : 0
            ZStack {
                image.saturation(0).opacity(0.45)
                image.mask(alignment: .bottom) {
                    GeometryReader { proxy in
                        Rectangle()
                            .frame(height: proxy.size.height * fill)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                    }
                }
            }
            .animation(reduceMotion ? nil : .easeOut(duration: 0.6), value: fill)
        }
    }

    private func state(_ level: Progress.Level) -> LocalizedStringResource {
        if level < progress.level {
            return LocalizedStringResource("Logrado", comment: "Level state: reached")
        }
        if level == progress.level {
            return LocalizedStringResource("Tu nivel", comment: "Level state: your current level")
        }
        if level == progress.level.next {
            return LocalizedStringResource("Siguiente", comment: "Level state: the next level")
        }
        return LocalizedStringResource("Más adelante", comment: "Level state: a later level")
    }
}
