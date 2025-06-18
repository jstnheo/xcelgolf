import SwiftUI
import SwiftData
import Charts

enum DateRange: String, CaseIterable {
    case week = "7 Days"
    case month = "30 Days"
    case year = "1 Year"
    
    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .year: return 365
        }
    }
    
    var startDate: Date {
        Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
    }
}

struct CategoryProgressView: View {
    let category: DrillCategory
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDateRange: DateRange = .year
    
    // Cached data to prevent recalculation
    @State private var cachedFilteredSessions: [PracticeSession] = []
    @State private var cachedChartData: [(String, [ChartDataPoint])] = []
    @State private var cachedOverallSuccessRate: Double = 0.0
    @State private var isDataLoaded = false
    
    // Query all sessions and filter in computed property for better performance
    @Query(sort: \PracticeSession.date, order: .reverse)
    private var allSessions: [PracticeSession]
    
    // Public initializer
    init(category: DrillCategory) {
        self.category = category
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with category info
                headerView
                
                // Date range picker
                dateRangePicker
                
                // Charts
                if cachedChartData.isEmpty && isDataLoaded {
                    emptyStateView
                } else if isDataLoaded {
                    chartsList
                } else {
                    loadingView
                }
                
                Spacer()
            }
            .background(theme.background)
            .navigationTitle(category.displayName)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(theme.primary)
                }
            }
            .ignoresSafeArea(.all, edges: .bottom)
        }
        .onAppear {
            loadData()
        }
        .onChange(of: selectedDateRange) { _, _ in
            loadData()
        }
        .onDisappear {
            // Clear cached data to prevent memory leaks
            clearCache()
        }
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading charts...")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
                .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func loadData() {
        // Perform heavy calculations in background
        Task {
            let startDate = selectedDateRange.startDate
            let filteredSessions = allSessions.filter { session in
                session.date >= startDate && session.drills.contains { $0.category == category }
            }
            
            let drillNames = Set(filteredSessions.flatMap { session in
                session.drills.filter { $0.category == category }.map { $0.name }
            })
            let actualDrillNames = Array(drillNames).sorted()
            
            let chartData = actualDrillNames.compactMap { drillName -> (String, [ChartDataPoint])? in
                let dataPoints = generateDataPoints(for: drillName, sessions: filteredSessions)
                return dataPoints.isEmpty ? nil : (drillName, dataPoints)
            }
            
            let overallSuccessRate = calculateOverallSuccessRate(sessions: filteredSessions)
            
            // Update UI on main thread
            await MainActor.run {
                self.cachedFilteredSessions = filteredSessions
                self.cachedChartData = chartData
                self.cachedOverallSuccessRate = overallSuccessRate
                self.isDataLoaded = true
            }
        }
    }
    
    private func clearCache() {
        cachedFilteredSessions.removeAll()
        cachedChartData.removeAll()
        cachedOverallSuccessRate = 0.0
        isDataLoaded = false
    }
    
    private func calculateOverallSuccessRate(sessions: [PracticeSession]) -> Double {
        let categoryDrills = sessions.flatMap { $0.drills }.filter { $0.category == category }
        let totalDrills = categoryDrills.count
        
        guard totalDrills > 0 else { return 0.0 }
        
        var totalSuccessRate = 0.0
        var validDrills = 0
        
        for drill in categoryDrills {
            if let maxScore = drill.maxScore, let actualScore = drill.actualScore, maxScore > 0 {
                let successRate = Double(actualScore) / Double(maxScore)
                totalSuccessRate += min(successRate, 1.0)
                validDrills += 1
            } else if let isCompleted = drill.isCompleted, isCompleted {
                totalSuccessRate += 1.0
                validDrills += 1
            }
        }
        
        return validDrills > 0 ? totalSuccessRate / Double(validDrills) : 0.0
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            // Category icon and stats
            HStack(spacing: 20) {
                Image(systemName: categoryIcon)
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                    .frame(width: 80, height: 80)
                    .background(categoryColor)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(category.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(theme.textPrimary)
                    
                    let totalDrills = cachedFilteredSessions.flatMap { $0.drills }.filter { $0.category == category }.count
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading) {
                            Text("Total Drills")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                            Text("\(totalDrills)")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.textPrimary)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Success Rate")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                            Text("\(Int(cachedOverallSuccessRate * 100))%")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(cachedOverallSuccessRate >= 0.7 ? theme.success : theme.warning)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(theme.cardBackground)
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .padding(.top)
    }
    
    private var dateRangePicker: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Time Period")
                    .font(.headline)
                    .foregroundColor(theme.textPrimary)
                Spacer()
            }
            
            Picker("Date Range", selection: $selectedDateRange) {
                ForEach(DateRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 50))
                .foregroundColor(theme.textSecondary)
            
            Text("No Data Available")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(theme.textPrimary)
            
            Text("Complete some \(category.displayName.lowercased()) drills to see progress charts")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var chartsList: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(Array(cachedChartData.enumerated()), id: \.offset) { index, chartItem in
                    DrillProgressChart(
                        drillName: chartItem.0,
                        dataPoints: chartItem.1,
                        color: categoryColor
                    )
                    .id("\(category.rawValue)-\(chartItem.0)-\(selectedDateRange.rawValue)")
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 100) // Extra padding for floating tab bar and safe area
        }
        .scrollIndicators(.hidden)
    }
    
    private func generateDataPoints(for drillName: String, sessions: [PracticeSession]) -> [ChartDataPoint] {
        let calendar = Calendar.current
        let startDate = selectedDateRange.startDate
        let endDate = Date()
        
        // Get all drills with this exact name in the date range
        let relevantDrills = sessions.flatMap { session in
            session.drills.filter { drill in
                drill.name == drillName && drill.category == category
            }.map { drill in
                (session.date, drill)
            }
        }
        
        // Group by day and calculate daily success rates
        let groupedByDay = Dictionary(grouping: relevantDrills) { item in
            calendar.startOfDay(for: item.0)
        }
        
        var dataPoints: [ChartDataPoint] = []
        var currentDate = calendar.startOfDay(for: startDate)
        
        while currentDate <= endDate {
            let drillsForDay = groupedByDay[currentDate] ?? []
            
            if !drillsForDay.isEmpty {
                // Calculate success rate based on actual scores vs max scores
                var totalSuccessRate = 0.0
                var validDrills = 0
                
                for (_, drill) in drillsForDay {
                    if let maxScore = drill.maxScore, let actualScore = drill.actualScore, maxScore > 0 {
                        let successRate = Double(actualScore) / Double(maxScore)
                        totalSuccessRate += min(successRate, 1.0) // Cap at 100%
                        validDrills += 1
                    } else if let isCompleted = drill.isCompleted, isCompleted {
                        // Fallback to completion status if no scores
                        totalSuccessRate += 1.0
                        validDrills += 1
                    }
                }
                
                if validDrills > 0 {
                    let avgSuccessRate = totalSuccessRate / Double(validDrills)
                    dataPoints.append(ChartDataPoint(
                        date: currentDate,
                        value: avgSuccessRate,
                        count: drillsForDay.count
                    ))
                }
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return dataPoints
    }
    
    private var categoryIcon: String {
        switch category {
        case .putting: return "target"
        case .chipping: return "figure.golf"
        case .pitching: return "sportscourt"
        case .irons: return "multiply.circle"
        case .driver: return "arrow.up.right"
        }
    }
    
    private var categoryColor: Color {
        switch category {
        case .putting: return theme.success
        case .chipping: return theme.warning
        case .pitching: return theme.primary
        case .driver: return theme.error
        case .irons: return theme.accent
        }
    }
}

struct ChartDataPoint: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let value: Double // Success rate (0.0 to 1.0)
    let count: Int // Number of drills
    
    static func == (lhs: ChartDataPoint, rhs: ChartDataPoint) -> Bool {
        lhs.date == rhs.date && lhs.value == rhs.value && lhs.count == rhs.count
    }
}

