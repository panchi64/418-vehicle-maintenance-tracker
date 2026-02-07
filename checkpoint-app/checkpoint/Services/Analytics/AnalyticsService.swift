//
//  AnalyticsService.swift
//  checkpoint
//
//  PostHog analytics wrapper with privacy-respecting, opt-out design
//

import Foundation
import os
@preconcurrency import PostHog

/// Manages analytics event capture via PostHog SDK.
/// Reads configuration from Info.plist keys `POSTHOG_API_KEY` and `POSTHOG_HOST`.
/// If either key is missing or empty, analytics are silently disabled.
@Observable
@MainActor
final class AnalyticsService {
    static let shared = AnalyticsService()

    private let logger = Logger(subsystem: "com.418-studio.checkpoint", category: "Analytics")
    private var isInitialized = false

    private init() {}

    // MARK: - Initialization

    /// Initialize PostHog SDK with config from Info.plist. Call once in checkpointApp.init().
    func initialize() {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "POSTHOG_API_KEY") as? String,
              !apiKey.isEmpty,
              !apiKey.hasPrefix("$(") else {
            logger.warning("PostHog API key not configured — analytics disabled")
            return
        }

        guard let hostString = Bundle.main.object(forInfoDictionaryKey: "POSTHOG_HOST") as? String,
              !hostString.isEmpty,
              !hostString.hasPrefix("$(") else {
            logger.warning("PostHog host not configured — analytics disabled")
            return
        }

        let config = PostHogConfig(apiKey: apiKey, host: hostString)
        config.captureScreenViews = false
        config.captureApplicationLifecycleEvents = false
        config.captureElementInteractions = false
        config.enableSwizzling = false
        config.preloadFeatureFlags = false
        config.sendFeatureFlagEvent = false
        config.sessionReplay = false
        config.surveys = false
        config.remoteConfig = false
        config.flushAt = 20
        config.flushIntervalSeconds = 30
        config.personProfiles = .identifiedOnly

        PostHogSDK.shared.setup(config)
        isInitialized = true

        // Sync opt-out state with user preference
        if AnalyticsSettings.shared.isEnabled {
            PostHogSDK.shared.optIn()
        } else {
            PostHogSDK.shared.optOut()
        }

        logger.info("PostHog initialized successfully")
    }

    // MARK: - Event Capture

    /// Capture an analytics event. Gated on initialization and user opt-in.
    func capture(_ event: AnalyticsEvent) {
        guard isInitialized, AnalyticsSettings.shared.isEnabled else { return }

        #if DEBUG
        logger.debug("Event: \(event.name) \(event.properties.isEmpty ? "" : String(describing: event.properties))")
        #endif

        PostHogSDK.shared.capture(event.name, properties: event.properties)
    }

    // MARK: - Opt-In / Opt-Out

    /// Update analytics consent. Sends the opt event before changing SDK state.
    func setEnabled(_ enabled: Bool) {
        AnalyticsSettings.shared.isEnabled = enabled

        guard isInitialized else { return }

        if enabled {
            PostHogSDK.shared.optIn()
            capture(.analyticsOptedIn)
        } else {
            capture(.analyticsOptedOut)
            PostHogSDK.shared.optOut()
        }

        logger.info("Analytics \(enabled ? "opted in" : "opted out")")
    }

    // MARK: - Flush

    /// Flush queued events. Call on scenePhase == .background.
    func flush() {
        guard isInitialized else { return }
        PostHogSDK.shared.flush()
    }
}
