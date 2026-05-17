import SwiftUI
import SwiftData
import Combine

// MARK: - Test Phase
private enum TestPhase { case ready, inProgress, results }

// MARK: - TestView

struct TestView: View {
    @Binding var selectedTab: Int
    @Environment(LanguageManager.self) private var lang
    @Environment(\.modelContext) private var modelContext

    @State private var phase: TestPhase = .ready
    @State private var questions: [Question] = []
    @State private var currentIndex = 0
    @State private var selectedAnswers: [Int: Int] = [:]
    @State private var timeRemaining = 45 * 60
    @State private var timerActive = false
    @State private var showingQuitAlert = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var currentQuestion: Question? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }
    var selectedForCurrent: Int? { currentQuestion.flatMap { selectedAnswers[$0.id] } }
    var score: Int { questions.filter { selectedAnswers[$0.id] == $0.correctIndex }.count }
    var errors: Int { questions.count - score }
    var passed: Bool { questions.count == 30 ? score >= 27 : score >= Int(Double(questions.count) * 0.9) }

    var body: some View {
        ZStack {
            switch phase {
            case .ready:      readyView
            case .inProgress: examView
            case .results:    resultsView
            }
        }
        .toolbar(phase == .ready ? .visible : .hidden, for: .tabBar)
        .onReceive(timer) { _ in
            guard timerActive, timeRemaining > 0 else {
                if timerActive && timeRemaining == 0 { finishExam() }
                return
            }
            timeRemaining -= 1
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
    }

    // MARK: - Ready Screen

    private var readyView: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.greekBlue.opacity(0.1))
                                .frame(width: 120, height: 120)
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 52, weight: .semibold))
                                .foregroundStyle(Color.greekBlue)
                        }
                        .padding(.top, 44)

                        Text(lang.t("Θεωρητική Εξέταση", "Theory Exam"))
                            .font(.system(size: 28, weight: .bold, design: .rounded))

                        Text(lang.t("Προσομοίωση εξέτασης ΚΟΚ", "Greek KOK exam simulation"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)

                    VStack(spacing: 0) {
                        examInfoRow(icon: "list.number", color: .catBlue,
                                    title: lang.t("Ερωτήσεις", "Questions"), value: "30")
                        Divider().padding(.horizontal, 16)
                        examInfoRow(icon: "clock.fill", color: .catOrange,
                                    title: lang.t("Χρόνος", "Time Limit"), value: lang.t("45 λεπτά", "45 min"))
                        Divider().padding(.horizontal, 16)
                        examInfoRow(icon: "xmark.circle.fill", color: .catRed,
                                    title: lang.t("Μέγιστα λάθη", "Max errors"), value: "3")
                        Divider().padding(.horizontal, 16)
                        examInfoRow(icon: "star.fill", color: .catGreen,
                                    title: lang.t("Βάση επιτυχίας", "Pass mark"), value: "27/30")
                    }
                    .cardStyle()
                    .padding(.horizontal, 20)

                    Button { startExam() } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "play.fill")
                            Text(lang.t("Έναρξη Εξέτασης", "Start Exam"))
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.greekBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .greekBlue.opacity(0.35), radius: 12, x: 0, y: 6)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    private func examInfoRow(icon: String, color: Color, title: String, value: String) -> some View {
        HStack {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 20)
                Text(title).foregroundStyle(.primary)
            }
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
    }

    // MARK: - Exam Screen

    private var examView: some View {
        ZStack(alignment: .top) {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                examNavBar
                    .background(.regularMaterial)

                // Thin progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(Color(.systemGray5)).frame(height: 3)
                        Rectangle().fill(Color.greekBlue)
                            .frame(
                                width: geo.size.width * CGFloat(currentIndex + 1) / CGFloat(max(questions.count, 1)),
                                height: 3
                            )
                            .animation(.spring(response: 0.4), value: currentIndex)
                    }
                }
                .frame(height: 3)

                if let q = currentQuestion {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Question card: header + image + text
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text((lang.language.isGreek ? "Ερώτηση " : "Question ") + "\(currentIndex + 1)")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                        .textCase(.uppercase)
                                        .tracking(0.5)
                                    Spacer()
                                    Text(q.category.name(greek: lang.language.isGreek))
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(categoryColor(q.category))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(categoryColor(q.category).opacity(0.12), in: Capsule())
                                }

                                // Visual — large and centered like the real exam
                                switch q.visual {
                                case .none:
                                    EmptyView()
                                default:
                                    HStack {
                                        Spacer()
                                        QuestionVisualView(visual: q.visual, size: 160)
                                        Spacer()
                                    }
                                }

                                Text(q.text(greek: lang.language.isGreek))
                                    .font(.system(.body).weight(.medium))
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                            }
                            .padding(20)
                            .background(Color(.systemBackground))

                            Divider()

                            // Answer options — iOS list style
                            VStack(spacing: 0) {
                                ForEach(q.options(greek: lang.language.isGreek).indices, id: \.self) { i in
                                    AnswerButton(
                                        label: ["Α", "Β", "Γ", "Δ"][i],
                                        text: q.options(greek: lang.language.isGreek)[i],
                                        state: answerState(for: i, question: q),
                                        isEnabled: selectedForCurrent == nil
                                    ) { selectAnswer(i, for: q) }

                                    if i < q.options(greek: lang.language.isGreek).count - 1 {
                                        Divider().padding(.leading, 62)
                                    }
                                }
                            }
                            .background(Color(.systemBackground))

                            // Explanation strip
                            if selectedForCurrent != nil {
                                explanationCard(for: q)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            }

                            Spacer(minLength: 100)
                        }
                        .padding(.top, 12)
                        .padding(.horizontal, 16)
                    }

                    // Sticky next button
                    if selectedForCurrent != nil {
                        VStack(spacing: 0) {
                            Divider()
                            Button { advanceQuestion() } label: {
                                HStack(spacing: 8) {
                                    Text(currentIndex < questions.count - 1
                                         ? lang.t("Επόμενη Ερώτηση", "Next Question")
                                         : lang.t("Τέλος Εξέτασης", "Finish Exam"))
                                    Image(systemName: currentIndex < questions.count - 1
                                          ? "arrow.right" : "flag.checkered")
                                }
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.greekBlue)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(.regularMaterial)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
        }
        .animation(.spring(response: 0.3), value: selectedForCurrent)
    }

    private var examNavBar: some View {
        HStack {
            Button { showingQuitAlert = true } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text(lang.t("Μενού", "Menu"))
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(Color.greekBlue)
            }

            Spacer()

            Text("\(currentIndex + 1) / \(questions.count)")
                .font(.system(.subheadline, design: .rounded).weight(.bold))

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(timeRemaining < 300 ? Color.catRed : Color.catOrange)
                Text(timeString)
                    .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                    .foregroundStyle(timeRemaining < 300 ? Color.catRed : .primary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(timeRemaining < 300 ? Color.catRed.opacity(0.12) : Color(.systemGray6))
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var timeString: String {
        String(format: "%02d:%02d", timeRemaining / 60, timeRemaining % 60)
    }

    private func answerState(for i: Int, question: Question) -> AnswerButtonState {
        guard let selected = selectedAnswers[question.id] else { return .idle }
        if i == question.correctIndex { return .correct }
        if i == selected { return .wrong }
        return .missed
    }

    private func explanationCard(for q: Question) -> some View {
        let expl = q.explanation(greek: lang.language.isGreek)
        return Group {
            if !expl.isEmpty {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(Color.catOrange)
                        .font(.subheadline)
                    Text(expl).font(.subheadline)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.catOrange.opacity(0.08))
                .overlay(
                    Rectangle().fill(Color.catOrange).frame(width: 3),
                    alignment: .leading
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.top, 2)
            }
        }
    }

    // MARK: - Results Screen

    private var resultsView: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                // Nav bar
                HStack {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) { phase = .ready }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text(lang.t("Εξέταση", "Exam"))
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundStyle(Color.greekBlue)
                    }
                    Spacer()
                    Text(lang.t("Αποτελέσματα", "Results")).font(.headline)
                    Spacer()
                    Color.clear.frame(width: 70)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(.regularMaterial)

                Divider()

                ScrollView {
                    VStack(spacing: 20) {
                        // Score ring
                        VStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .stroke(Color(.systemGray5), lineWidth: 16)
                                    .frame(width: 160, height: 160)
                                Circle()
                                    .trim(from: 0, to: CGFloat(score) / CGFloat(max(questions.count, 1)))
                                    .stroke(
                                        passed ? Color.passGreen : Color.failRed,
                                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                                    )
                                    .frame(width: 160, height: 160)
                                    .rotationEffect(.degrees(-90))
                                    .animation(.spring(response: 1.2, dampingFraction: 0.7), value: score)
                                VStack(spacing: 2) {
                                    Text("\(score)/\(questions.count)")
                                        .font(.system(size: 36, weight: .bold, design: .rounded))
                                    Text(passed ? lang.t("ΕΠΙΤΥΧΙΑ", "PASSED") : lang.t("ΑΠΟΤΥΧΙΑ", "FAILED"))
                                        .font(.caption.bold()).tracking(1.5)
                                        .foregroundStyle(passed ? Color.passGreen : Color.failRed)
                                }
                            }

                            Label(
                                passed
                                    ? lang.t("Συγχαρητήρια! Πέρασες!", "Congratulations! You passed!")
                                    : lang.t("Δεν πέρασες. Ξαναπροσπάθησε!", "You didn't pass. Try again!"),
                                systemImage: passed ? "checkmark.seal.fill" : "xmark.seal.fill"
                            )
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(passed ? Color.passGreen : Color.failRed)
                            .padding(.horizontal, 16).padding(.vertical, 8)
                            .background(
                                Capsule().fill(passed
                                    ? Color.passGreen.opacity(0.1)
                                    : Color.failRed.opacity(0.1))
                            )
                        }
                        .padding(.top, 28)

                        // Stats
                        HStack(spacing: 12) {
                            ResultStat(value: "\(score)", label: lang.t("Σωστές", "Correct"), color: .passGreen)
                            ResultStat(value: "\(errors)", label: lang.t("Λάθη", "Errors"),
                                       color: errors <= 3 ? .catOrange : .failRed)
                            ResultStat(value: timeUsedString, label: lang.t("Χρόνος", "Time"), color: .catBlue)
                        }
                        .padding(.horizontal, 16)

                        // Action buttons
                        VStack(spacing: 10) {
                            Button { restartExam() } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.clockwise")
                                    Text(lang.t("Νέα Εξέταση", "New Exam"))
                                }
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.greekBlue)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }

                            Button {
                                withAnimation(.easeInOut(duration: 0.3)) { phase = .ready }
                                selectedTab = 0
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "house.fill")
                                    Text(lang.t("Κεντρικό Μενού", "Main Menu"))
                                }
                                .font(.headline)
                                .foregroundStyle(Color.greekBlue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.greekBlue.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                        .padding(.horizontal, 16)

                        // Wrong answers review
                        let wrong = questions.filter { selectedAnswers[$0.id] != $0.correctIndex }
                        if !wrong.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(lang.t("Λανθασμένες Απαντήσεις", "Wrong Answers"))
                                        .font(.title3.bold())
                                    Spacer()
                                    Text("\(wrong.count)")
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 8).padding(.vertical, 4)
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

    private var timeUsedString: String {
        let used = (45 * 60) - timeRemaining
        let m = used / 60
        return m == 0 ? "<1m" : "\(m)m"
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
            withAnimation(.easeInOut(duration: 0.25)) { currentIndex += 1 }
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

// MARK: - Answer Button

struct AnswerButton: View {
    let label: String
    let text: String
    let state: AnswerButtonState
    let isEnabled: Bool
    let action: () -> Void

    enum AnswerButtonState { case idle, correct, wrong, missed }

    private var rowBg: Color {
        switch state {
        case .correct: return Color.passGreen.opacity(0.08)
        case .wrong:   return Color.failRed.opacity(0.08)
        default:       return .clear
        }
    }
    private var circleBg: Color {
        switch state {
        case .correct: return .passGreen
        case .wrong:   return .failRed
        default:       return Color(.systemGray5)
        }
    }
    private var textColor: Color {
        switch state {
        case .correct: return .passGreen
        case .wrong:   return .failRed
        default:       return .primary
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(circleBg).frame(width: 34, height: 34)
                    Group {
                        switch state {
                        case .correct:
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                        case .wrong:
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                        default:
                            Text(label)
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(textColor)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if state == .missed {
                    Circle()
                        .stroke(Color(.systemGray4), lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(rowBg)
        }
        .disabled(!isEnabled)
        .animation(.spring(response: 0.3), value: state)
    }
}

// MARK: - Result Stat

struct ResultStat: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.title2.bold()).foregroundStyle(color)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .cardStyle()
    }
}

// MARK: - Wrong Answer Card

struct WrongAnswerCard: View {
    @Environment(LanguageManager.self) private var lang
    let question: Question
    let selectedIndex: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            switch question.visual {
            case .none: EmptyView()
            default:    QuestionVisualView(visual: question.visual, size: 70)
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
                    .font(.subheadline).foregroundStyle(Color.passGreen)
            }

            let expl = question.explanation(greek: lang.language.isGreek)
            if !expl.isEmpty {
                Text(expl).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .cardStyle()
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.failRed.opacity(0.2), lineWidth: 1))
    }
}

typealias AnswerButtonState = AnswerButton.AnswerButtonState
