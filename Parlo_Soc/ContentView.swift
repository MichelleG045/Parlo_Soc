//
//  ContentView.swift
//  Parlo_Soc
//
//  Created by Michelle Gurovith on 9/17/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appData = AppData()
    
    var body: some View {
        MainSocialFeed()
            .environmentObject(appData)
            .onAppear {
                if appData.repo == nil {
                    appData.repo = MainSocialFeedRepository()
                }
            }
    }
}

#Preview {
    ContentView()
}
