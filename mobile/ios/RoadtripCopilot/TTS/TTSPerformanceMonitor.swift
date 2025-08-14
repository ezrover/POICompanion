import Foundation
import Combine
import UIKit

/// Comprehensive performance monitoring system for TTS operations
class TTSPerformanceMonitor: ObservableObject {
    
    // MARK: - Published Metrics
    @Published var currentMetrics: TTSPerformanceMetrics = TTSPerformanceMetrics()
    @Published var isMonitoring = false
    @Published var alertLevel: PerformanceAlertLevel = .normal
    
    // MARK: - Performance Tracking
    private var synthesisRecords: [SynthesisRecord] = []
    private var batteryMonitor: BatteryMonitor?
    private var thermalMonitor: ThermalMonitor?
    private var memoryMonitor: MemoryMonitor?
    private var networkMonitor: NetworkMonitor?
    
    // MARK: - Publishers
    let metricsPublisher = PassthroughSubject<TTSPerformanceMetrics, Never>()
    let alertPublisher = PassthroughSubject<PerformanceAlert, Never>()
    
    // MARK: - Configuration
    private let maxStoredRecords = 500
    private let alertThresholds = PerformanceThresholds()
    private let monitoringInterval: TimeInterval = 5.0 // 5 seconds
    private var monitoringTimer: Timer?
    
