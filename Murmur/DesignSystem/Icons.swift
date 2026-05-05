import SwiftUI

/// Original glyph set drawn as inline shapes — matches the design package's
/// `MMIcon` registry. We intentionally avoid SF Symbols so the marks read as
/// Murmur's own (per the design intent: "original — not lifted from Apple").
enum MMIcon: String, CaseIterable {
    case waveform, phone, map, gear, plus, search, chevron, chevronL, chevronD
    case play, pause, skipB, skipF, stop, mic, lock, person, dots, bookmark
    case check, square, sparkle, quote, download, cpu
}

struct MMIconView: View {
    let icon: MMIcon
    var size: CGFloat = 18
    var color: Color = .primary
    var weight: CGFloat = 1.8

    var body: some View {
        Canvas { ctx, _ in
            let s = size
            let scale = s / 24.0
            ctx.scaleBy(x: scale, y: scale)
            draw(into: &ctx)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private func draw(into ctx: inout GraphicsContext) {
        let line = StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round)
        switch icon {
        case .waveform:
            for (x, h) in [(3.0, 6.0), (6.5, 12.0), (10.0, 19.0), (13.5, 14.0), (17.0, 8.0), (20.5, 4.0)] {
                let mid = 12.0
                var p = Path()
                p.move(to: .init(x: x, y: mid - h/2))
                p.addLine(to: .init(x: x, y: mid + h/2))
                ctx.stroke(p, with: .color(color), style: line)
            }
        case .phone:
            var p = Path()
            p.move(to: .init(x: 5, y: 4))
            p.addCurve(to: .init(x: 6.8, y: 2),
                       control1: .init(x: 5, y: 3), control2: .init(x: 5.8, y: 2))
            p.addLine(to: .init(x: 9.2, y: 2))
            p.addCurve(to: .init(x: 10.7, y: 3.2),
                       control1: .init(x: 9.9, y: 2), control2: .init(x: 10.5, y: 2.5))
            p.addLine(to: .init(x: 11.4, y: 5.9))
            p.addCurve(to: .init(x: 10.7, y: 7.8),
                       control1: .init(x: 11.6, y: 6.6), control2: .init(x: 11.3, y: 7.4))
            p.addLine(to: .init(x: 9, y: 9.2))
            p.addCurve(to: .init(x: 14.4, y: 14.6),
                       control1: .init(x: 10, y: 11.6), control2: .init(x: 12, y: 13.6))
            p.addLine(to: .init(x: 15.8, y: 12.9))
            p.addCurve(to: .init(x: 17.7, y: 12.2),
                       control1: .init(x: 16.2, y: 12.3), control2: .init(x: 17, y: 12))
            p.addLine(to: .init(x: 20.4, y: 12.9))
            p.addCurve(to: .init(x: 21.6, y: 14.4),
                       control1: .init(x: 21.1, y: 13.1), control2: .init(x: 21.6, y: 13.7))
            p.addLine(to: .init(x: 21.6, y: 16.8))
            p.addCurve(to: .init(x: 19.6, y: 18.6),
                       control1: .init(x: 21.6, y: 17.8), control2: .init(x: 20.6, y: 18.6))
            p.addCurve(to: .init(x: 5, y: 4),
                       control1: .init(x: 10.6, y: 18.6), control2: .init(x: 5.4, y: 13.4))
            p.closeSubpath()
            ctx.fill(p, with: .color(color))
        case .map:
            // three nodes connected by lines
            for c in [(12.0, 5.0), (5.0, 17.0), (19.0, 17.0)] {
                ctx.fill(Path(ellipseIn: CGRect(x: c.0 - 2.2, y: c.1 - 2.2, width: 4.4, height: 4.4)),
                         with: .color(color))
            }
            for seg in [(11.0, 7.0, 6.5, 15.5), (13.0, 7.0, 17.5, 15.5)] {
                var p = Path()
                p.move(to: .init(x: seg.0, y: seg.1))
                p.addLine(to: .init(x: seg.2, y: seg.3))
                ctx.stroke(p, with: .color(color), style: line)
            }
            var dashed = Path()
            dashed.move(to: .init(x: 7.5, y: 17))
            dashed.addLine(to: .init(x: 16.5, y: 17))
            ctx.stroke(dashed, with: .color(color),
                       style: StrokeStyle(lineWidth: weight, dash: [2, 2]))
        case .gear:
            ctx.stroke(Path(ellipseIn: CGRect(x: 9, y: 9, width: 6, height: 6)),
                       with: .color(color), style: line)
            for spoke in [(12.0, 2.0, 12.0, 5.0), (12.0, 19.0, 12.0, 22.0),
                          (4.2, 4.2, 6.3, 6.3), (17.7, 17.7, 19.8, 19.8),
                          (2.0, 12.0, 5.0, 12.0), (19.0, 12.0, 22.0, 12.0),
                          (4.2, 19.8, 6.3, 17.7), (17.7, 6.3, 19.8, 4.2)] {
                var p = Path()
                p.move(to: .init(x: spoke.0, y: spoke.1))
                p.addLine(to: .init(x: spoke.2, y: spoke.3))
                ctx.stroke(p, with: .color(color), style: line)
            }
        case .plus:
            var p = Path()
            p.move(to: .init(x: 12, y: 5)); p.addLine(to: .init(x: 12, y: 19))
            p.move(to: .init(x: 5, y: 12)); p.addLine(to: .init(x: 19, y: 12))
            ctx.stroke(p, with: .color(color),
                       style: StrokeStyle(lineWidth: weight + 0.4, lineCap: .round))
        case .search:
            ctx.stroke(Path(ellipseIn: CGRect(x: 4.5, y: 4.5, width: 13, height: 13)),
                       with: .color(color), style: line)
            var p = Path()
            p.move(to: .init(x: 16, y: 16)); p.addLine(to: .init(x: 20.5, y: 20.5))
            ctx.stroke(p, with: .color(color), style: line)
        case .chevron:
            chevron(into: &ctx, points: [(9, 5), (16, 12), (9, 19)])
        case .chevronL:
            chevron(into: &ctx, points: [(15, 5), (8, 12), (15, 19)])
        case .chevronD:
            chevron(into: &ctx, points: [(5, 9), (12, 16), (19, 9)])
        case .play:
            var p = Path()
            p.move(to: .init(x: 7, y: 4))
            p.addLine(to: .init(x: 7, y: 20))
            p.addLine(to: .init(x: 20, y: 12))
            p.closeSubpath()
            ctx.fill(p, with: .color(color))
        case .pause:
            ctx.fill(Path(roundedRect: CGRect(x: 6, y: 4, width: 4, height: 16),
                          cornerRadius: 1.2), with: .color(color))
            ctx.fill(Path(roundedRect: CGRect(x: 14, y: 4, width: 4, height: 16),
                          cornerRadius: 1.2), with: .color(color))
        case .skipB:
            var p = Path()
            p.move(to: .init(x: 14, y: 4))
            p.addLine(to: .init(x: 14, y: 20))
            p.addLine(to: .init(x: 4, y: 12))
            p.closeSubpath()
            ctx.fill(p, with: .color(color))
            ctx.fill(Path(roundedRect: CGRect(x: 16, y: 4, width: 3, height: 16), cornerRadius: 1),
                     with: .color(color))
        case .skipF:
            var p = Path()
            p.move(to: .init(x: 10, y: 4))
            p.addLine(to: .init(x: 10, y: 20))
            p.addLine(to: .init(x: 20, y: 12))
            p.closeSubpath()
            ctx.fill(p, with: .color(color))
            ctx.fill(Path(roundedRect: CGRect(x: 5, y: 4, width: 3, height: 16), cornerRadius: 1),
                     with: .color(color))
        case .stop:
            ctx.fill(Path(roundedRect: CGRect(x: 6, y: 6, width: 12, height: 12), cornerRadius: 2),
                     with: .color(color))
        case .mic:
            ctx.fill(Path(roundedRect: CGRect(x: 9, y: 2.5, width: 6, height: 12), cornerRadius: 3),
                     with: .color(color))
            var arc = Path()
            arc.addArc(center: .init(x: 12, y: 11), radius: 6.5,
                       startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
            ctx.stroke(arc, with: .color(color), style: line)
            var stem = Path()
            stem.move(to: .init(x: 12, y: 17.5)); stem.addLine(to: .init(x: 12, y: 21))
            stem.move(to: .init(x: 9, y: 21)); stem.addLine(to: .init(x: 15, y: 21))
            ctx.stroke(stem, with: .color(color), style: line)
        case .lock:
            ctx.stroke(Path(roundedRect: CGRect(x: 5, y: 11, width: 14, height: 10), cornerRadius: 2),
                       with: .color(color), style: line)
            var hasp = Path()
            hasp.move(to: .init(x: 8, y: 11))
            hasp.addLine(to: .init(x: 8, y: 8))
            hasp.addArc(center: .init(x: 12, y: 8), radius: 4,
                        startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            hasp.addLine(to: .init(x: 16, y: 11))
            ctx.stroke(hasp, with: .color(color), style: line)
        case .person:
            ctx.fill(Path(ellipseIn: CGRect(x: 8.4, y: 4.4, width: 7.2, height: 7.2)),
                     with: .color(color))
            var arc = Path()
            arc.move(to: .init(x: 5, y: 20))
            arc.addCurve(to: .init(x: 19, y: 20),
                         control1: .init(x: 5, y: 16.5), control2: .init(x: 19, y: 16.5))
            ctx.fill(arc, with: .color(color))
        case .dots:
            for x in [6.0, 12.0, 18.0] {
                ctx.fill(Path(ellipseIn: CGRect(x: x - 1.6, y: 10.4, width: 3.2, height: 3.2)),
                         with: .color(color))
            }
        case .bookmark:
            var p = Path()
            p.move(to: .init(x: 7, y: 3))
            p.addLine(to: .init(x: 17, y: 3))
            p.addLine(to: .init(x: 17, y: 21))
            p.addLine(to: .init(x: 12, y: 17.5))
            p.addLine(to: .init(x: 7, y: 21))
            p.closeSubpath()
            ctx.fill(p, with: .color(color))
        case .check:
            chevron(into: &ctx, points: [(5, 12), (10, 17), (19, 7)],
                    width: weight + 0.3)
        case .square:
            ctx.stroke(Path(roundedRect: CGRect(x: 4.5, y: 4.5, width: 15, height: 15), cornerRadius: 3.5),
                       with: .color(color), style: line)
        case .sparkle:
            var p = Path()
            p.move(to: .init(x: 12, y: 3))
            p.addLine(to: .init(x: 13.5, y: 8))
            p.addLine(to: .init(x: 18, y: 9.5))
            p.addLine(to: .init(x: 13.5, y: 11))
            p.addLine(to: .init(x: 12, y: 16))
            p.addLine(to: .init(x: 10.5, y: 11))
            p.addLine(to: .init(x: 6, y: 9.5))
            p.addLine(to: .init(x: 10.5, y: 8))
            p.closeSubpath()
            ctx.fill(p, with: .color(color))
        case .quote:
            var p = Path()
            p.addRect(.init(x: 6, y: 10, width: 4, height: 4))
            p.addRect(.init(x: 14, y: 10, width: 4, height: 4))
            ctx.fill(p, with: .color(color))
        case .download:
            var p = Path()
            p.move(to: .init(x: 12, y: 4)); p.addLine(to: .init(x: 12, y: 16))
            p.move(to: .init(x: 7, y: 11))
            p.addLine(to: .init(x: 12, y: 16))
            p.addLine(to: .init(x: 17, y: 11))
            p.move(to: .init(x: 5, y: 20)); p.addLine(to: .init(x: 19, y: 20))
            ctx.stroke(p, with: .color(color), style: line)
        case .cpu:
            ctx.stroke(Path(roundedRect: CGRect(x: 6, y: 6, width: 12, height: 12), cornerRadius: 2),
                       with: .color(color), style: line)
            ctx.stroke(Path(roundedRect: CGRect(x: 9, y: 9, width: 6, height: 6), cornerRadius: 1),
                       with: .color(color), style: line)
            for seg in [(3.0, 10.0, 5.0, 10.0), (3.0, 14.0, 5.0, 14.0),
                        (19.0, 10.0, 21.0, 10.0), (19.0, 14.0, 21.0, 14.0),
                        (10.0, 3.0, 10.0, 5.0), (14.0, 3.0, 14.0, 5.0),
                        (10.0, 19.0, 10.0, 21.0), (14.0, 19.0, 14.0, 21.0)] {
                var p = Path()
                p.move(to: .init(x: seg.0, y: seg.1))
                p.addLine(to: .init(x: seg.2, y: seg.3))
                ctx.stroke(p, with: .color(color), style: line)
            }
        }
    }

    private func chevron(into ctx: inout GraphicsContext,
                         points: [(Double, Double)],
                         width: CGFloat? = nil) {
        var p = Path()
        guard let first = points.first else { return }
        p.move(to: .init(x: first.0, y: first.1))
        for pt in points.dropFirst() {
            p.addLine(to: .init(x: pt.0, y: pt.1))
        }
        ctx.stroke(p, with: .color(color),
                   style: StrokeStyle(lineWidth: width ?? weight,
                                      lineCap: .round, lineJoin: .round))
    }
}
