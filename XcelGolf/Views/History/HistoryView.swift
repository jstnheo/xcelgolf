import SwiftUI
import SwiftData

enum HistoryTab: String, CaseIterable {
    case trends = "Trends"
    case category = "Category"
    case raw = "Raw"
}

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.theme) private var theme
    @State private var selectedTab: HistoryTab = .raw
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                // Clean segmented control without box
                Picker("History View", selection: $selectedTab) {
                    ForEach(HistoryTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.vertical, 12)
                
                // Content based on selected tab - use lazy loading
                Group {
                    switch selectedTab {
                    case .trends:
                        TrendsView()
                    case .category:
                        CategoryHistoryView()
                    case .raw:
                        RawHistoryView()
                    }
                }
                .id(selectedTab) // Force recreation only when tab changes
            }
            .background(theme.background)
            .navigationTitle("Practice History")
            .navigationDestination(for: PracticeSession.self) { session in
                SessionDetailView(session: session)
            }
        }
    }
}

// MARK: - Trends View
struct TrendsView: View {
    @Environment(\.theme) private var theme
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // AI Insights Header
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.title2)
                        .foregroundColor(theme.primary)
                    Text("AI Golf Insights")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(theme.textPrimary)
                    Spacer()
                    Text("Beta")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(theme.warning.opacity(0.2))
                        .foregroundColor(theme.warning)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Lightweight trend cards - only show a few at a time
                Group {
                    // Performance Trend Card
                    TrendCard(
                        icon: "chart.line.uptrend.xyaxis",
                        iconColor: theme.success,
                        title: "Putting Performance",
                        insight: "Great progress! Your putting accuracy has improved 23% over the last month.",
                        trend: .improving,
                        chartData: [65, 68, 72, 75, 78, 82, 88]
                    )
                    
                    // Practice Pattern Card
                    TimePatternCard(
                        icon: "clock.fill",
                        iconColor: theme.primary,
                        title: "Optimal Practice Times",
                        insight: "You perform 18% better during evening sessions (6-8 PM).",
                        bestTime: "6-8 PM",
                        performance: 85
                    )
                    
                    // Streak Card
                    StreakCard(
                        icon: "flame.fill",
                        iconColor: theme.warning,
                        title: "Practice Streak",
                        insight: "Amazing! You've practiced consistently for 12 days straight.",
                        streakDays: 12,
                        nextGoal: 14
                    )
                    
                    // Weakness Focus Card
                    WeaknessCard(
                        icon: "target",
                        iconColor: theme.error,
                        title: "Focus Area Identified",
                        insight: "Your chipping accuracy drops 15% under pressure. Try practicing with distractions.",
                        category: "Chipping",
                        improvement: 25
                    )
                    
                    // Weather Insight Card
                    WeatherInsightCard(
                        icon: "cloud.sun.fill",
                        iconColor: theme.primary,
                        title: "Weather Performance",
                        insight: "You score 12% better on partly cloudy days compared to sunny conditions.",
                        bestCondition: "Partly Cloudy",
                        improvement: 12
                    )
                    
                    // Skill Balance Card
                    SkillBalanceCard(
                        icon: "chart.pie.fill",
                        iconColor: theme.warning,
                        title: "Skill Balance Analysis",
                        insight: "Your short game is lagging behind your driving. Focus on putting and chipping.",
                        skills: [
                            ("Driving", 85, theme.success),
                            ("Iron Play", 78, theme.primary),
                            ("Chipping", 65, theme.warning),
                            ("Putting", 62, theme.error)
                        ]
                    )
                    
                    // Milestone Achievement Card
                    MilestoneCard(
                        icon: "trophy.fill",
                        iconColor: theme.success,
                        title: "Milestone Achieved",
                        insight: "Congratulations! You've reached a new personal best in putting accuracy.",
                        achievement: "Personal Best",
                        value: "92% accuracy"
                    )
                    
                    // AI Recommendation Card
                    RecommendationCard(
                        icon: "brain.head.profile",
                        iconColor: theme.primary,
                        title: "AI Recommendation",
                        insight: "Based on your progress, try practicing 20-foot putts for 15 minutes daily.",
                        confidence: 87
                    )
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 80) // Extra padding for floating tab bar
        }
        .scrollIndicators(.hidden)
        .background(theme.background)
    }
}

// MARK: - Trend Cards

struct TrendCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let insight: String
    let trend: TrendDirection
    let chartData: [Double]
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.title3)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                TrendIndicator(direction: trend)
            }
            
            Text(insight)
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
                .lineLimit(2)
            
            // Mock trend chart
            HStack(spacing: 2) {
                ForEach(0..<chartData.count, id: \.self) { index in
                    Rectangle()
                        .fill(iconColor.gradient)
                        .frame(width: 8, height: CGFloat(chartData[index]) * 0.5)
                        .cornerRadius(2)
                }
            }
            .frame(height: 40)
        }
        .padding()
        .background(theme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.divider, lineWidth: 1)
        )
    }
}

