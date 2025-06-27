import SwiftUI
import CoreLocation

struct PracticeLocationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @EnvironmentObject private var golfCourseManager: GolfCourseManager
    @EnvironmentObject private var locationManager: LocationManager
    @State private var customLocationText: String = ""
    @State private var showingCustomInput: Bool = false
    @State private var savedCustomLocations: [String] = []
    
    let onLocationSelected: (PracticeLocation) -> Void
    
    private let customLocationsKey = "saved_custom_locations"
    
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
                if showingCustomInput {
                    customLocationInputView
                } else {
                    mainLocationView
                }
            }
            .navigationTitle("Practice Location")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(theme.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(showingCustomInput ? "Back" : "Custom") {
                        showingCustomInput.toggle()
                        if !showingCustomInput {
                            customLocationText = ""
                        }
                    }
                    .foregroundColor(theme.primary)
                }
            }
            .onAppear {
                loadSavedCustomLocations()
            }
        }
    }
    
    @ViewBuilder
    private var customLocationInputView: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Enter Custom Location")
                    .font(.headline)
                    .foregroundColor(theme.textPrimary)
                
                Text("Enter the name of your practice location (e.g., \"Home Backyard\", \"Local Park\", \"Driving Range XYZ\")")
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.leading)
                
                TextField("Practice location name", text: $customLocationText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.body)
                    .submitLabel(.done)
                    .onSubmit {
                        saveCustomLocation()
                    }
            }
            .padding()
            .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
            
            Button(action: saveCustomLocation) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Use This Location")
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(customLocationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? theme.textSecondary : theme.primary)
                .cornerRadius(12)
            }
            .disabled(customLocationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            
            Spacer()
        }
        .padding()
    }
    
    @ViewBuilder
    private var mainLocationView: some View {
        List {
            // Section 1: Nearby Golf Facilities
            if golfCourseManager.isLoading {
                Section("Nearby Golf Facilities") {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Finding nearby golf facilities...")
                            .font(.subheadline)
                            .foregroundColor(theme.textSecondary)
                    }
                    .padding(.vertical, 8)
                }
            } else if !sortedCourses.isEmpty {
                Section("Nearby Golf Facilities") {
                    ForEach(sortedCourses) { course in
                        PracticeLocationRowView(
                            location: .golfFacility(course),
                            userLocation: locationManager.location
                        ) {
                            onLocationSelected(.golfFacility(course))
                            dismiss()
                        }
                    }
                }
            }
            
            // Section 2: Saved Custom Locations
            if !savedCustomLocations.isEmpty {
                Section("Your Practice Locations") {
                    ForEach(savedCustomLocations, id: \.self) { locationName in
                        PracticeLocationRowView(
                            location: .custom(locationName),
                            userLocation: locationManager.location
                        ) {
                            onLocationSelected(.custom(locationName))
                            dismiss()
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button("Delete", role: .destructive) {
                                deleteCustomLocation(locationName)
                            }
                        }
                    }
                }
            }
            
            // Section 3: Add New Custom Location
            Section("Add Custom Location") {
                Button(action: { showingCustomInput = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(theme.primary)
                            .font(.title2)
                            .frame(width: 24, height: 24)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Add Custom Location")
                                .font(.headline)
                                .foregroundColor(theme.primary)
                            
                            Text("Enter your own practice location")
                                .font(.subheadline)
                                .foregroundColor(theme.textSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Section 4: Empty State or Error for Golf Facilities
            if !golfCourseManager.isLoading && sortedCourses.isEmpty {
                Section("Nearby Golf Facilities") {
                    VStack(spacing: 12) {
                        Image(systemName: "location.slash")
                            .font(.title2)
                            .foregroundColor(theme.textSecondary)
                        
                        Text("No Golf Facilities Found")
                            .font(.headline)
                            .foregroundColor(theme.textPrimary)
                        
                        Text("No golf courses or driving ranges found within 5km of your location.")
                            .font(.subheadline)
                            .foregroundColor(theme.textSecondary)
                            .multilineTextAlignment(.center)
                        
                        if let error = golfCourseManager.errorMessage {
                            Text("Error: \(error)")
                                .font(.caption)
                                .foregroundColor(theme.error)
                        }
                        
                        Button("Refresh") {
                            if let location = locationManager.location {
                                golfCourseManager.searchNearbyGolfCourses(location: location)
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(theme.primary)
                        .padding(.top, 8)
                        .disabled(golfCourseManager.isLoading || locationManager.location == nil)
                    }
                    .padding(.vertical, 16)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    // MARK: - Custom Location Management
    
    private func saveCustomLocation() {
        let trimmedText = customLocationText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        // Check if location already exists
        if savedCustomLocations.contains(trimmedText) {
            // Location already exists, just select it
            let customLocation = PracticeLocation.custom(trimmedText)
            onLocationSelected(customLocation)
            dismiss()
            return
        }
        
        // Add new location to saved list
        savedCustomLocations.append(trimmedText)
        saveSavedCustomLocations()
        
        // Select the new location
        let customLocation = PracticeLocation.custom(trimmedText)
        onLocationSelected(customLocation)
        dismiss()
    }
    
    private func deleteCustomLocation(_ locationName: String) {
        savedCustomLocations.removeAll { $0 == locationName }
        saveSavedCustomLocations()
    }
    
    private func loadSavedCustomLocations() {
        savedCustomLocations = UserDefaults.standard.stringArray(forKey: customLocationsKey) ?? []
    }
    
    private func saveSavedCustomLocations() {
        UserDefaults.standard.set(savedCustomLocations, forKey: customLocationsKey)
    }
}

// MARK: - Practice Location Model

enum PracticeLocation {
    case golfFacility(Course)
    case custom(String)
    
    var displayName: String {
        switch self {
        case .golfFacility(let course):
            return course.displayName
        case .custom(let name):
            return name
        }
    }
    
    var name: String {
        switch self {
        case .golfFacility(let course):
            return course.name
        case .custom(let name):
            return name
        }
    }
    
    var type: String {
        switch self {
        case .golfFacility(let course):
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
        case .custom:
            return "Custom Location"
        }
    }
    
    var location: CLLocation? {
        switch self {
        case .golfFacility(let course):
            return course.location
        case .custom:
            return nil
        }
    }
    
    var icon: String {
        switch self {
        case .golfFacility(let course):
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
        case .custom:
            return "location.circle.fill"
        }
    }
}

struct PracticeLocationRowView: View {
    @Environment(\.theme) private var theme
    let location: PracticeLocation
    let userLocation: CLLocation?
    let onTap: () -> Void
    
    // Computed property for distance display
    private var distanceText: String {
        switch location {
        case .custom:
            return ""
        case .golfFacility:
            guard let userLocation = userLocation,
                  let locationCoordinate = location.location else {
                return ""
            }
            
            let distance = userLocation.distance(from: locationCoordinate) / 1609.34 // Convert to miles
            
            if distance < 1.0 {
                return String(format: "%.1f mi", distance)
            } else {
                return String(format: "%.0f mi", distance)
            }
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Location icon
                Image(systemName: location.icon)
                    .foregroundColor(theme.primary)
                    .font(.title2)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.displayName)
                        .font(.headline)
                        .foregroundColor(theme.textPrimary)
                        .lineLimit(1)
                    
                    Text(location.type)
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
    PracticeLocationView { location in
        print("Selected location: \(location.name)")
    }
    .environmentObject(MockGolfCourseManager())
    .environmentObject(LocationManager())
    .themed()
} 