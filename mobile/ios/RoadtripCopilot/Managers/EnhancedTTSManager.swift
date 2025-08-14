import Foundation
import AVFoundation
import CoreML
import Speech
import Combine

/// Enhanced TTS Manager with Kitten TTS integration and automotive optimization
class EnhancedTTSManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isSpeaking = false
    @Published var isInitialized = false
    @Published var currentEngine: TTSEngine = .system
    @Published var voicePersonality: VoicePersonality = .friendlyGuide
    @Published var audioQuality: AudioQuality = .automotive
    @Published var performanceMetrics: TTSPerformanceMetrics = TTSPerformanceMetrics()
    
    // MARK: - Core Components
    private let systemSynthesizer = AVSpeechSynthesizer()
    private var kittenTTSProcessor: KittenTTSProcessor?
    private let audioSessionManager = AutomotiveAudioSessionManager()
    private let performanceMonitor = TTSPerformanceMonitor()
    private let podcastGenerator = SixSecondPodcastGenerator()
    
    // MARK: - Configuration
    private let voiceConfiguration = VoiceConfiguration()
    private var currentSession: TTSSession?
    private var audioQueue: [TTSRequest] = []
    private var isProcessingQueue = false
    
    // MARK: - Cancellables
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupTTSSystem()
    }
    
    private func setupTTSSystem() {
        setupSystemSynthesizer()
        initializeKittenTTS()
        configureAudioSession()
        setupPerformanceMonitoring()
        
        DispatchQueue.main.async {
            self.isInitialized = true
        }
    }
    
    private func setupSystemSynthesizer() {
        systemSynthesizer.delegate = self
    }
    
    private func initializeKittenTTS() {
        do {
            kittenTTSProcessor = try KittenTTSProcessor()
            print("✅ Kitten TTS initialized successfully")
        } catch {
            print("⚠️ Kitten TTS initialization failed: \(error)")
            print("🔄 Falling back to system TTS")
        }
    }
    
    private func configureAudioSession() {
        audioSessionManager.setupAutomotiveAudioSession()
    }
    
    private func setupPerformanceMonitoring() {
        performanceMonitor.startMonitoring()
        
        performanceMonitor.metricsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] metrics in
                self?.performanceMetrics = metrics
                self?.adaptToPerformance(metrics)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Interface
    
    /// Synthesize text with optimal engine selection
    func speak(_ text: String, 
               priority: TTSPriority = .normal,
               context: VoiceContext = .general) {
        guard !text.isEmpty else { return }
        
        let request = TTSRequest(
            text: preprocessText(text, for: context),
            priority: priority,
            context: context,
            voicePersonality: voicePersonality,
            requestId: UUID().uuidString,
            timestamp: Date()
        )
        
        addToQueue(request)
    }
    
    /// Generate 6-second podcast for POI discovery  
    func generatePOIAnnouncement(poi: POIData, completion: @escaping (Result<AudioData, TTSError>) -> Void) {
        podcastGenerator.generateSixSecondAudio(for: poi) { [weak self] result in
            switch result {
            case .success(let audioData):
                self?.playAudioData(audioData)
                completion(.success(audioData))
            case .failure(let error):
                completion(.failure(.podcastGenerationFailed(error)))
            }
        }
    }
    
    /// Handle voice command feedback
    func speakVoiceCommandFeedback(for command: VoiceCommand) {
        let feedbackText = generateCommandFeedback(for: command)
        speak(feedbackText, priority: .high, context: .commandFeedback)
    }
    
    /// Stop current speech and clear queue
    func stopSpeaking() {
        systemSynthesizer.stopSpeaking(at: .immediate)
        kittenTTSProcessor?.stopSynthesis()
        clearAudioQueue()
        
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
    
    /// Configure voice personality
    func configureVoice(personality: VoicePersonality) {
        voicePersonality = personality
        voiceConfiguration.updatePersonality(personality)
    }
    
    // MARK: - Private Methods
    
    private func addToQueue(_ request: TTSRequest) {
        if request.priority == .urgent {
            audioQueue.insert(request, at: 0)
        } else {
            audioQueue.append(request)
        }
        
        processQueueIfNeeded()
    }
    
    private func processQueueIfNeeded() {
        guard !isProcessingQueue && !audioQueue.isEmpty else { return }
        
        isProcessingQueue = true
        processNextRequest()
    }
    
    private func processNextRequest() {
        guard let request = audioQueue.first else {
            isProcessingQueue = false
            return
        }
        
        audioQueue.removeFirst()
        
        let startTime = Date()
        let engine = selectOptimalEngine(for: request)
        
        synthesizeWithEngine(request, engine: engine) { [weak self] result in
            let processingTime = Date().timeIntervalSince(startTime)
            
            self?.performanceMonitor.recordSynthesis(
                engine: engine,
                processingTime: processingTime,
                textLength: request.text.count,
                success: result.isSuccess
            )
            
            // Continue processing queue
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self?.processNextRequest()
            }
        }
    }
    
    private func selectOptimalEngine(for request: TTSRequest) -> TTSEngine {
        // Priority 1: Real-time requirements
        if request.priority == .urgent || request.context == .commandFeedback {
            return .system // Fastest response
        }
        
        // Priority 2: Kitten TTS availability and performance
        if let kittenProcessor = kittenTTSProcessor,
           kittenProcessor.isAvailable,
           performanceMetrics.averageLatency < 200 {
            return .kittenTTS
        }
        
        // Priority 3: Context-specific requirements
        switch request.context {
        case .podcastGeneration:
            return kittenTTSProcessor?.isAvailable == true ? .kittenTTS : .system
        case .commandFeedback:
            return .system // Immediate response needed
        case .general, .poiAnnouncement:
            return kittenTTSProcessor?.isAvailable == true ? .kittenTTS : .system
        }
    }
    
    private func synthesizeWithEngine(_ request: TTSRequest, 
                                    engine: TTSEngine,
                                    completion: @escaping (Result<Void, TTSError>) -> Void) {
        currentSession = TTSSession(request: request, engine: engine, startTime: Date())
        
        switch engine {
        case .system:
            synthesizeWithSystem(request, completion: completion)
        case .kittenTTS:
            synthesizeWithKitten(request, completion: completion)
        }
    }
    
    private func synthesizeWithSystem(_ request: TTSRequest, 
                                    completion: @escaping (Result<Void, TTSError>) -> Void) {
        let utterance = createSystemUtterance(from: request)
        
        // Store completion for delegate callback
        systemCompletions[request.requestId] = completion
        
        DispatchQueue.main.async {
            self.isSpeaking = true
            self.currentEngine = .system
        }
        
        systemSynthesizer.speak(utterance)
    }
    
    private func synthesizeWithKitten(_ request: TTSRequest, 
                                    completion: @escaping (Result<Void, TTSError>) -> Void) {
        guard let processor = kittenTTSProcessor else {
            completion(.failure(.engineUnavailable(.kittenTTS)))
            return
        }
        
        DispatchQueue.main.async {
            self.isSpeaking = true
            self.currentEngine = .kittenTTS
        }
        
        let config = KittenTTSConfig(
            voice: voiceConfiguration.getKittenVoice(for: request.voicePersonality),
            speed: voiceConfiguration.getSpeed(for: request.context),
            pitch: voiceConfiguration.getPitch(for: request.voicePersonality),
            quality: .automotive
        )
        
        processor.synthesize(text: request.text, config: config) { [weak self] result in
            switch result {
            case .success(let audioData):
                self?.playAudioData(audioData)
                completion(.success(()))
            case .failure(let error):
                completion(.failure(.synthesisError(error)))
            }
        }
    }
    
    private func createSystemUtterance(from request: TTSRequest) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: request.text)
        
        // Configure voice
        utterance.voice = voiceConfiguration.getSystemVoice(for: request.voicePersonality)
        
        // Configure speech parameters for automotive use
        utterance.rate = voiceConfiguration.getRate(for: request.context)
        utterance.pitchMultiplier = voiceConfiguration.getPitch(for: request.voicePersonality)
        utterance.volume = 1.0
        
        // Automotive-specific timing
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.2
        
        return utterance
    }
    
    private func playAudioData(_ audioData: AudioData) {
        audioSessionManager.playAudioData(audioData) { [weak self] completed in
            DispatchQueue.main.async {
                if completed {
                    self?.isSpeaking = false
                }
            }
        }
    }
    
    private func preprocessText(_ text: String, for context: VoiceContext) -> String {
        var processedText = text
        
        // Automotive-specific preprocessing
        processedText = processedText
            .replacingOccurrences(of: "km/h", with: "kilometers per hour")
            .replacingOccurrences(of: "mph", with: "miles per hour")
            .replacingOccurrences(of: "&", with: "and")
            .replacingOccurrences(of: "GPS", with: "G P S")
            .replacingOccurrences(of: "POI", with: "point of interest")
        
        // Context-specific preprocessing
        switch context {
        case .podcastGeneration:
            processedText = optimizeForPodcast(processedText)
        case .commandFeedback:
            processedText = addCommandConfirmation(processedText)
        case .poiAnnouncement:
            processedText = enhanceForAnnouncement(processedText)
        case .general:
            break
        }
        
        return processedText
    }
    
    private func optimizeForPodcast(_ text: String) -> String {
        // Optimize for 6-second audio duration (approximately 18-20 words)
        let words = text.components(separatedBy: .whitespaces)
        let maxWords = 18
        
        if words.count <= maxWords {
            return text
        }
        
        let truncatedWords = Array(words.prefix(maxWords))
        return truncatedWords.joined(separator: " ") + "."
    }
    
    private func addCommandConfirmation(_ text: String) -> String {
        return text // Command feedback is already optimized
    }
    
    private func enhanceForAnnouncement(_ text: String) -> String {
        // Add natural pauses for POI announcements
        return text.replacingOccurrences(of: ".", with: ", ")
    }
    
    private func generateCommandFeedback(for command: VoiceCommand) -> String {
        switch command {
        case .save:
            return "Saved to favorites"
        case .like:
            return "Liked"
        case .dislike:
            return "Skipped"
        case .next:
            return "Next location"
        case .previous:
            return "Previous location"
        case .navigate:
            return "Getting directions"
        case .call:
            return "Calling location"
        }
    }
    
    private func clearAudioQueue() {
        audioQueue.removeAll()
        isProcessingQueue = false
    }
    
    private func adaptToPerformance(_ metrics: TTSPerformanceMetrics) {
        // Adapt engine selection based on performance
        if metrics.averageLatency > 500 {
            // Switch to system TTS for faster responses
            print("📊 High latency detected, prioritizing system TTS")
        }
        
        if metrics.memoryPressure > 0.8 {
            // Optimize memory usage
            kittenTTSProcessor?.optimizeForMemory()
        }
        
        if metrics.batteryDrain > 4.0 {
            // Reduce battery usage
            voiceConfiguration.enableBatterySaver()
        }
    }
    
    // MARK: - System Speech Completion Tracking
    private var systemCompletions: [String: (Result<Void, TTSError>) -> Void] = [:]
}

