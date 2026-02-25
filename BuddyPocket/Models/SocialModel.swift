import Foundation

// ══════════════════════════════════════════════════════════════════
// SOCIAL MODEL — Amis, Chat, Clans, Battles
// ══════════════════════════════════════════════════════════════════

// MARK: — Profil joueur

struct PlayerProfile: Codable, Identifiable {
    var id: String = UUID().uuidString
    var username: String
    var friendCode: String        // BUDDY#1234
    var level: Int
    var buddyBodyType: String
    var buddyColor: String
    var buddyEyeType: String
    var isOnline: Bool = false
    var isOfficial: Bool = false  // pour BUD
    var lastSeen: Date = Date()
    var clanID: String? = nil
    
    static func generateFriendCode() -> String {
        let num = Int.random(in: 1000...9999)
        return "BUDDY#\(num)"
    }
    
    static let bud = PlayerProfile(
        id: "bud_official",
        username: "BUD",
        friendCode: "BUDDY#0001",
        level: 50,
        buddyBodyType: BodyType.cosmique.rawValue,
        buddyColor: BuddyColor.doreBrillant.rawValue,
        buddyEyeType: EyeType.etoile.rawValue,
        isOnline: true,
        isOfficial: true
    )
}

// MARK: — Amis

struct FriendRequest: Codable, Identifiable {
    let id: String
    let fromUserID: String
    let fromUsername: String
    let fromFriendCode: String
    let date: Date
    var status: RequestStatus = .pending
}

enum RequestStatus: String, Codable {
    case pending, accepted, rejected
}

struct Friend: Codable, Identifiable {
    let id: String               // user ID de l'ami
    let username: String
    let friendCode: String
    var isOnline: Bool
    var level: Int
    var buddyPreview: BuddyPreview
    var isOfficial: Bool = false
    var lastSeen: Date = Date()
}

struct BuddyPreview: Codable {
    var bodyType: String
    var color: String
    var eyeType: String
    var headAccessory: String?
    var costume: String?
    var moodEmoji: String
}

// MARK: — Chat

struct ChatMessage: Codable, Identifiable {
    var id: String = UUID().uuidString
    let senderID: String
    let senderName: String
    let content: MessageContent
    let timestamp: Date
    var isRead: Bool = false
}

enum MessageContent: Codable {
    case text(String)
    case emoji(String)
    case gift(itemID: String, itemName: String)
    case battleInvite
    case photo(dataBase64: String)
    
    var displayText: String {
        switch self {
        case .text(let t): return t
        case .emoji(let e): return e
        case .gift(_, let name): return "🎁 Cadeau : \(name)"
        case .battleInvite: return "⚔️ Défi Battle !"
        case .photo: return "📷 Photo"
        }
    }
}

struct Conversation: Codable, Identifiable {
    let id: String             // unique par paire d'amis
    let participants: [String] // user IDs
    var messages: [ChatMessage]
    var lastActivity: Date
    
    var lastMessage: ChatMessage? { messages.last }
    var unreadCount: Int { messages.filter { !$0.isRead }.count }
}

// MARK: — Clans

struct Clan: Codable, Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var emoji: String
    var description: String
    var leaderID: String
    var memberIDs: [String]
    var createdDate: Date = Date()
    var chatMessages: [ChatMessage] = []
    var weeklyMission: ClanMission?
    var totalPoints: Int = 0
    var rank: Int = 0
    
    var memberCount: Int { memberIDs.count }
    var isFull: Bool { memberCount >= 20 }
    
    static let creationCost = 50 // gemmes
}

struct ClanMission: Codable, Identifiable {
    let id: String
    let description: String
    let emoji: String
    let target: Int
    var progress: Int = 0
    let rewardGems: Int      // 5💎 par membre
    let weekID: String
    
    var isCompleted: Bool { progress >= target }
    
    static func weekly() -> ClanMission {
        let missions = [
            ("Jouez 100 mini-jeux en clan", "🎮", 100, 5),
            ("Gagnez 50 battles ensemble", "⚔️", 50, 5),
            ("Nourrissez vos Buddys 200 fois", "🍖", 200, 5),
            ("Cumulez 500 niveaux de Battle Pass", "🏆", 500, 5),
        ]
        let m = missions.randomElement()!
        let cal = Calendar.current
        let weekNum = cal.component(.weekOfYear, from: Date())
        return ClanMission(id: "clan_w\(weekNum)", description: m.0, emoji: m.1, target: m.2, rewardGems: m.3, weekID: "\(cal.component(.year, from: Date()))-W\(weekNum)")
    }
}

