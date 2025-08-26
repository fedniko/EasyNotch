//
//  EasyNotchApp.swift
//  EasyNotch
//
//  Created by Nikolay Fedorov on 26.08.2025.
//

import SwiftUI
import MediaPlayer

@main
struct EasyNotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

      var body: some Scene {
          // нет основного окна — наше "островок" отдельное NSWindow
          Settings { EmptyView() }
      }
}
