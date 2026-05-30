import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Environment(LanguageManager.self) private var lang
    @Query(sort: \TestResult.date, order: .reverse) private var results: [TestResult]
    @AppStorage("streakCount") private var streakCount = 0

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                if results.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            overallCards
                            achievementsSection
                            scoreChart
                            historyList
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                        .iPadReadableWidth()
                    }
                }
            }
            .navigationTitle(lang.t("Στατιστικά", "Statistics"))
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Empty
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 56))
                .foregroundColor(.secondary)
            Text(lang.t("Δεν υπάρχουν εξετάσεις ακόμα", "No exams yet"))
                .font(.headline).foregroundColor(.secondary)
            Text(lang.t("Κάνε μια εξέταση για να δεις τα στατιστικά σου!",
                         "Take an exam to see your statistics!"))
                .font(.subheadline).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: - Overall Cards
    private var overallCards: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard2(
                    value: "\(results.count)",
                    label: lang.t("Σύνολο", "Total"),
                    icon: "doc.text.fill", color: .catBlue
                )
                StatCard2(
                    value: "\(results.filter(\.passed).count)",
                    label: lang.t("Επιτυχίες", "Passed"),
                    icon: "checkmark.circle.fill", color: .passGreen
                )
                StatCard2(
                    value: "\(results.filter { !$0.passed }.count)",
                    label: lang.t("Αποτυχίες", "Failed"),
                    icon: "xmark.circle.fill", color: .failRed
                )
            }
            HStack(spacing: 12) {
                StatCard2(
                    value: passRateStr,
                    label: lang.t("Ποσοστό", "Pass Rate"),
                    icon: "percent", color: .catOrange
                )
                StatCard2(
                    value: avgScoreStr,
                    label: lang.t("Μ.Ο. Σκορ", "Avg Score"),
                    icon: "chart.line.uptrend.xyaxis", color: .catPurple
                )
                StatCard2(
                    value: bestStr,
                    label: lang.t("Καλύτερο", "Best"),
                    icon: "star.fill", color: .greekGold
                )
            }
        }
    }

    private var passRateStr: String {
        guard !results.isEmpty else { return "—" }
        return "\(Int(Double(results.filter(\.passed).count) / Double(results.count) * 100))%"
    }
    private var avgScoreStr: String {
        guard !results.isEmpty else { return "—" }
        let avg = Double(results.map(\.score).reduce(0, +)) / Double(results.count)
        return String(format: "%.1f", avg)
    }
    private var bestStr: String {
        guard let best = results.map(\.score).max() else { return "—" }
        return "\(best)/30"
    }

    // MARK: - Score Chart
    private var scoreChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(lang.t("Πρόσφατες Εξετάσεις", "Recent Exams"))
                .font(.title3.bold())

            let recent = Array(results.prefix(10).reversed())

            Chart {
                RuleMark(y: .value("Pass", 27))
                    .foregroundStyle(Color.passGreen.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    .annotation(position: .trailing) {
                        Text("27").font(.caption2).foregroundColor(.passGreen)
                    }

                ForEach(recent.indices, id: \.self) { i in
                    let r = recent[i]
                    LineMark(
                        x: .value("Exam", i + 1),
                        y: .value(lang.t("Σκορ", "Score"), r.score)
                    )
                    .foregroundStyle(Color.greekBlue)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Exam", i + 1),
                        y: .value(lang.t("Σκορ", "Score"), r.score)
                    )
                    .foregroundStyle(r.passed ? Color.passGreen : Color.failRed)
                    .symbolSize(60)
                }
            }
            .chartYScale(domain: 0...30)
            .chartYAxis {
                AxisMarks(values: [0, 10, 20, 27, 30]) { val in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisValueLabel()
                }
            }
            .frame(height: 200)
            .padding(16)
            .cardStyle()
        }
    }

    // MARK: - History List
    private var historyList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(lang.t("Ιστορικό", "History"))
                .font(.title3.bold())

            ForEach(results) { result in
                HistoryRow(result: result)
            }
        }
    }

    // MARK: - Achievements

    private struct Achievement {
        let icon: String
        let title: String
        let color: Color
        let unlocked: Bool
    }

    private var hasHatTrick: Bool {
        var consecutive = 0
        for r in results.reversed() {
            if r.passed { consecutive += 1; if consecutive >= 3 { return true } }
            else { consecutive = 0 }
        }
        return false
    }

    private var achievements: [Achievement] {
        [
            Achievement(icon: "doc.badge.plus",
                        title: lang.t("Πρώτη Εξέταση", "First Exam"),
                        color: .catBlue, unlocked: !results.isEmpty),
            Achievement(icon: "checkmark.seal.fill",
                        title: lang.t("Πρώτη Επιτυχία", "First Pass"),
                        color: .passGreen, unlocked: results.contains(where: \.passed)),
            Achievement(icon: "star.fill",
                        title: lang.t("Τέλεια Βαθμολογία", "Perfect Score"),
                        color: .greekGold, unlocked: results.contains { $0.score == 30 }),
            Achievement(icon: "circle.slash",
                        title: lang.t("Αλάνθαστος", "No Errors"),
                        color: .catBlue, unlocked: results.contains { $0.errors == 0 }),
            Achievement(icon: "3.circle.fill",
                        title: lang.t("Χατ Τρικ", "Hat Trick"),
                        color: .catGreen, unlocked: hasHatTrick),
            Achievement(icon: "flame.fill",
                        title: lang.t("3 Μέρες Σερί", "3-Day Streak"),
                        color: .catOrange, unlocked: streakCount >= 3),
            Achievement(icon: "bolt.fill",
                        title: lang.t("7 Μέρες Σερί", "7-Day Streak"),
                        color: .catRed, unlocked: streakCount >= 7),
            Achievement(icon: "trophy.fill",
                        title: lang.t("5 Εξετάσεις", "5 Exams"),
                        color: .catPurple, unlocked: results.count >= 5),
            Achievement(icon: "crown.fill",
                        title: lang.t("20 Εξετάσεις", "20 Exams"),
                        color: .greekGold, unlocked: results.count >= 20),
        ]
    }

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(lang.t("Επιτεύγματα", "Achievements"))
                    .font(.title3.bold())
                Spacer()
                Text("\(achievements.filter(\.unlocked).count)/\(achievements.count)")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(achievements.indices, id: \.self) { i in
                    achievementCard(achievements[i])
                }
            }
        }
    }

    private func achievementCard(_ a: Achievement) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(a.unlocked ? a.color.opacity(0.15) : Color(.systemGray5))
                    .frame(width: 48, height: 48)
                Image(systemName: a.icon)
                    .font(.title3)
                    .foregroundColor(a.unlocked ? a.color : Color(.systemGray3))
            }
            Text(a.title)
                .font(.caption2.bold())
                .multilineTextAlignment(.center)
                .foregroundColor(a.unlocked ? .primary : .secondary)
                .lineLimit(2)
            if !a.unlocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 9))
                    .foregroundColor(Color(.systemGray4))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .cardStyle()
        .opacity(a.unlocked ? 1.0 : 0.6)
    }
}

