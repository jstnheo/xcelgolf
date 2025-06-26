import Foundation
import SwiftData

/// Manages temporary session state before saving to SwiftData
class SessionManager: ObservableObject {
    @Published var currentSession: TempSession?
    
    private let sessionKey = "temp_session_data"
    
    init() {
        loadTempSession()
    }
    
    // MARK: - Session Management
    
    func startSession() {
        if currentSession == nil {
            currentSession = TempSession()
        }
    }
    
    func addDrillResult(_ drill: DrillTemplate, score: Int? = nil, isCompleted: Bool = false) {
        if currentSession == nil {
            startSession()
        }
        
        let result = TempDrillResult(
            drillTemplate: drill,
            score: score,
            isCompleted: isCompleted,
            completedAt: Date()
        )
        
        currentSession?.drillResults.append(result)
        saveTempSession()
    }
    
    func batchAddDrillResults(_ results: [TempDrillResult]) {
        if currentSession == nil {
            startSession()
        }
        
        currentSession?.drillResults.append(contentsOf: results)
        saveTempSession()
    }
    
    func getDrillResults(for category: DrillCategory) -> [TempDrillResult] {
        return currentSession?.drillResults.filter { $0.drillTemplate.category == category } ?? []
    }
    
    func getCompletedDrillsCount(for category: DrillCategory) -> Int {
        return getDrillResults(for: category).count
    }
    
    func saveSessionToSwiftData(modelContext: ModelContext) {
        guard let tempSession = currentSession else { 
            print("DEBUG: No current session to save")
            return 
        }
        
        print("DEBUG: Starting saveSessionToSwiftData")
        print("DEBUG: Temp session has \(tempSession.drillResults.count) drill results")
        
        // Create a new PracticeSession
        let practiceSession = PracticeSession(date: tempSession.startDate)
        print("DEBUG: Created practice session")
        
        // Insert the practice session into the context first
        modelContext.insert(practiceSession)
        print("DEBUG: Inserted practice session into context")
        
        // Convert temp drill results to actual Drill objects
        for (index, tempResult) in tempSession.drillResults.enumerated() {
            print("DEBUG: Processing drill \(index + 1): \(tempResult.drillTemplate.name)")
            
            let drill = Drill(
                name: tempResult.drillTemplate.name,
                drillDescription: tempResult.drillTemplate.description,
                category: tempResult.drillTemplate.category,
                scoringType: tempResult.drillTemplate.scoringType,
                maxScore: tempResult.drillTemplate.defaultMaxScore,
                actualScore: tempResult.score ?? 0,
                isCompleted: tempResult.isCompleted,
                completedAt: tempResult.completedAt
            )
            
            print("DEBUG: Created drill object")
            
            // Insert the drill into the context
            modelContext.insert(drill)
            print("DEBUG: Inserted drill into context")
            
            // Now establish the relationship (both objects are in the context)
            practiceSession.drills.append(drill)
            print("DEBUG: Added drill to practice session")
        }
        
        print("DEBUG: About to save context")
        
        // Save the context
        do {
            try modelContext.save()
            print("DEBUG: Successfully saved context")
            // Clear temp session after successful save
            clearSession()
            print("DEBUG: Cleared temp session")
        } catch {
            print("DEBUG: Failed to save session: \(error)")
        }
    }
    
    func clearSession() {
        currentSession = nil
        UserDefaults.standard.removeObject(forKey: sessionKey)
    }
    
    func forceSave() {
        saveTempSession()
    }
    
    // MARK: - Persistence
    
    private func saveTempSession() {
        guard let session = currentSession else { return }
        if let data = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(data, forKey: sessionKey)
        }
    }
    
    private func loadTempSession() {
        guard let data = UserDefaults.standard.data(forKey: sessionKey),
              let session = try? JSONDecoder().decode(TempSession.self, from: data) else {
            return
        }
        currentSession = session
    }
} 