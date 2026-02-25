//
//  GitState.swift
//  overgrowth
//
//  Created by Joel Butler on 2/24/26.
//

import SwiftUI

@Observable class GitState {
  var repositoryURL: URL? {
    didSet {
      UserDefaults.standard.set(repositoryURL, forKey: "repositoryURL")
    }
  }
  init() {
    self.repositoryURL = UserDefaults.standard.url(forKey: "repositoryURL")
  }
}
