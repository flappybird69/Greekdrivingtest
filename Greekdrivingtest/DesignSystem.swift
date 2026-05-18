import SwiftUI

// MARK: - Brand Colors (inspired by logo: deep teal → purple, neon cyan glow)
extension Color {
    static let greekBlue    = Color(red: 0.11, green: 0.33, blue: 0.47)   // #1C5478 – logo teal
    static let greekDark    = Color(red: 0.20, green: 0.06, blue: 0.33)   // #331055 – logo purple
    static let greekGold    = Color(red: 0.00, green: 0.83, blue: 0.93)   // #00D4ED – neon cyan glow
    static let catBlue      = Color(red: 0.00, green: 0.75, blue: 0.88)   // #00BFE0 – logo cyan
    static let catOrange    = Color(red: 0.95, green: 0.52, blue: 0.15)   // kept for contrast
    static let catPurple    = Color(red: 0.72, green: 0.20, blue: 0.88)   // #B833E0 – logo magenta-purple
    static let catGreen     = Color(red: 0.18, green: 0.72, blue: 0.42)
    static let catRed       = Color(red: 0.88, green: 0.22, blue: 0.25)
    static let passGreen    = Color(red: 0.16, green: 0.74, blue: 0.40)
    static let failRed      = Color(red: 0.88, green: 0.22, blue: 0.25)
}

// MARK: - Card Modifier
struct CardModifier: ViewModifier {
    var cornerRadius: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 0.5)
            )
    }
}

extension View {
    func cardStyle(cornerRadius: CGFloat = 16) -> some View {
        modifier(CardModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Category Color Helper
func categoryColor(_ category: QuestionCategory) -> Color {
    switch category {
    case .signs:     return .catBlue
    case .rules:     return .catOrange
    case .behavior:  return .catPurple
    case .vehicle:   return .catGreen
    case .firstAid:  return .catRed
    }
}

// MARK: - Gradient Background
struct AppBackground: View {
    var body: some View {
        ZStack {
            // Subtle teal wash from top-left (logo top)
            LinearGradient(
                colors: [Color.greekBlue.opacity(0.10), Color.clear],
                startPoint: .topLeading, endPoint: .center
            )
            // Purple glow from bottom-right (logo bottom)
            LinearGradient(
                colors: [Color.clear, Color.greekDark.opacity(0.08)],
                startPoint: .center, endPoint: .bottomTrailing
            )
            // Neon cyan orb – top right (mirrors logo's star sparkle)
            Circle()
                .fill(Color.greekGold.opacity(0.12))
                .frame(width: 320, height: 320)
                .blur(radius: 90)
                .offset(x: 140, y: -180)
            // Purple orb – bottom left
            Circle()
                .fill(Color.catPurple.opacity(0.09))
                .frame(width: 280, height: 280)
                .blur(radius: 70)
                .offset(x: -120, y: 220)
        }
        .ignoresSafeArea()
    }
}
