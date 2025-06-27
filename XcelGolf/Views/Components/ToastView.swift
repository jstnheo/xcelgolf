import SwiftUI

// MARK: - Toast Model
struct Toast: Identifiable, Equatable {
    let id = UUID()
    let type: ToastType
    let title: String
    let message: String?
    let duration: TimeInterval
    
    init(type: ToastType, title: String, message: String? = nil, duration: TimeInterval = 3.0) {
        self.type = type
        self.title = title
        self.message = message
        self.duration = duration
    }
}

enum ToastType {
    case success
    case error
    case info
    case warning
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }
    
    func color(for theme: any ColorTheme) -> Color {
        switch self {
        case .success: return theme.success
        case .error: return theme.error
        case .info: return theme.primary
        case .warning: return theme.warning
        }
    }
}

// MARK: - Toast Manager
class ToastManager: ObservableObject {
    @Published var toasts: [Toast] = []
    
    func show(_ toast: Toast) {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            toasts.append(toast)
        }
        
        // Auto-dismiss after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration) {
            self.dismiss(toast)
        }
    }
    
    func dismiss(_ toast: Toast) {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            toasts.removeAll { $0.id == toast.id }
        }
    }
    
    func dismissAll() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            toasts.removeAll()
        }
    }
    
    // Convenience methods
    func showSuccess(_ title: String, message: String? = nil, duration: TimeInterval = 2.5) {
        show(Toast(type: .success, title: title, message: message, duration: duration))
    }
    
    func showError(_ title: String, message: String? = nil, duration: TimeInterval = 4.0) {
        show(Toast(type: .error, title: title, message: message, duration: duration))
    }
    
    func showInfo(_ title: String, message: String? = nil, duration: TimeInterval = 3.0) {
        show(Toast(type: .info, title: title, message: message, duration: duration))
    }
    
    func showWarning(_ title: String, message: String? = nil, duration: TimeInterval = 3.5) {
        show(Toast(type: .warning, title: title, message: message, duration: duration))
    }
}

// MARK: - Toast View
struct ToastView: View {
    let toast: Toast
    let onDismiss: () -> Void
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.type.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(toast.type.color(for: theme))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(toast.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                
                if let message = toast.message {
                    Text(message)
                        .font(.system(size: 12))
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(theme.textSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.cardBackground)
                .shadow(color: theme.textPrimary.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(toast.type.color(for: theme).opacity(0.2), lineWidth: 1)
        )
        .onTapGesture {
            onDismiss()
        }
    }
}

// MARK: - Toast Container
struct ToastContainer: View {
    @ObservedObject var toastManager: ToastManager
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(toastManager.toasts) { toast in
                ToastView(toast: toast) {
                    toastManager.dismiss(toast)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

// MARK: - Toast Modifier
struct ToastModifier: ViewModifier {
    @ObservedObject var toastManager: ToastManager
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            VStack {
                ToastContainer(toastManager: toastManager)
                Spacer()
            }
        }
    }
}

extension View {
    func toast(manager: ToastManager) -> some View {
        self.modifier(ToastModifier(toastManager: manager))
    }
} 