import Foundation

// ══════════════════════════════════════════════════════════════════
// GAME MODEL — 10 Mini-jeux + système de récompenses
// ══════════════════════════════════════════════════════════════════

// MARK: — Mini-jeu

enum MiniGame: String, CaseIterable, Identifiable {
    case memory, quiz, reaction, simon, courseDebuddys
    case peche, cuisine, typing, dessinDevine, pictionary
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .memory:         return "Memory"
        case .quiz:           return "Quiz Culture"
        case .reaction:       return "Réaction"
        case .simon:          return "Simon"
        case .courseDebuddys: return "Course de Buddys"
        case .peche:          return "Pêche"
        case .cuisine:        return "Cuisine"
        case .typing:         return "Typing"
        case .dessinDevine:   return "Dessin Deviné"
        case .pictionary:     return "Pictionary"
        }
    }
    
    var emoji: String {
        switch self {
        case .memory: return "🃏"; case .quiz: return "🧠"; case .reaction: return "⚡"
        case .simon: return "🎵"; case .courseDebuddys: return "🏃"; case .peche: return "🎣"
        case .cuisine: return "🍳"; case .typing: return "⌨️"; case .dessinDevine: return "🎨"
        case .pictionary: return "✏️"
        }
    }
    
    var description: String {
        switch self {
        case .memory:         return "Trouve les paires de cartes !"
        case .quiz:           return "Réponds aux questions de culture !"
        case .reaction:       return "Tape au bon moment !"
        case .simon:          return "Reproduis la séquence de couleurs !"
        case .courseDebuddys: return "Swipe le plus vite possible !"
        case .peche:          return "Attrape les poissons au bon timing !"
        case .cuisine:        return "Combine les ingrédients !"
        case .typing:         return "Tape les mots rapidement !"
        case .dessinDevine:   return "Devine le dessin de l'IA !"
        case .pictionary:     return "Dessine pour l'IA !"
        }
    }
    
    var color: String {
        switch self {
        case .memory: return "FF3D7F"; case .quiz: return "7C3AED"; case .reaction: return "FFE066"
        case .simon: return "2ECC71"; case .courseDebuddys: return "FF9F43"; case .peche: return "5DCDFF"
        case .cuisine: return "FF6B6B"; case .typing: return "7FFFD4"; case .dessinDevine: return "E8D5FF"
        case .pictionary: return "FFE5EC"
        }
    }
    
    var rewardRange: ClosedRange<Int> { 5...10 }  // gemmes
    var coinReward: Int { 15 }
    var xpReward: Int { 20 }
}

// MARK: — Session de jeu

struct GameSession: Codable, Identifiable {
    var id: String = UUID().uuidString
    let gameType: String
    var score: Int = 0
    var isWin: Bool = false
    var gemsEarned: Int = 0
    var coinsEarned: Int = 0
    var xpEarned: Int = 0
    var date: Date = Date()
    var difficulty: GameDifficulty = .normal
}

enum GameDifficulty: String, Codable, CaseIterable {
    case easy = "Facile"
    case normal = "Normal"
    case hard = "Difficile"
    
    var multiplier: Double {
        switch self {
        case .easy: return 0.8; case .normal: return 1.0; case .hard: return 1.5
        }
    }
}

// MARK: — Limite quotidienne

struct DailyGameTracker: Codable {
    var date: String   // "yyyy-MM-dd"
    var sessionsPlayed: Int = 0
    var rewardedSessions: Int = 0
    var battlesPlayed: Int = 0
    var rewardedBattles: Int = 0
    
    static let maxRewardedSessions = 5
    static let maxRewardedBattles = 10
    static let maxGemsPerDay = 15
    var gemsEarnedToday: Int = 0
    
    var canEarnGameReward: Bool { rewardedSessions < Self.maxRewardedSessions }
    var canEarnBattleReward: Bool { rewardedBattles < Self.maxRewardedBattles }
    var canEarnGems: Bool { gemsEarnedToday < Self.maxGemsPerDay }
    
    mutating func recordGame(gems: Int) {
        sessionsPlayed += 1
        if canEarnGameReward {
            rewardedSessions += 1
            let actualGems = min(gems, Self.maxGemsPerDay - gemsEarnedToday)
            gemsEarnedToday += actualGems
        }
    }
    
    mutating func recordBattle(gems: Int) {
        battlesPlayed += 1
        if canEarnBattleReward {
            rewardedBattles += 1
            let actualGems = min(gems, Self.maxGemsPerDay - gemsEarnedToday)
            gemsEarnedToday += actualGems
        }
    }
    
    static func today() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}

// MARK: — Données Memory

struct MemoryCard: Identifiable {
    let id: Int
    let emoji: String
    var isFaceUp: Bool = false
    var isMatched: Bool = false
}

struct MemoryGameState {
    var cards: [MemoryCard] = []
    var firstFlipped: Int? = nil
    var moves: Int = 0
    var matchedPairs: Int = 0
    var totalPairs: Int = 6
    var isGameOver: Bool { matchedPairs >= totalPairs }
    
