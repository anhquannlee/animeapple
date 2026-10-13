// PreferencesManager.swift
// AnimeVsubIOS
//
// Port of PreferencesManager.kt — mirrors all settings keys and defaults.
// Uses UserDefaults as backing store. Exposed as @Published properties so
// SwiftUI views can react to changes without manual observation boilerplate.

import Foundation
import Combine

// MARK: - Constants (mirrors companion object in PreferencesManager.kt)
extension PreferencesManager {
    // MARK: Defaults
    static let defaultAutoNext: Bool   = true
    static let defaultAutoSkip: Bool   = false
    static let defaultVolumeGesture: Bool   = true
    static let defaultBrightnessGesture: Bool   = true
    static let defaultDoubleTapSkip: Int    = 10
    static let defaultLongPressSpeed: Float  = 2.0
    static let defaultAutoSyncNotify: Bool   = false
    static let defaultNotifyInterval: Int    = 15
    static let defaultDbNotifyInterval: Int  = 30
    static let defaultEnableBackgroundSync: Bool = true
    static let defaultEnableNotifications: Bool  = true
    static let defaultBreakReminderEnabled: Bool = false
    static let defaultBreakReminderInterval: Int = 60
    static let defaultBedtimeReminderEnabled: Bool        = false
    static let defaultBedtimeReminderStartTime: Int       = 23 * 60   // minutes from midnight
    static let defaultBedtimeReminderEndTime: Int         =  5 * 60
    static let defaultBedtimeReminderWaitFinish: Bool     = true
    static let defaultAppLanguage: String  = "auto"
    static let defaultDeveloperMode: Bool  = false
    static let defaultScreenTransition: String = "system"
    static let defaultAiSummaryEnabled: Bool = true
    static let defaultAiRecapEnabled: Bool   = true
    static let defaultAiProvider: String     = "gemini"
    static let defaultOpenaiApiKey: String   = ""
    static let defaultOpenaiModel: String    = "gpt-4o-mini"
    static let defaultOpenaiEndpoint: String = ""
    static let defaultClaudeApiKey: String   = ""
    static let defaultClaudeModel: String    = "claude-sonnet-4-20250514"
    static let defaultClaudeEndpoint: String = ""
    static let defaultGeminiApiKey: String   = ""
    static let defaultGeminiModel: String    = "gemini-1.5-flash"
    static let defaultPreferredServer: String = ""
    static let defaultMinBufferMs: Int       = 50_000
    static let defaultMaxBufferMs: Int       = 120_000
    static let defaultBufferForPlaybackMs: Int = 10_000
    static let defaultBufferForPlaybackAfterRebufferMs: Int = 12_000
    static let defaultPrioritizeTimeOverSize: Bool = true
    static let defaultDnsMode: String        = "cloudflare"
    static let defaultCustomDnsUrl: String   = "https://dns.google/dns-query"

    // MARK: DNS mode constants
    static let dnsModeSystem: String     = "system"
    static let dnsModeGoogle: String     = "google"
    static let dnsModeCloudflare: String = "cloudflare"
    static let dnsModeQuad9: String      = "quad9"
    static let dnsModeCustom: String     = "custom"

