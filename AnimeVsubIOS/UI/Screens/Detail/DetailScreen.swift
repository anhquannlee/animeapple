import SwiftUI
import AVKit

struct DetailScreen: View {
    let animeId: String
    @StateObject private var viewModel: DetailViewModel
    @State private var playingChapter: ChapterInfo? = nil

    init(animeId: String) {
        self.animeId = animeId
        _viewModel = StateObject(wrappedValue: DetailViewModel(animeId: animeId))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.uiState.isLoading {
                    ProgressView("Đang tải thông tin phim...")
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if let detail = viewModel.uiState.detail {
                    // Header / Poster
                    ZStack(alignment: .bottomLeading) {
                        AsyncImage(url: URL(string: detail.poster ?? detail.image ?? "")) { phase in
                            if let img = phase.image {
                                img.resizable().scaledToFill()
                            } else {
                                Color.gray.opacity(0.3)
                            }
                        }
                        .frame(height: 240)
                        .clipped()

                        LinearGradient(colors: [.clear, Color(hex: "#121212")], startPoint: .top, endPoint: .bottom)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(detail.name)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            HStack {
                                Text("⭐ \(String(format: "%.1f", detail.rate))")
                                    .foregroundColor(.yellow)
                                    .font(.system(size: 13, weight: .semibold))
                                Text("• \(detail.quality ?? "HD")")
                                    .foregroundColor(.white.opacity(0.8))
                                    .font(.system(size: 13))
                            }
                        }
                        .padding(16)
                    }

                    // Actions: Follow
                    HStack {
                        Button(action: { viewModel.toggleFollow() }) {
                            HStack {
                                Image(systemName: viewModel.uiState.isFollowed ? "heart.fill" : "heart")
                                Text(viewModel.uiState.isFollowed ? "Đã theo dõi" : "Theo dõi")
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(viewModel.uiState.isFollowed ? Color.red : Color.gray.opacity(0.3))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 16)

                    // Description
                    Text(detail.description)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 16)

                    // Episodes List
                    if let chapterData = viewModel.uiState.chapterData {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Danh sách tập (\(chapterData.chaps.count))")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 10) {
                                ForEach(chapterData.chaps, id: \.id) { chap in
                                    Button(action: {
                                        playingChapter = chap
                                    }) {
                                        Text(chap.name)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(Color.white.opacity(0.1))
                                            .cornerRadius(6)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
            }
            .padding(.bottom, 40)
        }
        .background(Color(hex: "#121212").ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $playingChapter) { chap in
            PlayerScreen(
                animeId: animeId,
                animeTitle: viewModel.uiState.detail?.name ?? "",
                chapter: chap,
                poster: viewModel.uiState.detail?.poster ?? viewModel.uiState.detail?.image
            )
        }
    }
}
