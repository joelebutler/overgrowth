//
//  overgrowthApp.swift
//  overgrowth
//
//  Created by Joel Butler on 2/23/26.
//

import SwiftUI

@main
struct OvergrowthApp: App {
  @State private var gitState = GitState()
  var body: some Scene {
//    Window("Overgrowth", id: "mainWindow") {
//      ContentView()
//    }
    MenuBarExtra(.overgrowth, systemImage: "tree") {
      MenuView()
        .environment(gitState)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
          gitState.stopAccess()
        }
    }
  }
}
