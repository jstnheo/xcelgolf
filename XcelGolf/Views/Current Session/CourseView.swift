import SwiftUI
import CoreLocation

struct CourseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @EnvironmentObject private var golfCourseManager: GolfCourseManager
    @EnvironmentObject private var locationManager: LocationManager
    
    let onCourseSelected: (Course) -> Void
    
    // Computed property to sort courses by distance
    private var sortedCourses: [Course] {
        guard let userLocation = locationManager.location else {
            return golfCourseManager.nearbyCourses
        }
        
        return golfCourseManager.nearbyCourses.sorted { course1, course2 in
            let distance1 = userLocation.distance(from: CLLocation(latitude: course1.latitude, longitude: course1.longitude))
            let distance2 = userLocation.distance(from: CLLocation(latitude: course2.latitude, longitude: course2.longitude))
            return distance1 < distance2
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if golfCourseManager.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Finding nearby golf courses and driving ranges...")
                            .font(.subheadline)
                            .foregroundColor(theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if sortedCourses.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "location.slash")
                            .font(.system(size: 48))
                            .foregroundColor(theme.textSecondary)
                        
                        Text("No Golf Facilities Found")
                            .font(.headline)
                            .foregroundColor(theme.textPrimary)
                        
                        Text("No golf courses or driving ranges found within 5km of your location. Try moving to a different area.")
                            .font(.subheadline)
                            .foregroundColor(theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        if let error = golfCourseManager.errorMessage {
                            Text("Error: \(error)")
                                .font(.caption)
                                .foregroundColor(theme.error)
                                .padding(.horizontal)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(sortedCourses) { course in
                            CourseRowView(
                                course: course,
                                userLocation: locationManager.location
                            ) {
                                onCourseSelected(course)
                                dismiss()
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Golf Courses & Ranges")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(theme.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        if let location = locationManager.location {
                            golfCourseManager.searchNearbyGolfCourses(location: location)
                        }
                    }
                    .foregroundColor(theme.primary)
                    .disabled(golfCourseManager.isLoading || locationManager.location == nil)
                }
            }
        }
    }
}

struct CourseRowView: View {
    @Environment(\.theme) private var theme
    let course: Course
    let userLocation: CLLocation?
    let onTap: () -> Void
    
    // Computed property for distance display
    private var distanceText: String {
        guard let userLocation = userLocation else {
            return ""
        }
        
        let courseLocation = CLLocation(latitude: course.latitude, longitude: course.longitude)
        let distance = userLocation.distance(from: courseLocation) / 1609.34 // Convert to miles
        
        if distance < 1.0 {
            return String(format: "%.1f mi", distance)
        } else {
            return String(format: "%.0f mi", distance)
        }
    }
    
    // Computed property for facility icon
    private var facilityIcon: String {
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
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Golf facility icon
                Image(systemName: facilityIcon)
                    .foregroundColor(theme.primary)
                    .font(.title2)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(course.displayName)
                        .font(.headline)
                        .foregroundColor(theme.textPrimary)
                        .lineLimit(1)
                    
                    Text(course.locationString)
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    if !distanceText.isEmpty {
                        Text(distanceText)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(theme.primary)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CourseView { course in
        print("Selected course: \(course.name)")
    }
    .environmentObject(MockGolfCourseManager())
    .environmentObject(LocationManager())
    .themed()
} 