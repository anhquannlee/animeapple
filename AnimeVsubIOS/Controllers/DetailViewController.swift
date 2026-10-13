// DetailViewController.swift
// AnimeVsubIOS (iOS 12+)

import UIKit

final class DetailViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    private let animeID: String
    private var detail: AnimeDetail? = nil
    private var episodes: [ChapterInfo] = []

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let posterView = AsyncImageView()
    private let titleLabel = UILabel()
    private let rateLabel = UILabel()
    private let genresLabel = UILabel()
    private let descLabel = UILabel()
    private let episodesTitleLabel = UILabel()
    private var episodeCollectionView: UICollectionView!
    private let loadingIndicator = UIActivityIndicatorView(style: .whiteLarge)

    init(animeID: String, initialTitle: String? = nil) {
        self.animeID = animeID
        super.init(nibName: nil, bundle: nil)
        title = initialTitle ?? "Chi tiết"
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.08, alpha: 1)
        setupViews()
        loadDetail()

        NotificationCenter.default.addObserver(self, selector: #selector(handleDownloadsChanged), name: DownloadManager.didChangeNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleDownloadsChanged() {
        DispatchQueue.main.async { [weak self] in
            self?.episodeCollectionView.reloadData()
        }
    }

    private func setupViews() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        posterView.contentMode = .scaleAspectFill
        posterView.clipsToBounds = true
        posterView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(posterView)

        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        rateLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        rateLabel.textColor = UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0)
        rateLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(rateLabel)

        genresLabel.font = UIFont.systemFont(ofSize: 12)
        genresLabel.textColor = UIColor(white: 0.7, alpha: 1)
        genresLabel.numberOfLines = 1
        genresLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(genresLabel)

        descLabel.font = UIFont.systemFont(ofSize: 13)
        descLabel.textColor = UIColor(white: 0.85, alpha: 1)
        descLabel.numberOfLines = 0
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(descLabel)

        episodesTitleLabel.text = "Danh sách tập"
        episodesTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        episodesTitleLabel.textColor = .white
        episodesTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(episodesTitleLabel)

        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        episodeCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        episodeCollectionView.backgroundColor = .clear
        episodeCollectionView.dataSource = self
        episodeCollectionView.delegate = self
        episodeCollectionView.isScrollEnabled = false
        episodeCollectionView.register(EpisodeGridCell.self, forCellWithReuseIdentifier: EpisodeGridCell.reuseIdentifier)
        episodeCollectionView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(episodeCollectionView)

        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.startAnimating()
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            posterView.topAnchor.constraint(equalTo: contentView.topAnchor),
            posterView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            posterView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            posterView.heightAnchor.constraint(equalToConstant: 220),

            titleLabel.topAnchor.constraint(equalTo: posterView.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            rateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            rateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            rateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            genresLabel.topAnchor.constraint(equalTo: rateLabel.bottomAnchor, constant: 4),
            genresLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            genresLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            descLabel.topAnchor.constraint(equalTo: genresLabel.bottomAnchor, constant: 10),
            descLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            descLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            episodesTitleLabel.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 20),
            episodesTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            episodesTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            episodeCollectionView.topAnchor.constraint(equalTo: episodesTitleLabel.bottomAnchor, constant: 10),
            episodeCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            episodeCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            episodeCollectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30),
            episodeCollectionView.heightAnchor.constraint(equalToConstant: 200), // Updated dynamically

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func loadDetail() {
        APIClient.shared.episodes(animeID: animeID) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.loadingIndicator.stopAnimating()
                switch result {
                case .success(let chaps):
                    self.episodes = chaps
                    self.episodesTitleLabel.text = "Danh sách tập (\(chaps.count))"
                    self.updateCollectionViewHeight()
                    self.episodeCollectionView.reloadData()
                case .failure(let err):
                    self.descLabel.text = "Không tải được danh sách tập: \(err.description)"
                }
            }
        }
    }

    private func updateCollectionViewHeight() {
        let cols: CGFloat = 3
        let rows = ceil(CGFloat(episodes.count) / cols)
        let height = max(rows * 44 + (rows - 1) * 8, 50)
        for c in episodeCollectionView.constraints where c.firstAttribute == .height {
            c.constant = height
        }
        view.layoutIfNeeded()
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return episodes.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EpisodeGridCell.reuseIdentifier, for: indexPath) as! EpisodeGridCell
        let chapter = episodes[indexPath.item]
        cell.configure(chapter: chapter, animeId: animeID, animeTitle: title ?? "") { [weak self] in
            guard let self = self else { return }
            self.startDownload(chapter: chapter)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing: CGFloat = 8
        let totalMargin = spacing * 2
        let width = floor((collectionView.bounds.width - totalMargin) / 3)
        return CGSize(width: width, height: 44)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let chapter = episodes[indexPath.item]
        openPlayer(chapter: chapter)
    }

    private func openPlayer(chapter: ChapterInfo) {
        let playerVC = PlayerViewController(animeID: animeID, animeTitle: title ?? "", chapter: chapter, poster: nil)
        present(playerVC, animated: true, completion: nil)
    }

    private func startDownload(chapter: ChapterInfo) {
        DownloadManager.shared.startDownload(
            animeId: animeID,
            chapter: chapter,
            title: title ?? "",
            poster: nil
        )
        episodeCollectionView.reloadData()
    }
}

