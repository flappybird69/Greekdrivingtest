//
//  GreekdrivingtestApp.swift
//  Greekdrivingtest
//
//  Created by John on 16/5/26.
//

import SwiftUI
import SwiftData
import StoreKit
import UserNotifications

@main
struct GreekdrivingtestApp: App {
    @State private var langManager = LanguageManager()
    @State private var storeKit = StoreKitManager()
    @State private var showSplash = true
    @AppStorage("useDarkMode") private var useDarkMode = true

    init() {}

    let container: ModelContainer = {
        let schema = Schema([TestResult.self, BookmarkedQuestion.self, DifficultQuestion.self])

        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            return try! ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        }

        let storeURL = appSupport
            .appendingPathComponent("Greekdrivingtest")
            .appendingPathComponent("default.store")

        let directory = storeURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        do {
            let config = ModelConfiguration(url: storeURL, cloudKitDatabase: .automatic)
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            return try! ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        }
    }()

    var body: some Scene {
        WindowGroup {
            if showSplash {
                SplashScreenView {
                    withAnimation(.easeOut(duration: 0.4)) {
                        showSplash = false
                    }
                }
                .transition(.opacity)
                .preferredColorScheme(useDarkMode ? .dark : .light)
            } else {
                ContentView()
                    .environment(langManager)
                    .environment(storeKit)
                    .onAppear { requestPushPermission() }
                    .transition(.opacity)
                    .preferredColorScheme(useDarkMode ? .dark : .light)
            }
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
