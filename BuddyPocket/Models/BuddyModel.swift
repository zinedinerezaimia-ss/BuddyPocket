import SwiftUI

// ══════════════════════════════════════════════════════════════════
// BUDDY MODEL — Toutes les données du compagnon virtuel
// ══════════════════════════════════════════════════════════════════

// MARK: — Buddy Principal

struct Buddy: Codable, Identifiable {
    var id: String = UUID().uuidString
    var name: String = "Mon Buddy"
    var gender: Gender = .boy
    var bodyType: BodyType = .blob
    var bodyColor: BuddyColor = .violet
    var eyeType: EyeType = .normal
    var headAccessory: String? = nil
    var topClothing: String? = nil
    var bottomClothing: String? = nil
    var costume: String? = nil   // si set → remplace top + bottom
    var roomTheme: RoomTheme = .defaultTheme
    var decorItems: [DecorPlacement] = []
    
    // Stats
    var hunger: Double = 1.0      // 0...1
    var happiness: Double = 1.0
    var energy: Double = 1.0
    var hygiene: Double = 1.0
    
    // Progression
    var level: Int = 1
    var xp: Int = 0
    var coins: Int = 100
    var gems: Int = 10
    
    // Streaks
    var streakDays: Int = 0
    var lastLoginDate: String? = nil
    var hasStreakShield: Bool = false
    
    // Inventaire débloqué
    var unlockedBodies: [String] = BodyType.allBasic.map(\.rawValue)
    var unlockedColors: [String] = BuddyColor.allBasic.map(\.rawValue)
    var unlockedEyes: [String] = EyeType.allBasic.map(\.rawValue)
    var unlockedHeadAccessories: [String] = []
    var unlockedTops: [String] = []
    var unlockedBottoms: [String] = []
    var unlockedCostumes: [String] = []
    var unlockedRoomThemes: [String] = RoomTheme.allBasic.map(\.rawValue)
    var unlockedDecor: [String] = []
    
    // Dev mode
    var isDevMode: Bool = false
    
    // XP requis pour le prochain niveau
    var xpForNextLevel: Int { level * 100 + 50 }
    var xpProgress: Double { Double(xp) / Double(xpForNextLevel) }
    
    mutating func addXP(_ amount: Int) {
        xp += amount
        while xp >= xpForNextLevel {
            xp -= xpForNextLevel
            level = min(level + 1, 50)
        }
    }
    
    // Stats critiques
    var criticalStat: StatType? {
        if hunger < 0.2 { return .hunger }
        if happiness < 0.2 { return .happiness }
        if energy < 0.2 { return .energy }
        if hygiene < 0.2 { return .hygiene }
        return nil
    }
    
    var moodEmoji: String {
        let avg = (hunger + happiness + energy + hygiene) / 4
        if avg > 0.8 { return "😊" }
        if avg > 0.6 { return "🙂" }
        if avg > 0.4 { return "😐" }
        if avg > 0.2 { return "😟" }
        return "😢"
    }
    
    var dialogueBubble: String {
        if let stat = criticalStat {
            switch stat {
            case .hunger:    return "J'ai trop faim... 🍖"
            case .happiness: return "Je me sens triste... 😢"
            case .energy:    return "Je suis épuisé... 💤"
            case .hygiene:   return "J'ai besoin d'un bain ! 🛁"
            }
        }
        let avg = (hunger + happiness + energy + hygiene) / 4
        if avg > 0.8 { return ["Je suis trop content !", "On joue ? 🎮", "T'es le meilleur ! ✨", "Quelle belle journée !"].randomElement()! }
        if avg > 0.5 { return ["Ça va tranquille 😊", "On fait quoi ?", "Hey salut !"].randomElement()! }
        return ["Hmm...", "J'ai connu mieux...", "Tu pourrais t'occuper de moi ?"].randomElement()!
    }
}

enum Gender: String, Codable, CaseIterable {
    case boy = "Garçon"
    case girl = "Fille"
    var icon: String { self == .boy ? "👦" : "👧" }
}

enum StatType: String, CaseIterable {
    case hunger = "Faim"
    case happiness = "Bonheur"
    case energy = "Énergie"
    case hygiene = "Hygiène"
    
    var icon: String {
        switch self {
        case .hunger:    return "🍖"
        case .happiness: return "😊"
        case .energy:    return "⚡"
        case .hygiene:   return "🛁"
        }
    }
    var color: Color {
        switch self {
        case .hunger:    return BP.orange
        case .happiness: return BP.pink
        case .energy:    return BP.yellow
        case .hygiene:   return BP.blue
        }
    }
}

// MARK: — Corps

struct AnchorOffsets: Codable {
    var eyeY: CGFloat = 0
    var hatY: CGFloat = 0
    var clothesY: CGFloat = 0
    var clothesScale: CGFloat = 1.0
}

