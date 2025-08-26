import SwiftUI

struct IslandView: View {
    @StateObject private var musicFetcher = SystemNowPlayingFetcher.shared
    @StateObject private var permissionManager = PermissionManager.shared
    @State private var isExpanded = false
    @State private var isHovered = false
    
    var body: some View {
        ZStack {
            // Фоновый размытый фон
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                .cornerRadius(28)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            
            // Контент
            HStack(spacing: 12) {
                // Иконка музыки или обложка альбома
                musicIconView
                
                // Информация о треке
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
                
                // Индикатор воспроизведения
                if musicFetcher.hasPermission && musicFetcher.isPlaying {
                    playingIndicator
                }
                
                // Стрелка для расширения
                if isHovered {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .transition(.opacity.combined(with: .scale))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(width: 220, height: 56)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
                isExpanded = hovering
            }
            
            // Уведомляем окно о состоянии hover
            NotificationCenter.default.post(
                name: .init("IslandSetInteractive"),
                object: hovering
            )
        }
        .onTapGesture {
            if !musicFetcher.hasPermission {
                permissionManager.showPermissionAlert()
            }
        }
        .onAppear {
            musicFetcher.refresh()
        }
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
    }
    
    @ViewBuilder
    private var musicIconView: some View {
        if !musicFetcher.hasPermission {
            // Иконка разрешения
            Image(systemName: "lock.shield")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 32, height: 32)
                .background(Color.white.opacity(0.1))
                .cornerRadius(6)
        } else if let song = musicFetcher.current, let artwork = song.artwork,
                  let nsImage = artwork.image(at: CGSize(width: 32, height: 32)) {
            // Показываем обложку альбома
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 32, height: 32)
                .cornerRadius(6)
        } else {
            // Показываем иконку музыки
            Image(systemName: "music.note")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 32, height: 32)
                .background(Color.white.opacity(0.1))
                .cornerRadius(6)
        }
    }
    
    @ViewBuilder
    private var playingIndicator: some View {
        HStack(spacing: 2) {
            ForEach(0..<3) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.white)
                    .frame(width: 2, height: 12)
                    .scaleEffect(y: 0.3 + Double(index) * 0.2)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.1),
                        value: musicFetcher.isPlaying
                    )
            }
        }
    }
}

#Preview {
    IslandView()
        .background(Color.black)
}
