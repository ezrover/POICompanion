package com.roadtrip.copilot

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import dagger.hilt.android.AndroidEntryPoint
import androidx.compose.foundation.layout.*
import com.roadtrip.copilot.design.DesignTokens
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.clickable
import androidx.compose.foundation.Image
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.ui.draw.scale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.activity.compose.BackHandler
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import coil.compose.AsyncImage
import androidx.compose.foundation.background
import androidx.compose.animation.core.*
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.text.style.TextOverflow
import kotlinx.coroutines.launch
import com.roadtrip.copilot.managers.*
import com.roadtrip.copilot.models.*
import com.roadtrip.copilot.models.POIData
import com.roadtrip.copilot.models.DestinationInfo
import com.roadtrip.copilot.ui.components.*
import com.roadtrip.copilot.ui.screens.*
import com.roadtrip.copilot.ui.theme.RoadtripCopilotTheme

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Force landscape orientation for automotive use
        requestedOrientation = android.content.pm.ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE
        
        setContent {
            RoadtripCopilotTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    MainAppContent()
                }
            }
        }
    }
    
}

@Composable
fun MainAppContent() {
    val context = LocalContext.current
    var allRequiredPermissionsGranted by remember { mutableStateOf(false) }
    var isModelLoaded by remember { mutableStateOf(false) }
    
    // Check all critical permission status on app start
    LaunchedEffect(Unit) {
        val hasMicrophonePermission = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.RECORD_AUDIO
        ) == PackageManager.PERMISSION_GRANTED
        
        val hasLocationPermission = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED ||
        ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_COARSE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
        
        // CRITICAL: Both microphone AND location permissions are required
        // Microphone is essential for voice commands and hands-free operation
        // Location is essential for POI discovery
        allRequiredPermissionsGranted = hasMicrophonePermission && hasLocationPermission
    }
    
    when {
        !allRequiredPermissionsGranted -> {
            PermissionRequestScreen(
                onAllPermissionsGranted = { allRequiredPermissionsGranted = true }
            )
        }
        !isModelLoaded -> {
            SplashScreen(
                onLoadingComplete = { isModelLoaded = true }
            )
        }
        else -> {
            RootScreen()
        }
    }
}

@Composable
fun RootScreen() {
    val appStateManager: AppStateManager = hiltViewModel()
    val roadtripSession: RoadtripSessionManager = hiltViewModel()
    
    val currentScreen by appStateManager.currentScreen.collectAsStateWithLifecycle()
    
    when (currentScreen) {
        AppScreen.DESTINATION_SELECTION -> {
            SetDestinationScreen(
                onNavigate = { destination ->
                    // Create DestinationInfo from destination string
                    val destinationInfo = DestinationInfo(
                        name = destination,
                        address = destination, // For now, use same as name - can be enhanced later
                        latitude = 0.0, // Default coordinates - will be resolved later
                        longitude = 0.0,
                        estimatedDuration = null
                    )
                    
                    // Navigate to main dashboard when navigation is triggered
                    appStateManager.startRoadtrip(destinationInfo)
                    
                    // Resume existing session or start new one
                    if (roadtripSession.sessionStartTime.value != 0L) {
                        roadtripSession.resumeSession()
                    } else {
                        roadtripSession.startSession()
                    }
                }
            )
        }
        
        AppScreen.MAIN_DASHBOARD -> {
            // Handle Android system back button
            BackHandler {
                appStateManager.returnToDestinationSelection()
                roadtripSession.pauseSession()
            }
            
            MainScreen(appStateManager, roadtripSession)
        }
    }
}

