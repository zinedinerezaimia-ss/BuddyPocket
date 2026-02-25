import SwiftUI

// ══════════════════════════════════════════════════════════════════
// HOME VIEW — Écran principal avec Buddy animé
// ══════════════════════════════════════════════════════════════════

struct HomeView: View {
    @EnvironmentObject var buddyVM: BuddyViewModel
    @State private var showDialogue = true
    @State private var dialogueText = ""
    @State private var actionCooldown = false
    @State private var showLevelUpSheet = false
    @State private var showMissions = false
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                if let msg = buddyVM.lastRewardMessage {
                    rewardBanner(msg)
                }
                missionsPreview
                buddyZone
                statsSection
                actionsSection
                xpSection
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .onChange(of: buddyVM.showLevelUp) { _, show in
            if show { showLevelUpSheet = true; buddyVM.showLevelUp = false }
        }
        .sheet(isPresented: $showLevelUpSheet) { levelUpSheet }
        .sheet(isPresented: $showMissions) { missionsSheet }
        .onAppear { dialogueText = buddyVM.buddy.dialogueBubble }
    }
    
    private func rewardBanner(_ msg: String) -> some View {
        HStack {
            Text(msg).font(BP.font(13, weight: .semibold)).foregroundStyle(.white)
            Spacer()
            Button { buddyVM.lastRewardMessage = nil } label: {
                Image(systemName: "xmark").foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(12).background(BP.goldGradient)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var missionsPreview: some View {
        Button { showMissions = true } label: {
            BPCard {
                HStack {
                    Text("📋").font(.system(size: 18))
                    Text("Missions du jour").font(BP.font(13, weight: .semibold))
                    Spacer()
                    let done = buddyVM.dailyMissions.filter(\.isCompleted).count
                    Text("\(done)/\(buddyVM.dailyMissions.count)")
                        .font(BP.font(12, weight: .bold))
                        .foregroundStyle(done == buddyVM.dailyMissions.count ? BP.green : BP.purple)
                    Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(.secondary)
                }
            }
        }.buttonStyle(.plain)
    }
    
    private var buddyZone: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LinearGradient(colors: buddyVM.buddy.roomTheme.colors, startPoint: .top, endPoint: .bottom))
                .frame(height: 300)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.2), lineWidth: 1))
            
            ForEach(buddyVM.buddy.decorItems) { decor in
                Text(decor.emoji).font(.system(size: 24)).position(x: decor.x, y: decor.y)
            }
            
            VStack(spacing: 8) {
                if showDialogue {
                    Text(dialogueText)
                        .font(BP.font(13, weight: .medium))
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 16).fill(.white).shadow(color: .black.opacity(0.08), radius: 6, y: 2))
                        .transition(.scale.combined(with: .opacity))
                }
                BuddyCanvasView(buddy: buddyVM.buddy, size: 150, animated: true)
                    .onTapGesture {
                        withAnimation(BP.springAnim) {
                            dialogueText = buddyVM.buddy.dialogueBubble; showDialogue.toggle()
                        }
                    }
                Text(buddyVM.buddy.moodEmoji).font(.system(size: 24))
            }
        }
    }
    
    private var statsSection: some View {
        BPCard {
            VStack(spacing: 10) {
                BPStatBar(label: StatType.hunger.rawValue, icon: StatType.hunger.icon, value: buddyVM.buddy.hunger, color: StatType.hunger.color)
                BPStatBar(label: StatType.happiness.rawValue, icon: StatType.happiness.icon, value: buddyVM.buddy.happiness, color: StatType.happiness.color)
                BPStatBar(label: StatType.energy.rawValue, icon: StatType.energy.icon, value: buddyVM.buddy.energy, color: StatType.energy.color)
                BPStatBar(label: StatType.hygiene.rawValue, icon: StatType.hygiene.icon, value: buddyVM.buddy.hygiene, color: StatType.hygiene.color)
            }
        }
        .overlay {
            if buddyVM.buddy.criticalStat != nil {
                RoundedRectangle(cornerRadius: BP.cardRadius).stroke(BP.red, lineWidth: 2).pulse()
            }
        }
    }
    
    private var actionsSection: some View {
        HStack(spacing: 10) {
            ForEach(BuddyAction.allCases, id: \.rawValue) { action in
                Button {
                    guard !actionCooldown else { return }
                    actionCooldown = true
                    buddyVM.performAction(action)
                    let responses: [String] = {
                        switch action {
                        case .feed:  return ["Miam miam ! 😋", "Trop bon !", "Encore ! 🍖"]
                        case .pet:   return ["Ronron... 😊", "J'adore les câlins !", "Encore !"]
                        case .sleep: return ["Zzz... 💤", "Bonne nuit...", "Un petit dodo..."]
                        case .bath:  return ["Splash ! 🛁", "Tout propre !", "Ça fait du bien !"]
                        }
                    }()
                    dialogueText = responses.randomElement()!
                    withAnimation(BP.springAnim) { showDialogue = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { actionCooldown = false }
                } label: {
                    VStack(spacing: 4) {
                        Text(action.icon).font(.system(size: 28))
                        Text(action.rawValue).font(BP.font(10, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(BP.cardBG).clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                }
                .buttonStyle(.plain).opacity(actionCooldown ? 0.6 : 1)
            }
        }
    }
    
    private var xpSection: some View {
        BPCard {
            VStack(spacing: 8) {
                HStack {
                    Text("⭐ Niveau \(buddyVM.buddy.level)").font(BP.font(14, weight: .bold)).foregroundStyle(BP.purple)
                    Spacer()
                    Text("\(buddyVM.buddy.xp)/\(buddyVM.buddy.xpForNextLevel) XP").font(BP.captionFont).foregroundStyle(.secondary)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(BP.purple.opacity(0.15)).frame(height: 10)
                        Capsule().fill(BP.purpleGradient)
                            .frame(width: max(4, geo.size.width * buddyVM.buddy.xpProgress), height: 10)
                            .animation(BP.springAnim, value: buddyVM.buddy.xpProgress)
                    }
                }.frame(height: 10)
            }
        }
    }
    
    private var levelUpSheet: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("🎉").font(.system(size: 80))
            Text("Niveau \(buddyVM.buddy.level) !").font(BP.font(32, weight: .bold)).foregroundStyle(BP.purpleGradient)
            Text("Félicitations !").font(BP.bodyFont).foregroundStyle(.secondary)
            let newBodies = BodyType.allSecret.filter { $0.unlockLevel == buddyVM.buddy.level }
            if !newBodies.isEmpty {
                VStack(spacing: 8) {
                    Text("Nouveau corps débloqué !").font(BP.font(14, weight: .semibold))
                    ForEach(newBodies) { b in
                        HStack { Text(b.emoji).font(.system(size: 30)); Text(b.displayName).font(BP.font(16, weight: .bold)) }
                    }
                }.padding().background(BP.goldGradient.opacity(0.2)).clipShape(RoundedRectangle(cornerRadius: 16))
            }
            Spacer()
            BPButton("Super !", gradient: BP.purpleGradient) { showLevelUpSheet = false }.padding(.bottom, 40)
        }.frame(maxWidth: .infinity).background(BP.bgGradient).presentationDetents([.medium])
    }
    
    private var missionsSheet: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(buddyVM.dailyMissions) { m in
                        HStack(spacing: 12) {
                            Text(m.emoji).font(.system(size: 28))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(m.description).font(BP.font(13, weight: .semibold))
                                ProgressView(value: m.progressPercent).tint(m.isCompleted ? BP.green : BP.purple)
                                Text("\(m.progress)/\(m.target)").font(BP.font(10, weight: .medium)).foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(spacing: 2) {
                                Text("+\(m.rewardGems)💎").font(BP.font(10, weight: .bold))
                                Text("+\(m.rewardCoins)🪙").font(BP.font(10, weight: .bold))
                            }
                            if m.isCompleted { Text("✅") }
                        }
                        .padding(12).background(BP.cardBG).clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }.padding()
            }.background(BP.bgGradient).navigationTitle("Missions du jour").navigationBarTitleDisplayMode(.inline)
        }.presentationDetents([.medium, .large])
    }
}
