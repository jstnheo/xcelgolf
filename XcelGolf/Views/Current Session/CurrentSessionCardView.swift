import SwiftUI
import SwiftData

struct CurrentSessionCardView: View {
    let session: PracticeSession?
    @Environment(\.theme) private var theme
    @State private var showingAddDrill = false
    @State private var showingLocationSelection = false
    @State private var selectedLocation: PracticeLocation?
    @EnvironmentObject private var sessionManager: SessionManager
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var weatherManager: WeatherManager
    @EnvironmentObject private var golfCourseManager: GolfCourseManager
    
    private var hasTempSession: Bool {
        sessionManager.currentSession != nil && !sessionManager.currentSession!.drillResults.isEmpty
    }
    
    // Computed property for location display
    private var locationDisplayText: String {
        // If user has selected a specific location, show that
        if let selectedLocation = selectedLocation {
            return selectedLocation.displayName
        }
        
        // Otherwise, show the nearest course or fallback to city name
        if golfCourseManager.isLoading {
            return "Finding locations..."
        } else if let course = golfCourseManager.nearestCourse {
            return course.displayName
        } else if !locationManager.locationName.isEmpty && locationManager.locationName != "Unknown Location" {
            return locationManager.locationName
        } else {
            return "Unknown Location"
        }
    }
    
    // Computed property for location icon
    private var locationIcon: String {
        // If user has selected a custom location, use its icon
        if let selectedLocation = selectedLocation {
            return selectedLocation.icon
        }
        
        // Otherwise, use the nearest course icon or fallback
        let courseToUse = golfCourseManager.nearestCourse
        
        if golfCourseManager.isLoading {
            return "location.circle"
        } else if let course = courseToUse {
            let name = course.name.lowercased()
            if name.contains("driving range") || name.contains("range") {
                return "target"
            } else if name.contains("mini golf") || name.contains("miniature") {
                return "figure.golf"
            } else if name.contains("practice") {
                return "sportscourt"
            } else {
                return "flag.fill"
            }
        } else {
            return "location.fill"
        }
    }
    
