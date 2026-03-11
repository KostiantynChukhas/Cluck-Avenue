import SwiftUI

struct RainItem: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var speed: CGFloat
    let type: RType

    enum RType {
        case raindrop, berry, mushroom, hailstone, leaf

        var emoji: String {
            switch self {
            case .raindrop:  return "💧"
            case .berry:     return "🫐"
            case .mushroom:  return "🍄"
            case .hailstone: return "🧊"
            case .leaf:      return "🍃"
            }
        }
        
        var imageName: String? {
            switch self {
            case .hailstone: return "ui_hailstone"
            case .mushroom:  return "ui_mushroom"
            default:         return nil
            }
        }
        
        var size: CGFloat  { self == .berry ? 34 : 28 }
        var points: Int {
            switch self {
            case .raindrop: return 5
            case .berry:    return 20
            case .leaf:     return 3
            case .mushroom: return 0
            case .hailstone: return 0
            }
        }
    }
}

struct RainPop: Identifiable {
    let id = UUID()
    var x: CGFloat; var y: CGFloat
    var text: String; var opacity: Double = 1.0
}

struct RainCatchGameView: View {
    @EnvironmentObject var data: HenHavenDataManager
    @Environment(\.dismiss) private var dismiss

    @State private var phase: Phase = .idle
    @State private var score = 0
    @State private var lives = 3
    @State private var timeLeft = 50
    @State private var combo = 0
    @State private var lastCatch: Date = .distantPast

    @State private var items: [RainItem] = []
    @State private var pops: [RainPop] = []
    @State private var bucketX: CGFloat = 0

    @State private var hitFlash = false
    @State private var rainIntensity = 0.3   // 0–1 as time progresses

    @State private var gameLoop: Timer?
    @State private var spawnTimer: Timer?
    @State private var countdown: Timer?
    @State private var arenaSize: CGSize = .zero

    private let bucketW: CGFloat = 76
    private let bucketH: CGFloat = 44

