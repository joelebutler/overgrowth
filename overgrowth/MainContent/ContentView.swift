//
//  ContentView.swift
//  overgrowth
//
//  Created by Joel Butler on 2/23/26.
//

import SwiftUI

struct ContentView: View {
  var body: some View {
    VStack {
    Image(systemName: "tree.fill")
      .imageScale(.large)
      .symbolRenderingMode(.multicolor)
    Text("This is the future home of overgrowth's contents.")
    }
    .padding()
  }
}

#Preview {
    ContentView()
}
