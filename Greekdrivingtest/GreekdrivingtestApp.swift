//
//  GreekdrivingtestApp.swift
//  Greekdrivingtest
//
//  Created by John on 16/5/26.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct GreekdrivingtestApp: App {
    @State private var langManager = LanguageManager()

    init() {}

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
            let config = ModelConfiguration(url: storeURL, cloudKitDatabase: .automatic)
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("SwiftData error: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(langManager)
                .onAppear { requestPushPermission() }
        }
        .modelContainer(container)
    }

    private func requestPushPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
}
