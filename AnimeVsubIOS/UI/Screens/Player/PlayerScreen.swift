import SwiftUI
import AVKit

struct PlayerScreen: View {
    let animeId: String
    let animeTitle: String
    let chapter: ChapterInfo
    let poster: String?

    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = PlayerViewModel()
    @State private var player: AVPlayer? = nil
    @State private var timeObserverToken: Any? = nil

    private var offlineURL: URL? {
        DownloadManager.shared.localURL(for: chapter.id)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let local = offlineURL {
                // Offline playback directly from disk
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear {
                        let avPlayer = AVPlayer(url: local)
                        self.player = avPlayer
                        setupTimeObserver(player: avPlayer)
                        avPlayer.play()
                    }
                    .onDisappear {
                        cleanupPlayer()
                    }
            } else if viewModel.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Đang tải nguồn phát...")
                        .foregroundColor(.white)
                        .font(.system(size: 14))
                }
            } else if let link = viewModel.playerLink, let url = URL(string: link) {
                // Online streaming playback
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear {
                        let avPlayer = AVPlayer(url: url)
                        self.player = avPlayer
                        setupTimeObserver(player: avPlayer)
                        avPlayer.play()
                    }
                    .onDisappear {
                        cleanupPlayer()
                    }
            } else {
                VStack(spacing: 16) {
                    Text(viewModel.error ?? "Không thể lấy link phát")
                        .foregroundColor(.white)
                        .font(.system(size: 14))
                    Button("Thử lại") {
                        Task { await viewModel.load(chapter: chapter) }
                    }
                    .foregroundColor(.red)
                }
            }

            // Controls overlay: Back button and Title
            VStack {
                HStack(spacing: 12) {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(animeTitle)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        HStack(spacing: 6) {
                            Text(chapter.name)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                            if offlineURL != nil {
                                Text("• Đang phát ngoại tuyến")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    Spacer()
                }
                .padding()
                Spacer()
            }
        }
        .task {
            if offlineURL == nil {
                await viewModel.load(chapter: chapter)
            }
        }
    }

    private func cleanupPlayer() {
        if let token = timeObserverToken, let p = player {
            p.removeTimeObserver(token)
            timeObserverToken = nil
        }
        player?.pause()
        player = nil
    }

    private func setupTimeObserver(player: AVPlayer) {
        let interval = CMTime(seconds: 5.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            if let duration = player.currentItem?.duration.seconds, duration.isFinite {
                viewModel.saveProgress(
                    animeId: animeId,
                    animeTitle: animeTitle,
                    chapter: chapter,
                    poster: poster,
                    current: time.seconds,
                    total: duration
                )
            }
        }
    }
}
