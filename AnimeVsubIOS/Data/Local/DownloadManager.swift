// DownloadManager.swift
// AnimeVsubIOS
//
// Robust offline video download manager with HLS segment parsing and direct MP4 support.
// Fixes 0% hang by accurately parsing playlist segments and updating progress per-segment.

import Foundation
import Combine
import AVFoundation

// MARK: - DownloadRecord

public struct DownloadRecord: Codable, Identifiable, Hashable {
    public let id: String              // chapterId
    public let animeId: String
    public let title: String           // anime title
    public let chapterName: String     // episode title, e.g. "Tập 1"
    public let poster: String?
    public var sourceURL: String
    public var localPath: String?
    public var progress: Double        // 0.0 ... 1.0
    public var state: String           // "waiting", "downloading", "completed", "error: ..."
    public var totalSegments: Int
    public var downloadedSegments: Int
    public var totalBytes: Int64

    public var progressPercent: Int {
        return Int(min(max(progress, 0.0), 1.0) * 100)
    }

    public var isCompleted: Bool {
        return state == "completed"
    }

    public var isDownloading: Bool {
        return state == "downloading" || state == "waiting"
    }

    public init(
        id: String,
        animeId: String,
        title: String,
        chapterName: String,
        poster: String?,
        sourceURL: String = "",
        localPath: String? = nil,
        progress: Double = 0.0,
        state: String = "waiting",
        totalSegments: Int = 0,
        downloadedSegments: Int = 0,
        totalBytes: Int64 = 0
    ) {
        self.id = id
        self.animeId = animeId
        self.title = title
        self.chapterName = chapterName
        self.poster = poster
        self.sourceURL = sourceURL
        self.localPath = localPath
        self.progress = progress
        self.state = state
        self.totalSegments = totalSegments
        self.downloadedSegments = downloadedSegments
        self.totalBytes = totalBytes
    }
}

// MARK: - DownloadManager

public final class DownloadManager: NSObject, ObservableObject, URLSessionDownloadDelegate {
    public static let shared = DownloadManager()

    @Published public private(set) var records: [DownloadRecord] = []

