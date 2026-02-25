import SwiftUI

// ══════════════════════════════════════════════════════════════════
// BATTLE PASS VIEW — Récompenses saisonnières
// ══════════════════════════════════════════════════════════════════

struct BattlePassView: View {
    @EnvironmentObject var shopVM: ShopViewModel
    @EnvironmentObject var buddyVM: BuddyViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            BPCard {
                VStack(spacing: 8) {
                    HStack {
                        Text("🏆 Saison: \(shopVM.battlePass.name) \(shopVM.battlePass.emoji)")
                            .font(BP.font(16, weight: .bold))
                        Spacer()
                        if shopVM.battlePass.isPremium {
                            BPBadge(text: "PREMIUM", color: BP.purple)
                        }
                    }
                    
                    HStack {
                        Text("Niveau \(shopVM.battlePass.currentLevel)/30")
                            .font(BP.font(13, weight: .semibold))
                        Spacer()
                        Text("\(shopVM.battlePass.daysRemaining) jours restants")
                            .font(BP.captionFont).foregroundStyle(.secondary)
                    }
                    
                    // XP bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(BP.purple.opacity(0.15)).frame(height: 8)
                            Capsule().fill(BP.purpleGradient)
                                .frame(width: max(4, geo.size.width * Double(shopVM.battlePass.xp) / Double(shopVM.battlePass.xpForNextLevel)), height: 8)
                        }
                    }.frame(height: 8)
                    
                    Text("\(shopVM.battlePass.xp)/\(shopVM.battlePass.xpForNextLevel) XP")
                        .font(BP.font(10, weight: .medium)).foregroundStyle(.secondary)
                    
                    if !shopVM.battlePass.isPremium {
                        BPButton("Passer Premium (2,99€)", icon: "⭐", gradient: BP.goldGradient) {
                            shopVM.upgradeBattlePassToPremium()
                        }
                    }
                }
            }
            
            // Rewards track
            ForEach(shopVM.battlePass.rewards) { reward in
                rewardRow(reward)
            }
        }
        .padding(.horizontal, 16)
    }
    
    private func rewardRow(_ reward: BPReward) -> some View {
        let isUnlocked = shopVM.battlePass.currentLevel >= reward.level
        let isPremiumLocked = reward.isPremiumOnly && !shopVM.battlePass.isPremium
        
        return HStack(spacing: 12) {
            // Level indicator
            ZStack {
                Circle()
                    .fill(isUnlocked ? BP.purpleGradient : LinearGradient(colors: [.gray.opacity(0.2)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 36, height: 36)
                Text("\(reward.level)")
                    .font(BP.font(12, weight: .bold))
                    .foregroundStyle(isUnlocked ? .white : .secondary)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(reward.emoji)
                    Text(reward.name).font(BP.font(12, weight: .semibold))
                    if reward.isPremiumOnly {
                        BPBadge(text: "PREMIUM", color: BP.purple.opacity(0.7))
                    }
                }
                if reward.rewardType == .gems || reward.rewardType == .coins {
                    Text("+\(reward.value) \(reward.rewardType == .gems ? "💎" : "🪙")")
                        .font(BP.font(10, weight: .medium)).foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Status
            if isUnlocked && !isPremiumLocked {
                Button {
                    _ = shopVM.claimBattlePassReward(reward, vm: buddyVM)
                    HapticService.purchase()
                } label: {
                    Text("Récupérer")
                        .font(BP.font(10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(BP.green).clipShape(Capsule())
                }
            } else if isPremiumLocked {
                Text("🔒").font(.system(size: 16))
            } else {
                Text("🔒").font(.system(size: 16)).opacity(0.4)
            }
        }
        .padding(10)
        .background(isUnlocked ? BP.cardBG : Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(isUnlocked ? 1 : 0.6)
    }
}
