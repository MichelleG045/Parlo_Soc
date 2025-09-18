//
//  SocialStubs.swift
//  Parlo_Soc
//
//  Temporary mock stubs so the project builds.
//  Replace with real implementations later.
//

import Foundation
import SwiftUI

// MARK: - Repository + VM Stubs

/// Mock SocialRepository
final class SocialRepository { }

/// Mock RequestsVM
@MainActor
final class RequestsVM: ObservableObject {
    @Published var incoming: [FriendRequest] = []
    init(repo: SocialRepository) { }
}

// MARK: - View Stubs

/// Mock RequestsView
struct RequestsView: View {
    var body: some View {
        Text("RequestsView placeholder")
            .foregroundColor(.gray)
            .padding()
    }
}

/// Mock NetworkGraph
struct NetworkGraph: View {
    var body: some View {
        Text("NetworkGraph placeholder")
            .foregroundColor(.gray)
            .padding()
    }
}

/// Mock AddingManager
struct AddingManager: View {
    var body: some View {
        Text("AddingManager placeholder")
            .foregroundColor(.gray)
            .padding()
    }
}

// MARK: - Data Model Stubs

/// Stub for weekly insights
struct WeekInsight: Codable, Identifiable {
    var id: UUID = UUID()
    let summary: String = "Weekly summary placeholder"
}

/// Stub for monthly insights
struct MonthInsight: Codable, Identifiable {
    var id: UUID = UUID()
    let summary: String = "Monthly summary placeholder"
}

/// Stub for badges
struct Badge: Codable, Identifiable {
    var id: UUID = UUID()
    let title: String = "Badge placeholder"
}