@Composable
fun MainScreen(
    appStateManager: AppStateManager = hiltViewModel(),
    roadtripSession: RoadtripSessionManager = hiltViewModel()
) {
    val context = LocalContext.current
    val locationManager: LocationManager = hiltViewModel()
    val speechManager: SpeechManager = hiltViewModel()
    val agentManager: AIAgentManager = hiltViewModel()
    
    LaunchedEffect(Unit) {
        speechManager.initialize(context)
    }
    
    val currentPOI by agentManager.currentPOI.collectAsStateWithLifecycle()
    val isListening by speechManager.isListening.collectAsStateWithLifecycle()
    val isSpeaking by speechManager.isSpeaking.collectAsStateWithLifecycle()
    val isVoiceDetected by speechManager.isVoiceDetected.collectAsStateWithLifecycle()
    val currentCity by locationManager.currentCity.collectAsStateWithLifecycle()
    val currentState by locationManager.currentState.collectAsStateWithLifecycle()
    
    var animatingButton by remember { mutableStateOf<String?>(null) }
    
    // Voice command receiver setup
    val voiceCommandReceiver = setupVoiceCommandObservers(agentManager, speechManager) { action ->
        animatingButton = action
    }
    
    LaunchedEffect(Unit) {
        locationManager.checkAndRequestLocationUpdates()
        agentManager.startBackgroundAgents()
        
        // Auto-start speech recognition when entering main screen
        kotlinx.coroutines.delay(500) // 0.5 second delay
        speechManager.startListening()
    }
    
    // Clean up receiver on dispose
    DisposableEffect(Unit) {
        onDispose {
            LocalBroadcastManager.getInstance(context)
                .unregisterReceiver(voiceCommandReceiver)
        }
    }
    
    Box(
        modifier = Modifier.fillMaxSize()
    ) {
        // Fullscreen Background Image
        val poi = currentPOI
        if (poi != null) {
            AsyncImage(
                model = poi.imageURL,
                contentDescription = poi.name,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop
            )
        } else {
            // Default Morro Rock image - using drawable resource
            Image(
                painter = painterResource(id = R.drawable.morro_rock),
                contentDescription = "Morro Rock",
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop
            )
        }
        
        // Content Overlay
        Column(
            modifier = Modifier
                .fillMaxSize()
                .statusBarsPadding() // Add status bar padding to prevent content going above screen
                .navigationBarsPadding() // Also add navigation bar padding
                .padding(top = 16.dp) // Add 16dp total to top safe area to prevent clipping
        ) {
            // Collect state for UI
            val isInActiveRoadtrip by appStateManager.isInActiveRoadtrip.collectAsStateWithLifecycle()
            
            // Top Status Bar with semi-transparent gradient background
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(
                        Brush.verticalGradient(
                            colors = listOf(
                                Color.Black.copy(alpha = 0.7f),
                                Color.Black.copy(alpha = 0.3f),
                                Color.Transparent
                            )
                        )
                    )
            ) {
                Column(
                    modifier = Modifier
                    .padding(horizontal = 16.dp) // Automotive standard: 16dp minimum edge margins
                    .padding(vertical = 16.dp) // Increased vertical padding to prevent clipping
                ) {
                    TopStatusBarWithDestination(
                        city = currentCity,
                        state = currentState,
                        destinationInfo = appStateManager.destinationInfo,
                        elapsedTime = roadtripSession.formatElapsedTime(),
                        isInActiveRoadtrip = isInActiveRoadtrip,
                        onBackPressed = {
                            appStateManager.returnToDestinationSelection()
                            roadtripSession.pauseSession()
                        },
                        isTransparent = true,
                        locationManager = locationManager,
                        appStateManager = appStateManager
                    )
                }
            }
            
            Spacer(modifier = Modifier.weight(1f))
            
            // POI Name Overlay (if available)
            currentPOI?.let { poi ->
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp)
                        .padding(bottom = 10.dp)
                        .background(
                            Color.Black.copy(alpha = 0.6f),
                            RoundedCornerShape(DesignTokens.CornerRadius.md)
                        )
                        .padding(12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.LocationOn,
                        contentDescription = "Location",
                        tint = Color.White,
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = poi.name,
                        color = Color.White,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
            
            // CRITICAL FIX: REMOVE center screen voice overlay per platform parity requirements
            // Voice animation should ONLY appear within the Go/Navigate button, not as center overlay
            // This ensures consistent UX across iOS and Android platforms
            
            // Bottom Control Buttons with full-width gray background
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(Color.Black.copy(alpha = 0.4f)) // Full width gray background
            ) {
                Column {
                    VoiceControlButtonsGrid(
                        onSave = { agentManager.favoriteCurrentPOI() },
                        onLike = { agentManager.likeCurrentPOI() },
                        onDislike = { agentManager.dislikeCurrentPOI() },
                        onNavigate = { handleNavigateActionWithContext(context, agentManager) },
                        onPrevious = { agentManager.previousPOI() },
                        onNext = { agentManager.nextPOI() },
                        onCall = { handleCallActionWithContext(context, agentManager) },
                        onEndTrip = {
                            appStateManager.returnToDestinationSelection()
                            roadtripSession.pauseSession()
                        },
                        animatingButton = animatingButton,
                        isTransparent = true,
                        isListening = isListening,
                        isSpeaking = isSpeaking,
                        isVoiceDetected = isVoiceDetected,
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 8.dp) // Adjusted margins for icon-only buttons
                            .padding(top = 12.dp) // Increased top margin for better spacing
                    )
                    
                    // Consistent bottom spacing
                    Spacer(modifier = Modifier.height(12.dp))
                }
            }
        }
    }
}

