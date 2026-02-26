//
//  GitState.swift
//  overgrowth
//
//  Created by Joel Butler on 2/24/26.
//

import SwiftUI

@Observable class GitState {
  var repositoryURLs: Set<URL> {
    didSet {
      let repos = repositoryURLs.compactMap { url -> Data? in
        guard url.startAccessingSecurityScopedResource() else {
          /* TODO: Look into safer later access methods. atm this is temp access for bookmark */
          /* TODO: Ensure folder selected is a git repo*/
          return nil
        }
        defer { url.stopAccessingSecurityScopedResource() }
        return try? url.bookmarkData(options: .withSecurityScope)
      }
      UserDefaults.standard.set(repos, forKey: "repositoryURLs")
    }
  }
  func addRepo(url: URL, setActive: Bool) {
    self.repositoryURLs.insert(url)
    if setActive {
      activeRepository = url
    }
  }
  func stopAccess() {
    activeRepository?.stopAccessingSecurityScopedResource()
  }
  func removeRepo(url: URL) {
    repositoryURLs.remove(url)
    if url == activeRepository {
      activeRepository = nil
    }
  }

  var activeRepository: URL? {
    didSet {
      oldValue?.stopAccessingSecurityScopedResource()

      if let url = activeRepository {
        if !url.startAccessingSecurityScopedResource() {
          // TODO: Error handling here
        }
      }
      UserDefaults.standard.set(
        activeRepository?.absoluteString,
        forKey: "activeRepository"
      )
    }
  }

  init() {
    let bookmarks: [Data] =
      UserDefaults.standard.array(forKey: "repositoryURLs") as? [Data] ?? []
    self.repositoryURLs = Set<URL>(
      bookmarks.compactMap {
        entry -> URL? in
        var stale: Bool = false
        let url = try? URL(
          resolvingBookmarkData: entry,
          options: .withSecurityScope,
          bookmarkDataIsStale: &stale
        )
        if stale {
          // TODO: Prompt user for re-selection.
          return nil
        }

        return url
      }
    )
    if let repoPath = UserDefaults.standard.string(forKey: "activeRepository") {
      activeRepository = repositoryURLs.first(where: {
        $0.absoluteString == repoPath
      })
    }
  }
}
