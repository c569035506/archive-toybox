import SwiftUI

struct ArgumentReviewView: View {
    let review: ArgumentReview

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                VStack(spacing: 8) {
                    Text("本局吵架复盘")
                        .font(.largeTitle.bold())
                    Text("你不是在吵赢谁，而是在练习把话说清楚。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 14) {
                    Text("《\(review.title)》")
                        .font(.title.bold())
                    Text(String(format: "%.1f / 5", review.finalScore))
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(.cyan)
                    RadarChartView(scores: review.scores)
                        .frame(height: 260)
                }
                .padding(22)
                .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 28))

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(review.scores) { score in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(score.label)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.1f", score.value))
                                .font(.title3.bold())
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18))
                    }
                }

                ReportBlock(title: "本局金句", body: "“\(review.bestQuote)”")
                if !review.highlights.isEmpty {
                    ReportBlock(
                        title: "做得好的点",
                        body: review.highlights.map { "• \($0)" }.joined(separator: "\n")
                    )
                }
                ReportBlock(title: "AI 改进建议", body: review.improvementTip)

                NavigationLink("生成分享海报") {
                    PosterPreviewView(review: review)
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
            }
            .padding(20)
        }
        .background(AppBackground())
        .navigationTitle("本局复盘")
    }
}

struct RadarChartView: View {
    let scores: [ArgumentScore]

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let radius = size * 0.36

            ZStack {
                ForEach(1...5, id: \.self) { level in
                    Polygon(points: points(center: center, radius: radius * CGFloat(level) / 5, values: Array(repeating: 1, count: scores.count)))
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                }

                ForEach(scores.indices, id: \.self) { index in
                    Path { path in
                        path.move(to: center)
                        path.addLine(to: axisPoint(center: center, radius: radius, index: index, count: scores.count))
                    }
                    .stroke(.white.opacity(0.12), lineWidth: 1)
                }

                Polygon(points: points(center: center, radius: radius, values: scores.map { $0.value / 5 }))
                    .fill(Color.cyan.opacity(0.28))
                Polygon(points: points(center: center, radius: radius, values: scores.map { $0.value / 5 }))
                    .stroke(Color.cyan, lineWidth: 2)

                ForEach(scores.indices, id: \.self) { index in
                    let point = axisPoint(center: center, radius: radius + 28, index: index, count: scores.count)
                    Text(scores[index].label)
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(width: 64)
                        .position(point)
                }
            }
        }
    }

    private func points(center: CGPoint, radius: CGFloat, values: [Double]) -> [CGPoint] {
        values.indices.map { index in
            axisPoint(center: center, radius: radius * CGFloat(values[index]), index: index, count: values.count)
        }
    }

    private func axisPoint(center: CGPoint, radius: CGFloat, index: Int, count: Int) -> CGPoint {
        let angle = (Double(index) / Double(count)) * 2 * Double.pi - Double.pi / 2
        return CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
    }
}

struct Polygon: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }
}

struct PosterPreviewView: View {
    let review: ArgumentReview
    @StateObject private var saver = PhotoSaver()

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                SharePosterView(review: review)
                    .frame(width: 300, height: 400)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(radius: 20)

                Button("保存图片到相册") {
                    saver.save(view: SharePosterView(review: review), size: CGSize(width: 1080, height: 1440))
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)

                if let message = saver.message {
                    Text(message)
                        .font(.footnote.bold())
                        .foregroundStyle(.secondary)
                }
            }
            .padding(20)
        }
        .background(AppBackground())
        .navigationTitle("分享海报")
    }
}

struct SharePosterView: View {
    let review: ArgumentReview

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.04, green: 0.06, blue: 0.12), Color(red: 0.07, green: 0.12, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)

            VStack(spacing: 28) {
                VStack(spacing: 8) {
                    Text("存档玩具盒｜好好吵架")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(.cyan)
                    Text("练习把话说清楚，而不是把关系说坏。")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }

                Text("《\(review.title)》")
                    .font(.system(size: 78, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)

                Text(String(format: "%.1f / 5", review.finalScore))
                    .font(.system(size: 88, weight: .black, design: .rounded))
                    .foregroundStyle(.cyan)

                RadarChartView(scores: review.scores)
                    .frame(height: 360)

                VStack(spacing: 10) {
                    Text("本局金句")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.cyan)
                    Text("“\(review.bestQuote)”")
                        .font(.system(size: 36, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                }

                Text(review.summary)
                    .font(.system(size: 30, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.75))

                Spacer()

                Text("扫码一起练习好好吵架")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white.opacity(0.68))
            }
            .padding(72)
        }
    }
}
