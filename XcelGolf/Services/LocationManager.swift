import Foundation
import CoreLocation
import SwiftUI

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationName: String = "Unknown Location"
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 100 // Update every 100 meters
    }
    
    // MARK: - Public Methods
    
    /// Request location permissions at app launch
    func requestLocationPermission() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            print("Location access denied or restricted")
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            break
        }
    }
    
    /// Start receiving location updates
    func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            print("Location not authorized")
            return
        }
        
        guard CLLocationManager.locationServicesEnabled() else {
            errorMessage = "Location services disabled"
            return
        }
        
        isLoading = true
        locationManager.startUpdatingLocation()
    }
    
    /// Stop receiving location updates
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        isLoading = false
    }
    
    /// Get readable location name from coordinates
    private func reverseGeocode(_ location: CLLocation) {
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Reverse geocoding error: \(error.localizedDescription)")
                    self?.locationName = "Unknown Location"
                    self?.errorMessage = "Unable to determine location name"
                    return
                }
                
                guard let placemark = placemarks?.first else {
                    self?.locationName = "Unknown Location"
                    return
                }
                
                // Create a readable location name
                var locationComponents: [String] = []
                
                // Add locality (city) if available
                if let locality = placemark.locality {
                    locationComponents.append(locality)
                }
                
                // Add administrative area (state) if available and different from locality
                if let adminArea = placemark.administrativeArea,
                   adminArea != placemark.locality {
                    locationComponents.append(adminArea)
                }
                
                // Fallback to name or thoroughfare if no locality
                if locationComponents.isEmpty {
                    if let name = placemark.name {
                        locationComponents.append(name)
                    } else if let thoroughfare = placemark.thoroughfare {
                        locationComponents.append(thoroughfare)
                    }
                }
                
                self?.locationName = locationComponents.isEmpty ? "Unknown Location" : locationComponents.joined(separator: ", ")
                self?.errorMessage = nil
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        
        // Only update if the new location is significantly different or it's the first location
        if let currentLocation = location {
            let distance = newLocation.distance(from: currentLocation)
            if distance < 100 { // Less than 100 meters difference
                return
            }
        }
        
        DispatchQueue.main.async {
            self.location = newLocation
            self.isLoading = false
            self.errorMessage = nil
        }
        
        // Get readable location name
        reverseGeocode(newLocation)
        
        // Stop updating after getting a good location to save battery
        stopLocationUpdates()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.errorMessage = "Failed to get location: \(error.localizedDescription)"
            print("Location error: \(error.localizedDescription)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
            
            switch status {
            case .notDetermined:
                print("Location authorization not determined")
            case .denied:
                print("Location authorization denied")
                self.errorMessage = "Location access denied"
            case .restricted:
                print("Location authorization restricted")
                self.errorMessage = "Location access restricted"
            case .authorizedWhenInUse:
                print("Location authorized when in use")
                self.startLocationUpdates()
            case .authorizedAlways:
                print("Location authorized always")
                self.startLocationUpdates()
            @unknown default:
                break
            }
        }
    }
} 