    // MARK: UserDefaults keys (match DataStore key names in Kotlin)
    fileprivate enum Key {
        static let autoNext             = "auto_next"
        static let autoSkip             = "auto_skip"
        static let volumeGesture        = "volume_gesture"
        static let brightnessGesture    = "brightness_gesture"
        static let doubleTapSkip        = "double_tap_skip"
        static let longPressSpeed       = "long_press_speed"
        static let autoSyncNotify       = "auto_sync_notify"
        static let notifyInterval       = "notify_interval"
        static let dbNotifyInterval     = "db_notify_interval"
        static let enableBackgroundSync = "enable_background_sync"
        static let enableNotifications  = "enable_notifications"
        static let breakReminderEnabled   = "break_reminder_enabled"
        static let breakReminderInterval  = "break_reminder_interval"
        static let bedtimeReminderEnabled   = "bedtime_reminder_enabled"
        static let bedtimeReminderStartTime = "bedtime_reminder_start_time"
        static let bedtimeReminderEndTime   = "bedtime_reminder_end_time"
        static let bedtimeReminderWaitFinish = "bedtime_reminder_wait_finish"
        static let appLanguage          = "app_language"
        static let developerMode        = "developer_mode"
        static let screenTransition     = "screen_transition"
        static let aiSummaryEnabled     = "ai_summary_enabled"
        static let aiRecapEnabled       = "ai_recap_enabled"
        static let aiProvider           = "ai_provider"
        static let openaiApiKey         = "openai_api_key"
        static let openaiModel          = "openai_model"
        static let openaiEndpoint       = "openai_endpoint"
        static let claudeApiKey         = "claude_api_key"
        static let claudeModel          = "claude_model"
        static let claudeEndpoint       = "claude_endpoint"
        static let geminiApiKey         = "gemini_api_key"
        static let geminiModel          = "gemini_model"
        static let preferredServer      = "preferred_server"
        static let minBufferMs          = "min_buffer_ms"
        static let maxBufferMs          = "max_buffer_ms"
        static let bufferForPlaybackMs  = "buffer_for_playback_ms"
        static let bufferForPlaybackAfterRebufferMs = "buffer_for_playback_after_rebuffer_ms"
        static let prioritizeTimeOverSize = "prioritize_time_over_size"
        static let dnsMode              = "dns_mode"
        static let customDnsUrl         = "custom_dns_url"
        static let searchHistory        = "search_history"
        /// Maximum number of search history entries to retain (mirrors Kotlin limit of 10)
        static let searchHistoryMaxCount = 10
    }
}

// MARK: - PreferencesManager

/// Observable wrapper around UserDefaults that mirrors the Android PreferencesManager.
/// All @Published properties are kept in sync with UserDefaults so that both
/// programmatic access and SwiftUI bindings work seamlessly.
final class PreferencesManager: ObservableObject {

    // MARK: Singleton
    static let shared = PreferencesManager()

    private let defaults: UserDefaults
    private var cancellables = Set<AnyCancellable>()

    // MARK: - @Published properties

    // Player settings
    @Published var autoNext: Bool
    @Published var autoSkip: Bool
    @Published var volumeGesture: Bool
    @Published var brightnessGesture: Bool
    @Published var doubleTapSkip: Int
    @Published var longPressSpeed: Float

    // Notification / sync
    @Published var autoSyncNotify: Bool
    @Published var notifyInterval: Int
    @Published var dbNotifyInterval: Int
    @Published var enableBackgroundSync: Bool
    @Published var enableNotifications: Bool

    // Break / bedtime reminders
    @Published var breakReminderEnabled: Bool
    @Published var breakReminderInterval: Int
    @Published var bedtimeReminderEnabled: Bool
    /// Minutes from midnight (e.g. 23*60 = 23:00)
    @Published var bedtimeReminderStartTime: Int
    @Published var bedtimeReminderEndTime: Int
    @Published var bedtimeReminderWaitFinish: Bool

    // App appearance / language
    @Published var appLanguage: String
    @Published var screenTransition: String
    @Published var developerMode: Bool

    // AI settings
    @Published var aiSummaryEnabled: Bool
    @Published var aiRecapEnabled: Bool
    @Published var aiProvider: String
    @Published var openaiApiKey: String
    @Published var openaiModel: String
    @Published var openaiEndpoint: String
    @Published var claudeApiKey: String
    @Published var claudeModel: String
    @Published var claudeEndpoint: String
    @Published var geminiApiKey: String
    @Published var geminiModel: String

    // Playback / server
    @Published var preferredServer: String
    @Published var minBufferMs: Int
    @Published var maxBufferMs: Int
    @Published var bufferForPlaybackMs: Int
    @Published var bufferForPlaybackAfterRebufferMs: Int
    @Published var prioritizeTimeOverSize: Bool

    // DNS
    @Published var dnsMode: String
    @Published var customDnsUrl: String

    // Search history (JSON-encoded [String])
    @Published var searchHistory: [String]

