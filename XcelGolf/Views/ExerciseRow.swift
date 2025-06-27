import SwiftUI

struct DrillRow: View {
    let drill: Drill
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(drill.name)
                    .font(.headline)
                    .foregroundColor(theme.textPrimary)
                Spacer()
                Text(drill.scoringType.displayName)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(drill.scoringType == .scored ? theme.primary.opacity(0.2) : theme.success.opacity(0.2))
                    .foregroundColor(drill.scoringType == .scored ? theme.primary : theme.success)
                    .cornerRadius(4)
            }
            
            HStack {
                Text("Score: \(drill.displayScore)")
                    .foregroundColor(theme.textPrimary)
                Spacer()
                Text("\(drill.successPercentage)%")
                    .foregroundColor(drill.successPercentage == 100 ? theme.success : (drill.successPercentage >= 50 ? theme.warning : theme.error))
                    .fontWeight(.medium)
            }
            
            if let notes = drill.notes {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }
        }
    }
}

// MARK: - Editable Drill Row

struct EditableDrillRow: View {
    @Bindable var drill: Drill
    @Environment(\.theme) private var theme
    @State private var showingEditSheet = false
    
    var body: some View {
        Button(action: {
            showingEditSheet = true
        }) {
            VStack(alignment: .leading) {
                HStack {
                    Text(drill.name)
                        .font(.headline)
                        .foregroundColor(theme.textPrimary)
                    Spacer()
                    Text(drill.scoringType.displayName)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(drill.scoringType == .scored ? theme.primary.opacity(0.2) : theme.success.opacity(0.2))
                        .foregroundColor(drill.scoringType == .scored ? theme.primary : theme.success)
                        .cornerRadius(4)
                }
                
                HStack {
                    Text("Score: \(drill.displayScore)")
                        .foregroundColor(theme.textPrimary)
                    Spacer()
                    Text("\(drill.successPercentage)%")
                        .foregroundColor(drill.successPercentage == 100 ? theme.success : (drill.successPercentage >= 50 ? theme.warning : theme.error))
                        .fontWeight(.medium)
                }
                
                if let notes = drill.notes {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
                
                // Edit indicator
                HStack {
                    Spacer()
                    Text("Tap to edit")
                        .font(.caption2)
                        .foregroundColor(theme.textSecondary.opacity(0.7))
                        .italic()
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingEditSheet) {
            DrillEditSheet(drill: drill)
        }
    }
}

// MARK: - Drill Edit Sheet

struct DrillEditSheet: View {
    @Bindable var drill: Drill
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @State private var tempMaxScore: Int
    @State private var tempActualScore: Int
    @State private var tempIsCompleted: Bool
    @State private var tempNotes: String
    @State private var maxScoreText: String
    @State private var actualScoreText: String
    
    init(drill: Drill) {
        self.drill = drill
        let maxScore = drill.maxScore ?? 0
        let actualScore = drill.actualScore ?? 0
        self._tempMaxScore = State(initialValue: maxScore)
        self._tempActualScore = State(initialValue: actualScore)
        self._tempIsCompleted = State(initialValue: drill.isCompleted ?? false)
        self._tempNotes = State(initialValue: drill.notes ?? "")
        self._maxScoreText = State(initialValue: "\(maxScore)")
        self._actualScoreText = State(initialValue: "\(actualScore)")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Drill Details") {
                    Text(drill.name)
                        .font(.headline)
                        .foregroundColor(theme.textPrimary)
                    
                    Text(drill.drillDescription)
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                }
                
                if drill.scoringType == .scored {
                    Section("Score") {
                        HStack {
                            Text("Max Score:")
                                .foregroundColor(theme.textPrimary)
                            Spacer()
                            TextField("Max", text: $maxScoreText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 80)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .onChange(of: maxScoreText) { _, newValue in
                                    validateMaxScore(newValue)
                                }
                        }
                        
                        HStack {
                            Text("Actual Score:")
                                .foregroundColor(theme.textPrimary)
                            Spacer()
                            TextField("Actual", text: $actualScoreText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 80)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .onChange(of: actualScoreText) { _, newValue in
                                    validateActualScore(newValue)
                                }
                        }
                        
                        HStack {
                            Text("Success Rate:")
                                .foregroundColor(theme.textPrimary)
                            Spacer()
                            let successRate = tempMaxScore > 0 ? Int(Double(tempActualScore) / Double(tempMaxScore) * 100) : 0
                            Text("\(successRate)%")
                                .foregroundColor(successRate == 100 ? theme.success : (successRate >= 50 ? theme.warning : theme.error))
                                .fontWeight(.medium)
                        }
                    }
                } else {
                    Section("Completion") {
                        Toggle("Completed", isOn: $tempIsCompleted)
                            .tint(theme.primary)
                    }
                }
                
                Section("Notes") {
                    TextField("Add notes about this drill...", text: $tempNotes, axis: .vertical)
                        .lineLimit(3...6)
                        .foregroundColor(theme.textPrimary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.background)
            .navigationTitle("Edit Drill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(theme.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveDrill()
                    }
                    .foregroundColor(theme.primary)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Validation Methods
    
    private func validateMaxScore(_ input: String) {
        // Remove any non-numeric characters
        let numericOnly = input.filter { $0.isNumber }
        
        // Convert to integer, default to 0 if invalid
        let value = Int(numericOnly) ?? 0
        
        // Update state
        tempMaxScore = value
        maxScoreText = "\(value)"
        
        // Re-validate actual score to ensure it doesn't exceed new max
        if tempActualScore > tempMaxScore {
            tempActualScore = tempMaxScore
            actualScoreText = "\(tempMaxScore)"
        }
    }
    
    private func validateActualScore(_ input: String) {
        // Remove any non-numeric characters
        let numericOnly = input.filter { $0.isNumber }
        
        // Convert to integer, default to 0 if invalid
        let value = Int(numericOnly) ?? 0
        
        // Cap at max score
        let cappedValue = min(value, tempMaxScore)
        
        // Update state
        tempActualScore = cappedValue
        actualScoreText = "\(cappedValue)"
    }
    
    private func saveDrill() {
        // Update drill with new values
        if drill.scoringType == .scored {
            drill.maxScore = tempMaxScore
            drill.actualScore = tempActualScore
        } else {
            drill.isCompleted = tempIsCompleted
        }
        
        drill.notes = tempNotes.isEmpty ? nil : tempNotes
        
        // Save to context
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save drill changes: \(error)")
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        DrillRow(drill: Drill(
            name: "3-Foot Straight Putts",
            drillDescription: "Make putts from 3 feet on a straight line",
            category: .putting,
            maxScore: 5,
            actualScore: 4,
            notes: "Good session"
        ))
        
        EditableDrillRow(drill: Drill(
            name: "Power Drive Session",
            drillDescription: "Focus on maximum distance and power with driver",
            category: .driver,
            isCompleted: true,
            notes: "Felt strong today"
        ))
    }
    .padding()
    .environmentObject(ThemeManager())
    .themed()
} 
