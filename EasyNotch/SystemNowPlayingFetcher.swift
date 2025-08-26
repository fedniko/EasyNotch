import Foundation
import MediaPlayer
import Combine
import AppKit

class SystemNowPlayingFetcher: ObservableObject {
    static let shared = SystemNowPlayingFetcher()
    
    @Published var current: NowPlayingInfo? = nil
    @Published var isPlaying: Bool = false
    @Published var hasPermission: Bool = true // На macOS разрешения не требуются для MPNowPlayingInfoCenter
    
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupNotifications()
        startPolling()
    }
    
    deinit {
        stopPolling()
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupNotifications() {
        // На macOS используем только доступные уведомления
        // MPNowPlayingInfoCenter автоматически обновляется системой
    }
    
    private func startPolling() {
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
        guard let info = MPNowPlayingInfoCenter.default().nowPlayingInfo else {
            DispatchQueue.main.async {
                self.current = nil
                self.isPlaying = false
            }
            return
        }
        
        let title = info[MPMediaItemPropertyTitle] as? String ?? "Неизвестный трек"
        let artist = info[MPMediaItemPropertyArtist] as? String ?? "Неизвестный исполнитель"
        let album = info[MPMediaItemPropertyAlbumTitle] as? String
        let artwork = info[MPMediaItemPropertyArtwork] as? MPMediaItemArtwork
        
        let playbackRate = info[MPNowPlayingInfoPropertyPlaybackRate] as? Double ?? 0.0
        let isCurrentlyPlaying = playbackRate > 0
        
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
    }
    
    func requestPermissionIfNeeded() {
        // На macOS разрешения не требуются для MPNowPlayingInfoCenter
        hasPermission = true
    }
}

struct NowPlayingInfo {
    let title: String
    let artist: String
    let album: String?
    let artwork: MPMediaItemArtwork?
}
