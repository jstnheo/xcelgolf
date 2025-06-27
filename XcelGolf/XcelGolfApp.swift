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
    @StateObject private var weatherManager = WeatherManager()
    @StateObject private var golfCourseManager = GolfCourseManager()
    
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
                .environmentObject(weatherManager)
                .environmentObject(golfCourseManager)
                .withThemeManager(themeManager)
                .themed()
                .toast(manager: toastManager)
                .onAppear {
                    // Request location permission at app launch
                    locationManager.requestLocationPermission()
                }
                .onChange(of: locationManager.location) { _, newLocation in
                    // Fetch weather and golf courses when location updates
                    if let location = newLocation {
                        print("📍 XcelGolfApp: Location updated, fetching weather and golf courses for: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                        weatherManager.fetchWeather(for: location)
                        print("🏌️ XcelGolfApp: Location updated, triggering golf course search")
                        golfCourseManager.searchNearbyGolfCourses(location: location)
                    } else {
                        print("📍 XcelGolfApp: Location is nil, not fetching data")
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
