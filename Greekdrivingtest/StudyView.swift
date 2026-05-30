import SwiftUI
import SwiftData

// MARK: - Filter Pill
struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.bold())
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? color : color.opacity(0.12))
                .foregroundColor(isSelected ? .white : color)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Study Question Row
struct StudyQuestionRow: View {
    @Environment(LanguageManager.self) private var lang
    let question: Question
    let isBookmarked: Bool
    let onBookmark: () -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(alignment: .top, spacing: 10) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(categoryColor(question.category))
                        .frame(width: 4, height: 40)

                    Text(question.text(greek: lang.language.isGreek))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
                .padding(14)
            }

            if isExpanded {
                Divider().padding(.horizontal, 14)

                VStack(alignment: .leading, spacing: 12) {
                    switch question.visual {
                    case .none:
                        EmptyView()
                    default:
                        HStack {
                            Spacer()
                            QuestionVisualView(visual: question.visual, size: 200, borderless: true)
                            Spacer()
                        }
                        .padding(.top, 8)
                    }

                    ForEach(question.options(greek: lang.language.isGreek).indices, id: \.self) { i in
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(i == question.correctIndex
                                          ? Color.passGreen
                                          : Color(.systemGray5))
                                    .frame(width: 28, height: 28)
                                Text(["Α","Β","Γ","Δ"][i])
                                    .font(.caption.bold())
                                    .foregroundColor(i == question.correctIndex ? .white : .secondary)
                            }
                            Text(question.options(greek: lang.language.isGreek)[i])
                                .font(.subheadline)
                                .foregroundColor(i == question.correctIndex ? .passGreen : .primary)
                                .fontWeight(i == question.correctIndex ? .semibold : .regular)
                        }
                    }

                    let expl = question.explanation(greek: lang.language.isGreek)
                    if !expl.isEmpty {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.catBlue)
                                .font(.caption)
                                .padding(.top, 1)
                            Text(expl)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(10)
                        .background(Color.catBlue.opacity(0.07))
                        .cornerRadius(10)
                    }

                    HStack {
                        Spacer()
                        Button(action: onBookmark) {
                            Label(
                                isBookmarked
                                    ? lang.t("Αφαίρεση", "Remove")
                                    : lang.t("Αποθήκευση", "Bookmark"),
                                systemImage: isBookmarked ? "bookmark.fill" : "bookmark"
                            )
                            .font(.caption.bold())
                            .foregroundColor(isBookmarked ? .greekGold : .secondary)
                        }
                    }
                }
                .padding(14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .cardStyle()
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded)
    }
}

// MARK: - Flashcard Session (Observable)
@Observable
class FlashcardSession {
    let questions: [Question]
    let onFinish: (Int, Int, [Int]) -> Void

    var currentIndex = 0
    var correctCount = 0
    var currentStreak = 0
    var bestStreak = 0
    var incorrectIds: Set<Int> = []

    init(questions: [Question],
         onFinish: @escaping (Int, Int, [Int]) -> Void = { _, _, _ in }) {
        self.questions = questions
        self.onFinish = onFinish
    }

    var weakQuestionIds: [Int] { Array(incorrectIds) }

    enum AnswerResult { case correct, incorrect }

    func advanceWithResult(_ result: AnswerResult) {
        guard currentIndex < questions.count else { return }
        let q = questions[currentIndex]

        switch result {
        case .correct:
            correctCount += 1
            currentStreak += 1
            if currentStreak > bestStreak { bestStreak = currentStreak }
        case .incorrect:
            currentStreak = 0
            incorrectIds.insert(q.id)
        }

        currentIndex += 1

        if currentIndex >= questions.count {
            onFinish(correctCount, questions.count, Array(incorrectIds))
        }
    }

    func reset() {
        currentIndex = 0
        correctCount = 0
        currentStreak = 0
        bestStreak = 0
        incorrectIds = []
    }

    var allAnswered: Bool { currentIndex >= questions.count }
}

// MARK: - FlashcardCard (premium iOS style)
struct FlashcardCard: View {
    @Environment(LanguageManager.self) private var lang
    @Environment(\.modelContext) private var modelContext
    @Query private var difficultQuestions: [DifficultQuestion]
    let question: Question
    let onAnswer: (Int) -> Void
    let onDontRemember: () -> Void
    let selectedAnswer: Int?
    let revealedCorrect: Bool
    let isAnswered: Bool

