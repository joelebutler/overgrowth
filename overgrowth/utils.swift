//
//  utils.swift
//  overgrowth
//
//  Created by Joel Butler on 2/26/26.
//

import SwiftUI

func isGitRepo(repository: URL) -> Bool {
  // Checks for a .git/HEAD within provided folder.
  var isDir: ObjCBool = false
  let exists: Bool = FileManager.default.fileExists(
    atPath: repository.appending(components: ".git", "HEAD").path,
    isDirectory: &isDir
  )
  return !isDir.boolValue && exists
}

func error(message: String, informativeText: String) {
  let alert = NSAlert()
  alert.messageText = message
  alert.informativeText = informativeText
  alert.alertStyle = .critical
  alert.runModal()
}

func reselectionDialog(message: String, informativeText: String) -> URL? {
  let alert = NSAlert()
  alert.messageText = message
  alert.informativeText = informativeText
  alert.alertStyle = .warning
  alert.addButton(withTitle: "Reselect")
  alert.addButton(withTitle: "Cancel")
  guard alert.runModal() == .alertFirstButtonReturn else { return nil }

  let panel = NSOpenPanel()
  panel.canChooseFiles = false
  panel.canChooseDirectories = true
  panel.allowsMultipleSelection = false
  panel.prompt = "Select"

  guard panel.runModal() == .OK else { return nil }

  return panel.url
}

func reidentificationLoop(url: URL?, message: String, informativeText: String)
  -> URL?
{
  let reidentified: URL? = reselectionDialog(
    message: message,
    informativeText: informativeText
  )
  guard let reidentified else { return nil }
  if isGitRepo(repository: reidentified) {
    return reidentificationLoop(
      url: url,
      message: message,
      informativeText: informativeText
    )
  }
  return reidentified
}