// MARK: — Battle Mode

struct Battle: Codable, Identifiable {
    var id: String = UUID().uuidString
    let player1ID: String
    let player2ID: String
    var player1Score: Int = 0
    var player2Score: Int = 0
    var rounds: [BattleRound] = []
    var status: BattleStatus = .waiting
    var startTime: Date = Date()
    
    var winnerID: String? {
        guard status == .finished else { return nil }
        if player1Score > player2Score { return player1ID }
        if player2Score > player1Score { return player2ID }
        return nil  // égalité
    }
}

struct BattleRound: Codable, Identifiable {
    var id: String = UUID().uuidString
    let roundNumber: Int
    let type: BattleRoundType
    var player1Value: Int = 0
    var player2Value: Int = 0
}

enum BattleRoundType: String, Codable, CaseIterable {
    case strength = "Force"       // basé sur niveau
    case luck = "Chance"          // aléatoire
    case speed = "Vitesse"        // basé sur stats
    
    var emoji: String {
        switch self {
        case .strength: return "💪"
        case .luck: return "🍀"
        case .speed: return "⚡"
        }
    }
}

enum BattleStatus: String, Codable {
    case waiting, inProgress, finished
}

// MARK: — BUD Responses (Assistant officiel)

struct BudAssistant {
    static func respond(to message: String, playerLevel: Int, buddyName: String) -> String {
        let lower = message.lowercased()
        
        // Questions sur le jeu
        if lower.contains("comment") && lower.contains("gemme") {
            return "Tu peux gagner des gemmes en jouant aux mini-jeux (1-3💎), en complétant tes missions quotidiennes (2💎), en gagnant des battles (3💎), et en maintenant ton streak ! Max 15💎/jour 😊"
        }
        if lower.contains("boutique") || lower.contains("shop") {
            return "La boutique change chaque lundi ! Tu y trouveras 6 items rotatifs. Si tu as un streak de 5+ jours, un item est gratuit ! 🛍️"
        }
        if lower.contains("battle") || lower.contains("combat") {
            return "Les battles sont basés sur les stats + un peu de chance. Tu gagnes 3💎 par victoire, max 10 battles récompensés par jour ! ⚔️"
        }
        if lower.contains("clan") {
            return "Créer un clan coûte 50💎, ou tu peux en rejoindre un gratuitement ! Max 20 membres, avec des missions hebdo collectives et un classement mondial 🏰"
        }
        if lower.contains("streak") || lower.contains("flamme") {
            return "Connecte-toi chaque jour pour maintenir ta flamme 🔥 ! Récompenses : 1💎 (j1), 2💎 (j3), 5💎 (j7), 10💎 (j14), 20💎 (j30) !"
        }
        if lower.contains("level") || lower.contains("niveau") {
            return "Tu es niveau \(playerLevel) ! Continue de t'occuper de \(buddyName) et de jouer pour gagner de l'XP. Il y a 50 niveaux au total 📈"
        }
        if lower.contains("secret") || lower.contains("caché") {
            return "Il existe des corps secrets déblocables à haut niveau... 👀 Continue de progresser !"
        }
        
        // Messages positifs
        if lower.contains("merci") {
            return "De rien ! Je suis toujours là pour t'aider 😊✨"
        }
        if lower.contains("bonjour") || lower.contains("salut") || lower.contains("hello") {
            return "Salut ! Comment va \(buddyName) aujourd'hui ? 🌟"
        }
        
        // Personnalisé selon le niveau
        if playerLevel < 5 {
            return "Hey ! N'oublie pas de nourrir \(buddyName) régulièrement et d'explorer les mini-jeux pour gagner des coins et gemmes ! 🎮"
        }
        if playerLevel < 15 {
            return "Tu progresses bien ! As-tu pensé à rejoindre un clan ? Les missions en groupe rapportent beaucoup ! 🏰"
        }
        if playerLevel < 30 {
            return "\(buddyName) est de plus en plus fort ! Continue comme ça, des surprises t'attendent aux niveaux élevés... 🔮"
        }
        
        // Défaut
        let defaults = [
            "Je suis BUD, ton assistant officiel ! Pose-moi une question sur le jeu 🤖",
            "Savais-tu que la boutique change chaque lundi ? Vérifie les nouveautés ! 🛍️",
            "Astuce : les missions quotidiennes rapportent 2💎 si tu les complètes toutes !",
            "N'oublie pas de garder ton streak ! La flamme, c'est la vie 🔥",
            "Tu peux envoyer des cadeaux à tes amis depuis le chat ! 🎁",
        ]
        return defaults.randomElement()!
    }
}
