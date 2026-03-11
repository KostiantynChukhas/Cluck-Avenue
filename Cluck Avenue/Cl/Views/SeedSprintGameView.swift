import SwiftUI

// MARK: — Seed Sprint (nature-themed endless runner)
// Hen runs through a meadow collecting seeds, dodging foxes & logs

private enum SC {
    static let groundH: CGFloat  = 90
    static let henX: CGFloat     = 90
    static let henSize: CGFloat  = 50
    static let seedSize: CGFloat = 28
    static let obsSize: CGFloat  = 42
    static let jumpVel: CGFloat  = 19
    static let gravity: CGFloat  = 6.2
    static let baseSpeed: CGFloat = 5.2
    static let tick: Double       = 1.0 / 60.0
}

struct SprintObstacle: Identifiable {
    let id = UUID()
    var x: CGFloat
    let type: OType
    enum OType { case fox, log, rock }
    var emoji: String {
        switch type { case .fox: return "🦊"; case .log: return "🪵"; case .rock: return "🪨" }
    }
}

struct SprintSeed: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat       // height above ground
    let type: SType
    enum SType { case seed, berry, flower }
    var emoji: String {
        switch type { case .seed: return "🌾"; case .berry: return "🫐"; case .flower: return "🌼" }
    }
    var points: Int {
        switch type { case .seed: return 5; case .berry: return 15; case .flower: return 10 }
    }
}

struct SeedSprintGameView: View {
    @EnvironmentObject var data: HenHavenDataManager
    @Environment(\.dismiss) private var dismiss

    @State private var phase: Phase = .idle
    @State private var score = 0
    @State private var distance = 0
    @State private var lives = 3
    @State private var speed: CGFloat = SC.baseSpeed

    @State private var henY: CGFloat = 0
    @State private var velY: CGFloat = 0
    @State private var onGround = true

    @State private var seeds: [SprintSeed] = []
    @State private var obstacles: [SprintObstacle] = []

    @State private var gameLoop: Timer?
    @State private var spawnTimer: Timer?
    @State private var distTimer: Timer?

    @State private var hitFlash = false
    @State private var collectPop: String? = nil
    @State private var arenaSize: CGSize = .zero

