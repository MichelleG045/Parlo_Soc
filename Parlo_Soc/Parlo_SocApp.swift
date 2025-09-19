//
//  Parlo_SocApp.swift
//  Parlo_Soc
//
//  Created by Michelle Gurovith on 9/16/25.
//

import SwiftUI

@main
struct Parlo_SocApp: App {
    @StateObject private var appData = AppData()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appData)
        }
    }
}

