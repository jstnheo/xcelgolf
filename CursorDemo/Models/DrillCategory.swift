import Foundation

enum DrillCategory: String, CaseIterable, Codable {
    case putting = "Putting"
    case chipping = "Chipping"
    case pitching = "Pitching"
    case irons = "Irons"
    case driver = "Driver"
    
    var displayName: String {
        return self.rawValue
    }
} 