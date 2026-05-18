//
//  GreekdrivingtestApp.swift
//  Greekdrivingtest
//
//  Created by John on 16/5/26.
//

import SwiftUI
import SwiftData

@main
struct GreekdrivingtestApp: App {
    @State private var langManager = LanguageManager()

    let container: ModelContainer = {
        let schema = Schema([TestResult.self, BookmarkedQuestion.self, DifficultQuestion.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do { return try ModelContainer(for: schema, configurations: [config]) }
        catch { fatalError("SwiftData error: \(error)") }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(langManager)
        }
        .modelContainer(container)
    }
}
