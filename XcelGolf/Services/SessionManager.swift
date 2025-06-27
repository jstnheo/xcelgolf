import Foundation
import SwiftData
import CoreLocation

/// Manages temporary session state before saving to SwiftData
class SessionManager: ObservableObject {
    @Published var currentSession: TempSession?
    @Published var shouldCollapseFloatingButton: Bool = false
    
    private let sessionKey = "temp_session_data"
    
    init() {
        loadTempSession()
    }
    
    // MARK: - Floating Button Management
    
    /// Triggers the floating button to collapse due to user interaction (scroll/tap)
    func collapseFloatingButtonOnInteraction() {
        shouldCollapseFloatingButton = true
        // Reset after a brief moment to allow the UI to respond and allow future collapse requests
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self.shouldCollapseFloatingButton = false
        }
    }
    
    // MARK: - Session Management
    
    func startSession() {
        if currentSession == nil {
            currentSession = TempSession()
        }
    }
    
    /// Start a session and capture current weather, wind, and location data
    @MainActor
    func startSessionWithEnvironmentData(
        weatherManager: WeatherManager,
        locationManager: LocationManager,
        golfCourseManager: GolfCourseManager,
        selectedLocation: PracticeLocation?
    ) {
        startSession()
        captureEnvironmentData(
            weatherManager: weatherManager,
            locationManager: locationManager,
            golfCourseManager: golfCourseManager,
            selectedLocation: selectedLocation
        )
    }
    
    /// Capture current weather, wind, and location data for the session
    @MainActor
    func captureEnvironmentData(
        weatherManager: WeatherManager,
        locationManager: LocationManager,
        golfCourseManager: GolfCourseManager,
        selectedLocation: PracticeLocation?
    ) {
        guard var session = currentSession else { return }
        
        print("🌤️ SessionManager: Capturing environment data for session")
        
        // Capture weather data
        if let weather = weatherManager.currentWeather {
            session.temperature = weather.main.temp
            session.weatherCondition = weather.weather.first?.main
            session.weatherDescription = weather.weather.first?.description
            session.humidity = weather.main.humidity
            session.feelsLikeTemperature = weather.main.feelsLike
            
            // Capture wind data
            if let wind = weather.wind {
                session.windSpeed = wind.speed
                session.windDirection = wind.deg
                session.windDirectionText = windDirectionText(from: wind.deg)
            }
            
            print("🌤️ SessionManager: Captured weather data - \(weather.main.temp)°F, \(weather.weather.first?.main ?? "N/A")")
        }
        
        // Capture location data
        if let location = locationManager.location {
            session.latitude = location.coordinate.latitude
            session.longitude = location.coordinate.longitude
            session.locationName = locationManager.locationName.isEmpty ? nil : locationManager.locationName
            
            print("📍 SessionManager: Captured location data - \(location.coordinate.latitude), \(location.coordinate.longitude)")
        }
        
        // Capture practice location data (golf course or custom location)
        if let practiceLocation = selectedLocation {
            session.golfCourseName = practiceLocation.name
            session.golfCourseType = practiceLocation.type
            
            // Calculate distance if we have both user location and practice location coordinates
            if let userLocation = locationManager.location,
               let practiceLocationCoordinate = practiceLocation.location {
                let distance = userLocation.distance(from: practiceLocationCoordinate) / 1609.34 // Convert to miles
                session.distanceToGolfCourse = distance
            }
            
            print("📍 SessionManager: Captured practice location data - \(practiceLocation.name) (\(practiceLocation.type))")
        } else if let course = golfCourseManager.nearestCourse {
            // Fallback to nearest course if no specific location selected
            session.golfCourseName = course.name
            session.golfCourseType = determineCourseType(course: course)
            
            // Calculate distance if we have both user location and course location
            if let userLocation = locationManager.location,
               let courseLocation = course.location {
                let distance = userLocation.distance(from: courseLocation) / 1609.34 // Convert to miles
                session.distanceToGolfCourse = distance
            }
            
            print("⛳ SessionManager: Captured nearest golf course data - \(course.name)")
        }
        
        // Update the session
        currentSession = session
        saveTempSession()
    }
    
    func addDrillResult(_ drill: DrillTemplate, score: Int? = nil, isCompleted: Bool = false) {
        if currentSession == nil {
            startSession()
        }
        
        let result = TempDrillResult(
            drillTemplate: drill,
            score: score,
            isCompleted: isCompleted,
            completedAt: Date()
        )
        
        currentSession?.drillResults.append(result)
        saveTempSession()
    }
    
    func batchAddDrillResults(_ results: [TempDrillResult]) {
        if currentSession == nil {
            startSession()
        }
        
        currentSession?.drillResults.append(contentsOf: results)
        saveTempSession()
    }
    
    func getDrillResults(for category: DrillCategory) -> [TempDrillResult] {
        return currentSession?.drillResults.filter { $0.drillTemplate.category == category } ?? []
    }
    
    func getCompletedDrillsCount(for category: DrillCategory) -> Int {
        return getDrillResults(for: category).count
    }
    
    func saveSessionToSwiftData(modelContext: ModelContext, toastManager: ToastManager? = nil) {
        guard let tempSession = currentSession else { 
            print("DEBUG: No current session to save")
            toastManager?.showWarning("No Session", message: "No active session to save")
            return 
        }
        
        print("DEBUG: Starting saveSessionToSwiftData")
        print("DEBUG: Temp session has \(tempSession.drillResults.count) drill results")
        
        // Create a new PracticeSession
        let practiceSession = PracticeSession(date: tempSession.startDate)
        
        // Transfer weather data
        practiceSession.temperature = tempSession.temperature
        practiceSession.weatherCondition = tempSession.weatherCondition
        practiceSession.weatherDescription = tempSession.weatherDescription
        practiceSession.humidity = tempSession.humidity
        practiceSession.feelsLikeTemperature = tempSession.feelsLikeTemperature
        
        // Transfer wind data
        practiceSession.windSpeed = tempSession.windSpeed
        practiceSession.windDirection = tempSession.windDirection
        practiceSession.windDirectionText = tempSession.windDirectionText
        
        // Transfer location data
        practiceSession.locationName = tempSession.locationName
        practiceSession.latitude = tempSession.latitude
        practiceSession.longitude = tempSession.longitude
        practiceSession.golfCourseName = tempSession.golfCourseName
        practiceSession.golfCourseType = tempSession.golfCourseType
        practiceSession.distanceToGolfCourse = tempSession.distanceToGolfCourse
        
        print("DEBUG: Created practice session with environment data")
        
        // Insert the practice session into the context first
        modelContext.insert(practiceSession)
        print("DEBUG: Inserted practice session into context")
        
        // Convert temp drill results to actual Drill objects
        for (index, tempResult) in tempSession.drillResults.enumerated() {
            print("DEBUG: Processing drill \(index + 1): \(tempResult.drillTemplate.name)")
            
            let drill = Drill(
                name: tempResult.drillTemplate.name,
                drillDescription: tempResult.drillTemplate.description,
                category: tempResult.drillTemplate.category,
                scoringType: tempResult.drillTemplate.scoringType,
                maxScore: tempResult.drillTemplate.defaultMaxScore,
                actualScore: tempResult.score ?? 0,
                isCompleted: tempResult.isCompleted,
                completedAt: tempResult.completedAt
            )
            
            print("DEBUG: Created drill object")
            
            // Insert the drill into the context
            modelContext.insert(drill)
            print("DEBUG: Inserted drill into context")
            
            // Now establish the relationship (both objects are in the context)
            practiceSession.drills.append(drill)
            print("DEBUG: Added drill to practice session")
        }
        
        print("DEBUG: About to save context")
        
        // Save the context
        do {
            try modelContext.save()
            print("DEBUG: Successfully saved context")
            
            // Show success toast with environment data info
            let drillCount = tempSession.drillResults.count
            var message = drillCount == 1 ? "1 drill saved" : "\(drillCount) drills saved"
            
            // Add environment data info to toast
            var envInfo: [String] = []
            if practiceSession.hasWeatherData { envInfo.append("weather") }
            if practiceSession.hasLocationData { envInfo.append("location") }
            if practiceSession.hasGolfCourseData { envInfo.append("course") }
            
            if !envInfo.isEmpty {
                message += " with \(envInfo.joined(separator: ", ")) data"
            }
            
            toastManager?.showSuccess("Session Saved", message: message)
            
            // Clear temp session after successful save (silently)
            clearSession(toastManager: toastManager, showToast: false)
            print("DEBUG: Cleared temp session")
        } catch {
            print("DEBUG: Failed to save session: \(error)")
            toastManager?.showError("Save Failed", message: "Unable to save session")
        }
    }
    
    func clearSession(toastManager: ToastManager? = nil, showToast: Bool = true) {
        let hadSession = currentSession != nil
        currentSession = nil
        UserDefaults.standard.removeObject(forKey: sessionKey)
        
        if hadSession && showToast {
            toastManager?.showInfo("Session Cleared", message: "Unsaved changes discarded")
        }
    }
    
    func forceSave() {
        saveTempSession()
    }
    
    // MARK: - Helper Methods
    
    /// Convert wind degree to direction text
    private func windDirectionText(from degrees: Int?) -> String? {
        guard let degrees = degrees else { return nil }
        
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                         "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int((Double(degrees) / 22.5).rounded()) % 16
        return directions[index]
    }
    
    /// Determine course type from Course object
    private func determineCourseType(course: Course) -> String {
        let name = course.name.lowercased()
        if name.contains("driving range") || name.contains("range") {
            return "Driving Range"
        } else if name.contains("mini golf") || name.contains("miniature") {
            return "Mini Golf"
        } else if name.contains("practice") {
            return "Practice Facility"
        } else {
            return "Golf Course"
        }
    }
    
    // MARK: - Persistence
    
    private func saveTempSession() {
        guard let session = currentSession else { return }
        if let data = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(data, forKey: sessionKey)
        }
    }
    
    private func loadTempSession() {
        guard let data = UserDefaults.standard.data(forKey: sessionKey),
              let session = try? JSONDecoder().decode(TempSession.self, from: data) else {
            return
        }
        currentSession = session
    }
} 