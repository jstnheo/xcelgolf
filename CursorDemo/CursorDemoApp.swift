//
//  CursorDemoApp.swift
//  CursorDemo
//
//  Created by Justin Heo on 6/2/25.
//

import SwiftUI
import SwiftData

@main
struct CursorDemoApp: App {
    @StateObject private var themeManager = ThemeManager()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Drill.self,
            PracticeSession.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .withThemeManager(themeManager)
                .themed()
        }
        .modelContainer(sharedModelContainer)
    }
}
