import SwiftUI

struct HenHavenOnboardingView: View {
    @EnvironmentObject var data: HenHavenDataManager
    @State private var page = 0

    private let pages: [(emoji: String, title: String, subtitle: String, bg: [Color])] = [
        ("🌅", "Welcome to\nCluck Avenue",
         "A peaceful countryside where your hens roam free and nature thrives.",
         [HenHavenTheme.wheat, HenHavenTheme.sundown]),
        ("🌾", "Sprint & Harvest",
         "Run through meadows collecting seeds. Dodge foxes and fallen logs!",
         [HenHavenTheme.meadow, HenHavenTheme.forest]),
        ("🌧️", "Rain Catch",
         "Move your bucket to catch raindrops and berries. Avoid the hailstones!",
         [HenHavenTheme.pond, Color(red: 0.18, green: 0.38, blue: 0.58)]),
        ("🪺", "Build Your Coop",
         "Collect 13 unique hens — from Common Meadow Molly to Legendary Solstice.",
         [HenHavenTheme.forest, HenHavenTheme.soil]),
    ]
    
    private let pageImages = ["onboarding_welcome", "onboarding_sprint", "onboarding_rain", "onboarding_coop"]

    var body: some View {
        ZStack {
            LinearGradient(colors: pages[page].bg, startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: page)

            VStack(spacing: 0) {
                Spacer()

                // Image
                Image(pageImages[page])
                    .resizable()
                    .scaledToFit()
                    .frame(height: 220)
                    .padding(.bottom, 32)
                    .transition(.scale.combined(with: .opacity))
                    .id("img\(page)")
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: page)

                // Title
                Text(pages[page].title)
                    .font(HenHavenTheme.title(32))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .id("title\(page)")
                    .animation(.easeInOut(duration: 0.4), value: page)

                // Subtitle
                Text(pages[page].subtitle)
                    .font(HenHavenTheme.body(16))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 16)
                    .id("sub\(page)")

                Spacer()

                // Dots
                HStack(spacing: 10) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Circle()
                            .fill(i == page ? Color.white : Color.white.opacity(0.35))
                            .frame(width: i == page ? 10 : 7, height: i == page ? 10 : 7)
                            .animation(.spring(), value: page)
                    }
                }
                .padding(.bottom, 32)

                // Button
                Button(action: advance) {
                    Text(page == pages.count - 1 ? "Start Farming 🌱" : "Next →")
                        .font(HenHavenTheme.title(18))
                        .foregroundColor(pages[page].bg.first ?? HenHavenTheme.forest)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.white)
                        .cornerRadius(20)
                        .padding(.horizontal, 40)
                        .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
                }
                .padding(.bottom, 16)

                // Skip
                if page < pages.count - 1 {
                    Button("Skip") { finishOnboarding() }
                        .font(HenHavenTheme.caption())
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.bottom, 32)
                } else {
                    Spacer().frame(height: 48)
                }
            }
        }
    }

    private func advance() {
        if page < pages.count - 1 {
            withAnimation { page += 1 }
        } else {
            finishOnboarding()
        }
    }

    private func finishOnboarding() {
        withAnimation { data.completeOnboarding() }
    }
}
