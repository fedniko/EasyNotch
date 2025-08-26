import Foundation
import MediaPlayer

class DebugMusicInfo {
    static func printNowPlayingInfo() {
        print("=== Отладочная информация о музыке ===")
        
        if let info = MPNowPlayingInfoCenter.default().nowPlayingInfo {
            print("✅ MPNowPlayingInfo найден!")
            print("Количество ключей: \(info.count)")
            
            for (key, value) in info {
                print("  \(key): \(value)")
            }
            
            // Проверяем основные ключи
            let title = info[MPMediaItemPropertyTitle] as? String
            let artist = info[MPMediaItemPropertyArtist] as? String
            let album = info[MPMediaItemPropertyAlbumTitle] as? String
            let playbackRate = info[MPNowPlayingInfoPropertyPlaybackRate] as? Double
            
            print("\n--- Основная информация ---")
            print("Название: \(title ?? "nil")")
            print("Исполнитель: \(artist ?? "nil")")
            print("Альбом: \(album ?? "nil")")
            print("Скорость воспроизведения: \(playbackRate ?? 0.0)")
            
        } else {
            print("❌ MPNowPlayingInfo не найден")
            print("Возможные причины:")
            print("  - Музыка не воспроизводится")
            print("  - Приложение не использует MediaPlayer framework")
            print("  - Проблемы с системными разрешениями")
        }
        
        print("================================")
    }
    
    static func startMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            printNowPlayingInfo()
        }
    }
}