    private func isDifficult(_ id: Int) -> Bool { difficultQuestions.contains { $0.questionId == id } }
    private func toggleDifficult(_ id: Int) {
        if let ex = difficultQuestions.first(where: { $0.questionId == id }) { modelContext.delete(ex) }
        else { modelContext.insert(DifficultQuestion(questionId: id)) }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [Color(.systemBackground), Color(.systemGray6).opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.08), radius: 24, x: 0, y: 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(categoryColor(question.category).opacity(0.25), lineWidth: 1)
                )

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    HStack {
                        Text(question.category.name(greek: lang.language.isGreek).uppercased())
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(categoryColor(question.category))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(categoryColor(question.category).opacity(0.12))
                            .clipShape(Capsule())
                        Spacer()
                        Button { toggleDifficult(question.id) } label: {
                            Image(systemName: isDifficult(question.id) ? "flag.fill" : "flag")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(isDifficult(question.id) ? Color.catOrange : Color(.systemGray3))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    switch question.visual {
                    case .none: EmptyView()
                    default:
                        QuestionVisualView(visual: question.visual, size: 200, borderless: true)
                    }

                    Text(question.text(greek: lang.language.isGreek))
                        .font(.title3.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)

                    Divider()
                        .padding(.horizontal, 20)

                    ForEach(question.options(greek: lang.language.isGreek).indices, id: \.self) { i in
                        Button {
                            guard !isAnswered else { return }
                            onAnswer(i)
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    if isAnswered && i == question.correctIndex {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title3)
                                            .foregroundColor(.green)
                                    } else if isAnswered && i == selectedAnswer {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title3)
                                            .foregroundColor(.red)
                                    } else {
                                        Text(["Α","Β","Γ","Δ"][i])
                                            .font(.subheadline.weight(.bold))
                                            .foregroundColor(.secondary)
                                            .frame(width: 32, height: 32)
                                            .background(Color(.systemGray5))
                                            .clipShape(Circle())
                                    }
                                }

                                Text(question.options(greek: lang.language.isGreek)[i])
                                    .font(.subheadline)
                                    .foregroundColor(
                                        isAnswered && i == question.correctIndex ? .green :
                                        isAnswered && i == selectedAnswer ? .red :
                                        .primary
                                    )
                                    .fontWeight(isAnswered && i == question.correctIndex ? .bold : .regular)
                                    .multilineTextAlignment(.leading)

                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        isAnswered && i == question.correctIndex ? Color.green.opacity(0.08) :
                                        isAnswered && i == selectedAnswer ? Color.red.opacity(0.08) :
                                        Color.clear
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        isAnswered && i == question.correctIndex ? Color.green.opacity(0.5) :
                                        isAnswered && i == selectedAnswer ? Color.red.opacity(0.5) :
                                        Color.clear,
                                        lineWidth: 1.5
                                    )
                            )
                        }
                        .disabled(isAnswered)
                    }

                    if !isAnswered {
                        Button {
                            onDontRemember()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "eye.slash")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                Text(lang.t("Δεν θυμάμαι", "I don't remember"))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.orange)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .overlay(
                                Capsule()
                                    .stroke(Color.orange.opacity(0.5), lineWidth: 1.5)
                            )
                        }
                        .padding(.top, 4)
                    }

                    if isAnswered {
                        let expl = question.explanation(greek: lang.language.isGreek)
                        if !expl.isEmpty {
                            HStack(spacing: 8) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                                Text(expl)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.yellow.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    Spacer(minLength: 12)
                }
                .padding(.vertical, 8)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - FlashcardSessionView (premium iOS style)
struct FlashcardSessionView: View {
    @Environment(LanguageManager.self) private var lang
    @State private var session: FlashcardSession

    let onReturn: () -> Void
    let onStartWeak: ([Int]) -> Void

    @State private var selectedAnswer: Int? = nil
    @State private var revealedCorrect = false
    @State private var isAnswered = false
    @State private var pendingResult: FlashcardSession.AnswerResult? = nil
    @State private var sessionVersion = 0

    init(session: FlashcardSession,
         onReturn: @escaping () -> Void = {},
         onStartWeak: @escaping ([Int]) -> Void = { _ in }) {
        _session = State(initialValue: session)
        self.onReturn = onReturn
        self.onStartWeak = onStartWeak
    }

    private var allAnswered: Bool { session.currentIndex >= session.questions.count }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(lang.t("Πρόοδος", "Progress"))
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(session.currentIndex + 1) / \(session.questions.count)")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.greekBlue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.greekBlue.opacity(0.1))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                    Capsule()
                        .fill(Color.greekBlue)
                        .frame(width: max(0, geo.size.width * CGFloat(session.currentIndex + 1) / CGFloat(max(1, session.questions.count))),
                               height: 6)
                        .animation(.spring(response: 0.5), value: session.currentIndex)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            if allAnswered {
                sessionSummaryView
            } else {
                let question = session.questions[session.currentIndex]
                FlashcardCard(
                    question: question,
                    onAnswer: { index in
                        selectedAnswer = index
                        revealedCorrect = false
                        isAnswered = true
                        if index == question.correctIndex {
                            pendingResult = .correct
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } else {
                            pendingResult = .incorrect
                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                        }
                    },
                    onDontRemember: {
                        revealedCorrect = true
                        isAnswered = true
                        pendingResult = .incorrect
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    },
                    selectedAnswer: selectedAnswer,
                    revealedCorrect: revealedCorrect,
                    isAnswered: isAnswered
                )
                .padding(.horizontal, 8)
                .padding(.vertical, 4)

                if isAnswered {
                    Button {
                        advanceToNext()
                    } label: {
                        HStack(spacing: 8) {
                            Text(session.currentIndex >= session.questions.count
                                 ? lang.t("Τέλος", "Finish")
                                 : lang.t("Επόμενη", "Next"))
                                .font(.headline.weight(.semibold))
                            Image(systemName: "arrow.right")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.greekBlue, .greekDark],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: .greekBlue.opacity(0.3), radius: 12, x: 0, y: 6)
                        .padding(.horizontal, 20)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .animation(.spring(response: 0.35), value: isAnswered)
    }

    private func advanceToNext() {
        if let result = pendingResult {
            session.advanceWithResult(result)
            pendingResult = nil
        }
        withAnimation(.spring(response: 0.3)) {
            selectedAnswer = nil
            revealedCorrect = false
            isAnswered = false
            sessionVersion += 1
        }
    }

    @ViewBuilder
    private var sessionSummaryView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: session.correctCount >= session.questions.count / 2
                  ? "star.fill" : "star")
                .font(.system(size: 60))
                .foregroundColor(.greekGold)
            Text(lang.t("Η συνεδρία ολοκληρώθηκε!", "Session Complete!"))
                .font(.title2.bold())
            Text("\(session.correctCount) / \(session.questions.count)")
                .font(.largeTitle.bold())
                .foregroundColor(.greekBlue)
            let pct = session.questions.isEmpty ? 0 : Double(session.correctCount) / Double(session.questions.count) * 100
            Text(String(format: "%.0f%%", pct))
                .font(.title3)
                .foregroundColor(.secondary)
            if session.bestStreak >= 3 {
                HStack(spacing: 4) {
                    Text("🔥")
                    Text(lang.t("Καλύτερο σερί:", "Best streak:") + " \(session.bestStreak)")
                        .font(.subheadline.bold())
                }
            }
            let weakIds = session.weakQuestionIds
            if !weakIds.isEmpty {
                VStack(spacing: 8) {
                    Text(lang.t("Ερωτήσεις που χρειάζονται εξάσκηση:", "Questions needing practice:"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button {
                        onStartWeak(Array(weakIds))
                    } label: {
                        Text(lang.t("Εξάσκηση αδύναμων καρτών", "Practice Weak Cards"))
                            .font(.subheadline.bold())
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(Color.orange))
                            .foregroundColor(.white)
                    }
                }
            }
            HStack(spacing: 20) {
                Button(lang.t("Επανάληψη", "Retry")) {
                    session.reset()
                }
                .buttonStyle(.bordered)
                Button(lang.t("Επιστροφή", "Return")) {
                    onReturn()
                }
                .buttonStyle(.borderedProminent)
            }
            Spacer()
        }
        .padding()
    }
}

