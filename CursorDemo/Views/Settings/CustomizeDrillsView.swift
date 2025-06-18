import SwiftUI
import SwiftData

struct CustomizeDrillsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @StateObject private var templateService = DrillTemplateService()
    @State private var showingAddDrill = false
    @State private var selectedCategory: DrillCategory?
    @State private var editingTemplate: DrillTemplate?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(DrillCategory.allCases, id: \.self) { category in
                    Section {
                        let templatesForCategory = templateService.getTemplatesForCategory(category)
                        
                        if templatesForCategory.isEmpty {
                            HStack {
                                Text("No drills in this category")
                                    .foregroundColor(theme.textSecondary)
                                    .font(.subheadline)
                                Spacer()
                                Button("Add First Drill") {
                                    selectedCategory = category
                                    showingAddDrill = true
                                }
                                .font(.caption)
                                .foregroundColor(theme.primary)
                            }
                            .padding(.vertical, 4)
                        } else {
                            ForEach(templatesForCategory) { template in
                                DrillTemplateRow(
                                    template: template,
                                    onEdit: {
                                        editingTemplate = template
                                    }
                                )
                            }
                        }
                        
                        // Add drill button for each category
                        Button(action: {
                            selectedCategory = category
                            showingAddDrill = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(theme.success)
                                Text("Add \(category.displayName) Drill")
                                    .foregroundColor(theme.success)
                                Spacer()
                            }
                        }
                        .padding(.vertical, 2)
                        
                    } header: {
                        HStack {
                            Image(systemName: categoryIcon(for: category))
                                .foregroundColor(categoryColor(for: category))
                            Text(category.displayName)
                                .foregroundColor(theme.textPrimary)
                            Spacer()
                            Text("\(templateService.getTemplatesForCategory(category).count)")
                                .foregroundColor(theme.textSecondary)
                                .font(.caption)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.background)
            .navigationTitle("Customize Drills")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(theme.primary)
                }
            }
        }
        .sheet(isPresented: $showingAddDrill) {
            if let category = selectedCategory {
                AddEditDrillView(category: category, editingTemplate: nil)
                    .environmentObject(templateService)
            }
        }
        .sheet(item: $editingTemplate) { template in
            AddEditDrillView(category: template.category, editingTemplate: template)
                .environmentObject(templateService)
        }
    }
    
    private func categoryIcon(for category: DrillCategory) -> String {
        switch category {
        case .putting: return "target"
        case .chipping: return "figure.golf"
        case .pitching: return "sportscourt"
        case .irons: return "multiply.circle"
        case .driver: return "arrow.up.right"
        }
    }
    
    private func categoryColor(for category: DrillCategory) -> Color {
        switch category {
        case .putting: return theme.success
        case .chipping: return theme.warning
        case .pitching: return theme.primary
        case .driver: return theme.error
        case .irons: return theme.accent
        }
    }
}

struct DrillTemplateRow: View {
    let template: DrillTemplate
    let onEdit: () -> Void
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: onEdit) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.name)
                            .font(.headline)
                            .foregroundColor(theme.textPrimary)
                        
                        Text(template.description)
                            .font(.subheadline)
                            .foregroundColor(theme.textSecondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            if template.isDefault {
                                Text("Default")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(theme.primary.opacity(0.2))
                                    .foregroundColor(theme.primary)
                                    .clipShape(Capsule())
                            } else {
                                Text("Custom")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(theme.success.opacity(0.2))
                                    .foregroundColor(theme.success)
                                    .clipShape(Capsule())
                            }
                            
                            Text(template.scoringType.displayName)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(template.scoringType == .scored ? theme.warning.opacity(0.2) : theme.accent.opacity(0.2))
                                .foregroundColor(template.scoringType == .scored ? theme.warning : theme.accent)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AddEditDrillView: View {
    let category: DrillCategory
    let editingTemplate: DrillTemplate?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @EnvironmentObject var templateService: DrillTemplateService
    
    @State private var name = ""
    @State private var description = ""
    @State private var defaultMaxScore = 5
    @State private var scoringType: ScoringType = .scored
    @State private var showingDeleteConfirmation = false
    
    private var isEditing: Bool {
        editingTemplate != nil
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Form {
                    Section("Drill Details") {
                        TextField("Drill Name", text: $name)
                            .foregroundColor(theme.textPrimary)
                        
                        TextField("Description", text: $description, axis: .vertical)
                            .lineLimit(3...6)
                            .foregroundColor(theme.textPrimary)
                    }
                    
                    Section("Scoring") {
                        Picker("Scoring Type", selection: $scoringType) {
                            ForEach(ScoringType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .foregroundColor(theme.textPrimary)
                        
                        if scoringType == .scored {
                            Stepper("Default Attempts: \(defaultMaxScore)", value: $defaultMaxScore, in: 1...50)
                                .foregroundColor(theme.textPrimary)
                        }
                    }
                    
                    Section("Category") {
                        HStack {
                            Image(systemName: categoryIcon(for: category))
                                .foregroundColor(categoryColor(for: category))
                            Text(category.displayName)
                                .foregroundColor(theme.textPrimary)
                            Spacer()
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(theme.background)
                
                // Delete button at the bottom (only show when editing)
                if isEditing {
                    VStack(spacing: 0) {
                        Divider()
                        
                        Button(action: {
                            showingDeleteConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Delete Drill")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(theme.error)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 16)
                        .background(theme.background)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Drill" : "New Drill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Update" : "Save") {
                        saveDrill()
                    }
                    .disabled(name.isEmpty || description.isEmpty)
                    .foregroundColor(name.isEmpty || description.isEmpty ? theme.textSecondary : theme.primary)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            if let template = editingTemplate {
                name = template.name
                description = template.description
                defaultMaxScore = template.defaultMaxScore
                scoringType = template.scoringType
            }
        }
        .confirmationDialog("Delete Drill", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let template = editingTemplate {
                    templateService.removeTemplate(template)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            if let template = editingTemplate {
                Text("Are you sure you want to delete '\(template.name)'? This action cannot be undone.")
            }
        }
    }
    
    private func saveDrill() {
        if let existingTemplate = editingTemplate {
            // Update existing template
            let updatedTemplate = DrillTemplate(
                id: existingTemplate.id,
                name: name,
                description: description,
                category: category,
                scoringType: scoringType,
                defaultMaxScore: scoringType == .scored ? defaultMaxScore : 1,
                isDefault: existingTemplate.isDefault
            )
            templateService.updateTemplate(updatedTemplate)
        } else {
            // Create new template
            let newTemplate = DrillTemplate(
                name: name,
                description: description,
                category: category,
                scoringType: scoringType,
                defaultMaxScore: scoringType == .scored ? defaultMaxScore : 1,
                isDefault: false
            )
            templateService.addCustomTemplate(newTemplate)
        }
        dismiss()
    }
    
    private func categoryIcon(for category: DrillCategory) -> String {
        switch category {
        case .putting: return "target"
        case .chipping: return "figure.golf"
        case .pitching: return "sportscourt"
        case .irons: return "multiply.circle"
        case .driver: return "arrow.up.right"
        }
    }
    
    private func categoryColor(for category: DrillCategory) -> Color {
        switch category {
        case .putting: return theme.success
        case .chipping: return theme.warning
        case .pitching: return theme.primary
        case .driver: return theme.error
        case .irons: return theme.accent
        }
    }
}

#Preview {
    CustomizeDrillsView()
        .environmentObject(ThemeManager())
        .themed()
} 