struct DrillProgressChart: View {
    let drillName: String
    let dataPoints: [ChartDataPoint]
    let color: Color
    @Environment(\.theme) private var theme
    
    // Cache computed values to prevent recalculation
    @State private var totalDrills: Int = 0
    @State private var avgSuccessRate: Double = 0.0
    @State private var latestSuccessRate: Int = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Chart header
            HStack {
                Text(drillName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Text("\(latestSuccessRate)%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
            
            // Chart
            if #available(iOS 16.0, *) {
                Chart(dataPoints) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Success Rate", point.value)
                    )
                    .foregroundStyle(color)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Success Rate", point.value)
                    )
                    .foregroundStyle(color.opacity(0.1))
                }
                .chartYScale(domain: 0...1)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text("\(Int(doubleValue * 100))%")
                                    .font(.caption)
                                    .foregroundStyle(theme.textSecondary)
                            }
                        }
                        AxisGridLine()
                            .foregroundStyle(theme.divider)
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .font(.caption)
                            .foregroundStyle(theme.textSecondary)
                        AxisGridLine()
                            .foregroundStyle(theme.divider)
                    }
                }
                .frame(height: 150)
            } else {
                // Fallback for iOS 15
                SimpleFallbackChart(dataPoints: dataPoints, color: color)
                    .frame(height: 150)
            }
            
            // Summary stats
            HStack {
                VStack(alignment: .leading) {
                    Text("Total Attempts")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                    Text("\(totalDrills)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(theme.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Average Success")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                    Text("\(Int(avgSuccessRate * 100))%")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(color)
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
        .onAppear {
            calculateStats()
        }
        .onChange(of: dataPoints) { _, _ in
            calculateStats()
        }
    }
    
    private func calculateStats() {
        totalDrills = dataPoints.reduce(0) { $0 + $1.count }
        avgSuccessRate = dataPoints.isEmpty ? 0.0 : dataPoints.map(\.value).reduce(0, +) / Double(dataPoints.count)
        latestSuccessRate = dataPoints.last.map { Int($0.value * 100) } ?? 0
    }
}

// Fallback chart for iOS 15
struct SimpleFallbackChart: View {
    let dataPoints: [ChartDataPoint]
    let color: Color
    @Environment(\.theme) private var theme
    @State private var chartPath: Path = Path()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(theme.divider, lineWidth: 1)
                    )
                
                if !dataPoints.isEmpty {
                    // Simple line chart
                    chartPath
                        .stroke(color, lineWidth: 2)
                } else {
                    Text("No data")
                        .foregroundColor(theme.textSecondary)
                }
            }
        }
        .onAppear {
            updateChartPath()
        }
        .onChange(of: dataPoints) { _, _ in
            updateChartPath()
        }
    }
    
    private func updateChartPath() {
        guard !dataPoints.isEmpty else {
            chartPath = Path()
            return
        }
        
        var path = Path()
        let width: CGFloat = 300 // Approximate width
        let height: CGFloat = 110 // Approximate height
        
        for (index, point) in dataPoints.enumerated() {
            let x = 20 + (CGFloat(index) / CGFloat(dataPoints.count - 1)) * width
            let y = 20 + (1 - CGFloat(point.value)) * height
            
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        chartPath = path
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PracticeSession.self, Drill.self, configurations: config)
    
    return NavigationView {
        CategoryProgressView(category: .putting)
            .modelContainer(container)
            .environmentObject(ThemeManager())
            .themed()
    }
} 