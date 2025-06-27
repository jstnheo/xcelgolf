import SwiftUI

struct CategoryDrillSelectionView: View {
    let category: DrillCategory
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @State private var drillStates: [String: DrillState] = [:]
    @State private var originalDrillStates: [String: DrillState] = [:]
    @State private var isInitialized = false
    @State private var hasSaved = false
    @State private var selectedLocation: PracticeLocation? // Track selected practice location from CurrentSessionCardView
    @EnvironmentObject private var sessionManager: SessionManager
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var weatherManager: WeatherManager
    @EnvironmentObject private var golfCourseManager: GolfCourseManager
    @StateObject private var drillTemplateService = DrillTemplateService()
    
    private var drillsForCategory: [DrillTemplate] {
        drillTemplateService.getTemplatesForCategory(category)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                if isInitialized {
                    LazyVStack(spacing: 16) {
                        ForEach(drillsForCategory) { drill in
                            DrillSelectionCard(
                                drill: drill,
                                state: drillStateBinding(for: drill)
                            )
                        }
                    }
                    .padding()
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .scrollIndicators(.hidden)
            .background(theme.background)
            .navigationTitle(category.displayName)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        handleDismiss()
                    }
                    .foregroundColor(theme.primary)
                }
            }
        }
        .interactiveDismissDisabled(false)
        .onAppear {
            if !isInitialized {
                loadExistingResults()
                isInitialized = true
            }
        }
        .onDisappear {
            print("DEBUG: onDisappear called, hasSaved: \(hasSaved)")
            if !hasSaved {
                print("DEBUG: onDisappear calling saveDrillsToSession")
                saveDrillsToSession()
                hasSaved = true
            } else {
                print("DEBUG: onDisappear skipping save (already saved)")
            }
            
            // Clear drill states to free memory
            drillStates.removeAll()
            originalDrillStates.removeAll()
        }
    }
    
    private func handleDismiss() {
        if !hasSaved {
            saveDrillsToSession()
            hasSaved = true
        }
        dismiss()
    }
    
    private func drillStateBinding(for drill: DrillTemplate) -> Binding<DrillState> {
        return Binding(
            get: {
                return drillStates[drill.id] ?? DrillState(drill: drill)
            },
            set: { newValue in
                drillStates[drill.id] = newValue
            }
        )
    }
    
    private func loadExistingResults() {
        for drill in drillsForCategory {
            drillStates[drill.id] = DrillState(drill: drill)
            originalDrillStates[drill.id] = DrillState(drill: drill)
        }
        
        let existingResults = sessionManager.getDrillResults(for: category)
        for result in existingResults {
            let state = DrillState(
                drill: result.drillTemplate,
                currentScore: result.score ?? 0,
                isCompleted: result.isCompleted
            )
            drillStates[result.drillTemplate.id] = state
            originalDrillStates[result.drillTemplate.id] = state
        }
    }
    
    private func saveDrillsToSession() {
        print("DEBUG: Starting saveDrillsToSession for category: \(category.displayName)")
        print("DEBUG: hasSaved flag: \(hasSaved)")
        print("DEBUG: Current drill states count: \(drillStates.count)")
        print("DEBUG: Original drill states count: \(originalDrillStates.count)")
        
        // Check if this is a new session (no current session exists)
        let isNewSession = sessionManager.currentSession == nil
        
        var resultsToAdd: [TempDrillResult] = []
        
        for (drillId, currentState) in drillStates {
            let originalState = originalDrillStates[drillId]
            
            let hasChanged = originalState == nil || 
                           (originalState?.currentScore != currentState.currentScore) ||
                           (originalState?.isCompleted != currentState.isCompleted)
            
            print("DEBUG: Drill \(currentState.drill.name) - hasChanged: \(hasChanged)")
            
            if hasChanged {
                if currentState.drill.scoringType == .scored && currentState.currentScore > 0 {
                    print("DEBUG: Adding scored drill result: \(currentState.drill.name), score: \(currentState.currentScore)")
                    let result = TempDrillResult(
                        drillTemplate: currentState.drill,
                        score: currentState.currentScore,
                        isCompleted: false,
                        completedAt: Date()
                    )
                    resultsToAdd.append(result)
                } else if currentState.drill.scoringType == .completion && currentState.isCompleted {
                    print("DEBUG: Adding completion drill result: \(currentState.drill.name)")
                    let result = TempDrillResult(
                        drillTemplate: currentState.drill,
                        score: nil,
                        isCompleted: true,
                        completedAt: Date()
                    )
                    resultsToAdd.append(result)
                }
            }
        }
        
        // If we have results to add and this is a new session, capture environment data first
        if !resultsToAdd.isEmpty && isNewSession {
            print("🌤️ DEBUG: New session detected, capturing environment data before adding drills")
            sessionManager.startSessionWithEnvironmentData(
                weatherManager: weatherManager,
                locationManager: locationManager,
                golfCourseManager: golfCourseManager,
                selectedLocation: selectedLocation
            )
        }
        
        // Batch add all results at once
        if !resultsToAdd.isEmpty {
            sessionManager.batchAddDrillResults(resultsToAdd)
        }
        
        print("DEBUG: Finished saveDrillsToSession, added \(resultsToAdd.count) results")
    }
    
    private var completedDrills: [DrillState] {
        drillStates.values.filter { state in
            switch state.drill.scoringType {
            case .scored:
                return state.currentScore > 0
            case .completion:
                return state.isCompleted
            }
        }
    }
}

