import Foundation
import CoreML
import AVFoundation
import Accelerate

/// Kitten TTS processor optimized for automotive on-device text-to-speech
class KittenTTSProcessor {
    
    // MARK: - Properties
    private let coreMLModel: MLModel
    private let audioEngine: AVAudioEngine
    private let audioPlayerNode: AVAudioPlayerNode
    private var isInitialized = false
    private let modelQueue = DispatchQueue(label: "com.roadtrip.kitten-tts", qos: .userInitiated)
    
    // MARK: - Performance Metrics
    private var averageInferenceTime: TimeInterval = 0
    private var inferenceCount = 0
    private let maxCacheSize = 50 // Cache up to 50 recent synthesized phrases
    private var synthesisCache: [String: AudioData] = [:]
    
    // MARK: - Configuration
    let availableVoices: [KittenVoice] = [
        .voice0, .voice1, .voice2, .voice3, // Female voices
        .voice4, .voice5, .voice6, .voice7  // Male voices
    ]
    
    var isAvailable: Bool {
        return isInitialized && !audioEngine.isRunning
    }
    
    // MARK: - Initialization
    
    init() throws {
        // Load Kitten TTS Core ML model
        guard let modelURL = Bundle.main.url(forResource: "kitten_tts_nano", withExtension: "mlmodelc") else {
            throw KittenTTSError.modelNotFound
        }
        
        do {
            self.coreMLModel = try MLModel(contentsOf: modelURL)
        } catch {
            throw KittenTTSError.modelLoadFailed(error)
        }
        
        // Initialize audio engine
        self.audioEngine = AVAudioEngine()
        self.audioPlayerNode = AVAudioPlayerNode()
        
        setupAudioEngine()
        
        isInitialized = true
        print("✅ Kitten TTS initialized with \(availableVoices.count) voices")
    }
    
    private func setupAudioEngine() {
        audioEngine.attach(audioPlayerNode)
        audioEngine.connect(audioPlayerNode, 
                          to: audioEngine.mainMixerNode, 
                          format: audioEngine.mainMixerNode.outputFormat(forBus: 0))
        
        do {
            try audioEngine.start()
        } catch {
            print("⚠️ Failed to start audio engine: \(error)")
        }
    }
    
    // MARK: - Public Interface
    
    /// Synthesize text to speech with Kitten TTS
    func synthesize(text: String, 
                   config: KittenTTSConfig,
                   completion: @escaping (Result<AudioData, KittenTTSError>) -> Void) {
        
        // Check cache first for common phrases
        let cacheKey = generateCacheKey(text: text, config: config)
        if let cachedAudio = synthesisCache[cacheKey] {
            completion(.success(cachedAudio))
            return
        }
        
        modelQueue.async { [weak self] in
            self?.performSynthesis(text: text, config: config, cacheKey: cacheKey, completion: completion)
        }
    }
    
    /// Quick synthesis for command feedback (optimized for <200ms)
    func synthesizeQuick(text: String, completion: @escaping (Result<AudioData, KittenTTSError>) -> Void) {
        let quickConfig = KittenTTSConfig(
            voice: .voice0, // Fastest voice
            speed: 1.2,     // Slightly faster
            pitch: 0.0,
            quality: .fast
        )
        
        synthesize(text: text, config: quickConfig, completion: completion)
    }
    
