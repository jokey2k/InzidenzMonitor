//
//  ContentView.swift
//  InzidenzMonitor WatchKit Extension
//
//  Created by Markus Ullmann on 29.10.21.
//

import SwiftUI
import ClockKit

struct ContentView: View {
    @State var fetchState: String = ""

    var body: some View {
        VStack {
            Button("Update me") {
                self.fetchState = "Fetch started"
                do {
                    try IncidencesStore.shared.fetchData() { store in
                        if store == nil {
                            self.fetchState = "Fetch failed"
                            return
                        }
                        self.fetchState = "Fetch completed"

                        let server = CLKComplicationServer.sharedInstance()

                        for complication in server.activeComplications ?? [] {
                            server.reloadTimeline(for: complication)
                        }
                    }
                } catch {
                    if let fetchError = error as? IncidenceFetchError {
                        self.fetchState = fetchError.localizedDescription
                    } else {
                        self.fetchState = "Fetch failed"
                    }
                }
            }
            Text(self.fetchState)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