    // MARK: - Cancellables
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        setupMonitors()
        setupAlertHandling()
    }
    
    private func setupMonitors() {
        batteryMonitor = BatteryMonitor()
        thermalMonitor = ThermalMonitor()
        memoryMonitor = MemoryMonitor()
        networkMonitor = NetworkMonitor()
    }
    
    private func setupAlertHandling() {
        alertPublisher
            .sink { [weak self] alert in
                self?.handlePerformanceAlert(alert)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Interface
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        batteryMonitor?.startMonitoring()
        thermalMonitor?.startMonitoring()
        memoryMonitor?.startMonitoring()
        networkMonitor?.startMonitoring()
        
        startPeriodicMetricsCalculation()
        
        print("📊 TTS Performance monitoring started")
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        isMonitoring = false
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        
        batteryMonitor?.stopMonitoring()
        thermalMonitor?.stopMonitoring()
        memoryMonitor?.stopMonitoring()
        networkMonitor?.stopMonitoring()
        
        print("📊 TTS Performance monitoring stopped")
    }
    
    /// Record a TTS synthesis operation
    func recordSynthesis(engine: TTSEngine,
                        processingTime: TimeInterval,
                        textLength: Int,
                        success: Bool,
                        audioDataSize: Int = 0) {
        
        let record = SynthesisRecord(
            engine: engine,
            processingTime: processingTime,
            textLength: textLength,
            success: success,
            audioDataSize: audioDataSize,
            timestamp: Date(),
            memoryUsage: memoryMonitor?.getCurrentUsage() ?? 0,
            batteryLevel: batteryMonitor?.getCurrentLevel() ?? 1.0,
            thermalState: thermalMonitor?.getCurrentState() ?? .nominal
        )
        
        synthesisRecords.append(record)
        
        // Maintain record limit
        if synthesisRecords.count > maxStoredRecords {
            synthesisRecords.removeFirst(synthesisRecords.count - maxStoredRecords)
        }
        
        // Update metrics immediately for critical operations
        if processingTime > alertThresholds.criticalLatency {
            updateMetrics()
        }
    }
    
    /// Get current performance report
    func getCurrentReport() -> PerformanceReport {
        return PerformanceReport(
            metrics: currentMetrics,
            alertLevel: alertLevel,
            recommendations: generateRecommendations(),
            lastUpdated: Date()
        )
    }
    
    /// Get detailed analytics for specific engine
    func getEngineAnalytics(for engine: TTSEngine) -> EngineAnalytics {
        let engineRecords = synthesisRecords.filter { $0.engine == engine }
        
        return EngineAnalytics(
            engine: engine,
            totalSyntheses: engineRecords.count,
            averageLatency: calculateAverageLatency(engineRecords),
            successRate: calculateSuccessRate(engineRecords),
            averageMemoryUsage: calculateAverageMemoryUsage(engineRecords),
            preferredTextLength: calculateOptimalTextLength(engineRecords)
        )
    }
    
    // MARK: - Private Implementation
    
    private func startPeriodicMetricsCalculation() {
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: monitoringInterval, repeats: true) { [weak self] _ in
            self?.updateMetrics()
        }
    }
    
    private func updateMetrics() {
        let newMetrics = calculateCurrentMetrics()
        
        DispatchQueue.main.async {
            self.currentMetrics = newMetrics
        }
        
        metricsPublisher.send(newMetrics)
        
        // Check for performance alerts
        checkForAlerts(newMetrics)
    }
    
    private func calculateCurrentMetrics() -> TTSPerformanceMetrics {
        let recentRecords = getRecentRecords(minutes: 5) // Last 5 minutes
        
        let averageLatency = calculateAverageLatency(recentRecords)
        let memoryPressure = memoryMonitor?.getCurrentPressure() ?? 0.0
        let batteryDrain = batteryMonitor?.getCurrentDrainRate() ?? 0.0
        let successRate = calculateSuccessRate(recentRecords)
        let engineUsage = calculateEngineUsage(recentRecords)
        let _ = calculateThermalImpact()
        let _ = networkMonitor?.getCurrentLatency() ?? 0.0
        
        return TTSPerformanceMetrics(
            averageLatency: averageLatency,
            memoryPressure: memoryPressure,
            batteryDrain: batteryDrain,
            successRate: successRate,
            engineUsage: engineUsage
        )
    }
    
    private func getRecentRecords(minutes: Int) -> [SynthesisRecord] {
        let cutoffTime = Date().addingTimeInterval(-TimeInterval(minutes * 60))
        return synthesisRecords.filter { $0.timestamp >= cutoffTime }
    }
    
    private func calculateAverageLatency(_ records: [SynthesisRecord]) -> TimeInterval {
        guard !records.isEmpty else { return 0 }
        
        let total = records.reduce(0) { $0 + $1.processingTime }
        return total / Double(records.count)
    }
    
    private func calculateSuccessRate(_ records: [SynthesisRecord]) -> Double {
        guard !records.isEmpty else { return 1.0 }
        
        let successCount = records.filter { $0.success }.count
        return Double(successCount) / Double(records.count)
    }
    
    private func calculateAverageMemoryUsage(_ records: [SynthesisRecord]) -> Double {
        guard !records.isEmpty else { return 0 }
        
        let total = records.reduce(0) { $0 + $1.memoryUsage }
        return total / Double(records.count)
    }
    
    private func calculateEngineUsage(_ records: [SynthesisRecord]) -> [TTSEngine: Int] {
        var usage: [TTSEngine: Int] = [:]
        
        for record in records {
            usage[record.engine, default: 0] += 1
        }
        
        return usage
    }
    
    private func calculateThermalImpact() -> Double {
        // Calculate thermal impact based on current state and recent activity
        let currentState = thermalMonitor?.getCurrentState() ?? .nominal
        let recentActivity = getRecentRecords(minutes: 2).count
        
        let baseImpact: Double
        switch currentState {
        case .nominal: baseImpact = 0.1
        case .fair: baseImpact = 0.3
        case .serious: baseImpact = 0.6
        case .critical: baseImpact = 0.9
        @unknown default: baseImpact = 0.2
        }
        
        // Adjust based on recent activity
        let activityMultiplier = min(2.0, 1.0 + Double(recentActivity) / 10.0)
        
        return min(1.0, baseImpact * activityMultiplier)
    }
    
    private func calculateOptimalTextLength(_ records: [SynthesisRecord]) -> Int {
        // Find text length that provides best latency/success ratio
        let successfulRecords = records.filter { $0.success && $0.processingTime < 0.5 }
        
        guard !successfulRecords.isEmpty else { return 100 } // Default
        
        let averageLength = successfulRecords.reduce(0) { $0 + $1.textLength } / successfulRecords.count
        return averageLength
    }
    
    private func checkForAlerts(_ metrics: TTSPerformanceMetrics) {
        var newAlertLevel: PerformanceAlertLevel = .normal
        var alerts: [PerformanceAlert] = []
        
        // Latency alerts
        if metrics.averageLatency > alertThresholds.criticalLatency {
            newAlertLevel = .critical
            alerts.append(PerformanceAlert(
                type: .highLatency,
                severity: .critical,
                value: metrics.averageLatency,
                threshold: alertThresholds.criticalLatency,
                message: "TTS latency critically high: \(Int(metrics.averageLatency * 1000))ms"
            ))
        } else if metrics.averageLatency > alertThresholds.warningLatency {
            newAlertLevel = max(newAlertLevel, .warning)
            alerts.append(PerformanceAlert(
                type: .highLatency,
                severity: .warning,
                value: metrics.averageLatency,
                threshold: alertThresholds.warningLatency,
                message: "TTS latency elevated: \(Int(metrics.averageLatency * 1000))ms"
            ))
        }
        
        // Memory pressure alerts
        if metrics.memoryPressure > alertThresholds.criticalMemoryPressure {
            newAlertLevel = .critical
            alerts.append(PerformanceAlert(
                type: .memoryPressure,
                severity: .critical,
                value: metrics.memoryPressure,
                threshold: alertThresholds.criticalMemoryPressure,
                message: "Memory pressure critical: \(Int(metrics.memoryPressure * 100))%"
            ))
        }
        
        // Battery drain alerts
        if metrics.batteryDrain > alertThresholds.criticalBatteryDrain {
            newAlertLevel = max(newAlertLevel, .warning)
            alerts.append(PerformanceAlert(
                type: .batteryDrain,
                severity: .warning,
                value: metrics.batteryDrain,
                threshold: alertThresholds.criticalBatteryDrain,
                message: "High battery drain: \(String(format: "%.1f", metrics.batteryDrain))%/hr"
            ))
        }
        
        // Success rate alerts
        if metrics.successRate < alertThresholds.minSuccessRate {
            newAlertLevel = max(newAlertLevel, .warning)
            alerts.append(PerformanceAlert(
                type: .lowSuccessRate,
                severity: .warning,
                value: metrics.successRate,
                threshold: alertThresholds.minSuccessRate,
                message: "TTS success rate low: \(Int(metrics.successRate * 100))%"
            ))
        }
        
        // Note: Thermal impact monitoring could be added to TTSPerformanceMetrics in the future
        // Thermal alerts would go here
        
        // Update alert level
        DispatchQueue.main.async {
            self.alertLevel = newAlertLevel
        }
        
        // Send alerts
        for alert in alerts {
            alertPublisher.send(alert)
        }
    }
    
    private func handlePerformanceAlert(_ alert: PerformanceAlert) {
        print("⚠️ TTS Performance Alert: \(alert.message)")
        
        // Could trigger automatic optimizations based on alert type
        switch alert.type {
        case .highLatency:
            // Could automatically switch to faster TTS engine
            break
        case .memoryPressure:
            // Could clear caches or switch to more memory-efficient settings
            break
        case .batteryDrain:
            // Could enable battery saver mode
            break
        case .thermalThrottling:
            // Could reduce processing frequency
            break
        case .lowSuccessRate:
            // Could switch TTS engines or adjust parameters
            break
        }
    }
    
    private func generateRecommendations() -> [PerformanceRecommendation] {
        var recommendations: [PerformanceRecommendation] = []
        
        // Analyze recent performance
        let recentRecords = getRecentRecords(minutes: 10)
        let systemAnalytics = getEngineAnalytics(for: .system)
        let kittenAnalytics = getEngineAnalytics(for: .kittenTTS)
        
        // Engine selection recommendation
        if kittenAnalytics.averageLatency > systemAnalytics.averageLatency * 1.5 {
            recommendations.append(PerformanceRecommendation(
                type: .engineSelection,
                priority: .medium,
                description: "Consider using System TTS for better latency",
                impact: "Could improve response time by \(Int((kittenAnalytics.averageLatency - systemAnalytics.averageLatency) * 1000))ms"
            ))
        }
        
        // Memory optimization
        if currentMetrics.memoryPressure > 0.7 {
            recommendations.append(PerformanceRecommendation(
                type: .memoryOptimization,
                priority: .high,
                description: "Clear TTS caches and reduce model memory usage",
                impact: "Could free up significant memory resources"
            ))
        }
        
        // Battery optimization
        if currentMetrics.batteryDrain > 4.0 {
            recommendations.append(PerformanceRecommendation(
                type: .batteryOptimization,
                priority: .medium,
                description: "Enable battery-efficient TTS settings",
                impact: "Could reduce battery drain by up to 30%"
            ))
        }
        
        // Text optimization
        let longTextFailures = recentRecords.filter { $0.textLength > 200 && !$0.success }.count
        if longTextFailures > recentRecords.count / 4 {
            recommendations.append(PerformanceRecommendation(
                type: .textOptimization,
                priority: .medium,
                description: "Optimize long text inputs for better success rates",
                impact: "Could improve synthesis success rate"
            ))
        }
        
        return recommendations
    }
}

