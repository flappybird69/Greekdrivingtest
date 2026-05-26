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
                    Spacer(minLength: 56)
                    headerSection
                    Spacer(minLength: 28)
                    featuresCard
                    Spacer(minLength: 16)
                    priceCard
                    Spacer(minLength: 28)
                    ctaSection
                    Spacer(minLength: 48)
                }
                .padding(.horizontal, 24)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 18) {
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

            trialBadge
        }
    }

    @ViewBuilder
    private var trialBadge: some View {
        if store.isTrialActive {
            HStack(spacing: 6) {
                Image(systemName: "clock.fill").font(.caption.bold())
                let d = store.trialDaysRemaining
                Text(lang.t(
                    "Δοκιμαστική περίοδος: \(d) \(d == 1 ? "μέρα" : "μέρες") ακόμα",
                    "Trial: \(d) \(d == 1 ? "day" : "days") left"
                ))
                .font(.caption.bold())
            }
            .foregroundStyle(Color.greekGold)
            .padding(.horizontal, 14).padding(.vertical, 7)
            .background(Color.greekGold.opacity(0.15))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.greekGold.opacity(0.4), lineWidth: 1))
        } else {
            HStack(spacing: 6) {
                Image(systemName: "lock.fill").font(.caption.bold())
                Text(lang.t("Η δοκιμαστική περίοδος έληξε", "Trial period expired"))
                    .font(.caption.bold())
            }
            .foregroundStyle(.white.opacity(0.55))
            .padding(.horizontal, 14).padding(.vertical, 7)
            .background(Color.white.opacity(0.08))
            .clipShape(Capsule())
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

    // MARK: - Price

    private var priceCard: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(lang.t("Εφάπαξ αγορά", "One-time purchase"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
                Text(lang.t("Χωρίς συνδρομή, ποτέ.", "No subscription, ever."))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.45))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(store.displayPrice)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(lang.t("εφ' άπαξ", "one time"))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 18)
        .background(.ultraThinMaterial.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.greekGold.opacity(0.35), lineWidth: 1)
        )
    }

    // MARK: - CTA

    private var ctaSection: some View {
        VStack(spacing: 14) {
            Button {
                Task { await store.purchase() }
            } label: {
                ZStack {
                    if store.isLoading {
                        ProgressView().tint(Color.greekDark)
                    } else {
                        HStack(spacing: 10) {
                            Image(systemName: "lock.open.fill").font(.headline.bold())
                            Text(lang.t(
                                "Ξεκλείδωμα — \(store.displayPrice)",
                                "Unlock — \(store.displayPrice)"
                            ))
                            .font(.headline.bold())
                        }
                        .foregroundStyle(Color.greekDark)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 58)
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
            .disabled(store.isLoading)

            Button {
                Task { await store.restorePurchases() }
            } label: {
                Text(lang.t("Επαναφορά αγορών", "Restore Purchase"))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.50))
            }
            .disabled(store.isLoading)

            if let err = store.purchaseError {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }

            Text(lang.t(
                "Η πληρωμή χρεώνεται μέσω Apple ID.\nΜεταφορά σε νέες συσκευές χωρίς επιπλέον κόστος.",
                "Payment is charged to your Apple ID.\nTransfer to new devices at no extra cost."
            ))
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.30))
            .multilineTextAlignment(.center)
            .lineSpacing(2)
        }
    }
}
