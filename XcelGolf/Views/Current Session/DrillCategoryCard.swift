import SwiftUI

struct DrillCategoryCard: View {
    let category: DrillCategory
    @Environment(\.theme) private var theme
    @State private var showingDrillSelection = false
    @EnvironmentObject private var sessionManager: SessionManager
    @StateObject private var drillTemplateService = DrillTemplateService()
    
    private var completedDrillsCount: Int {
        sessionManager.getCompletedDrillsCount(for: category)
    }
    
    private var totalDrillsCount: Int {
        // Get total available drills for this category from DrillTemplateService
        return max(1, drillTemplateService.getTemplatesForCategory(category).count)
    }
    
    private var clampedCompletedDrillsCount: Int {
        // Ensure completed count never exceeds total count
        return min(completedDrillsCount, totalDrillsCount)
    }
    
    var body: some View {
        Button(action: {
            showingDrillSelection = true
        }) {
            HStack(spacing: 16) {
                // Category icon
                Image(systemName: categoryIcon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(categoryColor)
                    .clipShape(Circle())
                
                // Category info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(category.displayName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.textPrimary)
                        
                        Spacer()
                        
                        if completedDrillsCount > 0 {
                            Text("\(clampedCompletedDrillsCount)/\(totalDrillsCount)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(theme.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(theme.primary.opacity(0.1))
                                .cornerRadius(10)
                        }
                    }
                    
                    Text(categoryDescription)
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(2)
                    
                    // Progress bar if there are completed drills
                    if completedDrillsCount > 0 {
                        ProgressView(value: Double(clampedCompletedDrillsCount), total: Double(totalDrillsCount))
                            .progressViewStyle(LinearProgressViewStyle(tint: categoryColor))
                            .scaleEffect(y: 0.8)
                    }
                }
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
            }
            .padding()
            .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(completedDrillsCount > 0 ? categoryColor.opacity(0.3) : theme.divider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDrillSelection) {
            CategoryDrillSelectionView(category: category)
                .environmentObject(sessionManager)
        }
    }
    
    private var categoryIcon: String {
        switch category {
        case .putting:
            return "target"
        case .chipping:
            return "figure.golf"
        case .pitching:
            return "sportscourt"
        case .driver:
            return "arrow.up.right"
        case .irons:
            return "multiply.circle"
        }
    }
    
    private var categoryColor: Color {
        switch category {
        case .putting:
            return theme.success
        case .chipping:
            return theme.warning
        case .pitching:
            return theme.primary
        case .driver:
            return theme.error
        case .irons:
            return theme.accent
        }
    }
    
    private var categoryDescription: String {
        switch category {
        case .putting:
            return "Short putts, distance control, and green reading"
        case .chipping:
            return "Around the green shots and bump and run"
        case .pitching:
            return "High trajectory shots around the green"
        case .driver:
            return "Tee shots and long distance drives"
        case .irons:
            return "Accuracy and distance with mid-range clubs"
        }
    }
}

#Preview {
    DrillCategoryCard(category: .putting)
        .padding()
        .environmentObject(ThemeManager())
        .themed()
} 