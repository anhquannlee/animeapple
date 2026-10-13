// MainTabBarController.swift
// AnimeVsubIOS (iOS 12+)

import UIKit

final class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        setupAppearance()
    }

    private func setupTabs() {
        let homeVC = HomeViewController()
        let homeNav = UINavigationController(rootViewController: homeVC)
        homeNav.tabBarItem = UITabBarItem(
            title: "Trang chủ",
            image: TabBarIconRenderer.homeIcon(),
            tag: 0
        )

        let searchVC = SearchViewController()
        let searchNav = UINavigationController(rootViewController: searchVC)
        searchNav.tabBarItem = UITabBarItem(
            title: "Tìm kiếm",
            image: TabBarIconRenderer.searchIcon(),
            tag: 1
        )

        let downloadsVC = DownloadsViewController()
        let downloadsNav = UINavigationController(rootViewController: downloadsVC)
        downloadsNav.tabBarItem = UITabBarItem(
            title: "Đã tải",
            image: TabBarIconRenderer.downloadsIcon(),
            tag: 2
        )

        let historyVC = HistoryViewController()
        let historyNav = UINavigationController(rootViewController: historyVC)
        historyNav.tabBarItem = UITabBarItem(
            title: "Lịch sử",
            image: TabBarIconRenderer.historyIcon(),
            tag: 3
        )

        let settingsVC = SettingsViewController()
        let settingsNav = UINavigationController(rootViewController: settingsVC)
        settingsNav.tabBarItem = UITabBarItem(
            title: "Cài đặt",
            image: TabBarIconRenderer.settingsIcon(),
            tag: 4
        )

        viewControllers = [homeNav, searchNav, downloadsNav, historyNav, settingsNav]
    }

    private func setupAppearance() {
        tabBar.barTintColor = UIColor(white: 0.1, alpha: 1.0)
        tabBar.tintColor = UIColor(red: 229 / 255.0, green: 57 / 255.0, blue: 53 / 255.0, alpha: 1.0)
        tabBar.unselectedItemTintColor = UIColor(white: 0.6, alpha: 1.0)
        tabBar.isTranslucent = false
    }
}

// MARK: - Programmatic Tab Bar Icon Renderer (iOS 12+ Compatible)

private enum TabBarIconRenderer {
    private static let size = CGSize(width: 25, height: 25)

    static func homeIcon() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let path = UIBezierPath()
            // Roof
            path.move(to: CGPoint(x: 12.5, y: 3))
            path.addLine(to: CGPoint(x: 2, y: 12))
            path.addLine(to: CGPoint(x: 5, y: 12))
            path.addLine(to: CGPoint(x: 5, y: 22))
            path.addLine(to: CGPoint(x: 10, y: 22))
            path.addLine(to: CGPoint(x: 10, y: 16))
            path.addLine(to: CGPoint(x: 15, y: 16))
            path.addLine(to: CGPoint(x: 15, y: 22))
            path.addLine(to: CGPoint(x: 20, y: 22))
            path.addLine(to: CGPoint(x: 20, y: 12))
            path.addLine(to: CGPoint(x: 23, y: 12))
            path.close()

            UIColor.white.setFill()
            path.fill()
        }
        return img.withRenderingMode(.alwaysTemplate)
    }

    static func searchIcon() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let circlePath = UIBezierPath(ovalIn: CGRect(x: 3, y: 3, width: 13, height: 13))
            circlePath.lineWidth = 2.5
            UIColor.white.setStroke()
            circlePath.stroke()

            let handlePath = UIBezierPath()
            handlePath.move(to: CGPoint(x: 13, y: 13))
            handlePath.addLine(to: CGPoint(x: 21, y: 21))
            handlePath.lineWidth = 2.5
            handlePath.lineCapStyle = .round
            UIColor.white.setStroke()
            handlePath.stroke()
        }
        return img.withRenderingMode(.alwaysTemplate)
    }

    static func downloadsIcon() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            // Arrow down
            let arrowPath = UIBezierPath()
            arrowPath.move(to: CGPoint(x: 12.5, y: 2))
            arrowPath.addLine(to: CGPoint(x: 12.5, y: 14))
            arrowPath.lineWidth = 2.5
            arrowPath.stroke()

            let headPath = UIBezierPath()
            headPath.move(to: CGPoint(x: 7, y: 9.5))
            headPath.addLine(to: CGPoint(x: 12.5, y: 15))
            headPath.addLine(to: CGPoint(x: 18, y: 9.5))
            headPath.lineWidth = 2.5
            headPath.lineCapStyle = .round
            headPath.lineJoinStyle = .round
            headPath.stroke()

            // Tray
            let trayPath = UIBezierPath()
            trayPath.move(to: CGPoint(x: 3, y: 17))
            trayPath.addLine(to: CGPoint(x: 3, y: 22))
            trayPath.addLine(to: CGPoint(x: 22, y: 22))
            trayPath.addLine(to: CGPoint(x: 22, y: 17))
            trayPath.lineWidth = 2.0
            trayPath.stroke()
        }
        return img.withRenderingMode(.alwaysTemplate)
    }

    static func historyIcon() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let circle = UIBezierPath(ovalIn: CGRect(x: 2.5, y: 2.5, width: 20, height: 20))
            circle.lineWidth = 2.0
            UIColor.white.setStroke()
            circle.stroke()

            let hands = UIBezierPath()
            hands.move(to: CGPoint(x: 12.5, y: 6.5))
            hands.addLine(to: CGPoint(x: 12.5, y: 12.5))
            hands.addLine(to: CGPoint(x: 17, y: 12.5))
            hands.lineWidth = 2.0
            hands.lineCapStyle = .round
            hands.stroke()
        }
        return img.withRenderingMode(.alwaysTemplate)
    }

    static func settingsIcon() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            // Outer gear circle
            let circle = UIBezierPath(ovalIn: CGRect(x: 4.5, y: 4.5, width: 16, height: 16))
            circle.lineWidth = 2.5
            UIColor.white.setStroke()
            circle.stroke()

            // Center inner circle
            let inner = UIBezierPath(ovalIn: CGRect(x: 9.5, y: 9.5, width: 6, height: 6))
            UIColor.white.setFill()
            inner.fill()

            // 4 gear teeth marks
            let teeth = UIBezierPath()
            teeth.move(to: CGPoint(x: 12.5, y: 1.5))
            teeth.addLine(to: CGPoint(x: 12.5, y: 4.5))
            teeth.move(to: CGPoint(x: 12.5, y: 20.5))
            teeth.addLine(to: CGPoint(x: 12.5, y: 23.5))
            teeth.move(to: CGPoint(x: 1.5, y: 12.5))
            teeth.addLine(to: CGPoint(x: 4.5, y: 12.5))
            teeth.move(to: CGPoint(x: 20.5, y: 12.5))
            teeth.addLine(to: CGPoint(x: 23.5, y: 12.5))
            teeth.lineWidth = 2.5
            teeth.lineCapStyle = .round
            teeth.stroke()
        }
        return img.withRenderingMode(.alwaysTemplate)
    }
}
