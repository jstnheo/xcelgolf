import SwiftUI

struct MediaView: View {
    @Environment(\.theme) private var theme
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "video.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(theme.primary)
                
                Text("Media")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(theme.textPrimary)
                
                Text("Coming Soon")
                    .font(.title2)
                    .foregroundColor(theme.textSecondary)
                
                Text("Practice videos, tutorials, and\ntechnique analysis will be available here.")
                    .font(.body)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.background)
            .navigationTitle("Media")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    MediaView()
        .environmentObject(ThemeManager())
        .themed()
} 