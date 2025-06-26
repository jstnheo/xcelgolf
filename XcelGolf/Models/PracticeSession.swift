import Foundation
import SwiftData

@Model
class PracticeSession {
    var date: Date
    var notes: String?
    @Relationship(deleteRule: .cascade) var drills: [Drill] = []
    
    init(date: Date = .now, notes: String? = nil) {
        self.date = date
        self.notes = notes
    }
    
    // MARK: - Computed Properties
    var totalDrills: Int {
        drills.count
    }
    
    var averageSuccessPercentage: Int {
        guard !drills.isEmpty else { return 0 }
        let totalPercentage = drills.reduce(0) { $0 + $1.successPercentage }
        return totalPercentage / drills.count
    }
}

extension PracticeSession: Identifiable {} 