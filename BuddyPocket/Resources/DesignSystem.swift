import SwiftUI

// ══════════════════════════════════════════════════════════════════
// DESIGN SYSTEM — Buddy Pocket
// Style : coloré, kawaii, tous âges
// ══════════════════════════════════════════════════════════════════

enum BP {
    // MARK: — Couleurs
    static let pink      = Color(hex: 0xFF3D7F)
    static let purple    = Color(hex: 0x7C3AED)
    static let blue      = Color(hex: 0x5DCDFF)
    static let mint      = Color(hex: 0x7FFFD4)
    static let yellow    = Color(hex: 0xFFE066)
    static let orange    = Color(hex: 0xFF9F43)
    static let coral     = Color(hex: 0xFF6B6B)
    static let green     = Color(hex: 0x2ECC71)
    static let red       = Color(hex: 0xE74C3C)
    
    static let bgGradient = LinearGradient(
        colors: [Color(hex: 0xFFE5EC), Color(hex: 0xE8D5FF), Color(hex: 0xD0F4FF)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    
    static let cardBG    = Color.white.opacity(0.95)
    static let cardRadius: CGFloat = 20
    
    // MARK: — Monnaies
    static let coinIcon  = "🪙"
    static let gemIcon   = "💎"
    
    // MARK: — Typographie (SF Rounded natif)
    static func font(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    
    static let titleFont   = font(28, weight: .bold)
    static let headFont    = font(20, weight: .semibold)
    static let bodyFont    = font(15, weight: .regular)
    static let captionFont = font(12, weight: .medium)
    static let smallFont   = font(10, weight: .regular)
    
    // MARK: — Animations
    static let springAnim  = Animation.spring(response: 0.5, dampingFraction: 0.7)
    static let bounceAnim  = Animation.spring(response: 0.4, dampingFraction: 0.5)
    static let gentleAnim  = Animation.easeInOut(duration: 0.3)
    static let floatAnim   = Animation.easeInOut(duration: 3).repeatForever(autoreverses: true)
    
    // MARK: — Dégradés utilitaires
    static let pinkGradient = LinearGradient(
        colors: [pink, coral], startPoint: .leading, endPoint: .trailing
    )
    static let purpleGradient = LinearGradient(
        colors: [purple, pink], startPoint: .leading, endPoint: .trailing
    )
    static let goldGradient = LinearGradient(
        colors: [yellow, orange], startPoint: .leading, endPoint: .trailing
    )
    static let gemGradient = LinearGradient(
        colors: [purple, blue], startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

// MARK: — Color hex init
extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8)  & 0xFF) / 255,
            blue:  Double( hex        & 0xFF) / 255,
            opacity: alpha
        )
    }
}

// MARK: — Composants réutilisables

struct BPCard<Content: View>: View {
    let content: () -> Content
    init(@ViewBuilder content: @escaping () -> Content) { self.content = content }
    var body: some View {
        content()
            .padding(16)
            .background(BP.cardBG)
            .clipShape(RoundedRectangle(cornerRadius: BP.cardRadius, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }
}

struct BPButton: View {
    let title: String
    let icon: String?
    let gradient: LinearGradient
    let action: () -> Void
    
    init(_ title: String, icon: String? = nil, gradient: LinearGradient = BP.pinkGradient, action: @escaping () -> Void) {
        self.title = title; self.icon = icon; self.gradient = gradient; self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon { Text(icon) }
                Text(title).font(BP.font(14, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(gradient)
            .clipShape(Capsule())
            .shadow(color: BP.pink.opacity(0.3), radius: 6, y: 3)
        }
    }
}

struct BPStatBar: View {
    let label: String
    let icon: String
    let value: Double   // 0...1
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Text(icon).font(.system(size: 16))
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(BP.captionFont).foregroundStyle(.secondary)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(color.opacity(0.15)).frame(height: 8)
                        Capsule().fill(color)
                            .frame(width: max(4, geo.size.width * value), height: 8)
                            .animation(BP.springAnim, value: value)
                    }
                }
                .frame(height: 8)
            }
            Text("\(Int(value * 100))%")
                .font(BP.font(11, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 36, alignment: .trailing)
        }
    }
}

struct BPBadge: View {
    let text: String
    let color: Color
    var body: some View {
        Text(text)
            .font(BP.font(10, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color)
            .clipShape(Capsule())
    }
}

struct BPCoinDisplay: View {
    let coins: Int
    let gems: Int
    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 3) {
                Text(BP.coinIcon).font(.system(size: 12))
                Text("\(coins)").font(BP.font(12, weight: .bold))
            }
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(BP.goldGradient)
            .clipShape(Capsule())
            
            HStack(spacing: 3) {
                Text(BP.gemIcon).font(.system(size: 12))
                Text("\(gems)").font(BP.font(12, weight: .bold))
            }
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(BP.gemGradient)
            .clipShape(Capsule())
            .foregroundStyle(.white)
        }
    }
}

// MARK: — Modifiers

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 6
    var shakesPerUnit = 3
    var animatableData: CGFloat
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)), y: 0
        ))
    }
}

struct PulseModifier: ViewModifier {
    @State private var isPulsing = false
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear { isPulsing = true }
    }
}

extension View {
    func pulse() -> some View { modifier(PulseModifier()) }
}
