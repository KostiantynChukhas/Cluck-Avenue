import Foundation

struct HarvestChallenge: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let emoji: String
    let reward: Int
    let type: ChallengeType
    var isCompleted: Bool = false

    enum ChallengeType { case game, trivia, coop, streak }

    static func todaysChallenges() -> [HarvestChallenge] {
        let all: [HarvestChallenge] = [
            HarvestChallenge(title: "Seed Collector",    description: "Collect 25 seeds in Seed Sprint",     emoji: "🌾", reward: 50, type: .game),
            HarvestChallenge(title: "Sunrise Scholar",   description: "Answer 5 nature trivia correctly",    emoji: "🌅", reward: 35, type: .trivia),
            HarvestChallenge(title: "New Arrival",       description: "Open a Nest Box",                     emoji: "🪺", reward: 25, type: .coop),
            HarvestChallenge(title: "Morning Routine",   description: "Open the app at dawn",                emoji: "🌄", reward: 10, type: .streak),
            HarvestChallenge(title: "Rain Dance",        description: "Score 500+ in Rain Catch",            emoji: "🌧️", reward: 40, type: .game),
            HarvestChallenge(title: "Field Notes",       description: "Complete a full trivia round",        emoji: "📋", reward: 30, type: .trivia),
        ]
        return Array(all.shuffled().prefix(3))
    }
}
