import SwiftUI

enum ToyRoute: Hashable {
    case woodenFish
    case luckyCat
    case argument
    case meditation
}

struct ArgumentScore: Identifiable {
    let id: String
    let label: String
    let value: Double
}

struct ArgumentReview {
    let title: String
    let finalScore: Double
    let scores: [ArgumentScore]
    let bestQuote: String
    let summary: String
    let improvementTip: String

    init(from dto: PracticeReviewDTO, bestQuote: String? = nil) {
        title = dto.title
        scores = dto.scores.asArgumentScores
        finalScore = scores.map(\.value).reduce(0, +) / Double(max(scores.count, 1))
        summary = dto.summary
        self.bestQuote = bestQuote ?? dto.poster?.bestQuote ?? "我已经在努力了。"
        improvementTip = "下一次可以在表达边界时增加一句对对方需求的承接。"
    }
}

struct MeditationTrack: Identifiable, Hashable {
    let id: String
    let title: String
    let categoryLabel: String
    let resourceName: String
    let fileExtension: String
    let duration: TimeInterval

    init(dto: MeditationTrackDTO) {
        id = dto.id
        title = dto.title
        categoryLabel = dto.category.replacingOccurrences(of: "_", with: " ")
        let filename = dto.audioUrl.replacingOccurrences(of: "/audio/", with: "")
        if let dot = filename.lastIndex(of: ".") {
            resourceName = String(filename[..<dot])
            fileExtension = String(filename[filename.index(after: dot)...])
        } else {
            resourceName = filename
            fileExtension = "wav"
        }
        duration = TimeInterval(dto.durationSec)
    }

    init(
        id: String,
        title: String,
        categoryLabel: String,
        resourceName: String,
        fileExtension: String = "wav",
        duration: TimeInterval
    ) {
        self.id = id
        self.title = title
        self.categoryLabel = categoryLabel
        self.resourceName = resourceName
        self.fileExtension = fileExtension
        self.duration = duration
    }
}
