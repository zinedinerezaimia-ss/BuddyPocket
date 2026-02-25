import SwiftUI

// ══════════════════════════════════════════════════════════════════
// GAMES VIEW — 10 Mini-jeux
// ══════════════════════════════════════════════════════════════════

struct GamesView: View {
    @EnvironmentObject var buddyVM: BuddyViewModel
    @State private var selectedGame: MiniGame?
    
    let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Infos sessions
                HStack {
                    Text("🎮 Sessions : \(buddyVM.gameTracker.rewardedSessions)/\(DailyGameTracker.maxRewardedSessions)")
                        .font(BP.captionFont).foregroundStyle(.secondary)
                    Spacer()
                    Text("💎 \(buddyVM.gameTracker.gemsEarnedToday)/\(DailyGameTracker.maxGemsPerDay) aujourd'hui")
                        .font(BP.captionFont).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 4)
                
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(MiniGame.allCases) { game in
                        Button { selectedGame = game } label: {
                            gameCard(game)
                        }.buttonStyle(.plain)
                    }
                }
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .fullScreenCover(item: $selectedGame) { game in
            GamePlayView(game: game) { selectedGame = nil }
        }
    }
    
    private func gameCard(_ game: MiniGame) -> some View {
        VStack(spacing: 8) {
            Text(game.emoji).font(.system(size: 36))
            Text(game.displayName).font(BP.font(14, weight: .bold))
            Text(game.description).font(BP.font(10, weight: .medium)).foregroundStyle(.secondary).lineLimit(2).multilineTextAlignment(.center)
            HStack(spacing: 4) {
                Text("5-10💎").font(BP.font(10, weight: .semibold)).foregroundStyle(BP.purple)
            }
            // High score
            if let hs = buddyVM.highScores.first(where: { $0.gameType == game.rawValue }) {
                Text("Record: \(hs.score)").font(BP.font(9, weight: .medium)).foregroundStyle(BP.orange)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(BP.cardBG)
                .shadow(color: Color(hex: UInt(game.color, radix: 16) ?? 0xFF3D7F).opacity(0.15), radius: 8, y: 3)
        )
    }
}

// MARK: — Game Play Container

struct GamePlayView: View {
    let game: MiniGame
    let onDismiss: () -> Void
    @EnvironmentObject var buddyVM: BuddyViewModel
    @State private var score = 0
    @State private var isGameOver = false
    @State private var gemsWon = 0
    @State private var coinsWon = 0
    
    var body: some View {
        ZStack {
            BP.bgGradient.ignoresSafeArea()
            
            VStack {
                // Header
                HStack {
                    Button { onDismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28)).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(game.displayName).font(BP.headFont)
                    Spacer()
                    Text("\(score)").font(BP.font(20, weight: .bold)).foregroundStyle(BP.purple)
                }
                .padding()
                
                if isGameOver {
                    gameOverView
                } else {
                    // Game content
                    switch game {
                    case .memory:   MemoryGameView(score: $score, isGameOver: $isGameOver)
                    case .quiz:     QuizGameView(score: $score, isGameOver: $isGameOver)
                    case .reaction: ReactionGameView(score: $score, isGameOver: $isGameOver)
                    case .simon:    SimonGameView(score: $score, isGameOver: $isGameOver)
                    default:        GenericGameView(game: game, score: $score, isGameOver: $isGameOver)
                    }
                }
            }
        }
        .onChange(of: isGameOver) { _, over in
            if over { finishGame() }
        }
    }
    
    private func finishGame() {
        gemsWon = buddyVM.gameTracker.canEarnGems ? Int.random(in: game.rewardRange) : 0
        coinsWon = game.coinReward
        buddyVM.rewardForGame(score: score, game: game)
        HapticService.levelUp()
    }
    
    private var gameOverView: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("🏁").font(.system(size: 60))
            Text("Partie terminée !").font(BP.titleFont).foregroundStyle(BP.purple)
            Text("Score: \(score)").font(BP.font(28, weight: .bold))
            
            HStack(spacing: 20) {
                VStack {
                    Text("+\(gemsWon)").font(BP.font(20, weight: .bold))
                    Text("💎 Gemmes").font(BP.captionFont)
                }
                VStack {
                    Text("+\(coinsWon)").font(BP.font(20, weight: .bold))
                    Text("🪙 Coins").font(BP.captionFont)
                }
                VStack {
                    Text("+\(game.xpReward)").font(BP.font(20, weight: .bold))
                    Text("⭐ XP").font(BP.captionFont)
                }
            }
            .padding().background(BP.cardBG).clipShape(RoundedRectangle(cornerRadius: 16))
            
            if !buddyVM.gameTracker.canEarnGems {
                Text("Plafond de gemmes atteint pour aujourd'hui").font(BP.captionFont).foregroundStyle(.secondary)
            }
            
            Spacer()
            HStack(spacing: 16) {
                BPButton("Rejouer", gradient: BP.purpleGradient) {
                    score = 0; isGameOver = false
                }
                BPButton("Quitter", gradient: BP.pinkGradient) { onDismiss() }
            }
            .padding(.bottom, 40)
        }
    }
}

