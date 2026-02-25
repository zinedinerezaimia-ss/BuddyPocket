import SwiftUI

// ══════════════════════════════════════════════════════════════════
// CUSTOMIZER VIEW — Personnalisation complète du Buddy
// ══════════════════════════════════════════════════════════════════

struct CustomizerView: View {
    @EnvironmentObject var buddyVM: BuddyViewModel
    @State private var selectedCategory: CustCategory = .body
    @State private var showPurchaseAlert = false
    @State private var pendingItem: CatalogItem?
    
    enum CustCategory: String, CaseIterable {
        case body = "Corps"
        case color = "Couleur"
        case eyes = "Yeux"
        case head = "Tête"
        case top = "Haut"
        case bottom = "Bas"
        case costume = "Costume"
        case room = "Chambre"
        
        var emoji: String {
            switch self {
            case .body: return "🐾"; case .color: return "🎨"; case .eyes: return "👀"
            case .head: return "🎩"; case .top: return "👕"; case .bottom: return "👖"
            case .costume: return "🎭"; case .room: return "🏠"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Preview
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(colors: buddyVM.buddy.roomTheme.colors, startPoint: .top, endPoint: .bottom))
                    .frame(height: 200)
                BuddyCanvasView(buddy: buddyVM.buddy, size: 130, animated: true)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            // Categories
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(CustCategory.allCases, id: \.rawValue) { cat in
                        Button {
                            withAnimation(BP.gentleAnim) { selectedCategory = cat }
                            HapticService.selection()
                        } label: {
                            HStack(spacing: 4) {
                                Text(cat.emoji)
                                Text(cat.rawValue).font(BP.font(11, weight: .semibold))
                            }
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(selectedCategory == cat ? BP.pink.opacity(0.2) : BP.cardBG)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(selectedCategory == cat ? BP.pink : .clear, lineWidth: 2))
                        }
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 10)
            }
            
