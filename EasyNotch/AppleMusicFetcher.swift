import Foundation
import ScriptingBridge

@objc protocol iTunesApplication {
    @objc optional var currentTrack: iTunesTrack { get }
    @objc optional var playerState: iTunesEPlS { get }
}

@objc protocol iTunesTrack {
    @objc optional var name: String { get }
    @objc optional var artist: String { get }
    @objc optional var album: String { get }
}

@objc enum iTunesEPlS: NSInteger {
    case stopped = 1800426320
    case playing = 1800426322
    case paused  = 1800426321
}

class AppleMusicFetcher {
    private let musicApp = SBApplication(bundleIdentifier: "com.apple.Music") as? iTunesApplication

    func getNowPlaying() -> (title: String, artist: String)? {
        guard let app = musicApp,
              let state = app.playerState,
              state == .playing,
              let track = app.currentTrack,
              let title = track.name,
              let artist = track.artist else {
            return nil
        }
        return (title, artist)
    }
}
