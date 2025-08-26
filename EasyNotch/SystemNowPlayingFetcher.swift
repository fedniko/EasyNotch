// Команды управления плеером
enum PlayerCommand {
    case play, pause, next, previous
}

import Foundation
import MediaPlayer
import Combine
import AppKit
import CoreGraphics

class SystemNowPlayingFetcher: ObservableObject {

    // Управление плеером через AppleScript/media keys
    func sendCommand(_ command: PlayerCommand) {
        // Используем глобальные media keys (F7/F8/F9)
        let key: Int32
        switch command {
        case .play, .pause:
            key = 16 // NX_KEYTYPE_PLAY
        case .next:
            key = 17 // NX_KEYTYPE_NEXT
        case .previous:
            key = 18 // NX_KEYTYPE_PREVIOUS
        }
        let flags = CGEventFlags.maskNonCoalesced
        if let eventDown = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true) {
            eventDown.flags = flags
            eventDown.setIntegerValueField(.keyboardEventAutorepeat, value: 0)
            eventDown.setIntegerValueField(.keyboardEventKeyboardType, value: 0)
            eventDown.setIntegerValueField(.keyboardEventKeycode, value: Int64(key))
            eventDown.post(tap: .cghidEventTap)
        }
        if let eventUp = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false) {
            eventUp.flags = flags
            eventUp.setIntegerValueField(.keyboardEventAutorepeat, value: 0)
            eventUp.setIntegerValueField(.keyboardEventKeyboardType, value: 0)
            eventUp.setIntegerValueField(.keyboardEventKeycode, value: Int64(key))
            eventUp.post(tap: .cghidEventTap)
        }
    }
    static let shared = SystemNowPlayingFetcher()
    
    @Published var current: NowPlayingInfo? = nil
    @Published var isPlaying: Bool = false
    @Published var hasPermission: Bool = true // На macOS MPNowPlayingInfoCenter работает без разрешений
    
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var distributedObservers: [NSObjectProtocol] = []
    private var yandexTimer: Timer?
    private var seenYandexTitles = Set<String>()
    
    init() {
        setupNotifications()
        setupDistributedNotifications()
        startPolling()
        startYandexPolling()
    }
    
    deinit {
        stopPolling()
        stopYandexPolling()
        NotificationCenter.default.removeObserver(self)
        let center = DistributedNotificationCenter.default()
        distributedObservers.forEach { center.removeObserver($0) }
        distributedObservers.removeAll()
    }
    
    private func setupNotifications() {
        // На macOS используем только доступные уведомления
        // MPNowPlayingInfoCenter автоматически обновляется системой
    }
    
    private func setupDistributedNotifications() {
        let center = DistributedNotificationCenter.default()
        
        // Apple Music / iTunes
        let appleMusicName = Notification.Name("com.apple.iTunes.playerInfo")
        let appleObs = center.addObserver(forName: appleMusicName, object: nil, queue: .main) { [weak self] n in
            guard let userInfo = n.userInfo as? [String: Any] else { return }
            self?.handleAppleMusic(userInfo: userInfo)
        }
        distributedObservers.append(appleObs)
        
        // Spotify
        let spotifyName = Notification.Name("com.spotify.client.PlaybackStateChanged")
        let spotObs = center.addObserver(forName: spotifyName, object: nil, queue: .main) { [weak self] n in
            guard let userInfo = n.userInfo as? [String: Any] else { return }
            self?.handleSpotify(userInfo: userInfo)
        }
        distributedObservers.append(spotObs)
    }
    
    private func handleAppleMusic(userInfo: [String: Any]) {
        let title = userInfo["Name"] as? String
        let artist = userInfo["Artist"] as? String
        let album = userInfo["Album"] as? String
        let playerState = (userInfo["Player State"] as? String) ?? ""
        let playing = playerState.lowercased() == "playing"
        
        if title != nil || artist != nil {
            DispatchQueue.main.async {
                self.current = NowPlayingInfo(
                    title: title ?? "Неизвестный трек",
                    artist: artist ?? "Неизвестный исполнитель",
                    album: album,
                    artwork: nil
                )
                self.isPlaying = playing
            }
        }
    }
    
    private func handleSpotify(userInfo: [String: Any]) {
        let title = userInfo["Name"] as? String
        let artist = userInfo["Artist"] as? String
        let album = userInfo["Album"] as? String
        let playerStateString = (userInfo["Player State"] as? String) ?? ""
        let playingFlag = (userInfo["Playing"] as? Bool) ?? false
        let playing = playingFlag || playerStateString.lowercased() == "playing"
        
        if title != nil || artist != nil {
            DispatchQueue.main.async {
                self.current = NowPlayingInfo(
                    title: title ?? "Неизвестный трек",
                    artist: artist ?? "Неизвестный исполнитель",
                    album: album,
                    artwork: nil
                )
                self.isPlaying = playing
            }
        }
    }
    
    // MARK: - Yandex Music (CGWindow title fallback, no permissions)
    private func startYandexPolling() {
        yandexTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateFromYandexWindow()
        }
        if let yandexTimer {
            RunLoop.main.add(yandexTimer, forMode: .common)
        }
    }
    
    private func stopYandexPolling() {
        yandexTimer?.invalidate()
        yandexTimer = nil
    }
    
    private func updateFromYandexWindow() {
        let titles = copyYandexWindowTitles()
        guard !titles.isEmpty else { return }
        
        // Логируем новые заголовки (для отладки парсинга)
        for t in titles {
            if !seenYandexTitles.contains(t) {
                seenYandexTitles.insert(t)
                print("[Yandex] Window title: \(t)")
            }
        }
        
        // Берём самый информативный (самый длинный)
        let bestRaw = titles.max(by: { $0.count < $1.count })!
        let cleaned = cleanupYandexAffixes(bestRaw)
        if let parsed = parseArtistAndTitle(from: cleaned) {
            DispatchQueue.main.async {
                self.current = NowPlayingInfo(
                    title: parsed.title,
                    artist: parsed.artist,
                    album: nil,
                    artwork: nil
                )
                self.isPlaying = true
            }
        }
    }
    
    private func copyYandexWindowTitles() -> [String] {
        var result: [String] = []
        let listOptions = CGWindowListOption([.excludeDesktopElements, .optionOnScreenOnly])
        guard let windowInfoList = CGWindowListCopyWindowInfo(listOptions, kCGNullWindowID) as? [[String: Any]] else { return result }
        for win in windowInfoList {
            guard let owner = win[kCGWindowOwnerName as String] as? String else { continue }
            let lowerOwner = owner.lowercased()
            let ownerLooksLikeYandex = lowerOwner.contains("yandex") || lowerOwner.contains("яндекс")
            if !ownerLooksLikeYandex { continue }
            if let name = win[kCGWindowName as String] as? String, !name.isEmpty {
                result.append(name)
            }
        }
        // Дополнительно: некоторые окна несут информацию в owner, а title пуст — игнорируем такие
        return Array(Set(result)) // уникальные
    }
    
    private func cleanupYandexAffixes(_ s: String) -> String {
        // Убираем типичные хвосты: "— Яндекс Музыка", "— Yandex Music", "/ Яндекс Музыка" и т.п.
        var out = s
        let affixes = [
            " — Яндекс Музыка", " — Yandex Music", " – Яндекс Музыка", " – Yandex Music",
            " — яндекс музыка", " – яндекс музыка",
            " | Яндекс Музыка", " | Yandex Music",
            " / Яндекс Музыка", " / Yandex Music",
            " — Яндекс.Музыка", " – Яндекс.Музыка"
        ]
        for a in affixes {
            if out.lowercased().hasSuffix(a.lowercased()) {
                out = String(out.dropLast(a.count)).trimmingCharacters(in: .whitespacesAndNewlines)
                break
            }
        }
        // Иногда сервис добавляет префикс
        let prefixes = ["Яндекс Музыка — ", "Yandex Music — ", "Яндекс.Музыка — "]
        for p in prefixes {
            if out.lowercased().hasPrefix(p.lowercased()) {
                out = String(out.dropFirst(p.count)).trimmingCharacters(in: .whitespacesAndNewlines)
                break
            }
        }
        return out
    }
    
    private func parseArtistAndTitle(from title: String) -> (artist: String, title: String)? {
        let separators = [" — ", " – ", " - "]
        // Сначала пробуем формат "Исполнитель — Трек — Яндекс Музыка" (мы уже пытались чистить хвост)
        var s = title
        // Если внутри 3 части, берём первые 2
        for sep in separators {
            let parts = s.components(separatedBy: sep)
            if parts.count >= 2 {
                let left = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let right = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                if !left.isEmpty && !right.isEmpty {
                    return (artist: left, title: right)
                }
            }
        }
        return nil
    }
    
    private func startPolling() {
        print("🚀 Запуск мониторинга музыки...")
        
        // Обновляем каждую секунду для надежности
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateInfo()
        }
        RunLoop.main.add(timer!, forMode: .common)
        
        // Сразу обновляем информацию
        updateInfo()
    }
    
    private func stopPolling() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateInfo() {
        print("🔄 Обновление информации о музыке через MPNowPlayingInfoCenter...")
        guard let info = MPNowPlayingInfoCenter.default().nowPlayingInfo else {
            print("❌ MPNowPlayingInfoCenter пуст — нет информации о треке")
            return
        }
        print("✅ MPNowPlayingInfo найден, ключей: \(info.count)")
        for (key, value) in info {
            print("  \(key): \(value)")
        }
        let title = info[MPMediaItemPropertyTitle] as? String ?? "Неизвестный трек"
        let artist = info[MPMediaItemPropertyArtist] as? String ?? "Неизвестный исполнитель"
        let album = info[MPMediaItemPropertyAlbumTitle] as? String
        let artwork = info[MPMediaItemPropertyArtwork] as? MPMediaItemArtwork
        let playbackRate = info[MPNowPlayingInfoPropertyPlaybackRate] as? Double ?? 0.0
        let isCurrentlyPlaying = playbackRate > 0
        print("🎵 Трек: \(title) | Исполнитель: \(artist) | Альбом: \(album ?? "-") | Воспроизведение: \(isCurrentlyPlaying)")
        DispatchQueue.main.async {
            self.current = NowPlayingInfo(
                title: title,
                artist: artist,
                album: album,
                artwork: artwork
            )
            self.isPlaying = isCurrentlyPlaying
        }
    }
    
    func refresh() {
        updateInfo()
        updateFromYandexWindow()
    }
    
    func requestPermissionIfNeeded() {
        // На macOS MPNowPlayingInfoCenter работает без разрешений
        hasPermission = true
    }
}

struct NowPlayingInfo: Equatable {
    let title: String
    let artist: String
    let album: String?
    let artwork: MPMediaItemArtwork?
    
    static func == (lhs: NowPlayingInfo, rhs: NowPlayingInfo) -> Bool {
        return lhs.title == rhs.title && 
               lhs.artist == rhs.artist && 
               lhs.album == rhs.album
    }
}
