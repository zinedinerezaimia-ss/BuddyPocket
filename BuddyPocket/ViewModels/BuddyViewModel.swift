import SwiftUI
import WidgetKit
import Combine

// ══════════════════════════════════════════════════════════════════
// BUDDY VIEW MODEL — Source de vérité principale
// ══════════════════════════════════════════════════════════════════

@MainActor
class BuddyViewModel: ObservableObject {
    @Published var buddy = Buddy()
    @Published var dailyMissions: [DailyMission] = DailyMission.dailySet()
    @Published var achievements: [Achievement] = Achievement.all
    @Published var gameTracker = DailyGameTracker(date: DailyGameTracker.today())
    @Published var highScores: [GameHighScore] = []
    @Published var showLevelUp = false
    @Published var lastRewardMessage: String?
    @Published var profile: PlayerProfile?
    
    private var statTimer: Timer?
    private var saveDebounce: AnyCancellable?
    
    init() {
        loadAll()
        startStatDecay()
        checkDailyReset()
        checkStreak()
        setupAutoSave()
    }
    
    // MARK: — Actions
    
    func performAction(_ action: BuddyAction) {
        withAnimation(BP.springAnim) {
            switch action {
            case .feed:
                buddy.hunger = min(1, buddy.hunger + 0.3)
                HapticService.feed()
            case .pet:
                buddy.happiness = min(1, buddy.happiness + 0.25)
                HapticService.pet()
            case .sleep:
                buddy.energy = min(1, buddy.energy + 0.35)
                HapticService.pet()
            case .bath:
                buddy.hygiene = min(1, buddy.hygiene + 0.3)
                HapticService.feed()
            }
            
            buddy.addXP(action.xpReward)
            buddy.coins += action.coinReward
            
            // Missions
            updateMission(for: action)
            
            // Notifications
            NotificationService.shared.cancelStat(action.stat)
        }
        
        checkLevelUp()
        save()
        syncWidget()
    }
    
    // MARK: — Stats Decay
    
