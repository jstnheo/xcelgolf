import SwiftUI
import SwiftData

struct SessionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.theme) private var theme
    @Bindable var session: PracticeSession
    @State private var showingAddDrill = false
    
    var body: some View {
        List {
            Section("Session Details") {
                DatePicker("Date", selection: $session.date)
                    .foregroundColor(theme.textPrimary)
                TextField("Notes", text: Binding(
                    get: { session.notes ?? "" },
                    set: { session.notes = $0.isEmpty ? nil : $0 }
                ))
                .foregroundColor(theme.textPrimary)
                
                if session.totalDrills > 0 {
                    HStack {
                        Text("Success Rate:")
                            .foregroundColor(theme.textPrimary)
                        Spacer()
                        Text("\(session.averageSuccessPercentage)%")
                            .foregroundColor(theme.success)
                            .fontWeight(.semibold)
                    }
                }
            }
            
            Section("Drills") {
                ForEach(session.drills.sorted { $0.completedAt < $1.completedAt }) { drill in
                    DrillRow(drill: drill)
                }
                .onDelete(perform: deleteDrills)
            }
        }
        .scrollContentBackground(.hidden)
        .background(theme.background)
        .navigationTitle("Practice Session")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddDrill = true }) {
                    Label("Add Drill", systemImage: "plus")
                }
                .foregroundColor(theme.primary)
            }
        }
        .sheet(isPresented: $showingAddDrill) {
            NewExerciseView(session: session)
        }
    }
    
    private func deleteDrills(offsets: IndexSet) {
        withAnimation {
            let sortedDrills = session.drills.sorted { $0.completedAt < $1.completedAt }
            for index in offsets {
                let drill = sortedDrills[index]
                if let drillIndex = session.drills.firstIndex(of: drill) {
                    session.drills.remove(at: drillIndex)
                }
                modelContext.delete(drill)
            }
            
            // Explicitly save the context to ensure persistence
            do {
                try modelContext.save()
            } catch {
                print("Failed to save after deleting drills: \(error)")
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PracticeSession.self, Drill.self, configurations: config)
    let context = container.mainContext
    
    let session = PracticeSession()
    context.insert(session)
    
    return SessionDetailView(session: session)
        .modelContainer(container)
        .environmentObject(ThemeManager())
        .themed()
} 