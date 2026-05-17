import SwiftUI
import SwiftData

// MARK: - Main Study Tab

struct StudyView: View {
    @Environment(LanguageManager.self) private var lang
    @Query private var bookmarks: [BookmarkedQuestion]
    @Environment(\.modelContext) private var modelContext

    @State private var selectedCategory: QuestionCategory? = nil
    @State private var showBookmarksOnly = false
    @State private var searchText = ""

    var filtered: [Question] {
        var q = QuestionBank.all
        if let cat = selectedCategory { q = q.filter { $0.category == cat } }
        if showBookmarksOnly {
            let ids = Set(bookmarks.map(\.questionId))
            q = q.filter { ids.contains($0.id) }
        }
        if !searchText.isEmpty {
            q = q.filter { $0.text(greek: lang.language.isGreek)
                .localizedCaseInsensitiveContains(searchText) }
        }
        return q
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                VStack(spacing: 0) {
                    categoryPills
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)

                    if filtered.isEmpty {
                        emptyState
                    } else {
                        List {
                            ForEach(filtered) { q in
                                StudyQuestionRow(question: q, isBookmarked: isBookmarked(q.id)) {
                                    toggleBookmark(q.id)
                                }
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle(lang.t("Μελέτη", "Study"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showBookmarksOnly.toggle() } label: {
                        Image(systemName: showBookmarksOnly ? "bookmark.fill" : "bookmark")
                            .foregroundColor(showBookmarksOnly ? .greekGold : .primary)
                    }
                }
            }
            .searchable(text: $searchText, prompt: lang.t("Αναζήτηση...", "Search..."))
        }
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

// MARK: - Category Detail (navigated from HomeView)

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
                    StudyQuestionRow(question: q, isBookmarked: isBookmarked(q.id)) {
                        toggleBookmark(q.id)
                    }
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
        if let existing = bookmarks.first(where: { $0.questionId == id }) {
            modelContext.delete(existing)
        } else {
            modelContext.insert(BookmarkedQuestion(questionId: id))
        }
    }
}

// MARK: - Question Row Card

struct StudyQuestionRow: View {
    @Environment(LanguageManager.self) private var lang
    let question: Question
    let isBookmarked: Bool
    let onBookmark: () -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
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
                    // Visual
                    switch question.visual {
                    case .none: EmptyView()
                    default:
                        HStack {
                            Spacer()
                            QuestionVisualView(visual: question.visual, size: 100)
                            Spacer()
                        }
                        .padding(.top, 4)
                    }

                    // Options
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

                    // Explanation
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

                    // Bookmark
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
