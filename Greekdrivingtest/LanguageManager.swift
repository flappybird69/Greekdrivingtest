import SwiftUI

enum AppLanguage: String, CaseIterable {
    case greek = "el"
    case english = "en"

    var displayName: String {
        switch self {
        case .greek: return "Ελληνικά"
        case .english: return "English"
        }
    }

    var flag: String {
        switch self {
        case .greek: return "🇬🇷"
        case .english: return "🇬🇧"
        }
    }

    var isGreek: Bool { self == .greek }
}

@Observable
final class LanguageManager {
    var language: AppLanguage

    init() {
        let stored = UserDefaults.standard.string(forKey: "selectedLanguage") ?? AppLanguage.greek.rawValue
        self.language = AppLanguage(rawValue: stored) ?? .greek
    }

    func setLanguage(_ lang: AppLanguage) {
        language = lang
        UserDefaults.standard.set(lang.rawValue, forKey: "selectedLanguage")
    }

    // Primary translation helper
    func t(_ gr: String, _ en: String) -> String {
        language.isGreek ? gr : en
    }
}
