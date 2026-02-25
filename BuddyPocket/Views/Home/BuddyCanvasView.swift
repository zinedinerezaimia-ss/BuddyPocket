import SwiftUI

// ══════════════════════════════════════════════════════════════════
// BUDDY CANVAS VIEW — Rendu du Buddy en layers SwiftUI
// ViewBox standard 200×250pt avec ancres normalisées
// ══════════════════════════════════════════════════════════════════

struct BuddyCanvasView: View {
    let buddy: Buddy
    var size: CGFloat = 200
    var animated: Bool = true
    
    @State private var floatOffset: CGFloat = 0
    
    private var scale: CGFloat { size / 200 }
    private var anchors: AnchorOffsets { buddy.bodyType.anchors }
    
    var body: some View {
        ZStack {
            // Layer 1: Corps
            bodyShape
            
            // Layer 2: Pantalon/bas (si pas de costume)
            if buddy.costume == nil, buddy.bottomClothing != nil {
                bottomLayer
            }
            
            // Layer 3: Haut (si pas de costume)
            if buddy.costume == nil, buddy.topClothing != nil {
                topLayer
            }
            
            // Layer 4: Costume (remplace haut+bas)
            if buddy.costume != nil {
                costumeLayer
            }
            
            // Layer 5: Yeux
            eyesLayer
            
            // Layer 6: Accessoire de tête
            if buddy.headAccessory != nil {
                headAccessoryLayer
            }
        }
        .frame(width: size, height: size * 1.25)
        .offset(y: animated ? floatOffset : 0)
        .onAppear {
            if animated {
                withAnimation(BP.floatAnim) { floatOffset = -8 }
            }
        }
    }
    
    // MARK: — Corps (Path)
    
