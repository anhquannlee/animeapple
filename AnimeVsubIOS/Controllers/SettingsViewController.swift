// SettingsViewController.swift
// AnimeVsubIOS (iOS 12+)

import UIKit

final class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .grouped)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Cài đặt"
        view.backgroundColor = UIColor(white: 0.08, alpha: 1)
        navigationController?.navigationBar.barTintColor = UIColor(white: 0.1, alpha: 1)
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]

        tableView.backgroundColor = UIColor(white: 0.08, alpha: 1)
        tableView.separatorColor = UIColor(white: 0.2, alpha: 1)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Phát lại"
        case 1: return "Dữ liệu & Bộ nhớ"
        case 2: return "Thông tin ứng dụng"
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 2
        case 1: return 3
        case 2: return 2
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.backgroundColor = UIColor(white: 0.12, alpha: 1)
        cell.textLabel?.textColor = .white
        cell.detailTextLabel?.textColor = UIColor(white: 0.7, alpha: 1)

        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            cell.textLabel?.text = "Tự động chuyển tập"
            let switchView = UISwitch()
            switchView.isOn = PreferencesManager.shared.autoNext
            switchView.onTintColor = .red
            switchView.addTarget(self, action: #selector(autoNextToggled(_:)), for: .valueChanged)
            cell.accessoryView = switchView
            cell.selectionStyle = .none
        case (0, 1):
            cell.textLabel?.text = "Thời gian tua (chạm 2 lần)"
            cell.detailTextLabel?.text = "\(PreferencesManager.shared.doubleTapSkip) giây"
            cell.accessoryType = .disclosureIndicator
        case (1, 0):
            cell.textLabel?.text = "Xoá lịch sử xem"
            cell.textLabel?.textColor = .red
        case (1, 1):
            cell.textLabel?.text = "Xoá lịch sử tìm kiếm"
            cell.textLabel?.textColor = .red
        case (1, 2):
            cell.textLabel?.text = "Xoá toàn bộ tập đã tải"
            cell.textLabel?.textColor = .red
        case (2, 0):
            cell.textLabel?.text = "Phiên bản"
            cell.detailTextLabel?.text = "1.0.0 (Build 1)"
            cell.selectionStyle = .none
        case (2, 1):
            cell.textLabel?.text = "Nguồn phim"
            cell.detailTextLabel?.text = "AnimeVietSub"
            cell.selectionStyle = .none
        default: break
        }
        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch (indexPath.section, indexPath.row) {
        case (0, 1):
            let alert = UIAlertController(title: "Chọn thời gian tua", message: nil, preferredStyle: .actionSheet)
            for s in [5, 10, 15, 30] {
                alert.addAction(UIAlertAction(title: "\(s) giây", style: .default) { _ in
                    PreferencesManager.shared.doubleTapSkip = s
                    tableView.reloadData()
                })
            }
            alert.addAction(UIAlertAction(title: "Huỷ", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        case (1, 0):
            confirmAction(title: "Xoá lịch sử xem?") {
                WatchHistoryManager.shared.clearAll()
            }
        case (1, 1):
            confirmAction(title: "Xoá lịch sử tìm kiếm?") {
                PreferencesManager.shared.clearSearchHistory()
            }
        case (1, 2):
            confirmAction(title: "Xoá toàn bộ tập đã tải?") {
                DownloadManager.shared.clearAll()
            }
        default: break
        }
    }

    @objc private func autoNextToggled(_ sender: UISwitch) {
        PreferencesManager.shared.autoNext = sender.isOn
    }

    private func confirmAction(title: String, action: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: "Hành động này không thể hoàn tác.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Xoá", style: .destructive) { _ in action() })
        alert.addAction(UIAlertAction(title: "Huỷ", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
