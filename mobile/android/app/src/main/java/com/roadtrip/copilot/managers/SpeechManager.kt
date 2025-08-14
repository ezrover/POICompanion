package com.roadtrip.copilot.managers

import android.Manifest
import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioManager
import android.media.AudioFocusRequest
import android.os.Build
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import androidx.core.content.ContextCompat
import androidx.lifecycle.ViewModel
// import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.*
// import javax.inject.Inject

// @HiltViewModel
class SpeechManager /* @Inject constructor() */ : ViewModel() {
    private val _isListening = MutableStateFlow(false)
    val isListening: StateFlow<Boolean> = _isListening.asStateFlow()
    
    private val _isSpeaking = MutableStateFlow(false)
    val isSpeaking: StateFlow<Boolean> = _isSpeaking.asStateFlow()
    
    private val _recognizedText = MutableStateFlow("")
    val recognizedText: StateFlow<String> = _recognizedText.asStateFlow()
    
    // Voice activity detection
    private val _isVoiceDetected = MutableStateFlow(false)
    val isVoiceDetected: StateFlow<Boolean> = _isVoiceDetected.asStateFlow()
    
    // Mute state management for platform parity
    private val _isMuted = MutableStateFlow(false)
    val isMuted: StateFlow<Boolean> = _isMuted.asStateFlow()
    
    private var speechRecognizer: SpeechRecognizer? = null
    private var textToSpeech: TextToSpeech? = null
    private var context: Context? = null
    private var audioManager: AudioManager? = null
    private var audioFocusRequest: AudioFocusRequest? = null
    private var hasAudioFocus = false
    
    // Audio session state to prevent restarts
    private var isAudioSessionActive = false
    
    // Destination mode for bypassing command pattern matching
    private val _isDestinationMode = MutableStateFlow(false)
    val isDestinationMode: StateFlow<Boolean> = _isDestinationMode.asStateFlow()
    
    // Voice activity timers
    private var silenceHandler: android.os.Handler? = null
    private var silenceRunnable: Runnable? = null
    private val silenceTimeoutMs = 3000L // 3 seconds
    
    // Destination mode silence detection
    private var destinationSilenceHandler: android.os.Handler? = null
    private var destinationSilenceRunnable: Runnable? = null
    private val destinationSilenceTimeoutMs = 3000L // 3 seconds
    private var accumulatedDestinationText = ""
    
    fun initialize(context: Context) {
        this.context = context
        setupAudioManager(context)
        setupSpeechRecognizer(context)
        setupTextToSpeech(context)
        
        // Initialize voice activity handler
        silenceHandler = android.os.Handler(android.os.Looper.getMainLooper())
    }
    
