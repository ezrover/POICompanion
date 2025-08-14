import Foundation
import Speech
import AVFoundation
import Combine
import UIKit

class SpeechManager: NSObject, ObservableObject {
    // Speech Recognition
    private let speechRecognizer = SFSpeechRecognizer()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // Speech Synthesis
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    // CRITICAL FIX: Stabilized Audio Session Management
    private let audioSession = AVAudioSession.sharedInstance()
    private var currentSessionMode: AudioSessionMode = .inactive
    private var isAudioSessionStable = false
    private var pendingModeChange: AudioSessionMode?
    private var audioSessionQueue = DispatchQueue(label: "audio.session.queue", qos: .userInitiated)
    @Published var isCarPlayConnected = false
    
    enum AudioSessionMode {
        case inactive
        case speechRecognition    // For listening
        case speechSynthesis      // For TTS output
        case carPlayAudio        // For CarPlay integration
        case backgroundAudio     // For background operations
    }
    
    // Published properties for UI updates
    @Published var isListening = false
    @Published var isSpeaking = false
    @Published var listeningAnimation = false
    @Published var speakingAnimation = false
    @Published var speakingLevels: [CGFloat] = [10, 15, 20, 15, 10]
    @Published var recognizedText = ""
    @Published var speechAuthorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    
    // Voice activity detection
    @Published var isVoiceDetected = false
    private var voiceActivityTimer: Timer?
    private var silenceTimer: Timer?
    private var audioLevelThreshold: Float = -40.0 // dB threshold for voice detection
    private var silenceTimeoutInterval: TimeInterval = 3.0 // 3 seconds
    
    // Destination mode for bypassing command pattern matching
    @Published var isDestinationMode = false
    private var destinationSilenceTimer: Timer?
    private var accumulatedDestinationText = ""
    
    private var cancellables = Set<AnyCancellable>()
    private var animationTimer: Timer?
    
