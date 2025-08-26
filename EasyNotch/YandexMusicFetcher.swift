// YandexMusicFetcher.swift
// Получение информации о текущем треке из приложения Яндекс Музыка через Accessibility API
// Требует разрешения на управление компьютером (System Preferences > Security & Privacy > Accessibility)

import Foundation
import Cocoa

struct YandexMusicTrackInfo {
    let title: String
    let artist: String
}

class YandexMusicFetcher {
    static let shared = YandexMusicFetcher()
    
    private let appName = "Яндекс Музыка"
    
    func getCurrentTrack() -> YandexMusicTrackInfo? {
        guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: "ru.yandex.desktop.music").first else {
            return nil
        }
        
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
        let trusted = AXIsProcessTrustedWithOptions(options)
        guard trusted else { return nil }
        
        let pid = app.processIdentifier
        var appElement: AXUIElement = AXUIElementCreateApplication(pid)
        
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &value)
        guard result == .success, let windows = value as? [AXUIElement], let window = windows.first else {
            return nil
        }
        
        // Попробуем найти элементы с текстом трека и исполнителя
        if let trackInfo = findTrackInfo(in: window) {
            return trackInfo
        }
        return nil
    }
    
    private func findTrackInfo(in element: AXUIElement) -> YandexMusicTrackInfo? {
        var children: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &children)
        if result == .success, let childrenArray = children as? [AXUIElement] {
            for child in childrenArray {
                if let info = findTrackInfo(in: child) {
                    return info
                }
                // Пробуем получить строку
                var value: AnyObject?
                if AXUIElementCopyAttributeValue(child, kAXValueAttribute as CFString, &value) == .success, let str = value as? String {
                    // Пример: "Исполнитель — Название трека"
                    let parts = str.components(separatedBy: " — ")
                    if parts.count == 2 {
                        return YandexMusicTrackInfo(title: parts[1], artist: parts[0])
                    }
                }
                if AXUIElementCopyAttributeValue(child, kAXTitleAttribute as CFString, &value) == .success, let str = value as? String {
                    let parts = str.components(separatedBy: " — ")
                    if parts.count == 2 {
                        return YandexMusicTrackInfo(title: parts[1], artist: parts[0])
                    }
                }
            }
        }
        return nil
    }
}
