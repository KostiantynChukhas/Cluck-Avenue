import SwiftUI

// ============================================================
// MARK: — Cluck Avenue Design System
// Nature / Countryside colour palette
// ============================================================
enum HenHavenTheme {

    // ── Primary greens ──────────────────────────────────────
    static let forest   = Color(red: 0.20, green: 0.45, blue: 0.22)   // deep forest green
    static let meadow   = Color(red: 0.42, green: 0.68, blue: 0.30)   // fresh grass
    static let sage     = Color(red: 0.60, green: 0.74, blue: 0.52)   // soft sage
    static let mint     = Color(red: 0.86, green: 0.95, blue: 0.80)   // pale mint bg

    // ── Earth tones ─────────────────────────────────────────
    static let soil     = Color(red: 0.42, green: 0.26, blue: 0.12)   // rich dark soil
    static let clay     = Color(red: 0.72, green: 0.45, blue: 0.22)   // warm clay
    static let straw    = Color(red: 0.96, green: 0.88, blue: 0.62)   // dry straw
    static let wheat    = Color(red: 0.95, green: 0.78, blue: 0.35)   // golden wheat

    // ── Sky / water ─────────────────────────────────────────
    static let sky      = Color(red: 0.68, green: 0.88, blue: 0.96)   // clear sky blue
    static let pond     = Color(red: 0.35, green: 0.65, blue: 0.78)   // pond teal

    // ── Accent ──────────────────────────────────────────────
    static let berry    = Color(red: 0.72, green: 0.18, blue: 0.20)   // wild berry red
    static let sundown  = Color(red: 0.97, green: 0.60, blue: 0.20)   // sunset orange

    // ── Backgrounds ─────────────────────────────────────────
    static let parchment = Color(red: 0.97, green: 0.95, blue: 0.88)  // aged parchment
    static let bark      = Color(red: 0.28, green: 0.19, blue: 0.10)  // dark bark

    // ── Gradients ───────────────────────────────────────────
    static let meadowGrad = LinearGradient(
        colors: [meadow, forest],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let sunsetGrad = LinearGradient(
        colors: [wheat, sundown, Color(red: 0.85, green: 0.35, blue: 0.18)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let skyGrad = LinearGradient(
        colors: [sky, mint],
        startPoint: .top, endPoint: .bottom
    )
    static let parchmentGrad = LinearGradient(
        colors: [parchment, Color(red: 0.92, green: 0.88, blue: 0.76)],
        startPoint: .top, endPoint: .bottom
    )

    // ── Typography helper ────────────────────────────────────
    static func title(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }
    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }
    static func caption(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
}

// ── Rarity with nature-themed names ─────────────────────────
enum HenRarity: String, CaseIterable, Codable {
    case common    = "Common"
    case rare      = "Rare"
    case epic      = "Epic"
    case legendary = "Legendary"

    var color: Color {
        switch self {
        case .common:    return HenHavenTheme.sage
        case .rare:      return HenHavenTheme.pond
        case .epic:      return HenHavenTheme.forest
        case .legendary: return HenHavenTheme.wheat
        }
    }

    var label: String {
        switch self {
        case .common:    return "🌿 Common"
        case .rare:      return "🌊 Rare"
        case .epic:      return "🌲 Epic"
        case .legendary: return "🌻 Legendary"
        }
    }

    var dropChance: Double {
        switch self {
        case .common:    return 0.60
        case .rare:      return 0.25
        case .epic:      return 0.12
        case .legendary: return 0.03
        }
    }
}
