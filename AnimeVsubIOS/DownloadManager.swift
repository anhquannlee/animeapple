// DownloadManager.swift
// AnimeVsubIOS (iOS 12+)
//
// Robust offline video download manager with HLS segment parsing and direct MP4 support.
// Fixes 0% hang by accurately parsing playlist segments and updating progress per-segment.

import Foundation

public struct DownloadRecord: Codable, Hashable {
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
        downloadedSegments: Int = 0
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
    }
}

public final class DownloadManager: NSObject {
    public static let shared = DownloadManager()
    public static let didChangeNotification = Notification.Name("AnimeVsubDownloadsDidChange")

    private let recordsKey = "AnimeVsub_DownloadRecords_v3"
    private var records: [DownloadRecord] = []
    private var activeTasks: [String: URLSessionDataTask] = [:]
    private var isCancelled: [String: Bool] = [:]

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        return URLSession(configuration: config)
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

    public func allRecords() -> [DownloadRecord] {
        return records
    }

    public func isDownloaded(chapterId: String) -> Bool {
        guard let rec = records.first(where: { $0.id == chapterId }), rec.isCompleted,
              let path = rec.localPath else { return false }
        return FileManager.default.fileExists(atPath: path)
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

    // MARK: - Start Download

    public func startDownload(
        animeId: String,
        chapter: ChapterInfo,
        title: String,
        poster: String?,
        videoURL: String? = nil
    ) {
        let chapterId = chapter.id
        if isDownloaded(chapterId: chapterId) { return }

        cancelDownload(chapterId: chapterId)
        isCancelled[chapterId] = false

        var record = DownloadRecord(
            id: chapterId,
            animeId: animeId,
            title: title,
            chapterName: chapter.name,
            poster: poster,
            sourceURL: videoURL ?? "",
            progress: 0.02, // 2% immediate indicator to prevent 0% hang
            state: "waiting"
        )
        upsertRecord(record)

        if let vUrl = videoURL, !vUrl.isEmpty, let url = URL(string: vUrl) {
            executeDownload(record: record, url: url)
        } else {
            // Fetch player link via APIClient
            APIClient.shared.player(chapter: chapter) { [weak self] result in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    switch result {
                    case .success(let data):
                        if let url = URL(string: data.link) {
                            record.sourceURL = data.link
                            self.upsertRecord(record)
                            self.executeDownload(record: record, url: url)
                        } else {
                            self.markError(chapterId: chapterId, message: "Link video không hợp lệ")
                        }
                    case .failure(let err):
                        self.markError(chapterId: chapterId, message: err.description)
                    }
                }
            }
        }
    }

    public func cancelDownload(chapterId: String) {
        isCancelled[chapterId] = true
        activeTasks[chapterId]?.cancel()
        activeTasks.removeValue(forKey: chapterId)

        if let idx = records.firstIndex(where: { $0.id == chapterId }), records[idx].isDownloading {
            if let path = records[idx].localPath {
                try? FileManager.default.removeItem(atPath: path)
            }
            records.remove(at: idx)
            saveRecords()
        }
    }

