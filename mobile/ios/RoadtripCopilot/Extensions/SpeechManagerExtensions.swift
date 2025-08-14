import Foundation
import AVFoundation
import UIKit

// MARK: - Enhanced Speech Manager Extensions for Voice Visualizer

extension SpeechManager {
    
    // MARK: - Real-time Audio Level Monitoring
    
    /// Get current microphone input level for visualizer
    var currentInputLevel: Float {
        // Real audio level monitoring will be implemented when SpeechManager exposes audioEngine
        // For now, we'll simulate based on listening state
        if isListening {
            return Float.random(in: 0.2...0.9)
        }
        return 0.0
    }
    
    /// Get current speech output level for visualizer
    var currentOutputLevel: Float {
        if isSpeaking {
            // Simulate speech levels based on current utterance
            return Float.random(in: 0.3...1.0)
        }
        return 0.0
    }
    
    // MARK: - Audio Analysis for Waveform
    
    /// Generate waveform data for visualization
    func generateWaveformData(sampleCount: Int = 64) -> [Float] {
        var waveformData = [Float]()
        let currentTime = Date().timeIntervalSince1970
        
        for i in 0..<sampleCount {
            let frequency = 5.0 + Double(i) * 0.1
            let amplitude: Float
            
            if isListening {
                // Listening waveform - more responsive, higher frequency
                amplitude = Float(0.2 + 0.6 * abs(sin(currentTime * 8 + Double(i) * 0.3)))
            } else if isSpeaking {
                // Speaking waveform - speech-like pattern
                let speechPattern = sin(currentTime * frequency) * 0.5 + 0.5
                amplitude = Float(0.3 + speechPattern * 0.7)
            } else {
                // Idle waveform - minimal activity
                amplitude = Float(0.1 + 0.2 * abs(sin(currentTime * 2 + Double(i) * 0.1)))
            }
            
            waveformData.append(amplitude)
        }
        
        return waveformData
    }
    
    // MARK: - Voice Command Integration
    
    /// Handle voice visualizer tap interaction
    func handleVisualizerTap() {
        if isListening {
            stopListening()
        } else if isSpeaking {
            stopSpeaking()
        } else {
            startListening()
        }
    }
    
    /// Check if the visualizer should be active
    var shouldShowVisualizer: Bool {
        return isListening || isSpeaking
    }
    
    // MARK: - CarPlay Integration
    
    /// Enhanced CarPlay voice interaction with visualizer feedback
    func handleCarPlayVoiceInteraction() {
        if isListening {
            stopListening()
        } else {
            // Provide haptic feedback if available
            provideHapticFeedback()
            startListening()
        }
    }
    
    private func provideHapticFeedback() {
        #if os(iOS)
        if #available(iOS 13.0, *) {
            let impactFeedback = UIImpactFeedbackGenerator(style: UIImpactFeedbackGenerator.FeedbackStyle.medium)
            impactFeedback.impactOccurred()
        }
        #endif
    }
    
    // MARK: - Voice Recognition Enhancement
    
    /// Start listening with enhanced visualizer integration
    func startListeningWithVisualizer() {
        startListening()
        
        // Post notification for visualizer activation
        NotificationCenter.default.post(
            name: .voiceVisualizerShouldActivate,
            object: nil,
            userInfo: ["mode": "listening"]
        )
    }
    
    /// Start speaking with enhanced visualizer integration
    func speakWithVisualizer(_ text: String) {
        speak(text)
        
        // Post notification for visualizer activation
        NotificationCenter.default.post(
            name: .voiceVisualizerShouldActivate,
            object: nil,
            userInfo: ["mode": "speaking", "text": text]
        )
    }
    
    // MARK: - Audio Session Management for Visualizer
    
    /// Configure audio session for optimal visualizer performance
    func configureAudioSessionForVisualizer() {
        // DISABLED: This conflicts with main SpeechManager audio session configuration
        // The main SpeechManager will handle all audio session configuration
        print("Audio session configuration deferred to main SpeechManager")
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let voiceVisualizerShouldActivate = Notification.Name("voiceVisualizerShouldActivate")
    static let voiceVisualizerShouldDeactivate = Notification.Name("voiceVisualizerShouldDeactivate")
    static let voiceVisualizerAudioLevelUpdate = Notification.Name("voiceVisualizerAudioLevelUpdate")
}

// MARK: - Audio Level Monitoring (Real Implementation)

class AudioLevelMonitor: ObservableObject {
    @Published var inputLevel: Float = 0.0
    @Published var outputLevel: Float = 0.0
    
    private var displayLink: CADisplayLink?
    private var audioEngine: AVAudioEngine?
    
    init() {
        setupAudioEngine()
        startMonitoring()
    }
    
    private func setupAudioEngine() {
        // DISABLED: This conflicts with main SpeechManager audio engine
        // Audio level monitoring will be handled by main SpeechManager
        print("Audio engine setup deferred to main SpeechManager")
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        let frameCount = Int(buffer.frameLength)
        var sum: Float = 0.0
        
        for i in 0..<frameCount {
            sum += abs(channelData[i])
        }
        
        let averageLevel = sum / Float(frameCount)
        inputLevel = min(averageLevel * 50, 1.0) // Scale and clamp
    }
    
    private func startMonitoring() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateLevels))
        displayLink?.add(to: .main, forMode: .default)
    }
    
    @objc private func updateLevels() {
        // Update levels - this would be connected to actual audio monitoring
        // For demo purposes, we'll use the current values
    }
    
    func stopMonitoring() {
        displayLink?.invalidate()
        displayLink = nil
        audioEngine?.stop()
    }
}