import SwiftUI

// ════════════════════════════════════════════════════════════
// MARK: — Games Hub
// ════════════════════════════════════════════════════════════
struct HenHavenGamesHubView: View {
    @EnvironmentObject var data: HenHavenDataManager
    @State private var selected: GamePick? = nil

    enum GamePick: String, Identifiable {
        case sprint = "Seed Sprint"
        case rain   = "Rain Catch"
        var id: String { rawValue }
    }

    var body: some View {
        NavigationView {
            ZStack {
                HenHavenTheme.parchmentGrad.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        Text("Choose your game:")
                            .font(HenHavenTheme.body(14))
                            .foregroundColor(HenHavenTheme.soil)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

                        gameCard(pick: .sprint, emoji: "🌾", title: "Seed Sprint",
                                 desc: "Run through meadows, jump obstacles, collect seeds!",
                                 color: HenHavenTheme.meadow, best: data.highScoreSeedSprint)
                        gameCard(pick: .rain, emoji: "🌧️", title: "Rain Catch",
                                 desc: "Catch raindrops and berries. Avoid hailstones!",
                                 color: HenHavenTheme.pond, best: data.highScoreRainCatch)
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Games 🎮")
            .fullScreenCover(item: $selected) { pick in
                if pick == .sprint {
                    SeedSprintGameView().environmentObject(data)
                } else {
                    RainCatchGameView().environmentObject(data)
                }
            }
        }
    }

    private func gameCard(pick: GamePick, emoji: String, title: String, desc: String, color: Color, best: Int) -> some View {
        Button(action: { selected = pick }) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(color.opacity(0.18))
                        .frame(width: 68, height: 68)
                    Text(emoji).font(.system(size: 40))
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(HenHavenTheme.title(19))
                        .foregroundColor(HenHavenTheme.bark)
                    Text(desc)
                        .font(HenHavenTheme.body(13))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    Text("Best: \(best) pts")
                        .font(HenHavenTheme.caption(12))
                        .foregroundColor(color)
                }
                Spacer()
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(color)
            }
            .padding(16)
            .background(Color.white.opacity(0.85))
            .cornerRadius(20)
            .shadow(color: color.opacity(0.18), radius: 10, y: 4)
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }
}

// ════════════════════════════════════════════════════════════
// MARK: — Nature Trivia Quiz
// ════════════════════════════════════════════════════════════
struct HenHavenQuizView: View {
    @EnvironmentObject var data: HenHavenDataManager

    @State private var questions  = NatureQuestion.bank.shuffled()
    @State private var current    = 0
    @State private var selected: Int? = nil
    @State private var showFact   = false
    @State private var correct    = 0
    @State private var done       = false
    @State private var earned     = 0

    var body: some View {
        NavigationView {
            ZStack {
                HenHavenTheme.parchmentGrad.ignoresSafeArea()
                if done { resultView } else { questionView }
            }
            .navigationTitle("Nature Trivia 🌿")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: Question
    private var questionView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Progress
                VStack(spacing: 6) {
                    HStack {
                        Text("Question \(current + 1) of \(questions.count)")
                            .font(HenHavenTheme.caption(13)).foregroundColor(.secondary)
                        Spacer()
                        Text(questions[current].category.rawValue)
                            .font(HenHavenTheme.caption(12))
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(HenHavenTheme.mint)
                            .cornerRadius(8)
                    }
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            Capsule().fill(HenHavenTheme.mint)
                            Capsule()
                                .fill(HenHavenTheme.meadowGrad)
                                .frame(width: g.size.width * CGFloat(current) / CGFloat(questions.count))
                        }
                    }
                    .frame(height: 8)
                }
                .padding(.horizontal, 20)

                // Question card
                Text(questions[current].question)
                    .font(HenHavenTheme.title(20))
                    .foregroundColor(HenHavenTheme.bark)
                    .multilineTextAlignment(.center)
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(20)
                    .padding(.horizontal, 16)

