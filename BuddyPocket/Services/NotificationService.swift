import Foundation
import UserNotifications

// ══════════════════════════════════════════════════════════════════
// NOTIFICATION SERVICE — Notifications locales programmées
// ══════════════════════════════════════════════════════════════════

class NotificationService {
    static let shared = NotificationService()
    
    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        } catch { return false }
    }
    
    // MARK: — Programmation
    
    func scheduleStatAlert(buddyName: String, stat: StatType, value: Double) {
        guard value < 0.2 else { return }
        
        let content = UNMutableNotificationContent()
        content.sound = .default
        
        switch stat {
        case .hunger:
            content.title = "🍖 \(buddyName) a faim !"
            content.body = "Vite, nourris \(buddyName) avant qu'il ne s'évanouisse !"
        case .happiness:
            content.title = "😢 \(buddyName) est triste..."
            content.body = "Ton Buddy a besoin d'attention et de câlins !"
        case .energy:
            content.title = "⚡ \(buddyName) est épuisé !"
            content.body = "Laisse \(buddyName) se reposer un peu..."
        case .hygiene:
            content.title = "🛁 \(buddyName) a besoin d'un bain !"
            content.body = "Un petit passage par la douche s'impose !"
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 300, repeats: false)
        let request = UNNotificationRequest(identifier: "stat_\(stat.rawValue)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleDailyReward() {
        let content = UNMutableNotificationContent()
        content.title = "🎁 Ta récompense quotidienne t'attend !"
        content.body = "Connecte-toi pour maintenir ta flamme et récupérer tes gemmes !"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 10
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_reward", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleBattleChallenge(fromFriend friendName: String) {
        let content = UNMutableNotificationContent()
        content.title = "⚔️ \(friendName) te défie en battle !"
        content.body = "Montre-lui qui est le plus fort !"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "battle_\(UUID().uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleClanMission() {
        let content = UNMutableNotificationContent()
        content.title = "🏆 Ton clan a besoin de toi !"
        content.body = "Une nouvelle mission de clan est disponible !"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.weekday = 2 // Lundi
        dateComponents.hour = 9
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "clan_mission", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleShopReset() {
        let content = UNMutableNotificationContent()
        content.title = "🛒 Nouvelle boutique disponible !"
        content.body = "Découvre les nouveaux items de la semaine !"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.weekday = 2 // Lundi
        dateComponents.hour = 8
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "shop_reset", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: — Nettoyage
    
    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func cancelStat(_ stat: StatType) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["stat_\(stat.rawValue)"])
    }
}
