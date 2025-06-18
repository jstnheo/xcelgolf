import SwiftUI
import SwiftData

struct NewExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.theme) private var theme
    
    let session: PracticeSession
    @State private var selectedCategory: DrillCategory?
    @State private var selectedTemplate: DrillTemplate?
    @State private var notes = ""
    @State private var maxScore = 5
    @State private var actualScore = 0
    @State private var isCompleted = false
    @StateObject private var templateService = DrillTemplateService()
    
    var templatesForCategory: [DrillTemplate] {
        guard let category = selectedCategory else { return [] }
        return templateService.getTemplatesForCategory(category)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Select Drill Category") {
                    Picker("Category", selection: $selectedCategory) {
                        Text("Choose a category").tag(DrillCategory?.none)
                        ForEach(DrillCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category as DrillCategory?)
                        }
                    }
                    .foregroundColor(theme.textPrimary)
                    .onChange(of: selectedCategory) { _, _ in
                        selectedTemplate = nil // Reset drill selection when category changes
                    }
                }
                
                if !templatesForCategory.isEmpty {
                    Section("Select Drill") {
                        Picker("Drill", selection: $selectedTemplate) {
                            Text("Choose a drill").tag(DrillTemplate?.none)
                            ForEach(templatesForCategory) { template in
                                VStack(alignment: .leading) {
                                    Text(template.name)
                                        .font(.headline)
                                        .foregroundColor(theme.textPrimary)
                                    Text(template.description)
                                        .font(.caption)
                                        .foregroundColor(theme.textSecondary)
                                    HStack {
                                        Text(template.scoringType.displayName)
                                            .font(.caption2)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(template.scoringType == .scored ? theme.primary.opacity(0.2) : theme.success.opacity(0.2))
                                            .foregroundColor(template.scoringType == .scored ? theme.primary : theme.success)
                                            .cornerRadius(4)
                                        Spacer()
                                    }
                                }
                                .tag(template as DrillTemplate?)
                            }
                        }
                        .onChange(of: selectedTemplate) { _, newTemplate in
                            if let template = newTemplate {
                                maxScore = template.defaultMaxScore
                                actualScore = 0 // Reset score
                                isCompleted = false // Reset completion
                            }
                        }
                    }
                }
                
                if let template = selectedTemplate {
                    Section("Record Your Performance") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(template.name)
                                .font(.headline)
                                .foregroundColor(theme.textPrimary)
                            Text(template.description)
                                .font(.subheadline)
                                .foregroundColor(theme.textSecondary)
                            
                            HStack {
                                Text("Type:")
                                    .foregroundColor(theme.textPrimary)
                                Spacer()
                                Text(template.scoringType.displayName)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(template.scoringType == .scored ? theme.primary.opacity(0.2) : theme.success.opacity(0.2))
                                    .foregroundColor(template.scoringType == .scored ? theme.primary : theme.success)
                                    .cornerRadius(4)
                                    .font(.caption)
                            }
                        }
                        
                        if template.scoringType == .scored {
                            // Scored drill UI
                            HStack {
                                Text("Attempts:")
                                    .foregroundColor(theme.textPrimary)
                                Spacer()
                                Stepper("\(maxScore)", value: $maxScore, in: 1...20)
                                    .foregroundColor(theme.primary)
                            }
                            
                            HStack {
                                Text("Successful:")
                                    .foregroundColor(theme.textPrimary)
                                Spacer()
                                Stepper("\(actualScore)", value: $actualScore, in: 0...maxScore)
                                    .foregroundColor(theme.primary)
                            }
                            
                            if maxScore > 0 {
                                let percentage = Int((Double(actualScore) / Double(maxScore)) * 100)
                                HStack {
                                    Text("Success Rate:")
                                        .foregroundColor(theme.textPrimary)
                                    Spacer()
                                    Text("\(percentage)%")
                                        .foregroundColor(theme.success)
                                        .fontWeight(.semibold)
                                }
                            }
                        } else {
                            // Completion drill UI
                            HStack {
                                Text("Completed:")
                                    .foregroundColor(theme.textPrimary)
                                Spacer()
                                Toggle("", isOn: $isCompleted)
                                    .labelsHidden()
                                    .toggleStyle(SwitchToggleStyle(tint: theme.primary))
                            }
                            
                            HStack {
                                Text("Status:")
                                    .foregroundColor(theme.textPrimary)
                                Spacer()
                                Text(isCompleted ? "Completed" : "Not Completed")
                                    .foregroundColor(isCompleted ? theme.success : theme.warning)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        TextField("Notes (optional)", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                            .foregroundColor(theme.textPrimary)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.background)
            .navigationTitle("Add Drill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveDrill()
                    }
                    .disabled(selectedTemplate == nil)
                    .foregroundColor(selectedTemplate == nil ? theme.textSecondary : theme.primary)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func saveDrill() {
        guard let template = selectedTemplate else { return }
        
        let drill: Drill
        
        if template.scoringType == .scored {
            // Create a scored drill
            drill = Drill(
                name: template.name,
                drillDescription: template.description,
                category: template.category,
                maxScore: maxScore,
                actualScore: actualScore,
                notes: notes.isEmpty ? nil : notes,
                completedAt: .now
            )
        } else {
            // Create a completion drill
            drill = Drill(
                name: template.name,
                drillDescription: template.description,
                category: template.category,
                isCompleted: isCompleted,
                notes: notes.isEmpty ? nil : notes,
                completedAt: .now
            )
        }
        
        // Add to session
        session.drills.append(drill)
        
        // Insert into context
        modelContext.insert(drill)
        
        // Explicitly save the context to ensure persistence
        do {
            try modelContext.save()
        } catch {
            print("Failed to save drill: \(error)")
        }
        
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PracticeSession.self, Drill.self, configurations: config)
    let context = container.mainContext
    
    let session = PracticeSession()
    context.insert(session)
    
    return NewExerciseView(session: session)
        .modelContainer(container)
        .environmentObject(ThemeManager())
        .themed()
} 