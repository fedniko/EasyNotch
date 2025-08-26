import SwiftUI

struct IslandView: View {
    @StateObject private var musicFetcher = SystemNowPlayingFetcher.shared
    @StateObject private var permissionManager = PermissionManager.shared
    @State private var isExpanded = false
    @State private var isHovered = false
    
    var body: some View {
        ZStack {
            // Чёрный фон с прозрачностью и тенью для эффекта Dynamic Island
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.black.opacity(0.92))
                .shadow(color: Color.black.opacity(0.35), radius: 16, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )

            // Контент
            HStack(spacing: 12) {
                musicIconView
                VStack(alignment: .leading, spacing: 2) {
                    if !musicFetcher.hasPermission {
                        Text("Требуется разрешение")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                        Text("Нажмите для настройки")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    } else if let song = musicFetcher.current {
                        Text(song.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text(song.artist)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                    } else {
                        Text("Музыка не играет")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                Spacer()
                if musicFetcher.hasPermission && musicFetcher.isPlaying {
                    playingIndicator
                }
                // Кнопки управления плеером
                HStack(spacing: 10) {
                    Button(action: {
                        SystemNowPlayingFetcher.shared.sendCommand(.previous)
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Button(action: {
                        SystemNowPlayingFetcher.shared.sendCommand(musicFetcher.isPlaying ? .pause : .play)
                    }) {
                        Image(systemName: musicFetcher.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Button(action: {
                        SystemNowPlayingFetcher.shared.sendCommand(.next)
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.top, 48)
            .padding(.bottom, 12)
        }
        .onTapGesture {
            if !musicFetcher.hasPermission {
                permissionManager.showPermissionAlert()
            } else {
                musicFetcher.refresh()
                print("🔄 Принудительное обновление информации о музыке")
            }
        }
        .onAppear {
            musicFetcher.refresh()
            print("🚀 IslandView появился, обновляем информацию о музыке")
        }
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onChange(of: musicFetcher.current) { newValue in
            print("🔄 Изменение current: \(newValue?.title ?? "nil") - \(newValue?.artist ?? "nil")")
        }
        .onChange(of: musicFetcher.isPlaying) { newValue in
            print("🔄 Изменение isPlaying: \(newValue)")
        }
    }
    
    @ViewBuilder
    private var musicIconView: some View {
        if !musicFetcher.hasPermission {
            Image(systemName: "lock.shield")
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 56, height: 56)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
        } else if let song = musicFetcher.current, let artwork = song.artwork {
            if let nsImage = artwork.image(at: CGSize(width: 64, height: 64)) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 56, height: 56)
                    .cornerRadius(12)
                    .shadow(radius: 6)
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 56, height: 56)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
            }
        } else {
            Image(systemName: "music.note")
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 56, height: 56)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    private var playingIndicator: some View {
        HStack(spacing: 3) {
            ForEach(0..<5) { index in
                Capsule()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.7), Color.white.opacity(0.3)]), startPoint: .bottom, endPoint: .top))
                    .frame(width: 4, height: 18)
                    .scaleEffect(y: musicFetcher.isPlaying ? CGFloat.random(in: 0.3...1.0) : 0.3, anchor: .bottom)
                    .animation(
                        Animation.easeInOut(duration: 0.4)
                            .repeatForever()
                            .delay(Double(index) * 0.08),
                        value: musicFetcher.isPlaying
                    )
            }
        }
        .frame(height: 20)
        .padding(.trailing, 4)
    }
}

#Preview {
    IslandView()
        .background(Color.black)
}
