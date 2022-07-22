//
//  ShutterSyncApp.swift
//  ShutterSync
//
//  Created by James Perlman on 7/21/22.
//

import SwiftUI

@main
struct ShutterSyncApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
