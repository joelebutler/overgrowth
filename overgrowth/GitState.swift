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
      (locals, remotes, currentBranch) = branchNames(repository: url)
    }
  }

  var locals: [String]
  var remotes: [String]
  var currentBranch: String? {
    didSet {
      var rollback = false
      if let current = currentBranch {
        let task = Process()
        task.executableURL = URL(filePath: "/usr/bin/git")  // TODO: Ensure this is proper location.
        task.currentDirectoryURL = activeRepository?.absoluteURL
        task.arguments = ["switch", current]
        let pipe = Pipe()
        task.standardError = pipe
        do {
          try task.run()
          task.waitUntilExit()
          
          let data = pipe.fileHandleForReading.readDataToEndOfFile()
          let output = String(decoding: data, as: UTF8.self)
          
          if output.contains("Please commit your changes or stash them before you switch branches.") {
            rollback = branchDialog(branch: current)
          }
        } catch {
          // TODO: Error handling here.
          rollback = true
        }
      } else {
        rollback = true
      }
      if rollback {
        currentBranch = oldValue
        return
      }
      UserDefaults.standard.set(currentBranch, forKey: "currentBranch")
    }
  }
  
  func makeBranch(name: String? = nil) {
    // If branch has remote prefix, make track remote.
    // If empty, prompt for new branch name.
    // Otherwise, just check out normally.
    guard let branchName: String = name ?? textPopup(title: "New Branch", message: "Name your new branch.") else {
      return
    }
    
    let task = Process()
    task.executableURL = URL(filePath: "/usr/bin/git")  // TODO: Ensure this is proper location.
    task.currentDirectoryURL = activeRepository?.absoluteURL
    
    let splits : [String] = branchName.components(separatedBy: "/")
    if (splits.count > 1) {
      let noRemote = splits[1]
      task.arguments = ["switch", "-c", noRemote, branchName]
    } else {
      task.arguments = ["switch", "-c", branchName]
    }
    let pipe = Pipe()
    task.standardError = pipe
    do {
      try task.run()
      task.waitUntilExit()
      
      (locals, remotes, currentBranch) = branchNames(repository: activeRepository!.absoluteURL)
    } catch {
      // TODO: Error handling here.
    }
  }
  
  func branchDialog(branch: String)->Bool {
    // returns bool whether to rollback
    let alert = NSAlert()
    alert.messageText = "Handle pending changes!"
    alert.messageText = "Your repository has pending changes. Would you like to bring them with you, discard, or cancel?"
    alert.addButton(withTitle: "Bring changes")
    alert.addButton(withTitle: "Discard all")
    alert.addButton(withTitle: "Cancel")
    let button: NSApplication.ModalResponse = alert.runModal()
    switch (button) {
    case .alertFirstButtonReturn: // Bring
      let _stash = Process()
      let _switch = Process()
      let _pop = Process()
      _stash.executableURL = URL(filePath: "/usr/bin/git") // TODO: Ensure this is proper location.
      _switch.executableURL = URL(filePath: "/usr/bin/git") // TODO: Ensure this is proper location.
      _pop.executableURL = URL(filePath: "/usr/bin/git") // TODO: Ensure this is proper location.
      _stash.currentDirectoryURL = activeRepository
      _switch.currentDirectoryURL = activeRepository
      _pop.currentDirectoryURL = activeRepository
      _stash.arguments = ["stash"]
      _switch.arguments = ["switch", branch]
      _pop.arguments = ["pop"]
      do {
        let stashPipe = Pipe()
        _stash.standardOutput = stashPipe
        
        try _stash.run()
        _stash.waitUntilExit()
        
        let stashOutput = String(decoding: stashPipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        let didStash = _stash.terminationStatus == 0 && !stashOutput.contains("No local changes to save")
        
        try _switch.run()
        _switch.waitUntilExit()
        if (didStash) {
          try _pop.run()
          _pop.waitUntilExit()
        }
        return false
      } catch {
        // TODO: More error handling
        return true
      }
    case .alertSecondButtonReturn: // Discard all
      let _discard = Process()
      let _switch = Process()
      _discard.executableURL = URL(filePath: "/usr/bin/git") // TODO: Ensure this is proper location.
      _switch.executableURL = URL(filePath: "/usr/bin/git") // TODO: Ensure this is proper location.
      _discard.currentDirectoryURL = activeRepository
      _switch.currentDirectoryURL = activeRepository
      _discard.arguments = ["restore", "--staged", "--worktree", "."]
      _switch.arguments = ["switch", branch]
      do {
        try _discard.run()
        _discard.waitUntilExit()
        try _switch.run()
        _switch.waitUntilExit()
        return false
      } catch {
        // TODO: More error handling
        return true
      }
    default: // Cancel
      return true
    }
  }

  init() {
    locals = []
    remotes = []
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
    if let _currentBranch = UserDefaults.standard.string(forKey: "currentBranch") {
      currentBranch = _currentBranch
    }
  }
}
