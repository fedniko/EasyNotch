#!/usr/bin/env swift

import Foundation
import MediaPlayer

print("🎵 Тестирование MPNowPlayingInfoCenter...")
print("==========================================")

// Проверяем информацию о музыке
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
    print("\nВозможные причины:")
    print("  - Музыка не воспроизводится")
    print("  - Приложение не использует MediaPlayer framework")
    print("  - Проблемы с системными разрешениями")
}

print("\n💡 Для тестирования:")
print("  1. Запустите Apple Music или Spotify")
print("  2. Воспроизведите любой трек")
print("  3. Запустите этот скрипт снова")
print("==========================================")
