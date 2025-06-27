import SwiftUI
import SwiftData

struct CurrentSessionCardView: View {
    let session: PracticeSession?
    @Environment(\.theme) private var theme
    @State private var showingAddDrill = false
    @EnvironmentObject private var sessionManager: SessionManager
    @EnvironmentObject private var locationManager: LocationManager
    
    private var hasTempSession: Bool {
        sessionManager.currentSession != nil && !sessionManager.currentSession!.drillResults.isEmpty
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Date, time, and location
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Date(), format: .dateTime.weekday(.wide).month(.wide).day())
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.textPrimary)
                    Text(Date(), format: .dateTime.hour().minute())
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                }
                
                Spacer()
                
                // Location
                HStack(spacing: 4) {
                    Image(systemName: locationManager.isLoading ? "location.circle" : "location.fill")
                        .foregroundColor(theme.primary)
                        .font(.caption)
                        .symbolEffect(.pulse, isActive: locationManager.isLoading)
                    Text(locationManager.locationName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(theme.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            
            // Weather information
            HStack(spacing: 16) {
                // Weather icon and temp
                HStack(spacing: 6) {
                    Image(systemName: "sun.max.fill")
                        .foregroundColor(theme.warning)
                        .font(.title3)
                    Text("72°F")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(theme.textPrimary)
                }
                
                // Wind information
                HStack(spacing: 6) {
                    Image(systemName: "wind")
                        .foregroundColor(theme.primary)
                        .font(.subheadline)
                    Text("5 mph NE")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                }
                
                Spacer()
                
                // Session status
                HStack(spacing: 4) {
                    Circle()
                        .fill(sessionStatusColor)
                        .frame(width: 8, height: 8)
                    Text(sessionStatusText)
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
            }
            
            // Temp session info if available
            if hasTempSession {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Practice in Progress")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(theme.warning)
                        Text("\(sessionManager.currentSession!.drillResults.count) drills logged")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    Text("Unsaved")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(theme.warning)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(theme.warning.opacity(0.1))
                        .cornerRadius(10)
                }
                .padding()
                .background(theme.warning.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.divider, lineWidth: 1)
        )
        .shadow(color: theme.primary.opacity(0.1), radius: 2)
        .sheet(isPresented: $showingAddDrill) {
            if let session = session {
                NewExerciseView(session: session)
            } else {
                NewSessionView()
            }
        }
        .onAppear {
            // Request location update when the card appears
            if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
                locationManager.startLocationUpdates()
            }
        }
    }
    
    private var sessionStatusColor: Color {
        if hasTempSession {
            return theme.warning
        } else if session != nil {
            return theme.success
        } else {
            return theme.textSecondary
        }
    }
    
    private var sessionStatusText: String {
        if hasTempSession {
            return "In Progress"
        } else if session != nil {
            return "New"
        } else {
            return "Not Started"
        }
    }
}

#Preview {
    CurrentSessionCardView(session: nil)
        .padding()
        .environmentObject(ThemeManager())
        .themed()
} 