// MARK: - Stat Card 2

struct StatCard2: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.title3).foregroundColor(color)
            Text(value).font(.title2.bold())
            Text(label).font(.caption).foregroundColor(.secondary).lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .cardStyle()
    }
}

// MARK: - History Row

struct HistoryRow: View {
    @Environment(LanguageManager.self) private var lang
    let result: TestResult

    var body: some View {
        HStack(spacing: 14) {
            // Pass/Fail indicator
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill((result.passed ? Color.passGreen : Color.failRed).opacity(0.12))
                    .frame(width: 46, height: 46)
                Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(result.passed ? .passGreen : .failRed)
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(result.passed ? lang.t("Επιτυχία", "Passed") : lang.t("Αποτυχία", "Failed"))
                    .font(.subheadline.bold())
                    .foregroundColor(result.passed ? .passGreen : .failRed)
                Text(result.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption).foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("\(result.score)/\(result.totalQuestions)")
                    .font(.headline.bold())
                    .foregroundColor(result.passed ? .passGreen : .failRed)
                Text("\(result.errors) \(lang.t("λάθη", "errors"))")
                    .font(.caption).foregroundColor(.secondary)
            }

            // Score bar
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 40, height: 6)
                RoundedRectangle(cornerRadius: 4)
                    .fill(result.passed ? Color.passGreen : Color.failRed)
                    .frame(width: 40 * CGFloat(result.score) / CGFloat(result.totalQuestions), height: 6)
            }
        }
        .padding(14)
        .cardStyle()
    }
}

#Preview {
    StatsView()
        .environment(LanguageManager())
        .modelContainer(for: [TestResult.self, BookmarkedQuestion.self, DifficultQuestion.self], inMemory: true)
}
