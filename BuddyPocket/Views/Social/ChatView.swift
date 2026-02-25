import SwiftUI

// ══════════════════════════════════════════════════════════════════
// CHAT VIEW — Messages 1:1 avec amis et BUD
// ══════════════════════════════════════════════════════════════════

struct ChatView: View {
    let friend: Friend
    @EnvironmentObject var socialVM: SocialViewModel
    @EnvironmentObject var buddyVM: BuddyViewModel
    @Environment(\.dismiss) var dismiss
    @State private var messageText = ""
    @State private var showEmojis = false
    
    private var messages: [ChatMessage] {
        socialVM.conversations[friend.id] ?? []
    }
    
    private let quickEmojis = ["😊", "😂", "❤️", "🔥", "👍", "🎮", "⚔️", "🎉", "💎", "🏆", "😢", "🤔"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 10) {
                    ZStack {
                        Circle().fill(BP.purple.opacity(0.15)).frame(width: 36, height: 36)
                        Text(friend.buddyPreview.moodEmoji).font(.system(size: 18))
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 4) {
                            Text(friend.username).font(BP.font(14, weight: .bold))
                            if friend.isOfficial { Text("✓").font(BP.font(10, weight: .bold)).foregroundStyle(BP.purple) }
                        }
                        Text(friend.isOnline ? "En ligne" : "Hors ligne")
                            .font(BP.font(10, weight: .medium))
                            .foregroundStyle(friend.isOnline ? BP.green : .secondary)
                    }
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 24)).foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                
                // Messages
                ScrollView {
                    ScrollViewReader { proxy in
                        LazyVStack(spacing: 8) {
                            ForEach(messages) { msg in
                                messageBubble(msg)
                                    .id(msg.id)
                            }
                        }
                        .padding()
                        .onChange(of: messages.count) { _, _ in
                            if let last = messages.last {
                                withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                            }
                        }
                    }
                }
                
                // Quick emojis
                if showEmojis {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(quickEmojis, id: \.self) { emoji in
                                Button {
                                    sendEmoji(emoji)
                                } label: {
                                    Text(emoji).font(.system(size: 28))
                                        .padding(6).background(BP.cardBG).clipShape(Circle())
                                }
                            }
                        }
                        .padding(.horizontal, 12).padding(.vertical, 6)
                    }
                    .background(.ultraThinMaterial)
                    .transition(.move(edge: .bottom))
                }
                
                // Input bar
                HStack(spacing: 8) {
                    Button {
                        withAnimation(BP.springAnim) { showEmojis.toggle() }
                    } label: {
                        Text("😊").font(.system(size: 24))
                    }
                    
                    TextField("Message...", text: $messageText)
                        .font(BP.bodyFont)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(BP.cardBG)
                        .clipShape(Capsule())
                    
                    Button {
                        sendMessage()
                    } label: {
                        Circle()
                            .fill(messageText.isEmpty ? .gray.opacity(0.3) : BP.pinkGradient)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                            )
                    }
                    .disabled(messageText.isEmpty)
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(.ultraThinMaterial)
            }
            .background(BP.bgGradient)
            .navigationBarHidden(true)
        }
    }
    
    private func messageBubble(_ msg: ChatMessage) -> some View {
        let isMe = msg.senderID == socialVM.myProfile.id
        
        return HStack {
            if isMe { Spacer(minLength: 50) }
            
            VStack(alignment: isMe ? .trailing : .leading, spacing: 2) {
                Text(msg.content.displayText)
                    .font(BP.font(14, weight: .regular))
                    .foregroundStyle(isMe ? .white : .primary)
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(isMe ? BP.pinkGradient : LinearGradient(colors: [BP.cardBG], startPoint: .top, endPoint: .bottom))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                Text(timeString(msg.timestamp))
                    .font(BP.font(9, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            if !isMe { Spacer(minLength: 50) }
        }
    }
    
    private func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let text = messageText
        messageText = ""
        
        socialVM.sendMessage(to: friend.id, text: text)
        buddyVM.recordMessageSent()
        HapticService.tap()
        
        // BUD auto-response
        if friend.isOfficial {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                let response = socialVM.getBudResponse(for: text, playerLevel: buddyVM.buddy.level, buddyName: buddyVM.buddy.name)
                if socialVM.conversations[friend.id] == nil { socialVM.conversations[friend.id] = [] }
                socialVM.conversations[friend.id]?.append(response)
            }
        }
    }
    
    private func sendEmoji(_ emoji: String) {
        socialVM.sendEmoji(to: friend.id, emoji: emoji)
        HapticService.tap()
        showEmojis = false
        
        if friend.isOfficial {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let response = socialVM.getBudResponse(for: emoji, playerLevel: buddyVM.buddy.level, buddyName: buddyVM.buddy.name)
                if socialVM.conversations[friend.id] == nil { socialVM.conversations[friend.id] = [] }
                socialVM.conversations[friend.id]?.append(response)
            }
        }
    }
}
