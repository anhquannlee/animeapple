// HomeViewController.swift
// AnimeVsubIOS (iOS 12+)

import UIKit

final class HomeViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    private var homeData: HomeData? = nil
    private var allCards: [AnimeCard] = []

    private let collectionView: UICollectionView
    private let refreshControl = UIRefreshControl()
    private let loadingIndicator = UIActivityIndicatorView(style: .whiteLarge)
    private let emptyLabel = UILabel()

    // Banner Carousel at the header
    private var carouselTimer: Timer?
    private var currentCarouselIndex: Int = 0

    init() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 12, left: 12, bottom: 20, right: 12)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "AnimeVsub"
        view.backgroundColor = UIColor(white: 0.08, alpha: 1)
        navigationController?.navigationBar.barTintColor = UIColor(white: 0.1, alpha: 1)
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]

        setupViews()
        loadData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        carouselTimer?.invalidate()
        carouselTimer = nil
    }

    private func setupViews() {
        collectionView.backgroundColor = UIColor(white: 0.08, alpha: 1)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = true
        collectionView.register(AnimeCardCell.self, forCellWithReuseIdentifier: AnimeCardCell.reuseIdentifier)
        collectionView.register(CarouselHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "CarouselHeader")

        refreshControl.tintColor = .white
        refreshControl.addTarget(self, action: #selector(loadData), for: .valueChanged)
        collectionView.refreshControl = refreshControl

        emptyLabel.text = "Đang tải dữ liệu phim…"
        emptyLabel.textColor = UIColor(white: 0.7, alpha: 1)
        emptyLabel.font = UIFont.systemFont(ofSize: 14)
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0

        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.startAnimating()

        [collectionView, emptyLabel, loadingIndicator].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc private func loadData() {
        APIClient.shared.home { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.refreshControl.endRefreshing()
                self.loadingIndicator.stopAnimating()
                switch result {
                case .success(let data):
                    self.homeData = data
                    // Combine lists for rich feed
                    self.allCards = data.hotUpdate + data.lastUpdate + data.thisSeason
                    self.emptyLabel.isHidden = !self.allCards.isEmpty
                    self.collectionView.reloadData()
                case .failure(let error):
                    if self.allCards.isEmpty {
                        self.emptyLabel.text = "Lỗi kết nối: \(error.description)\nKéo xuống để tải lại."
                        self.emptyLabel.isHidden = false
                    }
                }
            }
        }
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allCards.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AnimeCardCell.reuseIdentifier, for: indexPath) as! AnimeCardCell
        let anime = allCards[indexPath.item]
        cell.configure(anime: anime)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "CarouselHeader", for: indexPath) as! CarouselHeaderView
            if let carousel = homeData?.carousel, !carousel.isEmpty {
                header.configure(cards: carousel) { [weak self] selected in
                    self?.openDetail(animeID: selected.animeId, title: selected.name)
                }
            }
            return header
        }
        return UICollectionReusableView()
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // 3 items per row on iPhone
        let spacing: CGFloat = 8
        let totalMargin: CGFloat = 24 + (spacing * 2)
        let width = floor((collectionView.bounds.width - totalMargin) / 3)
        let height = width * 1.5 + 44
        return CGSize(width: width, height: height)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard let carousel = homeData?.carousel, !carousel.isEmpty else { return .zero }
        let width = collectionView.bounds.width
        return CGSize(width: width, height: width * 0.55)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = allCards[indexPath.item]
        openDetail(animeID: item.animeId, title: item.name)
    }

    private func openDetail(animeID: String, title: String) {
        let detailVC = DetailViewController(animeID: animeID, initialTitle: title)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - Carousel Header

final class CarouselHeaderView: UICollectionReusableView {
    private let imageView = AsyncImageView()
    private let titleLabel = UILabel()
    private let gradientLayer = CAGradientLayer()
    private var cards: [AnimeCard] = []
    private var currentIndex: Int = 0
    private var onSelect: ((AnimeCard) -> Void)?
    private var timer: Timer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2

        gradientLayer.colors = [UIColor.clear.cgColor, UIColor(white: 0.08, alpha: 0.95).cgColor]
        gradientLayer.locations = [0.4, 1.0]
        layer.addSublayer(gradientLayer)

        addSubview(imageView)
        addSubview(titleLabel)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    func configure(cards: [AnimeCard], onSelect: @escaping (AnimeCard) -> Void) {
        self.cards = cards
        self.onSelect = onSelect
        self.currentIndex = 0
        updateDisplay()

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { [weak self] _ in
            guard let self = self, !self.cards.isEmpty else { return }
            self.currentIndex = (self.currentIndex + 1) % self.cards.count
            self.updateDisplay()
        }
    }

    private func updateDisplay() {
        guard currentIndex < cards.count else { return }
        let card = cards[currentIndex]
        titleLabel.text = card.name
        if let u = URL(string: card.image) {
            imageView.load(url: u)
        }
    }

    @objc private func handleTap() {
        guard currentIndex < cards.count else { return }
        onSelect?(cards[currentIndex])
    }
}