    /// Generate 6-second podcast audio
    func generatePodcastAudio(script: String, 
                             voice: KittenVoice = .voice2,
                             completion: @escaping (Result<AudioData, KittenTTSError>) -> Void) {
        
        let podcastConfig = KittenTTSConfig(
            voice: voice,
            speed: 0.9,     // Slightly slower for clarity
            pitch: 0.1,     // Slightly higher for engagement
            quality: .high
        )
        
        // Optimize script for 6-second duration
        let optimizedScript = optimizeScriptForDuration(script, targetDuration: 6.0)
        
        synthesize(text: optimizedScript, config: podcastConfig) { result in
            switch result {
            case .success(let audioData):
                // Validate duration is close to 6 seconds
                if audioData.duration > 7.0 {
                    print("⚠️ Generated audio (\(audioData.duration)s) exceeds 6-second target")
                }
                completion(.success(audioData))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Stop current synthesis
    func stopSynthesis() {
        audioPlayerNode.stop()
    }
    
    /// Optimize for memory constraints
    func optimizeForMemory() {
        // Clear synthesis cache
        synthesisCache.removeAll()
        
        // Force garbage collection of Core ML resources
        // Note: Core ML handles this automatically, but we can help
        print("🧹 Kitten TTS memory optimization completed")
    }
    
    // MARK: - Private Implementation
    
    private func performSynthesis(text: String, 
                                config: KittenTTSConfig,
                                cacheKey: String,
                                completion: @escaping (Result<AudioData, KittenTTSError>) -> Void) {
        
        let startTime = Date()
        
        do {
            // Prepare input for Core ML model
            let input = try prepareModelInput(text: text, config: config)
            
            // Run inference
            let prediction = try coreMLModel.prediction(from: input)
            
            // Extract audio data from prediction
            let audioData = try extractAudioFromPrediction(prediction)
            
            // Update performance metrics
            let inferenceTime = Date().timeIntervalSince(startTime)
            updatePerformanceMetrics(inferenceTime)
            
            // Cache result if appropriate
            if shouldCacheResult(text: text, config: config) {
                cacheResult(cacheKey: cacheKey, audioData: audioData)
            }
            
            DispatchQueue.main.async {
                completion(.success(audioData))
            }
            
        } catch {
            DispatchQueue.main.async {
                completion(.failure(.synthesisError(error)))
            }
        }
    }
    
    private func prepareModelInput(text: String, config: KittenTTSConfig) throws -> MLFeatureProvider {
        // Tokenize text (simplified - actual implementation would use proper tokenizer)
        let tokens = tokenizeText(text)
        
        // Prepare input features
        var inputFeatures: [String: MLFeatureValue] = [:]
        
        // Text tokens as multi-array
        let tokenArray = try MLMultiArray(shape: [NSNumber(value: tokens.count)], dataType: .int32)
        for (index, token) in tokens.enumerated() {
            tokenArray[index] = NSNumber(value: token)
        }
        inputFeatures["text_tokens"] = MLFeatureValue(multiArray: tokenArray)
        
        // Voice ID
        inputFeatures["voice_id"] = MLFeatureValue(int64: Int64(config.voice.rawValue))
        
        // Speed parameter
        inputFeatures["speed"] = MLFeatureValue(double: Double(config.speed))
        
        // Pitch parameter
        inputFeatures["pitch"] = MLFeatureValue(double: Double(config.pitch))
        
        return try MLDictionaryFeatureProvider(dictionary: inputFeatures)
    }
    
    private func tokenizeText(_ text: String) -> [Int32] {
        // Simplified tokenization - in production this would use proper tokenizer
        // Convert characters to tokens for demo purposes
        return text.compactMap { char in
            Int32(char.asciiValue ?? 0)
        }
    }
    
    private func extractAudioFromPrediction(_ prediction: MLFeatureProvider) throws -> AudioData {
        // Extract audio multi-array from prediction
        guard let audioOutput = prediction.featureValue(for: "audio")?.multiArrayValue else {
            throw KittenTTSError.invalidModelOutput
        }
        
        // Convert MLMultiArray to audio samples
        let audioSamples = convertMultiArrayToFloat32(audioOutput)
        
        // Create audio buffer
        let sampleRate: Double = 22050 // Kitten TTS sample rate
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else {
            throw KittenTTSError.audioBufferCreationFailed
        }
        
        guard let audioBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(audioSamples.count)) else {
            throw KittenTTSError.audioBufferCreationFailed
        }
        
        // Copy samples to buffer
        audioBuffer.frameLength = AVAudioFrameCount(audioSamples.count)
        let channelData = audioBuffer.floatChannelData![0]
        for i in 0..<audioSamples.count {
            channelData[i] = audioSamples[i]
        }
        
        // Convert to Data
        let audioData = try convertBufferToData(audioBuffer)
        let duration = Double(audioSamples.count) / sampleRate
        
        return AudioData(
            data: audioData,
            duration: duration,
            format: format
        )
    }
    
    private func convertMultiArrayToFloat32(_ multiArray: MLMultiArray) -> [Float32] {
        let count = multiArray.count
        var samples: [Float32] = Array(repeating: 0.0, count: count)
        
        let dataPointer = multiArray.dataPointer.bindMemory(to: Float32.self, capacity: count)
        samples.withUnsafeMutableBufferPointer { bufferPointer in
            bufferPointer.baseAddress?.initialize(from: dataPointer, count: count)
        }
        
        return samples
    }
    
    private func convertBufferToData(_ buffer: AVAudioPCMBuffer) throws -> Data {
        guard let channelData = buffer.floatChannelData else {
            throw KittenTTSError.audioBufferConversionFailed
        }
        
        let frameCount = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)
        
        var data = Data()
        
        for frame in 0..<frameCount {
            for channel in 0..<channelCount {
                let sample = channelData[channel][frame]
                withUnsafeBytes(of: sample) { bytes in
                    data.append(contentsOf: bytes)
                }
            }
        }
        
        return data
    }
    
    private func optimizeScriptForDuration(_ script: String, targetDuration: Double) -> String {
        // Estimate words per second (approximately 3 words per second for clear speech)
        let wordsPerSecond: Double = 3.0
        let targetWords = Int(targetDuration * wordsPerSecond)
        
        let words = script.components(separatedBy: .whitespaces)
        if words.count <= targetWords {
            return script
        }
        
        // Truncate to fit target duration
        let truncatedWords = Array(words.prefix(targetWords))
        var result = truncatedWords.joined(separator: " ")
        
        // Ensure proper ending
        if !result.hasSuffix(".") && !result.hasSuffix("!") && !result.hasSuffix("?") {
            result += "."
        }
        
        return result
    }
    
    private func generateCacheKey(text: String, config: KittenTTSConfig) -> String {
        return "\(text.hashValue)_\(config.voice.rawValue)_\(config.speed)_\(config.pitch)"
    }
    
    private func shouldCacheResult(text: String, config: KittenTTSConfig) -> Bool {
        // Cache short, common phrases
        return text.count < 100 && synthesisCache.count < maxCacheSize
    }
    
    private func cacheResult(cacheKey: String, audioData: AudioData) {
        // Implement LRU cache behavior
        if synthesisCache.count >= maxCacheSize {
            // Remove oldest entry (simplified LRU)
            if let oldestKey = synthesisCache.keys.first {
                synthesisCache.removeValue(forKey: oldestKey)
            }
        }
        
        synthesisCache[cacheKey] = audioData
    }
    
    private func updatePerformanceMetrics(_ inferenceTime: TimeInterval) {
        inferenceCount += 1
        averageInferenceTime = (averageInferenceTime * Double(inferenceCount - 1) + inferenceTime) / Double(inferenceCount)
        
        if inferenceTime > 0.5 {
            print("⚠️ Slow Kitten TTS inference: \(inferenceTime * 1000)ms")
        }
    }
}

// MARK: - Supporting Types

enum KittenVoice: Int, CaseIterable {
    case voice0 = 0  // Female, Friendly
    case voice1 = 1  // Female, Professional
    case voice2 = 2  // Female, Warm
    case voice3 = 3  // Female, Energetic
    case voice4 = 4  // Male, Casual
    case voice5 = 5  // Male, Authoritative
    case voice6 = 6  // Male, Calm
    case voice7 = 7  // Male, Enthusiastic
    