    static func newGame(difficulty: GameDifficulty) -> MemoryGameState {
        let pairs: Int
        switch difficulty {
        case .easy: pairs = 4
        case .normal: pairs = 6
        case .hard: pairs = 8
        }
        let emojis = ["🍎", "🍕", "🎸", "🚀", "🌈", "🎃", "🦋", "🍦", "⭐", "🎵", "🌺", "🐙"]
        let selected = Array(emojis.shuffled().prefix(pairs))
        var cards: [MemoryCard] = []
        for (i, emoji) in selected.enumerated() {
            cards.append(MemoryCard(id: i * 2, emoji: emoji))
            cards.append(MemoryCard(id: i * 2 + 1, emoji: emoji))
        }
        return MemoryGameState(cards: cards.shuffled(), totalPairs: pairs)
    }
}

// MARK: — Données Quiz

struct QuizQuestion: Identifiable {
    let id = UUID()
    let question: String
    let answers: [String]
    let correctIndex: Int
    
    static let bank: [QuizQuestion] = [
        QuizQuestion(question: "Quelle est la capitale de la France ?", answers: ["Lyon", "Paris", "Marseille", "Toulouse"], correctIndex: 1),
        QuizQuestion(question: "Combien de continents y a-t-il ?", answers: ["5", "6", "7", "8"], correctIndex: 2),
        QuizQuestion(question: "Quel est le plus grand océan ?", answers: ["Atlantique", "Indien", "Arctique", "Pacifique"], correctIndex: 3),
        QuizQuestion(question: "Qui a peint la Joconde ?", answers: ["Picasso", "Van Gogh", "Da Vinci", "Monet"], correctIndex: 2),
        QuizQuestion(question: "Quel animal est le plus rapide ?", answers: ["Lion", "Guépard", "Aigle", "Lièvre"], correctIndex: 1),
        QuizQuestion(question: "En quelle année l'homme a marché sur la Lune ?", answers: ["1965", "1969", "1972", "1980"], correctIndex: 1),
        QuizQuestion(question: "Quel est le plus long fleuve du monde ?", answers: ["Amazone", "Nil", "Mississippi", "Yangtze"], correctIndex: 1),
        QuizQuestion(question: "Combien de joueurs dans une équipe de foot ?", answers: ["9", "10", "11", "12"], correctIndex: 2),
        QuizQuestion(question: "Quel pays a la forme d'une botte ?", answers: ["Espagne", "Grèce", "Italie", "Portugal"], correctIndex: 2),
        QuizQuestion(question: "Quel est le symbole chimique de l'eau ?", answers: ["O2", "H2O", "CO2", "NaCl"], correctIndex: 1),
        QuizQuestion(question: "Quelle planète est la plus proche du Soleil ?", answers: ["Vénus", "Mars", "Mercure", "Terre"], correctIndex: 2),
        QuizQuestion(question: "Combien de dents a un adulte ?", answers: ["28", "30", "32", "34"], correctIndex: 2),
        QuizQuestion(question: "Quel est le plus grand pays du monde ?", answers: ["Chine", "Canada", "Russie", "États-Unis"], correctIndex: 2),
        QuizQuestion(question: "Qui a écrit 'Les Misérables' ?", answers: ["Zola", "Hugo", "Flaubert", "Balzac"], correctIndex: 1),
        QuizQuestion(question: "Quelle est la monnaie du Japon ?", answers: ["Won", "Yuan", "Yen", "Baht"], correctIndex: 2),
        QuizQuestion(question: "Quel gaz les plantes produisent ?", answers: ["CO2", "Azote", "Oxygène", "Méthane"], correctIndex: 2),
        QuizQuestion(question: "Combien de côtés a un hexagone ?", answers: ["5", "6", "7", "8"], correctIndex: 1),
        QuizQuestion(question: "Quel est le sport le plus regardé au monde ?", answers: ["Basketball", "Cricket", "Football", "Tennis"], correctIndex: 2),
        QuizQuestion(question: "Dans quel pays se trouve le Machu Picchu ?", answers: ["Bolivie", "Pérou", "Colombie", "Chili"], correctIndex: 1),
        QuizQuestion(question: "Combien de cordes a une guitare standard ?", answers: ["4", "5", "6", "8"], correctIndex: 2),
    ]
    
    static func randomSet(count: Int = 5) -> [QuizQuestion] {
        Array(bank.shuffled().prefix(count))
    }
}

// MARK: — Simon State

struct SimonGameState {
    var sequence: [Int] = []     // indices 0-3 pour 4 couleurs
    var playerInput: [Int] = []
    var currentStep: Int = 0     // longueur actuelle de la séquence
    var isShowingSequence: Bool = false
    var highlightedButton: Int? = nil
    var isGameOver: Bool = false
    var score: Int = 0
    
    mutating func nextRound() {
        sequence.append(Int.random(in: 0...3))
        currentStep = sequence.count
        playerInput = []
    }
    