enum BodyType: String, Codable, CaseIterable, Identifiable {
    // 20 de base
    case blob, chat, lapin, chien, fantome, panda, dragon, ours, renard, chouette
    case pingouin, koala, lion, licorne, alien, dino, diable, phenix, cosmique, slime
    // 10 secrets (niveaux élevés)
    case clown, crane, robot, loupGarou, sirene, phenixDore, demonAncien, bebeDragon, cristalVivant, arcEnCiel
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .blob: return "Blob"; case .chat: return "Chat"; case .lapin: return "Lapin"
        case .chien: return "Chien"; case .fantome: return "Fantôme"; case .panda: return "Panda"
        case .dragon: return "Dragon"; case .ours: return "Ours"; case .renard: return "Renard"
        case .chouette: return "Chouette"; case .pingouin: return "Pingouin"; case .koala: return "Koala"
        case .lion: return "Lion"; case .licorne: return "Licorne"; case .alien: return "Alien"
        case .dino: return "Dino"; case .diable: return "Diable"; case .phenix: return "Phénix"
        case .cosmique: return "Cosmique"; case .slime: return "Slime"
        case .clown: return "Clown"; case .crane: return "Crâne"; case .robot: return "Robot"
        case .loupGarou: return "Loup-Garou"; case .sirene: return "Sirène"
        case .phenixDore: return "Phénix Doré"; case .demonAncien: return "Démon Ancien"
        case .bebeDragon: return "Bébé Dragon"; case .cristalVivant: return "Cristal Vivant"
        case .arcEnCiel: return "Arc-en-ciel"
        }
    }
    
    var emoji: String {
        switch self {
        case .blob: return "🫧"; case .chat: return "🐱"; case .lapin: return "🐰"
        case .chien: return "🐶"; case .fantome: return "👻"; case .panda: return "🐼"
        case .dragon: return "🐲"; case .ours: return "🐻"; case .renard: return "🦊"
        case .chouette: return "🦉"; case .pingouin: return "🐧"; case .koala: return "🐨"
        case .lion: return "🦁"; case .licorne: return "🦄"; case .alien: return "👽"
        case .dino: return "🦕"; case .diable: return "😈"; case .phenix: return "🔥"
        case .cosmique: return "✨"; case .slime: return "🟢"
        case .clown: return "🤡"; case .crane: return "💀"; case .robot: return "🤖"
        case .loupGarou: return "🐺"; case .sirene: return "🧜"; case .phenixDore: return "⭐"
        case .demonAncien: return "👿"; case .bebeDragon: return "🐣"; case .cristalVivant: return "💎"
        case .arcEnCiel: return "🌈"
        }
    }
    
    var anchors: AnchorOffsets {
        switch self {
        case .lapin:    return AnchorOffsets(hatY: -15)
        case .lion:     return AnchorOffsets(clothesScale: 1.15)
        case .fantome:  return AnchorOffsets(clothesY: -5)
        case .pingouin: return AnchorOffsets(clothesScale: 0.9)
        case .dragon:   return AnchorOffsets(hatY: -10, clothesScale: 1.1)
        case .ours:     return AnchorOffsets(hatY: -5, clothesScale: 1.1)
        case .dino:     return AnchorOffsets(hatY: -8, clothesScale: 1.15)
        case .alien:    return AnchorOffsets(eyeY: -5, hatY: -12)
        case .licorne:  return AnchorOffsets(hatY: -20)
        case .slime:    return AnchorOffsets(eyeY: 5, clothesY: 5, clothesScale: 0.95)
        case .cosmique: return AnchorOffsets(hatY: -10)
        case .panda:    return AnchorOffsets(hatY: -5, clothesScale: 1.05)
        case .diable:   return AnchorOffsets(hatY: -15)
        case .bebeDragon: return AnchorOffsets(clothesScale: 0.85)
        case .cristalVivant: return AnchorOffsets(hatY: -10, clothesScale: 0.9)
        default: return AnchorOffsets()
        }
    }
    
    var unlockLevel: Int? {
        switch self {
        case .clown: return 15; case .crane: return 20; case .robot: return 25
        case .loupGarou: return 30; case .sirene: return 32; case .phenixDore: return 35
        case .demonAncien: return 38; case .bebeDragon: return 40
        case .cristalVivant: return 45; case .arcEnCiel: return 50
        default: return nil
        }
    }
    
    var isSecret: Bool { unlockLevel != nil }
    static var allBasic: [BodyType] { allCases.filter { !$0.isSecret } }
    static var allSecret: [BodyType] { allCases.filter { $0.isSecret } }
}

// MARK: — Couleurs du Buddy

enum BuddyColor: String, Codable, CaseIterable, Identifiable {
    case violet, roseBonbon, bleuCiel, menthe, jauneSoleil, orange, corail
    case vertEmeraude, bleuMarine, blancCasse, noirCharbon, grisArdoise
    case lavande, turquoise, peche, bordeaux, vertOlive, bleuGlacier
    case roseSaumon, beigeSable, mauve, cyan, vertForet, brunChocolat
    case indigo, fuchsia, vertLime, bleuCobalt, rosePoudre, ocre
    // Premium
    case arcEnCielAnime, holographique, doreBrillant, argente, galaxie
    case cristal, lave, glace, neon, camouflage
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .violet:       return Color(hex: 0x7C3AED)
        case .roseBonbon:   return Color(hex: 0xFF69B4)
        case .bleuCiel:     return Color(hex: 0x87CEEB)
        case .menthe:       return Color(hex: 0x98FB98)
        case .jauneSoleil:  return Color(hex: 0xFFD700)
        case .orange:       return Color(hex: 0xFF9F43)
        case .corail:       return Color(hex: 0xFF6B6B)
        case .vertEmeraude: return Color(hex: 0x50C878)
        case .bleuMarine:   return Color(hex: 0x003366)
        case .blancCasse:   return Color(hex: 0xFAF0E6)
        case .noirCharbon:  return Color(hex: 0x2C2C2C)
        case .grisArdoise:  return Color(hex: 0x708090)
        case .lavande:      return Color(hex: 0xE6E6FA)
        case .turquoise:    return Color(hex: 0x40E0D0)
        case .peche:        return Color(hex: 0xFFDAB9)
        case .bordeaux:     return Color(hex: 0x800020)
        case .vertOlive:    return Color(hex: 0x808000)
        case .bleuGlacier:  return Color(hex: 0xA5F2F3)
        case .roseSaumon:   return Color(hex: 0xFA8072)
        case .beigeSable:   return Color(hex: 0xF5DEB3)
        case .mauve:        return Color(hex: 0xE0B0FF)
        case .cyan:         return Color(hex: 0x00FFFF)
        case .vertForet:    return Color(hex: 0x228B22)
        case .brunChocolat: return Color(hex: 0x7B3F00)
        case .indigo:       return Color(hex: 0x4B0082)
        case .fuchsia:      return Color(hex: 0xFF00FF)
        case .vertLime:     return Color(hex: 0x32CD32)
        case .bleuCobalt:   return Color(hex: 0x0047AB)
        case .rosePoudre:   return Color(hex: 0xFFB6C1)
        case .ocre:         return Color(hex: 0xCC7722)
        // Premium — couleur de base (les animations sont gérées dans le renderer)
        case .arcEnCielAnime: return Color(hex: 0xFF69B4)
        case .holographique:  return Color(hex: 0xC0C0C0)
        case .doreBrillant:   return Color(hex: 0xFFD700)
        case .argente:        return Color(hex: 0xC0C0C0)
        case .galaxie:        return Color(hex: 0x191970)
        case .cristal:        return Color(hex: 0xB0E0E6)
        case .lave:           return Color(hex: 0xFF4500)
        case .glace:          return Color(hex: 0xADD8E6)
        case .neon:           return Color(hex: 0x39FF14)
        case .camouflage:     return Color(hex: 0x78866B)
        }
    }
    
    var displayName: String {
        switch self {
        case .violet: return "Violet"; case .roseBonbon: return "Rose bonbon"
        case .bleuCiel: return "Bleu ciel"; case .menthe: return "Menthe"
        case .jauneSoleil: return "Jaune soleil"; case .orange: return "Orange"
        case .corail: return "Corail"; case .vertEmeraude: return "Vert émeraude"
        case .bleuMarine: return "Bleu marine"; case .blancCasse: return "Blanc cassé"
        case .noirCharbon: return "Noir charbon"; case .grisArdoise: return "Gris ardoise"
        case .lavande: return "Lavande"; case .turquoise: return "Turquoise"
        case .peche: return "Pêche"; case .bordeaux: return "Bordeaux"
        case .vertOlive: return "Vert olive"; case .bleuGlacier: return "Bleu glacier"
        case .roseSaumon: return "Rose saumon"; case .beigeSable: return "Beige sable"
        case .mauve: return "Mauve"; case .cyan: return "Cyan"
        case .vertForet: return "Vert forêt"; case .brunChocolat: return "Brun chocolat"
        case .indigo: return "Indigo"; case .fuchsia: return "Fuchsia"
        case .vertLime: return "Vert lime"; case .bleuCobalt: return "Bleu cobalt"
        case .rosePoudre: return "Rose poudré"; case .ocre: return "Ocre"
        case .arcEnCielAnime: return "Arc-en-ciel ✨"; case .holographique: return "Holographique ✨"
        case .doreBrillant: return "Doré ✨"; case .argente: return "Argenté ✨"
        case .galaxie: return "Galaxie ✨"; case .cristal: return "Cristal ✨"
        case .lave: return "Lave ✨"; case .glace: return "Glace ✨"
        case .neon: return "Néon ✨"; case .camouflage: return "Camouflage ✨"
        }
    }
    
    var isPremium: Bool {
        [.arcEnCielAnime, .holographique, .doreBrillant, .argente, .galaxie,
         .cristal, .lave, .glace, .neon, .camouflage].contains(self)
    }
    
    static var allBasic: [BuddyColor] { allCases.filter { !$0.isPremium } }
    static var allPremium: [BuddyColor] { allCases.filter { $0.isPremium } }
}

