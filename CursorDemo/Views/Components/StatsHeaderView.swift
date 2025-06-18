import SwiftUI

struct StatsHeaderView: View {
    let totalSessions: Int
    let totalDrills: Int
    let averageDrills: Double
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: 20) {
            StatCardView(title: "Sessions", value: "\(totalSessions)")
            StatCardView(title: "Total Drills", value: "\(totalDrills)")
            StatCardView(title: "Avg/Session", value: String(format: "%.1f", averageDrills))
        }
        .padding()
        .background(theme.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.divider, lineWidth: 1)
        )
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct StatCardView: View {
    let title: String
    let value: String
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(theme.primary)
            Text(title)
                .font(.caption)
                .foregroundColor(theme.textSecondary)
        }
    }
}

#Preview {
    StatsHeaderView(totalSessions: 5, totalDrills: 23, averageDrills: 4.6)
        .environmentObject(ThemeManager())
        .themed()
} 