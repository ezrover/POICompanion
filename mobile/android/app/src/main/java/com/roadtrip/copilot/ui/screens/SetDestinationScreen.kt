package com.roadtrip.copilot.ui.screens

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import com.roadtrip.copilot.design.DesignTokens
import androidx.compose.foundation.border
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.semantics.*
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.platform.LocalAccessibilityManager
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.roadtrip.copilot.managers.SpeechManager
import com.roadtrip.copilot.ai.Gemma3NProcessor
import com.roadtrip.copilot.ui.components.VoiceAnimationComponent
import com.roadtrip.copilot.domain.AutoDiscoverManager
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SetDestinationScreen(
    onNavigate: (String) -> Unit,
    onShowPOIResult: (String, String?, String) -> Unit,
    onShowMainPOIView: (() -> Unit)? = null,
    onCancel: (() -> Unit)? = null
) {
    val speechManager = remember { SpeechManager() }
    val context = LocalContext.current
    val gemmaProcessor = remember { Gemma3NProcessor(context) }
    val autoDiscoverManager = remember { AutoDiscoverManager.getInstance(context) }
    val hapticFeedback = LocalHapticFeedback.current
    val accessibilityManager = LocalAccessibilityManager.current
    val coroutineScope = rememberCoroutineScope()
    
    // UI State - Stable state management
    var destinationInput by remember { mutableStateOf("") }
    var isMicMuted by remember { mutableStateOf(false) }
    var showVoiceAnimation by remember { mutableStateOf(false) }
    var buttonState by remember { mutableStateOf(ButtonState.IDLE) }
    
    // Button visibility state - always visible with proper icons
    val startButtonVisible by remember { derivedStateOf { true } } // Always visible
    val micButtonVisible by remember { derivedStateOf { true } }   // Always visible
    
    // Voice recognition states
    val isListening by speechManager.isListening.collectAsState()
    val isSpeaking by speechManager.isSpeaking.collectAsState()
    val recognizedText by speechManager.recognizedText.collectAsState()
    val isVoiceDetected by speechManager.isVoiceDetected.collectAsState()
    
    // Initialize speech manager and Gemma processor for destination mode
    LaunchedEffect(Unit) {
        speechManager.initialize(context)
        speechManager.enableDestinationMode()
        
        // Initialize Gemma processor
        coroutineScope.launch {
            try {
                gemmaProcessor.loadModel()
                println("[SetDestinationScreen] Gemma-3N model loaded successfully")
                
                // TEST: Verify model with a simple question
                println("🧪 [SetDestinationScreen] Testing Gemma-3N with verification prompt...")
                val discoveryInput = com.roadtrip.copilot.ai.DiscoveryInput(
                    latitude = 0.0,
                    longitude = 0.0,
                    radius = 5.0,
                    categories = listOf("test"),
                    context = "who are you?"
                )
                val testResult = gemmaProcessor.processDiscovery(discoveryInput)
                println("✅ [SetDestinationScreen] Model test response: '${testResult.podcastScript}'")
                
            } catch (e: Exception) {
                println("[SetDestinationScreen] Gemma-3N loading failed: ${e.message}")
            }
        }
    }
    
    // AUTO-START VOICE RECOGNITION (Platform Parity with iOS)
    LaunchedEffect(Unit) {
        if (!isMicMuted) {
            delay(100) // Brief delay for screen stability
            try {
                speechManager.startListening()
                println("[SetDestinationScreen] Voice recognition auto-started on screen entry")
            } catch (e: Exception) {
                println("[SetDestinationScreen] Voice auto-start failed: ${e.message}")
            }
        }
    }
    
    // Handle voice recognition results
    LaunchedEffect(recognizedText) {
        if (recognizedText.isNotEmpty()) {
            destinationInput = recognizedText
            
            // CRITICAL FIX: Check for explicit navigation commands
            val navigationCommands = listOf("go", "navigate", "start", "begin")
            val hasNavigationCommand = navigationCommands.any { 
                recognizedText.lowercase().contains(it) 
            }
            
            if (hasNavigationCommand) {
                // CRITICAL FIX: Only auto-navigate with explicit voice navigation commands
                println("[SetDestinationScreen] Navigation command detected in voice input")
                
                // Extract destination without the command
                var cleanDestination = recognizedText
                navigationCommands.forEach { command ->
                    cleanDestination = cleanDestination.replace(
                        Regex("\\b$command\\b", RegexOption.IGNORE_CASE), 
                        ""
                    ).trim()
                }
                
                if (cleanDestination.isNotEmpty()) {
                    destinationInput = cleanDestination
                    // Only auto-trigger navigation with explicit voice navigation commands
                    println("[SetDestinationScreen] Auto-triggering navigation for explicit voice command: $cleanDestination")
                    handleGemmaIntegrationAndNavigation(cleanDestination, onShowPOIResult, gemmaProcessor, speechManager, coroutineScope)
                } else if (destinationInput.isNotEmpty()) {
                    // Navigate to current destination input with explicit voice navigation command
                    println("[SetDestinationScreen] Navigating to current destination with voice command: $destinationInput")
                    handleGemmaIntegrationAndNavigation(destinationInput, onShowPOIResult, gemmaProcessor, speechManager, coroutineScope)
                }
            } else {
                // CRITICAL FIX: Just destination text without command - show results but require user confirmation
                println("[SetDestinationScreen] Destination-only input received, requiring user confirmation to navigate")
                // Do not auto-navigate - user must tap navigate button or say explicit navigation commands
            }
        }
    }
    
    // Handle voice animation based on voice activity - platform parity with iOS
    LaunchedEffect(isVoiceDetected, isListening) {
        if (isVoiceDetected && isListening) {
            // CRITICAL FIX: Show voice animation on Go/Navigate button when voice is detected
            showVoiceAnimation = true
            buttonState = ButtonState.VOICE_DETECTING
            println("[SetDestinationScreen] Voice detected - showing animation on navigate button")
        } else if (!isListening || !isVoiceDetected) {
            // CRITICAL FIX: Platform parity - 2 second timeout after silence (matching iOS)
            delay(2000) // Match iOS timeout exactly
            if (!isVoiceDetected && !isListening) {
                showVoiceAnimation = false
                buttonState = ButtonState.IDLE
                println("[SetDestinationScreen] Voice animation stopped after 2 second timeout")
            }
        }
    }
    
    // Prevent UI state modification during recomposition
    LaunchedEffect(isListening) {
        if (!isListening) {
            // Ensure clean state when not listening
            kotlinx.coroutines.delay(100)
            if (!isListening && !isVoiceDetected) {
                showVoiceAnimation = false
            }
        }
    }
    
    // Accessibility announcements for state changes - prevent conflicts
    LaunchedEffect(isListening) {
        if (isListening && !isSpeaking) {
            // Only announce if not already speaking to prevent conflicts
            delay(800) // Longer delay to ensure audio stability
            if (isListening && !speechManager.isSpeaking.value) {
                speechManager.speak("Listening for destination")
            }
        }
    }
    
    // Accessibility announcement for voice detection
    LaunchedEffect(isVoiceDetected) {
        if (isVoiceDetected) {
            // Brief audio feedback when voice is detected
            hapticFeedback.performHapticFeedback(HapticFeedbackType.TextHandleMove)
        }
    }
    
    // Main Layout
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .padding(16.dp)
    ) {
        // Header
        Text(
            text = "Set Your Destination",
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.onBackground,
            textAlign = TextAlign.Center,
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 24.dp)
        )
        
        // Destination Input Container with Two-Button Layout
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .semantics { 
                    contentDescription = "Destination input area with voice controls"
                },
            elevation = CardDefaults.cardElevation(defaultElevation = 4.dp),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.surface
            )
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Destination Input Field
                OutlinedTextField(
                    value = destinationInput,
                    onValueChange = { destinationInput = it },
                    placeholder = { 
                        Text(
                            "Where would you like to go?",
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    },
                    leadingIcon = {
                        Icon(
                            Icons.Default.LocationOn,
                            contentDescription = "Destination",
                            tint = MaterialTheme.colorScheme.primary
                        )
                    },
                    keyboardOptions = KeyboardOptions(
                        imeAction = ImeAction.Go
                    ),
                    keyboardActions = KeyboardActions(
                        onGo = {
                            if (destinationInput.isNotEmpty()) {
                                // CRITICAL FIX: Enter key requires explicit user confirmation to navigate
                                println("[SetDestinationScreen] Enter key pressed - requiring explicit user confirmation to navigate")
                                handleGemmaIntegrationAndNavigation(destinationInput, onShowPOIResult, gemmaProcessor, speechManager, coroutineScope)
                            }
                        }
                    ),
                    modifier = Modifier
                        .weight(1f)
                        .semantics {
                            contentDescription = "Destination input field. You can type or use voice commands like 'navigate to' or 'go to'"
                        },
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = MaterialTheme.colorScheme.primary,
                        unfocusedBorderColor = MaterialTheme.colorScheme.outline
                    ),
                    singleLine = true
                )
                
                Spacer(modifier = Modifier.width(16.dp))
                
                // Start/Navigate Button - Always visible with stable state
                if (startButtonVisible) {
                    AnimatedStartButton(
                        destinationInput = destinationInput,
                        buttonState = buttonState,
                        showVoiceAnimation = showVoiceAnimation,
                        isVoiceDetected = isVoiceDetected,
                        onClick = {
                            if (destinationInput.isNotEmpty()) {
                                hapticFeedback.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                                handleGemmaIntegrationAndNavigation(destinationInput, onShowPOIResult, gemmaProcessor, speechManager, coroutineScope)
                            }
                        },
                        modifier = Modifier.size(56.dp)
                    )
                }
                
                Spacer(modifier = Modifier.width(16.dp))
                
                // Mic/Mute Button - Always visible with stable state
                if (micButtonVisible) {
                    MicButton(
                        isMuted = isMicMuted,
                        onClick = {
                            hapticFeedback.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                            // PLATFORM PARITY: Mic button is now mute/unmute toggle only (not start/stop)
                            isMicMuted = !isMicMuted
                            if (isMicMuted) {
                                speechManager.mute()
                                println("[SetDestinationScreen] Microphone muted")
                            } else {
                                speechManager.unmute()
                                println("[SetDestinationScreen] Microphone unmuted")
                            }
                        },
                        modifier = Modifier.size(56.dp)
                    )
                }
            }
        }
        
        // Voice Status Indicator
        AnimatedVisibility(
            visible = isListening || isSpeaking || recognizedText.isNotEmpty(),
            enter = fadeIn() + slideInVertically(),
            exit = fadeOut() + slideOutVertically()
        ) {
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 16.dp),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer
                )
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    when {
                        isListening -> {
                            Text(
                                "Listening... Say your destination",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onPrimaryContainer,
                                textAlign = TextAlign.Center
                            )
                        }
                        isSpeaking -> {
                            Text(
                                "Processing your request...",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onPrimaryContainer,
                                textAlign = TextAlign.Center
                            )
                        }
                        recognizedText.isNotEmpty() -> {
                            Text(
                                "Recognized: \"$recognizedText\"",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onPrimaryContainer,
                                textAlign = TextAlign.Center
                            )
                        }
                    }
                }
            }
        }
        
        Spacer(modifier = Modifier.weight(1f))
        
        // Instructions
        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.surfaceVariant
            )
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp)
            ) {
                Text(
                    "Voice Commands:",
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    "• \"Lost Lake, Oregon, Go\" - Set destination and navigate\n" +
                    "• \"Go\" / \"Navigate\" / \"Start\" - Begin navigation\n" +
                    "• \"Mute\" / \"Unmute\" - Control microphone",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
        
        // Auto Discover Button (NEW - Platform Parity with iOS)
        Spacer(modifier = Modifier.height(24.dp))
        
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .clickable {
                    hapticFeedback.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                    handleAutoDiscover(onShowMainPOIView, speechManager, autoDiscoverManager, coroutineScope)
                }
                .semantics {
                    contentDescription = "Auto Discover - Find amazing places nearby"
                    role = Role.Button
                },
            elevation = CardDefaults.cardElevation(defaultElevation = 6.dp),
            colors = CardDefaults.cardColors(
                containerColor = Color(0xFFFF9800) // Orange color matching iOS
            )
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(20.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Icon(
                    Icons.Default.Search,
                    contentDescription = "Auto Discover",
                    modifier = Modifier.size(44.dp),
                    tint = Color.White
                )
                
                Column(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Text(
                        text = "Auto Discover",
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.SemiBold,
                        color = Color.White
                    )
                    
                    Text(
                        text = "Find amazing places nearby",
                        style = MaterialTheme.typography.bodyMedium,
                        color = Color.White.copy(alpha = 0.9f)
                    )
                }
                
                Icon(
                    Icons.AutoMirrored.Filled.ArrowForward,
                    contentDescription = null,
                    tint = Color.White.copy(alpha = 0.7f),
                    modifier = Modifier.size(24.dp)
                )
            }
        }

        // Cancel Button
        onCancel?.let { cancelAction ->
            Spacer(modifier = Modifier.height(16.dp))
            OutlinedButton(
                onClick = cancelAction,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(48.dp)
            ) {
                Text("Cancel")
            }
        }
    }
}

