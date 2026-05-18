import SwiftUI
import SwiftData
private enum TestPhase { case ready, inProgress, results }

// MARK: - TestView

struct TestView: View {
    @Binding var selectedTab: Int
    @Environment(LanguageManager.self) private var lang
    @Environment(\.modelContext) private var modelContext
    @Query private var difficultQuestions: [DifficultQuestion]

    @State private var phase: TestPhase = .ready
    @State private var questions: [Question] = []
    @State private var currentIndex = 0
    @State private var selectedAnswers: [Int: Int] = [:]
    @State private var timeRemaining = 45 * 60
    @State private var timerActive = false
    @State private var showingQuitAlert = false
    @State private var showConfetti = false

    var currentQuestion: Question? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }
    var selectedForCurrent: Int? { currentQuestion.flatMap { selectedAnswers[$0.id] } }
    var score: Int { questions.filter { selectedAnswers[$0.id] == $0.correctIndex }.count }
    var runningErrors: Int {
        questions.prefix(currentIndex + (selectedForCurrent != nil ? 1 : 0))
            .filter { let s = selectedAnswers[$0.id]; return s != nil && s != $0.correctIndex }
            .count
    }
    var totalErrors: Int { questions.count - score }
    var passed: Bool { score >= 27 }

    var body: some View {
        ZStack {
            switch phase {
            case .ready:      readyView
            case .inProgress: examView
            case .results:    resultsView
            }
        }
        .toolbar(phase == .ready ? .visible : .hidden, for: .tabBar)
        .task(id: timerActive) {
            guard timerActive else { return }
            while timeRemaining > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard timerActive else { return }
                timeRemaining -= 1
                if timeRemaining == 10 {
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                }
            }
            if timerActive { finishExam() }
        }
        .alert(lang.t("Διακοπή Εξέτασης;", "Quit Exam?"), isPresented: $showingQuitAlert) {
            Button(lang.t("Συνέχεια", "Continue"), role: .cancel) {}
            Button(lang.t("Έξοδος", "Quit"), role: .destructive) {
                timerActive = false
                withAnimation(.easeInOut(duration: 0.3)) { phase = .ready }
            }
        } message: {
            Text(lang.t("Η πρόοδός σου θα χαθεί.", "Your progress will be lost."))
        }
        .animation(.easeInOut(duration: 0.35), value: phase)
        .onChange(of: phase) { _, newPhase in
            if newPhase == .results && passed {
                showConfetti = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { showConfetti = false }
            }
        }
    }

    // MARK: - Ready Screen

    private var readyView: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(spacing: 24) {
                    // Hero
                    ZStack(alignment: .bottomLeading) {
                        LinearGradient(
                            colors: [.greekBlue, .greekDark],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                        Circle()
                            .fill(Color.white.opacity(0.07))
                            .frame(width: 220, height: 220)
                            .offset(x: 200, y: -20)
                        Circle()
                            .fill(Color.white.opacity(0.04))
                            .frame(width: 120, height: 120)
                            .offset(x: 260, y: 40)

                        VStack(alignment: .leading, spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.18))
                                    .frame(width: 68, height: 68)
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 32, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            Text(lang.t("Θεωρητική Εξέταση ΚΟΚ", "KOK Theory Exam"))
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text(lang.t(
                                "30 ερωτήσεις · 45 λεπτά · Μέγιστο 3 λάθη",
                                "30 questions · 45 minutes · Max 3 errors"
                            ))
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.72))
                        }
                        .padding(24)
                    }
                    .frame(minHeight: 190)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: .greekBlue.opacity(0.45), radius: 22, x: 0, y: 10)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                    // Rules card
                    VStack(spacing: 0) {
                        readyRuleRow(icon: "list.number", color: .catBlue,
                                     title: lang.t("Ερωτήσεις", "Questions"), value: "30", last: false)
                        readyRuleRow(icon: "clock.fill", color: .catOrange,
                                     title: lang.t("Χρόνος", "Time Limit"), value: lang.t("45 λεπτά", "45 min"), last: false)
                        readyRuleRow(icon: "xmark.circle.fill", color: .catRed,
                                     title: lang.t("Μέγιστα λάθη", "Max errors"), value: "3", last: false)
                        readyRuleRow(icon: "checkmark.circle.fill", color: .catGreen,
                                     title: lang.t("Βαθμός επιτυχίας", "Pass mark"), value: "27/30", last: true)
                    }
                    .cardStyle()
                    .padding(.horizontal, 16)

                    // Start
                    Button { startExam() } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 15, weight: .bold))
                            Text(lang.t("Έναρξη Εξέτασης", "Start Exam"))
                                .font(.title3.bold())
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(colors: [.greekBlue, .greekDark],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .greekBlue.opacity(0.4), radius: 16, x: 0, y: 8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 36)
                }
            }
        }
    }

    private func readyRuleRow(icon: String, color: Color, title: String, value: String, last: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(color.opacity(0.12))
                        .frame(width: 38, height: 38)
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(color)
                }
                Text(title).font(.subheadline)
                Spacer()
                Text(value).font(.subheadline.bold()).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            if !last { Divider().padding(.leading, 68) }
        }
    }

    // MARK: - Exam Screen

    private var examView: some View {
        VStack(spacing: 0) {
            examTopBar
                .background(.regularMaterial)
                .overlay(alignment: .bottom) { Divider() }

            if let q = currentQuestion {
                ScrollView {
                    VStack(spacing: 0) {
                        questionCard(q)
                        answersBlock(q)
                        if selectedForCurrent != nil {
                            explanationStrip(q)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }
                        Spacer(minLength: 110)
                    }
                }
                .id(q.id)

                if selectedForCurrent != nil {
                    nextBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .animation(.spring(response: 0.33, dampingFraction: 0.85), value: selectedForCurrent)
        .animation(.easeInOut(duration: 0.22), value: currentIndex)
    }

    private var examTopBar: some View {
        VStack(spacing: 8) {
            HStack {
                // Exit
                Button { showingQuitAlert = true } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 30, height: 30)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }

                Spacer()

                Text("\(currentIndex + 1) / \(questions.count)")
                    .font(.system(.subheadline, design: .rounded).weight(.bold))

                Spacer()

                // Timer
                HStack(spacing: 5) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(timeRemaining < 300 ? Color.catRed : Color.catOrange)
                    Text(timeString)
                        .font(.system(.subheadline, design: .monospaced).weight(.bold))
                        .foregroundStyle(timeRemaining < 300 ? Color.catRed : .primary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule().fill(timeRemaining < 300 ? Color.catRed.opacity(0.1) : Color(.systemGray6))
                )
            }
            .padding(.horizontal, 16)

            // Error dots + progress bar
            HStack {
                HStack(spacing: 7) {
                    ForEach(0..<3, id: \.self) { slot in
                        Circle()
                            .fill(slot < runningErrors ? Color.catRed : Color(.systemGray4))
                            .frame(width: 11, height: 11)
                            .scaleEffect(slot < runningErrors ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3), value: runningErrors)
                    }
                    Text(lang.t("λάθη", "errors"))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 2)
                }

                Spacer()

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(.systemGray5)).frame(height: 5)
                        Capsule().fill(Color.greekBlue)
                            .frame(
                                width: geo.size.width * CGFloat(currentIndex + 1) / CGFloat(max(questions.count, 1)),
                                height: 5
                            )
                            .animation(.spring(response: 0.4), value: currentIndex)
                    }
                }
                .frame(width: 130, height: 5)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
        .padding(.top, 8)
    }

    private func questionCard(_ q: Question) -> some View {
        VStack(spacing: 16) {
            HStack(alignment: .center) {
                Text((lang.language.isGreek ? "Ερώτηση " : "Q ") + "\(currentIndex + 1)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.6)
                Spacer()
                HStack(spacing: 8) {
                    Text(q.category.name(greek: lang.language.isGreek))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(categoryColor(q.category))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(categoryColor(q.category).opacity(0.1), in: Capsule())
                    Button { toggleDifficult(q.id) } label: {
                        Image(systemName: isDifficult(q.id) ? "flag.fill" : "flag")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(isDifficult(q.id) ? Color.catOrange : Color(.systemGray3))
                    }
                }
            }

            switch q.visual {
            case .none: EmptyView()
            default:
                HStack {
                    Spacer()
                    QuestionVisualView(visual: q.visual, size: 185, borderless: true)
                    Spacer()
                }
                .padding(.vertical, 4)
            }

            Text(q.text(greek: lang.language.isGreek))
                .font(.system(.body).weight(.medium))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(Color(.systemBackground))
    }

    private func answersBlock(_ q: Question) -> some View {
        let opts = q.options(greek: lang.language.isGreek)
        return VStack(spacing: 0) {
            Divider()
            VStack(spacing: 0) {
                ForEach(opts.indices, id: \.self) { i in
                    ExamAnswerRow(
                        index: i,
                        text: opts[i],
                        state: answerState(for: i, question: q),
                        isEnabled: selectedForCurrent == nil
                    ) { selectAnswer(i, for: q) }
                    if i < opts.count - 1 {
                        Divider().padding(.leading, 64)
                    }
                }
            }
            .background(Color(.systemBackground))
        }
    }

    @ViewBuilder
    private func explanationStrip(_ q: Question) -> some View {
        let expl = q.explanation(greek: lang.language.isGreek)
        let wasCorrect = selectedAnswers[q.id] == q.correctIndex
        if !expl.isEmpty {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lightbulb.fill").foregroundStyle(Color.catOrange).font(.subheadline)
                Text(expl).font(.subheadline)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.catOrange.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.catOrange.opacity(0.2), lineWidth: 1))
        } else if !wasCorrect {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.passGreen).font(.subheadline)
                Text(lang.t("Σωστή: ", "Correct: ") + q.options(greek: lang.language.isGreek)[q.correctIndex])
                    .font(.subheadline).foregroundStyle(Color.passGreen)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.passGreen.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var nextBar: some View {
        VStack(spacing: 0) {
            Divider()
            Button { advanceQuestion() } label: {
                HStack(spacing: 10) {
                    Text(currentIndex < questions.count - 1
                         ? lang.t("Επόμενη Ερώτηση", "Next Question")
                         : lang.t("Τέλος Εξέτασης", "Finish Exam"))
                        .font(.headline)
                    Image(systemName: currentIndex < questions.count - 1 ? "arrow.right" : "flag.checkered")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(colors: [.greekBlue, .greekDark], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial)
        }
    }

    // MARK: - Results Screen

    private var shareText: String {
        let emoji = passed ? "✅" : "❌"
        let result = passed ? lang.t("ΕΠΙΤΥΧΙΑ", "PASSED") : lang.t("ΑΠΟΤΥΧΙΑ", "FAILED")
        return "\(emoji) \(result) \(score)/30 \(lang.t("στη Θεωρητική Εξέταση ΚΟΚ! 🇬🇷", "on the Greek KOK Theory Exam! 🇬🇷"))"
    }

    private var resultsView: some View {
        ZStack {
            (passed ? Color.passGreen.opacity(0.03) : Color(.systemGroupedBackground))
                .ignoresSafeArea()

            if showConfetti { ConfettiView() }

            VStack(spacing: 0) {
                // Nav bar
                HStack {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) { phase = .ready }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 30, height: 30)
                            .background(Color(.systemGray5))
                            .clipShape(Circle())
                    }
                    Spacer()
                    Text(lang.t("Αποτελέσματα", "Results")).font(.headline)
                    Spacer()
                    Color.clear.frame(width: 30, height: 30)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(.regularMaterial)
                .overlay(alignment: .bottom) { Divider() }

                ScrollView {
                    VStack(spacing: 24) {
                        // Score ring
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .stroke(Color(.systemGray5), lineWidth: 18)
                                    .frame(width: 180, height: 180)
                                Circle()
                                    .trim(from: 0, to: CGFloat(score) / 30.0)
                                    .stroke(
                                        LinearGradient(
                                            colors: passed ? [.passGreen, .catGreen] : [.failRed, .catRed],
                                            startPoint: .topLeading, endPoint: .bottomTrailing
                                        ),
                                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                                    )
                                    .frame(width: 180, height: 180)
                                    .rotationEffect(.degrees(-90))
                                    .animation(.spring(response: 1.4, dampingFraction: 0.65), value: score)

                                VStack(spacing: 2) {
                                    Text("\(score)")
                                        .font(.system(size: 54, weight: .bold, design: .rounded))
                                        .foregroundStyle(passed ? Color.passGreen : Color.failRed)
                                    Text("/ 30")
                                        .font(.title3.bold())
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.top, 28)

                            HStack(spacing: 10) {
                                Image(systemName: passed ? "checkmark.seal.fill" : "xmark.seal.fill")
                                    .font(.title3.bold())
                                    .foregroundStyle(passed ? Color.passGreen : Color.failRed)
                                Text(passed ? lang.t("ΕΠΙΤΥΧΙΑ", "PASSED") : lang.t("ΑΠΟΤΥΧΙΑ", "FAILED"))
                                    .font(.title3.bold())
                                    .tracking(2)
                                    .foregroundStyle(passed ? Color.passGreen : Color.failRed)
                            }
                            .padding(.horizontal, 20).padding(.vertical, 10)
                            .background(Capsule().fill(passed ? Color.passGreen.opacity(0.1) : Color.failRed.opacity(0.1)))

                            Text(passed
                                 ? lang.t("Συγχαρητήρια! Πέρασες την εξέταση.", "Congratulations! You passed the exam.")
                                 : lang.t("Δεν πέρασες. Συνέχισε την εξάσκηση!", "You didn't pass. Keep practicing!"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }

                        // Stats
                        HStack(spacing: 12) {
                            ResultStatCard(value: "\(score)", label: lang.t("Σωστές", "Correct"),
                                           color: .passGreen, icon: "checkmark.circle.fill")
                            ResultStatCard(value: "\(totalErrors)", label: lang.t("Λάθη", "Errors"),
                                           color: totalErrors <= 3 ? .catOrange : .failRed, icon: "xmark.circle.fill")
                            ResultStatCard(value: timeUsedString, label: lang.t("Χρόνος", "Time"),
                                           color: .catBlue, icon: "clock.fill")
                        }
                        .padding(.horizontal, 16)

                        // Actions
                        VStack(spacing: 10) {
                            Button { restartExam() } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "arrow.clockwise")
                                    Text(lang.t("Νέα Εξέταση", "New Exam"))
                                }
                                .font(.headline).foregroundStyle(.white)
                                .frame(maxWidth: .infinity).padding(.vertical, 16)
                                .background(LinearGradient(colors: [.greekBlue, .greekDark],
                                                           startPoint: .leading, endPoint: .trailing))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .shadow(color: .greekBlue.opacity(0.3), radius: 10, x: 0, y: 5)
                            }

                            Button {
                                withAnimation(.easeInOut(duration: 0.3)) { phase = .ready }
                                selectedTab = 0
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "house.fill")
                                    Text(lang.t("Κεντρικό Μενού", "Main Menu"))
                                }
                                .font(.headline).foregroundStyle(Color.greekBlue)
                                .frame(maxWidth: .infinity).padding(.vertical, 16)
                                .background(Color.greekBlue.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }

                            ShareLink(item: shareText) {
                                HStack(spacing: 10) {
                                    Image(systemName: "square.and.arrow.up")
                                    Text(lang.t("Κοινοποίηση Αποτελεσμάτων", "Share Results"))
                                }
                                .font(.headline).foregroundStyle(Color.catPurple)
                                .frame(maxWidth: .infinity).padding(.vertical, 16)
                                .background(Color.catPurple.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                        .padding(.horizontal, 16)

                        // Wrong answers review
                        let wrong = questions.filter { selectedAnswers[$0.id] != $0.correctIndex }
                        if !wrong.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "xmark.circle.fill").foregroundStyle(Color.failRed)
                                    Text(lang.t("Λανθασμένες Απαντήσεις", "Wrong Answers")).font(.headline)
                                    Spacer()
                                    Text("\(wrong.count)")
                                        .font(.caption.bold()).foregroundStyle(.white)
                                        .padding(.horizontal, 8).padding(.vertical, 3)
                                        .background(Color.failRed, in: Capsule())
                                }
                                .padding(.horizontal, 16)

                                ForEach(wrong) { q in
                                    WrongAnswerCard(question: q, selectedIndex: selectedAnswers[q.id])
                                        .padding(.horizontal, 16)
                                }
                            }
                        }

                        Spacer(minLength: 40)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var timeString: String {
        String(format: "%02d:%02d", timeRemaining / 60, timeRemaining % 60)
    }
    private var timeUsedString: String {
        let used = (45 * 60) - timeRemaining
        let m = used / 60
        return m == 0 ? "<1m" : "\(m)m"
    }

    private func answerState(for i: Int, question: Question) -> ExamAnswerState {
        guard let selected = selectedAnswers[question.id] else { return .idle }
        if i == question.correctIndex { return .correct }
        if i == selected { return .wrong }
        return .dimmed
    }

    private func isDifficult(_ id: Int) -> Bool {
        difficultQuestions.contains { $0.questionId == id }
    }
    private func toggleDifficult(_ id: Int) {
        if let existing = difficultQuestions.first(where: { $0.questionId == id }) {
            modelContext.delete(existing)
        } else {
            modelContext.insert(DifficultQuestion(questionId: id))
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    // MARK: - Actions

    private func startExam() {
        questions = Array(QuestionBank.all.shuffled().prefix(30))
        currentIndex = 0
        selectedAnswers = [:]
        timeRemaining = 45 * 60
        timerActive = true
        withAnimation(.easeInOut(duration: 0.3)) { phase = .inProgress }
    }
    private func selectAnswer(_ i: Int, for q: Question) {
        guard selectedAnswers[q.id] == nil else { return }
        withAnimation(.spring(response: 0.3)) { selectedAnswers[q.id] = i }
        UIImpactFeedbackGenerator(style: i == q.correctIndex ? .light : .heavy).impactOccurred()
    }
    private func advanceQuestion() {
        if currentIndex < questions.count - 1 {
            withAnimation(.easeInOut(duration: 0.22)) { currentIndex += 1 }
        } else {
            finishExam()
        }
    }
    private func finishExam() {
        timerActive = false
        let timeElapsed = TimeInterval((45 * 60) - timeRemaining)
        let wrongIds = questions.filter { selectedAnswers[$0.id] != $0.correctIndex }.map(\.id)
        let result = TestResult(score: score, totalQuestions: questions.count,
                                passed: passed, timeElapsed: timeElapsed,
                                wrongQuestionIds: wrongIds)
        modelContext.insert(result)
        withAnimation(.easeInOut(duration: 0.3)) { phase = .results }
    }
    private func restartExam() {
        withAnimation(.easeInOut(duration: 0.3)) { phase = .ready }
    }
}

// MARK: - Exam Answer Row

enum ExamAnswerState { case idle, correct, wrong, dimmed }

struct ExamAnswerRow: View {
    let index: Int
    let text: String
    let state: ExamAnswerState
    let isEnabled: Bool
    let action: () -> Void

    private let letters = ["Α", "Β", "Γ", "Δ"]

    private var badgeBg: Color {
        switch state {
        case .correct: return .passGreen
        case .wrong:   return .failRed
        default:       return Color(.systemGray5)
        }
    }
    private var rowBg: Color {
        switch state {
        case .correct: return Color.passGreen.opacity(0.07)
        case .wrong:   return Color.failRed.opacity(0.07)
        default:       return .clear
        }
    }
    private var textColor: Color {
        switch state {
        case .correct: return .passGreen
        case .wrong:   return .failRed
        case .dimmed:  return Color(.systemGray2)
        default:       return .primary
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(badgeBg)
                        .frame(width: 38, height: 38)
                    Group {
                        switch state {
                        case .correct:
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        case .wrong:
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        default:
                            Text(letters[min(index, letters.count - 1)])
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                                .foregroundStyle(state == .dimmed ? Color(.systemGray3) : .secondary)
                        }
                    }
                }

                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(textColor)
                    .fontWeight(state == .correct ? .semibold : .regular)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity)
            .background(rowBg)
            .contentShape(Rectangle())
        }
        .disabled(!isEnabled)
        .animation(.spring(response: 0.3), value: state)
    }
}

// MARK: - Result Stat Card

struct ResultStatCard: View {
    let value: String
    let label: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            Text(value).font(.title3.bold()).foregroundStyle(color)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .cardStyle()
    }
}

// MARK: - Wrong Answer Card

struct WrongAnswerCard: View {
    @Environment(LanguageManager.self) private var lang
    let question: Question
    let selectedIndex: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch question.visual {
            case .none: EmptyView()
            default:    QuestionVisualView(visual: question.visual, size: 70)
                            .frame(maxWidth: .infinity, alignment: .center)
            }

            Text(question.text(greek: lang.language.isGreek))
                .font(.subheadline.bold())

            if let sel = selectedIndex {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Color.failRed)
                    Text(question.options(greek: lang.language.isGreek)[sel])
                        .font(.subheadline).foregroundStyle(Color.failRed)
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.passGreen)
                Text(question.options(greek: lang.language.isGreek)[question.correctIndex])
                    .font(.subheadline.bold()).foregroundStyle(Color.passGreen)
            }

            let expl = question.explanation(greek: lang.language.isGreek)
            if !expl.isEmpty {
                Text(expl).font(.caption).foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
        }
        .padding(14)
        .cardStyle()
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.failRed.opacity(0.18), lineWidth: 1))
    }
}
