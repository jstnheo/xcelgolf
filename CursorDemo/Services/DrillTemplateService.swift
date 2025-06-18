import Foundation

/// Service for managing drill templates (both default and user-created)
class DrillTemplateService: ObservableObject {
    @Published var templates: [DrillTemplate] = []
    
    private let userTemplatesKey = "user_drill_templates"
    private let defaultTemplatesFileName = "default_drill_templates"
    private let deletedDefaultTemplatesKey = "deleted_default_templates"
    private let modifiedDefaultTemplatesKey = "modified_default_templates"
    
    init() {
        loadTemplates()
    }
    
    // MARK: - Public Methods
    
    func getTemplatesForCategory(_ category: DrillCategory) -> [DrillTemplate] {
        return templates.filter { $0.category == category }
    }
    
    func getAllTemplates() -> [DrillTemplate] {
        return templates
    }
    
    func addCustomTemplate(_ template: DrillTemplate) {
        var customTemplate = template
        customTemplate = DrillTemplate(
            id: template.id,
            name: template.name,
            description: template.description,
            category: template.category,
            scoringType: template.scoringType,
            defaultMaxScore: template.defaultMaxScore,
            isDefault: false
        )
        templates.append(customTemplate)
        saveUserTemplates()
    }
    
    func removeTemplate(_ template: DrillTemplate) {
        // Allow removal of any template (both default and custom)
        templates.removeAll { $0.id == template.id }
        
        if template.isDefault {
            // For default templates, we need to track which ones were deleted
            // so they don't reappear when the app restarts
            saveDeletedDefaultTemplates(template.id)
        }
        
        saveUserTemplates()
    }
    
    func updateTemplate(_ template: DrillTemplate) {
        // Allow updating any template (both default and custom)
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index] = template
            
            if template.isDefault {
                // For default templates that are modified, we need to track the changes
                // so they persist across app restarts
                saveModifiedDefaultTemplate(template)
            }
        }
        saveUserTemplates()
    }
    
    // MARK: - Reset Functionality
    
    func resetToDefaults() {
        // Clear all user customizations
        UserDefaults.standard.removeObject(forKey: userTemplatesKey)
        UserDefaults.standard.removeObject(forKey: deletedDefaultTemplatesKey)
        UserDefaults.standard.removeObject(forKey: modifiedDefaultTemplatesKey)
        
        // Reload templates from scratch
        loadTemplates()
    }
    
    // MARK: - Private Methods
    
    private func loadTemplates() {
        // Load default templates from bundle
        var defaultTemplates = loadDefaultTemplates()
        
        // Filter out deleted default templates
        let deletedDefaultIds = loadDeletedDefaultTemplateIds()
        defaultTemplates = defaultTemplates.filter { !deletedDefaultIds.contains($0.id) }
        
        // Apply modifications to default templates
        let modifiedDefaults = loadModifiedDefaultTemplates()
        for modifiedTemplate in modifiedDefaults {
            if let index = defaultTemplates.firstIndex(where: { $0.id == modifiedTemplate.id }) {
                defaultTemplates[index] = modifiedTemplate
            }
        }
        
        // Load user custom templates from UserDefaults
        let userTemplates = loadUserTemplates()
        
        // Combine them
        templates = defaultTemplates + userTemplates
    }
    
    private func loadDefaultTemplates() -> [DrillTemplate] {
        guard let url = Bundle.main.url(forResource: defaultTemplatesFileName, withExtension: "json") else {
            fatalError("Could not find \(defaultTemplatesFileName).json in app bundle")
        }
        
        guard let data = try? Data(contentsOf: url) else {
            fatalError("Could not load data from \(defaultTemplatesFileName).json")
        }
        
        do {
            let templates = try JSONDecoder().decode([DrillTemplate].self, from: data)
            return templates
        } catch {
            fatalError("Could not decode \(defaultTemplatesFileName).json: \(error)")
        }
    }
    
    private func loadUserTemplates() -> [DrillTemplate] {
        guard let data = UserDefaults.standard.data(forKey: userTemplatesKey),
              let templates = try? JSONDecoder().decode([DrillTemplate].self, from: data) else {
            return []
        }
        return templates
    }
    
    private func saveUserTemplates() {
        let userTemplates = templates.filter { !$0.isDefault }
        if let data = try? JSONEncoder().encode(userTemplates) {
            UserDefaults.standard.set(data, forKey: userTemplatesKey)
        }
    }
    
    private func saveDeletedDefaultTemplates(_ templateId: String) {
        var deletedIds = loadDeletedDefaultTemplateIds()
        deletedIds.insert(templateId)
        if let data = try? JSONEncoder().encode(Array(deletedIds)) {
            UserDefaults.standard.set(data, forKey: deletedDefaultTemplatesKey)
        }
    }
    
    private func loadDeletedDefaultTemplateIds() -> Set<String> {
        guard let data = UserDefaults.standard.data(forKey: deletedDefaultTemplatesKey),
              let ids = try? JSONDecoder().decode([String].self, from: data) else {
            return Set<String>()
        }
        return Set(ids)
    }
    
    private func saveModifiedDefaultTemplate(_ template: DrillTemplate) {
        var modifiedTemplates = loadModifiedDefaultTemplates()
        // Remove existing entry if it exists
        modifiedTemplates.removeAll { $0.id == template.id }
        // Add the updated template
        modifiedTemplates.append(template)
        
        if let data = try? JSONEncoder().encode(modifiedTemplates) {
            UserDefaults.standard.set(data, forKey: modifiedDefaultTemplatesKey)
        }
    }
    
    private func loadModifiedDefaultTemplates() -> [DrillTemplate] {
        guard let data = UserDefaults.standard.data(forKey: modifiedDefaultTemplatesKey),
              let templates = try? JSONDecoder().decode([DrillTemplate].self, from: data) else {
            return []
        }
        return templates
    }
    
    // MARK: - Server Updates (Future)
    
    func fetchUpdatedTemplatesFromServer() async {
        // TODO: Implement server fetching
        // This would fetch the latest default templates from your server
        // and update the local JSON file
    }
} 