import UIKit

// ══════════════════════════════════════════════════════════════════
// HAPTIC SERVICE — Retour haptique contextuel
// ══════════════════════════════════════════════════════════════════

enum HapticService {
    // Caresse → léger
    static func pet() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    // Nourrissage → moyen
    static func feed() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    // Level up → succès
    static func levelUp() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    // Victoire battle → heavy × 3 en rythme
    static func battleWin() {
        let gen = UIImpactFeedbackGenerator(style: .heavy)
        gen.prepare()
        gen.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { gen.impactOccurred() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) { gen.impactOccurred() }
    }
    
    // Stat critique → warning
    static func criticalStat() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
    
    // Achat boutique
    static func purchase() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    // Tap basique
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.6)
    }
    
    // Erreur
    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
    
    // Sélection
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
