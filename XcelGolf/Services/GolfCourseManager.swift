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
        // Overpass QL query - search for both golf courses and driving ranges
        let query = """
        [out:json][timeout:25];
        (
          node(around:\(Int(radius)),\(lat),\(lon))["leisure"="golf_course"];
          way(around:\(Int(radius)),\(lat),\(lon))["leisure"="golf_course"];
          rel(around:\(Int(radius)),\(lat),\(lon))["leisure"="golf_course"];
          node(around:\(Int(radius)),\(lat),\(lon))["golf"="driving_range"];
          way(around:\(Int(radius)),\(lat),\(lon))["golf"="driving_range"];
          rel(around:\(Int(radius)),\(lat),\(lon))["golf"="driving_range"];
          node(around:\(Int(radius)),\(lat),\(lon))["sport"="golf"];
          way(around:\(Int(radius)),\(lat),\(lon))["sport"="golf"];
          rel(around:\(Int(radius)),\(lat),\(lon))["sport"="golf"];
        );
        out center;
        """

        // Prepare URLRequest
        var request = URLRequest(url: URL(string: "https://overpass-api.de/api/interpreter")!)
        request.httpMethod = "POST"
        let bodyString = "data=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)"
        request.httpBody = bodyString.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "Content-Type")

        print("⛳ Overpass Query: \(query)")

        // Send request
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        // Decode Overpass response
        let overpass = try JSONDecoder().decode(OverpassResponse.self, from: data)

        // Map elements to Course with enhanced name detection and filtering
        let allCourses = overpass.elements.compactMap { elem -> Course? in
            // Determine coords
            let lat = elem.lat ?? elem.center?.lat
            let lon = elem.lon ?? elem.center?.lon
            guard let lat = lat, let lon = lon, let tags = elem.tags else { return nil }
            
            // Enhanced name detection with type identification
            let name = determineName(from: tags)
            
            return Course(id: elem.id, name: name, latitude: lat, longitude: lon, tags: tags)
        }
        
        // Filter out unnamed facilities and only show verified/real places
        let filteredCourses = allCourses.filter { course in
            isValidGolfFacility(course)
        }
        
        print("⛳ Found \(allCourses.count) total facilities, filtered to \(filteredCourses.count) verified facilities")
        return filteredCourses
    }
    
    /// Check if a golf facility is valid (has a proper name and looks like a real place)
    private func isValidGolfFacility(_ course: Course) -> Bool {
        let name = course.name.lowercased()
        
        // Filter out unnamed facilities
        if name.hasPrefix("unnamed") {
            return false
        }
        
        // Filter out very short names (likely incomplete data)
        if course.name.count < 3 {
            return false
        }
        
        // Filter out names that are just numbers or coordinates
        if course.name.allSatisfy({ $0.isNumber || $0.isWhitespace || $0 == "." || $0 == "," || $0 == "-" }) {
            return false
        }
        
        // Check if the course has a proper name tag (not just generated)
        if let nameTag = course.tags["name"], !nameTag.isEmpty {
            // Has a real name - this is good
            return true
        }
        
        // If no name tag, check for other identifying information
        if let brand = course.tags["brand"], !brand.isEmpty {
            // Has a brand name - this is acceptable
            return true
        }
        
        if let operatorName = course.tags["operator"], !operatorName.isEmpty {
            // Has an operator name - this is acceptable
            return true
        }
        
        // Check for website or phone (indicates established business)
        if course.tags["website"] != nil || course.tags["phone"] != nil {
            return true
        }
        
        // If none of the above, it's likely incomplete data
        return false
    }
    
    /// Determine the best name and type for a golf facility
    private func determineName(from tags: [String: String]) -> String {
        // First try to get the actual name
        if let name = tags["name"], !name.isEmpty {
            let facilityType = determineFacilityType(from: tags)
            if facilityType != "Golf Course" {
                return "\(name) (\(facilityType))"
            }
            return name
        }
        
        // Try brand name
        if let brand = tags["brand"], !brand.isEmpty {
            let facilityType = determineFacilityType(from: tags)
            if facilityType != "Golf Course" {
                return "\(brand) (\(facilityType))"
            }
            return brand
        }
        
        // Try operator name
        if let operatorName = tags["operator"], !operatorName.isEmpty {
            let facilityType = determineFacilityType(from: tags)
            if facilityType != "Golf Course" {
                return "\(operatorName) (\(facilityType))"
            }
            return operatorName
        }
        
        // If no name, create one based on type (this will be filtered out)
        let facilityType = determineFacilityType(from: tags)
        return "Unnamed \(facilityType)"
    }
    
    /// Determine what type of golf facility this is
    private func determineFacilityType(from tags: [String: String]) -> String {
        // Check for driving range indicators
        if tags["golf"] == "driving_range" {
            return "Driving Range"
        }
        
        // Check for specific golf facility types
        if let golfType = tags["golf"] {
            switch golfType {
            case "driving_range": return "Driving Range"
            case "practice": return "Practice Facility"
            case "miniature": return "Mini Golf"
            case "disc": return "Disc Golf"
            default: break
            }
        }
        
        // Check leisure tag
        if tags["leisure"] == "golf_course" {
            return "Golf Course"
        }
        
        // Check sport tag
        if tags["sport"] == "golf" {
            return "Golf Facility"
        }
        
        // Default
        return "Golf Course"
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