    public func deleteDownload(chapterId: String) {
        cancelDownload(chapterId: chapterId)
        if let idx = records.firstIndex(where: { $0.id == chapterId }) {
            if let path = records[idx].localPath {
                try? FileManager.default.removeItem(atPath: path)
            }
            records.remove(at: idx)
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

    // MARK: - Download Execution

    private func executeDownload(record: DownloadRecord, url: URL) {
        let chapterId = record.id
        updateState(chapterId: chapterId, state: "downloading", progress: 0.03)

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 12_5 like Mac OS X) AppleWebKit/605.1.15 Mobile Safari/604.1", forHTTPHeaderField: "User-Agent")
        if let host = url.host { request.setValue("https://\(host)/", forHTTPHeaderField: "Referer") }

        let task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            if self.isCancelled[chapterId] == true { return }

            guard let data = data, error == nil,
                  let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                self.markError(chapterId: chapterId, message: error?.localizedDescription ?? "Lỗi phản hồi HTTP")
                return
            }

            let text = String(data: data, encoding: .utf8) ?? ""
            if text.contains("#EXTM3U") {
                // HLS Playlist
                self.processHLS(chapterId: chapterId, baseURL: url, manifest: text)
            } else {
                // Direct MP4
                self.saveDirectFile(chapterId: chapterId, data: data)
            }
        }
        activeTasks[chapterId] = task
        task.resume()
    }

    // MARK: - HLS Processing

    private func processHLS(chapterId: String, baseURL: URL, manifest: String) {
        if manifest.contains("#EXT-X-STREAM-INF") {
            // Master playlist: pick highest variant
            if let variantURL = extractVariantURL(manifest: manifest, baseURL: baseURL) {
                var req = URLRequest(url: variantURL)
                req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 12_5 like Mac OS X) AppleWebKit/605.1.15 Mobile Safari/604.1", forHTTPHeaderField: "User-Agent")
                if let host = variantURL.host { req.setValue("https://\(host)/", forHTTPHeaderField: "Referer") }

                let task = session.dataTask(with: req) { [weak self] data, _, error in
                    guard let self = self else { return }
                    if self.isCancelled[chapterId] == true { return }
                    guard let data = data, let text = String(data: data, encoding: .utf8) else {
                        self.markError(chapterId: chapterId, message: error?.localizedDescription ?? "Không đọc được playlist")
                        return
                    }
                    self.downloadSegments(chapterId: chapterId, baseURL: variantURL, manifest: text)
                }
                activeTasks[chapterId] = task
                task.resume()
                return
            }
        }

        downloadSegments(chapterId: chapterId, baseURL: baseURL, manifest: manifest)
    }

    private func downloadSegments(chapterId: String, baseURL: URL, manifest: String) {
        let lines = manifest.components(separatedBy: .newlines)
        var segmentURLs: [URL] = []
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }
            if let u = URL(string: trimmed, relativeTo: baseURL)?.absoluteURL {
                segmentURLs.append(u)
            }
        }

        guard !segmentURLs.isEmpty else {
            markError(chapterId: chapterId, message: "Playlist không có segment video")
            return
        }

        let total = segmentURLs.count
        updateTotalSegments(chapterId: chapterId, total: total)

        let destination = downloadsDirectory.appendingPathComponent("\(chapterId).ts")
        try? FileManager.default.removeItem(at: destination)
        FileManager.default.createFile(atPath: destination.path, contents: nil)

        fetchNextSegment(chapterId: chapterId, segmentURLs: segmentURLs, index: 0, destination: destination)
    }

    private func fetchNextSegment(chapterId: String, segmentURLs: [URL], index: Int, destination: URL) {
        if isCancelled[chapterId] == true {
            try? FileManager.default.removeItem(at: destination)
            return
        }

        let total = segmentURLs.count
        guard index < total else {
            // All segments downloaded!
            markCompleted(chapterId: chapterId, localPath: destination.path)
            return
        }

        let segURL = segmentURLs[index]
        var req = URLRequest(url: segURL)
        req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 12_5 like Mac OS X) AppleWebKit/605.1.15 Mobile Safari/604.1", forHTTPHeaderField: "User-Agent")
        if let host = segURL.host { req.setValue("https://\(host)/", forHTTPHeaderField: "Referer") }

        let task = session.dataTask(with: req) { [weak self] data, response, error in
            guard let self = self else { return }
            if self.isCancelled[chapterId] == true { return }

            guard let data = data, error == nil,
                  let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                self.markError(chapterId: chapterId, message: "Lỗi tải đoạn \(index + 1)/\(total)")
                return
            }

            // Append data to destination file
            if let handle = try? FileHandle(forWritingTo: destination) {
                handle.seekToEndOfFile()
                handle.write(data)
                handle.closeFile()
            }

            let downloaded = index + 1
            let prog = 0.05 + (Double(downloaded) / Double(total)) * 0.94
            self.updateProgress(chapterId: chapterId, progress: prog, downloadedSegments: downloaded)

            // Next segment
            self.fetchNextSegment(chapterId: chapterId, segmentURLs: segmentURLs, index: index + 1, destination: destination)
        }
        activeTasks[chapterId] = task
        task.resume()
    }

    private func saveDirectFile(chapterId: String, data: Data) {
        let destination = downloadsDirectory.appendingPathComponent("\(chapterId).mp4")
        try? FileManager.default.removeItem(at: destination)
        do {
            try data.write(to: destination)
            markCompleted(chapterId: chapterId, localPath: destination.path)
        } catch {
            markError(chapterId: chapterId, message: "Không lưu được file video")
        }
    }

    // MARK: - Helpers

    private func extractVariantURL(manifest: String, baseURL: URL) -> URL? {
        let lines = manifest.components(separatedBy: .newlines)
        for (i, line) in lines.enumerated() where line.contains("#EXT-X-STREAM-INF") {
            if i + 1 < lines.count {
                let next = lines[i + 1].trimmingCharacters(in: .whitespacesAndNewlines)
                if !next.isEmpty && !next.hasPrefix("#") {
                    return URL(string: next, relativeTo: baseURL)?.absoluteURL
                }
            }
        }
        return nil
    }

    private func upsertRecord(_ record: DownloadRecord) {
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

    private func saveRecords() {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: recordsKey)
        }
        NotificationCenter.default.post(name: DownloadManager.didChangeNotification, object: nil)
    }

    private func loadRecords() {
        if let data = UserDefaults.standard.data(forKey: recordsKey),
           let saved = try? JSONDecoder().decode([DownloadRecord].self, from: data) {
            records = saved.map { mut in
                var item = mut
                if item.state == "completed", let path = item.localPath, !FileManager.default.fileExists(atPath: path) {
                    item.state = "error: file bị xoá"
                } else if item.isDownloading {
                    item.state = "error: bị ngắt quãng"
                }
                return item
            }
        }
    }
}
