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

            decorativeCircles

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: 40)
                    headerSection
                    Spacer(minLength: 20)
                    featuresCard
                    Spacer(minLength: 20)
                    trialCard
                    Spacer(minLength: 12)
                    monthlyCard
                    Spacer(minLength: 12)
                    onceCard
                    Spacer(minLength: 20)
                    legalLinks
                    Spacer(minLength: 16)
                    restoreButton
                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: 540)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
        }
    }

    private var decorativeCircles: some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.06)).frame(width: 300).offset(x: 160, y: -260)
            Circle().fill(Color.greekGold.opacity(0.18)).frame(width: 200).blur(radius: 60).offset(x: 120, y: -180)
            Circle().fill(Color.catPurple.opacity(0.12)).frame(width: 260).blur(radius: 80).offset(x: -130, y: 340)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.white.opacity(0.14)).frame(width: 100, height: 100).blur(radius: 14).scaleEffect(1.4)
                Circle().fill(Color.white.opacity(0.10)).frame(width: 88, height: 88)
                Text("🇬🇷").font(.system(size: 50))
            }
            VStack(spacing: 6) {
                Text(lang.t("Πλήρης Πρόσβαση", "Full Access"))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(lang.t(
                    "Όλες οι ερωτήσεις ΚΟΚ, flashcards, εξετάσεις & στατιστικά",
                    "All KOK questions, flashcards, exams & stats"
                ))
                .font(.subheadline).foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center).padding(.horizontal, 20)
            }
        }
    }

    private var featuresCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(lang.t("Τι περιλαμβάνεται", "What's included"))
                .font(.caption.bold()).foregroundStyle(.white.opacity(0.65)).textCase(.uppercase).tracking(0.8)
            VStack(spacing: 8) {
                featureRow("checkmark.circle.fill", .passGreen, lang.t("Απεριόριστες εξετάσεις", "Unlimited exams"))
                featureRow("book.fill", .catBlue, lang.t("Flashcards ανά κατηγορία", "Flashcards by category"))
                featureRow("exclamationmark.triangle.fill", .catOrange, lang.t("Πινακίδες & κανόνες", "Traffic signs & rules"))
                featureRow("chart.bar.fill", .catPurple, lang.t("Στατιστικά & πρόοδος", "Statistics & progress"))
            }
        }
        .padding(16).background(.ultraThinMaterial.opacity(0.5)).clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private func featureRow(_ icon: String, _ color: Color, _ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 13, weight: .semibold)).foregroundStyle(color).frame(width: 20)
            Text(text).font(.subheadline).foregroundStyle(.white.opacity(0.9))
            Spacer()
        }
    }

    private var trialCard: some View {
        purchaseCard(
            icon: "crown.fill",
            color: Color.greekGold,
            title: lang.t("Δωρεάν Δοκιμή 3 Ημερών", "3-Day Free Trial"),
            subtitle: lang.t("Μετά \(store.monthlyDisplayPrice)/μήνα", "Then \(store.monthlyDisplayPrice)/month"),
            detail: lang.t("Μηνιαία συνδρομή · Ανανεώνεται αυτόματα · Ακύρωση οποτεδήποτε", "Monthly subscription · Auto-renews · Cancel anytime"),
            buttonColor: LinearGradient(colors: [Color.greekGold, Color.greekGold.opacity(0.8)], startPoint: .leading, endPoint: .trailing),
            textColor: Color.greekDark,
            isOutline: false,
            action: { Task { await store.purchase(StoreKitManager.monthlyProductID) } }
        )
    }

    private var monthlyCard: some View {
        purchaseCard(
            icon: "repeat",
            color: Color.catBlue,
            title: lang.t("Μηνιαία Συνδρομή", "Monthly Subscription"),
            subtitle: "\(store.monthlyDisplayPrice)/\(lang.t("μήνα", "month"))",
            detail: lang.t("Ανανεώνεται αυτόματα · Ακύρωση οποτεδήποτε", "Auto-renews · Cancel anytime"),
            buttonColor: LinearGradient(colors: [Color.catBlue, Color.catBlue.opacity(0.8)], startPoint: .leading, endPoint: .trailing),
            textColor: .white,
            isOutline: false,
            action: { Task { await store.purchase(StoreKitManager.monthlyProductID) } }
        )
    }

    private var onceCard: some View {
        purchaseCard(
            icon: "infinity",
            color: .white,
            title: lang.t("Εφάπαξ Αγορά", "One-Time Purchase"),
            subtitle: store.onceDisplayPrice,
            detail: lang.t("Πλήρης πρόσβαση για πάντα · Χωρίς συνδρομή", "Full access forever · No subscription"),
            buttonColor: LinearGradient(colors: [Color.white.opacity(0.15), Color.white.opacity(0.08)], startPoint: .leading, endPoint: .trailing),
            textColor: .white,
            isOutline: true,
            action: { Task { await store.purchase(StoreKitManager.onceProductID) } }
        )
    }

    private func purchaseCard(icon: String, color: Color, title: String, subtitle: String, detail: String, buttonColor: LinearGradient, textColor: Color, isOutline: Bool, action: @escaping () -> Void) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 14) {
                Image(systemName: icon).font(.title3.weight(.semibold)).foregroundStyle(color).frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline.weight(.semibold)).foregroundStyle(.white)
                    Text(detail).font(.caption2).foregroundStyle(.white.opacity(0.55))
                }
                Spacer()
                Text(subtitle).font(.title3.weight(.bold)).foregroundStyle(.white)
            }

            Button(action: action) {
                ZStack {
                    if store.isLoading { ProgressView().tint(textColor) }
                    else { Text(lang.t("Συνέχεια", "Continue")).font(.headline.bold()).foregroundStyle(textColor) }
                }
                .frame(maxWidth: .infinity).frame(height: 48)
                .background(buttonColor)
                .clipShape(Capsule())
                .overlay(isOutline ? Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1) : nil)
            }
            .disabled(store.isLoading)
        }
        .padding(16)
        .background(.ultraThinMaterial.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(isOutline ? Color.white.opacity(0.15) : color.opacity(0.3), lineWidth: 1))
    }

    private var legalLinks: some View {
        VStack(spacing: 8) {
            Text(lang.t(
                "Η δωρεάν δοκιμή 3 ημερών ισχύει για νέους συνδρομητές. Μετά τη δοκιμή, η μηνιαία συνδρομή ανανεώνεται αυτόματα. Ακύρωση από Ρυθμίσεις Apple ID. Η εφάπαξ αγορά δεν ανανεώνεται.",
                "3-day free trial for new subscribers. After trial, monthly subscription auto-renews. Cancel in Apple ID Settings. One-time purchase does not renew."
            ))
            .font(.caption2).foregroundStyle(.white.opacity(0.40)).multilineTextAlignment(.center).lineSpacing(3)

            HStack(spacing: 24) {
                Link(destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text.fill").font(.caption2)
                        Text(lang.t("Όροι Χρήσης (EULA)", "Terms of Use (EULA)")).underline()
                    }
                }
                Link(destination: URL(string: "https://sites.google.com/view/greekdrivingtest/home")!) {
                    HStack(spacing: 4) {
                        Image(systemName: "hand.raised.fill").font(.caption2)
                        Text(lang.t("Πολιτική Απορρήτου", "Privacy Policy")).underline()
                    }
                }
            }
            .font(.caption.bold()).foregroundStyle(.white.opacity(0.65))
        }
    }

    private var restoreButton: some View {
        VStack(spacing: 8) {
            if let err = store.purchaseError {
                Text(err).font(.caption).foregroundStyle(.white.opacity(0.7)).multilineTextAlignment(.center)
            }
            Button { Task { await store.restorePurchases() } } label: {
                Text(lang.t("Επαναφορά Αγορών", "Restore Purchases"))
                    .font(.subheadline).foregroundStyle(.white.opacity(0.50))
            }
            .disabled(store.isLoading)
        }
    }
}
