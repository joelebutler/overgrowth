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
          return nil
        }
        defer { url.stopAccessingSecurityScopedResource() }
        return try? url.bookmarkData(options: .withSecurityScope)
      }
      UserDefaults.standard.set(repos, forKey: "repositoryURLs")
    }
  }
  func addRepo(url: URL, setActive: Bool) {
    let _url: URL =
      url.lastPathComponent == ".git" ? url.deletingLastPathComponent() : url

    if !isGitRepo(repository: _url) {
      error(
        message: "Invalid Repository Selected",
        informativeText:
          ".git/HEAD subdirectory not found. Operation will be canceled."
      )
      return
    }

    self.repositoryURLs.insert(_url)
    if setActive {
      activeRepository = _url
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

      guard let url = activeRepository else {
        UserDefaults.standard.removeObject(forKey: "activeRepository")
        return
      }

      if !url.startAccessingSecurityScopedResource() {
        error(
          message: "Access Denied",
          informativeText:
            "Unable to access \(url.lastPathComponent). Please ensure you have permission to access the folder and try again."
        )
        activeRepository = oldValue
        return
      }

      if !isGitRepo(repository: url) {
        error(
          message: "Invalid Repository Selected",
          informativeText: ".git/HEAD subdirectory not found."
        )
        activeRepository = oldValue
        return
      }

      UserDefaults.standard.set(
        url.absoluteString,
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
          return reidentificationLoop(
            url: url,
            message: "Stale repository",
            informativeText:
              "\(url?.lastPathComponent ?? "Repository") was found as a valid git repository. If it has changed locations or been deleted, please reselect it."
          )
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
