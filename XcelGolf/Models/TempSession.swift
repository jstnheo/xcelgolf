import Foundation

/// Temporary session model used before saving to SwiftData
struct TempSession: Codable {
    let id: String
    let startDate: Date
    var drillResults: [TempDrillResult]
    
    init() {
        self.id = UUID().uuidString
        self.startDate = Date()
        self.drillResults = []
    }
}

/// Temporary drill result model used during session
struct TempDrillResult: Codable {
    let drillTemplate: DrillTemplate
    let score: Int?
    let isCompleted: Bool
    let completedAt: Date
} 