                // Options
                ForEach(Array(questions[current].options.enumerated()), id: \.offset) { idx, opt in
                    Button(action: { answerTapped(idx) }) {
                        HStack {
                            Text(opt)
                                .font(HenHavenTheme.body(16))
                                .foregroundColor(optTextColor(idx))
                            Spacer()
                            if let sel = selected {
                                Image(systemName: idx == questions[current].correctIndex ? "checkmark.circle.fill" : (idx == sel ? "xmark.circle.fill" : ""))
                                    .foregroundColor(idx == questions[current].correctIndex ? HenHavenTheme.meadow : HenHavenTheme.berry)
                            }
                        }
                        .padding(16)
                        .background(optBg(idx))
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(optStroke(idx), lineWidth: 2))
                        .padding(.horizontal, 16)
                    }
                    .disabled(selected != nil)
                }

                // Fun fact
                if showFact {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("🌿 Fun Fact")
                            .font(HenHavenTheme.title(14)).foregroundColor(HenHavenTheme.forest)
                        Text(questions[current].funFact)
                            .font(HenHavenTheme.body(14)).foregroundColor(HenHavenTheme.soil)
                    }
                    .padding(16)
                    .background(HenHavenTheme.mint)
                    .cornerRadius(14)
                    .padding(.horizontal, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))

                    Button(current < questions.count - 1 ? "Next →" : "Finish 🌻") { nextQuestion() }
                        .font(HenHavenTheme.title(18))
                        .foregroundColor(.white)
                        .padding(.horizontal, 40).padding(.vertical, 14)
                        .background(HenHavenTheme.meadowGrad)
                        .cornerRadius(18)
                        .padding(.bottom, 20)
                }
            }
            .padding(.top, 16)
        }
    }

    private func optBg(_ idx: Int) -> Color {
        guard let sel = selected else { return Color.white.opacity(0.85) }
        if idx == questions[current].correctIndex { return HenHavenTheme.mint }
        if idx == sel { return HenHavenTheme.berry.opacity(0.12) }
        return Color.white.opacity(0.85)
    }

    private func optStroke(_ idx: Int) -> Color {
        guard let sel = selected else { return Color.clear }
        if idx == questions[current].correctIndex { return HenHavenTheme.meadow }
        if idx == sel { return HenHavenTheme.berry }
        return Color.clear
    }

    private func optTextColor(_ idx: Int) -> Color {
        guard selected != nil else { return HenHavenTheme.bark }
        if idx == questions[current].correctIndex { return HenHavenTheme.forest }
        return HenHavenTheme.bark
    }

    private func answerTapped(_ idx: Int) {
        guard selected == nil else { return }
        selected = idx
        showFact = true
        if idx == questions[current].correctIndex {
            correct += 1
            earned += 15
            data.recordCorrectTrivia()
            data.addSeeds(15)
        }
    }

    private func nextQuestion() {
        if current < questions.count - 1 {
            withAnimation { current += 1; selected = nil; showFact = false }
        } else {
            done = true
        }
    }

    // MARK: Result
    private var resultView: some View {
        VStack(spacing: 20) {
            Text(correct >= questions.count / 2 ? "🌻 Well Done!" : "🌱 Keep Growing!")
                .font(HenHavenTheme.title(32)).foregroundColor(HenHavenTheme.forest)
            Text("\(correct)/\(questions.count) correct")
                .font(HenHavenTheme.body(20)).foregroundColor(HenHavenTheme.soil)
            Text("You earned \(earned) 🌱")
                .font(HenHavenTheme.title(18)).foregroundColor(HenHavenTheme.clay)
            Button("Play Again 🔄") {
                questions = NatureQuestion.bank.shuffled()
                current = 0; selected = nil; showFact = false
                correct = 0; earned = 0; done = false
            }
            .font(HenHavenTheme.title(18)).foregroundColor(.white)
            .padding(.horizontal, 40).padding(.vertical, 14)
            .background(HenHavenTheme.meadowGrad).cornerRadius(18)
        }
        .padding(32)
    }
}

// ════════════════════════════════════════════════════════════
// MARK: — Coop (Collection)
// ════════════════════════════════════════════════════════════
struct HenHavenCoopView: View {
    @EnvironmentObject var data: HenHavenDataManager
    @State private var filter: HenRarity? = nil
    @State private var openedHen: Hen? = nil
    @State private var showResult = false

    private var filtered: [Hen] {
        guard let f = filter else { return Hen.all }
        return Hen.all.filter { $0.rarity == f }
    }

