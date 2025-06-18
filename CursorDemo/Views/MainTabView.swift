import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var activeTab: TabModel = .session
    @Environment(\.theme) private var theme
    @StateObject private var sessionManager = SessionManager()
    
    // Cache views to prevent recreation on tab switches
    @StateObject private var viewCache = TabViewCache()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background
            theme.background
                .ignoresSafeArea()
            
            // Content based on active tab - extends full height
            TabContentView(selectedTab: activeTab, viewCache: viewCache)
                .environmentObject(sessionManager)
            
            // Custom Floating Tab Bar overlaid at bottom
            CustomTabBar(activeTab: $activeTab)
                .environmentObject(sessionManager)
                .padding(.horizontal)
                .padding(.bottom, 30) // Raised by 20 points from original 10
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            // Clear cache when app goes to background to free memory
            viewCache.clearCache()
        }
    }
}

// MARK: - View Cache for Performance
class TabViewCache: ObservableObject {
    private var cachedViews: [TabModel: AnyView] = [:]
    
    func getView(for tab: TabModel) -> AnyView {
        if let cachedView = cachedViews[tab] {
            return cachedView
        }
        
        let newView: AnyView
        switch tab {
        case .session:
            newView = AnyView(CurrentSessionView())
        case .history:
            newView = AnyView(HistoryView())
        case .media:
            newView = AnyView(MediaView())
        case .settings:
            newView = AnyView(SettingsView())
        }
        
        cachedViews[tab] = newView
        return newView
    }
    
    func clearCache() {
        cachedViews.removeAll()
    }
}

struct TabContentView: View {
    let selectedTab: TabModel
    let viewCache: TabViewCache
    
    var body: some View {
        // Use cached views to prevent recreation
        viewCache.getView(for: selectedTab)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [PracticeSession.self, Drill.self])
        .environmentObject(ThemeManager())
        .themed()
} 