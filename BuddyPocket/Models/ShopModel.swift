import Foundation

// ══════════════════════════════════════════════════════════════════
// SHOP MODEL — Boutique, Battle Pass, IAP, Événements
// ══════════════════════════════════════════════════════════════════

// MARK: — Boutique hebdomadaire

struct WeeklyShop: Codable {
    var items: [ShopSlot]
    var freeItemID: String?           // gratuit si streak 5+
    var resetDate: Date               // prochain lundi
    var weekID: String                // ex: "2026-W09"
    
    static func generate(gender: Gender, weekID: String, excludeRecent: [String]) -> WeeklyShop {
        let allPremium = ItemCatalog.allItems(for: gender).filter { $0.isPremium }
        let available = allPremium.filter { !excludeRecent.contains($0.id) }
        let shuffled = available.shuffled()
        
        var slots: [ShopSlot] = []
        var tenues = shuffled.filter { $0.category == .top || $0.category == .costume }.prefix(2)
        var decos  = shuffled.filter { $0.category == .headAccessory }.prefix(2)
        var themes = shuffled.filter { $0.category == .roomTheme || $0.category == .special }.prefix(1)
        var mystere = shuffled.filter { !tenues.contains($0) && !decos.contains($0) && !themes.contains($0) }.prefix(1)
        
        for item in (Array(tenues) + Array(decos) + Array(themes) + Array(mystere)).prefix(6) {
            slots.append(ShopSlot(item: item, discount: nil))
        }
        
        // Remplir jusqu'à 6 si pas assez
        while slots.count < 6 {
            if let extra = available.randomElement() {
                slots.append(ShopSlot(item: extra, discount: nil))
            } else { break }
        }
        
        let calendar = Calendar.current
        let nextMonday = calendar.nextDate(after: Date(), matching: DateComponents(weekday: 2), matchingPolicy: .nextTime)!
        
        return WeeklyShop(items: slots, freeItemID: slots.first?.item.id, resetDate: nextMonday, weekID: weekID)
    }
}

struct ShopSlot: Codable, Identifiable {
    var id: String { item.id }
    let item: CatalogItem
    var discount: Int?        // pourcentage, nil = prix normal
    var isPurchased: Bool = false
    
    var finalPrice: Int {
        guard let disc = discount else { return item.price }
        return max(1, item.price - (item.price * disc / 100))
    }
}

// MARK: — Battle Pass

struct BattlePass: Codable, Identifiable {
    let id: String              // "season_1"
    let name: String            // "Cosmos"
    let emoji: String
    let startDate: Date
    let endDate: Date
    var currentLevel: Int = 0
    var xp: Int = 0
    var isPremium: Bool = false
    var rewards: [BPReward]
    
    var xpForNextLevel: Int { 200 + (currentLevel * 50) }
    var isActive: Bool { Date() >= startDate && Date() <= endDate }
    var daysRemaining: Int {
        max(0, Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0)
    }
    
    mutating func addXP(_ amount: Int) {
        xp += amount
        while xp >= xpForNextLevel && currentLevel < 30 {
            xp -= xpForNextLevel
            currentLevel += 1
        }
    }
    
    static let season1 = BattlePass(
        id: "season_1", name: "Cosmos", emoji: "🚀",
        startDate: Date(), endDate: Calendar.current.date(byAdding: .month, value: 2, to: Date())!,
        rewards: BPReward.season1Rewards
    )
}

struct BPReward: Codable, Identifiable {
    let id: String
    let level: Int
    let name: String
    let emoji: String
    let isPremiumOnly: Bool
    let rewardType: BPRewardType
    let value: Int             // gems, coins, ou item price
    
    var isLocked: Bool { false } // calculé dynamiquement
}

enum BPRewardType: String, Codable {
    case gems, coins, item, costume, theme, exclusive
}