// MARK: — Types d'yeux

enum EyeType: String, Codable, CaseIterable, Identifiable {
    case normal, amande, endormi, coeur, etoile, croix, spirale, trait
    case pixel, cyclope, heterochromie, colere, pleurant, amoureux, lunettes
    // Premium
    case galaxieEyes, laser, tvEcran, arcEnCielEyes, hypnotique
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .normal: return "Normal"; case .amande: return "Amande"
        case .endormi: return "Endormi"; case .coeur: return "Cœur"
        case .etoile: return "Étoilé"; case .croix: return "Croix"
        case .spirale: return "Spirale"; case .trait: return "Trait"
        case .pixel: return "Pixel 8bit"; case .cyclope: return "Cyclope"
        case .heterochromie: return "Hétérochromie"; case .colere: return "Colère"
        case .pleurant: return "Pleurant"; case .amoureux: return "Amoureux"
        case .lunettes: return "Lunettes"; case .galaxieEyes: return "Galaxie ✨"
        case .laser: return "Laser ✨"; case .tvEcran: return "TV ✨"
        case .arcEnCielEyes: return "Arc-en-ciel ✨"; case .hypnotique: return "Hypnotique ✨"
        }
    }
    
    var isPremium: Bool {
        [.galaxieEyes, .laser, .tvEcran, .arcEnCielEyes, .hypnotique].contains(self)
    }
    
    static var allBasic: [EyeType] { allCases.filter { !$0.isPremium } }
}

// MARK: — Accessoires, Vêtements, Costumes

struct CatalogItem: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let emoji: String
    let category: ItemCategory
    let gender: Gender?        // nil = unisex
    let isPremium: Bool
    let price: Int             // en gemmes
    let requiredLevel: Int
    
    var isUnisex: Bool { gender == nil }
}

enum ItemCategory: String, Codable, CaseIterable {
    case headAccessory = "Tête"
    case top = "Haut"
    case bottom = "Bas"
    case costume = "Costume"
    case decor = "Déco"
    case roomTheme = "Thème"
    case food = "Nourriture"
    case special = "Spécial"
}

// MARK: — Catalogue complet

struct ItemCatalog {
    // ── Accessoires de tête ──
    static let boyHeadAccessories: [CatalogItem] = [
        CatalogItem(id: "hat_tophat", name: "Chapeau haut-de-forme", emoji: "🎩", category: .headAccessory, gender: .boy, isPremium: false, price: 0, requiredLevel: 1),
        CatalogItem(id: "hat_cap", name: "Casquette", emoji: "🧢", category: .headAccessory, gender: .boy, isPremium: false, price: 0, requiredLevel: 1),
        CatalogItem(id: "hat_crown", name: "Couronne basique", emoji: "👑", category: .headAccessory, gender: .boy, isPremium: false, price: 0, requiredLevel: 1),
        CatalogItem(id: "acc_glasses_round", name: "Lunettes rondes", emoji: "👓", category: .headAccessory, gender: .boy, isPremium: false, price: 0, requiredLevel: 1),
        CatalogItem(id: "acc_sunglasses", name: "Lunettes soleil", emoji: "🕶️", category: .headAccessory, gender: .boy, isPremium: false, price: 0, requiredLevel: 1),
        CatalogItem(id: "acc_bowtie", name: "Nœud pap'", emoji: "🎀", category: .headAccessory, gender: .boy, isPremium: false, price: 0, requiredLevel: 2),
        CatalogItem(id: "acc_tie", name: "Cravate", emoji: "👔", category: .headAccessory, gender: .boy, isPremium: false, price: 0, requiredLevel: 2),
        CatalogItem(id: "acc_scarf", name: "Écharpe", emoji: "🧣", category: .headAccessory, gender: .boy, isPremium: false, price: 0, requiredLevel: 2),
        CatalogItem(id: "acc_antennae", name: "Antennes", emoji: "📡", category: .headAccessory, gender: .boy, isPremium: false, price: 0, requiredLevel: 3),
        CatalogItem(id: "acc_catears", name: "Oreilles chat", emoji: "🐱", category: .headAccessory, gender: .boy, isPremium: false, price: 0, requiredLevel: 3),
        CatalogItem(id: "acc_bunnyears", name: "Oreilles lapin", emoji: "🐰", category: .headAccessory, gender: .boy, isPremium: false, price: 0, requiredLevel: 3),
        CatalogItem(id: "acc_bandana", name: "Bandana", emoji: "🏴‍☠️", category: .headAccessory, gender: .boy, isPremium: false, price: 0, requiredLevel: 4),
        CatalogItem(id: "acc_headphones", name: "Casque musique", emoji: "🎧", category: .headAccessory, gender: .boy, isPremium: false, price: 0, requiredLevel: 4),
        CatalogItem(id: "acc_cape", name: "Cape basique", emoji: "🦸", category: .headAccessory, gender: .boy, isPremium: false, price: 0, requiredLevel: 5),
        CatalogItem(id: "acc_backpack", name: "Sac à dos mini", emoji: "🎒", category: .headAccessory, gender: .boy, isPremium: false, price: 0, requiredLevel: 5),
        CatalogItem(id: "acc_butterfly", name: "Ailes papillon", emoji: "🦋", category: .headAccessory, gender: .boy, isPremium: false, price: 0, requiredLevel: 6),
        CatalogItem(id: "acc_unicornhorn", name: "Corne licorne", emoji: "🦄", category: .headAccessory, gender: .boy, isPremium: false, price: 0, requiredLevel: 6),
        CatalogItem(id: "acc_halo", name: "Halo", emoji: "😇", category: .headAccessory, gender: .boy, isPremium: false, price: 0, requiredLevel: 7),
        CatalogItem(id: "acc_devilhorns", name: "Cornes diable", emoji: "😈", category: .headAccessory, gender: .boy, isPremium: false, price: 0, requiredLevel: 7),
        CatalogItem(id: "acc_sword", name: "Épée", emoji: "⚔️", category: .headAccessory, gender: .boy, isPremium: false, price: 0, requiredLevel: 8),
        CatalogItem(id: "acc_shield", name: "Bouclier", emoji: "🛡️", category: .headAccessory, gender: .boy, isPremium: false, price: 0, requiredLevel: 8),
        CatalogItem(id: "acc_scepter", name: "Sceptre", emoji: "🪄", category: .headAccessory, gender: .boy, isPremium: false, price: 0, requiredLevel: 9),
        CatalogItem(id: "acc_flower", name: "Fleur", emoji: "🌸", category: .headAccessory, gender: .boy, isPremium: false, price: 0, requiredLevel: 9),
        CatalogItem(id: "acc_tiara_b", name: "Diadème", emoji: "💍", category: .headAccessory, gender: .boy, isPremium: false, price: 0, requiredLevel: 10),
        CatalogItem(id: "acc_umbrella", name: "Parapluie", emoji: "☂️", category: .headAccessory, gender: .boy, isPremium: false, price: 0, requiredLevel: 10),
    ]
    
