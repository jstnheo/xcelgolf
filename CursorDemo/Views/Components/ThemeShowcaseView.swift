import SwiftUI

struct ThemeShowcaseView: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject var themeManager: ThemeManager
    @State private var sampleScore = 3
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Theme Selector
                    VStack(alignment: .leading, spacing: 12) {
                        ThemedSectionHeader("Theme Selection")
                        
                        HStack(spacing: 12) {
                            Button("Sage Green") {
                                themeManager.useSageGreen()
                            }
                            .primaryButton()
                            
                            Button("Blue") {
                                themeManager.useBlue()
                            }
                            .secondaryButton()
                            
                            Button("Minimal") {
                                themeManager.useMinimal()
                            }
                            .secondaryButton()
                        }
                    }
                    .themedCard()
                    
                    // Color Palette Display
                    VStack(alignment: .leading, spacing: 12) {
                        ThemedSectionHeader("Color Palette")
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                            ColorSwatch("Primary", color: theme.primary)
                            ColorSwatch("Primary Light", color: theme.primaryLight)
                            ColorSwatch("Primary Dark", color: theme.primaryDark)
                            ColorSwatch("Secondary", color: theme.secondary)
                            ColorSwatch("Accent", color: theme.accent)
                            ColorSwatch("Success", color: theme.success)
                            ColorSwatch("Warning", color: theme.warning)
                            ColorSwatch("Error", color: theme.error)
                            ColorSwatch("Background", color: theme.background)
                        }
                    }
                    .themedCard()
                    
                    // Sample Drill Card
                    VStack(alignment: .leading, spacing: 12) {
                        ThemedSectionHeader("Sample Drill Card")
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("3-Foot Putting")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(theme.textPrimary)
                                
                                Text("Practice putting from 3 feet")
                                    .font(.subheadline)
                                    .foregroundColor(theme.textSecondary)
                                
                                HStack {
                                    Image(systemName: "scope")
                                        .foregroundColor(theme.primary)
                                    Text("Putting")
                                        .font(.caption)
                                        .foregroundColor(theme.textSecondary)
                                }
                            }
                            
                            Spacer()
                            
                            ScoreCircle(score: sampleScore, maxScore: 5, size: 60)
                        }
                        
                        HStack {
                            Button("Decrease") {
                                if sampleScore > 0 {
                                    sampleScore -= 1
                                }
                            }
                            .secondaryButton()
                            
                            Spacer()
                            
                            Button("Increase") {
                                if sampleScore < 5 {
                                    sampleScore += 1
                                }
                            }
                            .primaryButton()
                        }
                    }
                    .themedCard()
                    
                    // Button Styles
                    VStack(alignment: .leading, spacing: 12) {
                        ThemedSectionHeader("Button Styles")
                        
                        VStack(spacing: 12) {
                            Button("Primary Button") { }
                                .primaryButton()
                            
                            Button("Secondary Button") { }
                                .secondaryButton()
                            
                            Button("Destructive Button") { }
                                .destructiveButton()
                        }
                    }
                    .themedCard()
                    
                    // Typography & Text Colors
                    VStack(alignment: .leading, spacing: 12) {
                        ThemedSectionHeader("Typography")
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Primary Text")
                                .font(.headline)
                                .foregroundColor(theme.textPrimary)
                            
                            Text("Secondary text for descriptions and subtitles")
                                .font(.subheadline)
                                .foregroundColor(theme.textSecondary)
                            
                            Text("Success message")
                                .font(.body)
                                .foregroundColor(theme.success)
                            
                            Text("Warning message")
                                .font(.body)
                                .foregroundColor(theme.warning)
                            
                            Text("Error message")
                                .font(.body)
                                .foregroundColor(theme.error)
                        }
                    }
                    .themedCard()
                }
                .padding()
                .padding(.bottom, 100) // Extra space for tab bar
            }
            .scrollIndicators(.hidden)
            .background(theme.background)
            .navigationTitle("Theme Showcase")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct ColorSwatch: View {
    let name: String
    let color: Color
    
    @Environment(\.theme) private var theme
    
    init(_ name: String, color: Color) {
        self.name = name
        self.color = color
    }
    
    var body: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.divider, lineWidth: 1)
                )
            
            Text(name)
                .font(.caption)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    ThemeShowcaseView()
        .environmentObject(ThemeManager())
        .themed()
} 