    @ViewBuilder
    private var bodyShape: some View {
        let color = buddy.bodyColor.color
        
        Canvas { context, canvasSize in
            let w = canvasSize.width
            let h = canvasSize.height
            
            var path = Path()
            
            switch buddy.bodyType {
            case .blob:
                path.addEllipse(in: CGRect(x: w * 0.15, y: h * 0.1, width: w * 0.7, height: h * 0.75))
                
            case .chat:
                // Corps arrondi + oreilles
                path.addEllipse(in: CGRect(x: w * 0.18, y: h * 0.2, width: w * 0.64, height: h * 0.6))
                // Oreille gauche
                path.move(to: CGPoint(x: w * 0.25, y: h * 0.22))
                path.addLine(to: CGPoint(x: w * 0.18, y: h * 0.05))
                path.addLine(to: CGPoint(x: w * 0.38, y: h * 0.18))
                path.closeSubpath()
                // Oreille droite
                path.move(to: CGPoint(x: w * 0.75, y: h * 0.22))
                path.addLine(to: CGPoint(x: w * 0.82, y: h * 0.05))
                path.addLine(to: CGPoint(x: w * 0.62, y: h * 0.18))
                path.closeSubpath()
                
            case .lapin:
                path.addEllipse(in: CGRect(x: w * 0.2, y: h * 0.25, width: w * 0.6, height: h * 0.55))
                // Oreilles longues
                path.addRoundedRect(in: CGRect(x: w * 0.25, y: h * -0.05, width: w * 0.12, height: h * 0.35), cornerSize: CGSize(width: 8, height: 8))
                path.addRoundedRect(in: CGRect(x: w * 0.63, y: h * -0.05, width: w * 0.12, height: h * 0.35), cornerSize: CGSize(width: 8, height: 8))
                
            case .chien:
                path.addEllipse(in: CGRect(x: w * 0.18, y: h * 0.18, width: w * 0.64, height: h * 0.62))
                // Oreilles tombantes
                path.addEllipse(in: CGRect(x: w * 0.08, y: h * 0.15, width: w * 0.18, height: h * 0.3))
                path.addEllipse(in: CGRect(x: w * 0.74, y: h * 0.15, width: w * 0.18, height: h * 0.3))
                
            case .fantome:
                path.move(to: CGPoint(x: w * 0.2, y: h * 0.85))
                path.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.08),
                              control1: CGPoint(x: w * 0.15, y: h * 0.4),
                              control2: CGPoint(x: w * 0.2, y: h * 0.08))
                path.addCurve(to: CGPoint(x: w * 0.8, y: h * 0.85),
                              control1: CGPoint(x: w * 0.8, y: h * 0.08),
                              control2: CGPoint(x: w * 0.85, y: h * 0.4))
                // Bas ondulé
                path.addCurve(to: CGPoint(x: w * 0.65, y: h * 0.78),
                              control1: CGPoint(x: w * 0.78, y: h * 0.9),
                              control2: CGPoint(x: w * 0.7, y: h * 0.75))
                path.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.85),
                              control1: CGPoint(x: w * 0.6, y: h * 0.82),
                              control2: CGPoint(x: w * 0.55, y: h * 0.88))
                path.addCurve(to: CGPoint(x: w * 0.35, y: h * 0.78),
                              control1: CGPoint(x: w * 0.45, y: h * 0.82),
                              control2: CGPoint(x: w * 0.4, y: h * 0.75))
                path.addCurve(to: CGPoint(x: w * 0.2, y: h * 0.85),
                              control1: CGPoint(x: w * 0.3, y: h * 0.82),
                              control2: CGPoint(x: w * 0.22, y: h * 0.9))
                path.closeSubpath()
                
            case .panda:
                path.addEllipse(in: CGRect(x: w * 0.17, y: h * 0.15, width: w * 0.66, height: h * 0.65))
                // Oreilles rondes
                path.addEllipse(in: CGRect(x: w * 0.15, y: h * 0.08, width: w * 0.18, height: h * 0.18))
                path.addEllipse(in: CGRect(x: w * 0.67, y: h * 0.08, width: w * 0.18, height: h * 0.18))
                
            case .dragon:
                path.addEllipse(in: CGRect(x: w * 0.15, y: h * 0.15, width: w * 0.7, height: h * 0.65))
                // Cornes
                path.move(to: CGPoint(x: w * 0.3, y: h * 0.18))
                path.addLine(to: CGPoint(x: w * 0.22, y: h * 0.02))
                path.addLine(to: CGPoint(x: w * 0.38, y: h * 0.14))
                path.closeSubpath()
                path.move(to: CGPoint(x: w * 0.7, y: h * 0.18))
                path.addLine(to: CGPoint(x: w * 0.78, y: h * 0.02))
                path.addLine(to: CGPoint(x: w * 0.62, y: h * 0.14))
                path.closeSubpath()
                
            case .ours:
                path.addEllipse(in: CGRect(x: w * 0.15, y: h * 0.18, width: w * 0.7, height: h * 0.62))
                path.addEllipse(in: CGRect(x: w * 0.13, y: h * 0.1, width: w * 0.16, height: h * 0.16))
                path.addEllipse(in: CGRect(x: w * 0.71, y: h * 0.1, width: w * 0.16, height: h * 0.16))
                
            case .renard:
                // Corps arrondi + oreilles pointues
                path.addEllipse(in: CGRect(x: w * 0.18, y: h * 0.2, width: w * 0.64, height: h * 0.6))
                path.move(to: CGPoint(x: w * 0.22, y: h * 0.22))
                path.addLine(to: CGPoint(x: w * 0.15, y: h * 0.02))
                path.addLine(to: CGPoint(x: w * 0.38, y: h * 0.18))
                path.closeSubpath()
                path.move(to: CGPoint(x: w * 0.78, y: h * 0.22))
                path.addLine(to: CGPoint(x: w * 0.85, y: h * 0.02))
                path.addLine(to: CGPoint(x: w * 0.62, y: h * 0.18))
                path.closeSubpath()
                
            case .licorne:
                path.addEllipse(in: CGRect(x: w * 0.18, y: h * 0.2, width: w * 0.64, height: h * 0.6))
                // Corne
                path.move(to: CGPoint(x: w * 0.43, y: h * 0.22))
                path.addLine(to: CGPoint(x: w * 0.5, y: h * -0.02))
                path.addLine(to: CGPoint(x: w * 0.57, y: h * 0.22))
                path.closeSubpath()
                
            case .alien:
                // Tête plus large en haut
                path.addEllipse(in: CGRect(x: w * 0.12, y: h * 0.08, width: w * 0.76, height: h * 0.72))
                
            case .slime:
                // Forme organique qui s'étale
                path.move(to: CGPoint(x: w * 0.15, y: h * 0.8))
                path.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.15),
                              control1: CGPoint(x: w * 0.1, y: h * 0.5),
                              control2: CGPoint(x: w * 0.25, y: h * 0.15))
                path.addCurve(to: CGPoint(x: w * 0.85, y: h * 0.8),
                              control1: CGPoint(x: w * 0.75, y: h * 0.15),
                              control2: CGPoint(x: w * 0.9, y: h * 0.5))
                path.addQuadCurve(to: CGPoint(x: w * 0.15, y: h * 0.8),
                                  control: CGPoint(x: w * 0.5, y: h * 0.88))
                path.closeSubpath()
                
            default:
                // Corps par défaut (arrondi)
                path.addRoundedRect(in: CGRect(x: w * 0.15, y: h * 0.1, width: w * 0.7, height: h * 0.75),
                                    cornerSize: CGSize(width: w * 0.25, height: h * 0.25))
            }
            
            context.fill(path, with: .color(color))
            // Léger highlight
            let highlight = path.applying(CGAffineTransform(scaleX: 0.85, y: 0.7).translatedBy(x: w * 0.05, y: h * 0.04))
            context.fill(highlight, with: .color(.white.opacity(0.12)))
            
        }
        .frame(width: size, height: size * 1.25)
    }
    
    // MARK: — Yeux
    
    @ViewBuilder
    private var eyesLayer: some View {
        let eyeY = (size * 1.25 * 0.34) + (anchors.eyeY * scale)
        let spacing = size * 0.2
        
        HStack(spacing: spacing) {
            singleEye(isLeft: true)
            if buddy.eyeType != .cyclope {
                singleEye(isLeft: false)
            }
        }
        .position(x: size / 2, y: eyeY)
    }
    
    @ViewBuilder
    private func singleEye(isLeft: Bool) -> some View {
        let eyeSize = size * 0.12
        
        switch buddy.eyeType {
        case .normal:
            Circle().fill(.white).frame(width: eyeSize, height: eyeSize)
                .overlay(Circle().fill(.black).frame(width: eyeSize * 0.5))
                .overlay(Circle().fill(.white).frame(width: eyeSize * 0.2).offset(x: -2, y: -2))
                
        case .amande:
            Ellipse().fill(.white).frame(width: eyeSize * 1.3, height: eyeSize * 0.8)
                .overlay(Circle().fill(.black).frame(width: eyeSize * 0.4))
                
        case .endormi:
            RoundedRectangle(cornerRadius: 2).fill(.black)
                .frame(width: eyeSize, height: eyeSize * 0.15)
                
        case .coeur:
            Text("❤️").font(.system(size: eyeSize * 0.8))
            
        case .etoile:
            Text("⭐").font(.system(size: eyeSize * 0.8))
            
        case .croix:
            Text("✕").font(BP.font(eyeSize * 0.7, weight: .bold)).foregroundStyle(.black)
            
        case .spirale:
            Text("🌀").font(.system(size: eyeSize * 0.8))
            
        case .trait:
            Rectangle().fill(.black).frame(width: eyeSize * 0.8, height: eyeSize * 0.12)
            
        case .pixel:
            // Grille 3×3 pixel
            VStack(spacing: 1) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 1) {
                        ForEach(0..<3, id: \.self) { col in
                            Rectangle().fill((row == 1 && col == 1) ? Color.white : Color.black)
                                .frame(width: eyeSize * 0.22, height: eyeSize * 0.22)
                        }
                    }
                }
            }
            
        case .cyclope:
            Circle().fill(.white).frame(width: eyeSize * 1.8, height: eyeSize * 1.8)
                .overlay(Circle().fill(.black).frame(width: eyeSize * 0.9))
                .overlay(Circle().fill(.white).frame(width: eyeSize * 0.3).offset(x: -3, y: -3))
                
        case .heterochromie:
            Circle().fill(.white).frame(width: eyeSize, height: eyeSize)
                .overlay(Circle().fill(isLeft ? .blue : .green).frame(width: eyeSize * 0.5))
                .overlay(Circle().fill(.black).frame(width: eyeSize * 0.25))
                
        case .colere:
            ZStack {
                Circle().fill(.white).frame(width: eyeSize, height: eyeSize)
                    .overlay(Circle().fill(.black).frame(width: eyeSize * 0.5))
                Rectangle().fill(buddy.bodyColor.color)
                    .frame(width: eyeSize * 1.2, height: eyeSize * 0.25)
                    .rotationEffect(.degrees(isLeft ? -15 : 15))
                    .offset(y: -eyeSize * 0.35)
            }
            
        case .pleurant:
            VStack(spacing: 1) {
                Circle().fill(.white).frame(width: eyeSize, height: eyeSize)
                    .overlay(Circle().fill(.black).frame(width: eyeSize * 0.5))
                Text("💧").font(.system(size: eyeSize * 0.4))
            }
            
        case .amoureux:
            Text("😍").font(.system(size: eyeSize * 0.9))
            
        case .lunettes:
            ZStack {
                Circle().stroke(.gray, lineWidth: 2).frame(width: eyeSize * 1.3, height: eyeSize * 1.3)
                Circle().fill(.white.opacity(0.3)).frame(width: eyeSize * 1.2, height: eyeSize * 1.2)
                Circle().fill(.black).frame(width: eyeSize * 0.4)
            }
            
        default:
            Circle().fill(.white).frame(width: eyeSize, height: eyeSize)
                .overlay(Circle().fill(.black).frame(width: eyeSize * 0.5))
        }
    }
    
    // MARK: — Vêtements (layers simplifiés avec emojis/formes)
    
    private var topLayer: some View {
        let clothesY = (size * 1.25 * 0.56) + (anchors.clothesY * scale)
        let clothesW = size * 0.52 * anchors.clothesScale
        
        return RoundedRectangle(cornerRadius: 6)
            .fill(clothingColor(buddy.topClothing))
            .frame(width: clothesW, height: size * 0.22)
            .overlay(
                Text(clothingEmoji(buddy.topClothing))
                    .font(.system(size: size * 0.08))
            )
            .position(x: size / 2, y: clothesY)
    }
    
    private var bottomLayer: some View {
        let pantsY = (size * 1.25 * 0.7) + (anchors.clothesY * scale)
        let pantsW = size * 0.45 * anchors.clothesScale
        
        return RoundedRectangle(cornerRadius: 4)
            .fill(clothingColor(buddy.bottomClothing))
            .frame(width: pantsW, height: size * 0.18)
            .position(x: size / 2, y: pantsY)
    }
    
    private var costumeLayer: some View {
        let costumeY = (size * 1.25 * 0.6) + (anchors.clothesY * scale)
        let costumeW = size * 0.55 * anchors.clothesScale
        
        return RoundedRectangle(cornerRadius: 8)
            .fill(costumeGradient)
            .frame(width: costumeW, height: size * 0.38)
            .overlay(
                Text(costumeEmoji)
                    .font(.system(size: size * 0.12))
            )
            .position(x: size / 2, y: costumeY)
    }
    
    private var headAccessoryLayer: some View {
        let hatY = (size * 1.25 * 0.08) + (anchors.hatY * scale)
        
        return Text(accessoryEmoji)
            .font(.system(size: size * 0.2))
            .position(x: size / 2, y: hatY)
    }
    
    // MARK: — Helpers couleurs/emojis
    
    private func clothingColor(_ id: String?) -> Color {
        guard let id else { return .clear }
        if id.contains("black") { return Color(hex: 0x2C2C2C) }
        if id.contains("white") { return .white.opacity(0.9) }
        if id.contains("hoodie") || id.contains("jogger") { return Color(hex: 0x808080) }
        if id.contains("pink") || id.contains("rose") { return Color(hex: 0xFF69B4) }
        if id.contains("denim") || id.contains("jean") { return Color(hex: 0x4169E1) }
        if id.contains("sport") { return Color(hex: 0x2ECC71) }
        return Color(hex: 0x6B7B8D)
    }
    
    private func clothingEmoji(_ id: String?) -> String {
        guard let id else { return "" }
        let item = ItemCatalog.allItems(for: buddy.gender).first(where: { $0.id == id })
        return item?.emoji ?? "👕"
    }
    
    private var costumeEmoji: String {
        guard let id = buddy.costume else { return "" }
        let item = ItemCatalog.costumes(for: buddy.gender).first(where: { $0.id == id })
        return item?.emoji ?? "🎭"
    }
    
    private var costumeGradient: LinearGradient {
        if buddy.costume?.contains("psg") ?? false { return LinearGradient(colors: [.blue, .red], startPoint: .top, endPoint: .bottom) }
        if buddy.costume?.contains("batman") ?? false { return LinearGradient(colors: [.black, .gray], startPoint: .top, endPoint: .bottom) }
        if buddy.costume?.contains("ramadan") ?? false { return LinearGradient(colors: [Color(hex: 0x006400), .white], startPoint: .top, endPoint: .bottom) }
        return LinearGradient(colors: [BP.purple.opacity(0.7), BP.pink.opacity(0.7)], startPoint: .top, endPoint: .bottom)
    }
    
    private var accessoryEmoji: String {
        guard let id = buddy.headAccessory else { return "" }
        let allAcc = ItemCatalog.headAccessories(for: buddy.gender) + ItemCatalog.premiumHeadAccessories
        return allAcc.first(where: { $0.id == id })?.emoji ?? "🎩"
    }
}

// MARK: — Preview miniature (pour listes, profils, etc.)

struct BuddyMiniView: View {
    let buddy: Buddy
    var size: CGFloat = 60
    
    var body: some View {
        BuddyCanvasView(buddy: buddy, size: size, animated: false)
            .frame(width: size, height: size * 1.25)
            .scaleEffect(0.8)
            .clipShape(Circle())
            .background(
                Circle().fill(buddy.bodyColor.color.opacity(0.15))
            )
    }
}
