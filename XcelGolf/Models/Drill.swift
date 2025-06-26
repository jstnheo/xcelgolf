import Foundation
import SwiftData

@Model
final class Drill {
    var name: String
    var drillDescription: String
    var category: DrillCategory
    var scoringType: ScoringType
    var maxScore: Int? // How many attempts (for scored drills only)
    var actualScore: Int? // How many successful (for scored drills only)
    var isCompleted: Bool? // For completion drills only
    var notes: String?
    var completedAt: Date
    @Relationship(inverse: \PracticeSession.drills) var session: PracticeSession?
    
    var successRate: Double {
        switch scoringType {
        case .scored:
            guard let maxScore = maxScore, let actualScore = actualScore, maxScore > 0 else { return 0 }
            return min(max(Double(actualScore) / Double(maxScore), 0), 1)
        case .completion:
            return isCompleted == true ? 1.0 : 0.0
        }
    }
    
    var successPercentage: Int {
        return Int(successRate * 100)
    }
    
    var displayScore: String {
        switch scoringType {
        case .scored:
            if let actualScore = actualScore, let maxScore = maxScore {
                return "\(actualScore)/\(maxScore)"
            }
            return "0/0"
        case .completion:
            return isCompleted == true ? "Completed" : "Not Completed"
        }
    }
    
    // Convenience initializer for scored drills
    init(name: String, drillDescription: String, category: DrillCategory, maxScore: Int, actualScore: Int, notes: String? = nil, completedAt: Date = .now) {
        self.name = name
        self.drillDescription = drillDescription
        self.category = category
        self.scoringType = .scored
        self.maxScore = maxScore
        self.actualScore = actualScore
        self.isCompleted = nil
        self.notes = notes
        self.completedAt = completedAt
    }
    
    // Convenience initializer for completion drills
    init(name: String, drillDescription: String, category: DrillCategory, isCompleted: Bool, notes: String? = nil, completedAt: Date = .now) {
        self.name = name
        self.drillDescription = drillDescription
        self.category = category
        self.scoringType = .completion
        self.maxScore = nil
        self.actualScore = nil
        self.isCompleted = isCompleted
        self.notes = notes
        self.completedAt = completedAt
    }
    
    // General initializer (for migration/flexibility)
    init(name: String, drillDescription: String, category: DrillCategory, scoringType: ScoringType, maxScore: Int? = nil, actualScore: Int? = nil, isCompleted: Bool? = nil, notes: String? = nil, completedAt: Date = .now) {
        self.name = name
        self.drillDescription = drillDescription
        self.category = category
        self.scoringType = scoringType
        self.maxScore = maxScore
        self.actualScore = actualScore
        self.isCompleted = isCompleted
        self.notes = notes
        self.completedAt = completedAt
    }
}

extension Drill: Identifiable {} 