enum class ButtonState {
    IDLE,
    VOICE_DETECTING,
    PROCESSING,
    SUCCESS,
    ERROR
}

@Composable
fun AnimatedStartButton(
    destinationInput: String,
    buttonState: ButtonState,
    showVoiceAnimation: Boolean,
    isVoiceDetected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    // Always enabled for voice commands, visual state shows availability
    val isEnabled = true
    val hasDestination = destinationInput.isNotEmpty()
    
    // Animation for button press
    val scale by animateFloatAsState(
        targetValue = if (buttonState == ButtonState.PROCESSING) 0.95f else 1f,
        animationSpec = tween(150),
        label = "button_scale"
    )
    
    // Note: containerColor removed - using borderless IconButton design
    
    // iOS-style borderless button - NO borders, NO backgrounds, icon-only
    IconButton(
        onClick = onClick,
        enabled = isEnabled,
        modifier = modifier
            .scale(scale)
            .size(DesignTokens.TouchTarget.comfortable) // 56dp touch target
            .semantics {
                contentDescription = "Start navigation to $destinationInput. Tap or say 'go', 'navigate', or 'start'"
                role = Role.Button
                stateDescription = when (buttonState) {
                    ButtonState.IDLE -> "ready for navigation"
                    ButtonState.VOICE_DETECTING -> "processing voice input"
                    ButtonState.PROCESSING -> "processing"
                    ButtonState.SUCCESS -> "success"
                    ButtonState.ERROR -> "error"
                }
            }
    ) {
        // CRITICAL FIX: Platform parity - Voice animation replaces icon during speech detection
        AnimatedContent(
            targetState = when {
                showVoiceAnimation && isVoiceDetected -> "voice"
                buttonState == ButtonState.PROCESSING -> "processing"
                buttonState == ButtonState.SUCCESS -> "success"
                buttonState == ButtonState.ERROR -> "error"
                else -> "idle"
            },
            transitionSpec = {
                fadeIn(tween(200)) togetherWith fadeOut(tween(200))
            },
            label = "navigate_button_content"
        ) { state ->
            when (state) {
                "voice" -> {
                    // CRITICAL FIX: Voice animation shows on navigate button during speech detection
                    VoiceAnimationComponent(
                        isActive = true,
                        modifier = Modifier.size(24.dp),
                        color = if (hasDestination) Color.White else MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                "processing" -> {
                    CircularProgressIndicator(
                        modifier = Modifier.size(24.dp),
                        strokeWidth = 2.dp,
                        color = if (hasDestination) Color.White else MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                "success" -> {
                    Icon(
                        Icons.Default.Check,
                        contentDescription = "Success",
                        modifier = Modifier.size(24.dp),
                        tint = Color.White
                    )
                }
                "error" -> {
                    Icon(
                        Icons.Default.Warning,
                        contentDescription = "Error",
                        modifier = Modifier.size(24.dp),
                        tint = Color.White
                    )
                }
                else -> {
                    // iOS-style arrow.right.circle icon
                    Icon(
                        Icons.AutoMirrored.Filled.ArrowForward,
                        contentDescription = "Start Navigation",
                        modifier = Modifier.size(24.dp),
                        tint = if (hasDestination) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
    }
}

@Composable
fun MicButton(
    isMuted: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    // PLATFORM PARITY FIX: MIC button is ONLY for mute/unmute toggle - NO voice activity animations allowed
    // Removed isListening parameter and all voice activity indicators per platform parity requirements
    
    // iOS-style borderless button - NO borders, NO backgrounds, icon-only
    IconButton(
        onClick = onClick,
        modifier = modifier
            .size(DesignTokens.TouchTarget.comfortable) // 56dp touch target
            .semantics {
                contentDescription = if (isMuted) "Microphone muted. Tap to unmute" else "Microphone ready. Tap to mute"
                role = Role.Button
                stateDescription = if (isMuted) "muted" else "ready"
            }
    ) {
        // PLATFORM PARITY FIX: Remove AnimatedContent with listening state - MIC button shows ONLY muted/active states
        Icon(
            imageVector = if (isMuted) Icons.Default.MicOff else Icons.Default.Mic,
            contentDescription = if (isMuted) "Microphone muted" else "Microphone ready",
            modifier = Modifier.size(24.dp),
            tint = if (isMuted) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.onSurface
        )
    }
}

private fun handleGemmaIntegrationAndNavigation(
    destination: String,
    onShowPOIResult: (String, String?, String) -> Unit,
    gemmaProcessor: Gemma3NProcessor,
    speechManager: SpeechManager,
    coroutineScope: kotlinx.coroutines.CoroutineScope
) {
    if (destination.isNotEmpty()) {
        val prompt = "tell me about this place: $destination"
        println("[SetDestinationScreen] Calling Gemma-3N with prompt: $prompt")
        
        coroutineScope.launch {
            try {
                // Ensure model is loaded
                if (!gemmaProcessor.isModelLoaded.value) {
                    gemmaProcessor.loadModel()
                }
                
                // Create discovery input for Gemma
                val discoveryInput = com.roadtrip.copilot.ai.DiscoveryInput(
                    latitude = 0.0, // We don't have coordinates yet
                    longitude = 0.0,
                    radius = 5.0,
                    categories = listOf("destination"),
                    context = prompt
                )
                
                // Get response from Gemma-3N
                val discoveryResult = gemmaProcessor.processDiscovery(discoveryInput)
                val gemmaResponse = discoveryResult.podcastScript
                
                println("[SetDestinationScreen] Gemma response received: $gemmaResponse")
                
                // Show POI result screen with response
                onShowPOIResult(destination, null, gemmaResponse)
                
            } catch (e: Exception) {
                println("[SetDestinationScreen] Gemma integration failed: ${e.message}")
                
                // Fallback response if Gemma fails
                val fallbackResponse = "This destination looks interesting! It's a great place to explore and discover new experiences."
                onShowPOIResult(destination, null, fallbackResponse)
            }
        }
        
        speechManager.disableDestinationMode()
    }
}

private fun handleAutoDiscover(
    onShowMainPOIView: (() -> Unit)?,
    speechManager: SpeechManager,
    autoDiscoverManager: AutoDiscoverManager,
    coroutineScope: kotlinx.coroutines.CoroutineScope
) {
    println("[SetDestinationScreen] Auto Discover initiated")
    speechManager.speak("Finding amazing places nearby")
    
    coroutineScope.launch {
        try {
            // Start auto discovery process using AutoDiscoverManager
            autoDiscoverManager.startAutoDiscovery()
            
            delay(1000) // Brief delay for voice feedback
            
            // Navigate to MainPOIView in discovery mode
            onShowMainPOIView?.invoke()
            
            println("[SetDestinationScreen] Auto Discover started successfully")
            
        } catch (e: Exception) {
            println("[SetDestinationScreen] Auto Discovery failed: ${e.message}")
            speechManager.speak("Sorry, discovery is not available right now")
        }
    }
    
    speechManager.disableDestinationMode()
}

private fun handleNavigationCommand(
    destination: String,
    onNavigate: (String) -> Unit,
    speechManager: SpeechManager
) {
    if (destination.isNotEmpty()) {
        speechManager.speak("Starting navigation to $destination")
        speechManager.disableDestinationMode()
        onNavigate(destination)
    }
}