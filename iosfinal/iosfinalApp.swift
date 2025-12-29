//
//  iosfinalApp.swift
//  iosfinal
//
//  Created by user19 on 2025/12/17.
//

import SwiftUI
import TipKit

@main
struct iosfinalApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // Configure TipKit
                    try? Tips.configure([
                        .displayFrequency(.immediate),
                        .datastoreLocation(.applicationDefault)
                    ])
                }
        }
    }
}