extension BPReward {
    static let season1Rewards: [BPReward] = (1...30).map { level in
        let isPremium = level % 3 == 0
        let type: BPRewardType
        let value: Int
        let name: String
        let emoji: String
        
        switch level % 5 {
        case 0:
            type = .costume; value = 0; name = "Costume Cosmique Nv\(level)"; emoji = "🚀"
        case 1:
            type = .gems; value = level * 2; name = "\(level * 2) Gemmes"; emoji = "💎"
        case 2:
            type = .coins; value = level * 20; name = "\(level * 20) Coins"; emoji = "🪙"
        case 3:
            type = .item; value = 0; name = "Accessoire Étoile"; emoji = "⭐"
        default:
            type = .theme; value = 0; name = "Thème Nébuleuse"; emoji = "🌌"
        }
        
        return BPReward(id: "bp_s1_\(level)", level: level, name: name, emoji: emoji, isPremiumOnly: isPremium, rewardType: type, value: value)
    }
}

// MARK: — Flash Sales

struct FlashSale: Codable, Identifiable {
    let id: String
    let item: CatalogItem
    let discount: Int          // 30-50%
    let startTime: Date
    let endTime: Date          // 1-2h après start
    
    var isActive: Bool { Date() >= startTime && Date() <= endTime }
    var minutesRemaining: Int {
        max(0, Int(endTime.timeIntervalSince(Date()) / 60))
    }
    var finalPrice: Int { max(1, item.price - (item.price * discount / 100)) }
}

// MARK: — Événements saisonniers

struct SeasonalEvent: Identifiable, Codable {
    let id: String
    let name: String
    let emoji: String
    let startDate: Date
    let endDate: Date          // 2 semaines
    let exclusiveItems: [CatalogItem]
    let bonusGems: Int         // jusqu'à 50
    
    var isActive: Bool { Date() >= startDate && Date() <= endDate }
    var daysRemaining: Int {
        max(0, Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0)
    }
    
    static let allEvents: [SeasonalEvent] = [
        SeasonalEvent(id: "halloween", name: "Halloween", emoji: "🎃",
                      startDate: dateFrom(month: 10, day: 20), endDate: dateFrom(month: 11, day: 3),
                      exclusiveItems: [], bonusGems: 50),
        SeasonalEvent(id: "noel", name: "Noël", emoji: "🎄",
                      startDate: dateFrom(month: 12, day: 15), endDate: dateFrom(month: 12, day: 29),
                      exclusiveItems: [], bonusGems: 50),
        SeasonalEvent(id: "ramadan", name: "Ramadan", emoji: "🌙",
                      startDate: dateFrom(month: 2, day: 28), endDate: dateFrom(month: 3, day: 14),
                      exclusiveItems: [], bonusGems: 50),
        SeasonalEvent(id: "valentine", name: "Saint-Valentin", emoji: "❤️",
                      startDate: dateFrom(month: 2, day: 7), endDate: dateFrom(month: 2, day: 21),
                      exclusiveItems: [], bonusGems: 30),
        SeasonalEvent(id: "summer", name: "Été", emoji: "☀️",
                      startDate: dateFrom(month: 6, day: 21), endDate: dateFrom(month: 7, day: 5),
                      exclusiveItems: [], bonusGems: 40),
        SeasonalEvent(id: "backtoschool", name: "Rentrée", emoji: "📚",
                      startDate: dateFrom(month: 9, day: 1), endDate: dateFrom(month: 9, day: 15),
                      exclusiveItems: [], bonusGems: 30),
    ]
    
    private static func dateFrom(month: Int, day: Int) -> Date {
        var comps = Calendar.current.dateComponents([.year], from: Date())
        comps.month = month; comps.day = day
        return Calendar.current.date(from: comps) ?? Date()
    }
}

// MARK: — IAP Products

enum IAPProduct: String, CaseIterable {
    case gems100  = "com.rezaimia.buddypocket.gems100"
    case gems500  = "com.rezaimia.buddypocket.gems500"
    case gems1200 = "com.rezaimia.buddypocket.gems1200"
    case premium  = "com.rezaimia.buddypocket.premium"
    
