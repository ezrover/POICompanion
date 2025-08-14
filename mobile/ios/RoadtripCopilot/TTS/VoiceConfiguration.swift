import Foundation
import AVFoundation

/// Voice configuration manager for personality-based TTS settings
class VoiceConfiguration {
    
    // MARK: - Configuration State
    private var currentPersonality: VoicePersonality = .friendlyGuide
    private var batterySaverEnabled = false
    private var automotiveOptimized = true
    
    // MARK: - Voice Mappings
    private let systemVoiceMapping: [VoicePersonality: String] = [
        .friendlyGuide: "com.apple.ttsbundle.Samantha-compact",
        .professionalAssistant: "com.apple.ttsbundle.Alex-compact", 
        .casualCompanion: "com.apple.ttsbundle.Karen-compact",
        .enthusiasticExplorer: "com.apple.ttsbundle.Victoria-compact"
    ]
    
    private let kittenVoiceMapping: [VoicePersonality: KittenVoice] = [
        .friendlyGuide: .voice0,        // Female Friendly
        .professionalAssistant: .voice1, // Female Professional  
        .casualCompanion: .voice4,       // Male Casual
        .enthusiasticExplorer: .voice3   // Female Energetic
    ]
    
    // MARK: - Speech Parameters
    private let baseRates: [VoiceContext: Float] = [
        .general: 0.5,
        .commandFeedback: 0.6,      // Slightly faster for quick confirmation
        .poiAnnouncement: 0.45,     // Slower for clear delivery
        .podcastGeneration: 0.4     // Slowest for podcast quality
    ]
    
    private let pitchMultipliers: [VoicePersonality: Float] = [
        .friendlyGuide: 1.0,
        .professionalAssistant: 0.95,   // Slightly lower
        .casualCompanion: 1.05,         // Slightly higher
        .enthusiasticExplorer: 1.1      // Higher for enthusiasm
    ]
    
    // MARK: - Public Interface
    
    func updatePersonality(_ personality: VoicePersonality) {
        currentPersonality = personality
        print("🎭 Voice personality updated to: \(personality.displayName)")
    }
    
    func enableBatterySaver() {
        batterySaverEnabled = true
        print("🔋 Battery saver mode enabled for voice synthesis")
    }
    
    func disableBatterySaver() {
        batterySaverEnabled = false
        print("🔋 Battery saver mode disabled")
    }
    
    func enableAutomotiveMode() {
        automotiveOptimized = true
        print("🚗 Automotive audio optimization enabled")
    }
    
    // MARK: - System Voice Configuration
    
    func getSystemVoice(for personality: VoicePersonality) -> AVSpeechSynthesisVoice? {
        let voiceIdentifier = systemVoiceMapping[personality] ?? systemVoiceMapping[.friendlyGuide]!
        
        // Try to get the specific voice, fallback to default
        if let voice = AVSpeechSynthesisVoice(identifier: voiceIdentifier) {
            return voice
        }
        
        // Fallback to default system voice
        return AVSpeechSynthesisVoice(language: "en-US")
    }
    
    func getRate(for context: VoiceContext) -> Float {
        var baseRate = baseRates[context] ?? baseRates[.general]!
        
        // Apply battery saver adjustments
        if batterySaverEnabled {
            baseRate *= 1.1 // Slightly faster to save battery
        }
        
        // Apply automotive optimizations
        if automotiveOptimized {
            baseRate = optimizeRateForAutomotive(baseRate, context: context)
        }
        
        return AVSpeechUtteranceDefaultSpeechRate * baseRate
    }
    
    func getPitch(for personality: VoicePersonality) -> Float {
        let basePitch = pitchMultipliers[personality] ?? pitchMultipliers[.friendlyGuide]!
        
        // Apply automotive optimizations (slightly lower pitch for road noise)
        if automotiveOptimized {
            return basePitch * 0.95
        }
        
        return basePitch
    }
    
    // MARK: - Kitten TTS Configuration
    
    func getKittenVoice(for personality: VoicePersonality) -> KittenVoice {
        return kittenVoiceMapping[personality] ?? kittenVoiceMapping[.friendlyGuide]!
    }
    