    // MARK: - Init

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // Read initial values — fall back to defaults when key is absent
        autoNext             = defaults.object(forKey: Key.autoNext) as? Bool ?? Self.defaultAutoNext
        autoSkip             = defaults.object(forKey: Key.autoSkip) as? Bool ?? Self.defaultAutoSkip
        volumeGesture        = defaults.object(forKey: Key.volumeGesture) as? Bool ?? Self.defaultVolumeGesture
        brightnessGesture    = defaults.object(forKey: Key.brightnessGesture) as? Bool ?? Self.defaultBrightnessGesture
        doubleTapSkip        = defaults.object(forKey: Key.doubleTapSkip) as? Int ?? Self.defaultDoubleTapSkip
        longPressSpeed       = defaults.object(forKey: Key.longPressSpeed) as? Float ?? Self.defaultLongPressSpeed
        autoSyncNotify       = defaults.object(forKey: Key.autoSyncNotify) as? Bool ?? Self.defaultAutoSyncNotify
        notifyInterval       = defaults.object(forKey: Key.notifyInterval) as? Int ?? Self.defaultNotifyInterval
        dbNotifyInterval     = defaults.object(forKey: Key.dbNotifyInterval) as? Int ?? Self.defaultDbNotifyInterval
        enableBackgroundSync = defaults.object(forKey: Key.enableBackgroundSync) as? Bool ?? Self.defaultEnableBackgroundSync
        enableNotifications  = defaults.object(forKey: Key.enableNotifications) as? Bool ?? Self.defaultEnableNotifications
        breakReminderEnabled   = defaults.object(forKey: Key.breakReminderEnabled) as? Bool ?? Self.defaultBreakReminderEnabled
        breakReminderInterval  = defaults.object(forKey: Key.breakReminderInterval) as? Int ?? Self.defaultBreakReminderInterval
        bedtimeReminderEnabled   = defaults.object(forKey: Key.bedtimeReminderEnabled) as? Bool ?? Self.defaultBedtimeReminderEnabled
        bedtimeReminderStartTime = defaults.object(forKey: Key.bedtimeReminderStartTime) as? Int ?? Self.defaultBedtimeReminderStartTime
        bedtimeReminderEndTime   = defaults.object(forKey: Key.bedtimeReminderEndTime) as? Int ?? Self.defaultBedtimeReminderEndTime
        bedtimeReminderWaitFinish = defaults.object(forKey: Key.bedtimeReminderWaitFinish) as? Bool ?? Self.defaultBedtimeReminderWaitFinish
        appLanguage          = defaults.string(forKey: Key.appLanguage) ?? Self.defaultAppLanguage
        screenTransition     = defaults.string(forKey: Key.screenTransition) ?? Self.defaultScreenTransition
        developerMode        = defaults.object(forKey: Key.developerMode) as? Bool ?? Self.defaultDeveloperMode
        aiSummaryEnabled     = defaults.object(forKey: Key.aiSummaryEnabled) as? Bool ?? Self.defaultAiSummaryEnabled
        aiRecapEnabled       = defaults.object(forKey: Key.aiRecapEnabled) as? Bool ?? Self.defaultAiRecapEnabled
        aiProvider           = defaults.string(forKey: Key.aiProvider) ?? Self.defaultAiProvider
        openaiApiKey         = defaults.string(forKey: Key.openaiApiKey) ?? Self.defaultOpenaiApiKey
        openaiModel          = defaults.string(forKey: Key.openaiModel) ?? Self.defaultOpenaiModel
        openaiEndpoint       = defaults.string(forKey: Key.openaiEndpoint) ?? Self.defaultOpenaiEndpoint
        claudeApiKey         = defaults.string(forKey: Key.claudeApiKey) ?? Self.defaultClaudeApiKey
        claudeModel          = defaults.string(forKey: Key.claudeModel) ?? Self.defaultClaudeModel
        claudeEndpoint       = defaults.string(forKey: Key.claudeEndpoint) ?? Self.defaultClaudeEndpoint
        geminiApiKey         = defaults.string(forKey: Key.geminiApiKey) ?? Self.defaultGeminiApiKey
        geminiModel          = defaults.string(forKey: Key.geminiModel) ?? Self.defaultGeminiModel
        preferredServer      = defaults.string(forKey: Key.preferredServer) ?? Self.defaultPreferredServer
        minBufferMs          = defaults.object(forKey: Key.minBufferMs) as? Int ?? Self.defaultMinBufferMs
        maxBufferMs          = defaults.object(forKey: Key.maxBufferMs) as? Int ?? Self.defaultMaxBufferMs
        bufferForPlaybackMs  = defaults.object(forKey: Key.bufferForPlaybackMs) as? Int ?? Self.defaultBufferForPlaybackMs
        bufferForPlaybackAfterRebufferMs = defaults.object(forKey: Key.bufferForPlaybackAfterRebufferMs) as? Int ?? Self.defaultBufferForPlaybackAfterRebufferMs
        prioritizeTimeOverSize = defaults.object(forKey: Key.prioritizeTimeOverSize) as? Bool ?? Self.defaultPrioritizeTimeOverSize
        dnsMode              = defaults.string(forKey: Key.dnsMode) ?? Self.defaultDnsMode
        customDnsUrl         = defaults.string(forKey: Key.customDnsUrl) ?? Self.defaultCustomDnsUrl
        searchHistory        = Self.loadSearchHistory(from: defaults)

