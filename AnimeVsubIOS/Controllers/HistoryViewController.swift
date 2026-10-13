// HistoryViewController.swift
// AnimeVsubIOS (iOS 12+)

import UIKit

final class HistoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()
    private var records: [HistoryRecord] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Lịch sử xem"
        view.backgroundColor = UIColor(white: 0.08, alpha: 1)
        navigationController?.navigationBar.barTintColor = UIColor(white: 0.1, alpha: 1)
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Xoá hết", style: .plain, target: self, action: #selector(handleClearAll))

        setupUI()
        reload()

        NotificationCenter.default.addObserver(self, selector: #selector(handleHistoryChanged), name: WatchHistoryManager.didChangeNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleHistoryChanged() {
        DispatchQueue.main.async { [weak self] in
            self?.reload()
        }
    }

    private func setupUI() {
        tableView.backgroundColor = UIColor(white: 0.08, alpha: 1)
        tableView.separatorColor = UIColor(white: 0.2, alpha: 1)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(HistoryTableCell.self, forCellReuseIdentifier: HistoryTableCell.reuseIdentifier)
        tableView.rowHeight = 80
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        emptyLabel.text = "Chưa có lịch sử xem phim."
        emptyLabel.font = UIFont.systemFont(ofSize: 14)
        emptyLabel.textColor = UIColor(white: 0.7, alpha: 1)
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func reload() {
        records = WatchHistoryManager.shared.getAll()
        emptyLabel.isHidden = !records.isEmpty
        navigationItem.rightBarButtonItem?.isEnabled = !records.isEmpty
        tableView.reloadData()
    }

    @objc private func handleClearAll() {
        let alert = UIAlertController(title: "Xác nhận", message: "Bạn có chắc muốn xoá toàn bộ lịch sử xem?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Xoá", style: .destructive) { _ in
            WatchHistoryManager.shared.clearAll()
        })
        alert.addAction(UIAlertAction(title: "Huỷ", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return records.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HistoryTableCell.reuseIdentifier, for: indexPath) as! HistoryTableCell
        let rec = records[indexPath.row]
        cell.configure(record: rec)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let rec = records[indexPath.row]
        let chapter = ChapterInfo(id: rec.chapterId, name: rec.chapterName)
        let playerVC = PlayerViewController(
            animeID: rec.animeId,
            animeTitle: rec.title,
            chapter: chapter,
            poster: rec.poster
        )
        present(playerVC, animated: true, completion: nil)
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let rec = records[indexPath.row]
            WatchHistoryManager.shared.delete(animeId: rec.animeId)
        }
    }
}

// MARK: - History Table Cell

final class HistoryTableCell: UITableViewCell {
    static let reuseIdentifier = "HistoryTableCell"

    private let posterView = AsyncImageView()
    private let titleLabel = UILabel()
    private let chapterLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .default)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = UIColor(white: 0.1, alpha: 1)
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = UIColor(white: 0.18, alpha: 1)

        posterView.contentMode = .scaleAspectFill
        posterView.clipsToBounds = true
        posterView.layer.cornerRadius = 6
        posterView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(posterView)

        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        chapterLabel.font = UIFont.systemFont(ofSize: 12)
        chapterLabel.textColor = UIColor(white: 0.7, alpha: 1)
        chapterLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(chapterLabel)

        progressView.progressTintColor = .red
        progressView.trackTintColor = UIColor(white: 0.25, alpha: 1)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(progressView)

        NSLayoutConstraint.activate([
            posterView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            posterView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            posterView.widthAnchor.constraint(equalToConstant: 45),
            posterView.heightAnchor.constraint(equalToConstant: 60),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: posterView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),

            chapterLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            chapterLabel.leadingAnchor.constraint(equalTo: posterView.trailingAnchor, constant: 12),
            chapterLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),

            progressView.leadingAnchor.constraint(equalTo: posterView.trailingAnchor, constant: 12),
            progressView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            progressView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(record: HistoryRecord) {
        titleLabel.text = record.title
        chapterLabel.text = "Đang xem: \(record.chapterName)"
        posterView.load(urlString: record.poster)
        progressView.setProgress(Float(record.progressPercent), animated: false)
    }
}
