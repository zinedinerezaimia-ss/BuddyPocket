import SwiftUI

// ══════════════════════════════════════════════════════════════════
// CLAN VIEW — Création, gestion, missions de clan
// ══════════════════════════════════════════════════════════════════

struct ClanView: View {
    @EnvironmentObject var socialVM: SocialViewModel
    @EnvironmentObject var buddyVM: BuddyViewModel
    @State private var showCreateClan = false
    @State private var clanName = ""
    @State private var clanEmoji = "⚔️"
    @State private var clanDescription = ""
    
    private let clanEmojis = ["⚔️", "🏰", "🐉", "🌟", "🔥", "💎", "🦁", "🌙", "⭐", "🎮", "🏆", "🚀"]
    
    var body: some View {
        VStack(spacing: 12) {
            if let clan = socialVM.myClan {
                myClanView(clan)
            } else {
                noClanView
            }
        }
        .padding(16)
        .sheet(isPresented: $showCreateClan) { createClanSheet }
    }
    
    // MARK: — No Clan
    
    private var noClanView: some View {
        VStack(spacing: 16) {
            Text("🏰").font(.system(size: 60))
            Text("Pas de clan").font(BP.headFont).foregroundStyle(BP.purple)
            Text("Crée ton clan ou rejoins-en un !").font(BP.bodyFont).foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                BPButton("Créer (50💎)", icon: "🏰", gradient: BP.purpleGradient) {
                    showCreateClan = true
                }
                .opacity(buddyVM.buddy.gems >= 50 ? 1 : 0.5)
            }
        }
        .padding(.top, 40)
    }
    
    // MARK: — My Clan
    
    private func myClanView(_ clan: Clan) -> some View {
        VStack(spacing: 12) {
            // Header
            BPCard {
                VStack(spacing: 8) {
                    HStack {
                        Text(clan.emoji).font(.system(size: 36))
                        VStack(alignment: .leading) {
                            Text(clan.name).font(BP.font(18, weight: .bold))
                            Text("\(clan.memberCount)/20 membres").font(BP.captionFont).foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack {
                            Text("🏆 #\(clan.rank == 0 ? "—" : "\(clan.rank)")").font(BP.font(14, weight: .bold))
                            Text("\(clan.totalPoints) pts").font(BP.captionFont).foregroundStyle(.secondary)
                        }
                    }
                    Text(clan.description).font(BP.font(12, weight: .medium)).foregroundStyle(.secondary)
                }
            }
            
            // Mission hebdo
            if let mission = clan.weeklyMission {
                BPCard {
                    VStack(spacing: 8) {
                        HStack {
                            Text("📋 Mission de la semaine").font(BP.font(13, weight: .semibold))
                            Spacer()
                            if mission.isCompleted { Text("✅") }
                        }
                        Text("\(mission.emoji) \(mission.description)").font(BP.font(12, weight: .medium))
                        ProgressView(value: Double(mission.progress) / Double(mission.target))
                            .tint(mission.isCompleted ? BP.green : BP.purple)
                        Text("\(mission.progress)/\(mission.target)").font(BP.captionFont).foregroundStyle(.secondary)
                        Text("Récompense: \(mission.rewardGems)💎/membre").font(BP.font(10, weight: .bold)).foregroundStyle(BP.purple)
                    }
                }
            }
            
            // Leave
            Button {
                socialVM.leaveClan()
            } label: {
                Text("Quitter le clan")
                    .font(BP.font(12, weight: .medium))
                    .foregroundStyle(BP.red)
                    .padding(.top, 8)
            }
        }
    }
    
    // MARK: — Create Clan Sheet
    
    private var createClanSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Créer un clan").font(BP.titleFont).foregroundStyle(BP.purple)
                
                // Emoji selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(clanEmojis, id: \.self) { e in
                            Button {
                                clanEmoji = e; HapticService.selection()
                            } label: {
                                Text(e).font(.system(size: 30))
                                    .padding(8)
                                    .background(clanEmoji == e ? BP.pink.opacity(0.2) : BP.cardBG)
                                    .clipShape(Circle())
                            }
                        }
                    }.padding(.horizontal, 20)
                }
                
                TextField("Nom du clan", text: $clanName)
                    .font(BP.font(16, weight: .semibold))
                    .padding().background(BP.cardBG)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 20)
                
                TextField("Description", text: $clanDescription)
                    .font(BP.bodyFont)
                    .padding().background(BP.cardBG)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 20)
                
                Text("Coût: 50💎").font(BP.font(14, weight: .bold)).foregroundStyle(BP.purple)
                
                BPButton("Créer le clan", icon: "🏰", gradient: BP.purpleGradient) {
                    if socialVM.createClan(name: clanName, emoji: clanEmoji, description: clanDescription, vm: buddyVM) {
                        showCreateClan = false
                    }
                }
                .opacity(buddyVM.buddy.gems >= 50 && !clanName.isEmpty ? 1 : 0.5)
                .disabled(buddyVM.buddy.gems < 50 || clanName.isEmpty)
                
                Spacer()
            }
            .padding(.top, 20)
            .background(BP.bgGradient)
        }
        .presentationDetents([.medium])
    }
}