    override init() {
        super.init()
        print("[SpeechManager] Initializing SpeechManager...")
        
        // CRITICAL FIX: Ultra-minimal safe initialization to prevent crashes
        speechSynthesizer.delegate = self
        print("[SpeechManager] Requesting speech permissions...")
        requestSpeechPermissions()
        
        // CRITICAL FIX: Very minimal audio session setup - no immediate activation
        do {
            try audioSession.setCategory(.ambient, mode: .default, options: [])
            // Don't activate the session immediately - wait until needed
            isAudioSessionStable = true
            currentSessionMode = .inactive
            print("[SpeechManager] Basic audio session category set")
        } catch {
            print("[SpeechManager] Basic audio session setup failed: \(error)")
            isAudioSessionStable = false
            currentSessionMode = .inactive
        }
        
        // CRITICAL FIX: Delay observers longer to prevent initialization conflicts
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.observeCarPlayConnection()
            self.observeAudioRouteChanges()
            print("[SpeechManager] SpeechManager initialization completed")
        }
    }
    
    // MARK: - Setup
    
    private func setupSpeech() {
        print("[SpeechManager] Setting up speech...")
        speechSynthesizer.delegate = self
        print("[SpeechManager] Requesting speech permissions...")
        requestSpeechPermissions()
        print("[SpeechManager] Setting up audio session...")
        setupAudioSession()
        print("[SpeechManager] Speech setup completed")
    }
    
    private func requestSpeechPermissions() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.speechAuthorizationStatus = status
            }
        }
    }
    
    private func setupAudioSession() {
        // CRITICAL FIX: Stabilized initialization with error recovery
        print("[SpeechManager] Setting up audio session for speech processing")
        audioSessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                // Initialize with minimal stable configuration
                try self.audioSession.setCategory(.ambient, mode: .default, options: [])
                self.isAudioSessionStable = true
                print("[SpeechManager] Audio session initialized successfully")
            } catch {
                print("[SpeechManager] Audio session initialization failed: \(error)")
                self.handleAudioSessionError(error)
            }
        }
    }
    
    private func resetAudioSession() {
        // CRITICAL FIX: Reset audio session for echo/feedback prevention
        print("[SpeechManager] Resetting audio session")
        
        do {
            // Deactivate session
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            
            // Brief pause for system cleanup
            Thread.sleep(forTimeInterval: 0.1)
            
            // Reactivate with current mode
            try configureAudioSessionForMode(currentSessionMode)
            
            print("[SpeechManager] Audio session reset successfully")
        } catch {
            print("[SpeechManager] Failed to reset audio session: \(error)")
        }
    }
    
    // MARK: - Speech Recognition
    
    func startListening() {
        // CRITICAL FIX: Stabilized voice recognition startup
        guard speechAuthorizationStatus == .authorized else {
            print("[SpeechManager] Speech recognition not authorized")
            DispatchQueue.main.async {
                self.isListening = false
                self.listeningAnimation = false
            }
            return
        }
        
        // Prevent multiple simultaneous starts
        guard !audioEngine.isRunning else {
            print("[SpeechManager] Audio engine already running - skipping start")
            return
        }
        
        // Ensure audio session is stable before starting
        guard isAudioSessionStable else {
            print("[SpeechManager] Audio session not stable - delaying start")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.startListening()
            }
            return
        }
        
        audioSessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                try self.startSpeechRecognition()
            } catch {
                print("[SpeechManager] Failed to start speech recognition: \(error)")
                self.handleSpeechRecognitionError(error)
            }
        }
    }
    
    private func handleSpeechRecognitionError(_ error: Error) {
        print("[SpeechManager] Handling speech recognition error: \(error)")
        
        let nsError = error as NSError
        
        // CRITICAL FIX: Handle specific error types without unnecessary engine restarts
        if nsError.domain == "kAFAssistantErrorDomain" {
            if nsError.code == 209 {
                // AFAggregator error 209 - common iOS system error, not fatal
                print("[SpeechManager] AFAggregator error 209 - continuing without restart")
                // Don't restart engine, just reset state
                DispatchQueue.main.async {
                    self.isListening = false
                    self.listeningAnimation = false
                }
                return
            }
        }
        
        // For other errors, attempt graceful recovery
        DispatchQueue.main.async {
            self.isListening = false
            self.listeningAnimation = false
            self.stopListening()
        }
        
        // Only restart if absolutely necessary
        if nsError.code == -1100 || nsError.localizedDescription.contains("audio") {
            print("[SpeechManager] Audio-related error - attempting recovery")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if !self.isListening {
                    self.startListening()
                }
            }
        }
    }
    
    func stopListening() {
        print("[SpeechManager] Stopping speech recognition")
        
        // Remove tap first while engine is still running
        let inputNode = audioEngine.inputNode
        if audioEngine.isRunning {
            inputNode.removeTap(onBus: 0)
            audioEngine.stop()
        }
        
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        // Clean up
        recognitionRequest = nil
        recognitionTask = nil
        
        DispatchQueue.main.async {
            self.isListening = false
            self.listeningAnimation = false
            self.isVoiceDetected = false
        }
        
        // Clean up voice activity timers
        silenceTimer?.invalidate()
        silenceTimer = nil
        voiceActivityTimer?.invalidate()
        voiceActivityTimer = nil
        
        stopAnimationTimer()
        
        // CRITICAL FIX: Return to background audio configuration after speech recognition
        configureAudioSessionForMode(.backgroundAudio)
        currentSessionMode = .backgroundAudio
    }
    
    private func startSpeechRecognition() throws {
        // Cancel any existing task and clean up audio engine
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Stop engine and remove any existing taps first
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        
        let inputNode = audioEngine.inputNode
        
        // Remove any existing tap safely - always try to remove if engine was running
        inputNode.removeTap(onBus: 0)
        
        // CRITICAL FIX: Configure audio session BEFORE accessing input node format
        configureAudioSessionForMode(.speechRecognition)
        currentSessionMode = .speechRecognition
        
        // Brief delay to allow audio session to stabilize
        Thread.sleep(forTimeInterval: 0.1)
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechError.recognitionRequestFailed
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Create recognition task with enhanced error handling
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            var isFinal = false
            
            if let result = result {
                DispatchQueue.main.async {
                    self?.recognizedText = result.bestTranscription.formattedString
                }
                isFinal = result.isFinal
            }
            
            // CRITICAL FIX: Enhanced AFAggregator error handling without engine disruption
            if let error = error {
                let nsError = error as NSError
                if nsError.domain == "kAFAssistantErrorDomain" {
                    switch nsError.code {
                    case 209:
                        // AFAggregator error 209 - common system error, continue gracefully
                        print("[SpeechManager] AFAggregator error 209 - continuing without disruption")
                        // Don't stop processing, this is not a fatal error
                        break
                        
                    case 203, 216:
                        // Temporary dictation service issues - wait and continue
                        print("[SpeechManager] Temporary dictation service error \(nsError.code)")
                        break
                        
                    default:
                        print("[SpeechManager] AFAssistant error \(nsError.code): \(error.localizedDescription)")
                        // Only stop processing for truly fatal errors
                        if nsError.code < 200 { // System-level errors
                            DispatchQueue.main.async {
                                self?.handleSpeechRecognitionError(error)
                            }
                            return
                        }
                    }
                } else {
                    print("[SpeechManager] Speech recognition error: \(error.localizedDescription)")
                    // Handle non-AF errors normally
                    if !error.localizedDescription.contains("cancelled") {
                        DispatchQueue.main.async {
                            self?.handleSpeechRecognitionError(error)
                        }
                        return
                    }
                }
            }
            
            if error != nil || isFinal {
                // Stop audio engine safely and remove tap
                if let strongSelf = self {
                    let inputNode = strongSelf.audioEngine.inputNode
                    
                    // Remove tap first while engine is still running, then stop engine
                    if strongSelf.audioEngine.isRunning {
                        inputNode.removeTap(onBus: 0)
                        strongSelf.audioEngine.stop()
                    }
                }
                
                self?.recognitionRequest = nil
                self?.recognitionTask = nil
                
                DispatchQueue.main.async {
                    self?.isListening = false
                    self?.listeningAnimation = false
                }
                
                self?.stopAnimationTimer()
                
                // Process the recognized text based on mode
                if let text = self?.recognizedText, !text.isEmpty {
                    if self?.isDestinationMode == true {
                        print("[SpeechManager] Processing in destination mode: '\(text)'")
                        self?.handleDestinationModeResult(text)
                    } else {
                        print("[SpeechManager] Processing in command mode: '\(text)'")
                        self?.processVoiceCommand(text)
                    }
                }
            }
        }
        
        // CRITICAL FIX: Safe native hardware format handling to prevent crashes
        // The tap format MUST match the input node's hardware format exactly
        let nativeInputFormat = inputNode.inputFormat(forBus: 0)
        
        // Validate format before proceeding
        guard nativeInputFormat.sampleRate > 0 && nativeInputFormat.channelCount > 0 else {
            print("[SpeechManager] Invalid input format - aborting")
            throw SpeechError.audioEngineNotAvailable
        }
        
        print("[SpeechManager] Using native hardware format: \(nativeInputFormat)")
        print("[SpeechManager] Native format details:")
        print("  - Sample Rate: \(nativeInputFormat.sampleRate) Hz")
        print("  - Channel Count: \(nativeInputFormat.channelCount)")
        print("  - Bit Depth: \(nativeInputFormat.commonFormat.rawValue)")
        print("  - Interleaved: \(nativeInputFormat.isInterleaved)")
        
        do {
            // CRITICAL FIX: Install tap with comprehensive error handling
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: nativeInputFormat) { [weak self] buffer, _ in
                guard let self = self, let request = self.recognitionRequest else {
                    return // Safely ignore if objects are deallocated
                }
                
                // Send buffer for speech recognition
                request.append(buffer)
                
                // Analyze audio level for voice activity detection  
                self.analyzeAudioLevel(buffer: buffer)
                
                // Handle destination mode partial results
                if self.isDestinationMode {
                    DispatchQueue.main.async {
                        self.resetDestinationSilenceTimer()
                    }
                }
            }
        } catch {
            print("[SpeechManager] Failed to install tap with native format: \(error)")
            print("[SpeechManager] Error details: \(error.localizedDescription)")
            // Clean up before throwing
            self.recognitionRequest = nil
            self.recognitionTask = nil
            throw SpeechError.audioEngineNotAvailable
        }
        
        // CRITICAL FIX: Safe audio engine startup with fallback handling
        do {
            audioEngine.prepare()
            try audioEngine.start()
            print("[SpeechManager] Audio engine started successfully")
        } catch {
            print("[SpeechManager] Audio engine failed to start: \(error)")
            
            // Clean up safely
            if audioEngine.inputNode.numberOfInputs > 0 {
                inputNode.removeTap(onBus: 0)
            }
            self.recognitionRequest = nil
            self.recognitionTask = nil
            
            // Don't attempt recovery immediately - could cause more crashes
            DispatchQueue.main.async {
                self.isListening = false
                self.listeningAnimation = false
            }
            
            throw SpeechError.audioEngineNotAvailable
        }
        
        DispatchQueue.main.async {
            self.isListening = true
            // Don't start animation immediately - wait for voice detection
            self.listeningAnimation = false
            self.isVoiceDetected = false
            self.recognizedText = ""
        }
        
        // Don't start animation timer immediately - wait for voice activity
    }
    
    private func processVoiceCommand(_ command: String) {
        let lowercaseCommand = command.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("[SpeechManager] Processing voice command: '\(command)' (Destination mode: \(isDestinationMode))")
        
        // CRITICAL FIX: In destination mode, skip command pattern matching entirely
        // This prevents "stop" from being processed as exit command when user says destination names
        if isDestinationMode {
            print("[SpeechManager] In destination mode - treating as destination name, not command")
            // This should not happen as destination mode results go through handleDestinationModeResult
            // But add safety check to prevent command processing in destination mode
            NotificationCenter.default.post(
                name: .voiceCommandReceived,
                object: command
            )
            return
        }
        
        // Define command patterns and their actions
        let commandActions: [(pattern: String, action: String, alternatives: [String])] = [
            ("save", "save", ["favorite", "bookmark", "remember"]),
            ("like", "like", ["love", "good", "great", "awesome"]),
            ("dislike", "dislike", ["skip", "bad", "not interested", "pass", "hate"]),
            ("next", "next", ["forward", "continue", "move on"]),
            ("previous", "previous", ["last one", "before"]), // CRITICAL FIX: Remove "back" from previous to prevent conflicts
            ("navigate", "navigate", ["directions", "go to", "take me to", "drive to", "start", "begin", "go"]),
            ("call", "call", ["phone", "contact", "dial"]),
            ("mute", "mute", ["silence", "quiet", "turn off mic"]),
            ("unmute", "unmute", ["activate mic", "turn on mic", "enable mic"]),
            ("back", "back", ["go back", "return"]), // CRITICAL FIX: Dedicated back command
            ("exit", "exit", ["close", "stop"])
        ]
        
        // Find matching command
        for commandAction in commandActions {
            let allPatterns = [commandAction.pattern] + commandAction.alternatives
            
            for pattern in allPatterns {
                if lowercaseCommand.contains(pattern) {
                    print("[SpeechManager] Matched command pattern '\(pattern)' for action '\(commandAction.action)'")
                    executeVoiceCommand(commandAction.action, originalText: command)
                    return
                }
            }
        }
        
        // If no specific command found, post for general processing
        print("[SpeechManager] No specific command pattern matched, posting for general processing")
        NotificationCenter.default.post(
            name: .voiceCommandReceived,
            object: command
        )
    }
    
    private func executeVoiceCommand(_ action: String, originalText: String) {
        print("Executing voice command action: \(action)")
        
        // If app is in background, bring it to foreground first
        DispatchQueue.main.async {
            if UIApplication.shared.applicationState == .background {
                // Post notification to bring app to foreground
                NotificationCenter.default.post(
                    name: .bringAppToForeground,
                    object: nil
                )
                print("App was in background - bringing to foreground for voice command: \(action)")
            }
        }
        
        // Animate the corresponding button
        NotificationCenter.default.post(
            name: .voiceCommandButtonAnimation,
            object: action
        )
        
        // Execute the actual command after a brief delay to show animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            NotificationCenter.default.post(
                name: .voiceCommandAction,
                object: ["action": action, "originalText": originalText]
            )
        }
        
        // Provide audio feedback
        let feedbackMessages: [String: String] = [
            "save": "Saving to favorites",
            "like": "Liked",
            "dislike": "Skipped",
            "next": "Next location",
            "previous": "Previous location",
            "navigate": "Getting directions",
            "call": "Calling location",
            "mute": "Microphone muted",
            "unmute": "Microphone active",
            "back": "Going back", // CRITICAL FIX: Add back command feedback
            "exit": "Exiting"
        ]
        
        if let feedback = feedbackMessages[action] {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.speak(feedback)
            }
        }
    }
    
    // MARK: - Speech Synthesis
    
    func speak(_ text: String) {
        guard !text.isEmpty else { return }
        
        // CRITICAL FIX: Configure audio session for clear TTS output
        configureAudioSessionForMode(.speechSynthesis)
        currentSessionMode = .speechSynthesis
        
        let utterance = AVSpeechUtterance(string: text)
        
        // Enhanced voice configuration for clarity
        if let voice = AVSpeechSynthesisVoice(language: "en-US") {
            utterance.voice = voice
        } else {
            // Fallback to system default
            utterance.voice = AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
        }
        
        // CRITICAL FIX: Enhanced speech parameters to eliminate echo and improve clarity
        utterance.rate = isCarPlayConnected ? 
            AVSpeechUtteranceDefaultSpeechRate * 0.85 :  // Slower for CarPlay to reduce echo
            AVSpeechUtteranceDefaultSpeechRate * 0.9     // Slightly slower for device clarity
        
        utterance.pitchMultiplier = 1.0
        
        // Volume adjustment based on audio route to prevent feedback
        utterance.volume = isCarPlayConnected ? 0.7 : 0.8  // Lower volume for CarPlay to prevent echo
        
        // Enhanced timing for automotive use - allow audio routing to stabilize
        utterance.preUtteranceDelay = isCarPlayConnected ? 0.3 : 0.2   // Longer delay for CarPlay
        utterance.postUtteranceDelay = 0.1
        
        DispatchQueue.main.async {
            self.isSpeaking = true
            self.speakingAnimation = true
        }
        
        startSpeakingAnimation()
        
        print("[SpeechManager] Speaking: \(text)")
        print("[SpeechManager] Audio route: \(getCurrentAudioRoute())")
        
        speechSynthesizer.speak(utterance)
    }
    
    func stopSpeaking() {
        speechSynthesizer.stopSpeaking(at: .immediate)
        
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.speakingAnimation = false
        }
        
        stopAnimationTimer()
    }
    
    // MARK: - Animations
    
    private func startAnimationTimer() {
        stopAnimationTimer()
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateAnimations()
        }
    }
    
    private func stopAnimationTimer() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    private func updateAnimations() {
        if isListening {
            DispatchQueue.main.async {
                self.listeningAnimation.toggle()
            }
        }
        
        if isSpeaking {
            updateSpeakingLevels()
        }
    }
    
    private func startSpeakingAnimation() {
        startAnimationTimer()
    }
    
    private func updateSpeakingLevels() {
        DispatchQueue.main.async {
            self.speakingLevels = self.speakingLevels.map { _ in
                CGFloat.random(in: 8...25)
            }
            self.speakingAnimation.toggle()
        }
    }
    
    // MARK: - Voice Activity Detection
    
    private func analyzeAudioLevel(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return }
        
        // Calculate RMS (Root Mean Square) for audio level
        var rmsValue: Float = 0
        for i in 0..<frameLength {
            let sample = channelData[i]
            rmsValue += sample * sample
        }
        rmsValue = sqrt(rmsValue / Float(frameLength))
        
        // Convert to decibels
        let dbLevel = 20 * log10(rmsValue)
        
        // Check if voice is detected (above threshold and not silent)
        let voiceDetected = dbLevel > audioLevelThreshold && !dbLevel.isInfinite
        
        DispatchQueue.main.async {
            self.handleVoiceActivity(detected: voiceDetected)
        }
    }
    
    private func handleVoiceActivity(detected: Bool) {
        if detected {
            // Voice detected - start animation if not already running
            if !isVoiceDetected {
                isVoiceDetected = true
                listeningAnimation = true
                startAnimationTimer()
                print("Voice activity detected - starting animation")
            }
            
            // Reset appropriate silence timer based on mode
            if isDestinationMode {
                resetDestinationSilenceTimer()
            } else {
                // Reset regular silence timer
                silenceTimer?.invalidate()
                silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceTimeoutInterval, repeats: false) { [weak self] _ in
                    self?.handleSilenceTimeout()
                }
            }
        }
        // If no voice detected, the silence timer will handle stopping
    }
    
    private func handleSilenceTimeout() {
        DispatchQueue.main.async {
            if self.isVoiceDetected {
                self.isVoiceDetected = false
                self.listeningAnimation = false
                self.stopAnimationTimer()
                print("Voice activity stopped after 3 seconds of silence")
            }
        }
    }
    
    // MARK: - CarPlay Integration
    
    func handleCarPlayVoiceCommand() {
        if isListening {
            stopListening()
        } else {
            startListening()
        }
    }
    
    func speakPOIAnnouncement(_ text: String) {
        // Format text for 6-second audio format
        let formattedText = formatFor6SecondAudio(text)
        speak(formattedText)
    }
    
    private func formatFor6SecondAudio(_ text: String) -> String {
        // Limit to approximately 6 seconds of speech (roughly 15-20 words)
        let words = text.components(separatedBy: .whitespaces)
        let maxWords = 18
        
        if words.count <= maxWords {
            return text
        }
        
        let truncatedWords = Array(words.prefix(maxWords))
        return truncatedWords.joined(separator: " ") + "..."
    }
    
    // MARK: - Destination + Action Parsing
    
    struct DestinationActionResult {
        let destination: String
        let action: String?
    }
    
    private func parseDestinationAndAction(_ text: String) -> DestinationActionResult {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercaseText = trimmedText.lowercased()
        
        print("[SpeechManager] Parsing text: '\(trimmedText)'")
        
        // Action keywords that trigger automatic navigation
        let actionKeywords = ["start", "go", "discover", "view", "navigate", "explore", "show", "begin"]
        let navigationPhrases = ["navigate to", "go to", "drive to", "take me to", "start trip to", "begin trip to"]
        
        // Check for navigation phrases first (higher priority)
        for phrase in navigationPhrases {
            if let range = lowercaseText.range(of: phrase) {
                let destination = String(trimmedText[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !destination.isEmpty {
                    print("[SpeechManager] Found navigation phrase '\(phrase)' with destination '\(destination)'")
                    return DestinationActionResult(destination: destination, action: "navigate")
                }
            }
        }
        
        // Check for action at the beginning (single word)
        for keyword in actionKeywords {
            if lowercaseText.hasPrefix("\(keyword) ") {
                let destination = String(trimmedText.dropFirst(keyword.count + 1)).trimmingCharacters(in: .whitespacesAndNewlines)
                if !destination.isEmpty {
                    print("[SpeechManager] Found action keyword '\(keyword)' at beginning with destination '\(destination)'")
                    return DestinationActionResult(destination: destination, action: "navigate")
                }
            }
        }
        
        // Check for standalone navigation commands (when destination already selected)
        let standaloneCommands = ["go", "let's go", "start", "navigate", "begin", "start trip", "take me there", "drive"]
        for command in standaloneCommands {
            if lowercaseText == command || lowercaseText == command.replacingOccurrences(of: " ", with: "") {
                print("[SpeechManager] Found standalone navigation command '\(command)'")
                return DestinationActionResult(destination: trimmedText, action: "navigate")
            }
        }
        
        // Check for action at the end (with comma or without)
        for keyword in actionKeywords {
            // Pattern: "destination, action" or "destination action"
            let patterns = [", \(keyword)", " \(keyword)"]
            
            for pattern in patterns {
                if lowercaseText.hasSuffix(pattern) {
                    let destination = String(trimmedText.dropLast(pattern.count)).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !destination.isEmpty {
                        print("[SpeechManager] Found action keyword '\(keyword)' at end with destination '\(destination)'")
                        return DestinationActionResult(destination: destination, action: "navigate")
                    }
                }
            }
            
            // Pattern: "destination,action" (no space after comma)
            if lowercaseText.hasSuffix(",\(keyword)") {
                let destination = String(trimmedText.dropLast(keyword.count + 1)).trimmingCharacters(in: .whitespacesAndNewlines)
                if !destination.isEmpty {
                    print("[SpeechManager] Found action keyword '\(keyword)' at end (no space) with destination '\(destination)'")
                    return DestinationActionResult(destination: destination, action: "navigate")
                }
            }
        }
        
        // No action keyword found - just return destination
        print("[SpeechManager] No action keyword found, treating as destination only: '\(trimmedText)'")
        return DestinationActionResult(destination: trimmedText, action: nil)
    }
    
    // MARK: - Destination Mode Methods
    
    func enableDestinationMode() {
        isDestinationMode = true
        accumulatedDestinationText = ""
        // Clear any previous recognition text
        recognizedText = ""
        print("[SpeechManager] Destination mode enabled - will accept raw destination names")
    }
    
    private func postDestinationSelected(_ destination: String, hasAction: Bool, action: String) {
        let userInfo: [String: Any] = [
            "destination": destination,
            "hasAction": hasAction,
            "action": action
        ]
        
        print("[SpeechManager] Posting destinationSelected notification with userInfo: \(userInfo)")
        
        NotificationCenter.default.post(
            name: .destinationSelected,
            object: destination,
            userInfo: userInfo
        )
    }
    
    func disableDestinationMode() {
        isDestinationMode = false
        accumulatedDestinationText = ""
        destinationSilenceTimer?.invalidate()
        destinationSilenceTimer = nil
        print("[SpeechManager] Destination mode disabled")
    }
    
    private func handleDestinationModeResult(_ text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedText.isEmpty else {
            print("[SpeechManager] Empty destination mode result, ignoring")
            return
        }
        
        print("[SpeechManager] Destination mode result: '\(trimmedText)'")
        
        // Parse destination and action
        let result = parseDestinationAndAction(trimmedText)
        print("[SpeechManager] Parsed destination: '\(result.destination)', action: '\(result.action ?? "none")'")
        
        // Validate we have a destination
        guard !result.destination.isEmpty else {
            print("[SpeechManager] No valid destination extracted, ignoring")
            return
        }
        
        // Post notification for destination selection with action info
        postDestinationSelected(result.destination, hasAction: result.action != nil, action: result.action ?? "")
        
        // CRITICAL FIX: Only disable destination mode if navigation action was detected
        if result.action != nil {
            print("[SpeechManager] Navigation action detected - disabling destination mode")
            disableDestinationMode()
        } else {
            print("[SpeechManager] Destination-only input - keeping destination mode active for more input")
            // Keep destination mode active and restart listening for navigation commands
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if self.isDestinationMode && !self.isListening {
                    print("[SpeechManager] Restarting listening in destination mode for navigation commands")
                    self.startListening()
                }
            }
        }
    }
    
    private func resetDestinationSilenceTimer() {
        destinationSilenceTimer?.invalidate()
        destinationSilenceTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            self?.handleDestinationSilenceTimeout()
        }
    }
    
    private func handleDestinationSilenceTimeout() {
        if isDestinationMode && !recognizedText.isEmpty {
            print("Destination silence timeout - using recognized text: \(recognizedText)")
            handleDestinationModeResult(recognizedText)
        } else if isDestinationMode {
            print("[SpeechManager] Destination mode timeout with empty text - restarting listening")
            // Restart listening if we're in destination mode but got no text
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if self.isDestinationMode {
                    self.startListening()
                }
            }
        }
    }
    
    // MARK: - Audio Session Management
    
    private func configureAudioSessionForMode(_ mode: AudioSessionMode) {
        // CRITICAL FIX: Prevent unnecessary audio session changes and rate limiting
        guard mode != currentSessionMode || !isAudioSessionStable else {
            print("[SpeechManager] Audio session already configured for \(mode) - skipping")
            return
        }
        
        // Rate limit audio session changes to prevent conflicts
        if let pending = pendingModeChange {
            print("[SpeechManager] Audio session change already pending (\(pending)) - queuing \(mode)")
            pendingModeChange = mode
            return
        }
        
        pendingModeChange = mode
        
        audioSessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            defer {
                self.pendingModeChange = nil
            }
            
            print("[SpeechManager] Configuring audio session for mode: \(mode)")
            
            do {
                switch mode {
                case .inactive:
                    // CRITICAL FIX: Minimal inactive configuration
                    try self.audioSession.setCategory(.ambient, mode: .default, options: [])
                    
                    // Only deactivate if we were previously active
                    if self.currentSessionMode != .inactive && self.isAudioSessionStable {
                        try self.audioSession.setActive(false, options: .notifyOthersOnDeactivation)
                        Thread.sleep(forTimeInterval: 0.1) // Brief stabilization pause
                    }
                
                case .speechRecognition:
                    // CRITICAL FIX: Simplified speech recognition configuration to prevent conflicts
                    try self.audioSession.setCategory(.playAndRecord, 
                                                     mode: .voiceChat,
                                                     options: [.allowBluetooth, .defaultToSpeaker])
                    
                    // CRITICAL: Activate session only when needed
                    try self.audioSession.setActive(true, options: [])
                    Thread.sleep(forTimeInterval: 0.05) // Shorter stabilization time
                
                case .speechSynthesis:
                    // CRITICAL FIX: Ultra-simplified TTS configuration to prevent conflicts
                    try self.audioSession.setCategory(.playback,
                                                     mode: .spokenAudio,
                                                     options: [.defaultToSpeaker])
                    try self.audioSession.setActive(true, options: [])
                    Thread.sleep(forTimeInterval: 0.05) // Shorter stabilization
                
                case .carPlayAudio:
                    // CRITICAL FIX: Simplified CarPlay audio configuration
                    try self.audioSession.setCategory(.playback,
                                                     mode: .spokenAudio,
                                                     options: [.allowBluetooth, .allowBluetoothA2DP, .duckOthers])
                    try self.audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                    Thread.sleep(forTimeInterval: 0.1)
                    
                case .backgroundAudio:
                    // CRITICAL FIX: Minimal background audio configuration
                    try self.audioSession.setCategory(.playback,
                                                     mode: .default,
                                                     options: [.mixWithOthers, .allowBluetooth])
                    try self.audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                }
                
                self.currentSessionMode = mode
                self.isAudioSessionStable = true
                print("[SpeechManager] Successfully configured audio session for mode: \(mode)")
                
            } catch {
                print("[SpeechManager] Failed to configure audio session for mode \(mode): \(error)")
                self.handleAudioSessionError(error)
            }
        }
    }
    
    /// Handle audio session errors with intelligent recovery
    private func handleAudioSessionError(_ error: Error) {
        print("[SpeechManager] Audio session error: \(error)")
        
        isAudioSessionStable = false
        
        // Attempt recovery after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.audioSessionQueue.async {
                do {
                    // Try minimal safe configuration
                    try self.audioSession.setCategory(.ambient, mode: .default, options: [])
                    self.isAudioSessionStable = true
                    self.currentSessionMode = .inactive
                    print("[SpeechManager] Audio session recovered")
                } catch {
                    print("[SpeechManager] Audio session recovery failed: \(error)")
                    // Mark as unstable but don't crash
                    DispatchQueue.main.async {
                        self.isListening = false
                        self.listeningAnimation = false
                    }
                }
            }
        }
    }
    
    private func observeCarPlayConnection() {
        // CRITICAL FIX: Safe CarPlay observer setup
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.observeCarPlayConnection()
            }
            return
        }
        
        // Listen for CarPlay connection status
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(carPlayDidConnect),
            name: .carPlayConnected,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(carPlayDidConnect),
            name: .carPlayAlreadyConnected,
            object: nil
        )
    }
    
    @objc private func carPlayDidConnect() {
        print("[SpeechManager] CarPlay connected - updating audio configuration")
        
        DispatchQueue.main.async { [weak self] in
            self?.isCarPlayConnected = true
            
            // Reconfigure audio session for CarPlay if currently active
            if self?.currentSessionMode != .inactive {
                self?.configureAudioSessionForMode(.carPlayAudio)
                self?.currentSessionMode = .carPlayAudio
            }
        }
    }
    
    private func observeAudioRouteChanges() {
        // CRITICAL FIX: Safe audio route observer setup
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.observeAudioRouteChanges()
            }
            return
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }
    
    @objc private func handleAudioRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        print("[SpeechManager] Audio route changed: \(reason) - \(getCurrentAudioRoute())")
        
        // CRITICAL FIX: Enhanced CarPlay detection and audio routing optimization
        let currentRoute = audioSession.currentRoute
        let outputs = currentRoute.outputs.map { $0.portType.rawValue }
        let _ = currentRoute.inputs.map { $0.portType.rawValue }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let wasCarPlayConnected = self.isCarPlayConnected
            
            // Enhanced CarPlay detection including wired and wireless connections
            let isNowCarPlayConnected = outputs.contains("CarAudio") || 
                                      outputs.contains("BluetoothA2DP") ||
                                      currentRoute.outputs.contains(where: { $0.portName.lowercased().contains("carplay") })
            
            if wasCarPlayConnected != isNowCarPlayConnected {
                print("[SpeechManager] CarPlay connection state changed: \(wasCarPlayConnected) -> \(isNowCarPlayConnected)")
                self.isCarPlayConnected = isNowCarPlayConnected
                
                // Handle specific route change reasons for optimal audio switching
                switch reason {
                case .newDeviceAvailable, .routeConfigurationChange:
                    // CarPlay just connected - optimize immediately
                    if isNowCarPlayConnected && self.currentSessionMode != .inactive {
                        print("[SpeechManager] CarPlay connected - switching to CarPlay audio mode")
                        self.configureAudioSessionForMode(.carPlayAudio)
                        self.currentSessionMode = .carPlayAudio
                    }
                    
                case .oldDeviceUnavailable:
                    // CarPlay disconnected - switch back to device audio
                    if !isNowCarPlayConnected && self.currentSessionMode == .carPlayAudio {
                        print("[SpeechManager] CarPlay disconnected - switching to device audio")
                        self.configureAudioSessionForMode(.speechSynthesis)
                        self.currentSessionMode = .speechSynthesis
                    }
                    
                default:
                    // General route change - reconfigure current mode appropriately
                    if self.currentSessionMode != .inactive {
                        let targetMode: AudioSessionMode = isNowCarPlayConnected ? .carPlayAudio : self.currentSessionMode
                        self.configureAudioSessionForMode(targetMode)
                    }
                }
                
                // Stop any ongoing speech to prevent echo during route changes
                if self.isSpeaking && reason != .routeConfigurationChange {
                    print("[SpeechManager] Stopping speech due to audio route change")
                    self.speechSynthesizer.stopSpeaking(at: .immediate)
                }
            }
        }
    }
    
    private func getCurrentAudioRoute() -> String {
        let currentRoute = audioSession.currentRoute
        let outputs = currentRoute.outputs.map { "\($0.portType.rawValue): \($0.portName)" }
        return outputs.joined(separator: ", ")
    }
    
    
    // CRITICAL FIX: Audio engine startup recovery with native format approach
    private func recoverAudioEngineStartup() throws {
        print("[SpeechManager] Attempting audio engine recovery...")
        
        // Reset audio session completely
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            Thread.sleep(forTimeInterval: 0.2)
            
            // Reconfigure with minimal settings
            try audioSession.setCategory(.record, mode: .default, options: [])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            Thread.sleep(forTimeInterval: 0.1)
            
            // Try starting engine again with fresh input node
            let inputNode = audioEngine.inputNode
            let nativeFormat = inputNode.inputFormat(forBus: 0)
            print("[SpeechManager] Recovery using native format: \(nativeFormat)")
            
            audioEngine.prepare()
            try audioEngine.start()
            print("[SpeechManager] Audio engine recovery successful")
        } catch {
            print("[SpeechManager] Audio engine recovery failed: \(error)")
            throw SpeechError.audioEngineNotAvailable
        }
    }
    
    private func printCurrentAudioConfiguration() {
        print("=== Audio Session Configuration ===")
        print("Category: \(audioSession.category)")
        print("Mode: \(audioSession.mode)")
        print("Options: \(audioSession.categoryOptions)")
        print("Current Route: \(getCurrentAudioRoute())")
        print("CarPlay Connected: \(isCarPlayConnected)")
        print("Current Session Mode: \(currentSessionMode)")
        print("===================================")
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension SpeechManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = true
            self.speakingAnimation = true
        }
        
        print("[SpeechManager] TTS started: \(utterance.speechString)")
        printCurrentAudioConfiguration()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.speakingAnimation = false
        }
        
        stopAnimationTimer()
        
        print("[SpeechManager] TTS finished: \(utterance.speechString)")
        
        // CRITICAL FIX: Return to background audio configuration after speech
        configureAudioSessionForMode(.backgroundAudio)
        currentSessionMode = .backgroundAudio
        
        // Notify completion
        NotificationCenter.default.post(name: .speechDidFinish, object: utterance.speechString)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.speakingAnimation = false
        }
        
        stopAnimationTimer()
        
        print("[SpeechManager] TTS cancelled: \(utterance.speechString)")
        
        // CRITICAL FIX: Return to background audio configuration after cancellation
        configureAudioSessionForMode(.backgroundAudio)
        currentSessionMode = .backgroundAudio
    }
}

// MARK: - Error Types

enum SpeechError: Error {
    case recognitionRequestFailed
    case audioEngineNotAvailable
    case speechRecognitionNotAvailable
}

// MARK: - Notification Names

extension Notification.Name {
    static let voiceCommandReceived = Notification.Name("voiceCommandReceived")
    static let voiceCommandAction = Notification.Name("voiceCommandAction")
    static let voiceCommandButtonAnimation = Notification.Name("voiceCommandButtonAnimation")
    static let speechDidFinish = Notification.Name("speechDidFinish")
    static let bringAppToForeground = Notification.Name("bringAppToForeground")
    static let destinationSelected = Notification.Name("destinationSelected")
    
    // CarPlay notification names are defined in CarPlaySceneDelegate
}