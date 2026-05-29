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
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.caption)
                        .foregroundStyle(Color.greekGold)
                    Text(lang.t("ΕΤΗΣΙΑ ΣΥΝΔΡΟΜΗ", "YEARLY SUBSCRIPTION"))
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.5))
                        .tracking(1)
                }

                Text(lang.t("3 Ημέρες Δωρεάν", "3 Days Free"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(lang.t("Μετά \(store.yearlyDisplayPrice)/έτος", "Then \(store.yearlyDisplayPrice)/year"))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Divider()
                .background(.white.opacity(0.15))
                .padding(.vertical, 14)

            VStack(spacing: 6) {
                disclosureRow(lang.t("Διάρκεια δοκιμής", "Trial period"),
                              lang.t("3 ημέρες δωρεάν", "3 days free"))
                disclosureRow(lang.t("Τιμή μετά τη δοκιμή", "Price after trial"),
                              "\(store.yearlyDisplayPrice)/\(lang.t("έτος", "year"))")
                disclosureRow(lang.t("Ανανέωση", "Renewal"),
                              lang.t("Αυτόματη, ακύρωση οποτεδήποτε", "Auto-renew, cancel anytime"))
                disclosureRow(lang.t("Περίοδος χρέωσης", "Billing period"),
                              lang.t("1 έτος", "1 year"))
            }

            Button {
                Task { await store.purchase(StoreKitManager.yearlyProductID) }
            } label: {
                ZStack {
                    if store.isLoading {
                        ProgressView().tint(Color.greekDark)
                    } else {
                        HStack(spacing: 10) {
                            Image(systemName: "lock.open.fill").font(.headline.bold())
                            Text(lang.t("Ξεκινήστε Δωρεάν Δοκιμή", "Start Free Trial"))
                                .font(.headline.bold())
                        }
                        .foregroundStyle(Color.greekDark)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
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
            .padding(.top, 4)
        }
        .padding(20)
        .background(.ultraThinMaterial.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.greekGold.opacity(0.35), lineWidth: 1)
        )
    }

    private func disclosureRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.45))
            Spacer()
            Text(value)
                .font(.caption2.bold())
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    // MARK: - Lifetime Option

    private var lifetimeOption: some View {
        Button {
            Task { await store.purchase(StoreKitManager.lifetimeProductID) }
        } label: {
            HStack {
                Image(systemName: "infinity")
                    .font(.system(size: 16, weight: .semibold))
                VStack(alignment: .leading, spacing: 2) {
                    Text(lang.t("Ισόβια Πρόσβαση", "Lifetime Access"))
                        .font(.headline.weight(.semibold))
                    Text(lang.t("Εφάπαξ πληρωμή, χωρίς συνδρομή", "One-time payment, no subscription"))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
                Text(store.lifetimeDisplayPrice)
                    .font(.title3.weight(.bold))
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
        VStack(spacing: 10) {
            Text(lang.t(
                "Η Ετήσια Συνδρομή (\(store.yearlyDisplayPrice)/έτος) περιλαμβάνει δωρεάν δοκιμή 3 ημερών. Μετά τη δοκιμή η συνδρομή ανανεώνεται αυτόματα εκτός αν ακυρωθεί τουλάχιστον 24 ώρες πριν τη λήξη. Η χρέωση γίνεται μέσω του Apple ID σας. Η διαχείριση και ακύρωση των συνδρομών γίνεται από τις Ρυθμίσεις του λογαριασμού σας στο App Store.",
                "Yearly Subscription (\(store.yearlyDisplayPrice)/year) includes a 3-day free trial. After the trial, the subscription auto-renews unless cancelled at least 24 hours before renewal. Payment is charged to your Apple ID. Manage and cancel subscriptions in your App Store account Settings."
            ))
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.30))
            .multilineTextAlignment(.center)
            .lineSpacing(3)

            HStack(spacing: 20) {
                Link(lang.t("Όροι Χρήσης (EULA)", "Terms of Use (EULA)"),
                     destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                Link(lang.t("Πολιτική Απορρήτου", "Privacy Policy"),
                     destination: URL(string: "https://www.termsfeed.com/live/your-privacy-policy-url")!)
            }
            .font(.caption2.bold())
            .foregroundStyle(.white.opacity(0.45))
            .underline()
        }
    }
}
