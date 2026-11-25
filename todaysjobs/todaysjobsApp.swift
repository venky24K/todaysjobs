//
//  todaysjobsApp.swift
//  todaysjobs
//
//  Created by vardhan on 25/11/26.
//

import SwiftUI

@main
struct todaysjobsApp: App {
    @State private var store = JobStore()

    var body: some Scene {
        WindowGroup {
            JobListView()
                .environment(store)
        }
    }
}
