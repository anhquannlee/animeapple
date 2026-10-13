// DownloadsScreen.swift
// AnimeVsubIOS
//
// Shows all downloaded episodes and active downloads with progress.

import SwiftUI

struct DownloadsScreen: View {
    @ObservedObject private var downloadManager = DownloadManager.shared
    @State private var playingRecord: DownloadRecord? = nil

    var body: some View {
        List {
            if downloadManager.records.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("Chưa có tập phim nào được tải về.")
                        .foregroundColor(.gray)
                        .font(.system(size: 15))
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 60)
                .listRowBackground(Color.clear)
            } else {
                ForEach(downloadManager.records) { record in
                    DownloadItemRow(record: record) {
                        if record.isCompleted {
                            playingRecord = record
                        }
                    } onCancel: {
                        downloadManager.deleteDownload(chapterId: record.id)
                    }
                    .listRowBackground(Color(hex: "#1a1a1a"))
                }
                .onDelete { indexSet in
                    for idx in indexSet {
                        let rec = downloadManager.records[idx]
                        downloadManager.deleteDownload(chapterId: rec.id)
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
        .background(Color(hex: "#121212").ignoresSafeArea())
        .navigationTitle("Đã tải xuống")
        .toolbar {
            if !downloadManager.records.isEmpty {
                Button("Xoá hết") {
                    downloadManager.clearAll()
                }
                .foregroundColor(.red)
            }
        }
        .fullScreenCover(item: $playingRecord) { record in
            if let localURL = downloadManager.localURL(for: record.id) {
                OfflinePlayerView(title: "\(record.title) - \(record.chapterName)", fileURL: localURL)
            }
        }
    }
}

// MARK: - Row

private struct DownloadItemRow: View {
    let record: DownloadRecord
    let onPlay: () -> Void
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Poster
            AsyncImage(url: URL(string: record.poster ?? "")) { phase in
                if let img = phase.image {
                    img.resizable().scaledToFill()
                } else {
                    Color.gray.opacity(0.3)
                }
            }
            .frame(width: 55, height: 75)
            .cornerRadius(6)
            .clipped()

            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(record.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(record.chapterName)
                    .font(.system(size: 12))
                    .foregroundColor(Color.white.opacity(0.7))

                if record.isCompleted {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                        Text("Đã tải xong")
                            .font(.system(size: 11))
                            .foregroundColor(.green)
                    }
                } else if record.state.starts(with: "error") {
                    Text(record.state)
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                        .lineLimit(1)
                } else {
                    // Downloading progress
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Đang tải: \(record.progressPercent)%")
                                .font(.system(size: 11))
                                .foregroundColor(.red)
                            Spacer()
                            if record.totalSegments > 0 {
                                Text("\(record.downloadedSegments)/\(record.totalSegments)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                            }
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.15))
                                    .frame(height: 4)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.red)
                                    .frame(width: geo.size.width * CGFloat(record.progress), height: 4)
                            }
                        }
                        .frame(height: 4)
                    }
                }
            }

            Spacer()

            // Action button
            if record.isCompleted {
                Button(action: onPlay) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.red)
                }
                .buttonStyle(BorderlessButtonStyle())
            } else {
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 22))
                        .foregroundColor(.gray)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            if record.isCompleted { onPlay() }
        }
    }
}

// MARK: - Offline Player View

import AVKit

struct OfflinePlayerView: View {
    let title: String
    let fileURL: URL
    @Environment(\.presentationMode) var presentationMode
    @State private var player: AVPlayer? = nil

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            }

            VStack {
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Spacer()
                }
                .padding()
                Spacer()
            }
        }
        .onAppear {
            let p = AVPlayer(url: fileURL)
            self.player = p
            p.play()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
}
