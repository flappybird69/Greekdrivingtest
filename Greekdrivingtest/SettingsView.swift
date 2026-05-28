import SwiftUI
import SwiftData
import StoreKit

struct SettingsView: View {
    @Environment(LanguageManager.self) private var lang
    @Environment(StoreKitManager.self) private var store
    @Environment(\.modelContext) private var modelContext
    @Query private var results: [TestResult]
    @State private var showingClearConfirm = false
    @AppStorage("userName") private var userName = ""
    @State private var nameInput = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                List {
                    // Profile
                    Section {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.greekBlue.opacity(0.12))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "person.fill")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.greekBlue)
                            }
                            TextField(lang.t("Το όνομά σου...", "Your name..."), text: $nameInput)
                                .submitLabel(.done)
                                .onChange(of: nameInput) { _, newValue in
                                    userName = newValue.trimmingCharacters(in: .whitespaces)
                                }
                            if !nameInput.isEmpty {
                                Button { nameInput = "" } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(Color(.systemGray3))
                                }
                            }
                        }
                    } header: {
                        Text(lang.t("Προφίλ", "Profile"))
                    } footer: {
                        Text(lang.t("Εμφανίζεται στην αρχική σελίδα", "Shown on the home screen"))
                    }

                    // Language
                    Section {
                        ForEach(AppLanguage.allCases, id: \.self) { language in
                            Button {
                                withAnimation { lang.setLanguage(language) }
                            } label: {
                                HStack {
                                    Text(language.flag)
                                        .font(.title2)
                                    Text(language.displayName)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if lang.language == language {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.greekBlue)
                                    }
                                }
                            }
                        }
                    } header: {
                        Text(lang.t("Γλώσσα", "Language"))
                    }

                    // Exam Info
                    Section {
                        InfoRow(
                            icon: "questionmark.circle.fill", color: .catBlue,
                            title: lang.t("Ερωτήσεις", "Questions"),
                            value: "30"
                        )
                        InfoRow(
                            icon: "clock.fill", color: .catOrange,
                            title: lang.t("Χρόνος", "Time Limit"),
                            value: lang.t("45 λεπτά", "45 minutes")
                        )
                        InfoRow(
                            icon: "xmark.circle.fill", color: .catRed,
                            title: lang.t("Μέγιστα Λάθη", "Max Errors"),
                            value: "3"
                        )
                        InfoRow(
                            icon: "checkmark.circle.fill", color: .catGreen,
                            title: lang.t("Βάση Επιτυχίας", "Pass Mark"),
                            value: "27/30"
                        )
                    } header: {
                        Text(lang.t("Μορφή Εξέτασης", "Exam Format"))
                    } footer: {
                        Text(lang.t(
                            "Βάσει ΚΟΚ (Κώδικας Οδικής Κυκλοφορίας) – Π.Δ. 19/1995 όπως τροποποιήθηκε.",
                            "Based on the Greek Highway Code (KOK) – P.D. 19/1995 as amended."
                        ))
                        .font(.caption)
                    }

                    // Stats Summary
                    Section {
                        InfoRow(
                            icon: "doc.text.fill", color: .catBlue,
                            title: lang.t("Σύνολο Εξετάσεων", "Total Exams"),
                            value: "\(results.count)"
                        )
                        InfoRow(
                            icon: "checkmark.seal.fill", color: .catGreen,
                            title: lang.t("Επιτυχίες", "Passed"),
                            value: "\(results.filter(\.passed).count)"
                        )
                    } header: {
                        Text(lang.t("Σύνοψη", "Summary"))
                    }

                    // Pro Access
                    Section {
                        if store.isLifetimePurchased {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(Color.passGreen).frame(width: 28)
                                Text(lang.t("Ισόβια Πρόσβαση", "Lifetime Access Unlocked"))
                                Spacer()
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.passGreen).font(.subheadline.bold())
                            }
                        } else if store.isSubscriptionActive {
                            if store.isTrialActive {
                                HStack {
                                    Image(systemName: "clock.fill")
                                        .foregroundStyle(Color.catOrange).frame(width: 28)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(lang.t("Δωρεάν Δοκιμή", "Free Trial Active"))
                                        let d = store.trialDaysRemaining
                                        Text(lang.t("\(d) \(d == 1 ? "μέρα" : "μέρες") απομένουν", "\(d) \(d == 1 ? "day" : "days") remaining"))
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                            } else {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.greekBlue).frame(width: 28)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(lang.t("Ενεργή Συνδρομή", "Subscription Active"))
                                        if let expiry = store.subscriptionExpiryDate {
                                            Text(expiry, style: .date)
                                                .font(.caption).foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                }
                            }
                        } else {
                            Button {
                                Task { await store.purchase(StoreKitManager.yearlyProductID) }
                            } label: {
                                HStack {
                                    Image(systemName: "lock.open.fill")
                                        .foregroundStyle(Color.greekBlue).frame(width: 28)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(lang.t("Δωρεάν Δοκιμή 3 Ημερών", "Start 3-Day Free Trial"))
                                            .foregroundStyle(Color.greekBlue).fontWeight(.semibold)
                                        Text(lang.t("Μετά \(store.yearlyDisplayPrice)/έτος", "Then \(store.yearlyDisplayPrice)/year"))
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if store.isLoading {
                                        ProgressView().scaleEffect(0.8)
                                    }
                                }
                            }
                            .disabled(store.isLoading)

                            Button {
                                Task { await store.purchase(StoreKitManager.lifetimeProductID) }
                            } label: {
                                HStack {
                                    Image(systemName: "infinity")
                                        .foregroundStyle(Color.greekGold).frame(width: 28)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(lang.t("Ισόβια — \(store.lifetimeDisplayPrice)", "Lifetime — \(store.lifetimeDisplayPrice)"))
                                            .foregroundStyle(Color.greekGold).fontWeight(.semibold)
                                        Text(lang.t("Εφάπαξ αγορά", "One-time purchase"))
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if store.isLoading {
                                        ProgressView().scaleEffect(0.8)
                                    }
                                }
                            }
                            .disabled(store.isLoading)

                            Button {
                                Task { await store.restorePurchases() }
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                        .foregroundStyle(Color.secondary).frame(width: 28)
                                    Text(lang.t("Επαναφορά Αγορών", "Restore Purchases"))
                                        .foregroundStyle(Color.secondary)
                                    Spacer()
                                }
                            }
                            .disabled(store.isLoading)

                            if let err = store.purchaseError {
                                Text(err)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 4)
                            }
                        }
                    } header: {
                        Text(lang.t("Pro Πρόσβαση", "Pro Access"))
                    } footer: {
                        if store.isLifetimePurchased {
                            Text(lang.t("Πλήρης πρόσβαση για πάντα.", "Full access forever."))
                        } else if store.isSubscriptionActive {
                            Text(lang.t("Διαχειριστείτε τη συνδρομή σας από τις Ρυθμίσεις Apple ID.", "Manage your subscription in Apple ID Settings."))
                        } else {
                            Text(lang.t(
                                "Δοκιμή 3 ημερών, μετά \(store.yearlyDisplayPrice)/έτος ή \(store.lifetimeDisplayPrice) εφάπαξ.",
                                "3-day trial, then \(store.yearlyDisplayPrice)/year or \(store.lifetimeDisplayPrice) once."
                            ))
                        }
                    }

                    // Clear history
                    Section {
                        Button(role: .destructive) {
                            showingClearConfirm = true
                        } label: {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text(lang.t("Διαγραφή Ιστορικού", "Clear History"))
                            }
                        }
                    }

                    // About
                    Section {
                        InfoRow(
                            icon: "info.circle.fill", color: .catBlue,
                            title: lang.t("Έκδοση", "Version"),
                            value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
                        )
                        InfoRow(
                            icon: "flag.fill", color: .catRed,
                            title: lang.t("Χώρα", "Country"),
                            value: lang.t("Ελλάδα 🇬🇷", "Greece 🇬🇷")
                        )
                    } header: {
                        Text(lang.t("Σχετικά", "About"))
                    }
                }
                .scrollContentBackground(.hidden)
                .onAppear { nameInput = userName }
            }
            .navigationTitle(lang.t("Ρυθμίσεις", "Settings"))
            .confirmationDialog(
                lang.t("Διαγραφή Ιστορικού;", "Clear History?"),
                isPresented: $showingClearConfirm,
                titleVisibility: .visible
            ) {
                Button(lang.t("Διαγραφή", "Delete"), role: .destructive) {
                    results.forEach { modelContext.delete($0) }
                }
                Button(lang.t("Άκυρο", "Cancel"), role: .cancel) {}
            } message: {
                Text(lang.t("Αυτή η ενέργεια δεν μπορεί να αναιρεθεί.", "This action cannot be undone."))
            }
        }
    }
}

struct InfoRow: View {
    let icon: String
    let color: Color
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 28)
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
                .font(.subheadline)
        }
    }
}

#Preview {
    SettingsView()
        .environment(LanguageManager())
        .modelContainer(for: [TestResult.self, BookmarkedQuestion.self, DifficultQuestion.self], inMemory: true)
}