struct TimePatternCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let insight: String
    let bestTime: String
    let performance: Int
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.title3)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
            }
            
            Text(insight)
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Best Time")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                    Text(bestTime)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(iconColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Performance")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                    Text("\(performance)%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(theme.success)
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
}

struct WeaknessCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let insight: String
    let category: String
    let improvement: Int
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.title3)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Text("FOCUS")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(iconColor.opacity(0.2))
                    .foregroundColor(iconColor)
                    .cornerRadius(6)
            }
            
            Text(insight)
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
            
            HStack {
                Text(category)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Text("Potential +\(improvement)% improvement")
                    .font(.caption)
                    .foregroundColor(theme.success)
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
}

struct StreakCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let insight: String
    let streakDays: Int
    let nextGoal: Int
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.title3)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Text("\(streakDays) DAYS")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(iconColor.opacity(0.2))
                    .foregroundColor(iconColor)
                    .cornerRadius(6)
            }
            
            Text(insight)
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
            
            HStack {
                Text("Next goal: \(nextGoal) days")
                    .font(.subheadline)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                ProgressView(value: Double(streakDays), total: Double(nextGoal))
                    .frame(width: 80)
                    .tint(iconColor)
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
}

struct WeatherInsightCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let insight: String
    let bestCondition: String
    let improvement: Int
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.title3)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
            }
            
            Text(insight)
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Best Conditions")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                    Text(bestCondition)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(theme.textPrimary)
                }
                
                Spacer()
                
                Text("+\(improvement)%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(theme.success)
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
}

struct SkillBalanceCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let insight: String
    let skills: [(String, Int, Color)]
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.title3)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
            }
            
            Text(insight)
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
            
            VStack(spacing: 8) {
                ForEach(skills, id: \.0) { skill, percentage, color in
                    HStack {
                        Text(skill)
                            .font(.caption)
                            .foregroundColor(theme.textPrimary)
                        
                        Spacer()
                        
                        Text("\(percentage)%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(theme.textSecondary)
                    }
                    
                    ProgressView(value: Double(percentage), total: 100.0)
                        .frame(height: 4)
                        .tint(color)
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
}

struct RecommendationCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let insight: String
    let confidence: Int
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.title3)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Text("\(confidence)% confident")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(iconColor.opacity(0.2))
                    .foregroundColor(iconColor)
                    .cornerRadius(6)
            }
            
            Text(insight)
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
        }
        .padding()
        .background(theme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.divider, lineWidth: 1)
        )
    }
}

struct MilestoneCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let insight: String
    let achievement: String
    let value: String
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.title3)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Text("NEW!")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(iconColor.opacity(0.2))
                    .foregroundColor(iconColor)
                    .cornerRadius(6)
            }
            
            Text(insight)
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
            
            HStack {
                VStack(alignment: .leading) {
                    Text(achievement)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.textPrimary)
                    Text(value)
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
                
                Spacer()
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
}

// MARK: - Supporting Components

enum TrendDirection {
    case improving, declining, stable
}

struct TrendIndicator: View {
    let direction: TrendDirection
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.caption)
                .foregroundColor(color)
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.1))
        .cornerRadius(4)
    }
    
    private var iconName: String {
        switch direction {
        case .improving: return "arrow.up"
        case .declining: return "arrow.down"
        case .stable: return "minus"
        }
    }
    
    private var text: String {
        switch direction {
        case .improving: return "UP"
        case .declining: return "DOWN"
        case .stable: return "STABLE"
        }
    }
    
    private var color: Color {
        switch direction {
        case .improving: return theme.success
        case .declining: return theme.error
        case .stable: return theme.warning
        }
    }
}

// MARK: - Category History View
struct CategoryHistoryView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @State private var selectedCategory: DrillCategory?
    
    // Use efficient SwiftData query with sorting
    @Query(sort: \PracticeSession.date, order: .reverse) 
    private var sessions: [PracticeSession]
    
    private var categoryStats: [(DrillCategory, Int, Double)] {
        // Only compute stats for categories that have data
        let stats = DrillCategory.allCases.compactMap { category -> (DrillCategory, Int, Double)? in
            let categoryDrills = sessions.flatMap { $0.drills }.filter { $0.category == category }
            let totalDrills = categoryDrills.count
            
            guard totalDrills > 0 else { return nil }
            
            let successfulDrills = categoryDrills.filter { drill in
                if let actualScore = drill.actualScore, let maxScore = drill.maxScore {
                    return Double(actualScore) / Double(maxScore) >= 0.7 // 70% success rate
                } else {
                    return drill.isCompleted ?? false
                }
            }
            let successRate = Double(successfulDrills.count) / Double(totalDrills)
            
            return (category, totalDrills, successRate)
        }
        
        return stats.sorted { $0.1 > $1.1 } // Sort by drill count
    }
    
    var body: some View {
        VStack {
            if categoryStats.isEmpty {
                ScrollView {
                    VStack {
                        Image(systemName: "chart.pie")
                            .font(.system(size: 50))
                            .foregroundColor(theme.textSecondary)
                        Text("No Category Data")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.textPrimary)
                        Text("Complete some practice sessions to see category breakdown")
                            .font(.subheadline)
                            .foregroundColor(theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.bottom, 80) // Extra padding for floating tab bar
                }
                .scrollIndicators(.hidden)
            } else {
                List {
                    ForEach(categoryStats, id: \.0) { category, drillCount, successRate in
                        CategoryStatsRow(
                            category: category,
                            drillCount: drillCount,
                            successRate: successRate
                        )
                    }
                }
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden)
                .background(theme.background)
                .safeAreaInset(edge: .bottom) {
                    // Invisible spacer for floating tab bar
                    Color.clear.frame(height: 80)
                }
            }
        }
        .background(theme.background)
    }
}

