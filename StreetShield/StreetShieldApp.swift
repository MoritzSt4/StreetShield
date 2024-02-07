//
//  StreetShieldApp.swift
//  StreetShield
//
//  Created by Moritz on 07.02.24.
//

import SwiftUI

@main
struct StreetShieldApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
