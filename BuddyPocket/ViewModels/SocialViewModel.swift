import SwiftUI

// ══════════════════════════════════════════════════════════════════
// SOCIAL VIEW MODEL — Amis, Chat, Clans, Battles
// ══════════════════════════════════════════════════════════════════

@MainActor
class SocialViewModel: ObservableObject {
    @Published var friends: [Friend] = []
    @Published var friendRequests: [FriendRequest] = []
    @Published var conversations: [String: [ChatMessage]] = [:]
    @Published var myClan: Clan?
    @Published var activeBattle: Battle?
    @Published var searchResult: PlayerProfile?
    @Published var isSearching = false
    @Published var myProfile: PlayerProfile
    
    let firebase = FirebaseService.shared
    
    init() {
        myProfile = PlayerProfile(
            username: "Joueur",
            friendCode: PlayerProfile.generateFriendCode(),
            level: 1, buddyBodyType: "blob", buddyColor: "violet", buddyEyeType: "normal"
        )
        loadProfile()
        addBudIfNeeded()
    }
    
    // MARK: — BUD (Assistant officiel)
    
    private func addBudIfNeeded() {
        if !friends.contains(where: { $0.isOfficial }) {
            let bud = Friend(
                id: "bud_official",
                username: "BUD ✓",
                friendCode: "BUDDY#0001",
                isOnline: true,
                level: 50,
                buddyPreview: BuddyPreview(
                    bodyType: "cosmique", color: "doreBrillant",
                    eyeType: "etoile", headAccessory: nil, costume: nil,
                    moodEmoji: "🤖"
                ),
                isOfficial: true
            )
            friends.insert(bud, at: 0)
        }
    }
    
    // MARK: — Recherche amis
    
    func searchFriend(code: String) async {
        isSearching = true
        searchResult = await firebase.searchByFriendCode(code)
        isSearching = false
    }
    
    func sendFriendRequest(to profile: PlayerProfile) {
        firebase.sendFriendRequest(to: profile.id, from: myProfile)
    }
    
    func acceptRequest(_ request: FriendRequest) {
        firebase.acceptFriendRequest(request, myProfile: myProfile)
        friendRequests.removeAll { $0.id == request.id }
        
        let newFriend = Friend(
            id: request.fromUserID,
            username: request.fromUsername,
            friendCode: request.fromFriendCode,
            isOnline: false,
            level: 1,
            buddyPreview: BuddyPreview(bodyType: "blob", color: "violet", eyeType: "normal", headAccessory: nil, costume: nil, moodEmoji: "😊")
        )
        friends.append(newFriend)
        saveFriends()
    }
    
    func rejectRequest(_ request: FriendRequest) {
        firebase.rejectFriendRequest(request)
        friendRequests.removeAll { $0.id == request.id }
    }
    
    // MARK: — Chat
    
    func sendMessage(to friendID: String, text: String) {
        let msg = ChatMessage(
            senderID: myProfile.id,
            senderName: myProfile.username,
            content: .text(text),
            timestamp: Date()
        )
        
        if conversations[friendID] == nil { conversations[friendID] = [] }
        conversations[friendID]?.append(msg)
        
        firebase.sendMessage(to: friendID, content: .text(text), senderName: myProfile.username)
        saveConversations()
    }
    
    func sendEmoji(to friendID: String, emoji: String) {
        let msg = ChatMessage(
            senderID: myProfile.id,
            senderName: myProfile.username,
            content: .emoji(emoji),
            timestamp: Date()
        )
        
        if conversations[friendID] == nil { conversations[friendID] = [] }
        conversations[friendID]?.append(msg)
        
        firebase.sendMessage(to: friendID, content: .emoji(emoji), senderName: myProfile.username)
    }
    
    func sendGift(to friendID: String, item: CatalogItem) {
        let msg = ChatMessage(
            senderID: myProfile.id,
            senderName: myProfile.username,
            content: .gift(itemID: item.id, itemName: item.name),
            timestamp: Date()
        )
        
        if conversations[friendID] == nil { conversations[friendID] = [] }
        conversations[friendID]?.append(msg)
        
        firebase.sendMessage(to: friendID, content: .gift(itemID: item.id, itemName: item.name), senderName: myProfile.username)
    }
    
    func getBudResponse(for message: String, playerLevel: Int, buddyName: String) -> ChatMessage {
        let response = BudAssistant.respond(to: message, playerLevel: playerLevel, buddyName: buddyName)
        return ChatMessage(
            senderID: "bud_official",
            senderName: "BUD ✓",
            content: .text(response),
            timestamp: Date()
        )
    }
    
    // MARK: — Clans
    
    func createClan(name: String, emoji: String, description: String, vm: BuddyViewModel) -> Bool {
        guard vm.buddy.gems >= Clan.creationCost else { return false }
        vm.buddy.gems -= Clan.creationCost
        
        myClan = Clan(name: name, emoji: emoji, description: description, leaderID: myProfile.id, memberIDs: [myProfile.id])
        firebase.createClan(name: name, emoji: emoji, description: description)
        saveClan()
        return true
    }
    
    func joinClan(_ clan: Clan) {
        guard !clan.isFull else { return }
        myClan = clan
        firebase.joinClan(clan.id)
        saveClan()
    }
    
    func leaveClan() {
        guard let clan = myClan else { return }
        firebase.leaveClan(clan.id)
        myClan = nil
        saveClan()
    }
    
    // MARK: — Battles
    
    func startBattle(friendID: String) {
        let battleID = firebase.startBattle(opponentID: friendID)
        
        // Simuler 3 rounds
        var battle = Battle(id: battleID, player1ID: myProfile.id, player2ID: friendID)
        for i in 1...3 {
            let roundType = BattleRoundType.allCases.randomElement()!
            let p1 = Int.random(in: 10...100)
            let p2 = Int.random(in: 10...100)
            battle.rounds.append(BattleRound(roundNumber: i, type: roundType, player1Value: p1, player2Value: p2))
            if p1 > p2 { battle.player1Score += 1 } else if p2 > p1 { battle.player2Score += 1 }
        }
        battle.status = .finished
        activeBattle = battle
    }
    
    // MARK: — Profile sync
    
    func updateProfile(from buddy: Buddy) {
        myProfile.level = buddy.level
        myProfile.buddyBodyType = buddy.bodyType.rawValue
        myProfile.buddyColor = buddy.bodyColor.rawValue
        myProfile.buddyEyeType = buddy.eyeType.rawValue
        firebase.saveProfile(myProfile)
        saveProfile()
    }
    
    // MARK: — Persistance
    
    private func saveProfile() {
        if let data = try? JSONEncoder().encode(myProfile) {
            UserDefaults.standard.set(data, forKey: "player_profile")
        }
    }
    private func loadProfile() {
        if let data = UserDefaults.standard.data(forKey: "player_profile"),
           let p = try? JSONDecoder().decode(PlayerProfile.self, from: data) { myProfile = p }
    }
    private func saveFriends() {
        if let data = try? JSONEncoder().encode(friends) {
            UserDefaults.standard.set(data, forKey: "friends_list")
        }
    }
    private func saveConversations() {
        if let data = try? JSONEncoder().encode(conversations) {
            UserDefaults.standard.set(data, forKey: "conversations")
        }
    }
    private func saveClan() {
        if let data = try? JSONEncoder().encode(myClan) {
            UserDefaults.standard.set(data, forKey: "my_clan")
        }
    }
}