            // Items grid
            ScrollView {
                switch selectedCategory {
                case .body:    bodyGrid
                case .color:   colorGrid
                case .eyes:    eyesGrid
                case .head:    itemGrid(items: ItemCatalog.headAccessories(for: buddyVM.buddy.gender), category: .headAccessory)
                case .top:     itemGrid(items: ItemCatalog.tops(for: buddyVM.buddy.gender), category: .top)
                case .bottom:  itemGrid(items: ItemCatalog.bottoms(for: buddyVM.buddy.gender), category: .bottom)
                case .costume: itemGrid(items: ItemCatalog.costumes(for: buddyVM.buddy.gender), category: .costume)
                case .room:    roomGrid
                }
            }
        }
        .alert("Acheter ?", isPresented: $showPurchaseAlert) {
            Button("Annuler", role: .cancel) {}
            Button("Acheter \(pendingItem?.price ?? 0)💎") {
                if let item = pendingItem { _ = buddyVM.purchaseItem(item) }
            }
        } message: {
            Text("\(pendingItem?.name ?? "") pour \(pendingItem?.price ?? 0) gemmes")
        }
    }
    
    // MARK: — Body Grid
    
    private var bodyGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 70), spacing: 8)], spacing: 8) {
            ForEach(BodyType.allCases) { bodyType in
                let isUnlocked = buddyVM.buddy.unlockedBodies.contains(bodyType.rawValue) || buddyVM.buddy.isDevMode
                let isSelected = buddyVM.buddy.bodyType == bodyType
                
                Button {
                    guard isUnlocked else { return }
                    withAnimation(BP.springAnim) { buddyVM.buddy.bodyType = bodyType }
                    buddyVM.save(); buddyVM.syncWidget(); HapticService.selection()
                } label: {
                    VStack(spacing: 4) {
                        Text(bodyType.emoji).font(.system(size: 28))
                        Text(bodyType.displayName).font(BP.font(9, weight: .medium)).lineLimit(1)
                        if let lvl = bodyType.unlockLevel, !isUnlocked {
                            Text("Nv.\(lvl)").font(BP.font(8, weight: .bold)).foregroundStyle(BP.purple)
                        }
                    }
                    .frame(width: 70, height: 70)
                    .background(isSelected ? BP.pink.opacity(0.2) : isUnlocked ? BP.cardBG : Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? BP.pink : .clear, lineWidth: 2))
                    .opacity(isUnlocked ? 1 : 0.5)
                    .overlay(alignment: .topTrailing) {
                        if !isUnlocked { Text("🔒").font(.system(size: 12)).offset(x: 4, y: -4) }
                    }
                }
            }
        }
        .padding(12)
    }
    
    // MARK: — Color Grid
    
    private var colorGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 8)], spacing: 8) {
            ForEach(BuddyColor.allCases) { color in
                let isUnlocked = buddyVM.buddy.unlockedColors.contains(color.rawValue) || buddyVM.buddy.isDevMode
                let isSelected = buddyVM.buddy.bodyColor == color
                
                Button {
                    guard isUnlocked else { return }
                    withAnimation(BP.springAnim) { buddyVM.buddy.bodyColor = color }
                    buddyVM.save(); buddyVM.syncWidget(); HapticService.selection()
                } label: {
                    Circle().fill(color.color).frame(width: 40, height: 40)
                        .overlay(Circle().stroke(.white, lineWidth: isSelected ? 3 : 0))
                        .shadow(color: isSelected ? color.color.opacity(0.5) : .clear, radius: 6)
                        .opacity(isUnlocked ? 1 : 0.4)
                        .overlay { if !isUnlocked { Text("🔒").font(.system(size: 10)) } }
                }
            }
        }
        .padding(12)
    }
    
    // MARK: — Eyes Grid
    
    private var eyesGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], spacing: 8) {
            ForEach(EyeType.allCases) { eye in
                let isUnlocked = buddyVM.buddy.unlockedEyes.contains(eye.rawValue) || buddyVM.buddy.isDevMode
                let isSelected = buddyVM.buddy.eyeType == eye
                
                Button {
                    guard isUnlocked else { return }
                    withAnimation(BP.springAnim) { buddyVM.buddy.eyeType = eye }
                    buddyVM.save(); buddyVM.syncWidget(); HapticService.selection()
                } label: {
                    Text(eye.displayName)
                        .font(BP.font(11, weight: .medium))
                        .padding(.horizontal, 12).padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(isSelected ? BP.pink.opacity(0.2) : isUnlocked ? BP.cardBG : Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? BP.pink : .clear, lineWidth: 2))
                        .opacity(isUnlocked ? 1 : 0.5)
                }
            }
        }
        .padding(12)
    }
    
    // MARK: — Item Grid (generic)
    
    private func itemGrid(items: [CatalogItem], category: ItemCategory) -> some View {
        VStack(spacing: 8) {
            // Unequip button
            Button {
                buddyVM.unequipItem(category); HapticService.selection()
            } label: {
                HStack {
                    Text("❌"); Text("Retirer").font(BP.font(12, weight: .medium))
                }
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(BP.cardBG).clipShape(Capsule())
            }
            .padding(.top, 8)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], spacing: 8) {
                ForEach(items) { item in
                    let unlocked = buddyVM.isUnlocked(item)
                    let equipped = isEquipped(item, category: category)
                    
                    Button {
                        if unlocked {
                            buddyVM.equipItem(item.id, category: category)
                            HapticService.selection()
                        } else if item.isPremium {
                            pendingItem = item; showPurchaseAlert = true
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text(item.emoji).font(.system(size: 26))
                            Text(item.name).font(BP.font(9, weight: .medium)).lineLimit(2).multilineTextAlignment(.center)
                            if !unlocked && item.isPremium {
                                Text("\(item.price)💎").font(BP.font(8, weight: .bold)).foregroundStyle(BP.purple)
                            }
                            if !unlocked && item.requiredLevel > buddyVM.buddy.level {
                                Text("Nv.\(item.requiredLevel)").font(BP.font(8, weight: .bold)).foregroundStyle(.secondary)
                            }
                        }
                        .frame(width: 80, height: 80)
                        .background(equipped ? BP.pink.opacity(0.2) : unlocked ? BP.cardBG : Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(equipped ? BP.pink : .clear, lineWidth: 2))
                        .opacity(unlocked ? 1 : 0.5)
                    }
                }
            }
            .padding(.horizontal, 12)
        }
    }
    
    private func isEquipped(_ item: CatalogItem, category: ItemCategory) -> Bool {
        switch category {
        case .headAccessory: return buddyVM.buddy.headAccessory == item.id
        case .top: return buddyVM.buddy.topClothing == item.id
        case .bottom: return buddyVM.buddy.bottomClothing == item.id
        case .costume: return buddyVM.buddy.costume == item.id
        default: return false
        }
    }
    
    // MARK: — Room Grid
    
    private var roomGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) {
            ForEach(RoomTheme.allCases) { theme in
                let isUnlocked = buddyVM.buddy.unlockedRoomThemes.contains(theme.rawValue) || buddyVM.buddy.isDevMode
                let isSelected = buddyVM.buddy.roomTheme == theme
                
                Button {
                    if isUnlocked {
                        withAnimation(BP.springAnim) { buddyVM.buddy.roomTheme = theme }
                        buddyVM.save(); HapticService.selection()
                    } else if theme.isPremium {
                        let fakeItem = CatalogItem(id: theme.rawValue, name: theme.displayName, emoji: theme.emoji, category: .roomTheme, gender: nil, isPremium: true, price: theme.price, requiredLevel: 1)
                        pendingItem = fakeItem; showPurchaseAlert = true
                    }
                } label: {
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(LinearGradient(colors: theme.colors, startPoint: .top, endPoint: .bottom))
                            .frame(height: 60)
                            .overlay(Text(theme.emoji).font(.system(size: 24)))
                        Text(theme.displayName).font(BP.font(10, weight: .semibold)).lineLimit(1)
                        if !isUnlocked { Text("\(theme.price)💎").font(BP.font(8, weight: .bold)).foregroundStyle(BP.purple) }
                    }
                    .padding(6)
                    .background(isSelected ? BP.pink.opacity(0.15) : BP.cardBG)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(isSelected ? BP.pink : .clear, lineWidth: 2))
                    .opacity(isUnlocked ? 1 : 0.5)
                }
            }
        }
        .padding(12)
    }
}
