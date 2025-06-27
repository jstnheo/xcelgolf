import Foundation
import SwiftData

enum ImportError: LocalizedError {
    case invalidFileFormat
    case emptyFile
    case invalidHeader
    case invalidDateFormat
    case invalidScoreFormat
    case duplicateSession
    case unknownCategory
    
    var errorDescription: String? {
        switch self {
        case .invalidFileFormat:
            return "Invalid file format. Please select a CSV file."
        case .emptyFile:
            return "The selected file is empty."
        case .invalidHeader:
            return "Invalid CSV header. Expected format: Session Date, Session Notes, Drill Name, Drill Description, Category, Max Score, Actual Score, Success Rate, Drill Notes, Completed At"
        case .invalidDateFormat:
            return "Invalid date format in CSV file."
        case .invalidScoreFormat:
            return "Invalid score format in CSV file."
        case .duplicateSession:
            return "Some sessions already exist and will be skipped."
        case .unknownCategory:
            return "Unknown drill category found in CSV file."
        }
    }
}

struct ImportResult {
    let sessionsImported: Int
    let drillsImported: Int
    let duplicatesSkipped: Int
    let errors: [ImportError]
}

struct CSVRow {
    let sessionDate: String
    let sessionNotes: String
    // Weather fields
    let temperature: String
    let weatherCondition: String
    let weatherDescription: String
    let humidity: String
    let feelsLike: String
    // Wind fields
    let windSpeed: String
    let windDirection: String
    let windDirectionText: String
    // Location fields
    let locationName: String
    let locationType: String
    let locationLatitude: String
    let locationLongitude: String
    // Drill fields
    let drillName: String
    let drillDescription: String
    let category: String
    let maxScore: String
    let actualScore: String
    let successRate: String
    let drillNotes: String
    let completedAt: String
}

class DataImportService {
    
    static func importFromCSV(data: Data, modelContext: ModelContext) async throws -> ImportResult {
        guard let csvString = String(data: data, encoding: .utf8) else {
            throw ImportError.invalidFileFormat
        }
        
        let lines = csvString.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        guard !lines.isEmpty else {
            throw ImportError.emptyFile
        }
        
        // Validate header
        let expectedHeader = "Session Date,Session Notes,Temperature,Weather Condition,Weather Description,Humidity,Feels Like,Wind Speed,Wind Direction,Wind Direction Text,Location Name,Location Type,Location Latitude,Location Longitude,Drill Name,Drill Description,Category,Max Score,Actual Score,Success Rate,Drill Notes,Completed At"
        let actualHeader = lines[0].replacingOccurrences(of: "\"", with: "")
        
        guard actualHeader.lowercased().contains("session date") && 
              actualHeader.lowercased().contains("drill name") &&
              actualHeader.lowercased().contains("category") else {
            throw ImportError.invalidHeader
        }
        
        var sessionsImported = 0
        var drillsImported = 0
        var duplicatesSkipped = 0
        var errors: [ImportError] = []
        
        // Parse CSV rows
        let csvRows = try parseCSVRows(lines: Array(lines.dropFirst()))
        
        // Group rows by session date and notes
        let groupedRows = Dictionary(grouping: csvRows) { row in
            "\(row.sessionDate)_\(row.sessionNotes)"
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        for (sessionKey, rows) in groupedRows {
            do {
                let firstRow = rows[0]
                
                // Parse session date
                guard let sessionDate = parseDate(from: firstRow.sessionDate) else {
                    errors.append(.invalidDateFormat)
                    continue
                }
                
                // Check for duplicate session
                let existingSessions = try modelContext.fetch(FetchDescriptor<PracticeSession>())
                let sessionNotes = firstRow.sessionNotes.isEmpty ? nil : firstRow.sessionNotes
                let isDuplicate = existingSessions.contains { session in
                    Calendar.current.isDate(session.date, inSameDayAs: sessionDate) &&
                    session.notes == sessionNotes
                }
                
                if isDuplicate {
                    duplicatesSkipped += 1
                    continue
                }
                
                // Create new session
                let session = PracticeSession(
                    date: sessionDate,
                    notes: sessionNotes
                )
                
                // Set weather data from first row
                if !firstRow.temperature.isEmpty {
                    session.temperature = Double(firstRow.temperature)
                }
                session.weatherCondition = firstRow.weatherCondition.isEmpty ? nil : firstRow.weatherCondition
                session.weatherDescription = firstRow.weatherDescription.isEmpty ? nil : firstRow.weatherDescription
                if !firstRow.humidity.isEmpty {
                    session.humidity = Int(firstRow.humidity)
                }
                if !firstRow.feelsLike.isEmpty {
                    session.feelsLikeTemperature = Double(firstRow.feelsLike)
                }
                
                // Set wind data from first row
                if !firstRow.windSpeed.isEmpty {
                    session.windSpeed = Double(firstRow.windSpeed)
                }
                if !firstRow.windDirection.isEmpty {
                    session.windDirection = Int(firstRow.windDirection)
                }
                session.windDirectionText = firstRow.windDirectionText.isEmpty ? nil : firstRow.windDirectionText
                
                // Set location data from first row
                session.locationName = firstRow.locationName.isEmpty ? nil : firstRow.locationName
                session.golfCourseType = firstRow.locationType.isEmpty ? nil : firstRow.locationType
                if !firstRow.locationLatitude.isEmpty {
                    session.latitude = Double(firstRow.locationLatitude)
                }
                if !firstRow.locationLongitude.isEmpty {
                    session.longitude = Double(firstRow.locationLongitude)
                }
                
                // Add drills to session
                for row in rows {
                    if !row.drillName.isEmpty {
                        do {
                            let drill = try createDrillFromRow(row: row)
                            session.drills.append(drill)
                            drillsImported += 1
                        } catch {
                            if let importError = error as? ImportError {
                                errors.append(importError)
                            }
                        }
                    }
                }
                
                modelContext.insert(session)
                sessionsImported += 1
                
            } catch {
                if let importError = error as? ImportError {
                    errors.append(importError)
                }
            }
        }
        
        try modelContext.save()
        
        return ImportResult(
            sessionsImported: sessionsImported,
            drillsImported: drillsImported,
            duplicatesSkipped: duplicatesSkipped,
            errors: errors
        )
    }
    
    private static func parseCSVRows(lines: [String]) throws -> [CSVRow] {
        var rows: [CSVRow] = []
        
        for line in lines {
            let fields = parseCSVLine(line)
            
            guard fields.count >= 22 else {
                continue // Skip incomplete rows
            }
            
            let row = CSVRow(
                sessionDate: fields[0],
                sessionNotes: fields[1],
                temperature: fields[2],
                weatherCondition: fields[3],
                weatherDescription: fields[4],
                humidity: fields[5],
                feelsLike: fields[6],
                windSpeed: fields[7],
                windDirection: fields[8],
                windDirectionText: fields[9],
                locationName: fields[10],
                locationType: fields[11],
                locationLatitude: fields[12],
                locationLongitude: fields[13],
                drillName: fields[14],
                drillDescription: fields[15],
                category: fields[16],
                maxScore: fields[17],
                actualScore: fields[18],
                successRate: fields[19],
                drillNotes: fields[20],
                completedAt: fields[21]
            )
            
            rows.append(row)
        }
        
        return rows
    }
    
    private static func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var insideQuotes = false
        var i = line.startIndex
        
        while i < line.endIndex {
            let char = line[i]
            
            if char == "\"" {
                if insideQuotes && i < line.index(before: line.endIndex) && line[line.index(after: i)] == "\"" {
                    // Escaped quote
                    currentField += "\""
                    i = line.index(after: i)
                } else {
                    insideQuotes.toggle()
                }
            } else if char == "," && !insideQuotes {
                fields.append(currentField)
                currentField = ""
            } else {
                currentField += String(char)
            }
            
            i = line.index(after: i)
        }
        
        fields.append(currentField)
        return fields
    }
    
