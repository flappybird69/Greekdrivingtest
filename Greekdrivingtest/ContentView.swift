import SwiftUI

struct ContentView: View {
    @Environment(LanguageManager.self) private var lang
    @State private var selectedTab = 0
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("streakCount") private var streakCount = 0
    @AppStorage("streakLastTimestamp") private var streakLastTimestamp: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedTab) {
                HomeView(selectedTab: $selectedTab)
                    .tabItem { Label(lang.t("Αρχική", "Home"), systemImage: "house.fill") }
                    .tag(0)
                StudyView()
                    .tabItem { Label(lang.t("Μελέτη", "Study"), systemImage: "book.fill") }
                    .tag(1)
                TestView(selectedTab: $selectedTab)
                    .tabItem { Label(lang.t("Εξέταση", "Exam"), systemImage: "checkmark.circle.fill") }
                    .tag(2)
                StatsView()
                    .tabItem { Label(lang.t("Στατιστικά", "Stats"), systemImage: "chart.bar.fill") }
                    .tag(3)
                SettingsView()
                    .tabItem { Label(lang.t("Ρυθμίσεις", "Settings"), systemImage: "gearshape.fill") }
                    .tag(4)
            }
            .tint(.greekBlue)
            .fullScreenCover(isPresented: Binding(get: { !hasSeenOnboarding }, set: { _ in })) {
                OnboardingView()
            }
            .onAppear { updateStreak() }
        }
    }

    private func updateStreak() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let lastDay = cal.startOfDay(for: Date(timeIntervalSince1970: streakLastTimestamp))
        let diff = cal.dateComponents([.day], from: lastDay, to: today).day ?? 0

        switch diff {
        case 0: break
        case 1:
            streakCount += 1
            streakLastTimestamp = today.timeIntervalSince1970
        default:
            streakCount = 1
            streakLastTimestamp = today.timeIntervalSince1970
        }
    }
}

// MARK: - Onboarding

struct OnboardingView: View {
    @AppStorage("userName") private var userName = ""
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @Environment(LanguageManager.self) private var lang
    @State private var nameInput = ""
    @State private var showGreeting = false
    @FocusState private var focused: Bool

    var trimmed: String { nameInput.trimmingCharacters(in: .whitespaces) }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.greekBlue, .greekDark],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle().fill(Color.white.opacity(0.06)).frame(width: 320).offset(x: 160, y: -200)
            Circle().fill(Color.white.opacity(0.04)).frame(width: 220).offset(x: -120, y: 260)

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 32) {
                    Text("🇬🇷")
                        .font(.system(size: 80))

                    VStack(spacing: 10) {
                        Text(lang.t("Καλώς ήρθες!", "Welcome!"))
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(lang.t(
                            "Ετοιμάσου για την εξέταση ΚΟΚ",
                            "Get ready for the KOK theory exam"
                        ))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    }

                    VStack(spacing: 16) {
                        Text(lang.t("Πώς σε λένε;", "What's your name?"))
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.85))

                        TextField(lang.t("Το όνομά σου...", "Your name..."), text: $nameInput)
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 16).padding(.horizontal, 20)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal, 40)
                            .focused($focused)
                            .submitLabel(.done)
                            .onSubmit { confirm() }
                            .onChange(of: nameInput) { _, val in
                                withAnimation(.spring(response: 0.4)) {
                                    showGreeting = !val.trimmingCharacters(in: .whitespaces).isEmpty
                                }
                            }
                    }

                    if showGreeting {
                        VStack(spacing: 20) {
                            VStack(spacing: 6) {
                                Text(lang.t("Γεια σου, \(trimmed)! 🎉", "Hey, \(trimmed)! 🎉"))
                                    .font(.title2.bold())
                                    .foregroundStyle(.white)
                                Text(lang.t("Καλή επιτυχία στην εξέτασή σου!", "Good luck on your exam!"))
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.72))
                            }
                            .transition(.scale.combined(with: .opacity))

                            Button { confirm() } label: {
                                HStack(spacing: 10) {
                                    Text(lang.t("Ας ξεκινήσουμε!", "Let's go!"))
                                        .font(.headline.bold())
                                    Image(systemName: "arrow.right").font(.headline.bold())
                                }
                                .foregroundStyle(Color.greekBlue)
                                .padding(.horizontal, 36).padding(.vertical, 16)
                                .background(Color.white)
                                .clipShape(Capsule())
                                .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                }

                Spacer()

                Button {
                    userName = ""
                    hasSeenOnboarding = true
                } label: {
                    Text(lang.t("Παράλειψη", "Skip"))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.bottom, 44)
            }
        }
        .animation(.spring(response: 0.4), value: showGreeting)
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { focused = true } }
    }

    private func confirm() {
        if !trimmed.isEmpty { userName = trimmed }
        hasSeenOnboarding = true
    }
}