    func getSpeed(for context: VoiceContext) -> Float {
        var speed: Float = 1.0
        
        switch context {
        case .general:
            speed = 1.0
        case .commandFeedback:
            speed = 1.2  // Faster for quick responses
        case .poiAnnouncement:
            speed = 0.9  // Slower for clarity
        case .podcastGeneration:
            speed = 0.85 // Slowest for podcast quality
        }
        
        // Apply battery saver
        if batterySaverEnabled {
            speed *= 1.15
        }
        
        // Apply automotive optimization
        if automotiveOptimized {
            speed = optimizeSpeedForAutomotive(speed, context: context)
        }
        
        return max(0.5, min(2.0, speed))
    }
    
    func getKittenPitch(for personality: VoicePersonality) -> Float {
        let basePitch: Float
        
        switch personality {
        case .friendlyGuide:
            basePitch = 0.0
        case .professionalAssistant:
            basePitch = -0.1
        case .casualCompanion:
            basePitch = 0.1
        case .enthusiasticExplorer:
            basePitch = 0.2
        }
        
        // Automotive optimization (compensate for road noise)
        if automotiveOptimized {
            return basePitch + 0.05
        }
        
        return max(-1.0, min(1.0, basePitch))
    }
    
    // MARK: - Automotive Optimizations
    
    private func optimizeRateForAutomotive(_ rate: Float, context: VoiceContext) -> Float {
        // Adjust rate based on context for automotive environment
        switch context {
        case .commandFeedback:
            return rate * 1.1 // Quick confirmations
        case .poiAnnouncement:
            return rate * 0.9 // Clear announcements over road noise
        case .podcastGeneration:
            return rate * 0.85 // High quality for content
        case .general:
            return rate
        }
    }
    
    private func optimizeSpeedForAutomotive(_ speed: Float, context: VoiceContext) -> Float {
        // Similar optimization for Kitten TTS speed parameter
        switch context {
        case .commandFeedback:
            return speed * 1.1
        case .poiAnnouncement:
            return speed * 0.95 // Slightly slower for road noise compensation
        case .podcastGeneration:
            return speed * 0.9  // Optimal for content creation
        case .general:
            return speed
        }
    }
    
    // MARK: - Dynamic Adjustments
    
    func adjustForNoisyEnvironment() {
        // Could be triggered by noise level detection
        print("🔊 Adjusting voice configuration for noisy environment")
        // Implementation would modify rates/pitch for better clarity
    }
    
    func adjustForQuietEnvironment() {
        print("🔇 Adjusting voice configuration for quiet environment")
        // Implementation would optimize for normal listening conditions
    }
    
    // MARK: - Voice Testing
    
    func getTestPhrase(for personality: VoicePersonality) -> String {
        switch personality {
        case .friendlyGuide:
            return "Hi there! I'm your friendly guide, ready to help you discover amazing places along your journey."
        case .professionalAssistant:
            return "Good day. I am your professional assistant, providing efficient navigation and discovery services."
        case .casualCompanion:
            return "Hey! I'm your casual travel companion, here to make your road trip more interesting and fun."
        case .enthusiasticExplorer:
            return "Wow! I'm so excited to explore with you and discover incredible hidden gems on your adventure!"
        }
    }
}

// MARK: - Automotive Audio Session Manager

class AutomotiveAudioSessionManager {
    
    private let audioSession = AVAudioSession.sharedInstance()
    private var isCarPlayActive = false
    private var isBluetoothConnected = false
    
    // MARK: - Setup
    
    func setupAutomotiveAudioSession() {
        configureAudioSession()
        observeAudioRouteChanges()
        detectCarPlayConnection()
    }
    
    private func configureAudioSession() {
        do {
            // Configure for automotive use with priority on speech clarity
            try audioSession.setCategory(.playAndRecord,
                                       mode: .voiceChat,  // Optimized for speech
                                       options: [.allowBluetooth, 
                                               .allowBluetoothA2DP,
                                               .defaultToSpeaker,
                                               .duckOthers,
                                               .interruptSpokenAudioAndMixWithOthers])
            
            try audioSession.setActive(true)
            
            print("✅ Automotive audio session configured successfully")
            
        } catch {
            print("❌ Failed to configure automotive audio session: \(error)")
        }
    }
    
