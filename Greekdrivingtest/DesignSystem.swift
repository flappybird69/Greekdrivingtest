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
    private let shadowColor = Color.black.opacity(0.06)
    private let strokeColor = Color.primary.opacity(0.05)
    func body(content: Content) -> some View {
        content
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: shadowColor, radius: 12, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(strokeColor, lineWidth: 0.5)
            )
    }
}

extension View {
    func cardStyle(cornerRadius: CGFloat = 16) -> some View {
        modifier(CardModifier(cornerRadius: cornerRadius))
    }

    /// Constrains content width for readable layouts on iPad while leaving iPhone untouched.
    func iPadReadableWidth(_ maxWidth: CGFloat = 700) -> some View {
        self
            .frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity, alignment: .center)
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

// MARK: - Confetti

struct ConfettiView: View {
    private let colors: [Color] = [.passGreen, .catBlue, .catOrange, .catPurple, .greekGold, .catRed, .white]
    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(0..<55, id: \.self) { i in
                ConfettiParticle(
                    color: colors[i % colors.count],
                    xStart: CGFloat(i * 41 % 380) - 190,
                    xDrift: CGFloat(i * 23 % 140) - 70,
                    size: CGFloat(6 + i % 7),
                    delay: Double(i % 18) * 0.045,
                    animate: animate
                )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { animate = true }
        }
    }
}

private struct ConfettiParticle: View {
    let color: Color
    let xStart: CGFloat
    let xDrift: CGFloat
    let size: CGFloat
    let delay: Double
    let animate: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.25)
            .fill(color)
            .frame(width: size, height: size * 1.6)
            .offset(x: animate ? xStart + xDrift : xStart,
                    y: animate ? -520 : 60)
            .opacity(animate ? 0 : 0.92)
            .rotationEffect(.degrees(animate ? Double(Int(xStart) * 3 % 360) : 0))
            .animation(
                .easeOut(duration: 1.1 + delay * 0.4).delay(delay),
                value: animate
            )
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