    private fun setupAudioManager(context: Context) {
        audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                .setAudioAttributes(
                    android.media.AudioAttributes.Builder()
                        .setUsage(android.media.AudioAttributes.USAGE_ASSISTANT)
                        .setContentType(android.media.AudioAttributes.CONTENT_TYPE_SPEECH)
                        .build()
                )
                .setOnAudioFocusChangeListener { focusChange ->
                    handleAudioFocusChange(focusChange)
                }
                .build()
        }
    }
    
    private fun handleAudioFocusChange(focusChange: Int) {
        when (focusChange) {
            AudioManager.AUDIOFOCUS_GAIN -> {
                hasAudioFocus = true
                println("Audio focus gained - resuming voice operations")
            }
            AudioManager.AUDIOFOCUS_LOSS, 
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                hasAudioFocus = false
                if (_isListening.value) {
                    println("Audio focus lost - stopping voice recognition")
                    stopListening()
                }
                if (_isSpeaking.value) {
                    println("Audio focus lost - stopping speech synthesis")
                    stopSpeaking()
                }
            }
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                // Continue but at lower volume - handled by system
                println("Audio focus loss transient - ducking audio")
            }
        }
    }
    
    private fun requestAudioFocus(): Boolean {
        audioManager?.let { am ->
            val result = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                audioFocusRequest?.let { am.requestAudioFocus(it) } ?: AudioManager.AUDIOFOCUS_REQUEST_FAILED
            } else {
                @Suppress("DEPRECATION")
                am.requestAudioFocus(
                    { focusChange -> handleAudioFocusChange(focusChange) },
                    AudioManager.STREAM_VOICE_CALL,
                    AudioManager.AUDIOFOCUS_GAIN_TRANSIENT
                )
            }
            
            hasAudioFocus = result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
            return hasAudioFocus
        }
        return false
    }
    
    private fun releaseAudioFocus() {
        if (hasAudioFocus) {
            audioManager?.let { am ->
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    audioFocusRequest?.let { am.abandonAudioFocusRequest(it) }
                } else {
                    @Suppress("DEPRECATION")
                    am.abandonAudioFocus { focusChange -> handleAudioFocusChange(focusChange) }
                }
            }
            hasAudioFocus = false
        }
    }
    
    private fun setupSpeechRecognizer(context: Context) {
        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(context)
        speechRecognizer?.setRecognitionListener(object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) {
                _isListening.value = true
            }
            
            override fun onBeginningOfSpeech() {}
            
            override fun onRmsChanged(rmsdB: Float) {
                // Voice activity detection based on RMS level
                // Typically, silence is around -40dB or lower
                val voiceDetected = rmsdB > -40f && rmsdB.isFinite()
                handleVoiceActivity(voiceDetected)
            }
            
            override fun onBufferReceived(buffer: ByteArray?) {}
            
            override fun onEndOfSpeech() {
                _isListening.value = false
                isAudioSessionActive = false
                resetVoiceActivity()
            }
            
            override fun onError(error: Int) {
                _isListening.value = false
                resetVoiceActivity()
                
                val errorMessage = when (error) {
                    SpeechRecognizer.ERROR_AUDIO -> "Audio recording error"
                    SpeechRecognizer.ERROR_CLIENT -> "Client side error"
                    SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Insufficient permissions"
                    SpeechRecognizer.ERROR_NETWORK -> "Network error"
                    SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "Network timeout"
                    SpeechRecognizer.ERROR_NO_MATCH -> "No speech match found"
                    SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "Recognition service busy"
                    SpeechRecognizer.ERROR_SERVER -> "Server error"
                    SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "No speech input"
                    else -> "Unknown error ($error)"
                }
                println("Speech recognition error: $errorMessage")
                
                // Only auto-restart for recoverable errors and if we have audio focus
                val recoverableErrors = setOf(
                    SpeechRecognizer.ERROR_NO_MATCH,
                    SpeechRecognizer.ERROR_SPEECH_TIMEOUT,
                    SpeechRecognizer.ERROR_NETWORK_TIMEOUT
                )
                
                if (error in recoverableErrors && hasAudioFocus && !isAudioSessionActive) {
                    android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                        if (!_isListening.value && hasAudioFocus) {
                            println("Auto-restarting speech recognition after recoverable error")
                            startListening()
                        }
                    }, 1500) // 1.5 second delay (matching iOS)
                }
            }
            
            override fun onResults(results: Bundle?) {
                _isListening.value = false
                val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                if (!matches.isNullOrEmpty()) {
                    val recognizedText = matches[0]
                    _recognizedText.value = recognizedText
                    
                    if (_isDestinationMode.value) {
                        handleDestinationModeResult(recognizedText)
                    } else {
                        processVoiceCommand(recognizedText)
                    }
                }
                
                // Auto-restart speech recognition for continuous listening (except in destination mode)
                if (!_isDestinationMode.value && hasAudioFocus) {
                    android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                        if (!_isListening.value && hasAudioFocus && !isAudioSessionActive) {
                            startListening()
                        }
                    }, 1000) // 1 second delay before restarting
                }
            }
            
            override fun onPartialResults(partialResults: Bundle?) {
                val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                if (!matches.isNullOrEmpty()) {
                    val partialText = matches[0]
                    _recognizedText.value = partialText
                    
                    if (_isDestinationMode.value) {
                        accumulatedDestinationText = partialText
                        resetDestinationSilenceTimer()
                    }
                }
            }
            
            override fun onEvent(eventType: Int, params: Bundle?) {}
        })
    }
    
    private fun setupTextToSpeech(context: Context) {
        textToSpeech = TextToSpeech(context) { status ->
            if (status == TextToSpeech.SUCCESS) {
                textToSpeech?.language = Locale.US
                println("TextToSpeech initialized successfully")
            } else {
                println("TextToSpeech initialization failed")
            }
        }
    }
    
    fun startListening() {
        context?.let { ctx ->
            // CRITICAL: Check microphone permission before starting
            if (ContextCompat.checkSelfPermission(
                ctx,
                Manifest.permission.RECORD_AUDIO
            ) != PackageManager.PERMISSION_GRANTED) {
                println("ERROR: Microphone permission not granted - cannot start listening")
                return
            }
            
            if (!_isListening.value && !isAudioSessionActive) {
                // Request audio focus first
                if (!requestAudioFocus()) {
                    println("Failed to gain audio focus - cannot start listening")
                    return
                }
                
                isAudioSessionActive = true
                
                val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                    putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                    putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.getDefault())
                    putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
                    putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
                    putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, 3000L)
                    putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS, 3000L)
                }
                
                try {
                    speechRecognizer?.startListening(intent)
                    _recognizedText.value = ""
                    println("Started speech recognition with audio focus")
                } catch (e: Exception) {
                    println("Failed to start listening: ${e.message}")
                    isAudioSessionActive = false
                    releaseAudioFocus()
                }
            }
        }
    }
    
    fun stopListening() {
        speechRecognizer?.stopListening()
        _isListening.value = false
        isAudioSessionActive = false
        resetVoiceActivity()
        println("Stopped speech recognition")
    }
    
    fun speak(text: String) {
        textToSpeech?.let { tts ->
            if (!text.isEmpty()) {
                _isSpeaking.value = true
                
                tts.setOnUtteranceProgressListener(object : android.speech.tts.UtteranceProgressListener() {
                    override fun onStart(utteranceId: String?) {
                        _isSpeaking.value = true
                    }
                    
                    override fun onDone(utteranceId: String?) {
                        _isSpeaking.value = false
                        
                        // Notify completion (matching iOS implementation)
                        context?.let { ctx ->
                            val intent = android.content.Intent(SPEECH_DID_FINISH)
                            intent.putExtra("utteranceId", utteranceId)
                            androidx.localbroadcastmanager.content.LocalBroadcastManager.getInstance(ctx).sendBroadcast(intent)
                        }
                    }
                    
                    override fun onError(utteranceId: String?) {
                        _isSpeaking.value = false
                    }
                })
                
                val params = Bundle()
                params.putString(TextToSpeech.Engine.KEY_PARAM_UTTERANCE_ID, "roadtrip_utterance")
                
                tts.speak(text, TextToSpeech.QUEUE_FLUSH, params, "roadtrip_utterance")
                println("Speaking: $text")
            }
        }
    }
    
    fun stopSpeaking() {
        textToSpeech?.stop()
        _isSpeaking.value = false
    }
    
    private fun processVoiceCommand(command: String) {
        val lowercaseCommand = command.lowercase().trim()
        
        println("Processing voice command: $command")
        
        // Define command patterns and their actions
        val commandActions = listOf(
            Triple("save", "save", listOf("favorite", "bookmark", "remember")),
            Triple("like", "like", listOf("love", "good", "great", "awesome")),
            Triple("dislike", "dislike", listOf("skip", "bad", "not interested", "pass", "hate")),
            Triple("next", "next", listOf("forward", "continue", "move on")),
            Triple("previous", "previous", listOf("back", "go back", "last one", "before")),
            Triple("navigate", "navigate", listOf("directions", "go to", "take me to", "drive to")),
            Triple("call", "call", listOf("phone", "contact", "dial")),
            Triple("exit", "exit", listOf("close", "back", "return", "stop"))
        )
        
        // Find matching command
        for ((pattern, action, alternatives) in commandActions) {
            val allPatterns = listOf(pattern) + alternatives
            
            for (searchPattern in allPatterns) {
                if (lowercaseCommand.contains(searchPattern)) {
                    executeVoiceCommand(action, command)
                    return
                }
            }
        }
        
        // If no specific command found, broadcast for general processing
        context?.let { ctx ->
            val intent = android.content.Intent(VOICE_COMMAND_RECEIVED)
            intent.putExtra("command", command)
            androidx.localbroadcastmanager.content.LocalBroadcastManager.getInstance(ctx).sendBroadcast(intent)
        }
        
        println("Voice command received: $command")
    }
    
    private fun executeVoiceCommand(action: String, originalText: String) {
        println("Executing voice command action: $action")
        
        // If app is in background, bring it to foreground first
        context?.let { ctx ->
            val activityManager = ctx.getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
            val runningTasks = activityManager.getRunningTasks(1)
            val topActivity = runningTasks[0].topActivity
            
            if (topActivity?.packageName != ctx.packageName) {
                // App is in background - bring to foreground
                val intent = ctx.packageManager.getLaunchIntentForPackage(ctx.packageName)
                intent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                ctx.startActivity(intent)
                println("App was in background - bringing to foreground for voice command: $action")
            }
        }
        
        // TODO: Implement Android-specific notification system for button animation
        // For now, we'll use a simplified approach
        notifyButtonAnimation(action)
        
        // Execute the actual command after a brief delay to show animation
        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
            notifyCommandAction(action, originalText)
        }, 200)
        
        // Provide audio feedback
        val feedbackMessages = mapOf(
            "save" to "Saving to favorites",
            "like" to "Liked",
            "dislike" to "Skipped",
            "next" to "Next location",
            "previous" to "Previous location",
            "navigate" to "Getting directions",
            "call" to "Calling location",
            "exit" to "Returning to destination selection"
        )
        
        feedbackMessages[action]?.let { feedback ->
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                speak(feedback)
            }, 300)
        }
    }
    
    private fun notifyButtonAnimation(action: String) {
        context?.let { ctx ->
            val intent = android.content.Intent(VOICE_COMMAND_BUTTON_ANIMATION)
            intent.putExtra("action", action)
            androidx.localbroadcastmanager.content.LocalBroadcastManager.getInstance(ctx).sendBroadcast(intent)
        }
        println("Button animation requested for: $action")
    }
    
    private fun notifyCommandAction(action: String, originalText: String) {
        context?.let { ctx ->
            val intent = android.content.Intent(VOICE_COMMAND_ACTION)
            intent.putExtra("action", action)
            intent.putExtra("originalText", originalText)
            androidx.localbroadcastmanager.content.LocalBroadcastManager.getInstance(ctx).sendBroadcast(intent)
        }
        println("Command action requested: $action")
    }
    
    // CarPlay Integration methods for parity
    fun handleAndroidAutoVoiceCommand() {
        if (isListening.value) {
            stopListening()
        } else {
            startListening()
        }
    }
    
    fun speakPOIAnnouncement(text: String) {
        // Format text for 6-second audio format (matching iOS implementation)
        val formattedText = formatFor6SecondAudio(text)
        speak(formattedText)
    }
    
    private fun formatFor6SecondAudio(text: String): String {
        // Limit to approximately 6 seconds of speech (roughly 15-20 words)
        val words = text.split(" ")
        val maxWords = 18
        
        return if (words.size <= maxWords) {
            text
        } else {
            words.take(maxWords).joinToString(" ") + "..."
        }
    }
    
    companion object {
        const val VOICE_COMMAND_RECEIVED = "com.roadtrip.copilot.VOICE_COMMAND_RECEIVED"
        const val VOICE_COMMAND_ACTION = "com.roadtrip.copilot.VOICE_COMMAND_ACTION"
        const val VOICE_COMMAND_BUTTON_ANIMATION = "com.roadtrip.copilot.VOICE_COMMAND_BUTTON_ANIMATION"
        const val SPEECH_DID_FINISH = "com.roadtrip.copilot.SPEECH_DID_FINISH"
        const val BRING_APP_TO_FOREGROUND = "com.roadtrip.copilot.BRING_APP_TO_FOREGROUND"
        const val DESTINATION_SELECTED = "com.roadtrip.copilot.DESTINATION_SELECTED"
        const val DESTINATION_ACTION_SELECTED = "com.roadtrip.copilot.DESTINATION_ACTION_SELECTED"
    }
    
    // Voice activity detection methods
    private fun handleVoiceActivity(detected: Boolean) {
        if (detected) {
            // Voice detected - start animation if not already running
            if (!_isVoiceDetected.value) {
                _isVoiceDetected.value = true
                println("Voice activity detected - starting animation")
            }
            
            // Reset appropriate silence timer based on mode
            if (_isDestinationMode.value) {
                resetDestinationSilenceTimer()
            } else {
                // Reset regular silence timer
                silenceRunnable?.let { silenceHandler?.removeCallbacks(it) }
                silenceRunnable = Runnable {
                    handleSilenceTimeout()
                }
                silenceHandler?.postDelayed(silenceRunnable!!, silenceTimeoutMs)
            }
        }
        // If no voice detected, the silence timer will handle stopping
    }
    
    private fun handleSilenceTimeout() {
        _isVoiceDetected.value = false
        println("Voice activity stopped after 3 seconds of silence")
    }
    
    private fun resetVoiceActivity() {
        _isVoiceDetected.value = false
        silenceRunnable?.let { silenceHandler?.removeCallbacks(it) }
        silenceRunnable = null
    }
    
    // MARK: - Destination + Action Parsing
    
    data class DestinationActionResult(
        val destination: String,
        val action: String?
    )
    
    private fun parseDestinationAndAction(text: String): DestinationActionResult {
        val trimmedText = text.trim()
        val lowercaseText = trimmedText.lowercase()
        
        println("Parsing text: '$trimmedText'")
        
        // Action keywords that trigger automatic navigation (matching iOS)
        val actionKeywords = listOf("start", "go", "discover", "view", "navigate", "explore", "show", "begin")
        val navigationPhrases = listOf("navigate to", "go to", "drive to", "take me to", "start trip to", "begin trip to", "let's go to")
        
        // Check for navigation phrases first (higher priority - matching iOS)
        for (phrase in navigationPhrases) {
            val phraseIndex = lowercaseText.indexOf(phrase)
            if (phraseIndex >= 0) {
                val destination = trimmedText.substring(phraseIndex + phrase.length).trim()
                if (destination.isNotEmpty()) {
                    println("Found navigation phrase '$phrase' with destination '$destination'")
                    return DestinationActionResult(destination, "navigate")
                }
            }
        }
        
        // Check for action at the beginning (single word - matching iOS)
        for (keyword in actionKeywords) {
            if (lowercaseText.startsWith("$keyword ")) {
                val destination = trimmedText.substring(keyword.length + 1).trim()
                if (destination.isNotEmpty()) {
                    println("Found action keyword '$keyword' at beginning with destination '$destination'")
                    return DestinationActionResult(destination, "navigate")
                }
            }
        }
        
        // Check for action at the end (with comma or without - matching iOS)
        for (keyword in actionKeywords) {
            // Pattern: "destination, action" or "destination action"
            val patterns = listOf(", $keyword", " $keyword")
            
            for (pattern in patterns) {
                if (lowercaseText.endsWith(pattern)) {
                    val destination = trimmedText.substring(0, trimmedText.length - pattern.length).trim()
                    if (destination.isNotEmpty()) {
                        println("Found action keyword '$keyword' at end with destination '$destination'")
                        return DestinationActionResult(destination, "navigate")
                    }
                }
            }
            
            // Pattern: "destination,action" (no space after comma)
            if (lowercaseText.endsWith(",$keyword")) {
                val destination = trimmedText.substring(0, trimmedText.length - keyword.length - 1).trim()
                if (destination.isNotEmpty()) {
                    println("Found action keyword '$keyword' with comma at end with destination '$destination'")
                    return DestinationActionResult(destination, "navigate")
                }
            }
        }
        
        // No action keyword found - just return destination (matching iOS)
        println("No action keyword found - destination only: '$trimmedText'")
        return DestinationActionResult(trimmedText, null)
    }
    
    // MARK: - Destination Mode Methods
    
    fun enableDestinationMode() {
        _isDestinationMode.value = true
        accumulatedDestinationText = ""
        println("Destination mode enabled - will accept raw destination names")
    }
    
    fun disableDestinationMode() {
        _isDestinationMode.value = false
        accumulatedDestinationText = ""
        destinationSilenceRunnable?.let { destinationSilenceHandler?.removeCallbacks(it) }
        destinationSilenceRunnable = null
        println("Destination mode disabled")
    }
    
    private fun handleDestinationModeResult(text: String) {
        if (text.isNotBlank()) {
            println("Destination mode result: $text")
            
            // Parse destination and action
            val result = parseDestinationAndAction(text)
            println("Parsed destination: '${result.destination}', action: '${result.action}'")
            
            // Broadcast destination selected with action info
            context?.let { ctx ->
                val intent = android.content.Intent(DESTINATION_SELECTED)
                intent.putExtra("destination", result.destination)
                intent.putExtra("hasAction", result.action != null)
                intent.putExtra("action", result.action)
                androidx.localbroadcastmanager.content.LocalBroadcastManager.getInstance(ctx).sendBroadcast(intent)
            }
            
            // CRITICAL FIX: Only disable destination mode if navigation action was detected
            if (result.action != null) {
                println("Navigation action detected - disabling destination mode")
                disableDestinationMode()
            } else {
                println("Destination-only input - keeping destination mode active for more input")
                // Keep destination mode active and restart listening for navigation commands
                android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                    if (_isDestinationMode.value && !_isListening.value) {
                        println("Restarting listening in destination mode for navigation commands")
                        startListening()
                    }
                }, 1500) // 1.5 second delay (matching iOS)
            }
        }
    }
    
    private fun resetDestinationSilenceTimer() {
        destinationSilenceRunnable?.let { destinationSilenceHandler?.removeCallbacks(it) }
        destinationSilenceRunnable = Runnable {
            handleDestinationSilenceTimeout()
        }
        
        if (destinationSilenceHandler == null) {
            destinationSilenceHandler = android.os.Handler(android.os.Looper.getMainLooper())
        }
        
        destinationSilenceHandler?.postDelayed(destinationSilenceRunnable!!, destinationSilenceTimeoutMs)
    }
    
    private fun handleDestinationSilenceTimeout() {
        if (_isDestinationMode.value && accumulatedDestinationText.isNotBlank()) {
            println("Destination silence timeout - using accumulated text: $accumulatedDestinationText")
            handleDestinationModeResult(accumulatedDestinationText)
        }
    }
    
    /**
     * Mutes the microphone while maintaining the active voice session
     * Platform parity feature for iOS matching behavior
     */
    fun mute() {
        _isMuted.value = true
        // Pause input processing but maintain audio session
        if (_isListening.value) {
            speechRecognizer?.stopListening()
            println("[SpeechManager] Microphone muted - session maintained")
        }
    }
    
    /**
     * Unmutes the microphone and resumes voice recognition
     * Platform parity feature for iOS matching behavior  
     */
    fun unmute() {
        _isMuted.value = false
        // Resume input processing
        if (context != null && !_isListening.value) {
            startListening()
            println("[SpeechManager] Microphone unmuted - resuming listening")
        }
    }
    
    /**
     * Toggles mute/unmute state
     * Used by microphone button for platform parity
     */
    fun toggleMute() {
        if (_isMuted.value) {
            unmute()
        } else {
            mute()
        }
    }
    
    override fun onCleared() {
        super.onCleared()
        resetVoiceActivity()
        destinationSilenceRunnable?.let { destinationSilenceHandler?.removeCallbacks(it) }
        releaseAudioFocus()
        isAudioSessionActive = false
        speechRecognizer?.destroy()
        textToSpeech?.shutdown()
    }
}