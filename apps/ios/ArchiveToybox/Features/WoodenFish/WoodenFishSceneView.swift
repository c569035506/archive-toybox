import SwiftUI

struct WoodenFishSceneView: View {
    let phase: KnockPhase

    private let stroke = Color.white

    var body: some View {
        ZStack {
            scene
                .scaleEffect(wrapScale)
                .offset(y: wrapOffsetY)
                .animation(wrapAnimation, value: phase)
        }
        .frame(maxWidth: 360)
        .padding(.vertical, 8)
    }

    private var wrapScale: CGFloat {
        switch phase {
        case .idle: return 1
        case .hit: return 0.95
        case .bounce: return 1
        }
    }

    private var wrapOffsetY: CGFloat {
        switch phase {
        case .idle: return 0
        case .hit: return 5
        case .bounce: return 0
        }
    }

    private var wrapAnimation: Animation? {
        phase == .bounce
            ? .interpolatingSpring(stiffness: 280, damping: 18)
            : .easeOut(duration: 0.05)
    }

    private var scene: some View {
        Canvas { context, size in
            let scale = min(size.width / 360, 1)
            context.scaleBy(x: scale, y: scale)

            drawFish(in: &context)
            drawMonk(in: &context)
            drawMallet(in: &context, knocking: phase == .hit || phase == .bounce)
        }
        .aspectRatio(360 / 260, contentMode: .fit)
        .accessibilityHidden(true)
    }

    private func drawFish(in context: inout GraphicsContext) {
        var fish = Path()
        fish.move(to: CGPoint(x: 28, y: 168))
        fish.addCurve(
            to: CGPoint(x: 198, y: 168),
            control1: CGPoint(x: 28, y: 118),
            control2: CGPoint(x: 68, y: 98)
        )
        fish.addCurve(
            to: CGPoint(x: 28, y: 168),
            control1: CGPoint(x: 198, y: 208),
            control2: CGPoint(x: 162, y: 228)
        )

        context.stroke(
            fish,
            with: .color(stroke),
            style: StrokeStyle(lineWidth: 2.5, lineJoin: .round)
        )

        var line = Path()
        line.move(to: CGPoint(x: 72, y: 166))
        line.addLine(to: CGPoint(x: 132, y: 166))
        context.stroke(line, with: .color(stroke), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))

        let circle = Path(ellipseIn: CGRect(x: 125, y: 159, width: 14, height: 14))
        context.stroke(circle, with: .color(stroke), style: StrokeStyle(lineWidth: 2.5))
    }

    private func drawMonk(in context: inout GraphicsContext) {
        let head = Path(ellipseIn: CGRect(x: 258, y: 68, width: 40, height: 40))
        context.stroke(head, with: .color(stroke), style: StrokeStyle(lineWidth: 2.5))

        var body = Path()
        body.move(to: CGPoint(x: 258, y: 108))
        body.addQuadCurve(to: CGPoint(x: 252, y: 158), control: CGPoint(x: 248, y: 130))
        body.addQuadCurve(to: CGPoint(x: 272, y: 200), control: CGPoint(x: 256, y: 188))
        body.addLine(to: CGPoint(x: 300, y: 202))
        body.addQuadCurve(to: CGPoint(x: 312, y: 162), control: CGPoint(x: 318, y: 188))
        body.addLine(to: CGPoint(x: 308, y: 128))
        body.addQuadCurve(to: CGPoint(x: 290, y: 102), control: CGPoint(x: 302, y: 108))
        context.stroke(body, with: .color(stroke), style: StrokeStyle(lineWidth: 2.5, lineJoin: .round))

        var robe = Path()
        robe.move(to: CGPoint(x: 268, y: 200))
        robe.addLine(to: CGPoint(x: 248, y: 218))
        robe.addLine(to: CGPoint(x: 272, y: 222))
        robe.addLine(to: CGPoint(x: 298, y: 218))
        robe.addLine(to: CGPoint(x: 284, y: 200))
        context.stroke(robe, with: .color(stroke), style: StrokeStyle(lineWidth: 2.5, lineJoin: .round))

        var arm = Path()
        arm.move(to: CGPoint(x: 290, y: 102))
        arm.addLine(to: CGPoint(x: 262, y: 118))
        context.stroke(arm, with: .color(stroke), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
    }

    private func drawMallet(in context: inout GraphicsContext, knocking: Bool) {
        let rotation = knocking ? 24.0 : -8.0
        let origin = CGPoint(x: 258, y: 116)
        let tip = CGPoint(x: 148, y: 148)

        var transform = CGAffineTransform(translationX: origin.x, y: origin.y)
        transform = transform.rotated(by: rotation * .pi / 180)
        transform = transform.translatedBy(x: -origin.x, y: -origin.y)

        var stick = Path()
        stick.move(to: CGPoint(x: 262, y: 118))
        stick.addLine(to: tip)
        context.stroke(
            stick.applying(transform),
            with: .color(stroke),
            style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
        )

        let head = Path(ellipseIn: CGRect(x: 141, y: 141, width: 14, height: 14))
        context.fill(head.applying(transform), with: .color(stroke))
    }
}