    var body: some View {
        NavigationView {
            ZStack {
                HenHavenTheme.parchmentGrad.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            HHFilterChip(label: "All 🌿", active: filter == nil) { filter = nil }
                            ForEach(HenRarity.allCases, id: \.self) { r in
                                HHFilterChip(label: r.label, active: filter == r) { filter = (filter == r ? nil : r) }
                            }
                        }
                        .padding(.horizontal, 16).padding(.vertical, 10)
                    }

                    // Grid
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(filtered) { hen in
                                HenCardView(hen: hen, unlocked: data.unlockedHens.contains(hen.id))
                            }
                        }
                        .padding(.horizontal, 12).padding(.bottom, 20)
                    }
                }

                // Nest box button
                VStack {
                    Spacer()
                    Button(action: openNestBox) {
                        HStack(spacing: 10) {
                            Image("icon_nest_box")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Open Nest Box")
                                    .font(HenHavenTheme.title(16)).foregroundColor(.white)
                                Text("\(data.nestBoxesAvailable) available")
                                    .font(HenHavenTheme.caption(12)).foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding(.horizontal, 28).padding(.vertical, 14)
                        .background(data.nestBoxesAvailable > 0
                            ? AnyView(HenHavenTheme.meadowGrad)
                            : AnyView(Color.gray))
                        .cornerRadius(22)
                        .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
                    }
                    .disabled(data.nestBoxesAvailable == 0)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("My Coop 🪺")
            .sheet(isPresented: $showResult) {
                if let hen = openedHen {
                    NestBoxResultView(hen: hen)
                }
            }
        }
    }

    private func openNestBox() {
        if let hen = data.openNestBox() { openedHen = hen; showResult = true }
    }
}

struct HenCardView: View {
    let hen: Hen; let unlocked: Bool
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(unlocked ? hen.rarity.color.opacity(0.15) : Color(.systemGray5))
                    .aspectRatio(1, contentMode: .fit)
                if unlocked {
                    Image(hen.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 52, height: 52)
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: "lock.fill").font(.system(size: 20)).foregroundColor(.gray)
                        Text("???").font(HenHavenTheme.caption(10)).foregroundColor(.gray)
                    }
                }
            }
            Text(unlocked ? hen.name : "???")
                .font(HenHavenTheme.caption(11))
                .foregroundColor(unlocked ? HenHavenTheme.bark : .gray)
                .lineLimit(1)
            Text(hen.rarity.label)
                .font(HenHavenTheme.caption(10))
                .foregroundColor(hen.rarity.color)
        }
    }
}

struct NestBoxResultView: View {
    let hen: Hen
    @Environment(\.dismiss) var dismiss
    @State private var scale: CGFloat = 0.3
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("🪺 New Arrival!").font(HenHavenTheme.title(28)).foregroundColor(HenHavenTheme.forest)
            Image(hen.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 140, height: 140)
                .scaleEffect(scale)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: scale)
                .onAppear { scale = 1.0 }
            Text(hen.name).font(HenHavenTheme.title(26)).foregroundColor(HenHavenTheme.bark)
            Text(hen.rarity.label)
                .font(HenHavenTheme.body(16))
                .padding(.horizontal, 16).padding(.vertical, 6)
                .background(hen.rarity.color.opacity(0.2))
                .cornerRadius(10)
            Text(hen.description)
                .font(HenHavenTheme.body(15)).foregroundColor(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 32)
            Spacer()
            Button("Welcome to the Coop! 🌿") { dismiss() }
                .font(HenHavenTheme.title(17)).foregroundColor(.white)
                .padding(.horizontal, 36).padding(.vertical, 14)
                .background(HenHavenTheme.meadowGrad).cornerRadius(20)
                .padding(.bottom, 40)
        }
        .background(HenHavenTheme.parchmentGrad.ignoresSafeArea())
    }
}

