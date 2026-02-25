//
//  MenuView.swift
//  overgrowth
//
//  Created by Joel Butler on 2/23/26.
//

import SwiftUI
internal import UniformTypeIdentifiers

struct MenuView: View {
  @Environment(GitState.self) private var gitState
  @State private var showingImporter: Bool = false
  var body: some View {
    VStack {
      Text(gitState.repositoryURL?.lastPathComponent ?? "No Active Repository")
      Divider()
      Menu ("More...") {
        Button ("Locate Repository") {
          showingImporter = true
        }.keyboardShortcut("l")
      }
      Button("Quit") {
        NSApplication.shared.terminate(nil)
      }.keyboardShortcut("q")
    }.fileImporter(
      isPresented: $showingImporter,
      allowedContentTypes: [.folder],
      allowsMultipleSelection: false
    ) { result in
      handleGitDirectory(result: result)
    }
  }
  
  private func handleGitDirectory(result: Result<[URL], any Error>) {
    switch result {
    case .success(let urls):
      for url in urls {
        /* TODO: Look into safer later access methods. for now guarantees this is accessible at the time of calling */
        /* TODO: Ensure folder selected is a git repo*/
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        
        gitState.repositoryURL = urls.first
      }
    case .failure(let error):
      print(error.localizedDescription)
    }
  }
}

#Preview {
  MenuView()
}
