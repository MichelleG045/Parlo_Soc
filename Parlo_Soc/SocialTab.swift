//
//  SocialTab.swift
//  echo
//
//  Created by Max Eisenberg on 9/10/25.
//

import SwiftUI

enum SocialView {
    case feed, network
}

struct SocialTab: View {
    // ✅ Use mock SocialRepository directly instead of @Root
    private let repo = SocialRepository()
    @StateObject private var requestsVM: RequestsVM

    init() {
        let repo = SocialRepository()
        _requestsVM = StateObject(wrappedValue: RequestsVM(repo: repo))
    }

    @State var view: SocialView = .feed
    @State var addFriendSheet = false
    @State var showRequests = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header - switch between feed and network
                HStack(alignment: .center) {
                    Button {
                        view = (view == .feed ? .network : .feed)
                    } label: {
                        if view == .feed {
                            Image(systemName: "globe")
                        } else {
                            Image(systemName: "house")
                        }
                    }
                }

                Spacer()

                // Notifications
                HStack(spacing: 20) {
                    Button {
                        showRequests = true
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell.fill")
                            if requestsVM.incoming.count > 0 {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 6, y: -6)
                            }
                        }
                    }
                }
                .sheet(isPresented: $showRequests) {
                    RequestsView() // ✅ placeholder from SocialStubs
                }

                Spacer()

                // Main content
                if view == .feed {
                    MainSocialFeed() // ✅ your feed screen
                } else {
                    NetworkGraph() // ✅ placeholder from SocialStubs
                }
            }
        }
    }
}
