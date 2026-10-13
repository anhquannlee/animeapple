// ImageLoader.swift
// AnimeVsubIOS (iOS 12+)

import UIKit

public final class ImageLoader {
    public static let shared = ImageLoader()
    private let cache = NSCache<NSURL, UIImage>()

    public func image(url: URL, completion: @escaping (UIImage?) -> Void) {
        if let cached = cache.object(forKey: url as NSURL) {
            completion(cached)
            return
        }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            let img = data.flatMap(UIImage.init(data:))
            if let img = img {
                self?.cache.setObject(img, forKey: url as NSURL)
            }
            DispatchQueue.main.async { completion(img) }
        }.resume()
    }
}

public final class AsyncImageView: UIImageView {
    private var representedURL: URL?

    public func load(url: URL) {
        representedURL = url
        image = nil
        ImageLoader.shared.image(url: url) { [weak self] img in
            guard self?.representedURL == url else { return }
            self?.image = img
        }
    }

    public func load(urlString: String?) {
        guard let s = urlString, let u = URL(string: s) else {
            image = nil
            return
        }
        load(url: u)
    }
}
