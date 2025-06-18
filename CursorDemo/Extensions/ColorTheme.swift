import SwiftUI

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// Creates an adaptive color that changes based on light/dark mode
    static func adaptive(light: Color, dark: Color) -> Color {
        return Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
}

// MARK: - Color Theme Protocol
protocol ColorTheme {
    var primary: Color { get }
    var primaryLight: Color { get }
    var primaryDark: Color { get }
    var secondary: Color { get }
    var accent: Color { get }
    var background: Color { get }
    var surface: Color { get }
    var cardBackground: Color { get }
    var textPrimary: Color { get }
    var textSecondary: Color { get }
    var success: Color { get }
    var warning: Color { get }
    var error: Color { get }
    var divider: Color { get }
}

// MARK: - Sage Green Theme
struct SageGreenTheme: ColorTheme {
    let primary = Color.adaptive(
        light: Color(hex: "#8F9779"),
        dark: Color(hex: "#A8C686")
    )
    let primaryLight = Color.adaptive(
        light: Color(hex: "#B9D0AA"),
        dark: Color(hex: "#8F9779")
    )
    let primaryDark = Color.adaptive(
        light: Color(hex: "#78866B"),
        dark: Color(hex: "#6B7A65")
    )
    let secondary = Color.adaptive(
        light: Color(hex: "#9BB3A8"),
        dark: Color(hex: "#7A9B8E")
    )
    let accent = Color.adaptive(
        light: Color(hex: "#A8C686"),
        dark: Color(hex: "#B9D0AA")
    )
    let background = Color.adaptive(
        light: Color(hex: "#F5F7F2"),
        dark: Color(hex: "#1C1E1A")
    )
    let surface = Color.adaptive(
        light: Color(hex: "#FAFBF8"),
        dark: Color(hex: "#252822")
    )
    let cardBackground = Color.adaptive(
        light: Color(hex: "#FFFFFF"),
        dark: Color(hex: "#2D332A")
    )
    let textPrimary = Color.adaptive(
        light: Color(hex: "#2D3E2A"),
        dark: Color(hex: "#E8F0E5")
    )
    let textSecondary = Color.adaptive(
        light: Color(hex: "#6B7A65"),
        dark: Color(hex: "#A8C686")
    )
    let success = Color.adaptive(
        light: Color(hex: "#7FA85C"),
        dark: Color(hex: "#9BC470")
    )
    let warning = Color.adaptive(
        light: Color(hex: "#D4B896"),
        dark: Color(hex: "#E6C9A8")
    )
    let error = Color.adaptive(
        light: Color(hex: "#C69C9C"),
        dark: Color(hex: "#E8B4B4")
    )
    let divider = Color.adaptive(
        light: Color(hex: "#D1DBD4"),
        dark: Color(hex: "#3A4237")
    )
}

// MARK: - Blue Theme
struct BlueTheme: ColorTheme {
    let primary = Color.adaptive(
        light: Color(hex: "#4A90E2"),
        dark: Color(hex: "#6FA8F5")
    )
    let primaryLight = Color.adaptive(
        light: Color(hex: "#6FA8F5"),
        dark: Color(hex: "#4A90E2")
    )
    let primaryDark = Color.adaptive(
        light: Color(hex: "#357ABD"),
        dark: Color(hex: "#2E6BA8")
    )
    let secondary = Color.adaptive(
        light: Color(hex: "#7B68EE"),
        dark: Color(hex: "#9B88FF")
    )
    let accent = Color.adaptive(
        light: Color(hex: "#FF6B6B"),
        dark: Color(hex: "#FF8A8A")
    )
    let background = Color.adaptive(
        light: Color(hex: "#F8FAFE"),
        dark: Color(hex: "#0F1419")
    )
    let surface = Color.adaptive(
        light: Color(hex: "#FFFFFF"),
        dark: Color(hex: "#1A1F2E")
    )
    let cardBackground = Color.adaptive(
        light: Color(hex: "#FFFFFF"),
        dark: Color(hex: "#252B3A")
    )
    let textPrimary = Color.adaptive(
        light: Color(hex: "#1A365D"),
        dark: Color(hex: "#E2E8F0")
    )
    let textSecondary = Color.adaptive(
        light: Color(hex: "#4A5568"),
        dark: Color(hex: "#A0AEC0")
    )
    let success = Color.adaptive(
        light: Color(hex: "#48BB78"),
        dark: Color(hex: "#68D391")
    )
    let warning = Color.adaptive(
        light: Color(hex: "#ED8936"),
        dark: Color(hex: "#F6AD55")
    )
    let error = Color.adaptive(
        light: Color(hex: "#F56565"),
        dark: Color(hex: "#FC8181")
    )
    let divider = Color.adaptive(
        light: Color(hex: "#E2E8F0"),
        dark: Color(hex: "#2D3748")
    )
}

