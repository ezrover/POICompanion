import Foundation
import AVFoundation
import Combine

/// Specialized generator for 6-second podcast audio content optimized for POI discoveries
class SixSecondPodcastGenerator: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isGenerating = false
    @Published var generationProgress: Double = 0.0
    @Published var lastGeneratedDuration: TimeInterval = 0.0
    
    // MARK: - Core Components
    private let kittenTTSProcessor: KittenTTSProcessor?
    private let scriptOptimizer = PodcastScriptOptimizer()
    private let audioProcessor = PodcastAudioProcessor()
    private let performanceTracker = PodcastPerformanceTracker()
    
    // MARK: - Configuration
    private let targetDuration: TimeInterval = 6.0
    private let durationTolerance: TimeInterval = 0.5 // ±0.5 seconds
    private let maxGenerationAttempts = 3
    
    // MARK: - Voice Selection for Podcasts
    private let podcastVoices: [POICategory: KittenVoice] = [
        .restaurants: .voice2,      // Female Warm
        .attractions: .voice3,      // Female Energetic  
        .parks: .voice7,           // Male Enthusiastic
        .shopping: .voice0,        // Female Friendly
        .entertainment: .voice3,   // Female Energetic
        .lodging: .voice1,         // Female Professional
        .museums: .voice6,         // Male Calm
        .historicsites: .voice5,   // Male Authoritative
        .beaches: .voice7,         // Male Enthusiastic
        .wineries: .voice3,        // Female Energetic
        .gasstations: .voice1,     // Female Professional
        .viewpoints: .voice7       // Male Enthusiastic
    ]
    
    // MARK: - Initialization
    
    init() {
        do {
            self.kittenTTSProcessor = try KittenTTSProcessor()
        } catch {
            print("⚠️ Failed to initialize Kitten TTS for podcast generation: \(error)")
            self.kittenTTSProcessor = nil
        }
    }
    
    // MARK: - Public Interface
    
    /// Generate 6-second podcast audio for POI discovery
    func generateSixSecondAudio(for poi: POIData, 
                               completion: @escaping (Result<AudioData, PodcastGenerationError>) -> Void) {
        
        guard kittenTTSProcessor != nil else {
            completion(.failure(.ttsUnavailable))
            return
        }
        
        DispatchQueue.main.async {
            self.isGenerating = true
            self.generationProgress = 0.0
        }
        
        let startTime = Date()
        
        // Phase 1: Generate and optimize script (20% progress)
        generateOptimizedScript(for: poi) { [weak self] scriptResult in
            DispatchQueue.main.async { self?.generationProgress = 0.2 }
            
            switch scriptResult {
            case .success(let script):
                // Phase 2: Select optimal voice (40% progress)
                let category = POICategory(rawValue: poi.category) ?? .attractions
                let voice = self?.selectOptimalVoice(for: category) ?? .voice0
                DispatchQueue.main.async { self?.generationProgress = 0.4 }
                
                // Phase 3: Generate audio with duration targeting (60-90% progress)
                self?.generateAudioWithDurationTarget(
                    script: script,
                    voice: voice,
                    poi: poi,
                    attempt: 1,
                    startTime: startTime
                ) { result in
                    DispatchQueue.main.async {
                        self?.isGenerating = false
                        self?.generationProgress = 1.0
                        
                        if case .success(let audioData) = result {
                            self?.lastGeneratedDuration = audioData.duration
                        }
                        
                        completion(result)
                    }
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.isGenerating = false
                    self?.generationProgress = 0.0
                }
                completion(.failure(.scriptGenerationFailed(error)))
            }
        }
    }
    
    /// Generate batch of podcast variations for A/B testing
    func generateVariations(for poi: POIData, 
                           count: Int = 3,
                           completion: @escaping (Result<[PodcastVariation], PodcastGenerationError>) -> Void) {
        
        let group = DispatchGroup()
        var variations: [PodcastVariation] = []
        var errors: [Error] = []
        
        for i in 0..<count {
            group.enter()
            
            generateVariation(for: poi, variationIndex: i) { result in
                switch result {
                case .success(let variation):
                    variations.append(variation)
                case .failure(let error):
                    errors.append(error)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            if variations.isEmpty {
                completion(.failure(.allVariationsFailed(errors)))
            } else {
                completion(.success(variations))
            }
        }
    }
    
    // MARK: - Private Implementation
    
    private func generateOptimizedScript(for poi: POIData, 
                                       completion: @escaping (Result<String, ScriptGenerationError>) -> Void) {
        
        let category = POICategory(rawValue: poi.category) ?? .attractions
        scriptOptimizer.generateScript(
            poiName: poi.name,
            description: poi.reviewSummary ?? "amazing experiences and activities",
            category: category,
            targetDuration: targetDuration
        ) { result in
            switch result {
            case .success(let script):
                let optimizedScript = self.scriptOptimizer.optimizeForSpeech(script)
                completion(.success(optimizedScript))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func selectOptimalVoice(for category: POICategory) -> KittenVoice {
        return podcastVoices[category] ?? .voice2 // Default to warm female voice
    }
    
    private func generateAudioWithDurationTarget(script: String,
                                               voice: KittenVoice,
                                               poi: POIData,
                                               attempt: Int,
                                               startTime: Date,
                                               completion: @escaping (Result<AudioData, PodcastGenerationError>) -> Void) {
        
        let config = createPodcastConfig(voice: voice, attempt: attempt)
        
        kittenTTSProcessor?.synthesize(text: script, config: config) { [weak self] result in
            let progressIncrement = 0.3 / Double(self?.maxGenerationAttempts ?? 3)
            DispatchQueue.main.async {
                self?.generationProgress += progressIncrement
            }
            
            switch result {
            case .success(let audioData):
                let duration = audioData.duration
                let targetDuration = self?.targetDuration ?? 6.0
                let tolerance = self?.durationTolerance ?? 0.5
                
                // Check if duration is within acceptable range
                if abs(duration - targetDuration) <= tolerance {
                    // Success! Duration is acceptable
                    self?.recordSuccess(poi: poi, 
                                      script: script, 
                                      audioData: audioData, 
                                      attempt: attempt,
                                      processingTime: Date().timeIntervalSince(startTime))
                    completion(.success(audioData))
                    
                } else if attempt < self?.maxGenerationAttempts ?? 3 {
                    // Try again with adjusted parameters
                    let adjustedScript = self?.adjustScriptForDuration(
                        script, 
                        currentDuration: duration, 
                        targetDuration: targetDuration
                    ) ?? script
                    
                    self?.generateAudioWithDurationTarget(
                        script: adjustedScript,
                        voice: voice,
                        poi: poi,
                        attempt: attempt + 1,
                        startTime: startTime,
                        completion: completion
                    )
                    
                } else {
                    // Max attempts reached, accept result with warning
                    print("⚠️ Podcast duration \(duration)s not optimal (target: \(targetDuration)s) after \(attempt) attempts")
                    
                    self?.recordSuboptimal(poi: poi, 
                                         script: script, 
                                         audioData: audioData,
                                         attempt: attempt,
                                         processingTime: Date().timeIntervalSince(startTime))
                    completion(.success(audioData))
                }
                
            case .failure(let error):
                if attempt < self?.maxGenerationAttempts ?? 3 {
                    // Retry with fallback voice
                    let fallbackVoice: KittenVoice = voice == .voice0 ? .voice2 : .voice0
                    
                    self?.generateAudioWithDurationTarget(
                        script: script,
                        voice: fallbackVoice,
                        poi: poi,
                        attempt: attempt + 1,
                        startTime: startTime,
                        completion: completion
                    )
                } else {
                    completion(.failure(.synthesisFailedAllAttempts(error)))
                }
            }
        }
    }
    
    private func createPodcastConfig(voice: KittenVoice, attempt: Int) -> KittenTTSConfig {
        // Adjust parameters based on attempt number
        let baseSpeed: Float = 0.85
        let speedAdjustment = Float(attempt - 1) * 0.05 // Slightly faster on retries
        
        return KittenTTSConfig(
            voice: voice,
            speed: baseSpeed + speedAdjustment,
            pitch: 0.1, // Slightly higher for engagement
            quality: .high
        )
    }
    
    private func adjustScriptForDuration(_ script: String, 
                                       currentDuration: TimeInterval, 
                                       targetDuration: TimeInterval) -> String {
        
        let ratio = targetDuration / currentDuration
        let words = script.components(separatedBy: .whitespaces)
        let targetWordCount = Int(Double(words.count) * ratio)
        
        if targetWordCount < words.count {
            // Trim script
            let trimmedWords = Array(words.prefix(targetWordCount))
            var result = trimmedWords.joined(separator: " ")
            
            // Ensure proper ending
            if !result.hasSuffix(".") && !result.hasSuffix("!") && !result.hasSuffix("?") {
                result += "."
            }
            
            return result
        } else {
            // Script is already optimal or needs expansion (less common)
            return script
        }
    }
    
    private func generateVariation(for poi: POIData, 
                                 variationIndex: Int,
                                 completion: @escaping (Result<PodcastVariation, PodcastGenerationError>) -> Void) {
        
        let variationConfig = PodcastVariationConfig.variations[variationIndex % PodcastVariationConfig.variations.count]
        
        let category = POICategory(rawValue: poi.category) ?? .attractions
        scriptOptimizer.generateVariationScript(
            poiName: poi.name,
            description: poi.reviewSummary ?? "amazing experiences and activities",
            category: category,
            variation: variationConfig
        ) { [weak self] scriptResult in
            
            switch scriptResult {
            case .success(let script):
                let voice = variationConfig.voice
                let config = KittenTTSConfig(
                    voice: voice,
                    speed: variationConfig.speed,
                    pitch: variationConfig.pitch,
                    quality: .high
                )
                
                self?.kittenTTSProcessor?.synthesize(text: script, config: config) { result in
                    switch result {
                    case .success(let audioData):
                        let variation = PodcastVariation(
                            id: "\(poi.name)_var_\(variationIndex)",
                            script: script,
                            voice: voice,
                            audioData: audioData,
                            config: variationConfig,
                            duration: audioData.duration
                        )
                        completion(.success(variation))
                        
                    case .failure(let error):
                        completion(.failure(.variationSynthesisFailed(variationIndex, error)))
                    }
                }
                
            case .failure(let error):
                completion(.failure(.variationScriptFailed(variationIndex, error)))
            }
        }
    }
    
    private func recordSuccess(poi: POIData, 
                             script: String, 
                             audioData: AudioData,
                             attempt: Int,
                             processingTime: TimeInterval) {
        
        let category = POICategory(rawValue: poi.category) ?? .attractions
        let metrics = PodcastGenerationMetrics(
            poiName: poi.name,
            category: category,
            scriptLength: script.count,
            audioDuration: audioData.duration,
            attemptsRequired: attempt,
            processingTime: processingTime,
            success: true
        )
        
        performanceTracker.recordMetrics(metrics)
        
        print("✅ 6-second podcast generated successfully for \(poi.name) in \(attempt) attempt(s)")
        print("📊 Duration: \(String(format: "%.1f", audioData.duration))s, Processing: \(String(format: "%.0f", processingTime * 1000))ms")
    }
    
    private func recordSuboptimal(poi: POIData, 
                                script: String, 
                                audioData: AudioData,
                                attempt: Int,
                                processingTime: TimeInterval) {
        
        let category = POICategory(rawValue: poi.category) ?? .attractions
        let metrics = PodcastGenerationMetrics(
            poiName: poi.name,
            category: category,
            scriptLength: script.count,
            audioDuration: audioData.duration,
            attemptsRequired: attempt,
            processingTime: processingTime,
            success: false // Suboptimal duration
        )
        
        performanceTracker.recordMetrics(metrics)
    }
}

// MARK: - Podcast Script Optimizer

class PodcastScriptOptimizer {
    
    private let templates: [POICategory: [String]] = [
        .restaurants: [
            "Discover {name}, a hidden culinary gem offering {description}. Perfect for food lovers seeking authentic flavors.",
            "Hungry? Try {name}! This local favorite serves {description} that'll make your taste buds dance.",
            "Pull over for {name}, where {description} meets incredible hospitality. A true roadside treasure."
        ],
        .attractions: [
            "Don't miss {name}! This amazing {description} offers unforgettable experiences for the whole family.",
            "Adventure awaits at {name}. Experience {description} that creates memories lasting a lifetime.",
            "Stop and explore {name}, featuring {description}. It's worth every minute of your detour."
        ],
        .parks: [
            "Nature lovers, meet {name}! Enjoy {description} surrounded by breathtaking natural beauty.",
            "Escape to {name} for {description}. Connect with nature and recharge your adventure spirit.",
            "Discover {name}, where {description} creates the perfect outdoor adventure experience."
        ]
    ]
    
    func generateScript(poiName: String,
                       description: String,
                       category: POICategory,
                       targetDuration: TimeInterval,
                       completion: @escaping (Result<String, ScriptGenerationError>) -> Void) {
        
        let templates = self.templates[category] ?? self.templates[.attractions] ?? []
        guard let template = templates.randomElement() else {
            completion(.failure(.templateNotFound))
            return
        }
        
        var script = template
            .replacingOccurrences(of: "{name}", with: poiName)
            .replacingOccurrences(of: "{description}", with: description)
        
        // Optimize length for target duration (approximately 3 words per second)
        let targetWords = Int(targetDuration * 3)
        script = optimizeWordCount(script, targetWords: targetWords)
        
        completion(.success(script))
    }
    
    func generateVariationScript(poiName: String,
                               description: String,
                               category: POICategory,
                               variation: PodcastVariationConfig,
                               completion: @escaping (Result<String, ScriptGenerationError>) -> Void) {
        
        let script = variation.scriptTemplate
            .replacingOccurrences(of: "{name}", with: poiName)
            .replacingOccurrences(of: "{description}", with: description)
        
        completion(.success(script))
    }
    
    func optimizeForSpeech(_ script: String) -> String {
        return script
            .replacingOccurrences(of: "&", with: "and")
            .replacingOccurrences(of: "GPS", with: "G P S")
            .replacingOccurrences(of: "POI", with: "point of interest")
            .replacingOccurrences(of: "...", with: ".")
    }
    
    private func optimizeWordCount(_ script: String, targetWords: Int) -> String {
        let words = script.components(separatedBy: .whitespaces)
        
        if words.count <= targetWords {
            return script
        }
        
        let trimmedWords = Array(words.prefix(targetWords))
        var result = trimmedWords.joined(separator: " ")
        
        // Ensure proper ending
        if !result.hasSuffix(".") && !result.hasSuffix("!") && !result.hasSuffix("?") {
            result += "."
        }
        
        return result
    }
}

// MARK: - Supporting Types

struct PodcastVariation {
    let id: String
    let script: String
    let voice: KittenVoice
    let audioData: AudioData
    let config: PodcastVariationConfig
    let duration: TimeInterval
}

struct PodcastVariationConfig {
    let name: String
    let voice: KittenVoice
    let speed: Float
    let pitch: Float
    let scriptTemplate: String
    
    static let variations: [PodcastVariationConfig] = [
        PodcastVariationConfig(
            name: "Enthusiastic",
            voice: .voice3,
            speed: 0.9,
            pitch: 0.2,
            scriptTemplate: "Amazing discovery! {name} offers incredible {description}. This is exactly what makes road trips special!"
        ),
        PodcastVariationConfig(
            name: "Professional",
            voice: .voice1,
            speed: 0.85,
            pitch: 0.0,
            scriptTemplate: "Introducing {name}, featuring {description}. An excellent addition to your journey itinerary."
        ),
        PodcastVariationConfig(
            name: "Casual",
            voice: .voice4,
            speed: 0.95,
            pitch: 0.1,
            scriptTemplate: "Check out {name}! They've got {description} that's definitely worth a stop on your trip."
        )
    ]
}

struct PodcastGenerationMetrics {
    let poiName: String
    let category: POICategory
    let scriptLength: Int
    let audioDuration: TimeInterval
    let attemptsRequired: Int
    let processingTime: TimeInterval
    let success: Bool
    let timestamp: Date = Date()
}

class PodcastPerformanceTracker {
    private var metrics: [PodcastGenerationMetrics] = []
    private let maxStoredMetrics = 100
    
    func recordMetrics(_ metrics: PodcastGenerationMetrics) {
        self.metrics.append(metrics)
        
        // Keep only recent metrics
        if self.metrics.count > maxStoredMetrics {
            self.metrics.removeFirst(self.metrics.count - maxStoredMetrics)
        }
    }
    
    func getAverageProcessingTime() -> TimeInterval {
        guard !metrics.isEmpty else { return 0 }
        
        let total = metrics.reduce(0) { $0 + $1.processingTime }
        return total / Double(metrics.count)
    }
    
    func getSuccessRate() -> Double {
        guard !metrics.isEmpty else { return 0 }
        
        let successCount = metrics.filter { $0.success }.count
        return Double(successCount) / Double(metrics.count)
    }
}

class PodcastAudioProcessor {
    // Future: Audio post-processing for podcast enhancement
    // Could include normalization, EQ, compression for automotive playback
}

enum PodcastGenerationError: Error {
    case ttsUnavailable
    case scriptGenerationFailed(ScriptGenerationError)
    case synthesisFailedAllAttempts(KittenTTSError)
    case allVariationsFailed([Error])
    case variationSynthesisFailed(Int, KittenTTSError)
    case variationScriptFailed(Int, ScriptGenerationError)
    
    var localizedDescription: String {
        switch self {
        case .ttsUnavailable:
            return "Text-to-speech engine not available for podcast generation"
        case .scriptGenerationFailed(let error):
            return "Failed to generate podcast script: \(error)"
        case .synthesisFailedAllAttempts(let error):
            return "Audio synthesis failed after all attempts: \(error.localizedDescription)"
        case .allVariationsFailed(let errors):
            return "All podcast variations failed: \(errors.count) errors"
        case .variationSynthesisFailed(let index, let error):
            return "Variation \(index) synthesis failed: \(error.localizedDescription)"
        case .variationScriptFailed(let index, let error):
            return "Variation \(index) script generation failed: \(error)"
        }
    }
}

enum ScriptGenerationError: Error {
    case templateNotFound
    case optimizationFailed
    case invalidInput
    
    var localizedDescription: String {
        switch self {
        case .templateNotFound: return "Script template not found"
        case .optimizationFailed: return "Script optimization failed"
        case .invalidInput: return "Invalid input for script generation"
        }
    }
}