// MARK: - Intensive Practice View

struct IntensivePracticeView: View {
    @Environment(LanguageManager.self) private var lang
    @Query(sort: \TestResult.date, order: .reverse) private var results: [TestResult]
    @Query private var difficultQuestions: [DifficultQuestion]
    @AppStorage("wrongQuestionsResetTimestamp") private var resetTimestamp: Double = 0

    @State private var selectedCategories: Set<QuestionCategory> = Set(QuestionCategory.allCases)
    @State private var questionCount: CountOption = .twenty
    @State private var sourceMode: SourceMode = .all
    @State private var activeSession: FlashcardSession? = nil
    @State private var showReset = false
    @State private var showSpeedRound = false
    @State private var cachedPool: [Question] = []
    @State private var categoryCounts: [QuestionCategory: Int] = [:]

    enum CountOption: Int, CaseIterable {
        case ten = 10, twenty = 20, thirty = 30, all = 0
        func label(greek: Bool) -> String {
            switch self {
            case .all: return greek ? "Όλες" : "All"
            default: return "\(rawValue)"
            }
        }
    }

    enum SourceMode { case all, wrongOnly, difficultOnly }

    var wrongIds: Set<Int> {
        let cutoff = Date(timeIntervalSince1970: resetTimestamp)
        return Set(results.filter { $0.date > cutoff }.flatMap { $0.wrongQuestionIds })
    }

    var difficultIds: Set<Int> { Set(difficultQuestions.map(\.questionId)) }

