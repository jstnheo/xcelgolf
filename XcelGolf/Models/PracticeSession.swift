import Foundation
import SwiftData

@Model
class PracticeSession {
    var date: Date
    var notes: String?
    @Relationship(deleteRule: .cascade) var drills: [Drill] = []
    
    // MARK: - Weather Data
    var temperature: Double? // Temperature in Fahrenheit
    var weatherCondition: String? // e.g., "Clear", "Cloudy", "Rain"
    var weatherDescription: String? // e.g., "clear sky", "light rain"
    var humidity: Int? // Humidity percentage
    var feelsLikeTemperature: Double? // Feels like temperature in Fahrenheit
    
    // MARK: - Wind Data
    var windSpeed: Double? // Wind speed in mph
    var windDirection: Int? // Wind direction in degrees (0-360)
    var windDirectionText: String? // Wind direction as text (e.g., "NE", "SW")
    
    // MARK: - Location Data
    var locationName: String? // Human-readable location name (city, state)
    var latitude: Double? // GPS latitude
    var longitude: Double? // GPS longitude
    var golfCourseName: String? // Name of the golf course/facility
    var golfCourseType: String? // Type: "Golf Course", "Driving Range", etc.
    
    init(date: Date = .now, notes: String? = nil) {
        self.date = date
        self.notes = notes
    }
    
    // MARK: - Computed Properties
    var totalDrills: Int {
        drills.count
    }
    
    var averageSuccessPercentage: Int {
        guard !drills.isEmpty else { return 0 }
        let totalPercentage = drills.reduce(0) { $0 + $1.successPercentage }
        return totalPercentage / drills.count
    }
    
    // MARK: - Weather Analysis Helpers
    var hasWeatherData: Bool {
        temperature != nil && weatherCondition != nil
    }
    
    var hasWindData: Bool {
        windSpeed != nil
    }
    
    var hasLocationData: Bool {
        latitude != nil && longitude != nil
    }
    
    var hasGolfCourseData: Bool {
        golfCourseName != nil
    }
    
    var weatherSummary: String {
        guard hasWeatherData else { return "No weather data" }
        
        var summary = "\(Int(temperature?.rounded() ?? 0))°F"
        if let condition = weatherCondition {
            summary += ", \(condition)"
        }
        if hasWindData {
            summary += ", \(Int(windSpeed?.rounded() ?? 0)) mph"
            if let windDir = windDirectionText {
                summary += " \(windDir)"
            }
        }
        return summary
    }
    
    var locationSummary: String {
        if let courseName = golfCourseName {
            return courseName
        } else if let locationName = locationName {
            return locationName
        } else {
            return "Unknown Location"
        }
    }
}

extension PracticeSession: Identifiable {} 