    enum Phase { case idle, playing, dead, timeUp }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                hud
                arenaView.frame(maxHeight: .infinity)
                controls
            }
            .navigationTitle("Rain Catch 🌧️")
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
                .font(HenHavenTheme.title(18))
                .foregroundColor(HenHavenTheme.wheat)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Timer pill
            ZStack {
                Capsule().fill(timeLeft <= 10
                    ? HenHavenTheme.berry.opacity(0.15)
                    : HenHavenTheme.pond.opacity(0.15))
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                    Text("\(timeLeft)s")
                }
                .font(HenHavenTheme.body(15))
                .foregroundColor(timeLeft <= 10 ? HenHavenTheme.berry : HenHavenTheme.pond)
            }
            .frame(width: 80, height: 32)

            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: i < lives ? "heart.fill" : "heart")
                        .foregroundColor(HenHavenTheme.berry).font(.system(size: 15))
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Color.white)
    }

    // MARK: — Arena
    private var arenaView: some View {
        GeometryReader { geo in
            let w = geo.size.width; let h = geo.size.height

            ZStack {
                // Rainy sky background
                Image("bg_rain_catch")
                    .resizable()
                    .scaledToFill()
                    .frame(width: w, height: h)
                    .clipped()

                // Rain streaks overlay
                ForEach(0..<20, id: \.self) { i in
                    Rectangle()
                        .fill(Color.white.opacity(0.07 + rainIntensity * 0.08))
                        .frame(width: 1.5, height: 40)
                        .position(x: CGFloat(i) * (w / 20), y: CGFloat(i % 5) * 60 + 30)
                }

                // Ground — mossy soil
                VStack(spacing: 0) {
                    Spacer()
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [HenHavenTheme.meadow, HenHavenTheme.forest],
                            startPoint: .top, endPoint: .bottom))
                        .frame(height: 60)
                }

                // Falling items
                ForEach(items) { item in
                    Group {
                        if let imageName = item.type.imageName {
                            Image(imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: item.type.size, height: item.type.size)
                        } else {
                            Text(item.type.emoji)
                                .font(.system(size: item.type.size))
                        }
                    }
                    .position(x: item.x, y: item.y)
                }

                // Score pops
                ForEach(pops) { pop in
                    Text(pop.text)
                        .font(HenHavenTheme.title(16))
                        .foregroundColor(HenHavenTheme.meadow)
                        .opacity(pop.opacity)
                        .position(x: pop.x, y: pop.y)
                }

                // Bucket (wooden)
                Text("🪣")
                    .font(.system(size: 52))
                    .position(
                        x: max(bucketW/2, min(bucketX, w - bucketW/2)),
                        y: h - bucketH/2 - 10
                    )
                    .opacity(hitFlash ? 0.2 : 1)
                    .animation(.easeInOut(duration: 0.06), value: hitFlash)

                // Combo badge
                if combo >= 3 {
                    Text("x\(combo) 🌿")
                        .font(HenHavenTheme.title(14))
                        .foregroundColor(HenHavenTheme.wheat)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(HenHavenTheme.forest.opacity(0.8))
                        .cornerRadius(10)
                        .position(x: max(bucketW/2, min(bucketX, w - bucketW/2)), y: h - 90)
                }

                if phase != .playing { overlayView(w: w, h: h) }
            }
            .onAppear { arenaSize = geo.size; bucketX = geo.size.width / 2 }
            .onChange(of: geo.size) { arenaSize = $1; bucketX = $1.width / 2 }
            .gesture(DragGesture(minimumDistance: 0).onChanged { val in
                if phase == .playing { bucketX = val.location.x }
            })
        }
    }

    // MARK: — Controls
    private var controls: some View {
        HStack(spacing: 0) {
            Button(action: { moveBucket(-32) }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 22, weight: .bold))
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
            }
            .background(HenHavenTheme.mint)
            Divider()
            Button(action: { moveBucket(32) }) {
                Image(systemName: "arrow.right")
                    .font(.system(size: 22, weight: .bold))
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
            }
            .background(HenHavenTheme.mint)
        }
        .frame(height: 52)
    }

    // MARK: — Overlay
    @ViewBuilder
    private func overlayView(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            Color.black.opacity(0.5)
            VStack(spacing: 18) {
                if phase == .timeUp {
                    Text("⏰ Rain Stopped!")
                        .font(HenHavenTheme.title(30)).foregroundColor(.white)
                    Text("Final: \(score) pts")
                        .font(HenHavenTheme.body(20)).foregroundColor(.white)
                    if score > data.highScoreRainCatch {
                        Text("🌻 New Record!")
                            .font(HenHavenTheme.title(16)).foregroundColor(HenHavenTheme.wheat)
                    }
                } else if phase == .dead {
                    Text("🧊 Hailstorm!")
                        .font(HenHavenTheme.title(30)).foregroundColor(.white)
                    Text("Score: \(score) — no more lives!")
                        .font(HenHavenTheme.body(16)).foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                } else {
                    Text("🌧️ Rain Catch")
                        .font(HenHavenTheme.title(34)).foregroundColor(.white)
                    VStack(spacing: 5) {
                        Text("• Slide or tap arrows to move bucket")
                        Text("• Catch 💧 drops (+5) and 🫐 berries (+20)")
                        Text("• 🍃 leaves give small bonus (+3)")
                        Text("• Avoid 🧊 hailstones and 🍄 mushrooms!")
                        Text("• Combo 3+ items for double points!")
                    }
                    .font(HenHavenTheme.body(13)).foregroundColor(.white.opacity(0.85))
                    if data.highScoreRainCatch > 0 {
                        Text("Best: \(data.highScoreRainCatch) pts")
                            .font(HenHavenTheme.caption(14)).foregroundColor(HenHavenTheme.wheat)
                    }
                }

                Button((phase == .dead || phase == .timeUp) ? "Play Again 🔄" : "Start 🪣") {
                    startGame()
                }
                .font(HenHavenTheme.title(20))
                .foregroundColor(HenHavenTheme.soil)
                .padding(.horizontal, 36).padding(.vertical, 14)
                .background(HenHavenTheme.sky)
                .cornerRadius(20)
                .shadow(color: HenHavenTheme.pond.opacity(0.5), radius: 12, y: 5)
            }
            .padding(28)
        }
    }

    // MARK: — Game logic
    private func startGame() {
        stopTimers()
        score = 0; lives = 3; timeLeft = 50; combo = 0
        items = []; pops = []
        bucketX = arenaSize.width / 2
        rainIntensity = 0.3
        phase = .playing

        gameLoop  = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { _ in tick() }
        spawnTimer = Timer.scheduledTimer(withTimeInterval: 0.75, repeats: true) { _ in spawnItem() }
        countdown  = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeLeft > 0 {
                timeLeft -= 1
                rainIntensity = min(0.3 + Double(50 - timeLeft) / 50.0 * 0.7, 1.0)
            } else { endGame(.timeUp) }
        }
    }

    private func stopTimers() {
        gameLoop?.invalidate(); spawnTimer?.invalidate(); countdown?.invalidate()
        gameLoop = nil; spawnTimer = nil; countdown = nil
    }

    private func tick() {
        guard phase == .playing, arenaSize.height > 0 else { return }
        let h = arenaSize.height; let w = arenaSize.width
        let bY = h - bucketH/2 - 10
        let clampX = max(bucketW/2, min(bucketX, w - bucketW/2))

        var remove: [UUID] = []
        for i in items.indices {
            items[i].y += items[i].speed
            let sz = items[i].type.size / 2
            let inX = abs(items[i].x - clampX) < (bucketW/2 + sz * 0.5)
            let inY = items[i].y + sz >= bY - bucketH/2 && items[i].y - sz <= bY + bucketH/2

            if inX && inY {
                if items[i].type == .hailstone || items[i].type == .mushroom {
                    remove.append(items[i].id)
                    hitItem(at: CGPoint(x: items[i].x, y: items[i].y))
                } else {
                    let pts = catchItem(items[i])
                    addPop("+\(pts)", at: CGPoint(x: items[i].x, y: items[i].y - 20))
                    remove.append(items[i].id)
                }
            } else if items[i].y > h + 40 {
                if items[i].type == .raindrop || items[i].type == .berry { combo = 0 }
                remove.append(items[i].id)
            }
        }
        items.removeAll { remove.contains($0.id) }

        for i in pops.indices {
            pops[i].y    -= 1.5
            pops[i].opacity -= 0.022
        }
        pops.removeAll { $0.opacity <= 0 }
    }

    private func spawnItem() {
        guard phase == .playing, arenaSize.width > 0 else { return }
        let w = arenaSize.width
        let progress = Double(50 - timeLeft) / 50.0
        let x = CGFloat.random(in: 20...(w - 20))
        let spd = CGFloat.random(in: 3.5...5.5) + CGFloat(progress) * 3.0

        let r = Double.random(in: 0...1)
        let hailChance   = 0.10 + progress * 0.08
        let berryChance  = 0.10 + progress * 0.03
        let mushChance   = 0.08
        let leafChance   = 0.12

        let type: RainItem.RType
        if r < hailChance                               { type = .hailstone }
        else if r < hailChance + berryChance            { type = .berry }
        else if r < hailChance + berryChance + mushChance { type = .mushroom }
        else if r < hailChance + berryChance + mushChance + leafChance { type = .leaf }
        else                                            { type = .raindrop }

        items.append(RainItem( x: x, y: -20, speed: spd, type: type))

        // Extra drops when raining harder
        if progress > 0.5 && Bool.random() {
            items.append(RainItem( x: CGFloat.random(in: 20...(w-20)), y: -50, speed: spd * 0.9, type: .raindrop))
        }
    }

    private func catchItem(_ item: RainItem) -> Int {
        let now = Date()
        combo = now.timeIntervalSince(lastCatch) < 0.9 ? combo + 1 : 1
        lastCatch = now
        let mult = combo >= 3 ? 2 : 1
        let pts = item.type.points * mult
        score += pts
        return pts
    }

    private func hitItem(at pt: CGPoint) {
        lives -= 1
        combo = 0
        hitFlash = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { hitFlash = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { hitFlash = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) { hitFlash = false }
        addPop("💥", at: pt)
        if lives <= 0 { endGame(.dead) }
    }

    private func moveBucket(_ d: CGFloat) {
        guard phase == .playing else { return }
        bucketX = max(bucketW/2, min(bucketX + d, arenaSize.width - bucketW/2))
    }

    private func addPop(_ t: String, at pt: CGPoint) {
        pops.append(RainPop( x: pt.x, y: pt.y, text: t))
    }

    private func endGame(_ reason: Phase) {
        stopTimers()
        data.updateHighScoreRainCatch(score)
        data.addSeeds(score / 8)
        phase = reason
    }
}
