//
//  StreetShieldApp.swift
//  StreetShield
//
//  Created by Moritz on 07.02.24.
//

import SwiftUI

@main
struct StreetShieldApp: App {
    @State private var currentBrightness = UIScreen.main.brightness
    
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView(currentBrightness: $currentBrightness)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    // Hier wird Code aufgerufen, wenn die App den aktiven Zustand verliert
                    UIScreen.main.brightness = currentBrightness
                }
        }
    }
}