    private func observeAudioRouteChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }
    
    private func detectCarPlayConnection() {
        // Check if CarPlay is currently active
        let currentRoute = audioSession.currentRoute
        isCarPlayActive = currentRoute.outputs.contains { output in
            output.portType == .carAudio
        }
        
        isBluetoothConnected = currentRoute.outputs.contains { output in
            output.portType == .bluetoothA2DP || output.portType == .bluetoothLE
        }
        
        if isCarPlayActive {
            print("🚗 CarPlay audio detected")
            optimizeForCarPlay()
        } else if isBluetoothConnected {
            print("🔵 Bluetooth audio detected")
            optimizeForBluetooth()
        }
    }
    
    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        switch reason {
        case .newDeviceAvailable:
            detectCarPlayConnection()
            print("🔄 New audio device available")
        case .oldDeviceUnavailable:
            detectCarPlayConnection()
            print("🔄 Audio device disconnected")
        default:
            break
        }
    }
    
    // MARK: - Audio Playback
    
    func playAudioData(_ audioData: AudioData, completion: @escaping (Bool) -> Void) {
        // Create audio player for the synthesized audio
        guard let audioBuffer = createAudioBuffer(from: audioData) else {
            completion(false)
            return
        }
        
        let audioEngine = AVAudioEngine()
        let playerNode = AVAudioPlayerNode()
        
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: audioData.format)
        
        do {
            try audioEngine.start()
            
            // Play with completion callback
            playerNode.scheduleBuffer(audioBuffer, at: nil, options: []) {
                DispatchQueue.main.async {
                    audioEngine.stop()
                    completion(true)
                }
            }
            
            playerNode.play()
            
        } catch {
            print("❌ Failed to play audio data: \(error)")
            completion(false)
        }
    }
    
    private func createAudioBuffer(from audioData: AudioData) -> AVAudioPCMBuffer? {
        let frameCount = UInt32(audioData.data.count / MemoryLayout<Float32>.size)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioData.format, frameCapacity: frameCount) else {
            return nil
        }
        
        buffer.frameLength = frameCount
        
        audioData.data.withUnsafeBytes { bytes in
            let floatPointer = bytes.bindMemory(to: Float32.self)
            let channelData = buffer.floatChannelData![0]
            
            for i in 0..<Int(frameCount) {
                channelData[i] = floatPointer[i]
            }
        }
        
        return buffer
    }
    
    // MARK: - Platform-Specific Optimizations
    
    private func optimizeForCarPlay() {
        // DISABLED: Audio session configuration handled by main SpeechManager
        // try audioSession.setPreferredIOBufferDuration(0.02) // 20ms for low latency
        // try audioSession.setPreferredSampleRate(44100)      // Standard CarPlay sample rate
        
        print("🚗 Audio optimization deferred to main SpeechManager")
    }
    
    private func optimizeForBluetooth() {
        // DISABLED: Audio session configuration handled by main SpeechManager
        // try audioSession.setPreferredIOBufferDuration(0.04) // 40ms for Bluetooth stability
        // try audioSession.setPreferredSampleRate(44100)
        
        print("🔵 Audio optimization deferred to main SpeechManager")
    }
    
    private func optimizeForSpeaker() {
        // DISABLED: Audio session configuration handled by main SpeechManager
        // try audioSession.setPreferredIOBufferDuration(0.01) // 10ms for minimal latency
        // try audioSession.setPreferredSampleRate(48000)      // Higher quality for direct playback
        
        print("🔊 Audio optimization deferred to main SpeechManager")
    }
    
    // MARK: - Audio Environment Detection
    
    func getCurrentAudioEnvironment() -> AudioEnvironment {
        let currentRoute = audioSession.currentRoute
        
        if currentRoute.outputs.contains(where: { $0.portType == .carAudio }) {
            return .carPlay
        } else if currentRoute.outputs.contains(where: { $0.portType == .bluetoothA2DP || $0.portType == .bluetoothLE }) {
            return .bluetooth
        } else if currentRoute.outputs.contains(where: { $0.portType == .builtInSpeaker }) {
            return .speaker
        } else if currentRoute.outputs.contains(where: { $0.portType == .headphones || $0.portType == .bluetoothHFP }) {
            return .headphones
        } else {
            return .unknown
        }
    }
}

// MARK: - Supporting Types

enum AudioEnvironment {
    case carPlay
    case bluetooth
    case speaker
    case headphones
    case unknown
    
    var displayName: String {
        switch self {
        case .carPlay: return "CarPlay"
        case .bluetooth: return "Bluetooth"
        case .speaker: return "Device Speaker"
        case .headphones: return "Headphones"
        case .unknown: return "Unknown"
        }
    }
    
    var requiresOptimization: Bool {
        switch self {
        case .carPlay, .bluetooth: return true
        case .speaker, .headphones, .unknown: return false
        }
    }
}