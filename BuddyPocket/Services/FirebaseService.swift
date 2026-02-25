import Foundation
import FirebaseAuth
import FirebaseDatabase
import SwiftUI

// ══════════════════════════════════════════════════════════════════
// FIREBASE SERVICE — Auth + Realtime Database
// ══════════════════════════════════════════════════════════════════

@MainActor
class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    
    @Published var currentUserID: String?
    @Published var isAuthenticated = false
    @Published var friends: [Friend] = []
    @Published var friendRequests: [FriendRequest] = []
    @Published var conversations: [Conversation] = []
    @Published var clans: [Clan] = []
    @Published var myClan: Clan?
    @Published var activeBattle: Battle?
    
    private let db = Database.database().reference()
    private var listeners: [DatabaseHandle] = []
    
    // MARK: — Auth
    
    func signInAnonymously() async throws {
        let result = try await Auth.auth().signInAnonymously()
        currentUserID = result.user.uid
        isAuthenticated = true
        setupListeners()
    }
    
    func signIn(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        currentUserID = result.user.uid
        isAuthenticated = true
        setupListeners()
    }
    
    func signUp(email: String, password: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        currentUserID = result.user.uid
        isAuthenticated = true
        setupListeners()
    }
    
    func signOut() {
        try? Auth.auth().signOut()
        currentUserID = nil
        isAuthenticated = false
        removeListeners()
    }
    
    func checkAuth() {
        if let user = Auth.auth().currentUser {
            currentUserID = user.uid
            isAuthenticated = true
            setupListeners()
        }
    }
    
    // MARK: — Profil
    
    func saveProfile(_ profile: PlayerProfile) {
        guard let uid = currentUserID else { return }
        let data: [String: Any] = [
            "username": profile.username,
            "friendCode": profile.friendCode,
            "level": profile.level,
            "buddyBodyType": profile.buddyBodyType,
            "buddyColor": profile.buddyColor,
            "buddyEyeType": profile.buddyEyeType,
            "isOnline": true,
            "lastSeen": ServerValue.timestamp()
        ]
        db.child("users").child(uid).setValue(data)
    }
    
    func setOnlineStatus(_ online: Bool) {
        guard let uid = currentUserID else { return }
        db.child("users").child(uid).child("isOnline").setValue(online)
        if !online { db.child("users").child(uid).child("lastSeen").setValue(ServerValue.timestamp()) }
    }
    
    // MARK: — Amis
    
    func searchByFriendCode(_ code: String) async -> PlayerProfile? {
        let snapshot = try? await db.child("users").queryOrdered(byChild: "friendCode").queryEqual(toValue: code).getData()
        guard let dict = snapshot?.value as? [String: [String: Any]], let (uid, data) = dict.first else { return nil }
        return PlayerProfile(
            id: uid,
            username: data["username"] as? String ?? "???",
            friendCode: code,
            level: data["level"] as? Int ?? 1,
            buddyBodyType: data["buddyBodyType"] as? String ?? "blob",
            buddyColor: data["buddyColor"] as? String ?? "violet",
            buddyEyeType: data["buddyEyeType"] as? String ?? "normal"
        )
    }
    
    func sendFriendRequest(to targetUID: String, from profile: PlayerProfile) {
        let requestID = UUID().uuidString
        let data: [String: Any] = [
            "fromUserID": currentUserID ?? "",
            "fromUsername": profile.username,
            "fromFriendCode": profile.friendCode,
            "date": ServerValue.timestamp(),
            "status": "pending"
        ]
        db.child("friendRequests").child(targetUID).child(requestID).setValue(data)
    }
    
    func acceptFriendRequest(_ request: FriendRequest, myProfile: PlayerProfile) {
        guard let uid = currentUserID else { return }
        // Ajouter dans les deux sens
        db.child("friends").child(uid).child(request.fromUserID).setValue(["accepted": true])
        db.child("friends").child(request.fromUserID).child(uid).setValue(["accepted": true])
        // Supprimer la requête
        db.child("friendRequests").child(uid).child(request.id).removeValue()
    }
    
    func rejectFriendRequest(_ request: FriendRequest) {
        guard let uid = currentUserID else { return }
        db.child("friendRequests").child(uid).child(request.id).removeValue()
    }
    
    // MARK: — Chat
    
    func sendMessage(to friendID: String, content: MessageContent, senderName: String) {
        guard let uid = currentUserID else { return }
        let convID = conversationID(uid, friendID)
        let msgID = UUID().uuidString
        
        var msgData: [String: Any] = [
            "senderID": uid,
            "senderName": senderName,
            "timestamp": ServerValue.timestamp(),
            "isRead": false
        ]
        
        switch content {
        case .text(let t): msgData["type"] = "text"; msgData["text"] = t
        case .emoji(let e): msgData["type"] = "emoji"; msgData["text"] = e
        case .gift(let id, let name): msgData["type"] = "gift"; msgData["itemID"] = id; msgData["itemName"] = name
        case .battleInvite: msgData["type"] = "battleInvite"
        case .photo(let data): msgData["type"] = "photo"; msgData["photoData"] = data
        }
        
        db.child("chats").child(convID).child("messages").child(msgID).setValue(msgData)
        db.child("chats").child(convID).child("lastActivity").setValue(ServerValue.timestamp())
    }
    
    private func conversationID(_ a: String, _ b: String) -> String {
        [a, b].sorted().joined(separator: "_")
    }
    
    // MARK: — Clans
    
    func createClan(name: String, emoji: String, description: String) {
        guard let uid = currentUserID else { return }
        let clanID = UUID().uuidString
        let data: [String: Any] = [
            "name": name, "emoji": emoji, "description": description,
            "leaderID": uid, "memberIDs": [uid],
            "createdDate": ServerValue.timestamp(), "totalPoints": 0
        ]
        db.child("clans").child(clanID).setValue(data)
        db.child("users").child(uid).child("clanID").setValue(clanID)
    }
    
    func joinClan(_ clanID: String) {
        guard let uid = currentUserID else { return }
        db.child("clans").child(clanID).child("memberIDs").observeSingleEvent(of: .value) { [weak self] snapshot in
            var members = snapshot.value as? [String] ?? []
            guard members.count < 20 else { return }
            members.append(uid)
            self?.db.child("clans").child(clanID).child("memberIDs").setValue(members)
            self?.db.child("users").child(uid).child("clanID").setValue(clanID)
        }
    }
    
    func leaveClan(_ clanID: String) {
        guard let uid = currentUserID else { return }
        db.child("clans").child(clanID).child("memberIDs").observeSingleEvent(of: .value) { [weak self] snapshot in
            var members = snapshot.value as? [String] ?? []
            members.removeAll { $0 == uid }
            self?.db.child("clans").child(clanID).child("memberIDs").setValue(members)
            self?.db.child("users").child(uid).child("clanID").removeValue()
        }
    }
    
    // MARK: — Battles
    
    func startBattle(opponentID: String) -> String {
        guard let uid = currentUserID else { return "" }
        let battleID = UUID().uuidString
        let data: [String: Any] = [
            "player1ID": uid, "player2ID": opponentID,
            "player1Score": 0, "player2Score": 0,
            "status": "waiting", "startTime": ServerValue.timestamp()
        ]
        db.child("battles").child(battleID).setValue(data)
        return battleID
    }
    
    func submitBattleRound(battleID: String, roundData: [String: Any]) {
        let roundID = UUID().uuidString
        db.child("battles").child(battleID).child("rounds").child(roundID).setValue(roundData)
    }
    
    func finishBattle(battleID: String, winnerID: String?, p1Score: Int, p2Score: Int) {
        db.child("battles").child(battleID).updateChildValues([
            "status": "finished",
            "player1Score": p1Score,
            "player2Score": p2Score,
            "winnerID": winnerID ?? ""
        ])
    }
    
    // MARK: — Listeners
    
    private func setupListeners() {
        guard let uid = currentUserID else { return }
        
        // Écouter les friend requests
        let reqHandle = db.child("friendRequests").child(uid).observe(.value) { [weak self] snapshot in
            var requests: [FriendRequest] = []
            for child in snapshot.children.allObjects as? [DataSnapshot] ?? [] {
                guard let data = child.value as? [String: Any] else { continue }
                requests.append(FriendRequest(
                    id: child.key,
                    fromUserID: data["fromUserID"] as? String ?? "",
                    fromUsername: data["fromUsername"] as? String ?? "???",
                    fromFriendCode: data["fromFriendCode"] as? String ?? "",
                    date: Date()
                ))
            }
            Task { @MainActor in self?.friendRequests = requests }
        }
        listeners.append(reqHandle)
    }
    
    private func removeListeners() {
        guard let uid = currentUserID else { return }
        for handle in listeners {
            db.child("friendRequests").child(uid).removeObserver(withHandle: handle)
        }
        listeners.removeAll()
    }
}
