import SwiftUI
import SwiftData

struct SessionRowView: View {
    let session: PracticeSession
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.date, format: .dateTime.day().month().year().hour().minute())
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.textPrimary)
                    
                    Text("\(session.totalDrills) drills")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                }
                
                Spacer()
                
                if session.totalDrills > 0 {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(session.averageSuccessPercentage)%")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(successRateColor)
                        
                        Text("success rate")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                }
            }
        }
        .padding()
        .background(theme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.divider, lineWidth: 1)
        )
    }
    
    private var successRateColor: Color {
        let rate = session.averageSuccessPercentage
        if rate >= 80 {
            return theme.success
        } else if rate >= 60 {
            return theme.warning
        } else {
            return theme.error
        }
    }
} 