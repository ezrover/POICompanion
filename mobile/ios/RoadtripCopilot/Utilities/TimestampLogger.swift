import Foundation

/// Performance monitoring utility with precise timestamps
/// Provides consistent timestamp formatting and slow process detection
struct TimestampLogger {
    
    // MARK: - Timestamp Formatting
    
    /// Returns current timestamp in ISO format with milliseconds: 2025-08-13T17:18:07.825Z
    static var currentTimestamp: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: Date())
    }
    
    /// Returns timestamp for a specific date in consistent ISO format
    static func timestamp(for date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
    
    // MARK: - Performance Thresholds (in milliseconds)
    
    enum PerformanceThreshold {
        static let search: TimeInterval = 2.0        // Search operations: >2 seconds
        static let voiceResponse: TimeInterval = 0.5 // Voice recognition: >500ms response
        static let navigation: TimeInterval = 1.0    // Navigation transitions: >1 second
        static let audioSetup: TimeInterval = 1.0    // Audio session changes: >1 second
        static let appLaunch: TimeInterval = 2.0     // App launch sequence: >2 seconds
    }
    
    // MARK: - Logging Methods
    
    /// Log with timestamp and optional performance monitoring
    static func log(_ message: String, category: String = "General", level: LogLevel = .info) {
        let timestamp = currentTimestamp
        let levelPrefix = level.prefix
        print("[\(timestamp)] [\(category)] \(levelPrefix)\(message)")
    }
    
    /// Log performance-critical operation with start timestamp
    static func logStart(_ operation: String, category: String = "Performance") -> Date {
        let startTime = Date()
        let timestamp = TimestampLogger.timestamp(for: startTime)
        print("[\(timestamp)] [\(category)] 🚀 START: \(operation)")
        return startTime
    }
    
    /// Log performance-critical operation completion with duration and slow process detection
    static func logEnd(_ operation: String, startTime: Date, threshold: TimeInterval? = nil, category: String = "Performance") {
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        let durationMs = Int(duration * 1000)
        
        let timestamp = TimestampLogger.timestamp(for: endTime)
        let durationText = formatDuration(duration)
        
        // Check if operation exceeded threshold
        if let threshold = threshold, duration > threshold {
            let thresholdMs = Int(threshold * 1000)
            print("[\(timestamp)] [\(category)] 🐌 SLOW END: \(operation) - \(durationText) (threshold: \(thresholdMs)ms)")
        } else {
            print("[\(timestamp)] [\(category)] ✅ END: \(operation) - \(durationText)")
        }
    }
    
    /// Log search operation with automatic threshold detection
    static func logSearchStart(_ query: String) -> Date {
        return logStart("Search for '\(query)'", category: "Search")
    }
    
    static func logSearchEnd(_ query: String, startTime: Date, resultCount: Int = 0) {
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        let timestamp = TimestampLogger.timestamp(for: endTime)
        let durationText = formatDuration(duration)
        
        if duration > PerformanceThreshold.search {
            print("[\(timestamp)] [Search] 🐌 SLOW SEARCH: '\(query)' - \(durationText) - \(resultCount) results (threshold: 2000ms)")
        } else {
            print("[\(timestamp)] [Search] ✅ SEARCH COMPLETE: '\(query)' - \(durationText) - \(resultCount) results")
        }
    }
    
    /// Log voice recognition operations
    static func logVoiceStart() -> Date {
        return logStart("Voice Recognition", category: "Voice")
    }
    
    static func logVoiceEnd(_ recognizedText: String, startTime: Date) {
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        let timestamp = TimestampLogger.timestamp(for: endTime)
        let durationText = formatDuration(duration)
        
        if duration > PerformanceThreshold.voiceResponse {
            print("[\(timestamp)] [Voice] 🐌 SLOW VOICE: '\(recognizedText)' - \(durationText) (threshold: 500ms)")
        } else {
            print("[\(timestamp)] [Voice] ✅ VOICE COMPLETE: '\(recognizedText)' - \(durationText)")
        }
    }
    
    /// Log navigation operations
    static func logNavigationStart(_ operation: String) -> Date {
        return logStart("Navigation: \(operation)", category: "Navigation")
    }
    
    static func logNavigationEnd(_ operation: String, startTime: Date) {
        logEnd("Navigation: \(operation)", startTime: startTime, threshold: PerformanceThreshold.navigation, category: "Navigation")
    }
    
    /// Log audio session operations
    static func logAudioStart(_ operation: String) -> Date {
        return logStart("Audio: \(operation)", category: "Audio")
    }
    
    static func logAudioEnd(_ operation: String, startTime: Date) {
        logEnd("Audio: \(operation)", startTime: startTime, threshold: PerformanceThreshold.audioSetup, category: "Audio")
    }
    
    /// Log app launch operations
    static func logAppLaunchStart(_ operation: String) -> Date {
        return logStart("AppLaunch: \(operation)", category: "AppLaunch")
    }
    
    static func logAppLaunchEnd(_ operation: String, startTime: Date) {
        logEnd("AppLaunch: \(operation)", startTime: startTime, threshold: PerformanceThreshold.appLaunch, category: "AppLaunch")
    }
    
    // MARK: - Utility Methods
    
    /// Format duration in human-readable format with milliseconds
    private static func formatDuration(_ duration: TimeInterval) -> String {
        let milliseconds = Int(duration * 1000)
        
        if duration >= 1.0 {
            return String(format: "%.3fs (%dms)", duration, milliseconds)
        } else {
            return "\(milliseconds)ms"
        }
    }
    
    // MARK: - Log Levels
    
    enum LogLevel {
        case debug
        case info
        case warning
        case error
        
        var prefix: String {
            switch self {
            case .debug: return "🔍 "
            case .info: return "ℹ️ "
            case .warning: return "⚠️ "
            case .error: return "❌ "
            }
        }
    }
}

// MARK: - Convenience Extensions

extension TimestampLogger {
    
    /// Quick timestamp logging for debugging
    static func debug(_ message: String, category: String = "Debug") {
        log(message, category: category, level: .debug)
    }
    
    static func info(_ message: String, category: String = "Info") {
        log(message, category: category, level: .info)
    }
    
    static func warning(_ message: String, category: String = "Warning") {
        log(message, category: category, level: .warning)
    }
    
    static func error(_ message: String, category: String = "Error") {
        log(message, category: category, level: .error)
    }
}

// MARK: - Performance Monitoring Protocols

/// Protocol for objects that can be performance-monitored
protocol PerformanceMonitored {
    var className: String { get }
}

extension PerformanceMonitored {
    var className: String {
        return String(describing: type(of: self))
    }
    
    func logStart(_ operation: String) -> Date {
        return TimestampLogger.logStart("\(className): \(operation)")
    }
    
    func logEnd(_ operation: String, startTime: Date, threshold: TimeInterval? = nil) {
        TimestampLogger.logEnd("\(className): \(operation)", startTime: startTime, threshold: threshold)
    }
}