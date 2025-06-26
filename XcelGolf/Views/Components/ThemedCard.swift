import SwiftUI

struct ThemedCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 12
    var shadowRadius: CGFloat = 2
    var shadowOpacity: Double = 0.1
    
    @Environment(\.theme) private var theme
    
    init(
        padding: CGFloat = 16,
        cornerRadius: CGFloat = 12,
        shadowRadius: CGFloat = 2,
        shadowOpacity: Double = 0.1,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.shadowOpacity = shadowOpacity
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(theme.cardBackground)
            .cornerRadius(cornerRadius)
            .shadow(
                color: theme.textPrimary.opacity(shadowOpacity),
                radius: shadowRadius,
                x: 0,
                y: 1
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(theme.divider, lineWidth: 0.5)
            )
    }
}

// MARK: - Themed Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.theme) private var theme
    var isLoading: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(theme.surface)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(theme.primary)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .disabled(isLoading)
            .overlay(
                Group {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: theme.surface))
                            .scaleEffect(0.8)
                    }
                }
            )
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.theme) private var theme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(theme.primary)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(theme.secondary)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(theme.primary, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct DestructiveButtonStyle: ButtonStyle {
    @Environment(\.theme) private var theme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(theme.surface)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(theme.error)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Themed Section Header
struct ThemedSectionHeader: View {
    let title: String
    let subtitle: String?
    
    @Environment(\.theme) private var theme
    
    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.textPrimary)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
            }
        }
    }
}

// MARK: - Score Circle Component
struct ScoreCircle: View {
    let score: Int
    let maxScore: Int
    let size: CGFloat
    
    @Environment(\.theme) private var theme
    
    init(score: Int, maxScore: Int, size: CGFloat = 60) {
        self.score = score
        self.maxScore = maxScore
        self.size = size
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(theme.divider, lineWidth: 2)
                .frame(width: size, height: size)
            
            Circle()
                .trim(from: 0, to: CGFloat(score) / CGFloat(maxScore))
                .stroke(
                    theme.primary,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: size - 4, height: size - 4)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: score)
            
            VStack(spacing: 0) {
                Text("\(score)")
                    .font(.system(size: size * 0.25, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                
                Text("/ \(maxScore)")
                    .font(.system(size: size * 0.15))
                    .foregroundColor(theme.textSecondary)
            }
        }
    }
}

// MARK: - View Extensions
extension View {
    func themedCard(
        padding: CGFloat = 16,
        cornerRadius: CGFloat = 12,
        shadowRadius: CGFloat = 2,
        shadowOpacity: Double = 0.1
    ) -> some View {
        ThemedCard(
            padding: padding,
            cornerRadius: cornerRadius,
            shadowRadius: shadowRadius,
            shadowOpacity: shadowOpacity
        ) {
            self
        }
    }
    
    func primaryButton(isLoading: Bool = false) -> some View {
        self.buttonStyle(PrimaryButtonStyle(isLoading: isLoading))
    }
    
    func secondaryButton() -> some View {
        self.buttonStyle(SecondaryButtonStyle())
    }
    
    func destructiveButton() -> some View {
        self.buttonStyle(DestructiveButtonStyle())
    }
} 