    private func startStatDecay() {
        statTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.decayStats()
            }
        }
    }
    
    private func decayStats() {
        let rate = 0.002  // ~12% par heure
        buddy.hunger    = max(0, buddy.hunger - rate)
        buddy.happiness = max(0, buddy.happiness - rate * 0.8)
        buddy.energy    = max(0, buddy.energy - rate * 0.6)
        buddy.hygiene   = max(0, buddy.hygiene - rate * 0.5)
        
        // Notifications pour stats critiques
        if let stat = buddy.criticalStat {
            HapticService.criticalStat()
            NotificationService.shared.scheduleStatAlert(buddyName: buddy.name, stat: stat, value: 0.15)
        }
    }
    
    // MARK: — Streaks
    
    private func checkStreak() {
        let today = DailyGameTracker.today()
        guard buddy.lastLoginDate != today else { return }
        
        let yesterday = yesterdayString()
        if buddy.lastLoginDate == yesterday {
            buddy.streakDays += 1
        } else if buddy.lastLoginDate != nil && buddy.lastLoginDate != yesterday {
            if buddy.hasStreakShield {
                buddy.hasStreakShield = false
            } else {
                buddy.streakDays = 1
            }
        } else {
            buddy.streakDays = 1
        }
        
        buddy.lastLoginDate = today
        
        // Récompense streak
        let gems = StreakReward.reward(forDay: buddy.streakDays)
        buddy.gems += gems
        lastRewardMessage = "🔥 Streak Jour \(buddy.streakDays) ! +\(gems)💎"
        
        save()
    }
    
    private func yesterdayString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        return f.string(from: yesterday)
    }
    
    // MARK: — Daily Reset
    
    private func checkDailyReset() {
        let today = DailyGameTracker.today()
        if gameTracker.date != today {
            gameTracker = DailyGameTracker(date: today)
            dailyMissions = DailyMission.dailySet()
        }
    }
    
    // MARK: — Missions
    
    private func updateMission(for action: BuddyAction) {
        if action == .feed {
            if let i = dailyMissions.firstIndex(where: { $0.id == "daily_feed" }) {
                dailyMissions[i].progress += 1
                checkMissionCompletion(i)
            }
        }
    }
    
    func recordGamePlayed() {
        if let i = dailyMissions.firstIndex(where: { $0.id == "daily_game" }) {
            dailyMissions[i].progress += 1
            checkMissionCompletion(i)
        }
    }
    
    func recordMessageSent() {
        if let i = dailyMissions.firstIndex(where: { $0.id == "daily_social" }) {
            dailyMissions[i].progress += 1
            checkMissionCompletion(i)
        }
    }
    
    private func checkMissionCompletion(_ index: Int) {
        guard dailyMissions[index].isCompleted else { return }
        buddy.gems += dailyMissions[index].rewardGems
        buddy.coins += dailyMissions[index].rewardCoins
        
        // Vérifier si toutes les missions sont complètes
        let allDone = dailyMissions.filter({ $0.id != "daily_all" }).allSatisfy(\.isCompleted)
        if allDone, let ai = dailyMissions.firstIndex(where: { $0.id == "daily_all" }) {
            dailyMissions[ai].progress = 1
            buddy.gems += dailyMissions[ai].rewardGems
            buddy.coins += dailyMissions[ai].rewardCoins
        }
    }
    
    // MARK: — Game Rewards
    
    func rewardForGame(score: Int, game: MiniGame) {
        let gemsWon = gameTracker.canEarnGems ? Int.random(in: game.rewardRange) : 0
        let coinsWon = game.coinReward
        let xpWon = game.xpReward
        
        gameTracker.recordGame(gems: gemsWon)
        buddy.gems += min(gemsWon, DailyGameTracker.maxGemsPerDay - gameTracker.gemsEarnedToday + gemsWon)
        buddy.coins += coinsWon
        buddy.addXP(xpWon)
        
        recordGamePlayed()
        
        // High score
        let existing = highScores.first(where: { $0.gameType == game.rawValue })
        if existing == nil || (existing?.score ?? 0) < score {
            highScores.removeAll(where: { $0.gameType == game.rawValue })
            highScores.append(GameHighScore(gameType: game.rawValue, score: score, date: Date()))
        }
        
        checkLevelUp()
        save()
    }
    
    func rewardForBattle(won: Bool) {
        if won {
            let gems = gameTracker.canEarnBattleReward ? 3 : 0
            gameTracker.recordBattle(gems: gems)
            buddy.gems += gems
            buddy.addXP(30)
            buddy.coins += 20
            HapticService.battleWin()
        } else {
            buddy.addXP(10)
            buddy.coins += 5
        }
        checkLevelUp()
        save()
    }
    
    // MARK: — Level Up
    
    private func checkLevelUp() {
        let oldLevel = buddy.level
        // addXP déjà gère le levelup, on check juste pour l'UI
        if buddy.level > oldLevel {
            showLevelUp = true
            HapticService.levelUp()
            
            // Débloquer corps secrets
            for body in BodyType.allSecret {
                if let req = body.unlockLevel, buddy.level >= req, !buddy.unlockedBodies.contains(body.rawValue) {
                    buddy.unlockedBodies.append(body.rawValue)
                }
            }
            
            // Achievements
            checkAchievements()
        }
    }
    
    // MARK: — Achievements
    
    func checkAchievements() {
        for i in achievements.indices {
            guard !achievements[i].isUnlocked else { continue }
            switch achievements[i].id {
            case "ach_level5":  achievements[i].isUnlocked = buddy.level >= 5
            case "ach_level10": achievements[i].isUnlocked = buddy.level >= 10
            case "ach_level25": achievements[i].isUnlocked = buddy.level >= 25
            case "ach_level50": achievements[i].isUnlocked = buddy.level >= 50
            case "ach_streak7": achievements[i].isUnlocked = buddy.streakDays >= 7
            case "ach_streak30": achievements[i].isUnlocked = buddy.streakDays >= 30
            default: break
            }
            if achievements[i].isUnlocked {
                buddy.gems += achievements[i].rewardGems
            }
        }
    }
    
    // MARK: — Customization
    
    func equipItem(_ itemID: String, category: ItemCategory) {
        switch category {
        case .headAccessory: buddy.headAccessory = itemID
        case .top:
            buddy.topClothing = itemID
            buddy.costume = nil
        case .bottom:
            buddy.bottomClothing = itemID
            buddy.costume = nil
        case .costume:
            buddy.costume = itemID
            buddy.topClothing = nil
            buddy.bottomClothing = nil
        default: break
        }
        save()
        syncWidget()
    }
    
    func unequipItem(_ category: ItemCategory) {
        switch category {
        case .headAccessory: buddy.headAccessory = nil
        case .top: buddy.topClothing = nil
        case .bottom: buddy.bottomClothing = nil
        case .costume: buddy.costume = nil
        default: break
        }
        save()
    }
    
    func purchaseItem(_ item: CatalogItem) -> Bool {
        guard buddy.gems >= item.price else { return false }
        buddy.gems -= item.price
        
        switch item.category {
        case .headAccessory: buddy.unlockedHeadAccessories.append(item.id)
        case .top: buddy.unlockedTops.append(item.id)
        case .bottom: buddy.unlockedBottoms.append(item.id)
        case .costume: buddy.unlockedCostumes.append(item.id)
        case .roomTheme: buddy.unlockedRoomThemes.append(item.id)
        case .decor: buddy.unlockedDecor.append(item.id)
        default: break
        }
        
        HapticService.purchase()
        save()
        return true
    }
    
    func isUnlocked(_ item: CatalogItem) -> Bool {
        if buddy.isDevMode { return true }
        if !item.isPremium && buddy.level >= item.requiredLevel { return true }
        switch item.category {
        case .headAccessory: return buddy.unlockedHeadAccessories.contains(item.id)
        case .top: return buddy.unlockedTops.contains(item.id)
        case .bottom: return buddy.unlockedBottoms.contains(item.id)
        case .costume: return buddy.unlockedCostumes.contains(item.id)
        default: return false
        }
    }
    
    // MARK: — Room Decoration
    
    func placeDecor(_ decorID: String, emoji: String, at point: CGPoint, isWall: Bool) {
        let placement = DecorPlacement(decorID: decorID, emoji: emoji, x: point.x, y: point.y, isWall: isWall)
        buddy.decorItems.append(placement)
        save()
    }
    
    func removeDecor(_ id: String) {
        buddy.decorItems.removeAll { $0.id == id }
        save()
    }
    
    func moveDecor(_ id: String, to point: CGPoint) {
        if let i = buddy.decorItems.firstIndex(where: { $0.id == id }) {
            buddy.decorItems[i].x = point.x
            buddy.decorItems[i].y = point.y
            save()
        }
    }
    
    // MARK: — Dev Mode
    
    func activateDevMode(code: String) -> Bool {
        guard code == "ZETA_DEV_2026" else { return false }
        buddy.isDevMode = true
        buddy.coins = Int.max / 2
        buddy.gems = Int.max / 2
        buddy.level = 50
        buddy.bodyType = .fantome
        buddy.headAccessory = "pacc_spiderman"
        buddy.topClothing = nil
        buddy.bottomClothing = "bbot_baggy"
        buddy.costume = "bcostp_psgplayer"
        save()
        return true
    }
    
    // MARK: — Persistance
    
    private func setupAutoSave() {
        saveDebounce = $buddy
            .debounce(for: .seconds(2), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.save() }
    }
    
    func save() {
        BuddyStore.save(buddy)
        saveGameTracker()
        saveMissions()
        saveAchievements()
        saveHighScores()
    }
    
    func loadAll() {
        buddy = BuddyStore.load()
        loadGameTracker()
        loadMissions()
        loadAchievements()
        loadHighScores()
    }
    
    private func saveGameTracker() {
        if let data = try? JSONEncoder().encode(gameTracker) {
            UserDefaults.standard.set(data, forKey: "game_tracker")
        }
    }
    private func loadGameTracker() {
        if let data = UserDefaults.standard.data(forKey: "game_tracker"),
           let t = try? JSONDecoder().decode(DailyGameTracker.self, from: data) {
            gameTracker = t
        }
    }
    private func saveMissions() {
        if let data = try? JSONEncoder().encode(dailyMissions) {
            UserDefaults.standard.set(data, forKey: "daily_missions")
        }
    }
    private func loadMissions() {
        if let data = UserDefaults.standard.data(forKey: "daily_missions"),
           let m = try? JSONDecoder().decode([DailyMission].self, from: data) {
            dailyMissions = m
        }
    }
    private func saveAchievements() {
        if let data = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(data, forKey: "achievements")
        }
    }
    private func loadAchievements() {
        if let data = UserDefaults.standard.data(forKey: "achievements"),
           let a = try? JSONDecoder().decode([Achievement].self, from: data) {
            achievements = a
        }
    }
    private func saveHighScores() {
        if let data = try? JSONEncoder().encode(highScores) {
            UserDefaults.standard.set(data, forKey: "high_scores")
        }
    }
    private func loadHighScores() {
        if let data = UserDefaults.standard.data(forKey: "high_scores"),
           let h = try? JSONDecoder().decode([GameHighScore].self, from: data) {
            highScores = h
        }
    }
    
    // MARK: — Widget Sync
    
    func syncWidget() {
        let widgetData: [String: Any] = [
            "name": buddy.name,
            "hunger": buddy.hunger,
            "happiness": buddy.happiness,
            "energy": buddy.energy,
            "hygiene": buddy.hygiene,
            "level": buddy.level,
            "streak": buddy.streakDays,
            "bodyType": buddy.bodyType.rawValue,
            "bodyColor": buddy.bodyColor.rawValue,
            "eyeType": buddy.eyeType.rawValue,
            "mood": buddy.moodEmoji
        ]
        if let data = try? JSONSerialization.data(withJSONObject: widgetData) {
            BuddyStore.shared.set(data, forKey: "widget_buddy")
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}
