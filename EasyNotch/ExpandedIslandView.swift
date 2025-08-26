import SwiftUI

struct ExpandedIslandView: View {
    @StateObject private var musicFetcher = SystemNowPlayingFetcher.shared
    @State private var isVisible = false
    
    var body: some View {
        ZStack {
            // Фоновый размытый фон
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                .cornerRadius(32)
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            
            VStack(spacing: 16) {
                // Заголовок
                HStack {
                    Image(systemName: "music.note")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("Сейчас играет")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                }
                
                if let song = musicFetcher.current {
                    // Обложка альбома
                    if let artwork = song.artwork,
                       let nsImage = artwork.image(at: CGSize(width: 120, height: 120)) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 120, height: 120)
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(.system(size: 40, weight: .light))
                                    .foregroundColor(.white.opacity(0.6))
                            )
                    }
                    
                    // Информация о треке
                    VStack(spacing: 8) {
                        Text(song.title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        
                        Text(song.artist)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                        
                        if let album = song.album {
                            Text(album)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.white.opacity(0.6))
                                .lineLimit(1)
                        }
                    }
                    
                    // Индикатор воспроизведения
                    if musicFetcher.isPlaying {
                        HStack(spacing: 4) {
                            ForEach(0..<5) { index in
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(Color.white)
                                    .frame(width: 3, height: 20)
                                    .scaleEffect(y: 0.3 + Double(index) * 0.15)
                                    .animation(
                                        Animation.easeInOut(duration: 0.8)
                                            .repeatForever()
                                            .delay(Double(index) * 0.1),
                                        value: musicFetcher.isPlaying
                                    )
                            }
                        }
                        .padding(.top, 8)
                    }
                } else {
                    // Состояние без музыки
                    VStack(spacing: 16) {
                        Image(systemName: "music.note.slash")
                            .font(.system(size: 40, weight: .light))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("Музыка не воспроизводится")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("Запустите Apple Music, Spotify или другое приложение для воспроизведения музыки")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                    }
                }
            }
            .padding(24)
        }
        .frame(width: 280, height: 400)
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.8)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                isVisible = true
            }
        }
    }
}

#Preview {
    ExpandedIslandView()
        .background(Color.black)
}
