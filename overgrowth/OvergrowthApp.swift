//
//  overgrowthApp.swift
//  overgrowth
//
//  Created by Joel Butler on 2/23/26.
//

import SwiftUI

@main
struct OvergrowthApp: App {
  var body: some Scene {
    Window("Overgrowth", id: "mainWindow") {
      ContentView()
    }
    MenuBarExtra("Overgrowth", systemImage: "tree") {
      MenuView()
    }
  }
}
