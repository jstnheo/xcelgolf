//
//  CustomTabBar.swift
//  Floating Tab Bar
//
//  Created by Balaji Venkatesh on 17/08/24.
//

import SwiftUI

struct CustomTabBar: View {
    @Binding var activeTab: TabModel
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var toastManager: ToastManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.theme) private var theme
    
    /// For Matched Geometry Effect
    @Namespace private var animation
    
    /// View Properties
    @State private var tabLocation: CGRect = .zero
    @State private var status: Bool = true // Track status locally
    @State private var showingTrashConfirmation = false
    
    var body: some View {
        // Track changes in activeTab and update status accordingly
        let isSessionTabActive = activeTab == .session
        
        HStack(spacing: !isSessionTabActive ? 0 : 12) {
            HStack(spacing: 0) {
                ForEach(TabModel.allCases, id: \.rawValue) { tab in
                    Button {
                        activeTab = tab
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: tab.rawValue)
                                .font(.title3)
                                .frame(width: 30, height: 30)
                            
                            if activeTab == tab {
                                Text(tab.title)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .lineLimit(1)
                            }
                        }
                        .foregroundStyle(activeTab == tab ? theme.surface : theme.textSecondary)
                        .padding(.vertical, 6)
                        .padding(.leading, 10)
                        .padding(.trailing, 15)
                        .contentShape(.rect)
                        .background {
                            if activeTab == tab {
                                Capsule()
                                    .fill(.clear)
                                    .onGeometryChange(for: CGRect.self, of: {
                                        $0.frame(in: .named("TABBARVIEW"))
                                    }, action: { newValue in
                                        tabLocation = newValue
                                    })
                                    .matchedGeometryEffect(id: "ACTIVETAB", in: animation)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(alignment: .leading) {
                Capsule()
                    .fill(theme.primary.gradient)
                    .frame(width: tabLocation.width, height: tabLocation.height)
                    .offset(x: tabLocation.minX)
            }
            .coordinateSpace(.named("TABBARVIEW"))
            .padding(.horizontal, 5)
            .frame(height: 52)
            .background(
                theme.cardBackground,
                in: .capsule
            )
            .overlay(
                Capsule()
                    .stroke(theme.divider, lineWidth: 1)
            )
            .zIndex(10)
            
            // Pass the status to the FloatingButton
            floatingButton($status)
        }
        .animation(.smooth(duration: 0.3, extraBounce: 0), value: activeTab)
        .frame(maxWidth: .infinity)
        // Use the onChange modifier to update status when activeTab changes
        .onChange(of: activeTab) { _, newTab in
                  // This will ensure that the status gets updated immediately when the tab changes
                  withAnimation {
                      status = newTab == .session
                  }
              }
        .alert("Trash Session", isPresented: $showingTrashConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Trash", role: .destructive) {
                sessionManager.clearSession(toastManager: toastManager, showToast: true)
            }
        } message: {
            Text("This will delete all unsaved drill results. This action cannot be undone.")
        }
    }
    
    @ViewBuilder
    func floatingButton(_ status: Binding<Bool>) -> some View {
        FloatingButton(
            status: status,
            shouldCollapse: $sessionManager.shouldCollapseFloatingButton,
            actions: {
                FloatingAction(symbol: "checkmark.circle.fill", tint: theme.surface, background: theme.success) {
                    if sessionManager.currentSession != nil {
                        sessionManager.saveSessionToSwiftData(modelContext: modelContext, toastManager: toastManager)
                    }
                }
                FloatingAction(symbol: "trash.fill", tint: theme.surface, background: theme.error) {
                    if sessionManager.currentSession != nil {
                        showingTrashConfirmation = true
                    }
                }
            }, label: { isExpanded in
                Image(systemName: "plus")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(theme.surface)
                    .rotationEffect(.init(degrees: isExpanded ? 45 : 0))
                    .scaleEffect(1.02)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(hasUnsavedSession ? theme.warning : theme.primary, in: .circle)
                
                /// Scaling Effect When Expanded
                    .scaleEffect(isExpanded ? 0.9 : 1)
            })
        .allowsHitTesting(status.wrappedValue)
        .offset(x: status.wrappedValue ? 0 : -20)
        .padding(.leading, status.wrappedValue ? 0 : -42)
    }
    
    private var hasUnsavedSession: Bool {
        sessionManager.currentSession != nil && !sessionManager.currentSession!.drillResults.isEmpty
    }
}
