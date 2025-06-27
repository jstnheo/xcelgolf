//
//  XcelGolfApp.swift
//  XcelGolf
//
//  Created by Justin Heo on 6/2/25.
//

import SwiftUI
import SwiftData

@main
struct XcelGolfApp: App {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var toastManager = ToastManager()
    @StateObject private var locationManager = LocationManager()
    
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
                .environmentObject(toastManager)
                .environmentObject(locationManager)
                .withThemeManager(themeManager)
                .themed()
                .toast(manager: toastManager)
                .onAppear {
                    // Request location permission at app launch
                    locationManager.requestLocationPermission()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
