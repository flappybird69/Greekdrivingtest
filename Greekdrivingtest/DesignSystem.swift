import SwiftUI

// MARK: - Brand Colors
extension Color {
    static let greekBlue    = Color(red: 0.00, green: 0.36, blue: 0.67)   // #005BAC
    static let greekDark    = Color(red: 0.00, green: 0.22, blue: 0.44)
    static let greekGold    = Color(red: 0.95, green: 0.78, blue: 0.22)
    static let catBlue      = Color(red: 0.20, green: 0.45, blue: 0.90)
    static let catOrange    = Color(red: 0.95, green: 0.52, blue: 0.15)
    static let catPurple    = Color(red: 0.58, green: 0.32, blue: 0.90)
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
            .shadow(color: .black.opacity(0.07), radius: 10, x: 0, y: 4)
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
        LinearGradient(
            colors: [Color.greekBlue.opacity(0.12), Color.clear],
            startPoint: .top, endPoint: .center
        )
        .ignoresSafeArea()
    }
}
