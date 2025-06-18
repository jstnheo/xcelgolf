import Foundation

enum ScoringType: String, Codable, CaseIterable {
    case scored = "scored"           // Traditional scoring: X out of Y attempts
    case completion = "completion"   // Binary: completed or not completed
    
    var displayName: String {
        switch self {
        case .scored:
            return "Scored"
        case .completion:
            return "Completion"
        }
    }
}

struct DrillTemplate: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    let description: String
    let category: DrillCategory
    let scoringType: ScoringType
    let defaultMaxScore: Int // Only used for scored type
    let isDefault: Bool // true for server/app defaults, false for user-created
    
    init(id: String = UUID().uuidString, name: String, description: String, category: DrillCategory, scoringType: ScoringType = .scored, defaultMaxScore: Int = 5, isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.scoringType = scoringType
        self.defaultMaxScore = defaultMaxScore
        self.isDefault = isDefault
    }
} 