//
//  Tab.swift
//  CursorDemo
//
//  Created by Justin Heo on 6/4/25.
//

import Foundation

enum TabModel: String, CaseIterable {
    case session = "figure.golf"
    case history = "note.text"
    case media = "video.fill"
    case settings = "gearshape"
    
    var title: String {
        switch self {
        case .session: "Session"
        case .history: "History"
        case .media: "Media"
        case .settings: "Settings"
        }
    }
}
