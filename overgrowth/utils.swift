//
//  utils.swift
//  overgrowth
//
//  Created by Joel Butler on 2/26/26.
//

import SwiftUI

func branchNames(repository: URL) -> (local: [String], remotes: [String], current: String?) {
  var locals: [String] = []
  var remotes: [String] = []
  var currentBranch: String? = nil
  
  let localTask = Process()
  localTask.executableURL = URL(filePath: "/usr/bin/git") // TODO: Ensure this is proper location.
  localTask.currentDirectoryURL = repository
  localTask.arguments = ["branch"]
  let remoteTask = Process()
  remoteTask.executableURL = URL(filePath: "/usr/bin/git")
  remoteTask.currentDirectoryURL = repository
  remoteTask.arguments = ["branch", "-r"]
  
  let errorPipe = Pipe()
  localTask.standardError = errorPipe
  do {
    let localPipe = Pipe()
    localTask.standardOutput = localPipe
    try localTask.run()
    let localData = localPipe.fileHandleForReading.readDataToEndOfFile()
    let local = String(decoding: localData, as: UTF8.self)
    
    for line in local.split(separator: "\n") {
      let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
      if trimmed.contains("*") {
        let noAsterisk = trimmed.replacingOccurrences(of: "* ", with: "")
        currentBranch = noAsterisk
        locals.append(noAsterisk)
      } else if trimmed.contains("->") {
        // skip remote HEAD pointers
        continue
      } else {
        locals.append(trimmed)
      }
    }
    
    let remotePipe = Pipe()
    remoteTask.standardOutput = remotePipe
    try remoteTask.run()
    let remoteData = remotePipe.fileHandleForReading.readDataToEndOfFile()
    let remote = String(decoding: remoteData, as: UTF8.self)
    for line in remote.split(separator: "\n") {
      let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
      if trimmed.contains("->") {
        // skip remote HEAD pointers
        continue
      } else {
        remotes.append(trimmed)
      }
    }
  } catch {
    // TODO: Log error here.
    return ([], [], nil)
  }
  return (locals, remotes, currentBranch)
  
}

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

func textPopup(title: String, message: String, w: Int? = nil, h: Int? = nil)->String? {
  let popup = NSAlert()
  popup.messageText = title
  popup.informativeText = message
  popup.addButton(withTitle: "OK")
  popup.addButton(withTitle: "Cancel")
  let buttonFrame = popup.buttons.first!.frame

  
  let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: w ?? Int(buttonFrame.width), height: h ?? 24))
  textField.placeholderString = "Type here..."
  popup.accessoryView = textField

  popup.window.initialFirstResponder = textField

  let response = popup.runModal()
  if response == .alertFirstButtonReturn {
      return textField.stringValue
  }
  return nil
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
