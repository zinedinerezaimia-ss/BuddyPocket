import SwiftUI
import StoreKit

// ══════════════════════════════════════════════════════════════════
// SHOP VIEW MODEL — Boutique, Battle Pass, IAP
// ══════════════════════════════════════════════════════════════════

@MainActor
class ShopViewModel: ObservableObject {
    @Published var weeklyShop: WeeklyShop?
    @Published var battlePass: BattlePass = BattlePass.season1
    @Published var flashSale: FlashSale?
    @Published var recentPurchaseIDs: [String] = []
    @Published var products: [Product] = []
    @Published var isPremium: Bool = false
    
    init() {
        loadShop()
        loadBattlePass()
        Task { await loadProducts() }
        checkPremium()
    }
    
    // MARK: — Boutique hebdomadaire
    
    func refreshShopIfNeeded(gender: Gender) {
        let cal = Calendar.current
        let weekNum = cal.component(.weekOfYear, from: Date())
        let year = cal.component(.year, from: Date())
        let currentWeekID = "\(year)-W\(weekNum)"
        
        if weeklyShop == nil || weeklyShop?.weekID != currentWeekID {
            weeklyShop = WeeklyShop.generate(gender: gender, weekID: currentWeekID, excludeRecent: recentPurchaseIDs)
            saveShop()
        }
    }
    
    func purchaseShopItem(slot: ShopSlot, vm: BuddyViewModel) -> Bool {
        guard !slot.isPurchased else { return false }
        let price = slot.finalPrice
        
        // Item gratuit si streak 5+
        let isFree = weeklyShop?.freeItemID == slot.item.id && vm.buddy.streakDays >= 5
        
        if !isFree {
            guard vm.buddy.gems >= price else { return false }
            vm.buddy.gems -= price
        }
        
        // Ajouter à l'inventaire
        _ = vm.purchaseItem(slot.item)
        
        // Marquer comme acheté
        if let i = weeklyShop?.items.firstIndex(where: { $0.id == slot.id }) {
            weeklyShop?.items[i].isPurchased = true
        }
        
        recentPurchaseIDs.append(slot.item.id)
        // Garder seulement les 3 derniers mois
        if recentPurchaseIDs.count > 50 { recentPurchaseIDs = Array(recentPurchaseIDs.suffix(30)) }
        
        HapticService.purchase()
        saveShop()
        return true
    }
    
    // MARK: — Battle Pass
    
    func addBattlePassXP(_ amount: Int) {
        battlePass.addXP(amount)
        saveBattlePass()
    }
    
    func claimBattlePassReward(_ reward: BPReward, vm: BuddyViewModel) -> Bool {
        guard battlePass.currentLevel >= reward.level else { return false }
        if reward.isPremiumOnly && !battlePass.isPremium { return false }
        
        switch reward.rewardType {
        case .gems:    vm.buddy.gems += reward.value
        case .coins:   vm.buddy.coins += reward.value
        case .item, .costume, .theme, .exclusive:
            // Débloquer l'item correspondant
            vm.buddy.gems += 10  // bonus fixe pour items
        }
        
        HapticService.purchase()
        return true
    }
    
    func upgradeBattlePassToPremium() {
        battlePass.isPremium = true
        saveBattlePass()
    }
    
    // MARK: — IAP (StoreKit 2)
    
    func loadProducts() async {
        do {
            products = try await Product.products(for: IAPProduct.allCases.map(\.rawValue))
        } catch {
            print("Erreur chargement produits: \(error)")
        }
    }
    
    func purchase(_ product: Product, vm: BuddyViewModel) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                
                // Attribuer les gemmes
                if let iap = IAPProduct(rawValue: product.id) {
                    vm.buddy.gems += iap.gems
                    if iap.isSubscription { isPremium = true; savePremium() }
                }
                
                await transaction.finish()
                HapticService.purchase()
                return true
                
            case .userCancelled: return false
            case .pending: return false
            @unknown default: return false
            }
        } catch { return false }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw StoreError.verificationFailed
        case .verified(let safe): return safe
        }
    }
    
    func checkPremium() {
        isPremium = UserDefaults.standard.bool(forKey: "is_premium")
        Task {
            for await result in Transaction.currentEntitlements {
                if case .verified(let tx) = result {
                    if tx.productID == IAPProduct.premium.rawValue { isPremium = true; savePremium() }
                }
            }
        }
    }
    
    private func savePremium() { UserDefaults.standard.set(isPremium, forKey: "is_premium") }
    
    // MARK: — Persistance
    
    private func saveShop() {
        if let data = try? JSONEncoder().encode(weeklyShop) {
            UserDefaults.standard.set(data, forKey: "weekly_shop")
        }
        if let data = try? JSONEncoder().encode(recentPurchaseIDs) {
            UserDefaults.standard.set(data, forKey: "recent_purchases")
        }
    }
    
    private func loadShop() {
        if let data = UserDefaults.standard.data(forKey: "weekly_shop"),
           let s = try? JSONDecoder().decode(WeeklyShop.self, from: data) { weeklyShop = s }
        if let data = UserDefaults.standard.data(forKey: "recent_purchases"),
           let r = try? JSONDecoder().decode([String].self, from: data) { recentPurchaseIDs = r }
    }
    
    private func saveBattlePass() {
        if let data = try? JSONEncoder().encode(battlePass) {
            UserDefaults.standard.set(data, forKey: "battle_pass")
        }
    }
    
    private func loadBattlePass() {
        if let data = UserDefaults.standard.data(forKey: "battle_pass"),
           let bp = try? JSONDecoder().decode(BattlePass.self, from: data) { battlePass = bp }
    }
}

enum StoreError: Error {
    case verificationFailed
}