    var description: String {
        switch self {
        case .voice0: return "Female Friendly"
        case .voice1: return "Female Professional"
        case .voice2: return "Female Warm"
        case .voice3: return "Female Energetic"
        case .voice4: return "Male Casual"
        case .voice5: return "Male Authoritative"
        case .voice6: return "Male Calm"
        case .voice7: return "Male Enthusiastic"
        }
    }
    
    var gender: VoiceGender {
        return rawValue < 4 ? .female : .male
    }
}

enum VoiceGender {
    case female
    case male
}

enum TTSQuality {
    case fast      // Optimized for speed
    case balanced  // Balance of quality and speed
    case high      // High quality, slower
    case automotive // Optimized for automotive environment
}

struct KittenTTSConfig {
    let voice: KittenVoice
    let speed: Float        // 0.5 - 2.0
    let pitch: Float        // -1.0 - 1.0
    let quality: TTSQuality
    
    init(voice: KittenVoice = .voice0,
         speed: Float = 1.0,
         pitch: Float = 0.0,
         quality: TTSQuality = .balanced) {
        self.voice = voice
        self.speed = max(0.5, min(2.0, speed))
        self.pitch = max(-1.0, min(1.0, pitch))
        self.quality = quality
    }
}

enum KittenTTSError: Error {
    case modelNotFound
    case modelLoadFailed(Error)
    case synthesisError(Error)
    case invalidModelOutput
    case audioBufferCreationFailed
    case audioBufferConversionFailed
    case textTooLong
    case invalidVoiceConfiguration
    
    var localizedDescription: String {
        switch self {
        case .modelNotFound:
            return "Kitten TTS model not found in app bundle"
        case .modelLoadFailed(let error):
            return "Failed to load Kitten TTS model: \(error.localizedDescription)"
        case .synthesisError(let error):
            return "TTS synthesis failed: \(error.localizedDescription)"
        case .invalidModelOutput:
            return "Invalid output from Kitten TTS model"
        case .audioBufferCreationFailed:
            return "Failed to create audio buffer"
        case .audioBufferConversionFailed:
            return "Failed to convert audio buffer to data"
        case .textTooLong:
            return "Input text exceeds maximum length"
        case .invalidVoiceConfiguration:
            return "Invalid voice configuration parameters"
        }
    }
}