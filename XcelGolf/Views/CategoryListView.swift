import SwiftUI
import SwiftData

struct CategoryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.theme) private var theme
    @StateObject private var templateService = DrillTemplateService()
    
    var body: some View {
        List {
            ForEach(DrillCategory.allCases, id: \.self) { category in
                NavigationLink {
                    CategoryDetailView(category: category)
                } label: {
                    VStack(alignment: .leading) {
                        Text(category.displayName)
                            .font(.headline)
                            .foregroundColor(theme.textPrimary)
                        Text("\(templateService.getTemplatesForCategory(category).count) drills")
                            .font(.subheadline)
                            .foregroundColor(theme.textSecondary)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(theme.background)
        .navigationTitle("Drill Categories")
    }
}

struct CategoryDetailView: View {
    let category: DrillCategory
    @Environment(\.theme) private var theme
    @State private var showingAddTemplate = false
    @StateObject private var templateService = DrillTemplateService()
    
    var templatesForCategory: [DrillTemplate] {
        templateService.getTemplatesForCategory(category)
    }
    
    var body: some View {
        List {
            ForEach(templatesForCategory) { template in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(template.name)
                            .font(.headline)
                            .foregroundColor(theme.textPrimary)
                        Spacer()
                        if template.isDefault {
                            Text("Default")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(theme.primary.opacity(0.2))
                                .foregroundColor(theme.primary)
                                .clipShape(Capsule())
                        } else {
                            Text("Custom")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(theme.success.opacity(0.2))
                                .foregroundColor(theme.success)
                                .clipShape(Capsule())
                        }
                    }
                    Text(template.description)
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                    Text("Default attempts: \(template.defaultMaxScore)")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
                .padding(.vertical, 2)
            }
            .onDelete(perform: deleteTemplate)
        }
        .scrollContentBackground(.hidden)
        .background(theme.background)
        .navigationTitle(category.displayName)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddTemplate = true }) {
                    Label("Add Custom Drill", systemImage: "plus")
                }
                .foregroundColor(theme.primary)
            }
        }
        .sheet(isPresented: $showingAddTemplate) {
            AddCustomDrillView(category: category)
        }
    }
    
    private func deleteTemplate(offsets: IndexSet) {
        for index in offsets {
            let template = templatesForCategory[index]
            templateService.removeTemplate(template)
        }
    }
}

struct AddCustomDrillView: View {
    let category: DrillCategory
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @StateObject private var templateService = DrillTemplateService()
    
    @State private var name = ""
    @State private var description = ""
    @State private var defaultMaxScore = 5
    
    var body: some View {
        NavigationView {
            Form {
                Section("Drill Details") {
                    TextField("Drill Name", text: $name)
                        .foregroundColor(theme.textPrimary)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                        .foregroundColor(theme.textPrimary)
                    Stepper("Default Attempts: \(defaultMaxScore)", value: $defaultMaxScore, in: 1...20)
                        .foregroundColor(theme.textPrimary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.background)
            .navigationTitle("New Custom Drill")
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
                        saveTemplate()
                    }
                    .disabled(name.isEmpty || description.isEmpty)
                    .foregroundColor(name.isEmpty || description.isEmpty ? theme.textSecondary : theme.primary)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func saveTemplate() {
        let template = DrillTemplate(
            name: name,
            description: description,
            category: category,
            defaultMaxScore: defaultMaxScore,
            isDefault: false
        )
        templateService.addCustomTemplate(template)
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PracticeSession.self, Drill.self, configurations: config)
    
    return CategoryListView()
        .modelContainer(container)
        .environmentObject(ThemeManager())
        .themed()
} 
