import SwiftUI

struct HistoryScreen: View {
    @StateObject private var viewModel = HistoryViewModel()
    @State private var selectedAnimeId: String? = nil

    var body: some View {
        List {
            if viewModel.historyItems.isEmpty {
                Text("Chưa có lịch sử xem phim.")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 40)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(viewModel.historyItems) { item in
                    Button(action: {
                        selectedAnimeId = item.seasonId
                    }) {
                        HStack(spacing: 12) {
                            AsyncImage(url: URL(string: item.poster)) { phase in
                                if let img = phase.image {
                                    img.resizable().scaledToFill()
                                } else {
                                    Color.gray.opacity(0.3)
                                }
                            }
                            .frame(width: 55, height: 75)
                            .cornerRadius(6)
                            .clipped()

                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.name)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)

                                if let chapName = item.chapName {
                                    Text("Đang xem: \(chapName)")
                                        .font(.system(size: 12))
                                        .foregroundColor(.red)
                                }

                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color.white.opacity(0.15))
                                            .frame(height: 4)
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color.red)
                                            .frame(width: geo.size.width * CGFloat(item.progress), height: 4)
                                    }
                                }
                                .frame(height: 4)
                            }
                        }
                    }
                    .listRowBackground(Color(hex: "#1a1a1a"))
                }
                .onDelete { indexSet in
                    for idx in indexSet {
                        viewModel.delete(item: viewModel.historyItems[idx])
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
        .background(Color(hex: "#121212").ignoresSafeArea())
        .navigationTitle("Lịch sử xem")
        .toolbar {
            if !viewModel.historyItems.isEmpty {
                Button("Xoá hết") {
                    viewModel.clearAll()
                }
                .foregroundColor(.red)
            }
        }
        .background(
            NavigationLink(
                destination: Group {
                    if let id = selectedAnimeId {
                        DetailScreen(animeId: id)
                    }
                },
                isActive: Binding(
                    get: { selectedAnimeId != nil },
                    set: { if !$0 { selectedAnimeId = nil } }
                )
            ) {
                EmptyView()
            }
        )
    }
}