// MARK: - Episode Cell with Download button

final class EpisodeGridCell: UICollectionViewCell {
    static let reuseIdentifier = "EpisodeGridCell"

    private let titleLabel = UILabel()
    private let statusIcon = UIImageView()
    private let downloadButton = UIButton(type: .system)
    private var onDownload: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(white: 0.16, alpha: 1)
        layer.cornerRadius = 6
        clipsToBounds = true

        titleLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = .white
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        statusIcon.contentMode = .scaleAspectFit
        statusIcon.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(statusIcon)

        downloadButton.setImage(UIImage(named: "download_icon"), for: .normal)
        downloadButton.setTitle("📥", for: .normal)
        downloadButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        downloadButton.addTarget(self, action: #selector(handleDownload), for: .touchUpInside)
        downloadButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(downloadButton)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: downloadButton.leadingAnchor, constant: -4),

            statusIcon.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            statusIcon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            statusIcon.widthAnchor.constraint(equalToConstant: 16),
            statusIcon.heightAnchor.constraint(equalToConstant: 16),

            downloadButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            downloadButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            downloadButton.widthAnchor.constraint(equalToConstant: 28),
            downloadButton.heightAnchor.constraint(equalToConstant: 28)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(chapter: ChapterInfo, animeId: String, animeTitle: String, onDownload: @escaping () -> Void) {
        self.onDownload = onDownload
        titleLabel.text = chapter.name

        let dm = DownloadManager.shared
        if dm.isDownloaded(chapterId: chapter.id) {
            backgroundColor = UIColor(red: 0.1, green: 0.35, blue: 0.15, alpha: 1)
            downloadButton.isHidden = true
            statusIcon.isHidden = false
            statusIcon.tintColor = .green
        } else if let rec = dm.getRecord(chapterId: chapter.id), rec.isDownloading {
            backgroundColor = UIColor(red: 0.35, green: 0.15, blue: 0.1, alpha: 1)
            downloadButton.isHidden = false
            downloadButton.setTitle("\(rec.progressPercent)%", for: .normal)
            downloadButton.setTitleColor(.yellow, for: .normal)
            statusIcon.isHidden = true
        } else {
            backgroundColor = UIColor(white: 0.16, alpha: 1)
            downloadButton.isHidden = false
            downloadButton.setTitle("📥", for: .normal)
            downloadButton.setTitleColor(.white, for: .normal)
            statusIcon.isHidden = true
        }
    }

    @objc private func handleDownload() {
        onDownload?()
    }
}