// MARK: - Minimal Theme
struct MinimalTheme: ColorTheme {
    let primary = Color.adaptive(
        light: Color(hex: "#2D3748"),
        dark: Color(hex: "#E2E8F0")
    )
    let primaryLight = Color.adaptive(
        light: Color(hex: "#4A5568"),
        dark: Color(hex: "#CBD5E0")
    )
    let primaryDark = Color.adaptive(
        light: Color(hex: "#1A202C"),
        dark: Color(hex: "#F7FAFC")
    )
    let secondary = Color.adaptive(
        light: Color(hex: "#718096"),
        dark: Color(hex: "#A0AEC0")
    )
    let accent = Color.adaptive(
        light: Color(hex: "#3182CE"),
        dark: Color(hex: "#63B3ED")
    )
    let background = Color.adaptive(
        light: Color(hex: "#FFFFFF"),
        dark: Color(hex: "#000000")
    )
    let surface = Color.adaptive(
        light: Color(hex: "#F7FAFC"),
        dark: Color(hex: "#1A202C")
    )
    let cardBackground = Color.adaptive(
        light: Color(hex: "#FFFFFF"),
        dark: Color(hex: "#2D3748")
    )
    let textPrimary = Color.adaptive(
        light: Color(hex: "#1A202C"),
        dark: Color(hex: "#F7FAFC")
    )
    let textSecondary = Color.adaptive(
        light: Color(hex: "#4A5568"),
        dark: Color(hex: "#A0AEC0")
    )
    let success = Color.adaptive(
        light: Color(hex: "#38A169"),
        dark: Color(hex: "#68D391")
    )
    let warning = Color.adaptive(
        light: Color(hex: "#D69E2E"),
        dark: Color(hex: "#F6E05E")
    )
    let error = Color.adaptive(
        light: Color(hex: "#E53E3E"),
        dark: Color(hex: "#FC8181")
    )
    let divider = Color.adaptive(
        light: Color(hex: "#E2E8F0"),
        dark: Color(hex: "#4A5568")
    )
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    @Published var currentTheme: ColorTheme = BlueTheme()
    
    func useSageGreen() {
        currentTheme = SageGreenTheme()
    }
    
    func useBlue() {
        currentTheme = BlueTheme()
    }
    
    func useMinimal() {
        currentTheme = MinimalTheme()
    }
}

// MARK: - Environment Key
struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue: ColorTheme = BlueTheme()
}

struct ThemeManagerEnvironmentKey: EnvironmentKey {
    static let defaultValue: ThemeManager? = nil
}

extension EnvironmentValues {
    var theme: ColorTheme {
        get { 
            // Try to get from ThemeManager first, fall back to direct theme
            if let themeManager = self[ThemeManagerEnvironmentKey.self] {
                return themeManager.currentTheme
            }
            return self[ThemeEnvironmentKey.self] 
        }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
    
    var themeManager: ThemeManager? {
        get { self[ThemeManagerEnvironmentKey.self] }
        set { self[ThemeManagerEnvironmentKey.self] = newValue }
    }
}

// MARK: - View Extensions
struct ThemedView<Content: View>: View {
    let content: Content
    let themeManager: ThemeManager?
    
    init(themeManager: ThemeManager? = nil, @ViewBuilder content: () -> Content) {
        self.themeManager = themeManager
        self.content = content()
    }
    
    var body: some View {
        content
            .environment(\.themeManager, themeManager)
            .environment(\.theme, themeManager?.currentTheme ?? BlueTheme())
    }
}

extension View {
    func themed() -> some View {
        ThemedView { self }
    }
    
    func withThemeManager(_ themeManager: ThemeManager) -> some View {
        ThemedView(themeManager: themeManager) { self }
    }
} 