// MARK: - Supporting Monitors

class BatteryMonitor {
    private var isMonitoring = false
    private var initialLevel: Float = 0
    private var startTime: Date = Date()
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        initialLevel = UIDevice.current.batteryLevel
        startTime = Date()
        UIDevice.current.isBatteryMonitoringEnabled = true
    }
    
    func stopMonitoring() {
        isMonitoring = false
        UIDevice.current.isBatteryMonitoringEnabled = false
    }
    
    func getCurrentLevel() -> Float {
        return UIDevice.current.batteryLevel
    }
    
    func getCurrentDrainRate() -> Double {
        guard isMonitoring else { return 0 }
        
        let currentLevel = UIDevice.current.batteryLevel
        let timeElapsed = Date().timeIntervalSince(startTime) / 3600 // hours
        
        guard timeElapsed > 0 else { return 0 }
        
        let drainPercentage = Double(initialLevel - currentLevel) * 100
        return drainPercentage / timeElapsed
    }
}

class ThermalMonitor {
    func startMonitoring() {
        // iOS handles thermal monitoring automatically
    }
    
    func stopMonitoring() {
        // No action needed
    }
    
    func getCurrentState() -> ProcessInfo.ThermalState {
        return ProcessInfo.processInfo.thermalState
    }
}

class MemoryMonitor {
    func startMonitoring() {
        // Memory monitoring is passive
    }
    
