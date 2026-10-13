// NetworkManager.swift
// AnimeVsubIOS
//
// Shared URLSession-based HTTP client.
// Handles cookies, redirects, and common headers automatically.

import Foundation

// MARK: - Network Errors

public enum NetworkError: LocalizedError {
    case invalidURL(String)
    case noData
    case httpError(statusCode: Int, body: Data?)
    case decodingError(Error)
    case requestFailed(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url): return "Invalid URL: \(url)"
        case .noData: return "No data received"
        case .httpError(let code, _): return "HTTP error \(code)"
        case .decodingError(let err): return "Decoding failed: \(err.localizedDescription)"
        case .requestFailed(let err): return "Request failed: \(err.localizedDescription)"
        }
    }
}

// MARK: - NetworkManager

/// Shared singleton HTTP client built on URLSession.
/// - Cookie storage is shared and persists across requests (session cookies).
/// - Redirects are followed automatically.
/// - A common iOS-compatible User-Agent is set by default.
public final class NetworkManager: NSObject {

    // MARK: Public singleton

    public static let shared = NetworkManager()

    // MARK: Constants

    public static let defaultUserAgent =
        "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) " +
        "AppleWebKit/605.1.15 (KHTML, like Gecko) " +
        "Version/17.0 Mobile/15E148 Safari/604.1"

    // MARK: Private state

    private let cookieStorage: HTTPCookieStorage
    private let session: URLSession

    /// The resolved base URL after following the initial redirect from animevietsub.xyz.
    /// Lazily resolved the first time it is accessed.
    private var _resolvedBaseURL: String?
    private let resolvedBaseURLLock = NSLock()

    // MARK: Initialisation

    private override init() {
        cookieStorage = HTTPCookieStorage.shared

        let config = URLSessionConfiguration.default
        config.httpCookieStorage = cookieStorage
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 120
        // Mimic a real browser so Cloudflare passes us through
        config.httpAdditionalHeaders = [
            "User-Agent": NetworkManager.defaultUserAgent,
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "vi-VN,vi;q=0.9,en-US;q=0.8,en;q=0.7",
        ]

        session = URLSession(configuration: config,
                             delegate: nil,
                             delegateQueue: nil)

        super.init()
    }

    // MARK: - Public API

    /// Performs a GET request and returns the raw response body.
    /// - Parameters:
    ///   - urlString: Fully-qualified URL string.
    ///   - headers: Additional request-specific headers (merged with defaults).
    /// - Returns: Response body as `Data`.
    public func get(url urlString: String,
                    headers: [String: String] = [:]) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL(urlString)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyHeaders(headers, to: &request)
        return try await perform(request)
    }

    /// Performs a GET request and decodes the JSON response.
    public func get<T: Decodable>(url urlString: String,
                                  headers: [String: String] = [:],
                                  as type: T.Type) async throws -> T {
        let data = try await get(url: urlString, headers: headers)
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }

    /// Performs a POST request and returns the raw response body.
    /// - Parameters:
    ///   - urlString: Fully-qualified URL string.
    ///   - body: HTTP body data.
    ///   - headers: Additional request-specific headers (merged with defaults).
    /// - Returns: Response body as `Data`.
    public func post(url urlString: String,
                     body: Data,
                     headers: [String: String] = [:]) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL(urlString)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        applyHeaders(headers, to: &request)
        if request.value(forHTTPHeaderField: "Content-Type") == nil {
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        }
        return try await perform(request)
    }

    /// Convenience POST for form-encoded body.
    public func postForm(url urlString: String,
                         params: [String: String],
                         headers: [String: String] = [:]) async throws -> Data {
        let encoded = params
            .map { k, v in
                "\(percentEncode(k))=\(percentEncode(v))"
            }
            .joined(separator: "&")
        let body = encoded.data(using: .utf8) ?? Data()
        return try await post(url: urlString, body: body, headers: headers)
    }

    /// Convenience POST with a JSON body.
    public func postJSON<T: Encodable>(url urlString: String,
                                       payload: T,
                                       headers: [String: String] = [:]) async throws -> Data {
        let body = try JSONEncoder().encode(payload)
        var merged = headers
        merged["Content-Type"] = "application/json"
        return try await post(url: urlString, body: body, headers: merged)
    }

    // MARK: - Cookie helpers

    /// Returns all cookies for a given URL as a header value string.
    public func cookieHeader(for url: URL) -> String {
        let cookies = cookieStorage.cookies(for: url) ?? []
        return cookies
            .map { "\($0.name)=\($0.value)" }
            .joined(separator: "; ")
    }

    /// Manually inject a cookie.
    public func setCookie(name: String, value: String, domain: String, path: String = "/") {
        let props: [HTTPCookiePropertyKey: Any] = [
            .name: name,
            .value: value,
            .domain: domain,
            .path: path
        ]
        if let cookie = HTTPCookie(properties: props) {
            cookieStorage.setCookie(cookie)
        }
    }

    /// Remove all cookies for a domain.
    public func clearCookies(for domain: String) {
        let allCookies = cookieStorage.cookies ?? []
        for cookie in allCookies where cookie.domain.contains(domain) {
            cookieStorage.deleteCookie(cookie)
        }
    }

    // MARK: - Resolved base URL

    /// Resolves the final URL after following redirects from `startURL`.
    /// Result is cached after the first successful call.
    public func resolveRedirect(from startURL: String) async throws -> String {
        guard let url = URL(string: startURL) else {
            throw NetworkError.invalidURL(startURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // We only care about the final URL; discard the body.
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              let finalURL = httpResponse.url else {
            return startURL
        }
        // Strip path/query — keep only origin.
        let origin = extractOrigin(finalURL.absoluteString)
        return origin
    }

    // MARK: - Utility

    /// Extracts scheme+host from a URL string, e.g. "https://example.com/path" → "https://example.com"
    public func extractOrigin(_ rawURL: String, defaultScheme: String = "https") -> String {
        let normalized = rawURL.contains("://") ? rawURL : "\(defaultScheme)://\(rawURL)"
        guard let url = URL(string: normalized),
              let scheme = url.scheme,
              let host = url.host else {
            return rawURL
        }
        if let port = url.port {
            return "\(scheme)://\(host):\(port)"
        }
        return "\(scheme)://\(host)"
    }

    // MARK: - Private helpers

    private func perform(_ request: URLRequest) async throws -> Data {
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.noData
            }
            let code = httpResponse.statusCode
            guard (200..<300).contains(code) else {
                throw NetworkError.httpError(statusCode: code, body: data)
            }
            return data
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.requestFailed(error)
        }
    }

    private func applyHeaders(_ headers: [String: String], to request: inout URLRequest) {
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
    }

    private func percentEncode(_ string: String) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return string.addingPercentEncoding(withAllowedCharacters: allowed) ?? string
    }
}