@Composable
fun TopStatusBarWithDestination(
    city: String?,
    state: String?,
    destinationInfo: String,
    elapsedTime: String,
    isInActiveRoadtrip: Boolean,
    onBackPressed: (() -> Unit)? = null,
    isTransparent: Boolean = false,
    locationManager: LocationManager? = null,
    appStateManager: AppStateManager? = null
) {
    Column {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Back Button and Title
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Spacer(modifier = Modifier.width(6.dp)) // 6dp left padding
                
                // Back Button
                if (onBackPressed != null) {
                    IconButton(
                        onClick = onBackPressed,
                        modifier = Modifier
                            .size(48.dp) // Automotive: larger touch target
                            .padding(4.dp)
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(4.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.ArrowBack,
                                contentDescription = "Back to destination selection",
                                tint = if (isTransparent) Color.White else Color.Blue,
                                modifier = Modifier.size(20.dp)
                            )
                            Text(
                                text = "Back",
                                color = if (isTransparent) Color.White else Color.Blue,
                                fontSize = 14.sp,
                                fontWeight = FontWeight.Medium
                            )
                        }
                    }
                }
                
                // Destination Info with Distance in center (moved from second row)
                if (isInActiveRoadtrip) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.LocationOn,
                            contentDescription = "Destination",
                            tint = if (isTransparent) Color.White else Color.Blue,
                            modifier = Modifier.size(16.dp)
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        
                        val distanceText = formatDistanceToDestination(locationManager, appStateManager)
                        Text(
                            text = "To: $destinationInfo, Trip: $distanceText",
                            fontSize = 20.sp,
                            fontWeight = FontWeight.Bold,
                            color = if (isTransparent) Color.White else MaterialTheme.colorScheme.primary,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    }
                } else {
                    Text(
                        text = "Roadtrip-Copilot",
                        fontSize = 20.sp,
                        fontWeight = FontWeight.Bold,
                        color = if (isTransparent) Color.White else MaterialTheme.colorScheme.primary
                    )
                }
            }
            
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Location Info - Single line to prevent breaking
                Row(
                    horizontalArrangement = Arrangement.End
                ) {
                    val locationText = when {
                        city != null && state != null -> "$city, $state"
                        city != null -> city
                        state != null -> state
                        else -> null
                    }
                    
                    locationText?.let {
                        Text(
                            text = it,
                            fontSize = 12.sp,
                            color = if (isTransparent) Color.White else MaterialTheme.colorScheme.onSurfaceVariant,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    }
                }
            }
        }
        
    }
}


@Composable
fun POIImageDisplay(poi: POIData?) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .height(300.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 8.dp)
    ) {
        if (poi != null) {
            AsyncImage(
                model = poi.imageURL,
                contentDescription = poi.name,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop
            )
        } else {
            // Default Morro Rock image
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.BottomStart
            ) {
                // Use a placeholder color representing the Morro Rock image
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(
                            Brush.verticalGradient(
                                colors = listOf(
                                    Color(0xFF4A90E2),
                                    Color(0xFF8B7355)
                                )
                            )
                        )
                )
                
                // Location overlay
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(Color.Black.copy(alpha = 0.6f))
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.LocationOn,
                        contentDescription = "Location",
                        tint = Color.White,
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "Morro Rock",
                        color = Color.White,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }
    }
}