// MARK: — Memory Game

struct MemoryGameView: View {
    @Binding var score: Int
    @Binding var isGameOver: Bool
    @State private var state = MemoryGameState.newGame(difficulty: .normal)
    @State private var isProcessing = false
    
    let columns = [GridItem(.adaptive(minimum: 65), spacing: 8)]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Trouve les paires ! (\(state.matchedPairs)/\(state.totalPairs))").font(BP.font(14, weight: .semibold))
            
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(state.cards.indices, id: \.self) { i in
                    cardView(index: i)
                }
            }
            .padding()
        }
    }
    
    private func cardView(index: Int) -> some View {
        let card = state.cards[index]
        return Button {
            guard !isProcessing, !card.isFaceUp, !card.isMatched else { return }
            flipCard(index)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(card.isMatched ? BP.green.opacity(0.3) : card.isFaceUp ? .white : BP.purpleGradient)
                    .frame(height: 75)
                if card.isFaceUp || card.isMatched {
                    Text(card.emoji).font(.system(size: 28))
                } else {
                    Text("?").font(BP.font(24, weight: .bold)).foregroundStyle(.white)
                }
            }
            .animation(BP.springAnim, value: card.isFaceUp)
        }
    }
    
    private func flipCard(_ index: Int) {
        state.cards[index].isFaceUp = true
        HapticService.tap()
        
        if let first = state.firstFlipped {
            isProcessing = true
            state.moves += 1
            
            if state.cards[first].emoji == state.cards[index].emoji {
                state.cards[first].isMatched = true
                state.cards[index].isMatched = true
                state.matchedPairs += 1
                state.firstFlipped = nil
                score += 20
                HapticService.levelUp()
                isProcessing = false
                
                if state.isGameOver { isGameOver = true }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    state.cards[first].isFaceUp = false
                    state.cards[index].isFaceUp = false
                    state.firstFlipped = nil
                    isProcessing = false
                }
            }
        } else {
            state.firstFlipped = index
        }
    }
}

// MARK: — Quiz Game

struct QuizGameView: View {
    @Binding var score: Int
    @Binding var isGameOver: Bool
    @State private var questions = QuizQuestion.randomSet(count: 5)
    @State private var current = 0
    @State private var selectedAnswer: Int?
    @State private var showResult = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Question \(current + 1)/\(questions.count)")
                .font(BP.captionFont).foregroundStyle(.secondary)
            
            if current < questions.count {
                let q = questions[current]
                Text(q.question).font(BP.font(18, weight: .semibold)).multilineTextAlignment(.center).padding(.horizontal, 20)
                
                VStack(spacing: 10) {
                    ForEach(q.answers.indices, id: \.self) { i in
                        Button {
                            guard selectedAnswer == nil else { return }
                            selectedAnswer = i
                            showResult = true
                            if i == q.correctIndex { score += 20; HapticService.levelUp() }
                            else { HapticService.error() }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                selectedAnswer = nil; showResult = false
                                current += 1
                                if current >= questions.count { isGameOver = true }
                            }
                        } label: {
                            HStack {
                                Text(q.answers[i]).font(BP.font(15, weight: .medium))
                                Spacer()
                                if showResult && i == q.correctIndex { Text("✅") }
                                else if showResult && i == selectedAnswer { Text("❌") }
                            }
                            .padding()
                            .background(
                                showResult && i == q.correctIndex ? BP.green.opacity(0.2) :
                                    showResult && i == selectedAnswer ? BP.red.opacity(0.2) :
                                    BP.cardBG
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }.buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
            
            Spacer()
        }
        .padding(.top, 20)
    }
}

// MARK: — Reaction Game

struct ReactionGameView: View {
    @Binding var score: Int
    @Binding var isGameOver: Bool
    @State private var state = ReactionGameState()
    @State private var waitingForTap = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Round \(state.round + 1)/\(state.totalRounds)")
                .font(BP.captionFont).foregroundStyle(.secondary)
            
            if let time = state.reactionTime {
                Text(String(format: "%.0f ms", time * 1000))
                    .font(BP.font(32, weight: .bold))
                    .foregroundStyle(time < 0.3 ? BP.green : BP.orange)
            }
            
