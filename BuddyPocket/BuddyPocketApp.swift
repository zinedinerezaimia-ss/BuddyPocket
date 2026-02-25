import SwiftUI
import FirebaseCore

// ══════════════════════════════════════════════════════════════════
// BUDDY POCKET APP — Point d'entrée principal
// ══════════════════════════════════════════════════════════════════

@main
struct BuddyPocketApp: App {
    @StateObject private var buddyVM = BuddyViewModel()
    @StateObject private var shopVM = ShopViewModel()
    @StateObject private var socialVM = SocialViewModel()
    @StateObject private var firebase = FirebaseService.shared
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(buddyVM)
                .environmentObject(shopVM)
                .environmentObject(socialVM)
                .environmentObject(firebase)
                .onAppear {
                    firebase.checkAuth()
                    NotificationService.shared.scheduleDailyReward()
                    NotificationService.shared.scheduleShopReset()
                    buddyVM.syncWidget()
                    shopVM.refreshShopIfNeeded(gender: buddyVM.buddy.gender)
                }
                .onChange(of: buddyVM.buddy.level) { _, _ in
                    socialVM.updateProfile(from: buddyVM.buddy)
                }
        }
    }
}

struct RootView: View {
    @EnvironmentObject var buddyVM: BuddyViewModel
    
    var body: some View {
        if BuddyStore.hasCompletedOnboarding {
            MainTabView()
        } else {
            OnboardingView()
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var buddyVM: BuddyViewModel
    @State private var selectedTab: AppTab = .home
    
    enum AppTab: Int, CaseIterable {
        case home, customizer, games, social, shop
        
        var title: String {
            switch self {
            case .home: return "Maison"; case .customizer: return "Style"
            case .games: return "Jeux"; case .social: return "Amis"
            case .shop: return "Boutique"
            }
        }
        var icon: String {
            switch self {
            case .home: return "🏠"; case .customizer: return "✨"
            case .games: return "🎮"; case .social: return "👥"
            case .shop: return "🛍️"
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background
            BP.bgGradient.ignoresSafeArea()
            
            // Content
            VStack(spacing: 0) {
                // Header
                headerBar
                
                // Pages
                Group {
                    switch selectedTab {
                    case .home:       HomeView()
                    case .customizer: CustomizerView()
                    case .games:      GamesView()
                    case .social:     SocialView()
                    case .shop:       ShopView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Spacer(minLength: 0)
            }
            
            // Tab Bar
            tabBar
        }
    }
    
    private var headerBar: some View {
        HStack {
            // Logo
            HStack(spacing: 4) {
                Text("🐾")
                Text("Buddy Pocket")
                    .font(BP.font(16, weight: .bold))
                    .foregroundStyle(BP.purple)
            }
            
            Spacer()
            
            // Streak
            if buddyVM.buddy.streakDays > 0 {
                HStack(spacing: 2) {
                    Text("🔥")
                    Text("\(buddyVM.buddy.streakDays)")
                        .font(BP.font(12, weight: .bold))
                        .foregroundStyle(BP.orange)
                }
                .padding(.horizontal, 6).padding(.vertical, 3)
                .background(Color.orange.opacity(0.15))
                .clipShape(Capsule())
            }
            
            // Monnaies
            BPCoinDisplay(
                coins: buddyVM.buddy.isDevMode ? .max : buddyVM.buddy.coins,
                gems: buddyVM.buddy.isDevMode ? .max : buddyVM.buddy.gems
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
    
    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.rawValue) { tab in
                Button {
                    withAnimation(BP.springAnim) { selectedTab = tab }
                    HapticService.tap()
                } label: {
                    VStack(spacing: 2) {
                        Text(tab.icon).font(.system(size: 22))
                        Text(tab.title)
                            .font(BP.font(9, weight: selectedTab == tab ? .bold : .medium))
                            .foregroundStyle(selectedTab == tab ? BP.pink : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        selectedTab == tab ?
                        BP.pinkGradient.opacity(0.15) : LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 6)
        .padding(.bottom, bottomSafeArea + 4)
        .background(.ultraThinMaterial)
    }
    
    private var bottomSafeArea: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.bottom ?? 0
    }
}
