import SwiftUI

struct SplashScreenView: View {
    @State private var progress: CGFloat = 0
    @State private var pulseScale: CGFloat = 0.8
    @State private var glowOpacity: Double = 0
    @State private var currentTipIndex = 0
    @State private var tipOpacity: Double = 1
    @State private var circleOffset: [CGSize] = [
        CGSize(width: -120, height: -180),
        CGSize(width: 140, height: 200),
        CGSize(width: -80, height: 260),
        CGSize(width: 160, height: -120)
    ]
    @State private var circleScale: [CGFloat] = [1, 1, 1, 1]
    @State private var tipTimer: Timer?

    let onFinish: () -> Void

    private let iconTeal = Color(red: 0 / 255, green: 128 / 255, blue: 128 / 255)
    private let iconBlue = Color(red: 0 / 255, green: 64 / 255, blue: 128 / 255)
    private let iconPurple = Color(red: 64 / 255, green: 0 / 255, blue: 64 / 255)

    private let tips: [(el: String, en: String)] = [
        ("Πάντα να φοράτε ζώνη ασφαλείας", "Always wear your seatbelt"),
        ("Τηρείτε τα όρια ταχύτητας", "Observe speed limits"),
        ("Μην οδηγείτε υπό την επήρεια αλκοόλ", "Don't drive under the influence"),
        ("Δώστε προτεραιότητα στους πεζούς", "Give way to pedestrians"),
        ("Ελέγχετε τους καθρέπτες σας τακτικά", "Check your mirrors regularly"),
        ("Διατηρείτε ασφαλή απόσταση", "Keep a safe distance"),
        ("Σέβεστε τα σήματα κυκλοφορίας", "Respect traffic signs"),
        ("Μην χρησιμοποιείτε κινητό ενώ οδηγείτε", "Don't use your phone while driving"),
        ("Κάντε διάλειμμα σε μεγάλα ταξίδια", "Take breaks on long trips"),
        ("Οδηγείτε αμυντικά", "Drive defensively")
    ]

    var body: some View {
        ZStack {
            backgroundLayer
            floatingCircles
            contentLayer
        }
        .onAppear(perform: startAnimations)
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        LinearGradient(
            colors: [iconBlue, iconTeal, iconPurple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Floating Circles

    private var floatingCircles: some View {
        ForEach(0..<4, id: \.self) { i in
            Circle()
                .fill(.white.opacity(i == 0 ? 0.05 : i == 1 ? 0.07 : i == 2 ? 0.04 : 0.06))
                .frame(width: CGFloat(160 + i * 80))
                .offset(circleOffset[i])
                .scaleEffect(circleScale[i])
                .blur(radius: CGFloat(20 + i * 10))
        }
    }

    // MARK: - Content

    private var contentLayer: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 50)

            welcomeSection

            Spacer()

            logoSection

            Spacer()

            tipsSection

            Spacer()

            bottomSection
                .padding(.horizontal, 48)
                .padding(.bottom, 50)
        }
    }

    // MARK: - Welcome

    private var welcomeSection: some View {
        Text("Καλωσήρθες, μελλοντικέ οδηγέ!")
            .font(.system(size: 22, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .opacity(glowOpacity)
    }

    // MARK: - Logo

    private var logoSection: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 180)
                .blur(radius: 30)
                .scaleEffect(pulseScale * 1.4)
                .opacity(glowOpacity)

            Circle()
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.3), .white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: 150)
                .scaleEffect(pulseScale)
                .opacity(glowOpacity * 0.6)

            Circle()
                .fill(.white.opacity(0.10))
                .frame(width: 130)
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.15), lineWidth: 1)
                )

            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .scaleEffect(pulseScale)
        }
    }

    // MARK: - Tips

    private var tipsSection: some View {
        VStack(spacing: 6) {
            Image(systemName: "lightbulb.fill")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.35))

            Text(tips[currentTipIndex].el)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .opacity(tipOpacity)

            Text(tips[currentTipIndex].en)
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.40))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .opacity(tipOpacity)
        }
        .frame(height: 80)
    }

    // MARK: - Bottom

    private var bottomSection: some View {
        VStack(spacing: 16) {
            loadingBar
            Text("Powered by Sephiance Inc.")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.45))
                .tracking(2)
        }
    }

    private var loadingBar: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.12))
                    .frame(height: 4)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0/255, green: 200/255, blue: 200/255),
                                Color(red: 0/255, green: 255/255, blue: 200/255),
                                .white
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(4, progress * 260), height: 4)
                    .animation(.smooth(duration: 0.3), value: progress)
            }
            .frame(width: 260)
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            pulseScale = 1.05
        }

        withAnimation(.easeOut(duration: 0.8)) {
            glowOpacity = 1
        }

        for i in 0..<4 {
            withAnimation(
                .easeInOut(duration: Double(3 + i * 2))
                .repeatForever(autoreverses: true)
                .delay(Double(i) * 0.5)
            ) {
                circleScale[i] = 0.7 + CGFloat(i) * 0.15
                circleOffset[i] = CGSize(
                    width: circleOffset[i].width + CGFloat(i % 2 == 0 ? 20 : -20),
                    height: circleOffset[i].height + CGFloat(i < 2 ? 30 : -30)
                )
            }
        }

        // Tip cycling
        let tipInterval = 2.0
        let totalTips = tips.count
        tipTimer = Timer.scheduledTimer(withTimeInterval: tipInterval, repeats: true) { _ in
            withAnimation(.easeOut(duration: 0.2)) { tipOpacity = 0 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                currentTipIndex = (currentTipIndex + 1) % totalTips
                withAnimation(.easeIn(duration: 0.3)) { tipOpacity = 1 }
            }
        }

        // Progress bar
        let steps = 40
        for step in 1...steps {
            let delay = Double(step) * (4.0 / Double(steps))
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.smooth(duration: 0.08)) {
                    progress = CGFloat(step) / CGFloat(steps)
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            tipTimer?.invalidate()
            tipTimer = nil
            withAnimation(.easeOut(duration: 0.6)) {
                glowOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                onFinish()
            }
        }
    }
}