    private func updatePool() {
        let wIds = wrongIds
        let dIds = difficultIds
        var base: [Question]
        switch sourceMode {
        case .all:
            base = QuestionBank.all.filter { selectedCategories.contains($0.category) }
        case .wrongOnly:
            base = QuestionBank.all.filter { wIds.contains($0.id) && selectedCategories.contains($0.category) }
        case .difficultOnly:
            base = QuestionBank.all.filter { dIds.contains($0.id) && selectedCategories.contains($0.category) }
        }
        base = base.shuffled()
        if questionCount != .all && questionCount.rawValue < base.count {
            base = Array(base.prefix(questionCount.rawValue))
        }
        cachedPool = base

        let filterIds: Set<Int>?
        switch sourceMode {
        case .all: filterIds = nil
        case .wrongOnly: filterIds = wIds
        case .difficultOnly: filterIds = dIds
        }
        var counts: [QuestionCategory: Int] = [:]
        for q in QuestionBank.all {
            if let ids = filterIds {
                if ids.contains(q.id) { counts[q.category, default: 0] += 1 }
            } else {
                counts[q.category, default: 0] += 1
            }
        }
        categoryCounts = counts
    }

    var body: some View {
        Group {
            if showSpeedRound {
                SpeedRoundView(
                    questions: cachedPool.isEmpty ? Array(QuestionBank.all.shuffled().prefix(30)) : cachedPool,
                    onReturn: { showSpeedRound = false }
                )
            } else if let session = activeSession {
                FlashcardSessionView(
                    session: session,
                    onReturn: { activeSession = nil },
                    onStartWeak: { weakIds in
                        let weak = QuestionBank.all.filter { weakIds.contains($0.id) }
                        if !weak.isEmpty {
                            activeSession = FlashcardSession(questions: weak, onFinish: { _, _, _ in activeSession = nil })
                        }
                    }
                )
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        sourcePicker
                        if sourceMode == .wrongOnly { wrongBankCard }
                        categorySection
                        countSection
                        startButton
                        speedChallengeCard
                    }
                    .padding(16)
                    .iPadReadableWidth()
                }
            }
        }
        .onAppear { updatePool() }
        .onChange(of: sourceMode) { _, _ in updatePool() }
        .onChange(of: selectedCategories) { _, _ in updatePool() }
        .onChange(of: questionCount) { _, _ in updatePool() }
        .onChange(of: results) { _, _ in updatePool() }
        .onChange(of: difficultQuestions) { _, _ in updatePool() }
    }

    // MARK: Source Picker
    private var sourcePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(lang.t("Πηγή Ερωτήσεων", "Question Source"))
                .font(.headline)

            VStack(spacing: 8) {
                sourceRow(
                    mode: .all,
                    icon: "books.vertical.fill",
                    color: .greekBlue,
                    title: lang.t("Όλες οι ερωτήσεις", "All questions"),
                    subtitle: "\(QuestionBank.all.count) \(lang.t("ερωτήσεις", "questions"))"
                )
                sourceRow(
                    mode: .wrongOnly,
                    icon: "xmark.circle.fill",
                    color: .catRed,
                    title: lang.t("Λάθος ερωτήσεις", "Wrong questions"),
                    subtitle: "\(wrongIds.count) \(lang.t("αποθηκευμένες", "stored"))"
                )
                sourceRow(
                    mode: .difficultOnly,
                    icon: "flag.fill",
                    color: .catOrange,
                    title: lang.t("Δύσκολες ερωτήσεις", "Difficult questions"),
                    subtitle: "\(difficultIds.count) \(lang.t("επισημασμένες", "flagged"))"
                )
            }
        }
    }

    private func sourceRow(mode: SourceMode, icon: String, color: Color, title: String, subtitle: String) -> some View {
        let selected = sourceMode == mode
        return Button { sourceMode = mode } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(selected ? color : color.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(selected ? .white : color)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline.bold())
                        .foregroundStyle(selected ? .white : .primary)
                    Text(subtitle).font(.caption)
                        .foregroundStyle(selected ? .white.opacity(0.75) : .secondary)
                }
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.9))
                        .font(.title3)
                }
            }
            .padding(14)
            .background(selected ? color : Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(selected ? color : color.opacity(0.2), lineWidth: 1))
            .shadow(color: selected ? color.opacity(0.3) : .black.opacity(0.04), radius: 8, x: 0, y: 3)
        }
        .animation(.spring(response: 0.25), value: selected)
    }

    // MARK: Wrong Bank Card
    private var wrongBankCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.catRed.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.catRed)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(lang.t("Τράπεζα Λαθών", "Wrong Question Bank"))
                    .font(.subheadline.bold())
                Text(lang.t("\(wrongIds.count) αποθηκευμένες από εξετάσεις", "\(wrongIds.count) saved from exams"))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button { showReset = true } label: {
                Text(lang.t("Επαναφορά", "Reset"))
                    .font(.caption.bold())
                    .foregroundStyle(Color.catRed)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color.catRed.opacity(0.1))
                    .clipShape(Capsule())
            }
            .disabled(wrongIds.isEmpty)
            .opacity(wrongIds.isEmpty ? 0.4 : 1)
        }
        .padding(14)
        .cardStyle()
        .confirmationDialog(
            lang.t("Επαναφορά τράπεζας λαθών;", "Reset wrong questions bank?"),
            isPresented: $showReset,
            titleVisibility: .visible
        ) {
            Button(lang.t("Επαναφορά", "Reset"), role: .destructive) {
                resetTimestamp = Date().timeIntervalSince1970
                if sourceMode == .wrongOnly { sourceMode = .all }
            }
            Button(lang.t("Ακύρωση", "Cancel"), role: .cancel) {}
        } message: {
            Text(lang.t("Αυτό θα σβήσει όλη την ιστορία λάθος ερωτήσεων.", "This clears all wrong question history."))
        }
    }

    // MARK: Category Section
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(lang.t("Κατηγορίες", "Categories"))
                    .font(.headline)
                Spacer()
                Button {
                    if selectedCategories.count == QuestionCategory.allCases.count {
                        selectedCategories = []
                    } else {
                        selectedCategories = Set(QuestionCategory.allCases)
                    }
                } label: {
                    Text(selectedCategories.count == QuestionCategory.allCases.count
                         ? lang.t("Αποεπιλογή", "Deselect All")
                         : lang.t("Όλες", "Select All"))
                        .font(.caption.bold())
                        .foregroundColor(.greekBlue)
                }
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(QuestionCategory.allCases, id: \.self) { cat in
                    categoryToggle(cat)
                }
            }
        }
    }

    private func categoryToggle(_ cat: QuestionCategory) -> some View {
        let selected = selectedCategories.contains(cat)
        let color = categoryColor(cat)
        let count = categoryCounts[cat] ?? 0

        return Button {
            if selected { selectedCategories.remove(cat) }
            else { selectedCategories.insert(cat) }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: cat.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(selected ? .white : color)
                    .frame(width: 34, height: 34)
                    .background(selected ? color : color.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(cat.name(greek: lang.language.isGreek))
                        .font(.caption.bold())
                        .foregroundColor(selected ? .white : .primary)
                        .lineLimit(1)
                    Text("\(count)")
                        .font(.caption2)
                        .foregroundColor(selected ? .white.opacity(0.75) : .secondary)
                }
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                }
            }
            .padding(10)
            .background(selected ? color : Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(selected ? color : color.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: selected ? color.opacity(0.3) : .black.opacity(0.04), radius: 6, x: 0, y: 3)
        }
        .animation(.spring(response: 0.25), value: selected)
    }

    // MARK: Count Section
    private var countSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(lang.t("Αριθμός Ερωτήσεων", "Question Count"))
                .font(.headline)

            HStack(spacing: 8) {
                ForEach(CountOption.allCases, id: \.self) { opt in
                    Button {
                        questionCount = opt
                    } label: {
                        Text(opt.label(greek: lang.language.isGreek))
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(questionCount == opt ? Color.greekBlue : Color(.systemGray6))
                            .foregroundColor(questionCount == opt ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .animation(.spring(response: 0.2), value: questionCount)
                }
            }
        }
    }

    // MARK: Start Button
    private var startButton: some View {
        let count = cachedPool.count
        let canStart = !selectedCategories.isEmpty && count > 0

        return VStack(spacing: 6) {
            Button {
                guard canStart else { return }
                activeSession = FlashcardSession(questions: cachedPool, onFinish: { _, _, _ in })
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "bolt.fill")
                    Text(lang.t("Έναρξη Εντατικής", "Start Intensive"))
                        .fontWeight(.bold)
                    Spacer()
                    Text("\(count) \(lang.t("ερωτήσεις", "questions"))")
                        .font(.subheadline)
                        .opacity(0.8)
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    canStart
                        ? LinearGradient(colors: [.greekBlue, .greekDark], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [Color(.systemGray4), Color(.systemGray4)], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: canStart ? .greekBlue.opacity(0.35) : .clear, radius: 12, x: 0, y: 6)
            }
            .disabled(!canStart)

            if !canStart {
                Text(lang.t("Επιλέξτε τουλάχιστον μία κατηγορία", "Select at least one category"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: Speed Challenge Card
    private var speedChallengeCard: some View {
        Button { showSpeedRound = true } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.catOrange.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: "bolt.fill")
                        .font(.title3)
                        .foregroundColor(.catOrange)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(lang.t("Αγώνας Ταχύτητας", "Speed Challenge"))
                        .font(.headline.bold())
                        .foregroundColor(.primary)
                    Text(lang.t("60 δευτερόλεπτα · Απάντα γρήγορα!", "60 seconds · Answer fast!"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.catOrange.opacity(0.3), lineWidth: 1))
            .shadow(color: Color.catOrange.opacity(0.12), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Speed Round View

struct SpeedRoundView: View {
    @Environment(LanguageManager.self) private var lang
    @AppStorage("speedRoundBest") private var personalBest: Int = 0

    let questions: [Question]
    let onReturn: () -> Void

    @State private var currentIndex = 0
    @State private var score = 0
    @State private var answered = 0
    @State private var timeLeft = 60
    @State private var isFinished = false
    @State private var flashGreen = false
    @State private var flashRed = false
    @State private var isNewBest = false

    private var currentQuestion: Question? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    var body: some View {
        ZStack {
            AppBackground()

            if isFinished {
                finishedView
            } else {
                VStack(spacing: 0) {
                    topBar
                    if let q = currentQuestion {
                        questionContent(q)
                    } else {
                        Spacer()
                        Text(lang.t("Ολοκληρώθηκαν οι ερωτήσεις!", "All questions done!"))
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }

            if flashGreen {
                Color.green.opacity(0.18)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
            if flashRed {
                Color.red.opacity(0.18)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .task(id: isFinished) {
            guard !isFinished else { return }
            while !isFinished && timeLeft > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !isFinished else { return }
                timeLeft -= 1
                if timeLeft == 10 {
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                }
            }
            if !isFinished { finish() }
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Button { finish() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(Color(.systemGray3))
            }

            Spacer()

            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 4)
                    .frame(width: 52, height: 52)
                Circle()
                    .trim(from: 0, to: CGFloat(timeLeft) / 60.0)
                    .stroke(timerColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 52, height: 52)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timeLeft)
                Text("\(timeLeft)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(timerColor)
            }

            Spacer()

            VStack(spacing: 2) {
                Text("\(score)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.passGreen)
                Text(lang.t("σωστά", "correct"))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 60)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var timerColor: Color {
        if timeLeft > 20 { return .greekBlue }
        if timeLeft > 10 { return .catOrange }
        return .catRed
    }

    @ViewBuilder
    private func questionContent(_ q: Question) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("\(lang.t("Ερώτηση", "Question")) \(answered + 1)")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12).padding(.vertical, 5)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())

                switch q.visual {
                case .none: EmptyView()
                default:
                    QuestionVisualView(visual: q.visual, size: 80)
                }

                Text(q.text(greek: lang.language.isGreek))
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                VStack(spacing: 10) {
                    ForEach(q.options(greek: lang.language.isGreek).indices, id: \.self) { i in
                        speedAnswerButton(q: q, index: i)
                    }
                }
                .padding(.horizontal, 16)

                Spacer(minLength: 20)
            }
            .padding(.vertical, 12)
            .iPadReadableWidth()
        }
    }

    private func speedAnswerButton(q: Question, index: Int) -> some View {
        Button {
            tapAnswer(q: q, index: index)
        } label: {
            HStack(spacing: 14) {
                Text(["Α","Β","Γ","Δ"][index])
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.greekBlue)
                    .clipShape(Circle())

                Text(q.options(greek: lang.language.isGreek)[index])
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(.systemGray5), lineWidth: 1)
            )
        }
    }

    private var finishedView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(score > answered / 2 ? Color.passGreen.opacity(0.12) : Color.catRed.opacity(0.12))
                    .frame(width: 120, height: 120)
                Text(score > answered / 2 ? "⚡" : "💪")
                    .font(.system(size: 56))
            }

            VStack(spacing: 8) {
                Text(lang.t("Χρόνος τελείωσε!", "Time's up!"))
                    .font(.title2.bold())
                HStack(spacing: 4) {
                    Text("\(score)")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundColor(.greekBlue)
                    Text("/ \(answered)")
                        .font(.title.weight(.medium))
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
                Text(lang.t("σωστά σε \(answered) ερωτήσεις", "correct out of \(answered) questions"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if isNewBest && personalBest > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.greekGold)
                    Text(lang.t("Νέο Ρεκόρ! 🎉", "New Personal Best! 🎉"))
                        .font(.headline.bold())
                        .foregroundColor(.greekGold)
                }
                .padding(.horizontal, 20).padding(.vertical, 12)
                .background(Color.greekGold.opacity(0.12))
                .clipShape(Capsule())
            } else if personalBest > 0 {
                Text(lang.t("Καλύτερο: \(personalBest)", "Best: \(personalBest)"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 16) {
                Button { onReturn() } label: {
                    Text(lang.t("Τέλος", "Exit"))
                        .font(.headline)
                        .foregroundColor(.greekBlue)
                        .padding(.horizontal, 28).padding(.vertical, 14)
                        .overlay(Capsule().stroke(Color.greekBlue, lineWidth: 1.5))
                }

                Button { restart() } label: {
                    Text(lang.t("Ξανά!", "Again!"))
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 28).padding(.vertical, 14)
                        .background(
                            Capsule().fill(LinearGradient(
                                colors: [.greekBlue, .greekDark],
                                startPoint: .leading, endPoint: .trailing
                            ))
                        )
                }
            }

            Spacer()
        }
        .padding()
    }

    private func tapAnswer(q: Question, index: Int) {
        guard !isFinished else { return }
        let correct = index == q.correctIndex
        if correct {
            score += 1
            withAnimation(.easeOut(duration: 0.1)) { flashGreen = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation { flashGreen = false }
            }
        } else {
            withAnimation(.easeOut(duration: 0.1)) { flashRed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation { flashRed = false }
            }
        }
        answered += 1
        currentIndex += 1
        UIImpactFeedbackGenerator(style: correct ? .medium : .heavy).impactOccurred()
        if currentIndex >= questions.count { finish() }
    }

    private func finish() {
        guard !isFinished else { return }
        if score > personalBest {
            personalBest = score
            isNewBest = true
        }
        isFinished = true
    }

    private func restart() {
        currentIndex = 0
        score = 0
        answered = 0
        timeLeft = 60
        isFinished = false
        isNewBest = false
    }
}

// MARK: - Main Study Tab
struct StudyView: View {
    @Environment(LanguageManager.self) private var lang
    @Query private var bookmarks: [BookmarkedQuestion]
    @Environment(\.modelContext) private var modelContext

    @State private var selectedCategory: QuestionCategory? = nil
    @State private var showBookmarksOnly = false
    @State private var searchText = ""
    @State private var studyMode: StudyMode = .browse
    @State private var flashcardSession: FlashcardSession? = nil
    @State private var filteredQuestions: [Question] = QuestionBank.all

    private func updateFiltered() {
        var q = QuestionBank.all
        if let cat = selectedCategory { q = q.filter { $0.category == cat } }
        if showBookmarksOnly {
            let ids = Set(bookmarks.map(\.questionId))
            q = q.filter { ids.contains($0.id) }
        }
        if !searchText.isEmpty {
            let isGreek = lang.language.isGreek
            q = q.filter { $0.text(greek: isGreek).localizedCaseInsensitiveContains(searchText) }
        }
        filteredQuestions = q
    }

    enum StudyMode: String, CaseIterable {
        case browse, flashcards, intensive
        var greekName: String {
            switch self {
            case .browse: return "Ανάγνωση"
            case .flashcards: return "Κάρτες"
            case .intensive: return "Εντατική"
            }
        }
        var englishName: String {
            switch self {
            case .browse: return "Browse"
            case .flashcards: return "Cards"
            case .intensive: return "Intensive"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                VStack(spacing: 0) {
                    Picker(lang.t("Τρόπος", "Mode"), selection: $studyMode) {
                        ForEach(StudyMode.allCases, id: \.self) { mode in
                            Text(lang.t(mode.greekName, mode.englishName)).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    if studyMode != .intensive {
                        categoryPills
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }

                    if studyMode == .browse {
                        browseContent
                    } else if studyMode == .flashcards {
                        flashcardContent
                    } else {
                        IntensivePracticeView()
                            .padding(.top, 8)
                    }
                }
            }
            .navigationTitle(lang.t("Μελέτη", "Study"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if studyMode != .intensive {
                        Button { showBookmarksOnly.toggle() } label: {
                            Image(systemName: showBookmarksOnly ? "bookmark.fill" : "bookmark")
                                .foregroundColor(showBookmarksOnly ? .greekGold : .primary)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: lang.t("Αναζήτηση...", "Search..."))
        }
        .onAppear { updateFiltered() }
        .onChange(of: selectedCategory) { _, _ in updateFiltered(); resetFlashcardSessionIfNeeded() }
        .onChange(of: showBookmarksOnly) { _, _ in updateFiltered(); resetFlashcardSessionIfNeeded() }
        .onChange(of: searchText) { _, _ in updateFiltered(); resetFlashcardSessionIfNeeded() }
        .onChange(of: bookmarks) { _, _ in updateFiltered() }
        .onChange(of: lang.language) { _, _ in updateFiltered() }
    }

    @ViewBuilder
    private var browseContent: some View {
        if filteredQuestions.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredQuestions) { q in
                        StudyQuestionRow(question: q, isBookmarked: isBookmarked(q.id)) {
                            toggleBookmark(q.id)
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 4)
                .iPadReadableWidth()
            }
        }
    }

    @ViewBuilder
    private var flashcardContent: some View {
        if filteredQuestions.isEmpty {
            emptyState
        } else if let session = flashcardSession {
            FlashcardSessionView(
                session: session,
                onReturn: { flashcardSession = nil },
                onStartWeak: { weakIds in
                    let weakQuestions = QuestionBank.all.filter { weakIds.contains($0.id) }
                    if !weakQuestions.isEmpty {
                        flashcardSession = FlashcardSession(
                            questions: weakQuestions,
                            onFinish: { _, _, _ in flashcardSession = nil }
                        )
                    }
                }
            )
        } else {
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "rectangle.on.rectangle.angled")
                    .font(.system(size: 60))
                    .foregroundColor(.greekBlue.opacity(0.6))
                Text(lang.t("Ξεκινήστε μια συνεδρία καρτών μελέτης", "Start a flashcard session"))
                    .font(.headline)
                    .foregroundColor(.secondary)
                Button {
                    startFlashcardSession(questions: filteredQuestions)
                } label: {
                    Label(lang.t("Ξεκινήστε Flashcards", "Start Flashcards"), systemImage: "play.fill")
                        .font(.title3.bold())
                        .padding(.horizontal, 30)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(Color.greekBlue))
                        .foregroundColor(.white)
                }
                Spacer()
            }
        }
    }

    private func startFlashcardSession(questions: [Question]) {
        let shuffled = questions.shuffled()
        flashcardSession = FlashcardSession(questions: shuffled)
    }

    private func resetFlashcardSessionIfNeeded() {
        flashcardSession = nil
    }

    private var categoryPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterPill(title: lang.t("Όλες", "All"),
                           isSelected: selectedCategory == nil, color: .greekBlue) {
                    selectedCategory = nil
                }
                ForEach(QuestionCategory.allCases, id: \.self) { cat in
                    FilterPill(title: cat.name(greek: lang.language.isGreek),
                               isSelected: selectedCategory == cat,
                               color: categoryColor(cat)) {
                        selectedCategory = (selectedCategory == cat) ? nil : cat
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text(lang.t("Δεν βρέθηκαν ερωτήσεις", "No questions found"))
                .font(.headline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    private func isBookmarked(_ id: Int) -> Bool {
        bookmarks.contains { $0.questionId == id }
    }

    private func toggleBookmark(_ id: Int) {
        if let existing = bookmarks.first(where: { $0.questionId == id }) {
            modelContext.delete(existing)
        } else {
            modelContext.insert(BookmarkedQuestion(questionId: id))
        }
    }
}

// MARK: - Category Question Card
struct CategoryQuestionCard: View {
    @Environment(LanguageManager.self) private var lang
    let question: Question
    let index: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Circle()
                    .fill(categoryColor(question.category))
                    .frame(width: 8, height: 8)
                Text("\(index + 1)")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(categoryColor(question.category))
            }

            switch question.visual {
            case .none: EmptyView()
            default:
                QuestionVisualView(visual: question.visual, size: 80)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            Text(question.text(greek: lang.language.isGreek))
                .font(.caption.weight(.medium))
                .foregroundColor(.primary)
                .lineLimit(3)

            Spacer()
        }
        .padding(12)
        .frame(minHeight: 140)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(categoryColor(question.category).opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Flashcard Detail View (full-screen card review)
struct FlashcardDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(LanguageManager.self) private var lang

    let question: Question
    let allQuestions: [Question]
    let currentIndex: Int
    let isBookmarked: Bool
    let onBookmark: () -> Void

    @State private var index: Int
    @State private var showAnswer = false

    init(question: Question, allQuestions: [Question], currentIndex: Int, isBookmarked: Bool, onBookmark: @escaping () -> Void) {
        self.question = question
        self.allQuestions = allQuestions
        self.currentIndex = currentIndex
        _index = State(initialValue: currentIndex)
        self.isBookmarked = isBookmarked
        self.onBookmark = onBookmark
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.greekBlue)
                }
                Spacer()
                Text("\(index + 1) / \(allQuestions.count)")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: onBookmark) {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .foregroundColor(isBookmarked ? .greekGold : .secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 4)

            TabView(selection: $index) {
                ForEach(Array(allQuestions.enumerated()), id: \.element.id) { i, q in
                    FlashcardCard(
                        question: q,
                        onAnswer: { _ in },
                        onDontRemember: {},
                        selectedAnswer: nil as Int?,
                        revealedCorrect: false,
                        isAnswered: false
                    )
                    .padding(.horizontal, 8)
                    .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: index)
            .onChange(of: index) { _, newIndex in
                // Reset answer state when moving to a different question
                showAnswer = false
            }
        }
        .navigationBarHidden(true)
        .background(AppBackground())
    }
}

#Preview {
    StudyView()
        .environment(LanguageManager())
        .modelContainer(for: [TestResult.self, BookmarkedQuestion.self, DifficultQuestion.self], inMemory: true)
}