    // Computed property for distance display
    private var distanceText: String {
        // Check if we have a selected location with coordinates
        if let selectedLocation = selectedLocation {
            switch selectedLocation {
            case .custom:
                return ""  // No distance for custom locations
            case .golfFacility(let course):
                guard let locationCoordinate = course.location,
                      let userLocation = locationManager.location else {
                    return ""
                }
                let distance = userLocation.distance(from: locationCoordinate) / 1609.34 // Convert to miles
                return distance < 1.0 ? String(format: "%.1f mi", distance) : String(format: "%.0f mi", distance)
            }
        }
        
        // Fallback to nearest course distance
        let courseToUse = golfCourseManager.nearestCourse
        
        guard let course = courseToUse,
              let courseLocation = course.location,
              let userLocation = locationManager.location else {
            return ""
        }
        
        let distance = userLocation.distance(from: courseLocation) / 1609.34 // Convert to miles
        
        if distance < 1.0 {
            return String(format: "%.1f mi", distance)
        } else {
            return String(format: "%.0f mi", distance)
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Date, time, and location
            GeometryReader { geometry in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Date(), format: .dateTime.weekday(.wide).month(.wide).day())
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.textPrimary)
                        Text(Date(), format: .dateTime.hour().minute())
                            .font(.subheadline)
                            .foregroundColor(theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Location (Golf Course or City)
                    VStack(alignment: .trailing, spacing: 2) {
                        Button(action: {
                            showingLocationSelection = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: locationIcon)
                                    .foregroundColor(theme.primary)
                                    .font(.caption)
                                    .symbolEffect(.pulse, isActive: golfCourseManager.isLoading || locationManager.isLoading)
                                Text(locationDisplayText)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(theme.textPrimary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Distance to golf course (if available)
                        if !distanceText.isEmpty {
                            Text(distanceText)
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                    .frame(maxWidth: geometry.size.width * 0.5, alignment: .trailing)
                }
            }
            .frame(height: 60) // Fixed height for the date/location section
            
            // Weather information
            HStack(spacing: 16) {
                // Weather icon and temp
                HStack(spacing: 6) {
                    if weatherManager.isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: weatherManager.weatherIconName)
                            .foregroundColor(weatherManager.weatherIconColor)
                            .font(.title3)
                            .symbolEffect(.pulse, isActive: weatherManager.currentWeather == nil && !weatherManager.isLoading)
                    }
                    Text(weatherManager.temperatureString)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(weatherManager.currentWeather == nil && !weatherManager.isLoading ? theme.textSecondary : theme.textPrimary)
                }
                
                // Wind information
                HStack(spacing: 6) {
                    Image(systemName: "wind")
                        .foregroundColor(weatherManager.currentWeather == nil && !weatherManager.isLoading ? theme.textSecondary : theme.primary)
                        .font(.subheadline)
                    Text(weatherManager.windString)
                        .font(.subheadline)
                        .foregroundColor(weatherManager.currentWeather == nil && !weatherManager.isLoading ? theme.textSecondary : theme.textSecondary)
                }
                
                Spacer()
                
                // Session status
                HStack(spacing: 4) {
                    Circle()
                        .fill(sessionStatusColor)
                        .frame(width: 8, height: 8)
                    Text(sessionStatusText)
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
            }
            
            // Temp session info if available
            if hasTempSession {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Practice in Progress")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(theme.warning)
                        Text("\(sessionManager.currentSession!.drillResults.count) drills logged")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    Text("Unsaved")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(theme.warning)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(theme.warning.opacity(0.1))
                        .cornerRadius(10)
                }
                .padding()
                .background(theme.warning.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.divider, lineWidth: 1)
        )
        .shadow(color: theme.primary.opacity(0.1), radius: 2)
        .onTapGesture {
            logLocationAndWeatherDebugInfo()
        }
        .sheet(isPresented: $showingAddDrill) {
            if let session = session {
                NewExerciseView(session: session)
            } else {
                NewSessionView()
            }
        }
        .sheet(isPresented: $showingLocationSelection) {
            PracticeLocationView { location in
                selectedLocation = location
                print("📍 User selected practice location: \(location.name)")
            }
        }
        .onAppear {
            // The LocationManager authorization callback will handle starting location updates
            // No need to call startLocationUpdates directly here to avoid threading issues
            print("📍 CurrentSessionCardView: Card appeared, location status: \(locationManager.authorizationStatus)")
        }
    }
    
    // MARK: - Debug Methods
    
    /// Logs detailed location, weather, and golf course information for debugging
    private func logLocationAndWeatherDebugInfo() {
        let timestamp = Date().formatted(date: .abbreviated, time: .standard)
        
        print("🏌️ === CurrentSessionCard Debug Info [\(timestamp)] ===")
        
        // Location Information
        print("📍 LOCATION:")
        print("   • Authorization Status: \(locationManager.authorizationStatus)")
        print("   • Is Loading: \(locationManager.isLoading)")
        print("   • Location Name: \(locationManager.locationName)")
        if let location = locationManager.location {
            print("   • Coordinates: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            print("   • Accuracy: \(location.horizontalAccuracy)m")
            print("   • Timestamp: \(location.timestamp.formatted(date: .omitted, time: .standard))")
        } else {
            print("   • Coordinates: Not available")
        }
        if let error = locationManager.errorMessage {
            print("   • Error: \(error)")
        }
        
        // Golf Course Information
        print("⛳ GOLF COURSES:")
        print("   • Is Loading: \(golfCourseManager.isLoading)")
        print("   • Courses Found: \(golfCourseManager.nearbyCourses.count)")
        if let nearest = golfCourseManager.nearestCourse {
            print("   • Nearest Course: \(nearest.name)")
            print("   • Distance: \(distanceText)")
            print("   • Location: \(nearest.locationString)")
        } else {
            print("   • Nearest Course: Not found")
        }
        if let error = golfCourseManager.errorMessage {
            print("   • Error: \(error)")
        }
        
        // Weather Information
        print("🌤️ WEATHER:")
        print("   • Is Loading: \(weatherManager.isLoading)")
        print("   • Temperature: \(weatherManager.temperatureString)")
        print("   • Wind: \(weatherManager.windString)")
        print("   • Icon: \(weatherManager.weatherIconName)")
        print("   • Icon Color: \(weatherManager.weatherIconColor)")
        
        if let weather = weatherManager.currentWeather {
            print("   • Raw Temperature: \(weather.main.temp)°F")
            print("   • Feels Like: \(weather.main.feelsLike)°F")
            print("   • Humidity: \(weather.main.humidity)%")
            print("   • Description: \(weather.weather.first?.description ?? "N/A")")
            print("   • Location Name: \(weather.name)")
            if let wind = weather.wind {
                print("   • Wind Speed: \(wind.speed) mph")
                print("   • Wind Direction: \(wind.deg ?? 0)°")
            }
        } else {
            print("   • Weather Data: Not available")
        }
        
        if let error = weatherManager.errorMessage {
            print("   • Error: \(error)")
        }
        
        print("🏌️ === End Debug Info ===")
    }
    
    private var sessionStatusColor: Color {
        if hasTempSession {
            return theme.warning
        } else if session != nil {
            return theme.success
        } else {
            return theme.textSecondary
        }
    }
    
    private var sessionStatusText: String {
        if hasTempSession {
            return "In Progress"
        } else if session != nil {
            return "New"
        } else {
            return "Not Started"
        }
    }
}

#Preview {
    CurrentSessionCardView(session: nil)
        .padding()
        .environmentObject(ThemeManager())
        .environmentObject(LocationManager())
        .environmentObject(MockWeatherManager())
        .environmentObject(MockGolfCourseManager())
        .themed()
} 