import XCTest
import SwiftData
@testable import CursorDemo

@MainActor
final class DataExportImportTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUpWithError() throws {
        // Create in-memory model container for testing
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: PracticeSession.self, Drill.self, configurations: config)
        modelContext = modelContainer.mainContext
    }
    
    override func tearDownWithError() throws {
        modelContainer = nil
        modelContext = nil
    }
    
    // MARK: - Test Data
    
    private func createTestSessions() -> [PracticeSession] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        // Session 1: Mixed drills with scores
        let session1 = PracticeSession(
            date: dateFormatter.date(from: "2024-01-15 09:30:00")!,
            notes: "Morning practice session"
        )
        
        let drill1 = Drill(
            name: "10 from 3′",
            drillDescription: "Make 10 putts from 3 feet",
            category: .putting,
            scoringType: .scored,
            maxScore: 10,
            actualScore: 8,
            isCompleted: nil,
            notes: "Good putting today",
            completedAt: dateFormatter.date(from: "2024-01-15 09:45:00")!
        )
        
        let drill2 = Drill(
            name: "Chip to 3-Foot Circle",
            drillDescription: "Chip balls to land within 3 feet of pin",
            category: .chipping,
            scoringType: .scored,
            maxScore: 5,
            actualScore: 3,
            isCompleted: nil,
            notes: nil,
            completedAt: dateFormatter.date(from: "2024-01-15 10:00:00")!
        )
        
        session1.drills = [drill1, drill2]
        
        // Session 2: Completion-based drills
        let session2 = PracticeSession(
            date: dateFormatter.date(from: "2024-01-20 14:15:00")!,
            notes: nil
        )
        
        let drill3 = Drill(
            name: "Alignment-stick pitches",
            drillDescription: "Practice pitching using alignment sticks for proper setup",
            category: .pitching,
            scoringType: .completion,
            maxScore: nil,
            actualScore: nil,
            isCompleted: true,
            notes: "Felt more consistent",
            completedAt: dateFormatter.date(from: "2024-01-20 14:30:00")!
        )
        
        let drill4 = Drill(
            name: "Balance & Setup Drills",
            drillDescription: "Practice proper stance and balance throughout swing",
            category: .driver,
            scoringType: .completion,
            maxScore: nil,
            actualScore: nil,
            isCompleted: false,
            notes: "Need more work on balance",
            completedAt: dateFormatter.date(from: "2024-01-20 14:45:00")!
        )
        
        session2.drills = [drill3, drill4]
        
        // Session 3: Iron drills with high scores
        let session3 = PracticeSession(
            date: dateFormatter.date(from: "2024-01-25 16:00:00")!,
            notes: "Focused on iron accuracy"
        )
        
        let drill5 = Drill(
            name: "7-iron on line (out of 5)",
            drillDescription: "Hit 5 seven-iron shots on target line",
            category: .irons,
            scoringType: .scored,
            maxScore: 5,
            actualScore: 5,
            isCompleted: nil,
            notes: "Perfect session!",
            completedAt: dateFormatter.date(from: "2024-01-25 16:20:00")!
        )
        
        session3.drills = [drill5]
        
        return [session1, session2, session3]
    }
    
    private var testCSVData: String {
        return """
        Session Date,Session Notes,Drill Name,Drill Description,Category,Max Score,Actual Score,Success Rate,Drill Notes,Completed At
        "Jan 15, 2024 at 9:30 AM","Morning practice session","10 from 3′","Make 10 putts from 3 feet","Putting","10","8","80.0%","Good putting today","Jan 15, 2024 at 9:45 AM"
        "Jan 15, 2024 at 9:30 AM","Morning practice session","Chip to 3-Foot Circle","Chip balls to land within 3 feet of pin","Chipping","5","3","60.0%","","Jan 15, 2024 at 10:00 AM"
        "Jan 20, 2024 at 2:15 PM","","Alignment-stick pitches","Practice pitching using alignment sticks for proper setup","Pitching","","","100%","Felt more consistent","Jan 20, 2024 at 2:30 PM"
        "Jan 20, 2024 at 2:15 PM","","Balance & Setup Drills","Practice proper stance and balance throughout swing","Driver","","","0%","Need more work on balance","Jan 20, 2024 at 2:45 PM"
        "Jan 25, 2024 at 4:00 PM","Focused on iron accuracy","7-iron on line (out of 5)","Hit 5 seven-iron shots on target line","Irons","5","5","100.0%","Perfect session!","Jan 25, 2024 at 4:20 PM"
        """
    }
    
    // MARK: - Export Tests
    
    func testCSVExport() throws {
        // Given
        let testSessions = createTestSessions()
        
        // When
        let exportData = DataExportService.exportData(sessions: testSessions, format: .csv)
        
        // Then
        XCTAssertNotNil(exportData, "Export data should not be nil")
        
        guard let data = exportData,
              let csvString = String(data: data, encoding: .utf8) else {
            XCTFail("Should be able to convert export data to string")
            return
        }
        
        let lines = csvString.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        // Should have header + 5 data rows
        XCTAssertEqual(lines.count, 6, "Should have header plus 5 drill rows")
        
        // Verify header
        let header = lines[0]
        XCTAssertTrue(header.contains("Session Date"))
        XCTAssertTrue(header.contains("Drill Name"))
        XCTAssertTrue(header.contains("Category"))
        
        // Verify first drill row contains expected data
        let firstDataRow = lines[1]
        XCTAssertTrue(firstDataRow.contains("10 from 3′"))
        XCTAssertTrue(firstDataRow.contains("Morning practice session"))
        XCTAssertTrue(firstDataRow.contains("Putting"))
        XCTAssertTrue(firstDataRow.contains("80.0%"))
    }
    
    // MARK: - Import Tests
    
    func testCSVImport() async throws {
        // Given
        let csvData = testCSVData.data(using: .utf8)!
        
        // When
        let result = try await DataImportService.importFromCSV(data: csvData, modelContext: modelContext)
        
        // Then
        XCTAssertEqual(result.sessionsImported, 3, "Should import 3 sessions")
        XCTAssertEqual(result.drillsImported, 5, "Should import 5 drills")
        XCTAssertEqual(result.duplicatesSkipped, 0, "Should have no duplicates")
        XCTAssertTrue(result.errors.isEmpty, "Should have no errors")
        
        // Verify data was actually saved
        let sessions = try modelContext.fetch(FetchDescriptor<PracticeSession>(
            sortBy: [SortDescriptor(\.date)]
        ))
        
        XCTAssertEqual(sessions.count, 3)
        
        // Verify first session
        let firstSession = sessions[0]
        XCTAssertEqual(firstSession.notes, "Morning practice session")
        XCTAssertEqual(firstSession.drills.count, 2)
        
        // Verify first drill
        let firstDrill = firstSession.drills.first { $0.name == "10 from 3′" }
        XCTAssertNotNil(firstDrill)
        XCTAssertEqual(firstDrill?.category, .putting)
        XCTAssertEqual(firstDrill?.maxScore, 10)
        XCTAssertEqual(firstDrill?.actualScore, 8)
        XCTAssertEqual(firstDrill?.notes, "Good putting today")
        
        // Verify completion drill
        let completionDrill = sessions[1].drills.first { $0.name == "Alignment-stick pitches" }
        XCTAssertNotNil(completionDrill)
        XCTAssertEqual(completionDrill?.scoringType, .completion)
        XCTAssertEqual(completionDrill?.isCompleted, true)
        XCTAssertNil(completionDrill?.maxScore)
        XCTAssertNil(completionDrill?.actualScore)
    }
    
    func testCSVImportDuplicateDetection() async throws {
        // Given - First import
        let csvData = testCSVData.data(using: .utf8)!
        let firstResult = try await DataImportService.importFromCSV(data: csvData, modelContext: modelContext)
        
        XCTAssertEqual(firstResult.sessionsImported, 3)
        XCTAssertEqual(firstResult.duplicatesSkipped, 0)
        
        // When - Second import (same data)
        let secondResult = try await DataImportService.importFromCSV(data: csvData, modelContext: modelContext)
        
        // Then
        XCTAssertEqual(secondResult.sessionsImported, 0, "Should not import duplicate sessions")
        XCTAssertEqual(secondResult.duplicatesSkipped, 3, "Should skip 3 duplicate sessions")
        XCTAssertEqual(secondResult.drillsImported, 0, "Should not import drills for duplicate sessions")
        
        // Verify total sessions is still 3
        let sessions = try modelContext.fetch(FetchDescriptor<PracticeSession>())
        XCTAssertEqual(sessions.count, 3)
    }
    
    func testCSVImportInvalidCategory() async throws {
        // Given
        let invalidCategoryCSV = """
        Session Date,Session Notes,Drill Name,Drill Description,Category,Max Score,Actual Score,Success Rate,Drill Notes,Completed At
        "Jan 15, 2024 at 9:30 AM","Test session","Test Drill","Test description","InvalidCategory","5","3","60.0%","","Jan 15, 2024 at 9:45 AM"
        """
        let csvData = invalidCategoryCSV.data(using: .utf8)!
        
        // When
        let result = try await DataImportService.importFromCSV(data: csvData, modelContext: modelContext)
        
        // Then
        XCTAssertEqual(result.sessionsImported, 1, "Should still create session")
        XCTAssertEqual(result.drillsImported, 0, "Should not import drill with invalid category")
        XCTAssertFalse(result.errors.isEmpty, "Should have errors")
        XCTAssertTrue(result.errors.contains { error in
            if case .unknownCategory = error { return true }
            return false
        }, "Should contain unknown category error")
    }
    
    func testEmptyCSVImport() async throws {
        // Given
        let emptyCSV = ""
        let csvData = emptyCSV.data(using: .utf8)!
        
        // When & Then
        do {
            _ = try await DataImportService.importFromCSV(data: csvData, modelContext: modelContext)
            XCTFail("Should throw empty file error")
        } catch {
            XCTAssertTrue(error is ImportError)
            if let importError = error as? ImportError {
                XCTAssertEqual(importError, ImportError.emptyFile)
            }
        }
    }
    
    func testInvalidHeaderCSVImport() async throws {
        // Given
        let invalidHeaderCSV = """
        Invalid,Header,Format
        "Some","Data","Here"
        """
        let csvData = invalidHeaderCSV.data(using: .utf8)!
        
        // When & Then
        do {
            _ = try await DataImportService.importFromCSV(data: csvData, modelContext: modelContext)
            XCTFail("Should throw invalid header error")
        } catch {
            XCTAssertTrue(error is ImportError)
            if let importError = error as? ImportError {
                XCTAssertEqual(importError, ImportError.invalidHeader)
            }
        }
    }
} 