    var displayName: String {
        switch self {
        case .gems100:  return "100 💎"
        case .gems500:  return "500 💎"
        case .gems1200: return "1200 💎"
        case .premium:  return "Buddy Premium"
        }
    }
    
    var price: String {
        switch self {
        case .gems100:  return "0,99€"
        case .gems500:  return "3,99€"
        case .gems1200: return "7,99€"
        case .premium:  return "2,99€/mois"
        }
    }
    
    var gems: Int {
        switch self {
        case .gems100: return 100; case .gems500: return 500
        case .gems1200: return 1200; case .premium: return 200
        }
    }
    
    var isSubscription: Bool { self == .premium }
}

// MARK: — Missions quotidiennes

struct DailyMission: Identifiable, Codable {
    let id: String
    let description: String
    let emoji: String
    let target: Int
    var progress: Int = 0
    let rewardGems: Int
    let rewardCoins: Int
    
    var isCompleted: Bool { progress >= target }
    var progressPercent: Double { min(1, Double(progress) / Double(target)) }
    
    static func dailySet() -> [DailyMission] {
        [
            DailyMission(id: "daily_feed", description: "Nourris ton Buddy 3 fois", emoji: "🍖", target: 3, rewardGems: 1, rewardCoins: 10),
            DailyMission(id: "daily_game", description: "Joue à 2 mini-jeux", emoji: "🎮", target: 2, rewardGems: 1, rewardCoins: 15),
            DailyMission(id: "daily_social", description: "Envoie un message", emoji: "💬", target: 1, rewardGems: 1, rewardCoins: 5),
            DailyMission(id: "daily_all", description: "Complète toutes les missions", emoji: "🏆", target: 1, rewardGems: 2, rewardCoins: 25),
        ]
    }
}

// MARK: — Achievements

struct Achievement: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let emoji: String
    let rewardGems: Int
    var isUnlocked: Bool = false
    
    static let all: [Achievement] = [
        Achievement(id: "ach_first_feed", name: "Premier repas", description: "Nourris ton Buddy pour la première fois", emoji: "🍽️", rewardGems: 5),
        Achievement(id: "ach_level5", name: "Débutant", description: "Atteins le niveau 5", emoji: "⭐", rewardGems: 10),
        Achievement(id: "ach_level10", name: "Intermédiaire", description: "Atteins le niveau 10", emoji: "🌟", rewardGems: 15),
        Achievement(id: "ach_level25", name: "Expert", description: "Atteins le niveau 25", emoji: "💫", rewardGems: 20),
        Achievement(id: "ach_level50", name: "Légende", description: "Atteins le niveau 50", emoji: "🏆", rewardGems: 50),
        Achievement(id: "ach_streak7", name: "Une semaine !", description: "7 jours de streak", emoji: "🔥", rewardGems: 10),
        Achievement(id: "ach_streak30", name: "Un mois !", description: "30 jours de streak", emoji: "🔥", rewardGems: 30),
        Achievement(id: "ach_10friends", name: "Populaire", description: "Ajoute 10 amis", emoji: "👥", rewardGems: 15),
        Achievement(id: "ach_first_battle", name: "Guerrier", description: "Gagne ton premier battle", emoji: "⚔️", rewardGems: 5),
        Achievement(id: "ach_10battles", name: "Champion", description: "Gagne 10 battles", emoji: "🏅", rewardGems: 20),
        Achievement(id: "ach_clan", name: "Membre de clan", description: "Rejoins un clan", emoji: "🏰", rewardGems: 10),
        Achievement(id: "ach_allgames", name: "Joueur complet", description: "Joue à tous les mini-jeux", emoji: "🎮", rewardGems: 15),
        Achievement(id: "ach_100costumes", name: "Fashionista", description: "Débloques 100 items", emoji: "👗", rewardGems: 20),
    ]
}
