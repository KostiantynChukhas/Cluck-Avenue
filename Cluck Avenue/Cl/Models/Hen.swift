import Foundation

struct Hen: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let emoji: String
    let imageName: String
    let rarity: HenRarity
    let description: String
    var isUnlocked: Bool

    static let all: [Hen] = [

        // MARK: — Common
        Hen(id: UUID(), name: "Meadow Molly",
            emoji: "🐔", imageName: "hen_common_molly",
            rarity: .common,
            description: "Lives in the meadow. Loves clover and long afternoon naps.",
            isUnlocked: true),

        Hen(id: UUID(), name: "Sprout",
            emoji: "🐣", imageName: "hen_common_sprout",
            rarity: .common,
            description: "Just hatched. Still has a piece of shell on her head. Adorable.",
            isUnlocked: true),

        Hen(id: UUID(), name: "Bramble",
            emoji: "🐓", imageName: "hen_common_bramble",
            rarity: .common,
            description: "Loves scratching through dry leaves. Finds the best worms.",
            isUnlocked: false),

        Hen(id: UUID(), name: "Dusty",
            emoji: "🐤", imageName: "hen_common_dusty",
            rarity: .common,
            description: "Always dusty. Takes 12 dust baths a day. No regrets.",
            isUnlocked: false),

        // MARK: — Rare
        Hen(id: UUID(), name: "Fern",
            emoji: "🌿", imageName: "hen_rare_fern",
            rarity: .rare,
            description: "Green-feathered hen who blends perfectly into the forest floor.",
            isUnlocked: false),

        Hen(id: UUID(), name: "Brook",
            emoji: "💧", imageName: "hen_rare_brook",
            rarity: .rare,
            description: "Lives near the pond. Surprisingly good swimmer for a chicken.",
            isUnlocked: false),

        Hen(id: UUID(), name: "Hazel",
            emoji: "🍂", imageName: "hen_rare_hazel",
            rarity: .rare,
            description: "Autumn-coloured feathers in red, brown, and gold. Very seasonal.",
            isUnlocked: false),

        // MARK: — Epic
        Hen(id: UUID(), name: "Sage",
            emoji: "🌱", imageName: "hen_epic_sage",
            rarity: .epic,
            description: "Ancient herb-keeper. Knows every plant in the valley by name.",
            isUnlocked: false),

        Hen(id: UUID(), name: "Storm",
            emoji: "⛈️", imageName: "hen_epic_storm",
            rarity: .epic,
            description: "Only comes out when it rains. Dances in thunderstorms.",
            isUnlocked: false),

        Hen(id: UUID(), name: "Thistle",
            emoji: "🌾", imageName: "hen_epic_thistle",
            rarity: .epic,
            description: "Lives in the wheat fields. Protects the harvest. Extremely proud.",
            isUnlocked: false),

        // MARK: — Legendary
        Hen(id: UUID(), name: "Aurora",
            emoji: "🌅", imageName: "hen_legendary_aurora",
            rarity: .legendary,
            description: "Her feathers glow at sunrise. Every morning is her moment.",
            isUnlocked: false),

        Hen(id: UUID(), name: "Gaia",
            emoji: "🌍", imageName: "hen_legendary_gaia",
            rarity: .legendary,
            description: "The earth mother. All crops grow taller near her. Ancient. Wise.",
            isUnlocked: false),

        Hen(id: UUID(), name: "Solstice",
            emoji: "☀️", imageName: "hen_legendary_solstice",
            rarity: .legendary,
            description: "Born on the summer solstice. Made of pure sunlight and joy.",
            isUnlocked: false),
    ]
}
