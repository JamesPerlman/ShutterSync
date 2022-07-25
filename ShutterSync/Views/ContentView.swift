//
//  ContentView.swift
//  ShutterSync
//
//  Created by James Perlman on 7/21/22.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @StateObject var session = MultipeerSession()
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Text("Connected Devices:")
                Text(String(describing: session.connectedPeers.map(\.displayName)))
                
                Divider()
                
                HStack {
                    ForEach(NamedColor.allCases, id: \.self) { color in
                        Button(color.rawValue) {
                            session.send(color: color)
                        }
                        .padding()
                    }
                }
                Spacer()
            }
            .padding()
            .background(session.currentColor.map(\.color) ?? .clear)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
