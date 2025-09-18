//
//  Parlo_SocApp.swift
//  Parlo_Soc
//
//  Created by Michelle Gurovith on 9/17/25.
//

import SwiftUI

@main
struct Parlo_SocApp: App {
    @StateObject private var appData = AppData()   // ✅ Global app state
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appData)  // ✅ inject into root view
        }
    }
}

