import SwiftUI

// ══════════════════════════════════════════════════════════════════
// ONBOARDING — 5 écrans d'introduction
// ══════════════════════════════════════════════════════════════════

struct OnboardingView: View {
    @EnvironmentObject var buddyVM: BuddyViewModel
    @EnvironmentObject var socialVM: SocialViewModel
    @State private var step = 0
    @State private var selectedGender: Gender = .boy
    @State private var selectedBody: BodyType = .blob
    @State private var selectedColor: BuddyColor = .violet
    @State private var selectedEyes: EyeType = .normal
    @State private var buddyName = ""
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    
    var body: some View {
        ZStack {
            BP.bgGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    ForEach(0..<5, id: \.self) { i in
                        Circle()
                            .fill(i <= step ? BP.pink : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(i == step ? 1.3 : 1)
                            .animation(BP.springAnim, value: step)
                    }
                }
                .padding(.top, 20)
                
                Spacer()
                
                Group {
                    switch step {
                    case 0: logoStep
                    case 1: genderStep
                    case 2: creatorStep
                    case 3: nameStep
                    case 4: notifStep
                    default: EmptyView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                
                Spacer()
                
                BPButton(step < 4 ? "Suivant" : "C'est parti ! 🚀", gradient: BP.purpleGradient) {
                    if step < 4 {
                        withAnimation(BP.springAnim) { step += 1 }
                    } else {
                        finishOnboarding()
                    }
                }
                .padding(.bottom, 40)
                .opacity(canProceed ? 1 : 0.5)
                .disabled(!canProceed)
            }
        }
    }
    
    private var canProceed: Bool {
        if step == 3 { return !buddyName.trimmingCharacters(in: .whitespaces).isEmpty }
        return true
    }
    
    // MARK: — Écran 1
    private var logoStep: some View {
        VStack(spacing: 20) {
            Text("🐾").font(.system(size: 80))
                .scaleEffect(logoScale).opacity(logoOpacity)
                .onAppear {
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.5)) {
                        logoScale = 1; logoOpacity = 1
                    }
                }
            Text("Buddy Pocket").font(BP.font(32, weight: .bold)).foregroundStyle(BP.purpleGradient)
            Text("Adopte ta créature !").font(BP.font(18, weight: .medium)).foregroundStyle(.secondary)
        }
    }
    
    // MARK: — Écran 2
    private var genderStep: some View {
        VStack(spacing: 24) {
            Text("Tu es...").font(BP.titleFont).foregroundStyle(BP.purple)
            Text("(ça change juste l'ordre des catégories, tout reste accessible !)")
                .font(BP.captionFont).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal, 30)
            HStack(spacing: 20) {
                ForEach(Gender.allCases, id: \.rawValue) { gender in
                    Button {
                        withAnimation(BP.springAnim) { selectedGender = gender }
                        HapticService.selection()
                    } label: {
                        VStack(spacing: 12) {
                            Text(gender.icon).font(.system(size: 60))
                            Text(gender.rawValue).font(BP.font(16, weight: .semibold))
                                .foregroundStyle(selectedGender == gender ? .white : BP.purple)
                        }
                        .frame(width: 130, height: 140)
                        .background(
                            RoundedRectangle(cornerRadius: BP.cardRadius, style: .continuous)
                                .fill(selectedGender == gender ? BP.purpleGradient : LinearGradient(colors: [BP.cardBG], startPoint: .top, endPoint: .bottom))
                                .shadow(color: selectedGender == gender ? BP.purple.opacity(0.4) : .clear, radius: 10)
                        )
                    }
                }
            }
        }
    }
    
    // MARK: — Écran 3
    private var creatorStep: some View {
        VStack(spacing: 16) {
            Text("Crée ton Buddy !").font(BP.titleFont).foregroundStyle(BP.purple)
            
            ZStack {
                Circle().fill(selectedColor.color.opacity(0.15)).frame(width: 140, height: 140)
                BuddyCanvasView(buddy: previewBuddy, size: 100, animated: true)
            }.frame(height: 160)
            
            VStack(spacing: 12) {
                selectorRow(title: "Corps") {
                    ForEach(BodyType.allBasic) { body in
                        Button {
                            withAnimation(BP.springAnim) { selectedBody = body }; HapticService.selection()
                        } label: {
                            VStack(spacing: 2) {
                                Text(body.emoji).font(.system(size: 24))
                                Text(body.displayName).font(BP.font(8, weight: .medium))
                            }
                            .frame(width: 56, height: 52)
                            .background(selectedBody == body ? BP.pink.opacity(0.2) : BP.cardBG)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(selectedBody == body ? BP.pink : .clear, lineWidth: 2))
                        }
                    }
                }
                
                selectorRow(title: "Couleur") {
                    ForEach(BuddyColor.allBasic) { color in
                        Button {
                            withAnimation(BP.springAnim) { selectedColor = color }; HapticService.selection()
                        } label: {
                            Circle().fill(color.color).frame(width: 32, height: 32)
                                .overlay(Circle().stroke(.white, lineWidth: selectedColor == color ? 3 : 0))
                                .shadow(color: selectedColor == color ? color.color.opacity(0.5) : .clear, radius: 4)
                        }
                    }
                }
                
                selectorRow(title: "Yeux") {
                    ForEach(EyeType.allBasic) { eye in
                        Button {
                            withAnimation(BP.springAnim) { selectedEyes = eye }; HapticService.selection()
                        } label: {
                            Text(eye.displayName).font(BP.font(10, weight: .medium))
                                .padding(.horizontal, 10).padding(.vertical, 8)
                                .background(selectedEyes == eye ? BP.pink.opacity(0.2) : BP.cardBG)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(selectedEyes == eye ? BP.pink : .clear, lineWidth: 2))
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 8)
    }
    
    private func selectorRow<Content: View>(title: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(BP.font(13, weight: .semibold)).foregroundStyle(.secondary).padding(.leading, 12)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) { content() }.padding(.horizontal, 12)
            }
        }
    }
    
    private var previewBuddy: Buddy {
        var b = Buddy(); b.bodyType = selectedBody; b.bodyColor = selectedColor; b.eyeType = selectedEyes; b.gender = selectedGender; return b
    }
    
    // MARK: — Écran 4
    private var nameStep: some View {
        VStack(spacing: 24) {
            BuddyCanvasView(buddy: previewBuddy, size: 80, animated: true)
            Text("Comment s'appelle ton Buddy ?").font(BP.headFont).foregroundStyle(BP.purple)
            TextField("Nom du Buddy", text: $buddyName)
                .font(BP.font(20, weight: .semibold)).multilineTextAlignment(.center)
                .padding().background(BP.cardBG).clipShape(RoundedRectangle(cornerRadius: BP.cardRadius)).padding(.horizontal, 40)
            if !buddyName.isEmpty {
                Text("Bienvenue, \(buddyName) ! 🎉").font(BP.bodyFont).foregroundStyle(.secondary)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    // MARK: — Écran 5
    private var notifStep: some View {
        VStack(spacing: 24) {
            Text("🔔").font(.system(size: 60))
            Text("Active les notifications").font(BP.titleFont).foregroundStyle(BP.purple)
            Text("\(buddyName) pourra t'envoyer des alertes quand il a besoin de toi !")
                .font(BP.bodyFont).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal, 30)
            VStack(spacing: 8) {
                notifRow("🍖", "\(buddyName) a faim !")
                notifRow("😢", "\(buddyName) est triste...")
                notifRow("🎁", "Ta récompense quotidienne t'attend !")
            }.padding(.horizontal, 20)
            BPButton("Activer les notifications", icon: "🔔", gradient: BP.pinkGradient) {
                Task { _ = await NotificationService.shared.requestPermission() }
            }
        }
    }
    
    private func notifRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 10) { Text(icon); Text(text).font(BP.font(13, weight: .medium)); Spacer() }
            .padding(10).background(BP.cardBG).clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: — Finish
    private func finishOnboarding() {
        buddyVM.buddy.name = buddyName.trimmingCharacters(in: .whitespaces)
        buddyVM.buddy.gender = selectedGender
        buddyVM.buddy.bodyType = selectedBody
        buddyVM.buddy.bodyColor = selectedColor
        buddyVM.buddy.eyeType = selectedEyes
        
        let accs = (selectedGender == .boy ? ItemCatalog.boyHeadAccessories : ItemCatalog.girlHeadAccessories).filter { $0.requiredLevel <= 1 }.map(\.id)
        buddyVM.buddy.unlockedHeadAccessories = accs
        let tops = (selectedGender == .boy ? ItemCatalog.boyTops : ItemCatalog.girlTops).filter { $0.requiredLevel <= 1 }.map(\.id)
        buddyVM.buddy.unlockedTops = tops
        let bots = (selectedGender == .boy ? ItemCatalog.boyBottoms : ItemCatalog.girlBottoms).filter { $0.requiredLevel <= 1 }.map(\.id)
        buddyVM.buddy.unlockedBottoms = bots
        
        socialVM.myProfile.username = buddyName
        socialVM.myProfile.friendCode = PlayerProfile.generateFriendCode()
        socialVM.myProfile.buddyBodyType = selectedBody.rawValue
        socialVM.myProfile.buddyColor = selectedColor.rawValue
        socialVM.myProfile.buddyEyeType = selectedEyes.rawValue
        
        buddyVM.save(); buddyVM.syncWidget()
        Task {
            try? await FirebaseService.shared.signInAnonymously()
            FirebaseService.shared.saveProfile(socialVM.myProfile)
        }
        BuddyStore.hasCompletedOnboarding = true
        HapticService.levelUp()
    }
}
