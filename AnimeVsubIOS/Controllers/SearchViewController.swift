// SearchViewController.swift
// AnimeVsubIOS (iOS 12+)

import UIKit

final class SearchViewController: UIViewController, UISearchBarDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITableViewDataSource, UITableViewDelegate {
    private let searchBar = UISearchBar()
    private var collectionView: UICollectionView!
    private let suggestionsTableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .whiteLarge)

    private var searchResults: [AnimeCard] = []
    private var suggestions: [SearchSuggestion] = []
    private var searchTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Tìm kiếm"
        view.backgroundColor = UIColor(white: 0.08, alpha: 1)
        navigationController?.navigationBar.barTintColor = UIColor(white: 0.1, alpha: 1)
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]

        setupUI()
    }

    private func setupUI() {
        searchBar.placeholder = "Nhập tên anime..."
        searchBar.delegate = self
        searchBar.barStyle = .black
        searchBar.barTintColor = UIColor(white: 0.1, alpha: 1)
        searchBar.tintColor = .white
        searchBar.searchBarStyle = .minimal
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)

        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 12, left: 12, bottom: 20, right: 12)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor(white: 0.08, alpha: 1)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(AnimeCardCell.self, forCellWithReuseIdentifier: AnimeCardCell.reuseIdentifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)

        suggestionsTableView.backgroundColor = UIColor(white: 0.12, alpha: 1)
        suggestionsTableView.separatorColor = UIColor(white: 0.22, alpha: 1)
        suggestionsTableView.dataSource = self
        suggestionsTableView.delegate = self
        suggestionsTableView.isHidden = true
        suggestionsTableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(suggestionsTableView)

        emptyLabel.text = "Nhập từ khoá để tìm anime yêu thích."
        emptyLabel.font = UIFont.systemFont(ofSize: 14)
        emptyLabel.textColor = UIColor(white: 0.6, alpha: 1)
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyLabel)

        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),

            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            suggestionsTableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            suggestionsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            suggestionsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            suggestionsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // MARK: - UISearchBarDelegate

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchTimer?.invalidate()
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            suggestions = []
            suggestionsTableView.isHidden = true
            return
        }

        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: false) { [weak self] _ in
            self?.fetchSuggestions(query: trimmed)
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        suggestionsTableView.isHidden = true
        guard let text = searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return }
        performFullSearch(keyword: text)
    }

    private func fetchSuggestions(query: String) {
        APIClient.shared.suggestions(keyword: query) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let items):
                    self.suggestions = items
                    self.suggestionsTableView.isHidden = items.isEmpty
                    self.suggestionsTableView.reloadData()
                case .failure:
                    self.suggestions = []
                    self.suggestionsTableView.isHidden = true
                }
            }
        }
    }

    private func performFullSearch(keyword: String) {
        loadingIndicator.startAnimating()
        emptyLabel.isHidden = true
        PreferencesManager.shared.addSearchHistory(keyword)

        APIClient.shared.search(keyword: keyword, page: 1) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.loadingIndicator.stopAnimating()
                switch result {
                case .success(let page):
                    self.searchResults = page.items
                    self.emptyLabel.text = page.items.isEmpty ? "Không tìm thấy anime nào phù hợp." : nil
                    self.emptyLabel.isHidden = !page.items.isEmpty
                    self.collectionView.reloadData()
                case .failure(let err):
                    self.emptyLabel.text = "Lỗi tìm kiếm: \(err.description)"
                    self.emptyLabel.isHidden = false
                }
            }
        }
    }

    // MARK: - Suggestions UITableViewDataSource & Delegate

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return suggestions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SuggestionCell") ?? UITableViewCell(style: .default, reuseIdentifier: "SuggestionCell")
        cell.backgroundColor = UIColor(white: 0.12, alpha: 1)
        cell.textLabel?.textColor = .white
        cell.textLabel?.font = UIFont.systemFont(ofSize: 14)
        let item = suggestions[indexPath.row]
        cell.textLabel?.text = item.name
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = suggestions[indexPath.row]
        suggestionsTableView.isHidden = true
        searchBar.text = item.name
        searchBar.resignFirstResponder()

        let detailVC = DetailViewController(animeID: item.id, initialTitle: item.name)
        navigationController?.pushViewController(detailVC, animated: true)
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return searchResults.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AnimeCardCell.reuseIdentifier, for: indexPath) as! AnimeCardCell
        let anime = searchResults[indexPath.item]
        cell.configure(anime: anime)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing: CGFloat = 8
        let totalMargin: CGFloat = 24 + (spacing * 2)
        let width = floor((collectionView.bounds.width - totalMargin) / 3)
        let height = width * 1.5 + 44
        return CGSize(width: width, height: height)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = searchResults[indexPath.item]
        let detailVC = DetailViewController(animeID: item.animeId, initialTitle: item.name)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