    static let girlHeadAccessories: [CatalogItem] = [
        CatalogItem(id: "gacc_bow", name: "Nœud", emoji: "🎀", category: .headAccessory, gender: .girl, isPremium: false, price: 0, requiredLevel: 1),
        CatalogItem(id: "gacc_flower", name: "Fleur", emoji: "🌺", category: .headAccessory, gender: .girl, isPremium: false, price: 0, requiredLevel: 1),
        CatalogItem(id: "gacc_tiara", name: "Diadème", emoji: "👸", category: .headAccessory, gender: .girl, isPremium: false, price: 0, requiredLevel: 1),
        CatalogItem(id: "gacc_crown", name: "Couronne", emoji: "👑", category: .headAccessory, gender: .girl, isPremium: false, price: 0, requiredLevel: 1),
        CatalogItem(id: "gacc_glasses", name: "Lunettes", emoji: "👓", category: .headAccessory, gender: .girl, isPremium: false, price: 0, requiredLevel: 2),
        CatalogItem(id: "gacc_headphones", name: "Casque musique", emoji: "🎧", category: .headAccessory, gender: .girl, isPremium: false, price: 0, requiredLevel: 2),
        CatalogItem(id: "gacc_unicornhorn", name: "Corne licorne", emoji: "🦄", category: .headAccessory, gender: .girl, isPremium: false, price: 0, requiredLevel: 2),
        CatalogItem(id: "gacc_fairywings", name: "Ailes fée", emoji: "🧚", category: .headAccessory, gender: .girl, isPremium: false, price: 0, requiredLevel: 3),
        CatalogItem(id: "gacc_halo", name: "Halo", emoji: "😇", category: .headAccessory, gender: .girl, isPremium: false, price: 0, requiredLevel: 3),
        CatalogItem(id: "gacc_stars", name: "Étoiles", emoji: "⭐", category: .headAccessory, gender: .girl, isPremium: false, price: 0, requiredLevel: 3),
        CatalogItem(id: "gacc_witchhat", name: "Chapeau sorcière", emoji: "🧙‍♀️", category: .headAccessory, gender: .girl, isPremium: false, price: 0, requiredLevel: 4),
        CatalogItem(id: "gacc_catears", name: "Oreilles chat", emoji: "🐱", category: .headAccessory, gender: .girl, isPremium: false, price: 0, requiredLevel: 4),
        CatalogItem(id: "gacc_bunnyears", name: "Oreilles lapin", emoji: "🐰", category: .headAccessory, gender: .girl, isPremium: false, price: 0, requiredLevel: 4),
        CatalogItem(id: "gacc_antennae", name: "Antennes", emoji: "📡", category: .headAccessory, gender: .girl, isPremium: false, price: 0, requiredLevel: 5),
        CatalogItem(id: "gacc_veil", name: "Voile", emoji: "💒", category: .headAccessory, gender: .girl, isPremium: false, price: 0, requiredLevel: 5),
        CatalogItem(id: "gacc_tiaraGem", name: "Tiare", emoji: "💎", category: .headAccessory, gender: .girl, isPremium: false, price: 0, requiredLevel: 5),
        CatalogItem(id: "gacc_headband", name: "Headband", emoji: "🎽", category: .headAccessory, gender: .girl, isPremium: false, price: 0, requiredLevel: 6),
        CatalogItem(id: "gacc_feather", name: "Plume", emoji: "🪶", category: .headAccessory, gender: .girl, isPremium: false, price: 0, requiredLevel: 6),
        CatalogItem(id: "gacc_cowgirlhat", name: "Chapeau cowgirl", emoji: "🤠", category: .headAccessory, gender: .girl, isPremium: false, price: 0, requiredLevel: 7),
        CatalogItem(id: "gacc_flowercrown", name: "Couronne fleurs", emoji: "🌼", category: .headAccessory, gender: .girl, isPremium: false, price: 0, requiredLevel: 7),
        CatalogItem(id: "gacc_cape", name: "Cape", emoji: "🦸‍♀️", category: .headAccessory, gender: .girl, isPremium: false, price: 0, requiredLevel: 8),
        CatalogItem(id: "gacc_wand", name: "Baguette magique", emoji: "🪄", category: .headAccessory, gender: .girl, isPremium: false, price: 0, requiredLevel: 8),
        CatalogItem(id: "gacc_fan", name: "Éventail", emoji: "🪭", category: .headAccessory, gender: .girl, isPremium: false, price: 0, requiredLevel: 9),
        CatalogItem(id: "gacc_beachhat", name: "Chapeau plage", emoji: "👒", category: .headAccessory, gender: .girl, isPremium: false, price: 0, requiredLevel: 9),
        CatalogItem(id: "gacc_sportband", name: "Bandeau sport", emoji: "💪", category: .headAccessory, gender: .girl, isPremium: false, price: 0, requiredLevel: 10),
    ]
    