    enum Phase { case idle, playing, dead }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                hud
                arena
                if phase == .playing { powerBar }
            }
            .navigationTitle("Seed Sprint 🌾")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        stopTimers()
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(HenHavenTheme.forest)
                    }
                }
            }
        }
    }

    // MARK: — HUD
    private var hud: some View {
        HStack {
            Label("\(score)", systemImage: "star.fill")
                .font(HenHavenTheme.title(20))
                .foregroundColor(HenHavenTheme.wheat)
            Spacer()
            Text("📏 \(distance)m")
                .font(HenHavenTheme.body(14))
                .foregroundColor(HenHavenTheme.soil)
            Spacer()
            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: i < lives ? "heart.fill" : "heart")
                        .foregroundColor(HenHavenTheme.berry)
                        .font(.system(size: 16))
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Color.white)
    }

    // MARK: — Arena
    private var arena: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Background
                Image("bg_seed_sprint")
                    .resizable()
                    .scaledToFill()
                    .frame(width: w, height: h)
                    .clipped()

                // Clouds
                Text("☁️").font(.system(size: 30)).position(x: w * 0.20, y: h * 0.13)
                Text("☁️").font(.system(size: 22)).position(x: w * 0.60, y: h * 0.20)
                Text("🌤️").font(.system(size: 26)).position(x: w * 0.82, y: h * 0.09)

                // Ground — grass strip
                VStack(spacing: 0) {
                    Spacer()
                    ZStack(alignment: .top) {
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [HenHavenTheme.meadow, HenHavenTheme.forest],
                                startPoint: .top, endPoint: .bottom))
                            .frame(height: SC.groundH)
                        // Grass tufts
                        HStack(spacing: 0) {
                            ForEach(0..<Int(w / 28), id: \.self) { _ in
                                Text("🌿").font(.system(size: 12))
                                Spacer()
                            }
                        }
                        .offset(y: -6)
                    }
                }

                // Collectibles
                ForEach(seeds) { s in
                    Text(s.emoji)
                        .font(.system(size: SC.seedSize))
                        .position(x: s.x, y: h - SC.groundH - s.y - SC.seedSize / 2)
                }

                // Obstacles
                ForEach(obstacles) { o in
                    Text(o.emoji)
                        .font(.system(size: SC.obsSize))
                        .position(x: o.x, y: h - SC.groundH - SC.obsSize / 2)
                }

                // Hen
                Text("🐔")
                    .font(.system(size: SC.henSize))
                    .position(x: SC.henX, y: h - SC.groundH - henY - SC.henSize / 2)
                    .opacity(hitFlash ? 0.15 : 1)
                    .animation(.easeInOut(duration: 0.06), value: hitFlash)

                // Score pop
                if let pop = collectPop {
                    Text(pop)
                        .font(HenHavenTheme.title(18))
                        .foregroundColor(HenHavenTheme.forest)
                        .position(x: SC.henX + 30, y: h - SC.groundH - henY - 70)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Overlay
                if phase != .playing {
                    overlayView(w: w, h: h)
                }
            }
            .onAppear { arenaSize = geo.size }
            .onChange(of: geo.size) { arenaSize = $1 }
            .contentShape(Rectangle())
            .onTapGesture { if phase == .playing { jump() } }
        }
    }

    // MARK: — Power bar
    private var powerBar: some View {
        HStack(spacing: 0) {
            powerBtn("ui_powerup_speed", "Speed")   { speed = min(speed + 1, 13) }
            powerBtn("ui_powerup_shield", "Shield")  { lives = min(lives + 1, 3) }
            powerBtn("ui_powerup_harvest", "Harvest") { harvestAll() }
        }
        .background(Color.white)
    }

    private func powerBtn(_ imageName: String, _ l: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                Text(l).font(HenHavenTheme.caption(10)).foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 10)
        }
    }

    // MARK: — Overlay
    @ViewBuilder
    private func overlayView(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            Color.black.opacity(0.45)
            VStack(spacing: 18) {
                if phase == .dead {
                    Text("🦊 Got you!")
                        .font(HenHavenTheme.title(30)).foregroundColor(.white)
                    Text("Score: \(score)  •  \(distance)m")
                        .font(HenHavenTheme.body(18)).foregroundColor(.white.opacity(0.9))
                    if score > data.highScoreSeedSprint {
                        Text("🌻 New Record!")
                            .font(HenHavenTheme.title(16)).foregroundColor(HenHavenTheme.wheat)
                    }
                } else {
                    Text("🌾 Seed Sprint")
                        .font(HenHavenTheme.title(34)).foregroundColor(.white)
                    VStack(spacing: 5) {
                        Text("• TAP to jump over obstacles")
                        Text("• Collect 🌾 seeds, 🫐 berries, 🌼 flowers")
                        Text("• Dodge 🦊 foxes, 🪵 logs, 🪨 rocks")
                        Text("• Speed increases every 10 metres")
                    }
                    .font(HenHavenTheme.body(13)).foregroundColor(.white.opacity(0.85))
                    if data.highScoreSeedSprint > 0 {
                        Text("Best: \(data.highScoreSeedSprint) pts")
                            .font(HenHavenTheme.caption(14)).foregroundColor(HenHavenTheme.wheat)
                    }
                }

                Button(phase == .dead ? "Try Again 🔄" : "Start Sprint 🐔") { startGame() }
                    .font(HenHavenTheme.title(20))
                    .foregroundColor(HenHavenTheme.soil)
                    .padding(.horizontal, 36).padding(.vertical, 14)
                    .background(HenHavenTheme.wheat)
                    .cornerRadius(20)
                    .shadow(color: HenHavenTheme.wheat.opacity(0.6), radius: 12, y: 5)
            }
            .padding(28)
        }
    }

    // MARK: — Game logic
    private func jump() {
        guard onGround else { return }
        velY = SC.jumpVel; onGround = false
    }

    private func startGame() {
        stopTimers()
        score = 0; distance = 0; lives = 3
        henY = 0; velY = 0; onGround = true
        seeds = []; obstacles = []
        speed = SC.baseSpeed; phase = .playing

        gameLoop  = Timer.scheduledTimer(withTimeInterval: SC.tick, repeats: true) { _ in tick() }
        spawnTimer = Timer.scheduledTimer(withTimeInterval: 1.3, repeats: true) { _ in spawnObjects() }
        distTimer  = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            distance += 1
            if distance % 10 == 0 { speed = min(speed + 0.4, 15) }
        }
    }

    private func stopTimers() {
        gameLoop?.invalidate(); spawnTimer?.invalidate(); distTimer?.invalidate()
        gameLoop = nil; spawnTimer = nil; distTimer = nil
    }

    private func tick() {
        let w = arenaSize.width; let h = arenaSize.height
        guard w > 0, phase == .playing else { return }

        // Physics
        if !onGround {
            velY -= SC.gravity * CGFloat(SC.tick) * 60 * 0.1
            henY += velY * CGFloat(SC.tick) * 60 * 0.35
            if henY <= 0 { henY = 0; velY = 0; onGround = true }
        }

        // Scroll
        seeds = seeds.compactMap { seed in
            var updated = seed
            updated.x -= speed
            return updated.x > -SC.seedSize ? updated : nil
        }
        obstacles = obstacles.compactMap { obstacle in
            var updated = obstacle
            updated.x -= speed
            return updated.x > -SC.obsSize ? updated : nil
        }

        let henBottom = h - SC.groundH - henY
        let henTop    = henBottom - SC.henSize
        let henCX     = (SC.henX - 22)...(SC.henX + 22)

        // Collect seeds
        var caught: [UUID] = []
        for s in seeds {
            let sTop = h - SC.groundH - s.y - SC.seedSize
            let sBot = sTop + SC.seedSize
            if henCX.contains(s.x) && !(henBottom < sTop || henTop > sBot) {
                caught.append(s.id)
                let pts = s.points
                score += pts
                showPop("+\(pts)")
            }
        }
        if !caught.isEmpty { seeds.removeAll { caught.contains($0.id) } }

        // Hit obstacles
        for o in obstacles {
            let oTop = h - SC.groundH - SC.obsSize
            let oBot = h - SC.groundH
            if abs(o.x - SC.henX) < 26 && !(henBottom < oTop || henTop > oBot) {
                obstacles.removeAll { $0.id == o.id }
                loseLife(); return
            }
        }
    }

    private func showPop(_ text: String) {
        collectPop = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { collectPop = nil }
    }

    private func spawnObjects() {
        guard phase == .playing, arenaSize.width > 0 else { return }
        let w = arenaSize.width

        // Collectibles
        if Int.random(in: 0...2) != 0 {
            let count = Int.random(in: 1...3)
            let types: [SprintSeed.SType] = [.seed, .seed, .seed, .berry, .flower]
            for i in 0..<count {
                let yOff: CGFloat = [0, 35, 70].randomElement()!
                seeds.append(SprintSeed( x: w + 30 + CGFloat(i * 55), y: yOff + 8, type: types.randomElement()!))
            }
        }

        // Obstacles
        let obsChance = min(0.30 + Double(distance) * 0.008, 0.70)
        if Double.random(in: 0...1) < obsChance {
            let types: [SprintObstacle.OType] = [.fox, .log, .rock]
            obstacles.append(SprintObstacle( x: w + 50, type: types.randomElement()!))
        }
    }

    private func loseLife() {
        lives -= 1
        hitFlash = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { hitFlash = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { hitFlash = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { hitFlash = false }
        if lives <= 0 {
            stopTimers()
            data.updateHighScoreSeedSprint(score)
            data.addSeeds(score / 5)
            phase = .dead
        }
    }

    private func harvestAll() {
        score += seeds.count * 5; seeds = []
    }
}
