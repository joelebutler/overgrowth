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
      Menu(
        "Repository: \(gitState.activeRepository?.lastPathComponent ?? "No Active Repository")"
      ) {
        ForEach(
          gitState.repositoryURLs.sorted(by: {
            $0.lastPathComponent < $1.lastPathComponent
          }),
          id: \.self
        ) {
          repository in
          Button(
            action: {
              gitState.activeRepository = repository
            },
            label: {
              if repository == gitState.activeRepository {
                Label(repository.lastPathComponent, systemImage: "checkmark")
              } else {
                Text(repository.lastPathComponent)
              }
            },
          )
        }
        Button("Locate Repository") {
          showingImporter = true
        }.keyboardShortcut("l")
        if gitState.activeRepository != nil {
          Button("Unadd Active Repository") {
            if let active = gitState.activeRepository {
              gitState.removeRepo(url: active)
            }
          }
        } else {
          Text("Unadd Active Repository")
        }
      }
      Divider()
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
        gitState.addRepo(url: url, setActive: true)
      }
    case .failure(let error):
      print(error.localizedDescription)
    }
  }
}

#Preview {
  MenuView()
}