    static let premiumHeadAccessories: [CatalogItem] = [
        CatalogItem(id: "pacc_spiderman", name: "½ Masque Spiderman", emoji: "🕷️", category: .headAccessory, gender: nil, isPremium: true, price: 80, requiredLevel: 5),
        CatalogItem(id: "pacc_viking", name: "Casque Viking", emoji: "⚔️", category: .headAccessory, gender: nil, isPremium: true, price: 60, requiredLevel: 8),
        CatalogItem(id: "pacc_pharaoh", name: "Couronne pharaon", emoji: "🏺", category: .headAccessory, gender: nil, isPremium: true, price: 100, requiredLevel: 10),
        CatalogItem(id: "pacc_xmas", name: "Chapeau Noël", emoji: "🎅", category: .headAccessory, gender: nil, isPremium: true, price: 30, requiredLevel: 1),
        CatalogItem(id: "pacc_ramadan", name: "Lanterne Ramadan", emoji: "🏮", category: .headAccessory, gender: nil, isPremium: true, price: 30, requiredLevel: 1),
        CatalogItem(id: "pacc_halloween", name: "Citrouille Halloween", emoji: "🎃", category: .headAccessory, gender: nil, isPremium: true, price: 30, requiredLevel: 1),
        CatalogItem(id: "pacc_spring", name: "Couronne fleurs printemps", emoji: "🌸", category: .headAccessory, gender: nil, isPremium: true, price: 40, requiredLevel: 3),
        CatalogItem(id: "pacc_astronaut", name: "Casque astronaute", emoji: "🧑‍🚀", category: .headAccessory, gender: nil, isPremium: true, price: 100, requiredLevel: 12),
        CatalogItem(id: "pacc_ninja", name: "Bandeau ninja", emoji: "🥷", category: .headAccessory, gender: nil, isPremium: true, price: 50, requiredLevel: 8),
        CatalogItem(id: "pacc_gaming", name: "Lunettes gaming", emoji: "🎮", category: .headAccessory, gender: nil, isPremium: true, price: 60, requiredLevel: 5),
    ]
    
    // ── Vêtements Haut ──
    static let boyTops: [CatalogItem] = [
        CatalogItem(id: "btop_white", name: "T-shirt blanc", emoji: "👕", category: .top, gender: .boy, isPremium: false, price: 0, requiredLevel: 1),
        CatalogItem(id: "btop_black", name: "T-shirt noir", emoji: "🖤", category: .top, gender: .boy, isPremium: false, price: 0, requiredLevel: 1),
        CatalogItem(id: "btop_hoodie", name: "Hoodie gris", emoji: "🧥", category: .top, gender: .boy, isPremium: false, price: 0, requiredLevel: 2),
        CatalogItem(id: "btop_turtleneck", name: "Pull col roulé", emoji: "🧶", category: .top, gender: .boy, isPremium: false, price: 0, requiredLevel: 3),
        CatalogItem(id: "btop_plaid", name: "Chemise carreaux", emoji: "👔", category: .top, gender: .boy, isPremium: false, price: 0, requiredLevel: 3),
        CatalogItem(id: "btop_tank", name: "Débardeur", emoji: "🎽", category: .top, gender: .boy, isPremium: false, price: 0, requiredLevel: 4),
        CatalogItem(id: "btop_denim", name: "Veste jean", emoji: "🧥", category: .top, gender: .boy, isPremium: false, price: 0, requiredLevel: 4),
        CatalogItem(id: "btop_kimono", name: "Kimono simple", emoji: "👘", category: .top, gender: .boy, isPremium: false, price: 0, requiredLevel: 5),
        CatalogItem(id: "btop_football", name: "Maillot foot", emoji: "⚽", category: .top, gender: .boy, isPremium: false, price: 0, requiredLevel: 5),
        CatalogItem(id: "btop_basket", name: "Jersey basket", emoji: "🏀", category: .top, gender: .boy, isPremium: false, price: 0, requiredLevel: 6),
        CatalogItem(id: "btop_striped", name: "Marinière", emoji: "⛵", category: .top, gender: .boy, isPremium: false, price: 0, requiredLevel: 6),
        CatalogItem(id: "btop_bomber", name: "Veste bomber", emoji: "🧥", category: .top, gender: .boy, isPremium: false, price: 0, requiredLevel: 7),
        CatalogItem(id: "btop_varsity", name: "Sweat universitaire", emoji: "🎓", category: .top, gender: .boy, isPremium: false, price: 0, requiredLevel: 8),
        CatalogItem(id: "btop_polo", name: "Polo", emoji: "👕", category: .top, gender: .boy, isPremium: false, price: 0, requiredLevel: 9),
        CatalogItem(id: "btop_banded", name: "T-shirt à bandes", emoji: "🏳️‍🌈", category: .top, gender: .boy, isPremium: false, price: 0, requiredLevel: 10),
    ]
    
    static let girlTops: [CatalogItem] = [
        CatalogItem(id: "gtop_croptop", name: "Crop top", emoji: "👚", category: .top, gender: .girl, isPremium: false, price: 0, requiredLevel: 1),
        CatalogItem(id: "gtop_blouse", name: "Blouse", emoji: "👚", category: .top, gender: .girl, isPremium: false, price: 0, requiredLevel: 1),
        CatalogItem(id: "gtop_hoodie", name: "Hoodie rose", emoji: "🧥", category: .top, gender: .girl, isPremium: false, price: 0, requiredLevel: 2),
        CatalogItem(id: "gtop_knotted", name: "Chemise nouée", emoji: "👔", category: .top, gender: .girl, isPremium: false, price: 0, requiredLevel: 3),
        CatalogItem(id: "gtop_kimono", name: "Kimono", emoji: "👘", category: .top, gender: .girl, isPremium: false, price: 0, requiredLevel: 3),
        CatalogItem(id: "gtop_kpop", name: "Style K-pop", emoji: "🎤", category: .top, gender: .girl, isPremium: false, price: 0, requiredLevel: 4),
        CatalogItem(id: "gtop_ruffle", name: "Débardeur à volants", emoji: "🎀", category: .top, gender: .girl, isPremium: false, price: 0, requiredLevel: 4),
        CatalogItem(id: "gtop_oversize", name: "Pull oversize", emoji: "🧶", category: .top, gender: .girl, isPremium: false, price: 0, requiredLevel: 5),
        CatalogItem(id: "gtop_striped", name: "Marinière", emoji: "⛵", category: .top, gender: .girl, isPremium: false, price: 0, requiredLevel: 5),
        CatalogItem(id: "gtop_denim", name: "Veste jean", emoji: "🧥", category: .top, gender: .girl, isPremium: false, price: 0, requiredLevel: 6),
        CatalogItem(id: "gtop_cardigan", name: "Cardigan", emoji: "🧶", category: .top, gender: .girl, isPremium: false, price: 0, requiredLevel: 6),
        CatalogItem(id: "gtop_plaid", name: "Chemise carreaux", emoji: "👔", category: .top, gender: .girl, isPremium: false, price: 0, requiredLevel: 7),
        CatalogItem(id: "gtop_sport", name: "Top sport", emoji: "🏃‍♀️", category: .top, gender: .girl, isPremium: false, price: 0, requiredLevel: 8),
        CatalogItem(id: "gtop_tennis", name: "Polo tennis", emoji: "🎾", category: .top, gender: .girl, isPremium: false, price: 0, requiredLevel: 9),
        CatalogItem(id: "gtop_varsity", name: "Sweat universitaire", emoji: "🎓", category: .top, gender: .girl, isPremium: false, price: 0, requiredLevel: 10),
    ]
    