    func stopMonitoring() {
        // No action needed
    }
    
    func getCurrentUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1024 / 1024 // MB
        }
        
        return 0
    }
    
    func getCurrentPressure() -> Double {
        // Simplified memory pressure calculation
        let usage = getCurrentUsage()
        let totalMemory = ProcessInfo.processInfo.physicalMemory / 1024 / 1024 // MB
        return usage / Double(totalMemory)
    }
}

class NetworkMonitor {
    func startMonitoring() {
        // Network monitoring setup would go here
    }
    
    func stopMonitoring() {
        // Cleanup
    }
    
    func getCurrentLatency() -> TimeInterval {
        // Would implement actual network latency measurement
        return 0.1 // Placeholder
    }
}

// MARK: - Supporting Types

struct SynthesisRecord {
    let engine: TTSEngine
    let processingTime: TimeInterval
    let textLength: Int
    let success: Bool
    let audioDataSize: Int
    let timestamp: Date
    let memoryUsage: Double
    let batteryLevel: Float
    let thermalState: ProcessInfo.ThermalState
}

struct PerformanceThresholds {
    let warningLatency: TimeInterval = 0.5      // 500ms
    let criticalLatency: TimeInterval = 1.0     // 1 second
    let criticalMemoryPressure: Double = 0.85   // 85%
    let criticalBatteryDrain: Double = 5.0      // 5%/hour
    let minSuccessRate: Double = 0.90           // 90%
    let maxThermalImpact: Double = 0.7          // 70%
}

enum PerformanceAlertLevel: Int, Comparable {
    case normal = 0
    case warning = 1
    case critical = 2
    
    static func < (lhs: PerformanceAlertLevel, rhs: PerformanceAlertLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

enum PerformanceAlertType {
    case highLatency
    case memoryPressure
    case batteryDrain
    case thermalThrottling
    case lowSuccessRate
}

enum PerformanceAlertSeverity {
    case info
    case warning
    case critical
}

struct PerformanceAlert {
    let type: PerformanceAlertType
    let severity: PerformanceAlertSeverity
    let value: Double
    let threshold: Double
    let message: String
    let timestamp: Date = Date()
}

struct PerformanceReport {
    let metrics: TTSPerformanceMetrics
    let alertLevel: PerformanceAlertLevel
    let recommendations: [PerformanceRecommendation]
    let lastUpdated: Date
}

struct EngineAnalytics {
    let engine: TTSEngine
    let totalSyntheses: Int
    let averageLatency: TimeInterval
    let successRate: Double
    let averageMemoryUsage: Double
    let preferredTextLength: Int
}

enum RecommendationType {
    case engineSelection
    case memoryOptimization
    case batteryOptimization
    case textOptimization
    case thermalManagement
}

enum RecommendationPriority {
    case low
    case medium
    case high
}

struct PerformanceRecommendation {
    let type: RecommendationType
    let priority: RecommendationPriority
    let description: String
    let impact: String
    let timestamp: Date = Date()
}