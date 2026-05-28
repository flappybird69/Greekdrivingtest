import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(StoreKitManager.self) private var store
    @Environment(LanguageManager.self) private var lang

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.greekBlue, .greekDark],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle().fill(Color.white.opacity(0.06)).frame(width: 300).offset(x: 160, y: -260)
            Circle().fill(Color.greekGold.opacity(0.18)).frame(width: 200).blur(radius: 60).offset(x: 120, y: -180)
            Circle().fill(Color.catPurple.opacity(0.12)).frame(width: 260).blur(radius: 80).offset(x: -130, y: 340)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: 48)
                    headerSection
                    Spacer(minLength: 24)
                    featuresCard
                    Spacer(minLength: 24)
                    subscriptionOption
                    Spacer(minLength: 12)
                    lifetimeOption
                    Spacer(minLength: 24)
                    restoreSection
                    Spacer(minLength: 32)
                    footnotes
                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 24)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.14))
                    .frame(width: 100, height: 100)
                    .blur(radius: 14)
                    .scaleEffect(1.4)
                Circle()
                    .fill(Color.white.opacity(0.10))
                    .frame(width: 88, height: 88)
                Text("🇬🇷")
                    .font(.system(size: 50))
            }

            VStack(spacing: 8) {
                Text(lang.t("Πλήρης Πρόσβαση", "Full Access"))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(lang.t(
                    "Όλες οι ερωτήσεις ΚΟΚ, αποθηκευμένες προόδους,\nστατιστικά και πολλά άλλα.",
                    "All KOK questions, saved progress,\nstatistics and much more."
                ))
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.68))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
            }
        }
    }

    // MARK: - Features

    private var featuresCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(lang.t("Τι περιλαμβάνεται", "What's included"))
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.55))
                .textCase(.uppercase)
                .tracking(0.8)

            VStack(spacing: 11) {
                featureRow("checkmark.circle.fill", .passGreen,
                           lang.t("Απεριόριστες εξετάσεις 30 ερωτήσεων", "Unlimited 30-question exams"))
                featureRow("book.fill", .catBlue,
                           lang.t("Μελέτη flashcards ανά κατηγορία", "Flashcard study by category"))
                featureRow("exclamationmark.triangle.fill", .catOrange,
                           lang.t("Πινακίδες & κανόνες κυκλοφορίας", "Traffic signs & road rules"))
                featureRow("chart.bar.fill", .catPurple,
                           lang.t("Στατιστικά & παρακολούθηση προόδου", "Statistics & progress tracking"))
                featureRow("star.fill", .greekGold,
                           lang.t("Ερώτηση της ημέρας", "Question of the day"))
            }
        }
        .padding(20)
        .background(.ultraThinMaterial.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.10), lineWidth: 1))
    }

    private func featureRow(_ icon: String, _ color: Color, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 22)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.88))
            Spacer()
        }
    }

    // MARK: - Subscription Option

    private var subscriptionOption: some View {
        VStack(spacing: 14) {
            purchaseButton(
                title: lang.t("Ξεκινήστε Δωρεάν Δοκιμή 3 Ημερών", "Start 3-Day Free Trial"),
                subtitle: lang.t("Στη συνέχεια \(store.yearlyDisplayPrice)/έτος · Ακύρωση οποτεδήποτε", "Then \(store.yearlyDisplayPrice)/year · Cancel anytime"),
                isLoading: store.isLoading,
                action: { Task { await store.purchase(StoreKitManager.yearlyProductID) } }
            )
        }
        .padding(20)
        .background(.ultraThinMaterial.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.greekGold.opacity(0.35), lineWidth: 1)
        )
    }

    // MARK: - Lifetime Option

    private var lifetimeOption: some View {
        Button {
            Task { await store.purchase(StoreKitManager.lifetimeProductID) }
        } label: {
            HStack {
                Image(systemName: "infinity")
                    .font(.system(size: 16, weight: .semibold))
                Text(lang.t("Ισόβια Πρόσβαση — \(store.lifetimeDisplayPrice)", "Lifetime Access — \(store.lifetimeDisplayPrice)"))
                    .font(.headline.weight(.semibold))
                Spacer()
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20).padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.15), lineWidth: 1))
        }
        .disabled(store.isLoading)
        .overlay(alignment: .topTrailing) {
            Text(lang.t("εφάπαξ", "one-time"))
                .font(.caption2.bold())
                .foregroundStyle(Color.greekGold)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Color.greekGold.opacity(0.15))
                .clipShape(Capsule())
                .padding(8)
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func purchaseButton(title: String, subtitle: String, isLoading: Bool, action: @escaping () -> Void) -> some View {
        VStack(spacing: 6) {
            Button(action: action) {
                ZStack {
                    if isLoading {
                        ProgressView().tint(Color.greekDark)
                    } else {
                        HStack(spacing: 10) {
                            Image(systemName: "lock.open.fill").font(.headline.bold())
                            Text(title)
                                .font(.headline.bold())
                                .multilineTextAlignment(.center)
                        }
                        .foregroundStyle(Color.greekDark)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [Color.greekGold, Color.greekGold.opacity(0.80)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Color.greekGold.opacity(0.55), radius: 18, x: 0, y: 8)
            }
            .disabled(isLoading)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Restore

    private var restoreSection: some View {
        VStack(spacing: 10) {
            if let err = store.purchaseError {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }

            Button {
                Task { await store.restorePurchases() }
            } label: {
                Text(lang.t("Επαναφορά αγορών", "Restore Purchase"))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.50))
            }
            .disabled(store.isLoading)
        }
    }

    // MARK: - Footnotes

    private var footnotes: some View {
        VStack(spacing: 8) {
            Text(lang.t(
                "Ετήσια συνδρομή \(store.yearlyDisplayPrice)/έτος. Δωρεάν δοκιμή 3 ημερών για νέους συνδρομητές. Ανανεώνεται αυτόματα εκτός αν ακυρωθεί 24 ώρες πριν τη λήξη. Χρέωση μέσω Apple ID. Ακύρωση από Ρυθμίσεις → Συνδρομές.",
                "Yearly subscription \(store.yearlyDisplayPrice)/year. 3-day free trial for new subscribers. Auto-renews unless cancelled 24h before renewal. Charged to your Apple ID. Cancel in Settings → Subscriptions."
            ))
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.28))
            .multilineTextAlignment(.center)
            .lineSpacing(2)

            HStack(spacing: 16) {
                Link(lang.t("Όροι Χρήσης", "Terms of Use"),
                     destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                Link(lang.t("Πολιτική Απορρήτου", "Privacy Policy"),
                     destination: URL(string: "https://www.termsfeed.com/live/your-privacy-policy-url")!)
            }
            .font(.caption2.bold())
            .foregroundStyle(.white.opacity(0.45))
        }
    }
}
