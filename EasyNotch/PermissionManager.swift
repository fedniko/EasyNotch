import Foundation
import AppKit

class PermissionManager: ObservableObject {
    static let shared = PermissionManager()
    
    @Published var hasRequiredPermissions: Bool = true // На macOS MPNowPlayingInfoCenter работает без разрешений
    
    private init() {
        checkPermissions()
    }
    
    func checkPermissions() {
        // На macOS MPNowPlayingInfoCenter работает без разрешений
        hasRequiredPermissions = true
    }
    
    func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Информация о разрешениях"
        alert.informativeText = "На macOS приложение EasyNotch работает автоматически без запроса дополнительных разрешений.\n\nЕсли музыка не отображается, убедитесь что:\n1. Музыка воспроизводится в поддерживаемом приложении\n2. Приложение EasyNotch запущено\n3. Мышь находится в верхней области экрана"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
