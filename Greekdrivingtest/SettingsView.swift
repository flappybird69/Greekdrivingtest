import SwiftUI
import SwiftData
import StoreKit

struct SettingsView: View {
    @Environment(LanguageManager.self) private var lang
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreManager.self) private var storeManager
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

                    // Remove Ads
                    Section {
                        if storeManager.adsRemoved {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.passGreen)
                                    .frame(width: 28)
                                Text(lang.t("Διαφημίσεις απενεργοποιημένες", "Ads removed"))
                                    .foregroundColor(.passGreen)
                                    .fontWeight(.semibold)
                            }
                        } else {
                            Button {
                                Task { await storeManager.purchase() }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.greekGold)
                                        .frame(width: 28)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(lang.t("Αφαίρεση Διαφημίσεων", "Remove Ads"))
                                            .foregroundColor(.primary)
                                            .fontWeight(.semibold)
                                        if let product = storeManager.product {
                                            Text(product.displayPrice)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                    if storeManager.isPurchasing {
                                        ProgressView().scaleEffect(0.8)
                                    }
                                }
                            }
                            .disabled(storeManager.isPurchasing || storeManager.product == nil)

                            Button {
                                Task { await storeManager.restore() }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "arrow.clockwise")
                                        .foregroundColor(.greekBlue)
                                        .frame(width: 28)
                                    Text(lang.t("Επαναφορά Αγοράς", "Restore Purchase"))
                                        .foregroundColor(.greekBlue)
                                }
                            }
                            .disabled(storeManager.isPurchasing)
                        }

                        if let error = storeManager.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.catRed)
                        }
                    } header: {
                        Text(lang.t("Αγορά", "Purchase"))
                    } footer: {
                        Text(lang.t(
                            "Εφάπαξ αγορά. Χωρίς συνδρομή.",
                            "One-time purchase. No subscription."
                        ))
                        .font(.caption)
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
        .environment(StoreManager())
        .modelContainer(for: [TestResult.self, BookmarkedQuestion.self, DifficultQuestion.self], inMemory: true)
}