struct CategoryStatsRow: View {
    let category: DrillCategory
    let drillCount: Int
    let successRate: Double
    @Environment(\.theme) private var theme
    @State private var showingProgressView = false
    
    var categoryIcon: String {
        switch category {
        case .putting: return "target"
        case .chipping: return "figure.golf"
        case .pitching: return "sportscourt"
        case .irons: return "multiply.circle"
        case .driver: return "arrow.up.right"
        }
    }
    
    var body: some View {
        Button(action: {
            showingProgressView = true
        }) {
            HStack(spacing: 16) {
                // Category icon
                Image(systemName: categoryIcon)
                    .font(.title2)
                    .foregroundColor(theme.primary)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.displayName)
                        .font(.headline)
                        .foregroundColor(theme.textPrimary)
                    
                    HStack {
                        Text("\(drillCount) drills")
                            .font(.subheadline)
                            .foregroundColor(theme.textSecondary)
                        
                        Spacer()
                        
                        // Success rate with color coding
                        let successPercentage = Int(successRate * 100)
                        let successColor = successRate >= 0.8 ? theme.success : 
                                         successRate >= 0.6 ? theme.warning : theme.error
                        
                        Text("\(successPercentage)%")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(successColor)
                    }
                    
                    // Progress bar
                    ProgressView(value: successRate)
                        .progressViewStyle(LinearProgressViewStyle(tint: theme.primary))
                        .scaleEffect(y: 0.8)
                }
                
                // Chevron to indicate it's tappable
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingProgressView) {
            CategoryProgressView(category: category)
        }
    }
}

// MARK: - Raw History View
struct RawHistoryView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    
    // Use efficient SwiftData query with sorting - most recent first
    @Query(sort: \PracticeSession.date, order: .reverse) 
    private var sessions: [PracticeSession]
    
    // Group sessions by month efficiently
    private var sessionsByMonth: [(String, [PracticeSession])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sessions) { session in
            let components = calendar.dateComponents([.year, .month], from: session.date)
            let monthDate = calendar.date(from: components) ?? session.date
            return monthDate
        }
        
        // Sort months in descending order (most recent first)
        let sortedKeys = grouped.keys.sorted(by: >)
        
        return sortedKeys.map { monthDate in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            let monthString = formatter.string(from: monthDate)
            let sessionsInMonth = grouped[monthDate] ?? []
            return (monthString, sessionsInMonth.sorted { $0.date > $1.date })
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if sessions.isEmpty {
                ScrollView {
                    VStack {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 50))
                            .foregroundColor(theme.textSecondary)
                        Text("No Practice Sessions")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.textPrimary)
                        Text("Start practicing to see your sessions here")
                            .font(.subheadline)
                            .foregroundColor(theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.bottom, 80) // Extra padding for floating tab bar
                }
                .scrollIndicators(.hidden)
            } else {
                // Statistics header with proper spacing
                let totalDrills = sessions.reduce(0) { $0 + $1.totalDrills }
                let averageDrills = sessions.isEmpty ? 0.0 : Double(totalDrills) / Double(sessions.count)
                
                VStack(spacing: 0) {
                    StatsHeaderView(
                        totalSessions: sessions.count,
                        totalDrills: totalDrills,
                        averageDrills: averageDrills
                    )
                    .padding(.bottom, 16) // Space between stats and list
                    
                    // Use LazyVStack for better performance with large lists
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(sessionsByMonth, id: \.0) { monthName, monthSessions in
                                VStack(alignment: .leading, spacing: 12) {
                                    // Month header
                                    HStack {
                                        Text(monthName)
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(theme.textPrimary)
                                        
                                        Spacer()
                                        
                                        Text("\(monthSessions.count) sessions")
                                            .font(.subheadline)
                                            .foregroundColor(theme.textSecondary)
                                    }
                                    .padding(.horizontal)
                                    
                                    // Sessions for this month
                                    LazyVStack(spacing: 12) {
                                        ForEach(monthSessions) { session in
                                            NavigationLink(value: session) {
                                                SessionRowView(session: session)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 80) // Extra padding for floating tab bar
                    }
                    .scrollIndicators(.hidden)
                    .background(theme.background)
                }
            }
        }
        .background(theme.background)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PracticeSession.self, Drill.self, configurations: config)
    
    return HistoryView()
        .modelContainer(container)
        .environmentObject(ThemeManager())
        .themed()
} 