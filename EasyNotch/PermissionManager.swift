import Foundation
import AppKit

class PermissionManager: ObservableObject {
    static let shared = PermissionManager()
    
    @Published var hasRequiredPermissions: Bool = true
    
    private init() {
        // На macOS разрешения для MPNowPlayingInfoCenter не требуются
        checkPermissions()
    }
    
    func checkPermissions() {
        // На macOS разрешения для MPNowPlayingInfoCenter не требуются
        hasRequiredPermissions = true
    }
    
    func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Информация"
        alert.informativeText = "На macOS разрешения для отображения информации о музыке не требуются. Приложение должно работать автоматически."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        
        alert.runModal()
    }
}