@Composable
fun VoiceControlButtonsGrid(
    onSave: () -> Unit,
    onLike: () -> Unit,
    onDislike: () -> Unit,
    onNavigate: () -> Unit,
    onPrevious: () -> Unit,
    onNext: () -> Unit,
    onCall: () -> Unit,
    onEndTrip: () -> Unit,
    animatingButton: String?,
    isTransparent: Boolean = false,
    isListening: Boolean = false,
    isSpeaking: Boolean = false,
    isVoiceDetected: Boolean = false,
    modifier: Modifier = Modifier
) {
    // Single Row Layout with even distribution using Spacer
    Row(
        modifier = modifier.fillMaxWidth()
    ) {
        VoiceAnimatedButton(
            icon = Icons.Default.KeyboardArrowLeft,
            label = "Previous",
            color = Color.White,
            onClick = onPrevious,
            actionKey = "previous",
            isAnimating = animatingButton == "previous",
            isTransparent = isTransparent
        )
        
        Spacer(modifier = Modifier.weight(1f))
        
        VoiceAnimatedButton(
            icon = Icons.Default.Favorite,
            label = "Save",
            color = Color.Red,
            onClick = onSave,
            actionKey = "save",
            isAnimating = animatingButton == "save",
            isTransparent = isTransparent
        )
        
        Spacer(modifier = Modifier.weight(1f))
        
        VoiceAnimatedButton(
            icon = Icons.Default.ThumbUp,
            label = "Like",
            color = Color.Green,
            onClick = onLike,
            actionKey = "like",
            isAnimating = animatingButton == "like",
            isTransparent = isTransparent
        )
        
        Spacer(modifier = Modifier.weight(1f))
        
        VoiceAnimatedButton(
            icon = Icons.Default.ThumbDown,
            label = "Dislike",
            color = Color(0xFFFF9800),
            onClick = onDislike,
            actionKey = "dislike",
            isAnimating = animatingButton == "dislike",
            isTransparent = isTransparent
        )
        
        Spacer(modifier = Modifier.weight(1f))
        
        VoiceAnimatedButton(
            icon = Icons.Default.LocationOn,
            label = "Navigate",
            color = Color.Blue,
            onClick = onNavigate,
            actionKey = "navigate",
            isAnimating = animatingButton == "navigate",
            isTransparent = isTransparent,
            showVoiceWave = isVoiceDetected || isSpeaking
        )
        
        Spacer(modifier = Modifier.weight(1f))
        
        VoiceAnimatedButton(
            icon = Icons.Default.Phone,
            label = "Call",
            color = Color(0xFF4CAF50), // Green
            onClick = onCall,
            actionKey = "call",
            isAnimating = animatingButton == "call",
            isTransparent = isTransparent
        )
        
        Spacer(modifier = Modifier.weight(1f))
        
        VoiceAnimatedButton(
            icon = Icons.Default.Close,
            label = "Exit",
            color = Color.Red,
            onClick = onEndTrip,
            actionKey = "exit",
            isAnimating = animatingButton == "exit",
            isTransparent = isTransparent
        )
        
        Spacer(modifier = Modifier.weight(1f))
        
        VoiceAnimatedButton(
            icon = Icons.Default.KeyboardArrowRight,
            label = "Next",
            color = Color.White,
            onClick = onNext,
            actionKey = "next",
            isAnimating = animatingButton == "next",
            isTransparent = isTransparent
        )
    }
}

