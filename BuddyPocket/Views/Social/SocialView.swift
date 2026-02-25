import SwiftUI

// ══════════════════════════════════════════════════════════════════
// SOCIAL VIEW — Amis, Recherche, Battles, Clans
// ══════════════════════════════════════════════════════════════════

struct SocialView: View {
    @EnvironmentObject var socialVM: SocialViewModel
    @EnvironmentObject var buddyVM: BuddyViewModel
    @State private var selectedTab: SocialTab = .friends
    @State private var searchCode = ""
    @State private var showAddFriend = false
    @State private var showBattleResult = false
    @State private var selectedFriend: Friend?
    
    enum SocialTab: String, CaseIterable {
        case friends = "Amis"
        case requests = "Demandes"
        case clans = "Clans"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Mon code ami
            myCodeCard
            
            // Tabs
            HStack(spacing: 0) {
                ForEach(SocialTab.allCases, id: \.rawValue) { tab in
                    Button {
                        withAnimation(BP.gentleAnim) { selectedTab = tab }
                    } label: {
                        VStack(spacing: 4) {
                            Text(tab.rawValue).font(BP.font(13, weight: selectedTab == tab ? .bold : .medium))
                            if tab == .requests && !socialVM.friendRequests.isEmpty {
                                Circle().fill(BP.red).frame(width: 6, height: 6)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(selectedTab == tab ? BP.pink.opacity(0.1) : .clear)
                    }
                    .foregroundStyle(selectedTab == tab ? BP.pink : .secondary)
                }
            }
            .padding(.horizontal, 16)
            
            // Content
            ScrollView(showsIndicators: false) {
                switch selectedTab {
                case .friends:  friendsListView
                case .requests: requestsView
                case .clans:    ClanView()
                }
            }
        }
        .sheet(isPresented: $showAddFriend) { addFriendSheet }
        .sheet(item: $selectedFriend) { friend in
            ChatView(friend: friend)
        }
        .sheet(isPresented: $showBattleResult) { battleResultSheet }
    }
    
    // MARK: — Mon code
    
