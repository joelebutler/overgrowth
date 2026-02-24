//
//  MenuView.swift
//  overgrowth
//
//  Created by Joel Butler on 2/23/26.
//

import SwiftUI

struct MenuView: View {
    var body: some View {
      VStack {
        Button("Quit") {
          NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut(KeyEquivalent("q"))
      }
    }
}

#Preview {
    MenuView()
}