    private let recordsKey = "AnimeVsub_DownloadRecords_v2"
    private var activeTasks: [String: Task<Void, Never>] = [:]
    private var directDownloadTasks: [Int: String] = [:] // taskIdentifier -> recordId

    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 600
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    private var downloadsDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Downloads", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    override private init() {
        super.init()
        loadRecords()
    }

    // MARK: - Public Queries

    public func isDownloaded(chapterId: String) -> Bool {
        guard let rec = records.first(where: { $0.id == chapterId }), rec.isCompleted,
              let path = rec.localPath else { return false }
        return FileManager.default.fileExists(atPath: path)
    }

    public func isDownloading(chapterId: String) -> Bool {
        guard let rec = records.first(where: { $0.id == chapterId }) else { return false }
        return rec.isDownloading
    }

    public func localURL(for chapterId: String) -> URL? {
        guard let rec = records.first(where: { $0.id == chapterId }),
              let path = rec.localPath,
              FileManager.default.fileExists(atPath: path) else { return nil }
        return URL(fileURLWithPath: path)
    }

    public func getRecord(chapterId: String) -> DownloadRecord? {
        return records.first { $0.id == chapterId }
    }

    // MARK: - Download Actions

    public func startDownload(
        animeId: String,
        chapter: ChapterInfo,
        title: String,
        poster: String?,
        videoURL: String? = nil
    ) {
        let chapterId = chapter.id
        if isDownloaded(chapterId: chapterId) { return }

        // If already downloading, cancel existing task to restart clean
        cancelDownload(chapterId: chapterId)

        var record = DownloadRecord(
            id: chapterId,
            animeId: animeId,
            title: title,
            chapterName: chapter.name,
            poster: poster,
            sourceURL: videoURL ?? "",
            progress: 0.01, // Start with 1% immediately to avoid 0% stuck perception
            state: "waiting"
        )
        updateOrAddRecord(record)

        let task = Task { [weak self] in
            guard let self = self else { return }

            var resolvedURL = videoURL ?? ""
            if resolvedURL.isEmpty {
                // Fetch server and player link automatically
                do {
                    let servers = try await AnimeRepository.shared.getServers(chapter: chapter)
                    if let firstServer = servers.first {
                        let playerData = try await AnimeRepository.shared.getPlayerLink(server: firstServer)
                        resolvedURL = playerData.link
                    }
                } catch {
                    self.markError(chapterId: chapterId, message: "Không lấy được link: \(error.localizedDescription)")
                    return
                }
            }

            guard !resolvedURL.isEmpty, let url = URL(string: resolvedURL) else {
                self.markError(chapterId: chapterId, message: "Link tải không hợp lệ")
                return
            }

            record.sourceURL = resolvedURL
            self.updateOrAddRecord(record)

            await self.executeDownload(record: record, url: url)
        }
        activeTasks[chapterId] = task
    }

    public func cancelDownload(chapterId: String) {
        activeTasks[chapterId]?.cancel()
        activeTasks.removeValue(forKey: chapterId)

        if let index = records.firstIndex(where: { $0.id == chapterId }), records[index].isDownloading {
            if let path = records[index].localPath {
                try? FileManager.default.removeItem(atPath: path)
            }
            records.remove(at: index)
            saveRecords()
        }
    }

    public func deleteDownload(chapterId: String) {
        cancelDownload(chapterId: chapterId)
        if let index = records.firstIndex(where: { $0.id == chapterId }) {
            if let path = records[index].localPath {
                try? FileManager.default.removeItem(atPath: path)
            }
            records.remove(at: index)
            saveRecords()
        }
    }

    public func clearAll() {
        for record in records {
            cancelDownload(chapterId: record.id)
            if let path = record.localPath {
                try? FileManager.default.removeItem(atPath: path)
            }
        }
        records.removeAll()
        saveRecords()
    }

    // MARK: - Internal Download Logic

    private func executeDownload(record: DownloadRecord, url: URL) async {
        let chapterId = record.id
        updateState(chapterId: chapterId, state: "downloading", progress: 0.02)

        do {
            // Step 1: Probe URL with HTTP GET to inspect Content-Type / Manifest
            var request = URLRequest(url: url)
            request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 Mobile Safari/604.1", forHTTPHeaderField: "User-Agent")
            if let host = url.host {
                request.setValue("https://\(host)/", forHTTPHeaderField: "Referer")
            }

            let (data, response) = try await urlSession.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                markError(chapterId: chapterId, message: "Server phản hồi mã lỗi HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                return
            }

            let text = String(data: data, encoding: .utf8) ?? ""

            // Step 2: Determine if HLS (.m3u8) or Direct Video File
            if text.contains("#EXTM3U") {
                // HLS Stream
                await downloadHLS(chapterId: chapterId, baseURL: url, manifestText: text)
            } else {
                // Direct MP4 / binary stream
                await downloadDirectVideo(chapterId: chapterId, url: url, initialData: data)
            }
        } catch {
            if !Task.isCancelled {
                markError(chapterId: chapterId, message: error.localizedDescription)
            }
        }
    }

    // MARK: - HLS Download Pipeline

    private func downloadHLS(chapterId: String, baseURL: URL, manifestText: String) async {
        var mediaManifestText = manifestText
        var mediaBaseURL = baseURL

        // Check for Master Playlist with variant streams (#EXT-X-STREAM-INF)
        if manifestText.contains("#EXT-X-STREAM-INF") {
            updateProgress(chapterId: chapterId, progress: 0.05)
            if let variantURL = extractHighestQualityVariant(from: manifestText, baseURL: baseURL) {
                mediaBaseURL = variantURL
                do {
                    var req = URLRequest(url: variantURL)
                    req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 Mobile Safari/604.1", forHTTPHeaderField: "User-Agent")
                    if let host = variantURL.host { req.setValue("https://\(host)/", forHTTPHeaderField: "Referer") }
                    let (vData, _) = try await urlSession.data(for: req)
                    mediaManifestText = String(data: vData, encoding: .utf8) ?? ""
                } catch {
                    markError(chapterId: chapterId, message: "Không tải được playlist phân giải: \(error.localizedDescription)")
                    return
                }
            }
        }

        // Parse Segments
        let segmentURLs = extractSegmentURLs(from: mediaManifestText, baseURL: mediaBaseURL)
        guard !segmentURLs.isEmpty else {
            markError(chapterId: chapterId, message: "Không tìm thấy segment video trong playlist")
            return
        }

        let total = segmentURLs.count
        updateTotalSegments(chapterId: chapterId, total: total)
        updateProgress(chapterId: chapterId, progress: 0.05)

        // Destination file (.ts container playable natively by AVPlayer)
        let destination = downloadsDirectory.appendingPathComponent("\(chapterId).ts")
        try? FileManager.default.removeItem(at: destination)
        FileManager.default.createFile(atPath: destination.path, contents: nil)

        guard let fileHandle = try? FileHandle(forWritingTo: destination) else {
            markError(chapterId: chapterId, message: "Không tạo được file lưu trữ")
            return
        }
        defer { try? fileHandle.close() }

        // Download segments sequentially with retry to ensure ordered continuous TS stream
        var downloaded = 0
        for (index, segmentURL) in segmentURLs.enumerated() {
            if Task.isCancelled {
                try? FileManager.default.removeItem(at: destination)
                return
            }

            var segmentData: Data? = nil
            for attempt in 1...3 {
                do {
                    var req = URLRequest(url: segmentURL)
                    req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 Mobile Safari/604.1", forHTTPHeaderField: "User-Agent")
                    if let host = segmentURL.host { req.setValue("https://\(host)/", forHTTPHeaderField: "Referer") }
                    let (data, res) = try await urlSession.data(for: req)
                    if let http = res as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                        segmentData = data
                        break
                    }
                } catch {
                    if attempt == 3 {
                        markError(chapterId: chapterId, message: "Lỗi tải đoạn video \(index + 1)/\(total)")
                        return
                    }
                    try? await Task.sleep(nanoseconds: 500_000_000)
                }
            }

            guard let data = segmentData else {
                markError(chapterId: chapterId, message: "Không tải được đoạn video \(index + 1)/\(total)")
                return
            }

            fileHandle.write(data)
            downloaded += 1

            // Dynamic progress: min 5% to 99% during segments, 100% on complete
            let prog = 0.05 + (Double(downloaded) / Double(total)) * 0.94
            updateProgress(chapterId: chapterId, progress: prog, downloadedSegments: downloaded)
        }

        // Completed
        markCompleted(chapterId: chapterId, localPath: destination.path)
    }

    // MARK: - Direct Video Download

    private func downloadDirectVideo(chapterId: String, url: URL, initialData: Data) async {
        let destination = downloadsDirectory.appendingPathComponent("\(chapterId).mp4")
        try? FileManager.default.removeItem(at: destination)

        do {
            try initialData.write(to: destination)
            markCompleted(chapterId: chapterId, localPath: destination.path)
        } catch {
            markError(chapterId: chapterId, message: "Không ghi được file video: \(error.localizedDescription)")
        }
    }

    // MARK: - Playlist Parser Helpers

    private func extractHighestQualityVariant(from manifest: String, baseURL: URL) -> URL? {
        let lines = manifest.components(separatedBy: .newlines)
        var bestURL: URL? = nil
        var bestBandwidth: Int = 0

        for (i, line) in lines.enumerated() where line.contains("#EXT-X-STREAM-INF") {
            let bw = extractAttribute("BANDWIDTH", from: line).flatMap(Int.init) ?? 0
            if i + 1 < lines.count {
                let nextLine = lines[i + 1].trimmingCharacters(in: .whitespacesAndNewlines)
                if !nextLine.isEmpty && !nextLine.hasPrefix("#") {
                    if let target = URL(string: nextLine, relativeTo: baseURL)?.absoluteURL {
                        if bw >= bestBandwidth || bestURL == nil {
                            bestBandwidth = bw
                            bestURL = target
                        }
                    }
                }
            }
        }
        return bestURL
    }

    private func extractSegmentURLs(from manifest: String, baseURL: URL) -> [URL] {
        let lines = manifest.components(separatedBy: .newlines)
        var urls: [URL] = []
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }
            if let segmentURL = URL(string: trimmed, relativeTo: baseURL)?.absoluteURL {
                urls.append(segmentURL)
            }
        }
        return urls
    }

    private func extractAttribute(_ key: String, from line: String) -> String? {
        guard let range = line.range(of: "\(key)=") else { return nil }
        let sub = line[range.upperBound...]
        if sub.hasPrefix("\"") {
            let withoutQuote = sub.dropFirst()
            if let endQuote = withoutQuote.firstIndex(of: "\"") {
                return String(withoutQuote[..<endQuote])
            }
        } else {
            let value = sub.prefix { $0 != "," && $0 != " " && $0 != "\n" }
            return String(value)
        }
        return nil
    }

    // MARK: - State Management

    private func updateOrAddRecord(_ record: DownloadRecord) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let idx = self.records.firstIndex(where: { $0.id == record.id }) {
                self.records[idx] = record
            } else {
                self.records.insert(record, at: 0)
            }
            self.saveRecords()
        }
    }

    private func updateState(chapterId: String, state: String, progress: Double? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let idx = self.records.firstIndex(where: { $0.id == chapterId }) else { return }
            self.records[idx].state = state
            if let p = progress { self.records[idx].progress = p }
            self.saveRecords()
        }
    }

    private func updateTotalSegments(chapterId: String, total: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let idx = self.records.firstIndex(where: { $0.id == chapterId }) else { return }
            self.records[idx].totalSegments = total
            self.saveRecords()
        }
    }

    private func updateProgress(chapterId: String, progress: Double, downloadedSegments: Int? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let idx = self.records.firstIndex(where: { $0.id == chapterId }) else { return }
            self.records[idx].progress = min(max(progress, 0.0), 1.0)
            if let seg = downloadedSegments { self.records[idx].downloadedSegments = seg }
            self.saveRecords()
        }
    }

    private func markCompleted(chapterId: String, localPath: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let idx = self.records.firstIndex(where: { $0.id == chapterId }) else { return }
            self.records[idx].state = "completed"
            self.records[idx].progress = 1.0
            self.records[idx].localPath = localPath
            self.activeTasks.removeValue(forKey: chapterId)
            self.saveRecords()
        }
    }

    private func markError(chapterId: String, message: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let idx = self.records.firstIndex(where: { $0.id == chapterId }) else { return }
            self.records[idx].state = "error: \(message)"
            self.activeTasks.removeValue(forKey: chapterId)
            self.saveRecords()
        }
    }

    // MARK: - URLSessionDownloadDelegate

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // Handled in async pipeline
    }

    // MARK: - Persistence

    private func saveRecords() {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: recordsKey)
        }
    }

    private func loadRecords() {
        if let data = UserDefaults.standard.data(forKey: recordsKey),
           let saved = try? JSONDecoder().decode([DownloadRecord].self, from: data) {
            // Verify files on disk for completed items
            self.records = saved.map { mut in
                var item = mut
                if item.state == "completed", let path = item.localPath, !FileManager.default.fileExists(atPath: path) {
                    item.state = "error: file bị xoá"
                } else if item.state == "downloading" || item.state == "waiting" {
                    // Reset interrupted download state
                    item.state = "error: bị ngắt quãng"
                }
                return item
            }
        }
    }
}