    private static func createDrillFromRow(row: CSVRow) throws -> Drill {
        // Parse category
        guard let category = DrillCategory.fromDisplayName(row.category) else {
            throw ImportError.unknownCategory
        }
        
        // Parse scores
        let maxScore = parseScore(row.maxScore)
        let actualScore = parseScore(row.actualScore)
        
        // Determine scoring type
        let scoringType: ScoringType
        if maxScore != nil || actualScore != nil {
            scoringType = .scored
        } else {
            scoringType = .completion
        }
        
        // Parse completion date
        let completedAt = parseDate(from: row.completedAt) ?? Date()
        
        // Determine completion status
        let isCompleted: Bool?
        if scoringType == .completion {
            isCompleted = !row.successRate.isEmpty && row.successRate != "0%"
        } else {
            isCompleted = nil
        }
        
        return Drill(
            name: row.drillName,
            drillDescription: row.drillDescription.isEmpty ? row.drillName : row.drillDescription,
            category: category,
            scoringType: scoringType,
            maxScore: maxScore,
            actualScore: actualScore,
            isCompleted: isCompleted,
            notes: row.drillNotes.isEmpty ? nil : row.drillNotes,
            completedAt: completedAt
        )
    }
    
    private static func parseDate(from string: String) -> Date? {
        let formatters = [
            DateFormatter().apply { $0.dateStyle = .medium; $0.timeStyle = .short },
            DateFormatter().apply { $0.dateFormat = "yyyy-MM-dd HH:mm:ss" },
            DateFormatter().apply { $0.dateFormat = "yyyy-MM-dd" },
            DateFormatter().apply { $0.dateFormat = "MM/dd/yyyy" },
            DateFormatter().apply { $0.dateFormat = "dd/MM/yyyy" },
            DateFormatter().apply { $0.dateFormat = "yyyy/MM/dd" }
        ]
        
        for formatter in formatters {
            if let date = formatter.date(from: string) {
                return date
            }
        }
        
        return nil
    }
    
    private static func parseScore(_ string: String) -> Int? {
        let cleanString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return Int(cleanString)
    }
}

// MARK: - Extensions
extension DrillCategory {
    static func fromDisplayName(_ displayName: String) -> DrillCategory? {
        return DrillCategory.allCases.first { $0.displayName.lowercased() == displayName.lowercased() }
    }
}

extension DateFormatter {
    func apply(_ closure: (DateFormatter) -> Void) -> DateFormatter {
        closure(self)
        return self
    }
} 