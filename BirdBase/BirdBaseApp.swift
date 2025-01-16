//
//  BirdBaseApp.swift
//  BirdBase
//
//  Created by iMac 2019 on 16/01/2025.
//

import SwiftUI

@main
struct BirdBaseApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
