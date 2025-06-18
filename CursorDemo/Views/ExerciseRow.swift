import SwiftUI

struct DrillRow: View {
    let drill: Drill
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(drill.name)
                    .font(.headline)
                    .foregroundColor(theme.textPrimary)
                Spacer()
                Text(drill.scoringType.displayName)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(drill.scoringType == .scored ? theme.primary.opacity(0.2) : theme.success.opacity(0.2))
                    .foregroundColor(drill.scoringType == .scored ? theme.primary : theme.success)
                    .cornerRadius(4)
            }
            
            HStack {
                Text("Score: \(drill.displayScore)")
                    .foregroundColor(theme.textPrimary)
                Spacer()
                Text("\(drill.successPercentage)%")
                    .foregroundColor(drill.successPercentage == 100 ? theme.success : (drill.successPercentage >= 50 ? theme.warning : theme.error))
                    .fontWeight(.medium)
            }
            
            if let notes = drill.notes {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        DrillRow(drill: Drill(
            name: "3-Foot Straight Putts",
            drillDescription: "Make putts from 3 feet on a straight line",
            category: .putting,
            maxScore: 5,
            actualScore: 4,
            notes: "Good session"
        ))
        
        DrillRow(drill: Drill(
            name: "Power Drive Session",
            drillDescription: "Focus on maximum distance and power with driver",
            category: .driver,
            isCompleted: true,
            notes: "Felt strong today"
        ))
    }
    .padding()
    .environmentObject(ThemeManager())
    .themed()
} 
