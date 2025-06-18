import SwiftUI
import SwiftData

struct CurrentSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.theme) private var theme
    @Query private var sessions: [PracticeSession]
    @State private var showingNewSession = false
    @State private var activeSession: PracticeSession?
    @EnvironmentObject private var sessionManager: SessionManager
    
    // Get today's session if it exists
    var todaysSession: PracticeSession? {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        return sessions.first { session in
            session.date >= today && session.date < tomorrow
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Always show current session card (with placeholder data if no real session)
                    CurrentSessionCardView(session: todaysSession)
                        .environmentObject(sessionManager)
                    
                    // Drill Category Cards
                    LazyVStack(spacing: 16) {
                        ForEach(DrillCategory.allCases, id: \.self) { category in
                            DrillCategoryCard(category: category)
                        }
                    }
                    
                    // TODO: FUTURE FEATURE - Current Session Enhancements
                    /*
                     CURRENT SESSION FEATURES TO IMPLEMENT:
                     
                     1. ACTIVE SESSION MANAGEMENT:
                        - Session timer/duration tracking
                        - Real-time drill counter
                        - Quick drill entry without navigation
                        - Session pause/resume functionality
                     
                     2. TODAY'S PRACTICE OVERVIEW:
                        - Weather conditions
                        - Location/course information
                        - Practice goals for the day
                        - Energy/mood tracking
                     
                     3. QUICK ACTIONS:
                        - One-tap drill logging
                        - Voice notes for sessions
                        - Photo capture for form analysis
                        - Quick performance rating (1-5 stars)
                     
                     4. MOTIVATION & GAMIFICATION:
                        - Daily streak counter
                        - Achievement badges
                        - Progress towards goals
                        - Motivational quotes/tips
                     
                     IMPLEMENTATION NOTES:
                     - Use Timer for session duration tracking
                     - Consider location services for course tracking
                     - Implement quick drill templates for fast entry
                     - Add haptic feedback for accomplishments
                     */
                }
                .padding()
                .padding(.bottom, 80) // Extra padding for floating tab bar
            }
            .scrollIndicators(.hidden)
            .background(theme.background)
            .navigationTitle("Current Session")
        }
        .sheet(isPresented: $showingNewSession) {
            NewSessionView()
        }
        .onAppear {
            activeSession = todaysSession
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PracticeSession.self, Drill.self, configurations: config)
    
    return CurrentSessionView()
        .modelContainer(container)
        .environmentObject(ThemeManager())
        .themed()
}
