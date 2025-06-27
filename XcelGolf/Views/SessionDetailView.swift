import SwiftUI
import SwiftData

struct SessionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.theme) private var theme
    @EnvironmentObject var toastManager: ToastManager
    @Bindable var session: PracticeSession
    @State private var showingAddDrill = false
    
    var body: some View {
        List {
            Section("Session Details") {
                DatePicker("Date", selection: $session.date)
                    .foregroundColor(theme.textPrimary)
                TextField("Notes", text: Binding(
                    get: { session.notes ?? "" },
                    set: { session.notes = $0.isEmpty ? nil : $0 }
                ))
                .foregroundColor(theme.textPrimary)
                
                if session.totalDrills > 0 {
                    HStack {
                        Text("Success Rate:")
                            .foregroundColor(theme.textPrimary)
                        Spacer()
                        Text("\(session.averageSuccessPercentage)%")
                            .foregroundColor(theme.success)
                            .fontWeight(.semibold)
                    }
                }
            }
            
            // Weather & Conditions Section
            if session.hasWeatherData || session.hasLocationData || session.hasGolfCourseData {
                Section("Conditions") {
                    // Weather Information
                    if session.hasWeatherData {
                        HStack {
                            Image(systemName: weatherIcon(for: session.weatherCondition))
                                .foregroundColor(weatherIconColor(for: session.weatherCondition))
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(session.weatherSummary)
                                    .foregroundColor(theme.textPrimary)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                if let description = session.weatherDescription {
                                    Text(description.capitalized)
                                        .foregroundColor(theme.textSecondary)
                                        .font(.caption)
                                }
                            }
                            
                            Spacer()
                            
                            if let humidity = session.humidity {
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(humidity)%")
                                        .foregroundColor(theme.textPrimary)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    Text("Humidity")
                                        .foregroundColor(theme.textSecondary)
                                        .font(.caption2)
                                }
                            }
                        }
                    }
                    
                    // Location Information
                    if session.hasLocationData {
                        HStack {
                            Image(systemName: session.hasGolfCourseData ? "flag.fill" : "location.fill")
                                .foregroundColor(theme.primary)
                                .font(.subheadline)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(session.locationSummary)
                                    .foregroundColor(theme.textPrimary)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                if let courseType = session.golfCourseType, session.hasGolfCourseData {
                                    Text(courseType)
                                        .foregroundColor(theme.textSecondary)
                                        .font(.caption)
                                }
                            }
                            
                            Spacer()
                            
                            if let distance = session.distanceToGolfCourse {
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(String(format: "%.1f mi", distance))
                                        .foregroundColor(theme.textPrimary)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    Text("Distance")
                                        .foregroundColor(theme.textSecondary)
                                        .font(.caption2)
                                }
                            }
                        }
                    }
                }
            }
            
            Section("Drills") {
                ForEach(session.drills.sorted { $0.completedAt < $1.completedAt }) { drill in
                    DrillRow(drill: drill)
                }
                .onDelete(perform: deleteDrills)
            }
        }
        .scrollContentBackground(.hidden)
        .background(theme.background)
        .navigationTitle("Practice Session")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddDrill = true }) {
                    Label("Add Drill", systemImage: "plus")
                }
                .foregroundColor(theme.primary)
            }
        }
        .sheet(isPresented: $showingAddDrill) {
            NewExerciseView(session: session)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Get weather icon for condition
    private func weatherIcon(for condition: String?) -> String {
        guard let condition = condition?.lowercased() else { return "sun.max.fill" }
        
        switch condition {
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
    private func weatherIconColor(for condition: String?) -> Color {
        guard let condition = condition?.lowercased() else { return .orange }
        
        switch condition {
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
    
    private func deleteDrills(offsets: IndexSet) {
        withAnimation {
            let sortedDrills = session.drills.sorted { $0.completedAt < $1.completedAt }
            let drillCount = offsets.count
            
            for index in offsets {
                let drill = sortedDrills[index]
                if let drillIndex = session.drills.firstIndex(of: drill) {
                    session.drills.remove(at: drillIndex)
                }
                modelContext.delete(drill)
            }
            
            // Explicitly save the context to ensure persistence
            do {
                try modelContext.save()
                let message = drillCount == 1 ? "1 drill deleted" : "\(drillCount) drills deleted"
                toastManager.showSuccess("Drills Deleted", message: message)
            } catch {
                print("Failed to save after deleting drills: \(error)")
                toastManager.showError("Delete Failed", message: "Unable to delete drills")
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PracticeSession.self, Drill.self, configurations: config)
    let context = container.mainContext
    
    let session = PracticeSession()
    context.insert(session)
    
    return SessionDetailView(session: session)
        .modelContainer(container)
        .environmentObject(ThemeManager())
        .themed()
} 