    // ── Vêtements Bas ──
    static let boyBottoms: [CatalogItem] = [
        CatalogItem(id: "bbot_jeanblue", name: "Jean bleu", emoji: "👖", category: .bottom, gender: .boy, isPremium: false, price: 0, requiredLevel: 1),
        CatalogItem(id: "bbot_jeanblack", name: "Jean noir", emoji: "👖", category: .bottom, gender: .boy, isPremium: false, price: 0, requiredLevel: 1),
        CatalogItem(id: "bbot_jogger", name: "Jogging gris", emoji: "🏃", category: .bottom, gender: .boy, isPremium: false, price: 0, requiredLevel: 2),
        CatalogItem(id: "bbot_shortsport", name: "Short sport", emoji: "🩳", category: .bottom, gender: .boy, isPremium: false, price: 0, requiredLevel: 3),
        CatalogItem(id: "bbot_bermuda", name: "Bermuda", emoji: "🩳", category: .bottom, gender: .boy, isPremium: false, price: 0, requiredLevel: 4),
        CatalogItem(id: "bbot_shortjean", name: "Short jean", emoji: "🩳", category: .bottom, gender: .boy, isPremium: false, price: 0, requiredLevel: 5),
        CatalogItem(id: "bbot_cargo", name: "Cargo", emoji: "👖", category: .bottom, gender: .boy, isPremium: false, price: 0, requiredLevel: 6),
        CatalogItem(id: "bbot_legging", name: "Legging sport", emoji: "🏋️", category: .bottom, gender: .boy, isPremium: false, price: 0, requiredLevel: 7),
        CatalogItem(id: "bbot_tracksuit", name: "Survêtement", emoji: "🏅", category: .bottom, gender: .boy, isPremium: false, price: 0, requiredLevel: 8),
        CatalogItem(id: "bbot_baggy", name: "Baggy bleu", emoji: "👖", category: .bottom, gender: .boy, isPremium: false, price: 0, requiredLevel: 9),
    ]
    
    static let girlBottoms: [CatalogItem] = [
        CatalogItem(id: "gbot_skirtpink", name: "Jupe rose", emoji: "👗", category: .bottom, gender: .girl, isPremium: false, price: 0, requiredLevel: 1),
        CatalogItem(id: "gbot_legging", name: "Legging noir", emoji: "🏃‍♀️", category: .bottom, gender: .girl, isPremium: false, price: 0, requiredLevel: 1),
        CatalogItem(id: "gbot_highwaist", name: "Jean taille haute", emoji: "👖", category: .bottom, gender: .girl, isPremium: false, price: 0, requiredLevel: 2),
        CatalogItem(id: "gbot_shortjean", name: "Short jean", emoji: "🩳", category: .bottom, gender: .girl, isPremium: false, price: 0, requiredLevel: 3),
        CatalogItem(id: "gbot_jogger", name: "Jogging", emoji: "🏃‍♀️", category: .bottom, gender: .girl, isPremium: false, price: 0, requiredLevel: 4),
        CatalogItem(id: "gbot_tennis", name: "Jupe tennis", emoji: "🎾", category: .bottom, gender: .girl, isPremium: false, price: 0, requiredLevel: 5),
        CatalogItem(id: "gbot_long", name: "Jupe longue", emoji: "👗", category: .bottom, gender: .girl, isPremium: false, price: 0, requiredLevel: 6),
        CatalogItem(id: "gbot_tutu", name: "Tutu ballet", emoji: "🩰", category: .bottom, gender: .girl, isPremium: false, price: 0, requiredLevel: 7),
        CatalogItem(id: "gbot_cargo", name: "Cargo", emoji: "👖", category: .bottom, gender: .girl, isPremium: false, price: 0, requiredLevel: 8),
        CatalogItem(id: "gbot_shortsport", name: "Short sport", emoji: "🩳", category: .bottom, gender: .girl, isPremium: false, price: 0, requiredLevel: 9),
    ]
    
    // ── Costumes complets ──
    static let boyCostumes: [CatalogItem] = [
        CatalogItem(id: "bcost_astronaut", name: "Astronaute", emoji: "🧑‍🚀", category: .costume, gender: .boy, isPremium: false, price: 0, requiredLevel: 5),
        CatalogItem(id: "bcost_ninja", name: "Ninja noir", emoji: "🥷", category: .costume, gender: .boy, isPremium: false, price: 0, requiredLevel: 5),
        CatalogItem(id: "bcost_knight", name: "Chevalier médiéval", emoji: "⚔️", category: .costume, gender: .boy, isPremium: false, price: 0, requiredLevel: 8),
        CatalogItem(id: "bcost_scientist", name: "Scientifique", emoji: "🔬", category: .costume, gender: .boy, isPremium: false, price: 0, requiredLevel: 8),
        CatalogItem(id: "bcost_pirate", name: "Pirate", emoji: "🏴‍☠️", category: .costume, gender: .boy, isPremium: false, price: 0, requiredLevel: 10),
    ]
    
