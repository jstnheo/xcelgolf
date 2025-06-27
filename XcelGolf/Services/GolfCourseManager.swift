import Foundation
import CoreLocation
import SwiftUI

// MARK: - Golf Course Models

/// Represents a golf course returned from Overpass API
struct Course: Identifiable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let tags: [String: String]
}

// MARK: - Overpass Response Models

private struct OverpassResponse: Codable {
    let elements: [Element]
}

private struct Element: Codable {
    let id: Int
    let lat: Double?
    let lon: Double?
    let center: Center?
    let tags: [String: String]?
}

private struct Center: Codable {
    let lat: Double
    let lon: Double
}

// MARK: - Golf Course Manager

@MainActor
class GolfCourseManager: ObservableObject {
    @Published var nearbyCourses: [Course] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Computed properties for backward compatibility
    var nearestCourse: Course? {
        nearbyCourses.first
    }

    var hasValidCourseData: Bool {
        !nearbyCourses.isEmpty
    }

    /// Search for golf courses using OpenStreetMap Overpass API
    func searchNearbyCourses(around location: CLLocation, radius: Double = 5000) {
        isLoading = true
        errorMessage = nil
        nearbyCourses = []

        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        print("⛳ Searching Overpass around \(lat), \(lon) radius: \(radius)m")

        Task {
            do {
                let courses = try await fetchOverpassCourses(lat: lat, lon: lon, radius: radius)
                self.nearbyCourses = courses
                self.isLoading = false
                print("⛳ Found \(courses.count) courses")
            } catch {
                self.errorMessage = "Overpass API error: \(error.localizedDescription)"
                self.isLoading = false
                print("⛳ Error - \(error)")
            }
        }
    }

    /// Backward compatibility method - calls the new Overpass API method
    func searchNearbyGolfCourses(location: CLLocation) {
        searchNearbyCourses(around: location, radius: 5000)
    }

    /// Perform Overpass API request and decode courses
    private func fetchOverpassCourses(lat: Double, lon: Double, radius: Double) async throws -> [Course] {
        // Overpass QL query
        let query = """
        [out:json][timeout:25];
        (
          node(around:\(Int(radius)),\(lat),\(lon))["leisure"="golf_course"];
          way(around:\(Int(radius)),\(lat),\(lon))["leisure"="golf_course"];
          rel(around:\(Int(radius)),\(lat),\(lon))["leisure"="golf_course"];
        );
        out center;
        """

        // Prepare URLRequest
        var request = URLRequest(url: URL(string: "https://overpass-api.de/api/interpreter")!)
        request.httpMethod = "POST"
        let bodyString = "data=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)"
        request.httpBody = bodyString.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "Content-Type")

        // Send request
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        // Decode Overpass response
        let overpass = try JSONDecoder().decode(OverpassResponse.self, from: data)

        // Map elements to Course
        return overpass.elements.compactMap { elem in
            // Determine coords
            let lat = elem.lat ?? elem.center?.lat
            let lon = elem.lon ?? elem.center?.lon
            guard let lat = lat, let lon = lon, let tags = elem.tags else { return nil }
            let name = tags["name"] ?? "Unnamed Course"
            return Course(id: elem.id, name: name, latitude: lat, longitude: lon, tags: tags)
        }
    }
}

// MARK: - Course Extensions

extension Course {
    var displayName: String {
        name
    }

    var locationString: String {
        // Try to build a readable address from tags
        var components: [String] = []
        
        if let city = tags["addr:city"] {
            components.append(city)
        }
        if let state = tags["addr:state"] {
            components.append(state)
        }
        if let country = tags["addr:country"] {
            components.append(country)
        }
        
        if components.isEmpty {
            return "Golf Course"
        }
        
        return components.joined(separator: ", ")
    }

    var location: CLLocation? {
        return CLLocation(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Mock Golf Course Manager for Previews

/// A mock manager to use in SwiftUI previews
class MockGolfCourseManager: GolfCourseManager {
    override func searchNearbyCourses(around location: CLLocation, radius: Double = 5000) {
        // Provide static mock data
        let mock = Course(id: 1,
                          name: "Mock Golf Course",
                          latitude: location.coordinate.latitude + 0.001,
                          longitude: location.coordinate.longitude + 0.001,
                          tags: ["name": "Mock Golf Course"])
        self.nearbyCourses = [mock]
        self.isLoading = false
    }
}
