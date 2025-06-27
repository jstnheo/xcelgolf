import Foundation
import CoreLocation
import SwiftUI

// MARK: - Weather Models

struct WeatherData: Codable {
    let main: MainWeather
    let weather: [Weather]
    let wind: Wind?
    let name: String
    
    struct MainWeather: Codable {
        let temp: Double
        let feelsLike: Double
        let humidity: Int
        
        enum CodingKeys: String, CodingKey {
            case temp
            case feelsLike = "feels_like"
            case humidity
        }
    }
    
    struct Weather: Codable {
        let main: String
        let description: String
        let icon: String
    }
    
    struct Wind: Codable {
        let speed: Double
        let deg: Int?
    }
}

// MARK: - Weather Manager

class WeatherManager: ObservableObject {
    @Published var currentWeather: WeatherData?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // OpenWeatherMap API key - you'll need to get this from openweathermap.org
    private let apiKey = "01291032408206b82f063d3657da94d1" // Replace with actual API key
    private let baseURL = "https://api.openweathermap.org/data/2.5/weather"
    
    // MARK: - Public Methods
    
    /// Fetch weather data for a given location
    func fetchWeather(for location: CLLocation) {
        print("🌤️ WeatherManager: fetchWeather called for location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        guard !apiKey.isEmpty else {
            print("🌤️ WeatherManager: Weather API key not configured")
            return
        }
        
        print("🌤️ WeatherManager: API key is configured, proceeding with request")
        
        isLoading = true
        errorMessage = nil
        
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        
        let urlString = "\(baseURL)?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=imperial"
        print("🌤️ WeatherManager: Request URL: \(urlString.replacingOccurrences(of: apiKey, with: "***API_KEY***"))")
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Invalid URL"
                print("🌤️ WeatherManager: Invalid URL error")
            }
            return
        }
        
        print("🌤️ WeatherManager: Starting network request...")
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Network error: \(error.localizedDescription)"
                    print("🌤️ WeatherManager: Network error: \(error)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("🌤️ WeatherManager: HTTP Status Code: \(httpResponse.statusCode)")
                }
                
                guard let data = data else {
                    self?.errorMessage = "No data received"
                    print("🌤️ WeatherManager: No data received")
                    return
                }
                
                print("🌤️ WeatherManager: Received \(data.count) bytes of data")
                
                do {
                    let weatherData = try JSONDecoder().decode(WeatherData.self, from: data)
                    self?.currentWeather = weatherData
                    self?.errorMessage = nil
                    print("🌤️ WeatherManager: Weather data updated successfully: \(weatherData.main.temp)°F, \(weatherData.weather.first?.description ?? "N/A")")
                } catch {
                    self?.errorMessage = "Failed to decode weather data: \(error.localizedDescription)"
                    print("🌤️ WeatherManager: Decode error: \(error)")
                    if let dataString = String(data: data, encoding: .utf8) {
                        print("🌤️ WeatherManager: Raw response: \(dataString)")
                    }
                }
            }
        }.resume()
    }
    
    // MARK: - Helper Methods
    
    /// Get temperature string with proper formatting
    var temperatureString: String {
        guard let weather = currentWeather else { 
            return isLoading ? "Loading..." : "N/A" 
        }
        return "\(Int(weather.main.temp.rounded()))°F"
    }
    
    /// Get wind information string
    var windString: String {
        guard let weather = currentWeather, let wind = weather.wind else { 
            return isLoading ? "Loading..." : "No data" 
        }
        
        let speed = Int(wind.speed.rounded())
        let direction = windDirection(from: wind.deg)
        return "\(speed) mph \(direction)"
    }
    
    /// Get weather icon name for SF Symbols
    var weatherIconName: String {
        if isLoading {
            return "cloud.fill" // Neutral loading icon
        }
        
        guard let weather = currentWeather?.weather.first else { 
            return "sun.max.fill" // Friendly fallback icon
        }
        
        switch weather.main.lowercased() {
        case "clear":
            return "sun.max.fill"
        case "clouds":
            return "cloud.fill"
        case "rain":
            return "cloud.rain.fill"
        case "drizzle":
            return "cloud.drizzle.fill"
        case "thunderstorm":
            return "cloud.bolt.fill"
        case "snow":
            return "cloud.snow.fill"
        case "mist", "fog", "haze":
            return "cloud.fog.fill"
        default:
            return "sun.max.fill"
        }
    }
    
    /// Get weather icon color
    var weatherIconColor: Color {
        if isLoading {
            return .gray // Neutral loading color
        }
        
        guard let weather = currentWeather?.weather.first else { 
            return .gray // Muted color when unavailable
        }
        
        switch weather.main.lowercased() {
        case "clear":
            return .orange
        case "clouds":
            return .gray
        case "rain", "drizzle":
            return .blue
        case "thunderstorm":
            return .purple
        case "snow":
            return .white
        case "mist", "fog", "haze":
            return .gray
        default:
            return .orange
        }
    }
    
    /// Convert wind degree to direction
    private func windDirection(from degrees: Int?) -> String {
        guard let degrees = degrees else { return "N" }
        
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                         "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        
        let index = Int((Double(degrees) + 11.25) / 22.5) % 16
        return directions[index]
    }
    
    /// Check if weather data is stale (older than 10 minutes)
    var isWeatherDataStale: Bool {
        // For now, we'll refresh weather when location changes
        // In a more sophisticated implementation, you could add timestamps
        return currentWeather == nil
    }
}

// MARK: - Mock Weather Manager for Previews

class MockWeatherManager: WeatherManager {
    override init() {
        super.init()
        
        // Set mock data for previews
        self.currentWeather = WeatherData(
            main: WeatherData.MainWeather(temp: 72.0, feelsLike: 75.0, humidity: 65),
            weather: [WeatherData.Weather(main: "Clear", description: "clear sky", icon: "01d")],
            wind: WeatherData.Wind(speed: 5.2, deg: 45),
            name: "Mock Location"
        )
    }
    
    override func fetchWeather(for location: CLLocation) {
        // Mock implementation - don't make actual API calls in previews
        isLoading = false
    }
} 