    static let boyPremiumCostumes: [CatalogItem] = [
        CatalogItem(id: "bcostp_batman", name: "Batman", emoji: "🦇", category: .costume, gender: .boy, isPremium: true, price: 150, requiredLevel: 10),
        CatalogItem(id: "bcostp_slimshady", name: "Slim Shady", emoji: "🎤", category: .costume, gender: .boy, isPremium: true, price: 120, requiredLevel: 8),
        CatalogItem(id: "bcostp_samurai", name: "Samouraï", emoji: "⚔️", category: .costume, gender: .boy, isPremium: true, price: 100, requiredLevel: 12),
        CatalogItem(id: "bcostp_viking", name: "Viking", emoji: "🪓", category: .costume, gender: .boy, isPremium: true, price: 100, requiredLevel: 10),
        CatalogItem(id: "bcostp_pharaoh", name: "Pharaon", emoji: "🏺", category: .costume, gender: .boy, isPremium: true, price: 120, requiredLevel: 15),
        CatalogItem(id: "bcostp_cowboy", name: "Cowboy", emoji: "🤠", category: .costume, gender: .boy, isPremium: true, price: 80, requiredLevel: 8),
        CatalogItem(id: "bcostp_vampire", name: "Vampire élégant", emoji: "🧛", category: .costume, gender: .boy, isPremium: true, price: 100, requiredLevel: 12),
        CatalogItem(id: "bcostp_psgplayer", name: "Footballeur PSG", emoji: "⚽", category: .costume, gender: .boy, isPremium: true, price: 80, requiredLevel: 5),
        CatalogItem(id: "bcostp_nbaplayer", name: "Basketteur NBA", emoji: "🏀", category: .costume, gender: .boy, isPremium: true, price: 80, requiredLevel: 5),
        CatalogItem(id: "bcostp_boxer", name: "Boxeur", emoji: "🥊", category: .costume, gender: .boy, isPremium: true, price: 60, requiredLevel: 8),
        CatalogItem(id: "bcostp_superhero", name: "Superhéros Buddy", emoji: "🦸", category: .costume, gender: .boy, isPremium: true, price: 200, requiredLevel: 20),
        CatalogItem(id: "bcostp_gamer", name: "Gamer pro", emoji: "🎮", category: .costume, gender: .boy, isPremium: true, price: 80, requiredLevel: 5),
        CatalogItem(id: "bcostp_ramadan", name: "Tenue Ramadan", emoji: "🌙", category: .costume, gender: .boy, isPremium: true, price: 50, requiredLevel: 1),
        CatalogItem(id: "bcostp_african", name: "Tenue africaine festive", emoji: "🌍", category: .costume, gender: .boy, isPremium: true, price: 80, requiredLevel: 5),
        CatalogItem(id: "bcostp_rapper", name: "Rappeur US", emoji: "🎤", category: .costume, gender: .boy, isPremium: true, price: 100, requiredLevel: 10),
        CatalogItem(id: "bcostp_goldknight", name: "Chevalier doré", emoji: "🏅", category: .costume, gender: .boy, isPremium: true, price: 200, requiredLevel: 25),
    ]
    
    static let girlCostumes: [CatalogItem] = [
        CatalogItem(id: "gcost_fairy", name: "Fée", emoji: "🧚", category: .costume, gender: .girl, isPremium: false, price: 0, requiredLevel: 5),
        CatalogItem(id: "gcost_witch", name: "Sorcière", emoji: "🧙‍♀️", category: .costume, gender: .girl, isPremium: false, price: 0, requiredLevel: 5),
        CatalogItem(id: "gcost_astronaut", name: "Astronaute", emoji: "🧑‍🚀", category: .costume, gender: .girl, isPremium: false, price: 0, requiredLevel: 8),
        CatalogItem(id: "gcost_ninja", name: "Ninja féminin", emoji: "🥷", category: .costume, gender: .girl, isPremium: false, price: 0, requiredLevel: 8),
        CatalogItem(id: "gcost_princess", name: "Princesse basique", emoji: "👸", category: .costume, gender: .girl, isPremium: false, price: 0, requiredLevel: 10),
    ]
    
    static let girlPremiumCostumes: [CatalogItem] = [
        CatalogItem(id: "gcostp_cleopatra", name: "Cléopâtre", emoji: "👸", category: .costume, gender: .girl, isPremium: true, price: 120, requiredLevel: 10),
        CatalogItem(id: "gcostp_kpopidol", name: "K-pop idol", emoji: "🎤", category: .costume, gender: .girl, isPremium: true, price: 100, requiredLevel: 8),
        CatalogItem(id: "gcostp_ballgown", name: "Robe de bal", emoji: "👗", category: .costume, gender: .girl, isPremium: true, price: 150, requiredLevel: 15),
        CatalogItem(id: "gcostp_cheerleader", name: "Cheerleader", emoji: "📣", category: .costume, gender: .girl, isPremium: true, price: 60, requiredLevel: 5),
        CatalogItem(id: "gcostp_bollywood", name: "Bollywood", emoji: "💃", category: .costume, gender: .girl, isPremium: true, price: 100, requiredLevel: 10),
        CatalogItem(id: "gcostp_kimonogala", name: "Kimono de gala", emoji: "👘", category: .costume, gender: .girl, isPremium: true, price: 120, requiredLevel: 12),
        CatalogItem(id: "gcostp_vampire", name: "Vampire féminin", emoji: "🧛‍♀️", category: .costume, gender: .girl, isPremium: true, price: 100, requiredLevel: 12),
        CatalogItem(id: "gcostp_african", name: "Tenue africaine", emoji: "🌍", category: .costume, gender: .girl, isPremium: true, price: 80, requiredLevel: 5),
        CatalogItem(id: "gcostp_ramadan", name: "Tenue Ramadan féminine", emoji: "🌙", category: .costume, gender: .girl, isPremium: true, price: 50, requiredLevel: 1),
        CatalogItem(id: "gcostp_pirate", name: "Pirate féminin", emoji: "🏴‍☠️", category: .costume, gender: .girl, isPremium: true, price: 80, requiredLevel: 8),
        CatalogItem(id: "gcostp_icefairy", name: "Fée des neiges", emoji: "❄️", category: .costume, gender: .girl, isPremium: true, price: 150, requiredLevel: 15),
    ]
    
    // ── Fonctions d'accès au catalogue ──
    
    static func headAccessories(for gender: Gender) -> [CatalogItem] {
        let base = gender == .boy ? boyHeadAccessories : girlHeadAccessories
        return base + premiumHeadAccessories
    }
    
    static func tops(for gender: Gender) -> [CatalogItem] {
        gender == .boy ? boyTops : girlTops
    }
    
    static func bottoms(for gender: Gender) -> [CatalogItem] {
        gender == .boy ? boyBottoms : girlBottoms
    }
    
    static func costumes(for gender: Gender) -> [CatalogItem] {
        let base = gender == .boy ? boyCostumes : girlCostumes
        let premium = gender == .boy ? boyPremiumCostumes : girlPremiumCostumes
        return base + premium
    }
    
    static func allItems(for gender: Gender) -> [CatalogItem] {
        headAccessories(for: gender) + tops(for: gender) + bottoms(for: gender) + costumes(for: gender)
    }
    
    static func item(byID id: String, gender: Gender) -> CatalogItem? {
        allItems(for: gender).first { $0.id == id }
    }
}

// MARK: — Décoration de chambre

