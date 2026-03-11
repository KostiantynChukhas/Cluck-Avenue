import SwiftUI

struct HenHavenTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HenHavenHomeView()
                .tabItem { Label("Meadow", systemImage: "leaf.fill") }
                .tag(0)

            HenHavenGamesHubView()
                .tabItem { Label("Play", systemImage: "gamecontroller.fill") }
                .tag(1)

            HenHavenCoopView()
                .tabItem { Label("Coop", systemImage: "square.grid.3x3.fill") }
                .tag(2)

            HenHavenQuizView()
                .tabItem { Label("Trivia", systemImage: "questionmark.bubble.fill") }
                .tag(3)

            HenHavenProfileView()
                .tabItem { Label("Farmer", systemImage: "person.fill") }
                .tag(4)
        }
        .tint(HenHavenTheme.forest)
    }
}
