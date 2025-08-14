import Foundation

/// Simple timestamp logger for performance tracking
struct TimestampLogger {
    static func info(_ message: String, category: String = "") {
        #if DEBUG
        print("[\(category)] \(message)")
        #endif
    }
    
    static func logNavigationStart(_ action: String) -> Date {
        let startTime = Date()
        info("Navigation started: \(action)", category: "Navigation")
        return startTime
    }
    
    static func logNavigationEnd(_ action: String, startTime: Date) {
        let elapsed = Date().timeIntervalSince(startTime)
        info("Navigation completed: \(action) in \(elapsed)s", category: "Navigation")
    }
    
    static func logAudioStart(_ action: String) -> Date {
        let startTime = Date()
        info("Audio started: \(action)", category: "Audio")
        return startTime
    }
    
    static func logAudioEnd(_ action: String, startTime: Date) {
        let elapsed = Date().timeIntervalSince(startTime)
        info("Audio completed: \(action) in \(elapsed)s", category: "Audio")
    }
    
    static func logSearchStart(_ query: String) -> Date {
        let startTime = Date()
        info("Search started: \(query)", category: "Search")
        return startTime
    }
    
    static func logSearchEnd(_ query: String, startTime: Date, resultCount: Int) {
        let elapsed = Date().timeIntervalSince(startTime)
        info("Search completed: \(query) with \(resultCount) results in \(elapsed)s", category: "Search")
    }
}