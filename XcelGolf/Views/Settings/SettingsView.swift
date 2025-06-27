import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.theme) private var theme
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var toastManager: ToastManager
    @State private var showingEraseConfirmation = false
    @State private var showingTestDataConfirmation = false
    @State private var isCreatingTestData = false
    @State private var showingThemeShowcase = false
    @State private var showingCustomizeDrills = false
    @State private var showingResetDrillsConfirmation = false
    @State private var showingExportData = false
    @State private var showingImportData = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Appearance") {
                    // Theme Selection
                    HStack {
                        Image(systemName: "paintbrush.fill")
                            .foregroundColor(theme.primary)
                        Text("Color Theme")
                        Spacer()
                        Menu {
                            Button("Sage Green") {
                                themeManager.useSageGreen()
                            }
                            Button("Blue") {
                                themeManager.useBlue()
                            }
                            Button("Minimal") {
                                themeManager.useMinimal()
                            }
                        } label: {
                            HStack {
                                Text(currentThemeName)
                                    .foregroundColor(theme.textSecondary)
                                Image(systemName: "chevron.down")
                                    .foregroundColor(theme.textSecondary)
                                    .font(.caption)
                            }
                        }
                    }
                    
                    // Theme Preview Button
                    Button(action: {
                        showingThemeShowcase = true
                    }) {
                        HStack {
                            Image(systemName: "eye.fill")
                                .foregroundColor(theme.primary)
                            Text("Preview Theme Components")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(theme.textSecondary)
                                .font(.caption)
                        }
                    }
                    .foregroundColor(theme.textPrimary)
                }

                Section("Drill Management") {
                    // Customize Drills
                    Button(action: {
                        showingCustomizeDrills = true
                    }) {
                        HStack {
                            Image(systemName: "list.bullet.clipboard.fill")
                                .foregroundColor(theme.primary)
                            Text("Customize Drills")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(theme.textSecondary)
                                .font(.caption)
                        }
                    }
                    .foregroundColor(theme.textPrimary)
                    
                    // Reset Drills to Defaults
                    Button(action: {
                        showingResetDrillsConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .foregroundColor(theme.warning)
                            Text("Reset Drills to Defaults")
                        }
                    }
                    .foregroundColor(theme.warning)
                }

                Section("Data Management") {
                    // Export Data
                    Button(action: {
                        showingExportData = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up.fill")
                                .foregroundColor(theme.primary)
                            Text("Export Data")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(theme.textSecondary)
                                .font(.caption)
                        }
                    }
                    .foregroundColor(theme.textPrimary)
                    
                    // Import Data
                    Button(action: {
                        showingImportData = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down.fill")
                                .foregroundColor(theme.primary)
                            Text("Import Data")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(theme.textSecondary)
                                .font(.caption)
                        }
                    }
                    .foregroundColor(theme.textPrimary)
                    
                    // Create Test Data
                    Button(action: {
                        showingTestDataConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(theme.success)
                            Text("Create Test Data")
                            if isCreatingTestData {
                                Spacer()
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(isCreatingTestData)
                    .foregroundColor(theme.textPrimary)
                    
                    // Erase All Data
                    Button(action: {
                        showingEraseConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(theme.error)
                            Text("Erase All Data")
                        }
                    }
                    .foregroundColor(theme.error)
                }
                
                Section("App Info") {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(theme.primary)
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                            .foregroundColor(theme.textSecondary)
                    }
                    
                    HStack {
                        Image(systemName: "hammer.fill")
                            .foregroundColor(theme.primary)
                        Text("Build")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")
                            .foregroundColor(theme.textSecondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .background(theme.background)
            .scrollContentBackground(.hidden)
            .safeAreaInset(edge: .bottom) {
                // Add padding for floating tab bar
                Color.clear.frame(height: 80)
            }
        }
        .confirmationDialog("Erase All Data", isPresented: $showingEraseConfirmation) {
            Button("Erase All Data", role: .destructive) {
                eraseAllData()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all practice sessions and drills. This action cannot be undone.")
        }
        .confirmationDialog("Create Test Data", isPresented: $showingTestDataConfirmation) {
            Button("Create Test Data") {
                createTestData()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will create 10 practice sessions with random dates from the past year, each containing 2-6 drills with varied performance data.")
        }
        .sheet(isPresented: $showingThemeShowcase) {
            ThemeShowcaseView()
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showingCustomizeDrills) {
            CustomizeDrillsView()
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showingExportData) {
            ExportDataView()
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showingImportData) {
            ImportDataView()
                .environmentObject(themeManager)
        }
        .confirmationDialog("Reset Drills to Defaults", isPresented: $showingResetDrillsConfirmation) {
            Button("Reset to Defaults", role: .destructive) {
                resetDrillsToDefaults()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will restore all default drills and remove all custom drills and modifications. This action cannot be undone.")
        }
    }
    
    private var currentThemeName: String {
        switch type(of: themeManager.currentTheme) {
        case is SageGreenTheme.Type:
            return "Sage Green"
        case is BlueTheme.Type:
            return "Blue"
        case is MinimalTheme.Type:
            return "Minimal"
        default:
            return "Custom"
        }
    }
    
    private func eraseAllData() {
        // Delete all practice sessions
        let sessionDescriptor = FetchDescriptor<PracticeSession>()
        let sessions = (try? modelContext.fetch(sessionDescriptor)) ?? []
        let sessionCount = sessions.count
        
        for session in sessions {
            modelContext.delete(session)
        }
        
        // Delete all drills
        let drillDescriptor = FetchDescriptor<Drill>()
        let drills = (try? modelContext.fetch(drillDescriptor)) ?? []
        let drillCount = drills.count
        
        for drill in drills {
            modelContext.delete(drill)
        }
        
        do {
            try modelContext.save()
            let message = "Deleted \(sessionCount) sessions and \(drillCount) drills"
            toastManager.showSuccess("All Data Erased", message: message)
        } catch {
            print("Failed to erase data: \(error)")
            toastManager.showError("Erase Failed", message: "Unable to delete all data")
        }
    }
    
    private func createTestData() {
        isCreatingTestData = true
        
        Task {
            await MainActor.run {
                // Create 10 test sessions with random dates and times
                for sessionIndex in 0..<10 {
                    // Generate random date between now and 1 year ago
                    let now = Date()
                    let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: now) ?? now
                    let randomTimeInterval = TimeInterval.random(in: oneYearAgo.timeIntervalSince1970...now.timeIntervalSince1970)
                    let randomDate = Date(timeIntervalSince1970: randomTimeInterval)
                    
                    // Adjust to realistic practice hours (7am - 8pm)
                    let calendar = Calendar.current
                    let startOfDay = calendar.startOfDay(for: randomDate)
                    let practiceStartHour = 7 // 7am
                    let practiceEndHour = 20 // 8pm
                    let randomHour = Int.random(in: practiceStartHour...practiceEndHour)
                    let randomMinute = Int.random(in: 0...59)
                    
                    guard let practiceDate = calendar.date(byAdding: .hour, value: randomHour, to: startOfDay),
                          let finalDate = calendar.date(byAdding: .minute, value: randomMinute, to: practiceDate) else {
                        continue
                    }
                    
                    // Create session with varied notes
                    let sessionNotes = [
                        "Great practice session today!",
                        "Worked on fundamentals",
                        "Focused on short game",
                        "Beautiful weather for golf",
                        "Morning practice session",
                        "Evening practice round",
                        "Concentrated on putting",
                        "Driving range session",
                        "Course practice",
                        "Quick tune-up session",
                        nil // Some sessions without notes
                    ]
                    
                    let testSession = PracticeSession(
                        date: finalDate,
                        notes: sessionNotes.randomElement() ?? nil
                    )
                    
                    modelContext.insert(testSession)
                    
                    // Create 2-6 random drills per session
                    let drillCount = Int.random(in: 2...6)
                    
                    let allDrillTemplates = [
                        (name: "3-Foot Putts", description: "Short putting practice", category: DrillCategory.putting),
                        (name: "6-Foot Putts", description: "Medium distance putting", category: DrillCategory.putting),
                        (name: "Lag Putting", description: "Long distance putting for lag", category: DrillCategory.putting),
                        (name: "Chip and Run", description: "Basic chipping around the green", category: DrillCategory.chipping),
                        (name: "Flop Shots", description: "High trajectory chips", category: DrillCategory.chipping),
                        (name: "Bunker Practice", description: "Sand shots around the green", category: DrillCategory.chipping),
                        (name: "50-Yard Pitches", description: "Half wedge shots", category: DrillCategory.pitching),
                        (name: "Full Wedge", description: "Full swing wedge shots", category: DrillCategory.pitching),
                        (name: "7-Iron Accuracy", description: "Target practice with 7-iron", category: DrillCategory.irons),
                        (name: "6-Iron Distance", description: "Consistent distance with 6-iron", category: DrillCategory.irons),
                        (name: "5-Iron Control", description: "Ball flight control", category: DrillCategory.irons),
                        (name: "Driver Accuracy", description: "Fairway finding with driver", category: DrillCategory.driver),
                        (name: "Driver Distance", description: "Maximum distance practice", category: DrillCategory.driver)
                    ]
                    
                    let selectedDrills = allDrillTemplates.shuffled().prefix(drillCount)
                    
                    for drillTemplate in selectedDrills {
                        let maxScore = Int.random(in: 3...10) // Varied drill difficulties
                        let actualScore = Int.random(in: 0...maxScore)
                        
                        let drillNotes = [
                            "Good form today",
                            "Need more practice",
                            "Feeling confident",
                            "Struggled with consistency",
                            "Best session yet",
                            "Room for improvement",
                            nil, nil // More sessions without notes
                        ]
                        
                        let drill = Drill(
                            name: drillTemplate.name,
                            drillDescription: drillTemplate.description,
                            category: drillTemplate.category,
                            maxScore: maxScore,
                            actualScore: actualScore,
                            notes: drillNotes.randomElement() ?? nil,
                            completedAt: finalDate
                        )
                        
                        modelContext.insert(drill)
                        testSession.drills.append(drill)
                    }
                }
                
                // Save the context
                do {
                    try modelContext.save()
                    toastManager.showSuccess("Test Data Created", message: "10 practice sessions with sample drills added")
                } catch {
                    print("Failed to save test data: \(error)")
                    toastManager.showError("Creation Failed", message: "Unable to create test data")
                }
                
                isCreatingTestData = false
            }
        }
    }
    
    private func resetDrillsToDefaults() {
        // Reset drill templates to defaults
        let templateService = DrillTemplateService()
        templateService.resetToDefaults()
        toastManager.showSuccess("Drills Reset", message: "All drills restored to defaults")
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PracticeSession.self, Drill.self, configurations: config)
    
    return SettingsView()
        .modelContainer(container)
        .environmentObject(ThemeManager())
        .themed()
} 