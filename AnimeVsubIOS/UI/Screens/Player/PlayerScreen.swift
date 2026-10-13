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

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if viewModel.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Đang tải nguồn phát...")
                        .foregroundColor(.white)
                        .font(.system(size: 14))
                }
            } else if let link = viewModel.playerLink, let url = URL(string: link) {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear {
                        let avPlayer = AVPlayer(url: url)
                        self.player = avPlayer
                        setupTimeObserver(player: avPlayer)
                        avPlayer.play()
                    }
                    .onDisappear {
                        if let token = timeObserverToken, let p = player {
                            p.removeTimeObserver(token)
                        }
                        player?.pause()
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

            // Close button top-left
            VStack {
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(16)
                    }
                    Spacer()
                }
                Spacer()
            }
        }
        .task {
            await viewModel.load(chapter: chapter)
        }
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
