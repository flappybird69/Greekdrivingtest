import SwiftUI
import SwiftData

struct HomeView: View {
    @Binding var selectedTab: Int
    @Environment(LanguageManager.self) private var lang
    @Query(sort: \TestResult.date, order: .reverse) private var results: [TestResult]
    @AppStorage("userName") private var userName = ""
    @AppStorage("streakCount") private var streakCount = 0
    @State private var showLicenseInfo = false
    @AppStorage("qotdDate") private var qotdDateStr = ""
    @AppStorage("qotdQuestionId") private var qotdQuestionId = -1
    @AppStorage("qotdAnsweredIndex") private var qotdAnsweredIndex = -1

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        heroSection
                        questionOfTheDay
                        readinessCard
                        statsRow
                        categoryGrid
                        officialLinksCard
                        if !results.isEmpty { recentSection }
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear { refreshQotd() }
    }

    private func refreshQotd() {
        let today = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
        if qotdDateStr != today {
            qotdDateStr = today
            qotdQuestionId = QuestionBank.all.randomElement()?.id ?? -1
            qotdAnsweredIndex = -1
        }
    }

    private var qotdQuestion: Question? {
        QuestionBank.all.first { $0.id == qotdQuestionId }
    }

    // MARK: - Hero

    private var displayName: String {
        userName.isEmpty ? "" : userName
    }

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [.greekBlue, .greekDark],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            Circle().fill(Color.white.opacity(0.07)).frame(width: 200).offset(x: 180, y: -20)
            Circle().fill(Color.white.opacity(0.04)).frame(width: 120).offset(x: 250, y: 40)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Text("🇬🇷").font(.system(size: 38))
                    VStack(alignment: .leading, spacing: 2) {
                        if !displayName.isEmpty {
                            Text(lang.t("Γεια σου, \(displayName)! 👋", "Hey, \(displayName)! 👋"))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white.opacity(0.80))
                        } else {
                            Text(lang.t("Θεωρητική", "Theory"))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.65))
                                .textCase(.uppercase)
                                .tracking(1.2)
                        }
                        Text(lang.t("Εξέταση ΚΟΚ", "KOK Exam"))
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }

                if !displayName.isEmpty {
                    Text(lang.t("Καλή επιτυχία! 🍀", "Good luck! 🍀"))
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white.opacity(0.78))
                } else {
                    Text(lang.t(
                        "30 ερωτήσεις · 45 λεπτά · Μέγιστο 3 λάθη",
                        "30 questions · 45 minutes · Max 3 errors"
                    ))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.72))
                }

                Button { selectedTab = 2 } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.circle.fill")
                        Text(lang.t("Έναρξη Εξέτασης", "Start Exam")).fontWeight(.bold)
                    }
                    .foregroundColor(.greekDark)
                    .padding(.horizontal, 20).padding(.vertical, 11)
                    .background(Color.greekGold)
                    .clipShape(Capsule())
                }
                .padding(.top, 6)
            }
            .padding(24)
        }
        .frame(minHeight: 210)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(color: .greekGold.opacity(0.35), radius: 28, x: 0, y: 12)
    }

    // MARK: - Readiness Card

    private var readinessCard: some View {
        let score = readinessScore
        let color: Color = score >= 90 ? .passGreen : score >= 70 ? .catOrange : score > 0 ? .catRed : .catBlue
        let hasData = !results.isEmpty

        return HStack(spacing: 16) {
            // Ring
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 7)
                    .frame(width: 64, height: 64)
                Circle()
                    .trim(from: 0, to: hasData ? CGFloat(score) / 100.0 : 0)
                    .stroke(color, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .frame(width: 64, height: 64)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 1.0), value: score)
                if hasData {
                    Text("\(score)%")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(color)
                } else {
                    Image(systemName: "questionmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color(.systemGray3))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(lang.t("Ετοιμότητα", "Readiness"))
                    .font(.subheadline.bold())
                if hasData {
                    Text(readinessLabel(score))
                        .font(.caption)
                        .foregroundStyle(color)
                        .fontWeight(.semibold)
                    Text(lang.t("Βάσει των τελευταίων \(min(results.count, 5)) εξετάσεων",
                                "Based on last \(min(results.count, 5)) exams"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Text(lang.t("Κάνε την πρώτη σου εξέταση!", "Take your first exam!"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Streak pill
            if streakCount > 0 {
                VStack(spacing: 4) {
                    Text("🔥")
                        .font(.title2)
                    Text("\(streakCount)")
                        .font(.caption.bold())
                        .foregroundStyle(Color.catOrange)
                    Text(lang.t("μέρες", "days"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
            }
        }
        .padding(16)
        .cardStyle()
    }

    private var readinessScore: Int {
        guard !results.isEmpty else { return 0 }
        let recent = results.prefix(5)
        let avg = Double(recent.map(\.score).reduce(0, +)) / Double(recent.count)
        return Int(avg / 30.0 * 100)
    }

    private func readinessLabel(_ score: Int) -> String {
        switch score {
        case 90...100: return lang.t("Εξαιρετική ετοιμότητα ✓", "Excellent readiness ✓")
        case 70..<90:  return lang.t("Καλή πρόοδος", "Good progress")
        case 50..<70:  return lang.t("Χρειάζεσαι περισσότερη εξάσκηση", "Needs more practice")
        default:       return lang.t("Συνέχισε να προσπαθείς!", "Keep practicing!")
        }
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

    private var passRate: Double {
        guard !results.isEmpty else { return -1 }
        return Double(results.filter(\.passed).count) / Double(results.count)
    }
    private var passRateString: String {
        guard passRate >= 0 else { return "—" }
        return "\(Int(passRate * 100))%"
    }
    private var passRateColor: Color {
        guard passRate >= 0 else { return .catGreen }
        return passRate >= 0.5 ? .catGreen : .catRed
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
                    NavigationLink { StudyCategoryView(category: cat) } label: {
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

    // MARK: - Question of the Day

    private var questionOfTheDay: some View {
        Group {
            if let q = qotdQuestion {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.greekGold.opacity(0.18))
                                .frame(width: 36, height: 36)
                            Image(systemName: "star.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.greekGold)
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text(lang.t("Ερώτηση της Ημέρας", "Question of the Day"))
                                .font(.headline)
                            Text(lang.t("Δοκίμασε τις γνώσεις σου!", "Test your knowledge!"))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if qotdAnsweredIndex >= 0 {
                            Image(systemName: qotdAnsweredIndex == q.correctIndex ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(qotdAnsweredIndex == q.correctIndex ? Color.passGreen : Color.failRed)
                                .font(.title3)
                        }
                    }

                    Divider()

                    switch q.visual {
                    case .none: EmptyView()
                    default:
                        HStack { Spacer(); QuestionVisualView(visual: q.visual, size: 110, borderless: true); Spacer() }
                    }

                    Text(q.text(greek: lang.language.isGreek))
                        .font(.subheadline.weight(.medium))
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(spacing: 6) {
                        ForEach(q.options(greek: lang.language.isGreek).indices, id: \.self) { i in
                            let answered = qotdAnsweredIndex >= 0
                            let isCorrect = i == q.correctIndex
                            let isSelected = i == qotdAnsweredIndex
                            Button {
                                guard qotdAnsweredIndex < 0 else { return }
                                qotdAnsweredIndex = i
                                UIImpactFeedbackGenerator(style: isCorrect ? .medium : .heavy).impactOccurred()
                            } label: {
                                HStack(spacing: 10) {
                                    ZStack {
                                        Circle()
                                            .fill(answered && isCorrect ? Color.passGreen
                                                  : answered && isSelected ? Color.failRed
                                                  : Color(.systemGray5))
                                            .frame(width: 26, height: 26)
                                        Text(["Α","Β","Γ","Δ"][i])
                                            .font(.caption.bold())
                                            .foregroundStyle(answered && (isCorrect || isSelected) ? .white : .secondary)
                                    }
                                    Text(q.options(greek: lang.language.isGreek)[i])
                                        .font(.subheadline)
                                        .foregroundStyle(answered && isCorrect ? Color.passGreen
                                                         : answered && isSelected ? Color.failRed : .primary)
                                        .fontWeight(answered && isCorrect ? .semibold : .regular)
                                        .multilineTextAlignment(.leading)
                                    Spacer()
                                }
                                .padding(.horizontal, 12).padding(.vertical, 9)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(answered && isCorrect ? Color.passGreen.opacity(0.08)
                                              : answered && isSelected ? Color.failRed.opacity(0.08)
                                              : Color(.systemGray6))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(answered && isCorrect ? Color.passGreen.opacity(0.5)
                                                : answered && isSelected ? Color.failRed.opacity(0.5)
                                                : Color.clear, lineWidth: 1.5)
                                )
                            }
                            .disabled(answered)
                        }
                    }

                    if qotdAnsweredIndex >= 0 {
                        let expl = q.explanation(greek: lang.language.isGreek)
                        if !expl.isEmpty {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "lightbulb.fill").foregroundStyle(Color.catOrange).font(.caption)
                                Text(expl).font(.caption).foregroundStyle(.secondary)
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.catOrange.opacity(0.07))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                }
                .padding(16)
                .cardStyle()
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: qotdAnsweredIndex)
            }
        }
    }

    // MARK: - Official Links Card

    private var officialLinksCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Header
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.catBlue.opacity(0.13))
                        .frame(width: 36, height: 36)
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.catBlue)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(lang.t("Επίσημες Πηγές", "Official Resources"))
                        .font(.headline)
                    Text(lang.t("Κυβερνητικές ιστοσελίδες", "Greek government websites"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // Government links
            OfficialLinkRow(
                icon: "checkmark.seal.fill",
                color: .catBlue,
                title: lang.t("Αίτηση Διπλώματος Οδήγησης", "Driving License Application"),
                subtitle: lang.t("Ψηφιακές υπηρεσίες gov.gr", "Digital services on gov.gr"),
                url: "https://www.gov.gr/ipiresies/polites-kai-kathemerinoteta/odegese"
            )
            Divider().padding(.leading, 46)
            OfficialLinkRow(
                icon: "calendar.badge.plus",
                color: .catOrange,
                title: lang.t("Εγγραφή Θεωρητικής Εξέτασης", "Theory Exam Registration"),
                subtitle: lang.t("Δηλώστε συμμετοχή στη θεωρητική εξέταση", "Sign up for the official theory exam"),
                url: "https://www.gov.gr/ipiresies/polites-kai-kathemerinoteta/odegese"
            )
            Divider().padding(.leading, 46)
            OfficialLinkRow(
                icon: "car.fill",
                color: .catGreen,
                title: lang.t("Υπουργείο Υποδομών & Μεταφορών", "Ministry of Infrastructure & Transport"),
                subtitle: lang.t("ΚΟΚ, κανονισμοί & επίσημες ανακοινώσεις", "Highway Code, regulations & official news"),
                url: "https://www.yme.gr"
            )
            Divider().padding(.leading, 46)
            OfficialLinkRow(
                icon: "doc.text.fill",
                color: .catPurple,
                title: lang.t("Απαιτούμενα Δικαιολογητικά", "Required Documents"),
                subtitle: lang.t("Τι χρειάζεστε για την εξέταση οδήγησης", "What you need for the driving exam"),
                url: "https://www.gov.gr/ipiresies/polites-kai-kathemerinoteta/odegese"
            )

            Divider()

            // License categories toggle
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showLicenseInfo.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "car.2.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.greekBlue)
                    Text(lang.t("Κατηγορίες Αδειών Οδήγησης", "Driving License Categories"))
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: showLicenseInfo ? "chevron.up" : "chevron.down")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
            }

            if showLicenseInfo {
                licenseCategories
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .cardStyle()
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showLicenseInfo)
    }

    private var licenseCategories: some View {
        VStack(spacing: 8) {
            licenseCategoryRow(badge: "AM", color: .catGreen,
                vehicle: lang.t("Μοτοποδήλατο / Τρίκυκλο", "Moped / Light Tricycle"),
                age: "16+",
                detail: lang.t("≤50cc, μέγ. 45 km/h", "≤50cc, max 45 km/h"))
            licenseCategoryRow(badge: "A1", color: .catBlue,
                vehicle: lang.t("Μοτοσυκλέτα Α1", "Light Motorcycle"),
                age: "16+",
                detail: lang.t("≤125cc, ≤11kW", "≤125cc, ≤11kW"))
            licenseCategoryRow(badge: "A2", color: .catBlue,
                vehicle: lang.t("Μοτοσυκλέτα Α2", "Medium Motorcycle"),
                age: "18+",
                detail: lang.t("≤35kW, ισχύς/βάρος ≤0.2kW/kg", "≤35kW, power/weight ≤0.2kW/kg"))
            licenseCategoryRow(badge: "A", color: .catPurple,
                vehicle: lang.t("Μοτοσυκλέτα (όλες)", "Motorcycle (all)"),
                age: "20+",
                detail: lang.t("Μετά από 2 χρόνια A2, ή 24+ απευθείας", "After 2 yrs A2, or 24+ direct access"))
            licenseCategoryRow(badge: "B", color: .greekBlue,
                vehicle: lang.t("Αυτοκίνητο", "Car"),
                age: "18+",
                detail: lang.t("≤3500kg, έως 8 επιβάτες", "≤3500kg, up to 8 passengers"))
            licenseCategoryRow(badge: "BE", color: .greekBlue,
                vehicle: lang.t("Αυτοκίνητο με ρυμουλκό", "Car with Trailer"),
                age: "18+",
                detail: lang.t("Κατηγορία B + ρυμουλκό", "Category B + trailer"))
            licenseCategoryRow(badge: "C", color: .catOrange,
                vehicle: lang.t("Φορτηγό", "Heavy Truck"),
                age: "21+",
                detail: lang.t(">3500kg, απαιτείται ΠΕΙ", ">3500kg, CPC certificate required"))
            licenseCategoryRow(badge: "D", color: .catRed,
                vehicle: lang.t("Λεωφορείο", "Bus"),
                age: "24+",
                detail: lang.t("Μεταφορά επιβατών, απαιτείται ΠΕΙ", "Passenger transport, CPC required"))
        }
    }

    private func licenseCategoryRow(badge: String, color: Color, vehicle: String, age: String, detail: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color)
                    .frame(width: 38, height: 38)
                Text(badge)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(vehicle)
                        .font(.subheadline.bold())
                    Spacer()
                    Text(age)
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7).padding(.vertical, 2)
                        .background(color, in: Capsule())
                }
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(color.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Subviews

struct StatPill: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.14)).frame(width: 36, height: 36)
                Image(systemName: icon).font(.system(size: 15, weight: .semibold)).foregroundColor(color)
            }
            Text(value).font(.title3.bold())
            Text(label).font(.caption).foregroundColor(.secondary)
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
                RoundedRectangle(cornerRadius: 12)
                    .fill(categoryColor(category).opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: category.icon).font(.title3).foregroundColor(categoryColor(category))
            }
            Text(category.name(greek: lang.language.isGreek))
                .font(.subheadline.bold()).foregroundColor(.primary).multilineTextAlignment(.leading)
            Text(lang.t("Μελέτη", "Study"))
                .font(.caption).foregroundColor(categoryColor(category))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                Color(.systemBackground)
                LinearGradient(
                    colors: [categoryColor(category).opacity(0.07), .clear],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: categoryColor(category).opacity(0.18), radius: 12, x: 0, y: 4)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(categoryColor(category).opacity(0.2), lineWidth: 1))
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
                    .foregroundColor(result.passed ? .passGreen : .failRed).font(.title3)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(result.passed ? lang.t("Επιτυχία", "Passed") : lang.t("Αποτυχία", "Failed"))
                    .font(.subheadline.bold())
                Text(result.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(result.score)/\(result.totalQuestions)")
                    .font(.headline.bold())
                    .foregroundColor(result.passed ? .passGreen : .failRed)
                Text("\(result.errors) \(lang.t("λάθη", "errors"))")
                    .font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(14)
        .cardStyle()
    }
}