@Composable
fun VoiceAnimatedButton(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    color: Color,
    onClick: () -> Unit,
    actionKey: String,
    isAnimating: Boolean,
    isTransparent: Boolean = false,
    showVoiceWave: Boolean = false
) {
    val scale by animateFloatAsState(
        targetValue = if (isAnimating) 1.2f else 1.0f,
        animationSpec = tween(300, easing = EaseInOut), label = "button_scale"
    )
    
    val iconScale by animateFloatAsState(
        targetValue = if (isAnimating) 1.3f else 1.0f,
        animationSpec = tween(300, easing = EaseInOut), label = "icon_scale"
    )
    
    // Icon-only button with no circular background
    Box(
        modifier = Modifier
            .size(48.dp) // Smaller footprint: 48dp touch targets
            .clickable(
                onClick = onClick,
                indication = null, // Remove ripple effect for cleaner look
                interactionSource = remember { MutableInteractionSource() }
            )
            .scale(scale),
        contentAlignment = Alignment.Center
    ) {
        if (showVoiceWave && actionKey == "navigate") {
            // Show voice wave animation for navigate button
            VoiceWaveAnimation()
        } else {
            // Show icon with enhanced visibility
            Icon(
                imageVector = icon,
                contentDescription = label,
                tint = if (isAnimating) Color.White else color,
                modifier = Modifier
                    .size(32.dp) // Larger icon for better visibility
                    .scale(iconScale)
            )
        }
    }
}

