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

        // Create a sub‑directory for app data if it doesn’t exist
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let storeURL = appSupport
            .appendingPathComponent("Greekdrivingtest")
            .appendingPathComponent("default.store")

        // Ensure the parent directory exists
        let directory = storeURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        do {
            let config = ModelConfiguration(url: storeURL)
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("SwiftData error: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(langManager)
        }
        .modelContainer(container)
    }
}