            Spacer()
            
            ZStack {
                Circle()
                    .fill(state.targetVisible ? BP.green : BP.red.opacity(0.3))
                    .frame(width: 180, height: 180)
                    .onTapGesture {
                        if state.targetVisible {
                            let reaction = Date().timeIntervalSince(state.targetAppearTime ?? Date())
                            state.reactionTime = reaction
                            state.times.append(reaction)
                            state.targetVisible = false
                            state.round += 1
                            score = state.score
                            HapticService.tap()
                            
                            if state.isGameOver { isGameOver = true }
                            else { scheduleNext() }
                        }
                    }
                
                Text(state.targetVisible ? "TAP !" : "Attends...")
                    .font(BP.font(20, weight: .bold))
                    .foregroundStyle(.white)
            }
            
            Spacer()
            
            if let avg = state.averageTime {
                Text(String(format: "Moyenne: %.0f ms", avg * 1000))
                    .font(BP.font(14, weight: .semibold)).foregroundStyle(.secondary)
            }
        }
        .onAppear { scheduleNext() }
    }
    
    private func scheduleNext() {
        let delay = Double.random(in: 1.5...4.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            state.targetVisible = true
            state.targetAppearTime = Date()
            HapticService.feed()
        }
    }
}

// MARK: — Simon Game

struct SimonGameView: View {
    @Binding var score: Int
    @Binding var isGameOver: Bool
    @State private var state = SimonGameState()
    @State private var highlightIndex: Int?
    
    let colors: [Color] = [.red, .blue, .green, .yellow]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Séquence: \(state.currentStep)")
                .font(BP.font(16, weight: .semibold))
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(0..<4, id: \.self) { i in
                    Button {
                        guard !state.isShowingSequence else { return }
                        playerTap(i)
                    } label: {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colors[i].opacity(highlightIndex == i ? 1 : 0.4))
                            .frame(height: 120)
                            .overlay(Text(SimonGameState.colors[i]).font(.system(size: 30)))
                            .animation(.easeOut(duration: 0.2), value: highlightIndex)
                    }
                }
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .padding(.top, 20)
        .onAppear { startRound() }
    }
    
    private func startRound() {
        state.nextRound()
        state.isShowingSequence = true
        
        for (i, colorIdx) in state.sequence.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.6 + 0.5) {
                highlightIndex = colorIdx
                HapticService.tap()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.6 + 0.9) {
                highlightIndex = nil
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(state.sequence.count) * 0.6 + 1) {
            state.isShowingSequence = false
        }
    }
    
    private func playerTap(_ index: Int) {
        highlightIndex = index
        HapticService.tap()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { highlightIndex = nil }
        
        state.playerInput.append(index)
        let pos = state.playerInput.count - 1
        
        if state.playerInput[pos] != state.sequence[pos] {
            state.isGameOver = true
            score = state.score
            isGameOver = true
            HapticService.error()
            return
        }
        
        if state.playerInput.count == state.sequence.count {
            state.score += 10
            score = state.score
            state.playerInput = []
            HapticService.levelUp()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { startRound() }
        }
    }
}

// MARK: — Generic Game (pour les jeux restants)

struct GenericGameView: View {
    let game: MiniGame
    @Binding var score: Int
    @Binding var isGameOver: Bool
    @State private var taps = 0
    @State private var timeLeft: Double = 15
    @State private var timer: Timer?
    
    var body: some View {
        VStack(spacing: 20) {
            Text(game.description).font(BP.font(16, weight: .semibold)).multilineTextAlignment(.center)
            
            Text(String(format: "%.1fs", timeLeft))
                .font(BP.font(28, weight: .bold))
                .foregroundStyle(timeLeft < 5 ? BP.red : BP.purple)
            
            Spacer()
            
            Button {
                taps += 1; score = taps * 5
                HapticService.tap()
            } label: {
                ZStack {
                    Circle()
                        .fill(BP.pinkGradient)
                        .frame(width: 160, height: 160)
                        .shadow(color: BP.pink.opacity(0.3), radius: 10)
                    VStack {
                        Text(game.emoji).font(.system(size: 50))
                        Text("\(taps)").font(BP.font(24, weight: .bold)).foregroundStyle(.white)
                    }
                }
            }
            
            Spacer()
            
            Text("Tape le plus vite possible !").font(BP.captionFont).foregroundStyle(.secondary)
        }
        .padding(.top, 20)
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                Task { @MainActor in
                    timeLeft -= 0.1
                    if timeLeft <= 0 {
                        timer?.invalidate()
                        isGameOver = true
                    }
                }
            }
        }
        .onDisappear { timer?.invalidate() }
    }
}