// MARK: - Supporting Views and Models

struct DrillState {
    let drill: DrillTemplate
    var currentScore: Int = 0
    var isCompleted: Bool = false
    
    init(drill: DrillTemplate, currentScore: Int = 0, isCompleted: Bool = false) {
        self.drill = drill
        self.currentScore = currentScore
        self.isCompleted = isCompleted
    }
}

struct DrillSelectionCard: View {
    let drill: DrillTemplate
    @Binding var state: DrillState
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Drill header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(drill.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.textPrimary)
                    
                    Text(drill.description)
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Scoring type indicator
                scoringTypeBadge
            }
            
            // Scoring interface
            scoringInterface
        }
        .padding()
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 1)
        )
        .onTapGesture {
            // Only handle tap for completion drills
            if drill.scoringType == .completion {
                // Haptic feedback when completion card is tapped
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                state.isCompleted.toggle()
            }
        }
    }
    
    @ViewBuilder
    private var scoringTypeBadge: some View {
        let isScored = drill.scoringType == .scored
        Text(drill.scoringType.displayName)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isScored ? theme.primary.opacity(0.2) : theme.success.opacity(0.2))
            .foregroundColor(isScored ? theme.primary : theme.success)
            .cornerRadius(6)
    }
    
    @ViewBuilder
    private var scoringInterface: some View {
        switch drill.scoringType {
        case .scored:
            scoredDrillInterface
        case .completion:
            completionDrillInterface
        }
    }
    
    @ViewBuilder
    private var scoredDrillInterface: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Score: \(state.currentScore) / \(drill.defaultMaxScore)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                if state.currentScore > 0 {
                    Text(percentageText)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(theme.primary)
                }
            }
            
            CustomSlider(
                value: scoreBinding,
                in: 0...CGFloat(drill.defaultMaxScore),
                config: .init(
                    inActiveTint: theme.divider,
                    activeTint: theme.primary,
                    cornerRadius: 12,
                    extraHeight: 15,
                    overlayActiveTint: theme.cardBackground,
                    overlayInActiveTint: theme.textSecondary
                )
            ) {
                HStack {
                    Image(systemName: "target")
                        .font(.system(size: 14, weight: .medium))
                    
                    Spacer()
                    
                    Text("\(state.currentScore)/\(drill.defaultMaxScore)")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 12)
            }
            .onChange(of: state.currentScore) { _, newValue in
                // Haptic feedback when slider value changes
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
        }
    }
    
    @ViewBuilder
    private var completionDrillInterface: some View {
        HStack(spacing: 12) {
            Image(systemName: state.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundColor(state.isCompleted ? theme.success : theme.textSecondary)
            
            Text(state.isCompleted ? "Completed" : "Mark as Complete")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(state.isCompleted ? theme.success : theme.textPrimary)
            
            Spacer()
        }
    }
    
    private var scoreBinding: Binding<CGFloat> {
        Binding(
            get: { CGFloat(state.currentScore) },
            set: { state.currentScore = Int($0) }
        )
    }
    
    private var percentageText: String {
        let percentage = Int((Double(state.currentScore) / Double(drill.defaultMaxScore)) * 100)
        return "\(percentage)%"
    }
    
    private var borderColor: Color {
        switch drill.scoringType {
        case .scored:
            return state.currentScore > 0 ? theme.primary.opacity(0.3) : theme.divider
        case .completion:
            return state.isCompleted ? theme.success.opacity(0.3) : theme.divider
        }
    }
}

struct StatBadge: View {
    let title: String
    let value: String
    let color: Color
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(theme.textSecondary)
        }
    }
} 