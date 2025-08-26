#!/usr/bin/env swift

import Foundation
import MediaPlayer
import AppKit

print("🔍 Детальная диагностика MPNowPlayingInfoCenter")
print("================================================")

// Проверяем доступность MediaPlayer framework
print("📱 Проверка MediaPlayer framework...")
if let bundle = Bundle(identifier: "com.apple.MediaPlayer") {
    print("✅ MediaPlayer framework доступен")
} else {
    print("❌ MediaPlayer framework недоступен")
}

// Проверяем MPNowPlayingInfoCenter
print("\n🎵 Проверка MPNowPlayingInfoCenter...")
let infoCenter = MPNowPlayingInfoCenter.default()
print("✅ MPNowPlayingInfoCenter создан")

// Проверяем текущую информацию
if let info = infoCenter.nowPlayingInfo {
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
    
    // Попробуем принудительно обновить
    print("\n🔄 Попытка принудительного обновления...")
    
    // Создаем тестовую информацию
    let testInfo: [String: Any] = [
        MPMediaItemPropertyTitle: "Тестовый трек",
        MPMediaItemPropertyArtist: "Тестовый исполнитель",
        MPNowPlayingInfoPropertyPlaybackRate: 1.0
    ]
    
    infoCenter.nowPlayingInfo = testInfo
    print("✅ Тестовая информация установлена")
    
    // Проверяем снова
    if let updatedInfo = infoCenter.nowPlayingInfo {
        print("✅ MPNowPlayingInfo обновлен!")
        print("Количество ключей: \(updatedInfo.count)")
        
        for (key, value) in updatedInfo {
            print("  \(key): \(value)")
        }
    } else {
        print("❌ MPNowPlayingInfo все еще не найден")
    }
    
    // Очищаем тестовую информацию
    infoCenter.nowPlayingInfo = nil
    print("🧹 Тестовая информация очищена")
}

// Проверяем системные процессы
print("\n🖥️ Проверка системных процессов...")
let task = Process()
task.launchPath = "/bin/ps"
task.arguments = ["aux"]

let pipe = Pipe()
task.standardOutput = pipe

do {
    try task.run()
    task.waitUntilExit()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    if let output = String(data: data, encoding: .utf8) {
        let lines = output.components(separatedBy: .newlines)
        
        print("📊 Активные процессы:")
        for line in lines {
            if line.contains("Music") || line.contains("Spotify") || line.contains("VLC") || line.contains("Yandex") {
                print("  \(line)")
            }
        }
    }
} catch {
    print("❌ Ошибка при проверке процессов: \(error)")
}

print("\n================================================")
print("🏁 Диагностика завершена!")

