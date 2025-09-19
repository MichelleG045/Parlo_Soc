//
//  SocialStubs.swift
//  Parlo_Soc
//
//  Created by Michelle Gurovith on 9/17/25.
//

import Foundation
import SwiftUI


final class SocialRepository { }

@MainActor
final class RequestsVM: ObservableObject {
    @Published var incoming: [FriendRequest] = []
    init(repo: SocialRepository) { }
}


struct RequestsView: View {
    var body: some View {
        Text("RequestsView placeholder")
            .foregroundColor(.gray)
            .padding()
    }
}

struct NetworkGraph: View {
    var body: some View {
        Text("NetworkGraph placeholder")
            .foregroundColor(.gray)
            .padding()
    }
}

struct AddingManager: View {
    var body: some View {
        Text("AddingManager placeholder")
            .foregroundColor(.gray)
            .padding()
    }
}


struct WeekInsight: Codable, Identifiable {
    var id: UUID = UUID()
    let summary: String = "Weekly summary placeholder"
}


struct MonthInsight: Codable, Identifiable {
    var id: UUID = UUID()
    let summary: String = "Monthly summary placeholder"
}

struct Badge: Codable, Identifiable {
    var id: UUID = UUID()
    let title: String = "Badge placeholder"
}

