import Cocoa
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    var islandWindow: DynamicIslandWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        islandWindow = DynamicIslandWindow()
        islandWindow?.startHoverMonitoring()
    }

    func applicationWillTerminate(_ notification: Notification) {
        islandWindow?.stopHoverMonitoring()
    }
}
