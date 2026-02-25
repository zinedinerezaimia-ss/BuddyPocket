import SwiftUI

// ══════════════════════════════════════════════════════════════════
// SHOP VIEW — Boutique hebdo, Flash Sales, IAP, Events
// ══════════════════════════════════════════════════════════════════

struct ShopView: View {
    @EnvironmentObject var shopVM: ShopViewModel
    @EnvironmentObject var buddyVM: BuddyViewModel
    @State private var selectedSection: ShopSection = .weekly
    @State private var showBattlePass = false
    @State private var showIAP = false
    @State private var purchaseMessage: String?
    
    enum ShopSection: String, CaseIterable {
        case weekly = "Boutique"
        case battlePass = "Battle Pass"
        case gems = "Gemmes"
        case events = "Événements"
        
        var emoji: String {
            switch self {
            case .weekly: return "🛍️"; case .battlePass: return "🏆"
            case .gems: return "💎"; case .events: return "🎉"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Section tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ShopSection.allCases, id: \.rawValue) { section in
                        Button {
                            withAnimation(BP.gentleAnim) { selectedSection = section }
                        } label: {
                            HStack(spacing: 4) {
                                Text(section.emoji)
                                Text(section.rawValue).font(BP.font(12, weight: .semibold))
                            }
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(selectedSection == section ? BP.pink.opacity(0.2) : BP.cardBG)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(selectedSection == section ? BP.pink : .clear, lineWidth: 2))
                        }
                    }
                }.padding(.horizontal, 16).padding(.vertical, 10)
            }
            
            ScrollView(showsIndicators: false) {
                switch selectedSection {
                case .weekly:     weeklyShopView
                case .battlePass: BattlePassView()
                case .gems:       iapView
                case .events:     eventsView
                }
                
                Spacer(minLength: 100)
            }
        }
        .onAppear { shopVM.refreshShopIfNeeded(gender: buddyVM.buddy.gender) }
        .overlay {
            if let msg = purchaseMessage {
                VStack {
                    Text(msg).font(BP.font(14, weight: .semibold)).foregroundStyle(.white)
                        .padding().background(BP.green).clipShape(Capsule())
                        .transition(.move(edge: .top).combined(with: .opacity))
                    Spacer()
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { purchaseMessage = nil }
                    }
                }
            }
        }
    }
    
    // MARK: — Weekly Shop
    
    private var weeklyShopView: some View {
        VStack(spacing: 12) {
            if let shop = shopVM.weeklyShop {
                // Timer
                HStack {
                    Text("🛍️ Boutique de la semaine").font(BP.font(14, weight: .bold))
                    Spacer()
                    Text("Reset lundi").font(BP.captionFont).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                
                // Free item indicator
                if buddyVM.buddy.streakDays >= 5 {
                    HStack {
                        Text("🎁 1 item gratuit grâce à ton streak de \(buddyVM.buddy.streakDays) jours !")
                            .font(BP.font(12, weight: .semibold)).foregroundStyle(BP.green)
                    }
                    .padding(10).background(BP.green.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 16)
                }
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                    ForEach(shop.items) { slot in
                        shopItemCard(slot)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    private func shopItemCard(_ slot: ShopSlot) -> some View {
        let isFree = shopVM.weeklyShop?.freeItemID == slot.item.id && buddyVM.buddy.streakDays >= 5
        
        return VStack(spacing: 8) {
            Text(slot.item.emoji).font(.system(size: 36))
            Text(slot.item.name).font(BP.font(11, weight: .semibold)).lineLimit(2).multilineTextAlignment(.center)
            
            if slot.isPurchased {
                Text("✅ Acheté").font(BP.font(10, weight: .bold)).foregroundStyle(BP.green)
            } else if isFree {
                BPButton("Gratuit 🎁", gradient: LinearGradient(colors: [BP.green, .green], startPoint: .leading, endPoint: .trailing)) {
                    if shopVM.purchaseShopItem(slot: slot, vm: buddyVM) {
                        withAnimation { purchaseMessage = "🎁 \(slot.item.name) obtenu gratuitement !" }
                    }
                }
            } else {
                HStack {
                    if let disc = slot.discount {
                        Text("\(slot.item.price)💎").font(BP.font(10, weight: .medium)).strikethrough().foregroundStyle(.secondary)
                        Text("-\(disc)%").font(BP.font(9, weight: .bold)).foregroundStyle(BP.red)
                    }
                    Text("\(slot.finalPrice)💎").font(BP.font(12, weight: .bold)).foregroundStyle(BP.purple)
                }
                
                BPButton("Acheter", gradient: BP.purpleGradient) {
                    if shopVM.purchaseShopItem(slot: slot, vm: buddyVM) {
                        withAnimation { purchaseMessage = "✨ \(slot.item.name) acheté !" }
                    }
                }
                .opacity(buddyVM.buddy.gems >= slot.finalPrice ? 1 : 0.5)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(BP.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
    
    // MARK: — IAP
    
    private var iapView: some View {
        VStack(spacing: 12) {
            Text("💎 Acheter des Gemmes").font(BP.headFont).foregroundStyle(BP.purple)
                .padding(.top, 8)
            
            ForEach(IAPProduct.allCases, id: \.rawValue) { product in
                BPCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(product.displayName).font(BP.font(16, weight: .bold))
                            if product.isSubscription {
                                Text("200💎/mois + contenu exclusif").font(BP.captionFont).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        BPButton(product.price, gradient: product.isSubscription ? BP.goldGradient : BP.purpleGradient) {
                            Task {
                                if let storeProduct = shopVM.products.first(where: { $0.id == product.rawValue }) {
                                    let success = await shopVM.purchase(storeProduct, vm: buddyVM)
                                    if success {
                                        withAnimation { purchaseMessage = "✨ Achat réussi !" }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // Philosophie
            BPCard {
                VStack(spacing: 6) {
                    Text("🎮 Notre philosophie").font(BP.font(13, weight: .bold))
                    Text("Payer = style, pas puissance ! Les joueurs gratuits peuvent tout débloquer en 2-3 mois.")
                        .font(BP.font(11, weight: .medium)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
            }
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: — Events
    
    private var eventsView: some View {
        VStack(spacing: 12) {
            Text("🎉 Événements").font(BP.headFont).foregroundStyle(BP.purple).padding(.top, 8)
            
            let activeEvents = SeasonalEvent.allEvents.filter(\.isActive)
            if activeEvents.isEmpty {
                VStack(spacing: 12) {
                    Text("📅").font(.system(size: 50))
                    Text("Pas d'événement en cours").font(BP.font(14, weight: .semibold))
                    Text("Reviens bientôt !").font(BP.captionFont).foregroundStyle(.secondary)
                }.padding(.top, 30)
            }
            
            ForEach(SeasonalEvent.allEvents) { event in
                BPCard {
                    HStack {
                        Text(event.emoji).font(.system(size: 30))
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(event.name).font(BP.font(14, weight: .bold))
                                if event.isActive {
                                    BPBadge(text: "EN COURS", color: BP.green)
                                }
                            }
                            if event.isActive {
                                Text("\(event.daysRemaining) jours restants").font(BP.captionFont).foregroundStyle(.secondary)
                            }
                            Text("Jusqu'à \(event.bonusGems)💎 de bonus").font(BP.font(10, weight: .semibold)).foregroundStyle(BP.purple)
                        }
                        Spacer()
                    }
                }
                .opacity(event.isActive ? 1 : 0.5)
            }
        }
        .padding(.horizontal, 16)
    }
}
