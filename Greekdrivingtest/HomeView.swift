import SwiftUI
import SwiftData

struct HomeView: View {
    @Binding var selectedTab: Int
    @Environment(LanguageManager.self) private var lang
    @Query(sort: \TestResult.date, order: .reverse) private var results: [TestResult]

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        heroSection
                        statsRow
                        categoryGrid
                        if !results.isEmpty { recentSection }
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Hero
    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [.greekBlue, .greekDark],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))

            VStack(alignment: .leading, spacing: 12) {
                Text("🇬🇷")
                    .font(.system(size: 46))
                Text(lang.t("Θεωρητική Εξέταση", "Theory Exam"))
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                Text(lang.t(
                    "30 ερωτήσεις · 45 λεπτά · Μέγιστο 3 λάθη",
                    "30 questions · 45 minutes · Max 3 errors"
                ))
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))

                Button { selectedTab = 2 } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.circle.fill")
                        Text(lang.t("Έναρξη Εξέτασης", "Start Exam"))
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.greekBlue)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .clipShape(Capsule())
                }
                .padding(.top, 4)
            }
            .padding(24)
        }
        .frame(minHeight: 230)
        .shadow(color: .greekBlue.opacity(0.35), radius: 16, x: 0, y: 8)
    }

    // MARK: - Stats
    private var statsRow: some View {
        HStack(spacing: 12) {
            StatPill(
                value: "\(results.count)",
                label: lang.t("Εξετάσεις", "Exams"),
                icon: "doc.text.fill", color: .catBlue
            )
            StatPill(
                value: passRateString,
                label: lang.t("Επιτυχία", "Pass Rate"),
                icon: "percent", color: passRateColor
            )
            StatPill(
                value: bestScoreString,
                label: lang.t("Καλύτερο", "Best"),
                icon: "star.fill", color: .catOrange
            )
        }
    }

    private var passRateString: String {
        guard !results.isEmpty else { return "—" }
        let pct = Double(results.filter(\.passed).count) / Double(results.count) * 100
        return "\(Int(pct))%"
    }
    private var passRateColor: Color {
        guard !results.isEmpty else { return .catGreen }
        let pct = Double(results.filter(\.passed).count) / Double(results.count)
        return pct >= 0.5 ? .catGreen : .catRed
    }
    private var bestScoreString: String {
        guard let best = results.map(\.score).max() else { return "—" }
        return "\(best)/30"
    }

    // MARK: - Categories
    private var categoryGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(lang.t("Κατηγορίες", "Categories"))
                .font(.title3.bold())
                .padding(.leading, 2)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(QuestionCategory.allCases, id: \.self) { cat in
                    NavigationLink {
                        StudyCategoryView(category: cat)
                    } label: {
                        CategoryCard(category: cat)
                    }
                }
            }
        }
    }

    // MARK: - Recent
    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(lang.t("Πρόσφατα Αποτελέσματα", "Recent Results"))
                .font(.title3.bold())
                .padding(.leading, 2)
            ForEach(results.prefix(3)) { result in
                RecentResultRow(result: result)
            }
        }
    }
}

// MARK: - Subviews

struct StatPill: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.title2.bold())
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .cardStyle()
    }
}

struct CategoryCard: View {
    @Environment(LanguageManager.self) private var lang
    let category: QuestionCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                Circle()
                    .fill(categoryColor(category).opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: category.icon)
                    .font(.title3)
                    .foregroundColor(categoryColor(category))
            }
            Text(category.name(greek: lang.language.isGreek))
                .font(.subheadline.bold())
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            Text(lang.t("Μελέτη", "Study"))
                .font(.caption)
                .foregroundColor(categoryColor(category))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(categoryColor(category).opacity(0.25), lineWidth: 1)
        )
    }
}

struct RecentResultRow: View {
    @Environment(LanguageManager.self) private var lang
    let result: TestResult

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill((result.passed ? Color.passGreen : Color.failRed).opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(result.passed ? .passGreen : .failRed)
                    .font(.title3)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(result.passed ? lang.t("Επιτυχία", "Passed") : lang.t("Αποτυχία", "Failed"))
                    .font(.subheadline.bold())
                Text(result.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(result.score)/\(result.totalQuestions)")
                    .font(.headline.bold())
                    .foregroundColor(result.passed ? .passGreen : .failRed)
                Text("\(result.errors) \(lang.t("λάθη", "errors"))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .cardStyle()
    }
}
