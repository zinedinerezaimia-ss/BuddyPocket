import SwiftUI

// ══════════════════════════════════════════════════════════════════
// PROFILE VIEW — Profil, Achievements, Dev Mode, Paramètres
// ══════════════════════════════════════════════════════════════════

struct ProfileView: View {
    @EnvironmentObject var buddyVM: BuddyViewModel
    @EnvironmentObject var socialVM: SocialViewModel
    @State private var showDevMode = false
    @State private var devCode = ""
    @State private var devTapCount = 0
    @State private var showAchievements = false
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Buddy card
                    BPCard {
                        VStack(spacing: 12) {
                            BuddyCanvasView(buddy: buddyVM.buddy, size: 80, animated: false)
                            
                            HStack(spacing: 4) {
                                Text(buddyVM.buddy.name).font(BP.font(20, weight: .bold))
                                if buddyVM.buddy.isDevMode {
                                    BPBadge(text: "🛠️ DEV", color: BP.purple)
                                }
                            }
                            
                            HStack(spacing: 16) {
                                statBubble("Nv.\(buddyVM.buddy.level)", "⭐")
                                statBubble("\(buddyVM.buddy.streakDays)j", "🔥")
                                statBubble("\(buddyVM.buddy.coins)", "🪙")
                                statBubble("\(buddyVM.buddy.gems)", "💎")
                            }
                        }
                    }
                    
                    // Code ami
                    BPCard {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Code ami").font(BP.captionFont).foregroundStyle(.secondary)
                                Text(socialVM.myProfile.friendCode).font(BP.font(16, weight: .bold)).foregroundStyle(BP.purple)
                            }
                            Spacer()
                            Button {
                                UIPasteboard.general.string = socialVM.myProfile.friendCode
                                HapticService.tap()
                            } label: {
                                Text("📋 Copier").font(BP.font(12, weight: .semibold))
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(BP.purple.opacity(0.1)).clipShape(Capsule())
                            }
                        }
                    }
                    
                    // Achievements
                    Button { showAchievements = true } label: {
                        BPCard {
                            HStack {
                                Text("🏆").font(.system(size: 22))
                                Text("Achievements").font(BP.font(14, weight: .semibold))
                                Spacer()
                                let unlocked = buddyVM.achievements.filter(\.isUnlocked).count
                                Text("\(unlocked)/\(buddyVM.achievements.count)")
                                    .font(BP.font(12, weight: .bold)).foregroundStyle(BP.purple)
                                Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(.secondary)
                            }
                        }
                    }.buttonStyle(.plain)
                    
                    // High Scores
                    if !buddyVM.highScores.isEmpty {
                        BPCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("🏅 Records").font(BP.font(14, weight: .semibold))
                                ForEach(buddyVM.highScores) { hs in
                                    HStack {
                                        let game = MiniGame(rawValue: hs.gameType)
                                        Text(game?.emoji ?? "🎮")
                                        Text(game?.displayName ?? hs.gameType).font(BP.font(12, weight: .medium))
                                        Spacer()
                                        Text("\(hs.score)").font(BP.font(14, weight: .bold)).foregroundStyle(BP.purple)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Stats résumé
                    BPCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("📊 Statistiques").font(BP.font(14, weight: .semibold))
                            statRow("Parties jouées", "\(buddyVM.gameTracker.sessionsPlayed)")
                            statRow("Battles gagnés", "\(buddyVM.gameTracker.rewardedBattles)")
                            statRow("Streak max", "\(buddyVM.buddy.streakDays) jours")
                            statRow("Items débloqués", "\(totalUnlocked)")
                        }
                    }
                    
                    // Dev mode trigger (bouton discret)
                    Button {
                        devTapCount += 1
                        if devTapCount >= 7 { showDevMode = true; devTapCount = 0 }
                    } label: {
                        Text("Buddy Pocket v1.0.0")
                            .font(BP.font(10, weight: .medium))
                            .foregroundStyle(.secondary.opacity(0.5))
                    }
                    .padding(.top, 10)
                    
                    Spacer(minLength: 100)
                }
                .padding(16)
            }
            .background(BP.bgGradient)
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAchievements) { achievementsSheet }
            .alert("Mode Développeur", isPresented: $showDevMode) {
                TextField("Code secret", text: $devCode)
                Button("Annuler", role: .cancel) {}
                Button("Activer") {
                    if buddyVM.activateDevMode(code: devCode) {
                        HapticService.levelUp()
                    }
                }
            }
        }
    }
    
    private func statBubble(_ value: String, _ icon: String) -> some View {
        VStack(spacing: 2) {
            Text(icon).font(.system(size: 16))
            Text(value).font(BP.font(11, weight: .bold))
        }
        .frame(width: 60)
        .padding(.vertical, 6)
        .background(BP.purple.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(BP.font(12, weight: .medium)).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(BP.font(12, weight: .bold))
        }
    }
    
    private var totalUnlocked: Int {
        buddyVM.buddy.unlockedBodies.count + buddyVM.buddy.unlockedHeadAccessories.count +
        buddyVM.buddy.unlockedTops.count + buddyVM.buddy.unlockedBottoms.count +
        buddyVM.buddy.unlockedCostumes.count
    }
    
    private var achievementsSheet: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(buddyVM.achievements) { ach in
                        HStack(spacing: 12) {
                            Text(ach.emoji).font(.system(size: 28))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(ach.name).font(BP.font(13, weight: .bold))
                                Text(ach.description).font(BP.font(11, weight: .medium)).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if ach.isUnlocked {
                                VStack {
                                    Text("✅")
                                    Text("+\(ach.rewardGems)💎").font(BP.font(9, weight: .bold)).foregroundStyle(BP.purple)
                                }
                            } else {
                                Text("🔒").opacity(0.5)
                            }
                        }
                        .padding(12)
                        .background(ach.isUnlocked ? BP.cardBG : Color.gray.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .opacity(ach.isUnlocked ? 1 : 0.6)
                    }
                }.padding()
            }
            .background(BP.bgGradient)
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.large])
    }
}
