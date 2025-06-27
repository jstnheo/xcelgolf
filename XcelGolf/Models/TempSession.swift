import Foundation

/// Temporary session model used before saving to SwiftData
struct TempSession: Codable {
    let id: String
    let startDate: Date
    var drillResults: [TempDrillResult]
    
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
    
    init() {
        self.id = UUID().uuidString
        self.startDate = Date()
        self.drillResults = []
    }
}

/// Temporary drill result model used during session
struct TempDrillResult: Codable {
    let drillTemplate: DrillTemplate
    let score: Int?
    let isCompleted: Bool
    let completedAt: Date
} 