        // Wire every @Published change back to UserDefaults persistence
        setupPersistence()
    }

    // MARK: - Persistence wiring

    /// Subscribes to every @Published property and persists changes to UserDefaults.
    private func setupPersistence() {
        $autoNext.dropFirst().sink { [weak self] v in self?.defaults.set(v, forKey: Key.autoNext) }.store(in: &cancellables)
        $autoSkip.dropFirst().sink { [weak self] v in self?.defaults.set(v, forKey: Key.autoSkip) }.store(in: &cancellables)
        $volumeGesture.dropFirst().sink { [weak self] v in self?.defaults.set(v, forKey: Key.volumeGesture) }.store(in: &cancellables)
        $brightnessGesture.dropFirst().sink { [weak self] v in self?.defaults.set(v, forKey: Key.brightnessGesture) }.store(in: &cancellables)
        $doubleTapSkip.dropFirst().sink { [weak self] v in self?.defaults.set(v, forKey: Key.doubleTapSkip) }.store(in: &cancellables)
        $longPressSpeed.dropFirst().sink { [weak self] v in self?.defaults.set(v, forKey: Key.longPressSpeed) }.store(in: &cancellables)
        $autoSyncNotify.dropFirst().sink { [weak self] v in self?.defaults.set(v, forKey: Key.autoSyncNotify) }.store(in: &cancellables)
        $notifyInterval.dropFirst().sink { [weak self] v in self?.defaults.set(v, forKey: Key.notifyInterval) }.store(in: &cancellables)
        $dbNotifyInterval.dropFirst().sink { [weak self] v in self?.defaults.set(v, forKey: Key.dbNotifyInterval) }.store(in: &cancellables)
        $enableBackgroundSync.dropFirst().sink { [weak self] v in self?.defaults.set(v, forKey: Key.enableBackgroundSync) }.store(in: &cancellables)
        $enableNotifications.dropFirst().sink { [weak self] v in self?.defaults.set(v, forKey: Key.enableNotifications) }.store(in: &cancellables)
        $breakReminderEnabled.dropFirst().sink { [weak self] v in self?.defaults.set(v, forKey: Key.breakReminderEnabled) }.store(in: &cancellables)
        $breakReminderInterval.dropFirst().sink { [weak self] v in self?.defaults.set(v, forKey: Key.breakReminderInterval) }.store(in: &cancellables)
        $bedtimeReminderEnabled.dropFirst().sink { [weak self] v in self?.defaults.set(v, forKey: Key.bedtimeReminderEnabled) }.store(in: &cancellables)
        $bedtimeReminderStartTime.dropFirst().sink { [weak self] v in self?.defaults.set(v, forKey: Key.bedtimeReminderStartTime) }.store(in: &cancellables)
        $bedtimeReminderEndTime.dropFirst().sink { [weak self] v in self?.defaults.set(v, forKey: Key.bedtimeReminderEndTime) }.store(in: &cancellables)
        $bedtimeReminderWaitFinish.dropFirst().sink { [weak self] v in self?.defaults.set(v, forKey: Key.bedtimeReminderWaitFinish) }.store(in: &cancellables)
        $appLanguage.dropFirst().sink { [weak self] v in self?.defaults.set(v, forKey: Key.appLanguage) }.store(in: &cancellables)
        $screenTransition.dropFirst().sink { [weak self] v in self?.defaults.set(v, forKey: Key.screenTransition) }.store(in: &cancellables)
        $developerMode.dropFirst().sink { [weak self] v in self?.defaults.set(v, forKey: Key.developerMode) }.store(in: &cancellables)
        $aiSummaryEnabled.dropFirst().sink { [weak self] v in self?.defaults.set(v, forKey: Key.aiSummaryEnabled) }.store(in: &cancellables)
        $aiRecapEnabled.dropFirst().sink { [weak self] v in self?.defaults.set(v, forKey: Key.aiRecapEnabled) }.store(in: &cancellables)
        $aiProvider.dropFirst().sink { [weak self] v in self?.defaults.set(v, forKey: Key.aiProvider) }.store(in: &cancellables)
        $openaiApiKey.dropFirst().sink { [weak self] v in self?.defaults.set(v, forKey: Key.openaiApiKey) }.store(in: &cancellables)
        $openaiModel.dropFirst().sink { [weak self] v in self?.defaults.set(v, forKey: Key.openaiModel) }.store(in: &cancellables)
        $openaiEndpoint.dropFirst().sink { [weak self] v in self?.defaults.set(v, forKey: Key.openaiEndpoint) }.store(in: &cancellables)
        $claudeApiKey.dropFirst().sink { [weak self] v in self?.defaults.set(v, forKey: Key.claudeApiKey) }.store(in: &cancellables)
        $claudeModel.dropFirst().sink { [weak self] v in self?.defaults.set(v, forKey: Key.claudeModel) }.store(in: &cancellables)
        $claudeEndpoint.dropFirst().sink { [weak self] v in self?.defaults.set(v, forKey: Key.claudeEndpoint) }.store(in: &cancellables)
        $geminiApiKey.dropFirst().sink { [weak self] v in self?.defaults.set(v, forKey: Key.geminiApiKey) }.store(in: &cancellables)
        $geminiModel.dropFirst().sink { [weak self] v in self?.defaults.set(v, forKey: Key.geminiModel) }.store(in: &cancellables)
        $preferredServer.dropFirst().sink { [weak self] v in self?.defaults.set(v, forKey: Key.preferredServer) }.store(in: &cancellables)
        $minBufferMs.dropFirst().sink { [weak self] v in self?.defaults.set(v, forKey: Key.minBufferMs) }.store(in: &cancellables)
        $maxBufferMs.dropFirst().sink { [weak self] v in self?.defaults.set(v, forKey: Key.maxBufferMs) }.store(in: &cancellables)
        $bufferForPlaybackMs.dropFirst().sink { [weak self] v in self?.defaults.set(v, forKey: Key.bufferForPlaybackMs) }.store(in: &cancellables)
        $bufferForPlaybackAfterRebufferMs.dropFirst().sink { [weak self] v in self?.defaults.set(v, forKey: Key.bufferForPlaybackAfterRebufferMs) }.store(in: &cancellables)
        $prioritizeTimeOverSize.dropFirst().sink { [weak self] v in self?.defaults.set(v, forKey: Key.prioritizeTimeOverSize) }.store(in: &cancellables)
        $dnsMode.dropFirst().sink { [weak self] v in self?.defaults.set(v, forKey: Key.dnsMode) }.store(in: &cancellables)
        $customDnsUrl.dropFirst().sink { [weak self] v in self?.defaults.set(v, forKey: Key.customDnsUrl) }.store(in: &cancellables)

        // searchHistory uses JSON encoding so handle separately
        $searchHistory.dropFirst().sink { [weak self] history in
            self?.persistSearchHistory(history)
        }.store(in: &cancellables)
    }

    // MARK: - Search history helpers

    /// Mirrors Kotlin `addSearchHistory`: deduplicates, appends to tail, trims to max 10.
    func addSearchHistory(_ query: String) {
        var history = searchHistory
        history.removeAll { $0 == query }
        history.append(query)
        if history.count > Key.searchHistoryMaxCount {
            history.removeFirst()
        }
        searchHistory = history
    }

    /// Clears the stored search history.
    func clearSearchHistory() {
        searchHistory = []
        defaults.removeObject(forKey: Key.searchHistory)
    }

    // MARK: - Private helpers

    private func persistSearchHistory(_ history: [String]) {
        if let data = try? JSONEncoder().encode(history),
           let json = String(data: data, encoding: .utf8) {
            defaults.set(json, forKey: Key.searchHistory)
        }
    }

    private static func loadSearchHistory(from defaults: UserDefaults) -> [String] {
        guard let json = defaults.string(forKey: Key.searchHistory),
              let data = json.data(using: .utf8),
              let history = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return history
    }
}