@Composable
fun VoiceWaveAnimation() {
    val animatedHeights = remember {
        (0..7).map { 
            Animatable(0.3f)
        }
    }
    val scope = rememberCoroutineScope()
    
    LaunchedEffect(Unit) {
        animatedHeights.forEachIndexed { index, animatable ->
            scope.launch {
                animatable.animateTo(
                    targetValue = 1.0f,
                    animationSpec = infiniteRepeatable(
                        animation = tween(
                            durationMillis = (400 + index * 100),
                            easing = EaseInOut
                        ),
                        repeatMode = RepeatMode.Reverse
                    )
                )
            }
        }
    }
    
    Row(
        horizontalArrangement = Arrangement.spacedBy(2.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        animatedHeights.forEach { height ->
            Box(
                modifier = Modifier
                    .width(3.dp)
                    .height((4 + height.value * 12).dp)
                    .background(
                        Color.White,
                        RoundedCornerShape(DesignTokens.CornerRadius.xs)
                    )
            )
        }
    }
}

@Composable
fun ControlButton(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    color: Color,
    onClick: () -> Unit
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        IconButton(
            onClick = onClick,
            modifier = Modifier
                .size(60.dp)
                .clip(RoundedCornerShape(DesignTokens.CornerRadius.sm))
        ) {
            Icon(
                imageVector = icon,
                contentDescription = label,
                tint = color,
                modifier = Modifier.size(32.dp)
            )
        }
        
        Text(
            text = label,
            fontSize = 10.sp,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}


// Voice command observer setup (matching iOS implementation)
class VoiceCommandReceiver(
    private val agentManager: AIAgentManager,
    private val speechManager: SpeechManager,
    private val context: Context,
    private val onButtonAnimate: (String) -> Unit
) : BroadcastReceiver() {
    
    override fun onReceive(context: Context?, intent: Intent?) {
        when (intent?.action) {
            SpeechManager.VOICE_COMMAND_BUTTON_ANIMATION -> {
                val action = intent.getStringExtra("action")
                action?.let { onButtonAnimate(it) }
            }
            SpeechManager.VOICE_COMMAND_ACTION -> {
                val action = intent.getStringExtra("action")
                val originalText = intent.getStringExtra("originalText")
                action?.let { handleVoiceCommandAction(it, originalText) }
            }
            SpeechManager.VOICE_COMMAND_RECEIVED -> {
                val command = intent.getStringExtra("command")
                command?.let { processAndroidVoiceCommand(it, context) }
            }
            SpeechManager.SPEECH_DID_FINISH -> {
                // Speech finished, could update UI state here
                println("[Android] Speech synthesis finished")
            }
        }
    }
    
    private fun handleVoiceCommandAction(action: String, originalText: String?) {
        println("[Android] Handling voice command action: $action")
        
        when (action) {
            "save" -> {
                agentManager.favoriteCurrentPOI()
                speechManager.speak("Saved to favorites")
            }
            "like" -> {
                agentManager.likeCurrentPOI()
                speechManager.speak("Liked")
            }
            "dislike" -> {
                agentManager.dislikeCurrentPOI()
                agentManager.nextPOI()
                speechManager.speak("Skipped to next place")
            }
            "next" -> {
                agentManager.nextPOI()
                speechManager.speak("Next location")
            }
            "previous" -> {
                agentManager.previousPOI()
                speechManager.speak("Previous location")
            }
            "navigate" -> {
                handleNavigateActionWithContext(context, agentManager)
                speechManager.speak("Getting directions")
            }
            "call" -> {
                handleCallActionWithContext(context, agentManager)
                speechManager.speak("Calling location")
            }
            "exit" -> {
                // This would need app state manager context to work properly
                speechManager.speak("Returning to destination selection")
            }
            else -> {
                println("[Android] Unknown voice command action: $action")
            }
        }
    }
    
    private fun processAndroidVoiceCommand(command: String, context: Context?) {
        val lowercaseCommand = command.lowercase()
        
        println("[Android] Processing voice command: $command")
        
        // Check if command matches POI category keywords for filtering requests
        context?.let { ctx ->
            POICategories.matchCategoryFromVoiceKeywords(command, ctx)?.let { categoryId ->
                speechManager.speak("Looking for ${POICategories.getCategoryDisplayName(categoryId, ctx)} places near you")
                // TODO: Implement category-specific POI filtering
                return
            }
        }
        
        // General voice commands that don't require specific context
        when {
            lowercaseCommand.contains("show me") || lowercaseCommand.contains("tell me about") -> {
                agentManager.currentPOI.value?.let { poi ->
                    val categoryName = context?.let { poi.getCategoryDisplayName(it) } ?: poi.getCategoryDisplayName()
                    speechManager.speak("This is ${poi.name}, a $categoryName. ${poi.reviewSummary ?: "A great place to visit."}")
                } ?: speechManager.speak("I'm still discovering places for you")
            }
            
            lowercaseCommand.contains("what's here") || lowercaseCommand.contains("where are we") -> {
                agentManager.currentPOI.value?.let { poi ->
                    speechManager.speak("We're looking at ${poi.name}, ${poi.getFormattedDistance()} ahead")
                } ?: speechManager.speak("I'm finding interesting places along your route")
            }
            
            // Emergency/safety category priority
            lowercaseCommand.contains("help") || lowercaseCommand.contains("emergency") -> {
                speechManager.speak("Looking for nearby hospitals, gas stations, and emergency services")
                // TODO: Filter to safety categories only
            }
            
            else -> {
                speechManager.speak("I didn't understand that command. You can say save, like, dislike, next, previous, navigate, or call.")
            }
        }
    }
}

// Voice command observer setup
@Composable
private fun setupVoiceCommandObservers(
    agentManager: AIAgentManager,
    speechManager: SpeechManager,
    onButtonAnimate: (String) -> Unit
): VoiceCommandReceiver {
    val context = LocalContext.current
    val receiver = remember {
        VoiceCommandReceiver(agentManager, speechManager, context, onButtonAnimate)
    }
    
    LaunchedEffect(Unit) {
        val filter = IntentFilter().apply {
            addAction(SpeechManager.VOICE_COMMAND_ACTION)
            addAction(SpeechManager.VOICE_COMMAND_BUTTON_ANIMATION)
            addAction(SpeechManager.VOICE_COMMAND_RECEIVED)
            addAction(SpeechManager.SPEECH_DID_FINISH)
        }
        
        LocalBroadcastManager.getInstance(context).registerReceiver(receiver, filter)
    }
    
    return receiver
}

// Navigation action handler
private fun handleNavigateAction() {
    // This would typically be called with access to agentManager and context
    // For now, we'll use a placeholder implementation
    println("Navigate action triggered")
    // TODO: Access current POI from agentManager to get coordinates
}

// Navigation action handler with context and agent manager
private fun handleNavigateActionWithContext(
    context: android.content.Context,
    agentManager: com.roadtrip.copilot.managers.AIAgentManager
) {
    val currentPOI = agentManager.currentPOI.value
    if (currentPOI == null) {
        println("No current POI available for navigation")
        return
    }
    
    val latitude = currentPOI.latitude
    val longitude = currentPOI.longitude
    val name = currentPOI.name
    
    println("Navigate action triggered for $name at $latitude, $longitude")
    
    // Create intent to open Google Maps or default map app
    val gmmIntentUri = Uri.parse("google.navigation:q=$latitude,$longitude")
    val mapIntent = Intent(Intent.ACTION_VIEW, gmmIntentUri)
    mapIntent.setPackage("com.google.android.apps.maps")
    
    // Try to open Google Maps first
    if (mapIntent.resolveActivity(context.packageManager) != null) {
        context.startActivity(mapIntent)
        println("Opened Google Maps for navigation to $name")
    } else {
        // Fallback to generic map intent if Google Maps is not available
        val genericMapUri = Uri.parse("geo:$latitude,$longitude?q=$latitude,$longitude($name)")
        val genericMapIntent = Intent(Intent.ACTION_VIEW, genericMapUri)
        
        if (genericMapIntent.resolveActivity(context.packageManager) != null) {
            context.startActivity(genericMapIntent)
            println("Opened default map app for navigation to $name")
        } else {
            println("No map application available")
        }
    }
}

// Call action handler  
private fun handleCallActionWithContext(
    context: android.content.Context,
    agentManager: com.roadtrip.copilot.managers.AIAgentManager
) {
    val currentPOI = agentManager.currentPOI.value
    if (currentPOI == null) {
        println("No current POI available for calling")
        return
    }
    
    val phoneNumber = currentPOI.phoneNumber
    if (phoneNumber.isNullOrEmpty()) {
        println("No phone number available for ${currentPOI.name}")
        return
    }
    
    // Clean phone number (remove any formatting characters except + and digits)
    val cleanPhoneNumber = phoneNumber.replace(Regex("[^+\\d]"), "")
    
    if (cleanPhoneNumber.isEmpty()) {
        println("Invalid phone number format: $phoneNumber")
        return
    }
    
    try {
        // Create phone intent
        val phoneIntent = Intent(Intent.ACTION_CALL).apply {
            data = Uri.parse("tel:$cleanPhoneNumber")
        }
        
        // Check if phone call permission is available and device can handle phone calls
        if (phoneIntent.resolveActivity(context.packageManager) != null) {
            context.startActivity(phoneIntent)
            println("Opened phone app to call $cleanPhoneNumber for ${currentPOI.name}")
        } else {
            // Fallback to dialer app if direct calling is not available
            val dialerIntent = Intent(Intent.ACTION_DIAL).apply {
                data = Uri.parse("tel:$cleanPhoneNumber")
            }
            
            if (dialerIntent.resolveActivity(context.packageManager) != null) {
                context.startActivity(dialerIntent)
                println("Opened dialer app with $cleanPhoneNumber for ${currentPOI.name}")
            } else {
                println("No phone app available on this device")
            }
        }
    } catch (e: Exception) {
        println("Error making phone call: ${e.message}")
        
        // Fallback to dialer app
        try {
            val dialerIntent = Intent(Intent.ACTION_DIAL).apply {
                data = Uri.parse("tel:$cleanPhoneNumber")
            }
            context.startActivity(dialerIntent)
            println("Opened dialer app as fallback")
        } catch (e2: Exception) {
            println("Failed to open dialer app: ${e2.message}")
        }
    }
}

// Legacy handleCallAction for compatibility
private fun handleCallAction() {
    println("Call action triggered - use handleCallActionWithContext instead")
}

@Composable
private fun formatDistanceToDestination(
    locationManager: LocationManager?,
    appStateManager: AppStateManager?
): String {
    val destination = appStateManager?.getDestinationInfo()
    return if (locationManager != null && destination != null) {
        val distanceInMeters = locationManager.getDistanceTo(destination.latitude, destination.longitude)
        if (distanceInMeters != null) {
            val distanceInMiles = distanceInMeters * 0.000621371f // Convert meters to miles
            
            // Format based on distance
            when {
                distanceInMiles < 0.1f -> "0m"
                distanceInMiles < 1.0f -> String.format("%.1fm", distanceInMiles)
                distanceInMiles < 10.0f -> String.format("%.1fm", distanceInMiles)
                else -> String.format("%.0fm", distanceInMiles)
            }
        } else {
            "0m"
        }
    } else {
        "0m"
    }
}