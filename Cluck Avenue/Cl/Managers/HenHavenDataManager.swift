import Foundation
import Combine

class HenHavenDataManager: ObservableObject {
    @Published var hasCompletedOnboarding: Bool
    @Published var farmerName: String
    @Published var seeds: Int                   // currency (seeds instead of coins)
    @Published var streakDays: Int
    @Published var lastOpenedDate: Date?
    @Published var unlockedHens: [UUID]
    @Published var highScoreSeedSprint: Int
    @Published var highScoreRainCatch: Int
    @Published var totalTriviaCorrect: Int
    @Published var nestBoxesAvailable: Int
    @Published var dailyChallenges: [HarvestChallenge]

    private let defaults = UserDefaults.standard

    init() {
        hasCompletedOnboarding = defaults.bool(forKey: "hh_onboarded")
        farmerName             = defaults.string(forKey: "hh_name") ?? "Farmer Friend"
        seeds                  = defaults.integer(forKey: "hh_seeds")
        streakDays             = defaults.integer(forKey: "hh_streak")
        highScoreSeedSprint    = defaults.integer(forKey: "hh_score_sprint")
        highScoreRainCatch     = defaults.integer(forKey: "hh_score_rain")
        totalTriviaCorrect     = defaults.integer(forKey: "hh_trivia")
        nestBoxesAvailable     = max(defaults.integer(forKey: "hh_nests"), 1)
        lastOpenedDate         = defaults.object(forKey: "hh_lastOpen") as? Date
        dailyChallenges        = HarvestChallenge.todaysChallenges()

        if let saved = defaults.array(forKey: "hh_hens") as? [String] {
            unlockedHens = saved.compactMap { UUID(uuidString: $0) }
        } else {
            unlockedHens = Hen.all.filter(\.isUnlocked).map(\.id)
        }
        updateStreak()
    }

    // MARK: — Onboarding
    func completeOnboarding() {
        hasCompletedOnboarding = true
        defaults.set(true, forKey: "hh_onboarded")
    }

    // MARK: — Name
    func updateFarmerName(_ name: String) {
        let t = name.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        farmerName = t
        defaults.set(t, forKey: "hh_name")
    }

    // MARK: — Seeds (currency)
    func addSeeds(_ amount: Int) {
        seeds += amount
        defaults.set(seeds, forKey: "hh_seeds")
    }

    func spendSeeds(_ amount: Int) -> Bool {
        guard seeds >= amount else { return false }
        seeds -= amount
        defaults.set(seeds, forKey: "hh_seeds")
        return true
    }

    // MARK: — Game scores
    func updateHighScoreSeedSprint(_ score: Int) {
        if score > highScoreSeedSprint {
            highScoreSeedSprint = score
            defaults.set(score, forKey: "hh_score_sprint")
        }
    }

    func updateHighScoreRainCatch(_ score: Int) {
        if score > highScoreRainCatch {
            highScoreRainCatch = score
            defaults.set(score, forKey: "hh_score_rain")
        }
    }

    // MARK: — Trivia
    func recordCorrectTrivia() {
        totalTriviaCorrect += 1
        defaults.set(totalTriviaCorrect, forKey: "hh_trivia")
    }

    // MARK: — Nest box (chest equivalent)
    func addNestBox() {
        nestBoxesAvailable += 1
        defaults.set(nestBoxesAvailable, forKey: "hh_nests")
    }

    func openNestBox() -> Hen? {
        guard nestBoxesAvailable > 0 else { return nil }
        nestBoxesAvailable -= 1
        defaults.set(nestBoxesAvailable, forKey: "hh_nests")

        let locked = Hen.all.filter { !unlockedHens.contains($0.id) }
        guard !locked.isEmpty else { return nil }

        let rand = Double.random(in: 0...1)
        let pool: [Hen]
        if rand < 0.03        { pool = locked.filter { $0.rarity == .legendary }
        } else if rand < 0.15 { pool = locked.filter { $0.rarity == .epic }
        } else if rand < 0.40 { pool = locked.filter { $0.rarity == .rare }
        } else                { pool = locked.filter { $0.rarity == .common } }

        let winner = (pool.isEmpty ? locked : pool).randomElement()
        if let w = winner {
            unlockedHens.append(w.id)
            defaults.set(unlockedHens.map(\.uuidString), forKey: "hh_hens")
        }
        return winner
    }

    // MARK: — Streak
    private func updateStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        if let last = lastOpenedDate {
            let lastDay = Calendar.current.startOfDay(for: last)
            let diff = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0
            if diff == 1     { streakDays += 1 }
            else if diff > 1 { streakDays = 1 }
        } else {
            streakDays = 1
        }
        lastOpenedDate = Date()
        defaults.set(streakDays, forKey: "hh_streak")
        defaults.set(Date(), forKey: "hh_lastOpen")
    }

    // MARK: — Challenges
    func completeChallenge(id: UUID) {
        if let idx = dailyChallenges.firstIndex(where: { $0.id == id }) {
            dailyChallenges[idx].isCompleted = true
            addSeeds(dailyChallenges[idx].reward)
        }
    }

    var allChallengesCompleted: Bool {
        dailyChallenges.allSatisfy(\.isCompleted)
    }
}