// MARK: - StudyCategoryView

struct StudyCategoryView: View {
    @Environment(LanguageManager.self) private var lang
    @Query private var bookmarks: [BookmarkedQuestion]
    @Environment(\.modelContext) private var modelContext
    let category: QuestionCategory
    var questions: [Question] { QuestionBank.all.filter { $0.category == category } }

    var body: some View {
        ZStack {
            AppBackground()
            List {
                ForEach(questions) { q in
                    StudyQuestionRow(question: q, isBookmarked: isBookmarked(q.id)) { toggleBookmark(q.id) }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(category.name(greek: lang.language.isGreek))
        .navigationBarTitleDisplayMode(.large)
    }

    private func isBookmarked(_ id: Int) -> Bool { bookmarks.contains { $0.questionId == id } }
    private func toggleBookmark(_ id: Int) {
        if let ex = bookmarks.first(where: { $0.questionId == id }) { modelContext.delete(ex) }
        else { modelContext.insert(BookmarkedQuestion(questionId: id)) }
    }
}
// MARK: - Official Link Row

struct OfficialLinkRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    let url: String

    var body: some View {
        Group {
            if let destination = URL(string: url) {
                Link(destination: destination) {
                    rowContent
                }
            } else {
                rowContent
            }
        }
    }

    private var rowContent: some View {
        HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.12))
                        .frame(width: 34, height: 34)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(color)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
        }
    }
}