// MARK: - AVSpeechSynthesizerDelegate

extension EnhancedTTSManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        // Speech started - already handled in synthesis method
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
        
        // Find and complete the corresponding request
        if let session = currentSession {
            systemCompletions[session.request.requestId]?(.success(()))
            systemCompletions.removeValue(forKey: session.request.requestId)
        }
        
        currentSession = nil
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
        
        if let session = currentSession {
            systemCompletions[session.request.requestId]?(.failure(.cancelled))
            systemCompletions.removeValue(forKey: session.request.requestId)
        }
        
        currentSession = nil
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        // Handle pause if needed
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        // Handle continue if needed
    }
}

// MARK: - Supporting Types

enum TTSEngine {
    case system
    case kittenTTS
}

enum VoicePersonality: CaseIterable {
    case friendlyGuide
    case professionalAssistant
    case casualCompanion
    case enthusiasticExplorer
    
    var displayName: String {
        switch self {
        case .friendlyGuide: return "Friendly Guide"
        case .professionalAssistant: return "Professional Assistant"
        case .casualCompanion: return "Casual Companion"
        case .enthusiasticExplorer: return "Enthusiastic Explorer"
        }
    }
}

enum VoiceContext {
    case general
    case commandFeedback
    case poiAnnouncement
    case podcastGeneration
}

enum TTSPriority {
    case low
    case normal
    case high
    case urgent
}

enum VoiceCommand {
    case save
    case like
    case dislike
    case next
    case previous
    case navigate
    case call
}

enum AudioQuality {
    case automotive
    case standard
    case premium
}

struct TTSRequest {
    let text: String
    let priority: TTSPriority
    let context: VoiceContext
    let voicePersonality: VoicePersonality
    let requestId: String
    let timestamp: Date
}

struct TTSSession {
    let request: TTSRequest
    let engine: TTSEngine
    let startTime: Date
}

struct TTSPerformanceMetrics {
    var averageLatency: TimeInterval = 0
    var memoryPressure: Double = 0
    var batteryDrain: Double = 0
    var successRate: Double = 1.0
    var engineUsage: [TTSEngine: Int] = [:]
}

struct AudioData {
    let data: Data
    let duration: TimeInterval
    let format: AVAudioFormat
}

enum TTSError: Error {
    case engineUnavailable(TTSEngine)
    case synthesisError(Error)
    case podcastGenerationFailed(Error)
    case cancelled
    case audioSessionError(Error)
}

extension Result {
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
}