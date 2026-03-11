import Foundation

struct NatureQuestion: Identifiable {
    let id = UUID()
    let question: String
    let options: [String]
    let correctIndex: Int
    let funFact: String
    let category: Category

    enum Category: String, CaseIterable {
        case farm     = "🌾 Farm Life"
        case nature   = "🌿 Nature"
        case seasons  = "🍂 Seasons"
        case animals  = "🐾 Animals"
        case plants   = "🌻 Plants"
        case weather  = "⛅ Weather"
    }

    static let bank: [NatureQuestion] = [
        NatureQuestion(
            question: "What do hens need to produce the most eggs?",
            options: ["Total darkness", "14–16 hours of daylight", "Cold temperatures", "Lots of rain"],
            correctIndex: 1,
            funFact: "Hens lay best with 14–16 hours of light per day — farmers often use artificial light in winter.",
            category: .farm
        ),
        NatureQuestion(
            question: "Which season do chickens naturally reduce egg laying?",
            options: ["Spring", "Summer", "Autumn", "Winter"],
            correctIndex: 3,
            funFact: "Shorter winter days trigger hens to slow down — it's their natural annual rest.",
            category: .seasons
        ),
        NatureQuestion(
            question: "What is a hen's favourite dust-bathing material?",
            options: ["Wet mud", "Fine dry soil or sand", "Gravel", "Fresh grass"],
            correctIndex: 1,
            funFact: "Dust bathing smothers mites and parasites — it's a chicken's built-in pest control!",
            category: .farm
        ),
        NatureQuestion(
            question: "How far can a free-range chicken roam in one day?",
            options: ["About 10 metres", "Up to 100 metres", "Over 1 kilometre", "5 kilometres"],
            correctIndex: 2,
            funFact: "A healthy free-range hen can walk over 1 km daily foraging for seeds, bugs, and greens.",
            category: .nature
        ),
        NatureQuestion(
            question: "Which plant is actually toxic to chickens?",
            options: ["Clover", "Dandelion", "Nightshade", "Sunflower seeds"],
            correctIndex: 2,
            funFact: "Nightshade berries are poisonous to chickens. Clover, dandelion, and sunflowers are fine!",
            category: .plants
        ),
        NatureQuestion(
            question: "What do chickens do before a storm?",
            options: ["Lay extra eggs", "Return to the coop and roost", "Dig deeper in the soil", "Run faster than usual"],
            correctIndex: 1,
            funFact: "Chickens sense barometric pressure drops and head home before storms — better than most weather apps!",
            category: .weather
        ),
        NatureQuestion(
            question: "What is a group of baby chicks called?",
            options: ["A flock", "A clutch", "A brood", "A hatch"],
            correctIndex: 2,
            funFact: "A hen and her newly hatched chicks are called a brood. The chicks are brooded (kept warm) by the mother.",
            category: .animals
        ),
        NatureQuestion(
            question: "Which wild bird is the closest ancestor to the domestic chicken?",
            options: ["Pheasant", "Red Junglefowl", "Wild Turkey", "Peacock"],
            correctIndex: 1,
            funFact: "The Red Junglefowl (Gallus gallus) from Southeast Asia is the direct ancestor of every chicken alive today.",
            category: .nature
        ),
        NatureQuestion(
            question: "What is the natural lifespan of a chicken?",
            options: ["1–2 years", "3–5 years", "5–10 years", "Over 15 years"],
            correctIndex: 2,
            funFact: "Chickens naturally live 5–10 years. The oldest recorded chicken, Muffy, lived to 22!",
            category: .animals
        ),
        NatureQuestion(
            question: "Which flower do free-range hens most enjoy eating?",
            options: ["Rose petals", "Lavender", "Dandelion", "Tulip"],
            correctIndex: 2,
            funFact: "Dandelions are a chicken superfood — packed with vitamins A, C, and K. Tulips are mildly toxic.",
            category: .plants
        ),
        NatureQuestion(
            question: "How do chickens communicate danger to each other?",
            options: ["Colour change", "Specific alarm calls", "Tail signals", "Stomping feet"],
            correctIndex: 1,
            funFact: "Chickens have distinct alarm calls for aerial predators vs ground predators — different sounds, different dangers!",
            category: .animals
        ),
        NatureQuestion(
            question: "What season do most heritage breed hens naturally start laying?",
            options: ["Winter", "Autumn", "Spring", "Midsummer"],
            correctIndex: 2,
            funFact: "Spring's lengthening days signal hens to resume laying — synced perfectly with more food being available.",
            category: .seasons
        ),
    ]
}
