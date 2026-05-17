//
//  ContentView.swift
//  Greekdrivingtest
//
//  Created by John on 16/5/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(LanguageManager.self) private var lang
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem { Label(lang.t("Αρχική", "Home"), systemImage: "house.fill") }
                .tag(0)
            StudyView()
                .tabItem { Label(lang.t("Μελέτη", "Study"), systemImage: "book.fill") }
                .tag(1)
            TestView(selectedTab: $selectedTab)
                .tabItem { Label(lang.t("Εξέταση", "Exam"), systemImage: "checkmark.circle.fill") }
                .tag(2)
            StatsView()
                .tabItem { Label(lang.t("Στατιστικά", "Stats"), systemImage: "chart.bar.fill") }
                .tag(3)
            SettingsView()
                .tabItem { Label(lang.t("Ρυθμίσεις", "Settings"), systemImage: "gearshape.fill") }
                .tag(4)
        }
        .tint(.greekBlue)
    }
}