    static let colors = ["🔴", "🔵", "🟢", "🟡"]
}

// MARK: — Reaction State

struct ReactionGameState {
    var targetVisible: Bool = false
    var reactionTime: Double? = nil
    var targetAppearTime: Date? = nil
    var round: Int = 0
    var totalRounds: Int = 5
    var times: [Double] = []
    var isGameOver: Bool { round >= totalRounds }
    var averageTime: Double? {
        guard !times.isEmpty else { return nil }
        return times.reduce(0, +) / Double(times.count)
    }
    var score: Int {
        guard let avg = averageTime else { return 0 }
        if avg < 0.2 { return 100 }
        if avg < 0.3 { return 80 }
        if avg < 0.5 { return 50 }
        return 20
    }
}

// MARK: — Course de Buddys

struct RaceGameState {
    var playerPosition: Double = 0     // 0...1
    var opponentPositions: [Double] = [0, 0, 0]
    var swipeCount: Int = 0
    var timeRemaining: Double = 10     // secondes
    var isRacing: Bool = false
    var isGameOver: Bool = false
    var placement: Int = 4             // 1er, 2ème, etc.
    
    var score: Int {
        switch placement {
        case 1: return 100; case 2: return 60
        case 3: return 30; default: return 10
        }
    }
}

// MARK: — Pêche

struct FishingGameState {
    var fishPosition: Double = 0     // position du poisson 0...1
    var hookPosition: Double = 0.5   // position du crochet
    var catchZoneSize: Double = 0.15
    var caughtFish: Int = 0
    var missedFish: Int = 0
    var maxMisses: Int = 3
    var timeRemaining: Double = 30
    var isGameOver: Bool { missedFish >= maxMisses || timeRemaining <= 0 }
    var score: Int { caughtFish * 20 }
    
    var fishEmojis = ["🐟", "🐠", "🐡", "🦈", "🐙", "🦑", "🦀", "🐳"]
    var currentFish: String { fishEmojis[caughtFish % fishEmojis.count] }
}

// MARK: — Cuisine

struct CookingGameState {
    var recipe: CookingRecipe
    var selectedIngredients: [String] = []
    var timeRemaining: Double = 20
    var isGameOver: Bool = false
    var isSuccess: Bool = false
    var score: Int { isSuccess ? 100 : 0 }
    
    static func random() -> CookingGameState {
        CookingGameState(recipe: CookingRecipe.recipes.randomElement()!)
    }
}

struct CookingRecipe: Identifiable {
    let id = UUID()
    let name: String
    let emoji: String
    let requiredIngredients: [String]
    let allIngredients: [String]   // incluant des distracteurs
    
    static let recipes: [CookingRecipe] = [
        CookingRecipe(name: "Pizza", emoji: "🍕", requiredIngredients: ["🫓", "🧀", "🍅"], allIngredients: ["🫓", "🧀", "🍅", "🍌", "🥬", "🥚"]),
        CookingRecipe(name: "Burger", emoji: "🍔", requiredIngredients: ["🍞", "🥩", "🧀", "🥬"], allIngredients: ["🍞", "🥩", "🧀", "🥬", "🍫", "🎃"]),
        CookingRecipe(name: "Sushi", emoji: "🍣", requiredIngredients: ["🍚", "🐟", "🥒"], allIngredients: ["🍚", "🐟", "🥒", "🍎", "🍕", "🥛"]),
        CookingRecipe(name: "Crêpe", emoji: "🥞", requiredIngredients: ["🥚", "🫓", "🥛"], allIngredients: ["🥚", "🫓", "🥛", "🍆", "🌶️", "🐟"]),
        CookingRecipe(name: "Salade", emoji: "🥗", requiredIngredients: ["🥬", "🍅", "🥒"], allIngredients: ["🥬", "🍅", "🥒", "🍫", "🍕", "🍞"]),
    ]
}

// MARK: — Typing

struct TypingGameState {
    var currentWord: String = ""
    var playerInput: String = ""
    var wordsCompleted: Int = 0
    var timeRemaining: Double = 30
    var isGameOver: Bool { timeRemaining <= 0 }
    var score: Int { wordsCompleted * 15 }
    
    static let wordBank: [String] = [
        "buddy", "poche", "amitié", "jouer", "étoile", "dragon", "magie", "ninja",
        "course", "puzzle", "trésor", "victoire", "aventure", "cristal", "combat",
        "potion", "armure", "bouclier", "flamme", "éclair", "tempête", "lune",
        "soleil", "forêt", "océan", "montagne", "château", "pirate", "galaxie"
    ]
    
    mutating func nextWord() {
        currentWord = Self.wordBank.randomElement() ?? "buddy"
        playerInput = ""
    }
}

// MARK: — Scores historiques

struct GameHighScore: Codable, Identifiable {
    var id: String = UUID().uuidString
    let gameType: String
    let score: Int
    let date: Date
}
