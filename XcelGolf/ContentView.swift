//
//  ContentView.swift
//  CursorDemo
//
//  Created by Justin Heo on 6/2/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        MainTabView()
            .environmentObject(themeManager)
            .withThemeManager(themeManager)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PracticeSession.self, Drill.self, configurations: config)
    
    return ContentView()
        .modelContainer(container)
        .environmentObject(ThemeManager())
        .themed()
}
