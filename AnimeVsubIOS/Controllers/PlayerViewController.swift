// PlayerViewController.swift
// AnimeVsubIOS (iOS 12+)

import UIKit
import AVFoundation

final class PlayerViewController: UIViewController {
    private let animeID: String
    private let animeTitle: String
    private let chapter: ChapterInfo
    private let poster: String?

    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var timeObserverToken: Any?

    private let controlsOverlay = UIView()
    private let closeButton = UIButton(type: .system)
    private let playPauseButton = UIButton(type: .system)
    private let forward10Button = UIButton(type: .system)
    private let replay10Button = UIButton(type: .system)
    private let timeSlider = UISlider()
    private let timeLabel = UILabel()
    private let titleLabel = UILabel()
    private let offlineBadge = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .whiteLarge)
    private let statusLabel = UILabel()

    init(animeID: String, animeTitle: String, chapter: ChapterInfo, poster: String?) {
        self.animeID = animeID
        self.animeTitle = animeTitle
        self.chapter = chapter
        self.poster = poster
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()

        // Check if downloaded offline
        if let localURL = DownloadManager.shared.localURL(for: chapter.id) {
            offlineBadge.isHidden = false
            startPlayback(url: localURL)
        } else {
            offlineBadge.isHidden = true
            loadOnlineStream()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cleanupPlayer()
    }

    private func setupUI() {
        controlsOverlay.backgroundColor = UIColor(white: 0, alpha: 0.4)
        controlsOverlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controlsOverlay)

        closeButton.setTitle("✕", for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        closeButton.tintColor = .white
        closeButton.addTarget(self, action: #selector(handleClose), for: .touchUpInside)

        titleLabel.text = "\(animeTitle) - \(chapter.name)"
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.lineBreakMode = .byTruncatingTail

        offlineBadge.text = " Ngoại tuyến "
        offlineBadge.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        offlineBadge.textColor = .white
        offlineBadge.backgroundColor = UIColor(red: 0.15, green: 0.6, blue: 0.2, alpha: 0.9)
        offlineBadge.layer.cornerRadius = 4
        offlineBadge.clipsToBounds = true

        playPauseButton.setTitle("❚❚", for: .normal)
        playPauseButton.titleLabel?.font = UIFont.systemFont(ofSize: 32)
        playPauseButton.tintColor = .white
        playPauseButton.addTarget(self, action: #selector(togglePlayPause), for: .touchUpInside)

        replay10Button.setTitle("-10s", for: .normal)
        replay10Button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        replay10Button.tintColor = .white
        replay10Button.addTarget(self, action: #selector(replay10), for: .touchUpInside)

        forward10Button.setTitle("+10s", for: .normal)
        forward10Button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        forward10Button.tintColor = .white
        forward10Button.addTarget(self, action: #selector(forward10), for: .touchUpInside)

        timeSlider.minimumTrackTintColor = .red
        timeSlider.maximumTrackTintColor = UIColor(white: 1, alpha: 0.3)
        timeSlider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)

        timeLabel.text = "00:00 / 00:00"
        timeLabel.font = UIFont.systemFont(ofSize: 11)
        timeLabel.textColor = UIColor(white: 0.8, alpha: 1)

        loadingIndicator.hidesWhenStopped = true
        statusLabel.font = UIFont.systemFont(ofSize: 13)
        statusLabel.textColor = .white
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0

        [closeButton, titleLabel, offlineBadge, playPauseButton, replay10Button, forward10Button,
         timeSlider, timeLabel, loadingIndicator, statusLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            controlsOverlay.addSubview($0)
        }

        NSLayoutConstraint.activate([
            controlsOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            controlsOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controlsOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            controlsOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),

            titleLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: closeButton.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: offlineBadge.leadingAnchor, constant: -8),

            offlineBadge.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            offlineBadge.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),

            playPauseButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playPauseButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            replay10Button.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
            replay10Button.trailingAnchor.constraint(equalTo: playPauseButton.leadingAnchor, constant: -40),

            forward10Button.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
            forward10Button.leadingAnchor.constraint(equalTo: playPauseButton.trailingAnchor, constant: 40),

            timeSlider.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            timeSlider.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -12),
            timeSlider.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),

            timeLabel.centerYAnchor.constraint(equalTo: timeSlider.centerYAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            statusLabel.topAnchor.constraint(equalTo: loadingIndicator.bottomAnchor, constant: 12),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(toggleControls))
        view.addGestureRecognizer(tap)
    }

    private func loadOnlineStream() {
        loadingIndicator.startAnimating()
        statusLabel.text = "Đang lấy link phát…"

        APIClient.shared.player(chapter: chapter) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.loadingIndicator.stopAnimating()
                switch result {
                case .success(let data):
                    if let url = URL(string: data.link) {
                        self.statusLabel.text = nil
                        self.startPlayback(url: url)
                    } else {
                        self.statusLabel.text = "Link phát không hợp lệ"
                    }
                case .failure(let error):
                    self.statusLabel.text = "Không tải được video: \(error.description)"
                }
            }
        }
    }

    private func startPlayback(url: URL) {
        cleanupPlayer()

        let item = AVPlayerItem(url: url)
        let avPlayer = AVPlayer(playerItem: item)
        self.player = avPlayer

        let layer = AVPlayerLayer(player: avPlayer)
        layer.videoGravity = .resizeAspect
        layer.frame = view.bounds
        view.layer.insertSublayer(layer, below: controlsOverlay.layer)
        self.playerLayer = layer

        avPlayer.play()
        playPauseButton.setTitle("❚❚", for: .normal)

        // Observe time
        let interval = CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = avPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            let current = CMTimeGetSeconds(time)
            guard let duration = self.player?.currentItem?.duration, duration.isNumeric else { return }
            let total = CMTimeGetSeconds(duration)
            if total > 0 {
                self.timeSlider.value = Float(current / total)
                self.timeLabel.text = "\(self.formatTime(current)) / \(self.formatTime(total))"

                // Save progress
                WatchHistoryManager.shared.save(
                    animeId: self.animeID,
                    title: self.animeTitle,
                    poster: self.poster,
                    chapterId: self.chapter.id,
                    chapterName: self.chapter.name,
                    current: current,
                    total: total
                )
            }
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    private func cleanupPlayer() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        player?.pause()
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        player = nil
    }

    // MARK: - Actions

    @objc private func handleClose() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func togglePlayPause() {
        guard let p = player else { return }
        if p.rate != 0 {
            p.pause()
            playPauseButton.setTitle("▶", for: .normal)
        } else {
            p.play()
            playPauseButton.setTitle("❚❚", for: .normal)
        }
    }

    @objc private func replay10() {
        guard let p = player else { return }
        let current = CMTimeGetSeconds(p.currentTime())
        let target = max(current - 10, 0)
        p.seek(to: CMTime(seconds: target, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
    }

    @objc private func forward10() {
        guard let p = player, let d = p.currentItem?.duration, d.isNumeric else { return }
        let current = CMTimeGetSeconds(p.currentTime())
        let total = CMTimeGetSeconds(d)
        let target = min(current + 10, total)
        p.seek(to: CMTime(seconds: target, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
    }

    @objc private func sliderChanged() {
        guard let p = player, let d = p.currentItem?.duration, d.isNumeric else { return }
        let total = CMTimeGetSeconds(d)
        let target = Double(timeSlider.value) * total
        p.seek(to: CMTime(seconds: target, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
    }

    @objc private func toggleControls() {
        UIView.animate(withDuration: 0.25) {
            self.controlsOverlay.alpha = self.controlsOverlay.alpha == 0 ? 1 : 0
        }
    }
}
