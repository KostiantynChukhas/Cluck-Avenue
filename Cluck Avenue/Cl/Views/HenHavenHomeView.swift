import SwiftUI

struct HenHavenHomeView: View {
    @EnvironmentObject var data: HenHavenDataManager
    @State private var showChallenges = false

    private var timeOfDayGreeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 5..<12:  return "Good morning 🌄"
        case 12..<17: return "Good afternoon ☀️"
        case 17..<21: return "Good evening 🌇"
        default:      return "Good night 🌙"
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                HenHavenTheme.parchmentGrad.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        headerCard
                        seedsBar
                        challengeButton
                        quickGrid
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 36)
                    .padding(.horizontal, 16)
                }
            }
            .navigationTitle("Cluck Avenue 🌿")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showChallenges) {
            HenHavenChallengesView()
        }
    }

    // MARK: — Header
    private var headerCard: some View {
        ZStack(alignment: .bottomTrailing) {
            HenHavenTheme.meadowGrad
                .cornerRadius(24)

            VStack(alignment: .leading, spacing: 8) {
                Text(timeOfDayGreeting)
                    .font(HenHavenTheme.caption(13))
                    .foregroundColor(.white.opacity(0.8))

                Text(data.farmerName)
                    .font(HenHavenTheme.title(26))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 10) {
                    streakPill
                    seedsPill
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("🐔")
                .font(.system(size: 64))
                .opacity(0.25)
                .offset(x: -12, y: 10)
        }
        .frame(height: 150)
    }

    private var streakPill: some View {
        Label("\(data.streakDays) Day Streak", systemImage: "flame.fill")
            .font(HenHavenTheme.caption(13))
            .foregroundColor(HenHavenTheme.wheat)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(.white.opacity(0.2))
            .cornerRadius(12)
    }

    private var seedsPill: some View {
        Label("\(data.seeds) Seeds", systemImage: "leaf.fill")
            .font(HenHavenTheme.caption(13))
            .foregroundColor(.white)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(.white.opacity(0.2))
            .cornerRadius(12)
    }

    // MARK: — Seeds progress bar
    private var seedsBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 4) {
                    Image("ui_seed")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                    Text("Seed Stash")
                        .font(HenHavenTheme.body(14))
                        .foregroundColor(HenHavenTheme.soil)
                }
                Spacer()
                Text("\(data.seeds) seeds")
                    .font(HenHavenTheme.caption(13))
                    .foregroundColor(HenHavenTheme.forest)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(HenHavenTheme.mint)
                    Capsule()
                        .fill(HenHavenTheme.meadowGrad)
                        .frame(width: min(CGFloat(data.seeds) / 500.0, 1.0) * geo.size.width)
                        .animation(.spring(), value: data.seeds)
                }
            }
            .frame(height: 10)
        }
        .padding(16)
        .background(Color.white.opacity(0.7))
        .cornerRadius(16)
    }

    // MARK: — Challenge button
    private var challengeButton: some View {
        Button(action: { showChallenges = true }) {
            HStack(spacing: 14) {
                Text("⚡").font(.system(size: 30))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Harvest Challenges")
                        .font(HenHavenTheme.title(16))
                        .foregroundColor(.white)
                    Text("Complete 3 tasks · earn up to 125 🌱")
                        .font(HenHavenTheme.caption(12))
                        .foregroundColor(.white.opacity(0.8))
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.6))
            }
            .padding(16)
            .background(
                LinearGradient(colors: [HenHavenTheme.clay, HenHavenTheme.soil],
                               startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(18)
        }
    }

    // MARK: — Quick grid
    private var quickGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            HHQuickCard(emoji: "🌾", title: "Seed Sprint",
                        subtitle: "Best: \(data.highScoreSeedSprint) pts",
                        color: HenHavenTheme.meadow)
            HHQuickCard(emoji: "🌧️", title: "Rain Catch",
                        subtitle: "Best: \(data.highScoreRainCatch) pts",
                        color: HenHavenTheme.pond)
            HHQuickCard(emoji: "🌿", title: "Nature Trivia",
                        subtitle: "\(NatureQuestion.bank.count) questions",
                        color: HenHavenTheme.forest)
            HHQuickCard(emoji: "🪺", title: "My Coop",
                        subtitle: "\(data.unlockedHens.count)/\(Hen.all.count) hens",
                        color: HenHavenTheme.clay)
        }
    }
}
