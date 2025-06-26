import SwiftUI
import SwiftData

struct NewSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @State private var date = Date()
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                DatePicker("Date", selection: $date)
                    .foregroundColor(theme.textPrimary)
                TextField("Notes", text: $notes)
                    .foregroundColor(theme.textPrimary)
            }
            .scrollContentBackground(.hidden)
            .background(theme.background)
            .navigationTitle("New Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let session = PracticeSession(date: date, notes: notes.isEmpty ? nil : notes)
                        modelContext.insert(session)
                        
                        // Explicitly save the context to ensure persistence
                        do {
                            try modelContext.save()
                        } catch {
                            print("Failed to save session: \(error)")
                        }
                        
                        dismiss()
                    }
                    .foregroundColor(theme.primary)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PracticeSession.self, Drill.self, configurations: config)
    
    return NewSessionView()
        .modelContainer(container)
        .environmentObject(ThemeManager())
        .themed()
} 