    private var myCodeCard: some View {
        BPCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mon code ami").font(BP.captionFont).foregroundStyle(.secondary)
                    Text(socialVM.myProfile.friendCode)
                        .font(BP.font(18, weight: .bold)).foregroundStyle(BP.purple)
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
                Button { showAddFriend = true } label: {
                    Text("➕").font(.system(size: 22))
                }
            }
        }
        .padding(.horizontal, 16).padding(.top, 8)
    }
    
    // MARK: — Friends List
    
    private var friendsListView: some View {
        VStack(spacing: 8) {
            if socialVM.friends.isEmpty {
                VStack(spacing: 12) {
                    Text("👥").font(.system(size: 50))
                    Text("Pas encore d'amis").font(BP.font(16, weight: .semibold))
                    Text("Ajoute des amis avec leur code !").font(BP.captionFont).foregroundStyle(.secondary)
                }
                .padding(.top, 40)
            } else {
                ForEach(socialVM.friends) { friend in
                    friendRow(friend)
                }
            }
        }
        .padding(16)
    }
    
    private func friendRow(_ friend: Friend) -> some View {
        BPCard {
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle().fill(Color(hex: UInt(friend.buddyPreview.color.hashValue & 0xFFFFFF)).opacity(0.2))
                        .frame(width: 44, height: 44)
                    Text(friend.buddyPreview.moodEmoji).font(.system(size: 22))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(friend.username).font(BP.font(14, weight: .bold))
                        if friend.isOfficial { BPBadge(text: "✓ Officiel", color: BP.purple) }
                    }
                    Text("Nv.\(friend.level)").font(BP.captionFont).foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Online indicator
                Circle().fill(friend.isOnline ? BP.green : .gray.opacity(0.3)).frame(width: 8, height: 8)
                
                // Actions
                HStack(spacing: 6) {
                    Button {
                        selectedFriend = friend
                    } label: {
                        Text("💬").font(.system(size: 20))
                    }
                    
                    if !friend.isOfficial {
                        Button {
                            socialVM.startBattle(friendID: friend.id)
                            showBattleResult = true
                        } label: {
                            Text("⚔️").font(.system(size: 20))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: — Requests
    
    private var requestsView: some View {
        VStack(spacing: 8) {
            if socialVM.friendRequests.isEmpty {
                VStack(spacing: 12) {
                    Text("📨").font(.system(size: 50))
                    Text("Aucune demande").font(BP.font(16, weight: .semibold))
                }.padding(.top, 40)
            }
            ForEach(socialVM.friendRequests) { req in
                BPCard {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(req.fromUsername).font(BP.font(14, weight: .bold))
                            Text(req.fromFriendCode).font(BP.captionFont).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button { socialVM.acceptRequest(req) } label: {
                            Text("✅").font(.system(size: 24))
                        }
                        Button { socialVM.rejectRequest(req) } label: {
                            Text("❌").font(.system(size: 24))
                        }
                    }
                }
            }
        }
        .padding(16)
    }
    
    // MARK: — Add Friend Sheet
    
    private var addFriendSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Ajouter un ami").font(BP.titleFont).foregroundStyle(BP.purple)
                
                HStack {
                    TextField("BUDDY#1234", text: $searchCode)
                        .font(BP.font(16, weight: .semibold))
                        .textInputAutocapitalization(.characters)
                        .padding()
                        .background(BP.cardBG)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    
                    BPButton("Chercher", gradient: BP.purpleGradient) {
                        Task { await socialVM.searchFriend(code: searchCode) }
                    }
                }
                .padding(.horizontal, 20)
                
                if socialVM.isSearching {
                    ProgressView().padding()
                }
                
                if let result = socialVM.searchResult {
                    BPCard {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(result.username).font(BP.font(16, weight: .bold))
                                Text("Nv.\(result.level)").font(BP.captionFont).foregroundStyle(.secondary)
                            }
                            Spacer()
                            BPButton("Ajouter", icon: "➕", gradient: BP.pinkGradient) {
                                socialVM.sendFriendRequest(to: result)
                                showAddFriend = false
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
            }
            .padding(.top, 20)
            .background(BP.bgGradient)
        }
        .presentationDetents([.medium])
    }
    
    // MARK: — Battle Result Sheet
    
    private var battleResultSheet: some View {
        VStack(spacing: 20) {
            Spacer()
            if let battle = socialVM.activeBattle {
                let won = battle.winnerID == socialVM.myProfile.id
                Text(won ? "🏆 Victoire !" : "😤 Défaite...").font(BP.font(28, weight: .bold))
                Text("\(battle.player1Score) - \(battle.player2Score)").font(BP.font(24, weight: .semibold))
                
                ForEach(battle.rounds) { round in
                    HStack {
                        Text(round.type.emoji)
                        Text(round.type.rawValue).font(BP.font(13, weight: .medium))
                        Spacer()
                        Text("\(round.player1Value)").font(BP.font(14, weight: .bold))
                            .foregroundStyle(round.player1Value > round.player2Value ? BP.green : BP.red)
                        Text("vs").font(BP.captionFont).foregroundStyle(.secondary)
                        Text("\(round.player2Value)").font(BP.font(14, weight: .bold))
                            .foregroundStyle(round.player2Value > round.player1Value ? BP.green : BP.red)
                    }
                    .padding(.horizontal, 30)
                }
                
                if won {
                    Text("+3💎 +20🪙 +30⭐").font(BP.font(14, weight: .bold)).foregroundStyle(BP.purple)
                }
            }
            Spacer()
            BPButton("Fermer", gradient: BP.pinkGradient) {
                buddyVM.rewardForBattle(won: socialVM.activeBattle?.winnerID == socialVM.myProfile.id)
                showBattleResult = false
            }
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity).background(BP.bgGradient)
        .presentationDetents([.medium])
    }
}
