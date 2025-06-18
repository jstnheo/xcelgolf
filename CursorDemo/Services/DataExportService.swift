import Foundation
import SwiftData
import MessageUI

enum ExportFormat: String, CaseIterable {
    case csv = "CSV"
    case json = "JSON"
    
    var fileExtension: String {
        switch self {
        case .csv: return "csv"
        case .json: return "json"
        }
    }
    
    var mimeType: String {
        switch self {
        case .csv: return "text/csv"
        case .json: return "application/json"
        }
    }
}

struct ExportData {
    let sessions: [PracticeSession]
    let format: ExportFormat
    let dateRange: String
}

class DataExportService {
    
    static func exportData(sessions: [PracticeSession], format: ExportFormat) -> Data? {
        switch format {
        case .csv:
            return exportToCSV(sessions: sessions)
        case .json:
            return exportToJSON(sessions: sessions)
        }
    }
    
    private static func exportToCSV(sessions: [PracticeSession]) -> Data? {
        var csvContent = "Session Date,Session Notes,Drill Name,Drill Description,Category,Max Score,Actual Score,Success Rate,Drill Notes,Completed At\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        for session in sessions {
            let sessionDate = dateFormatter.string(from: session.date)
            let sessionNotes = session.notes?.replacingOccurrences(of: "\"", with: "\"\"") ?? ""
            
            if session.drills.isEmpty {
                // Session with no drills
                csvContent += "\"\(sessionDate)\",\"\(sessionNotes)\",,,,,,,,\n"
            } else {
                for drill in session.drills {
                    let drillName = drill.name.replacingOccurrences(of: "\"", with: "\"\"")
                    let drillDescription = drill.drillDescription.replacingOccurrences(of: "\"", with: "\"\"")
                    let category = drill.category.displayName
                    let maxScore = drill.maxScore?.description ?? ""
                    let actualScore = drill.actualScore?.description ?? ""
                    let successRate: String
                    
                    if let max = drill.maxScore, let actual = drill.actualScore, max > 0 {
                        let rate = Double(actual) / Double(max) * 100
                        successRate = String(format: "%.1f%%", rate)
                    } else if let completed = drill.isCompleted {
                        successRate = completed ? "100%" : "0%"
                    } else {
                        successRate = ""
                    }
                    
                    let drillNotes = drill.notes?.replacingOccurrences(of: "\"", with: "\"\"") ?? ""
                    let completedAt = dateFormatter.string(from: drill.completedAt)
                    
                    csvContent += "\"\(sessionDate)\",\"\(sessionNotes)\",\"\(drillName)\",\"\(drillDescription)\",\"\(category)\",\"\(maxScore)\",\"\(actualScore)\",\"\(successRate)\",\"\(drillNotes)\",\"\(completedAt)\"\n"
                }
            }
        }
        
        return csvContent.data(using: .utf8)
    }
    
    private static func exportToJSON(sessions: [PracticeSession]) -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let exportSessions = sessions.map { session in
            ExportSession(
                id: session.id.hashValue.description,
                date: session.date,
                notes: session.notes,
                drills: session.drills.map { drill in
                    ExportDrill(
                        id: drill.id.hashValue.description,
                        name: drill.name,
                        description: drill.drillDescription,
                        category: drill.category.rawValue,
                        maxScore: drill.maxScore,
                        actualScore: drill.actualScore,
                        isCompleted: drill.isCompleted,
                        notes: drill.notes,
                        completedAt: drill.completedAt
                    )
                }
            )
        }
        
        let exportData = ExportContainer(
            exportDate: Date(),
            version: "1.0",
            totalSessions: sessions.count,
            totalDrills: sessions.flatMap { $0.drills }.count,
            sessions: exportSessions
        )
        
        return try? encoder.encode(exportData)
    }
    
    static func generateFileName(format: ExportFormat) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm"
        let timestamp = dateFormatter.string(from: Date())
        return "golf_practice_data_\(timestamp).\(format.fileExtension)"
    }
}

// MARK: - Export Data Models
struct ExportContainer: Codable {
    let exportDate: Date
    let version: String
    let totalSessions: Int
    let totalDrills: Int
    let sessions: [ExportSession]
}

struct ExportSession: Codable {
    let id: String
    let date: Date
    let notes: String?
    let drills: [ExportDrill]
}

struct ExportDrill: Codable {
    let id: String
    let name: String
    let description: String?
    let category: String
    let maxScore: Int?
    let actualScore: Int?
    let isCompleted: Bool?
    let notes: String?
    let completedAt: Date?
} 