// ════════════════════════════════════════════════════════════
// MARK: — Daily Challenges
// ════════════════════════════════════════════════════════════
struct HenHavenChallengesView: View {
    @EnvironmentObject var data: HenHavenDataManager
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationView {
            ZStack {
                HenHavenTheme.parchmentGrad.ignoresSafeArea()
                VStack(spacing: 16) {
                    if data.allChallengesCompleted {
                        VStack(spacing: 12) {
                            Text("🌻 All Done!").font(HenHavenTheme.title(28)).foregroundColor(HenHavenTheme.forest)
                            Text("Bonus Nest Box earned!").font(HenHavenTheme.body(16)).foregroundColor(.secondary)
                        }
                        .padding(.top, 20)
                    }
                    ForEach(data.dailyChallenges) { c in
                        HStack(spacing: 14) {
                            Text(c.emoji).font(.system(size: 32))
                            VStack(alignment: .leading, spacing: 3) {
                                Text(c.title).font(HenHavenTheme.title(16)).foregroundColor(HenHavenTheme.bark)
                                Text(c.description).font(HenHavenTheme.body(13)).foregroundColor(.secondary)
                                Text("+\(c.reward) 🌱").font(HenHavenTheme.caption(12)).foregroundColor(HenHavenTheme.forest)
                            }
                            Spacer()
                            if c.isCompleted {
                                Image(systemName: "checkmark.seal.fill").foregroundColor(HenHavenTheme.meadow).font(.system(size: 24))
                            } else {
                                Button("Go!") { data.completeChallenge(id: c.id) }
                                    .font(HenHavenTheme.title(14)).foregroundColor(.white)
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(HenHavenTheme.meadowGrad).cornerRadius(10)
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(c.isCompleted ? 0.5 : 0.9))
                        .cornerRadius(18)
                        .padding(.horizontal, 16)
                    }
                    Spacer()
                }
                .padding(.top, 16)
            }
            .navigationTitle("Harvest Challenges ⚡")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

// ════════════════════════════════════════════════════════════
// MARK: — Profile
// ════════════════════════════════════════════════════════════
struct HenHavenProfileView: View {
    @EnvironmentObject var data: HenHavenDataManager
    @State private var showEditName = false
    @State private var editingName  = ""

    var body: some View {
        NavigationView {
            ZStack {
                HenHavenTheme.parchmentGrad.ignoresSafeArea()
                List {
                    profileHeader
                    statsSection
                    achievementsSection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Farmer Profile 👤")
            .sheet(isPresented: $showEditName) {
                HHEditNameSheet(name: $editingName) { data.updateFarmerName(editingName) }
            }
        }
    }

    private var profileHeader: some View {
        Section {
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(HenHavenTheme.meadowGrad)
                        .frame(width: 80, height: 80)
                    Text("🐔").font(.system(size: 44))
                }
                HStack(spacing: 8) {
                    Text(data.farmerName).font(HenHavenTheme.title(22))
                    Button(action: { editingName = data.farmerName; showEditName = true }) {
                        Image(systemName: "pencil.circle.fill").font(.system(size: 20)).foregroundColor(HenHavenTheme.forest)
                    }
                }
                Text("Nature Farmer 🌾").font(HenHavenTheme.caption(13)).foregroundColor(.secondary)
                HStack(spacing: 0) {
                    quickStat("\(data.streakDays)", "Streak", "🔥")
                    Divider().frame(height: 36)
                    quickStat("\(data.seeds)", "Seeds", "🌱")
                    Divider().frame(height: 36)
                    quickStat("\(data.unlockedHens.count)/\(Hen.all.count)", "Coop", "🪺")
                }
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(14)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 12)
        }
    }

    private func quickStat(_ v: String, _ l: String, _ i: String) -> some View {
        VStack(spacing: 3) {
            if i == "🌱" {
                Image("ui_seed")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
            } else if i == "🪺" {
                Image("icon_nest_box")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
            } else {
                Text(i).font(.system(size: 18))
            }
            Text(v).font(HenHavenTheme.title(16))
            Text(l).font(HenHavenTheme.caption(10)).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var statsSection: some View {
        Section("📊 Stats") {
            HHStatRow("🔥", "Streak",          "\(data.streakDays) days")
            HHStatRow("🌱", "Seeds",            "\(data.seeds)")
            HHStatRow("🌾", "Seed Sprint Best", "\(data.highScoreSeedSprint) pts")
            HHStatRow("🌧️", "Rain Catch Best",  "\(data.highScoreRainCatch) pts")
            HHStatRow("🧠", "Trivia Correct",   "\(data.totalTriviaCorrect)")
            HHStatRow("🪺", "Coop",             "\(data.unlockedHens.count)/\(Hen.all.count)")
        }
    }

    private var achievementsSection: some View {
        Section("🏆 Achievements") {
            HHAchRow(emoji: "🌾", title: "First Harvest",    desc: "Play Seed Sprint once",             done: data.highScoreSeedSprint > 0)
            HHAchRow(emoji: "🌧️", title: "Rain Dancer",      desc: "Score 100+ in Rain Catch",          done: data.highScoreRainCatch >= 100)
            HHAchRow(emoji: "🔥", title: "Consistent",       desc: "Reach a 7-day streak",              done: data.streakDays >= 7)
            HHAchRow(emoji: "🌿", title: "Field Scholar",    desc: "Answer 30 trivia correctly",        done: data.totalTriviaCorrect >= 30)
            HHAchRow(emoji: "🌻", title: "Legendary Farmer", desc: "Unlock a Legendary hen",            done: data.unlockedHens.contains(where: { id in Hen.all.first { $0.id == id }?.rarity == .legendary }))
            HHAchRow(emoji: "🌍", title: "Full Coop",        desc: "Collect all 13 hens",               done: data.unlockedHens.count >= Hen.all.count)
        }
    }
}

struct HHEditNameSheet: View {
    @Binding var name: String
    let onSave: () -> Void
    @Environment(\.dismiss) var dismiss
    @FocusState private var focused: Bool
    var body: some View {
        NavigationView {
            VStack(spacing: 28) {
                Text("🐔").font(.system(size: 72)).padding(.top, 20)
                VStack(spacing: 6) {
                    Text("Your Farmer Name").font(HenHavenTheme.title(18)).foregroundColor(HenHavenTheme.forest)
                    Text("What do your hens call you?").font(HenHavenTheme.body(14)).foregroundColor(.secondary)
                }
                TextField("Enter name...", text: $name)
                    .font(HenHavenTheme.title(20))
                    .multilineTextAlignment(.center)
                    .padding(16)
                    .background(HenHavenTheme.mint)
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(HenHavenTheme.forest.opacity(0.4), lineWidth: 2))
                    .padding(.horizontal, 32)
                    .focused($focused).onAppear { focused = true }
                Text("\(name.count)/20").font(HenHavenTheme.caption(12))
                    .foregroundColor(name.count > 20 ? .red : .secondary)
                Button("Save 🌱") { onSave(); dismiss() }
                    .font(HenHavenTheme.title(18)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(name.trimmingCharacters(in: .whitespaces).isEmpty || name.count > 20
                        ? AnyView(Color.gray) : AnyView(HenHavenTheme.meadowGrad))
                    .cornerRadius(18).padding(.horizontal, 32)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || name.count > 20)
                Spacer()
            }
            .background(HenHavenTheme.parchmentGrad.ignoresSafeArea())
            .navigationTitle("Edit Name").navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") { dismiss() })
        }
    }
}

// ════════════════════════════════════════════════════════════
// MARK: — Shared Components
// ════════════════════════════════════════════════════════════
struct HHQuickCard: View {
    let emoji: String; let title: String; let subtitle: String; let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(emoji).font(.system(size: 34))
            Text(title).font(HenHavenTheme.title(16)).foregroundColor(HenHavenTheme.bark)
            Text(subtitle).font(HenHavenTheme.caption(12)).foregroundColor(color)
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.8)).cornerRadius(18)
        .shadow(color: color.opacity(0.15), radius: 8, y: 3)
    }
}

struct HHFilterChip: View {
    let label: String; let active: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label).font(HenHavenTheme.caption(13))
                .foregroundColor(active ? .white : HenHavenTheme.forest)
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(active ? AnyView(HenHavenTheme.meadowGrad) : AnyView(Color.white.opacity(0.8)))
                .cornerRadius(20)
        }
    }
}

struct HHStatRow: View {
    let icon: String; let label: String; let value: String
    init(_ icon: String, _ label: String, _ value: String) { self.icon=icon; self.label=label; self.value=value }
    var body: some View {
        HStack { Text(icon); Text(label).font(HenHavenTheme.body(15)); Spacer(); Text(value).font(HenHavenTheme.body(14)).foregroundColor(HenHavenTheme.forest) }
    }
}

struct HHAchRow: View {
    let emoji: String; let title: String; let desc: String; let done: Bool
    var body: some View {
        HStack(spacing: 12) {
            Text(emoji).font(.system(size: 28)).opacity(done ? 1 : 0.3)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(HenHavenTheme.body(15)).foregroundColor(done ? HenHavenTheme.bark : .gray)
                Text(desc).font(HenHavenTheme.caption(12)).foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: done ? "checkmark.seal.fill" : "lock.fill")
                .foregroundColor(done ? HenHavenTheme.meadow : .gray)
        }
    }
}
