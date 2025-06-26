//
//  FloatingButton.swift
//  Floating Tab Bar
//
//  Created by Justin Heo on 1/30/25.
//

import SwiftUI

struct FloatingButton<Label: View>: View {
    
    var buttonSize: CGFloat
    var actions: [FloatingAction]
    var label: (Bool) -> Label
    @State private var isExpanded: Bool = false // Local state to control expansion
    @Binding var status: Bool // Use a binding to control whether the floating button should expand or collapse
    @State private var hapticTriggered: Bool = false // State to track whether haptic feedback was triggered
    @Environment(\.theme) private var theme
    
    init(
        buttonSize: CGFloat = 50,
        status: Binding<Bool>,  // Accept status as a binding
        @FloatingActionBuilder actions: @escaping () -> [FloatingAction],
        @ViewBuilder label: @escaping (Bool) -> Label
    ) {
        self.buttonSize = buttonSize
        self._status = status // Bind the passed status here
        self.actions = actions()
        self.label = label
    }
    
    /// View Properties
    @State private var dragLocataion: CGPoint = .zero
    @State private var selectedAction: FloatingAction?
    @GestureState private var isDragging: Bool = false
    
    var body: some View {
        Button {
            // Tapping Haptic
            UIImpactFeedbackGenerator(style: .light).impactOccurred()  // Light haptic feedback on tap
            isExpanded.toggle() // Toggle the expanded state when tapped
        } label: {
            label(isExpanded)
                .frame(width: buttonSize, height: buttonSize)
                .contentShape(.rect)
        }
        .buttonStyle(NoAnimationButtonStyle())
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.3)
                .onEnded { _ in
                    // Long Press Haptic
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()  // Stronger haptic feedback for long press
                    isExpanded = true
                }.sequenced(before: DragGesture().updating($isDragging, body: { _, out, _ in
                    out = true
                }).onChanged { value in
                    guard isExpanded else { return }
                    dragLocataion = value.location
                    
                }.onEnded { _ in
                    Task {
                        if let selectedAction {
                            selectedAction.action()
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()  // Light haptic feedback on tap
                            isExpanded = false
                        }
                        selectedAction = nil
                        dragLocataion = .zero
                    }
                })
        )
        .background {
            ZStack {
                ForEach(Array(actions.enumerated()), id: \.element.id) { index, action in
                    ActionView(action, at: index)
                        .opacity(isExpanded && status ? 1 : 0) // Apply opacity change here for actions
                        .animation(.easeInOut(duration: 0.3), value: isExpanded) // Smooth animation for opacity
                }
            }
            .frame(width: buttonSize, height: buttonSize)
        }
        .coordinateSpace(.named("FLOATING_VIEW"))
        .animation(.snappy(duration: 0.4, extraBounce: 0), value: isExpanded)
        
        // Observe changes in status and reset isExpanded if status is false
        .onChange(of: status) { _, newStatus in
            if !newStatus {
                isExpanded = false // Reset the expanded state when status is false
            }
        }
    }
    
    /// Action View
    @ViewBuilder
    func ActionView(_ action: FloatingAction, at index: Int) -> some View {
        Button {
            action.action()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()  // Light haptic feedback on tap
            isExpanded = false
        } label: {
            Image(systemName: action.symbol)
                .font(action.font)
                .foregroundStyle(action.tint)
                .frame(width: buttonSize, height: buttonSize)
                .background(action.background, in: .circle)
                .contentShape(.circle)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!isExpanded)
        .animation(.snappy(duration: 0.3, extraBounce: 0)) { content in
            content
                .scaleEffect(selectedAction?.id == action.id ? 1.25 : 1)
        }
        .background {
            GeometryReader { geometry in
                let rect = geometry.frame(in: .named("FLOATING_VIEW"))
                
                Color.clear
                    .onChange(of: dragLocataion) { oldValue, newValue in
                        if isExpanded {
                            // Check if the drag location is inside any action's rect
                            if rect.contains(newValue) {
                                // User has dragged to an action
                                selectedAction = action
                                
                                // Only trigger haptic once if the location has changed
                                if oldValue != newValue {
                                    if !hapticTriggered { // If haptic feedback hasn't been triggered
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        hapticTriggered = true // Set haptic feedback as triggered
                                    }
                                }
                            } else {
                                // Check if it has gone out of the rect
                                if selectedAction?.id == action.id && !rect.contains(newValue) {
                                    selectedAction = nil
                                    hapticTriggered = false // Reset haptic trigger when leaving the action
                                }
                            }
                        }
                    }
            }
        }
        .offset(y: isExpanded ? -CGFloat(index + 1) * (buttonSize + 10) : 0)
        .animation(.snappy(duration: 0.4, extraBounce: 0), value: isExpanded)
    }
    
    private var offset: CGFloat {
        let buttonSize = buttonSize + 10
        return Double(actions.count) * buttonSize
    }
}

/// Custom Button Styles
fileprivate struct NoAnimationButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

fileprivate struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ?  0.9 : 1)
            .animation(.snappy(duration: 0.3, extraBounce: 0), value: configuration.isPressed)
    }
}

struct FloatingAction: Identifiable {
    private(set) var id: UUID = .init()
    var symbol: String
    var font: Font = .title3
    var tint: Color = .white
    var background: Color = .black
    var action: () -> ()
    var isHidden: Bool = true
    
    // Theme-aware initializer
    init(
        symbol: String,
        font: Font = .title3,
        tint: Color = .white,
        background: Color? = nil,
        action: @escaping () -> (),
        isHidden: Bool = true
    ) {
        self.symbol = symbol
        self.font = font
        self.tint = tint
        self.background = background ?? .black
        self.action = action
        self.isHidden = isHidden
    }
}

@resultBuilder
struct FloatingActionBuilder {
    static func buildBlock(_ components: FloatingAction...) -> [FloatingAction] {
        components.compactMap { $0 }
    }
}