enum RoomTheme: String, Codable, CaseIterable, Identifiable {
    case defaultTheme, plage, espace, foret, bonbons, nuit, coucherSoleil, chambreCosy, desert
    // Premium
    case aquarium, chateau, lune, metroFuturiste, jungle, volcan, sousLeau, arcticPalace
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .defaultTheme: return "Classique"; case .plage: return "Plage"
        case .espace: return "Espace"; case .foret: return "Forêt"
        case .bonbons: return "Bonbons"; case .nuit: return "Nuit"
        case .coucherSoleil: return "Coucher de soleil"; case .chambreCosy: return "Chambre cosy"
        case .desert: return "Désert"; case .aquarium: return "Aquarium ✨"
        case .chateau: return "Château ✨"; case .lune: return "Lune ✨"
        case .metroFuturiste: return "Métro futuriste ✨"; case .jungle: return "Jungle ✨"
        case .volcan: return "Volcan ✨"; case .sousLeau: return "Sous l'eau ✨"
        case .arcticPalace: return "Palais arctique ✨"
        }
    }
    
    var emoji: String {
        switch self {
        case .defaultTheme: return "🏠"; case .plage: return "🏖️"; case .espace: return "🚀"
        case .foret: return "🌲"; case .bonbons: return "🍬"; case .nuit: return "🌙"
        case .coucherSoleil: return "🌅"; case .chambreCosy: return "🛋️"; case .desert: return "🏜️"
        case .aquarium: return "🐠"; case .chateau: return "🏰"; case .lune: return "🌕"
        case .metroFuturiste: return "🚇"; case .jungle: return "🌴"; case .volcan: return "🌋"
        case .sousLeau: return "🐙"; case .arcticPalace: return "🧊"
        }
    }
    
    var colors: [Color] {
        switch self {
        case .defaultTheme:  return [Color(hex: 0xE8D5FF), Color(hex: 0xFFE5EC)]
        case .plage:         return [Color(hex: 0x87CEEB), Color(hex: 0xF0E68C), Color(hex: 0xDEB887)]
        case .espace:        return [Color(hex: 0x0F0C29), Color(hex: 0x302B63), Color(hex: 0x24243E)]
        case .foret:         return [Color(hex: 0x90EE90), Color(hex: 0x228B22), Color(hex: 0x8B4513)]
        case .bonbons:       return [Color(hex: 0xFFB6C1), Color(hex: 0xFF69B4), Color(hex: 0xFFE5EC)]
        case .nuit:          return [Color(hex: 0x1A1A2E), Color(hex: 0x16213E), Color(hex: 0x0F3460)]
        case .coucherSoleil: return [Color(hex: 0xFF7E5F), Color(hex: 0xFEB47B), Color(hex: 0xFFCDA5)]
        case .chambreCosy:   return [Color(hex: 0xFFF5E4), Color(hex: 0xFFE4C4), Color(hex: 0xDEB887)]
        case .desert:        return [Color(hex: 0xEDC9AF), Color(hex: 0xC19A6B), Color(hex: 0xA0522D)]
        case .aquarium:      return [Color(hex: 0x006994), Color(hex: 0x40E0D0), Color(hex: 0x00CED1)]
        case .chateau:       return [Color(hex: 0x8B8589), Color(hex: 0xD3D3D3), Color(hex: 0xFFD700)]
        case .lune:          return [Color(hex: 0x0C0E30), Color(hex: 0x1C1E4A), Color(hex: 0xC0C0C0)]
        case .metroFuturiste:return [Color(hex: 0x1A1A2E), Color(hex: 0x00FFFF), Color(hex: 0x7C3AED)]
        case .jungle:        return [Color(hex: 0x006400), Color(hex: 0x228B22), Color(hex: 0x8B4513)]
        case .volcan:        return [Color(hex: 0x8B0000), Color(hex: 0xFF4500), Color(hex: 0xFFD700)]
        case .sousLeau:      return [Color(hex: 0x000080), Color(hex: 0x0047AB), Color(hex: 0x40E0D0)]
        case .arcticPalace:  return [Color(hex: 0xADD8E6), Color(hex: 0xE0FFFF), Color(hex: 0xF0F8FF)]
        }
    }
    
    var isPremium: Bool {
        [.aquarium, .chateau, .lune, .metroFuturiste, .jungle, .volcan, .sousLeau, .arcticPalace].contains(self)
    }
    var price: Int {
        isPremium ? 50 : 0
    }
    
    static var allBasic: [RoomTheme] { allCases.filter { !$0.isPremium } }
}

struct DecorPlacement: Codable, Identifiable {
    var id: String = UUID().uuidString
    var decorID: String
    var emoji: String
    var x: CGFloat
    var y: CGFloat
    var isWall: Bool    // true = mur, false = sol
}

// MARK: — Actions

enum BuddyAction: String, CaseIterable {
    case feed = "Nourrir"
    case pet = "Caresser"
    case sleep = "Dormir"
    case bath = "Bain"
    
    var icon: String {
        switch self {
        case .feed:  return "🍖"
        case .pet:   return "🤗"
        case .sleep: return "💤"
        case .bath:  return "🛁"
        }
    }
    var stat: StatType {
        switch self {
        case .feed:  return .hunger
        case .pet:   return .happiness
        case .sleep: return .energy
        case .bath:  return .hygiene
        }
    }
    var xpReward: Int { 5 }
    var coinReward: Int { 2 }
}

// MARK: — Streaks & Récompenses

struct StreakReward {
    let day: Int
    let gems: Int
    static let milestones: [StreakReward] = [
        StreakReward(day: 1, gems: 1), StreakReward(day: 3, gems: 2),
        StreakReward(day: 7, gems: 5), StreakReward(day: 14, gems: 10),
        StreakReward(day: 30, gems: 20)
    ]
    static func reward(forDay day: Int) -> Int {
        milestones.last(where: { $0.day <= day })?.gems ?? 1
    }
}

// MARK: — Persistance helpers

struct BuddyStore {
    static let appGroupID = "group.com.rezaimia.buddypocket"
    static let shared = UserDefaults(suiteName: appGroupID) ?? .standard
    
    static func save(_ buddy: Buddy) {
        if let data = try? JSONEncoder().encode(buddy) {
            UserDefaults.standard.set(data, forKey: "buddy_data")
            shared.set(data, forKey: "buddy_widget_data")
        }
    }
    
    static func load() -> Buddy {
        guard let data = UserDefaults.standard.data(forKey: "buddy_data"),
              let buddy = try? JSONDecoder().decode(Buddy.self, from: data) else {
            return Buddy()
        }
        return buddy
    }
    
    static var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: "onboarding_done") }
        set { UserDefaults.standard.set(newValue, forKey: "onboarding_done") }
    }
}
