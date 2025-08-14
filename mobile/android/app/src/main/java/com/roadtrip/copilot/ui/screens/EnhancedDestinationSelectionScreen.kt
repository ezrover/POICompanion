package com.roadtrip.copilot.ui.screens

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.MapView
import com.google.android.gms.maps.model.*
import com.roadtrip.copilot.managers.*
import com.roadtrip.copilot.models.*
import com.roadtrip.copilot.models.DestinationSearchResult
import kotlinx.coroutines.delay
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import android.content.BroadcastReceiver
import android.content.IntentFilter

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RedesignedDestinationSelectionScreen(
    onNavigate: (DestinationInfo) -> Unit
) {
    val context = LocalContext.current
    val speechManager: SpeechManager = hiltViewModel()
    val locationManager: LocationManager = hiltViewModel()
    
    var searchQuery by remember { mutableStateOf("") }
    var searchResults by remember { mutableStateOf<List<DestinationSearchResult>>(emptyList()) }
    var selectedDestination by remember { mutableStateOf<DestinationSearchResult?>(null) }
    var googleMap by remember { mutableStateOf<GoogleMap?>(null) }
    
    // Initialize speech manager and auto-start voice listening
    LaunchedEffect(Unit) {
        speechManager.initialize(context)
        
        // Enable destination mode for accepting raw destination names
        speechManager.enableDestinationMode()
        
        // Auto-start voice listening after a short delay (like iOS)
        kotlinx.coroutines.delay(500)
        speechManager.startListening()
    }
    
    // Set up destination selection broadcast receiver
    DisposableEffect(context) {
        val destinationReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: android.content.Context?, intent: android.content.Intent?) {
                when (intent?.action) {
                    SpeechManager.DESTINATION_SELECTED -> {
                        val destination = intent.getStringExtra("destination")
                        val hasAction = intent.getBooleanExtra("hasAction", false)
                        val action = intent.getStringExtra("action")
                        
                        if (!destination.isNullOrBlank()) {
                            searchQuery = destination
                            performDestinationSearch(destination) { results ->
                                searchResults = results
                                if (results.isNotEmpty()) {
                                    selectedDestination = results[0]
                                    updateMapCamera(googleMap, results[0])
                                    
                                    if (hasAction && action == "navigate") {
                                        // Auto-navigate when action keyword was detected
                                        speechManager.speak("Navigating to ${results[0].name}")
                                        onNavigate(results[0].toDestinationInfo())
                                    } else {
                                        speechManager.speak("Found ${results[0].name}")
                                    }
                                } else {
                                    speechManager.speak("No results found for $destination")
                                }
                            }
                        }
                    }
                }
            }
        }
        
        val filter = IntentFilter().apply {
            addAction(SpeechManager.DESTINATION_SELECTED)
        }
        
        LocalBroadcastManager.getInstance(context)
            .registerReceiver(destinationReceiver, filter)
        
        onDispose {
            LocalBroadcastManager.getInstance(context)
                .unregisterReceiver(destinationReceiver)
            speechManager.disableDestinationMode()
        }
    }
    
    // Listen for recognized speech
    val recognizedText by speechManager.recognizedText.collectAsStateWithLifecycle()
    val isListening by speechManager.isListening.collectAsStateWithLifecycle()
    val isSpeaking by speechManager.isSpeaking.collectAsStateWithLifecycle()
    val isDestinationMode by speechManager.isDestinationMode.collectAsStateWithLifecycle()
    
    // Handle navigation commands when destination is selected (enhanced for platform parity)
    LaunchedEffect(recognizedText, isListening, isDestinationMode) {
        if (recognizedText.isNotEmpty() && !isListening) {
            val lowercaseInput = recognizedText.lowercase().trim()
            
            // Navigation command patterns (matching iOS)
            val navigationCommands = listOf(
                "go", "let's go", "navigate", "navigate there", 
                "start", "start trip", "start roadtrip",
                "take me there", "begin", "drive"
            )
            
            // Check if it's a standalone navigation command
            val isNavigationCommand = navigationCommands.any { command ->
                lowercaseInput == command || lowercaseInput.startsWith("$command ")
            }
            
            if (isNavigationCommand) {
                selectedDestination?.let { destination ->
                    println("Standalone navigation command detected: '$recognizedText'")
                    speechManager.disableDestinationMode() // Disable since we're navigating
                    speechManager.speak("Starting roadtrip to ${destination.name}")
                    onNavigate(destination.toDestinationInfo())
                    return@LaunchedEffect
                }
            }
            
            // Legacy fallback for non-destination mode navigation commands
            if (!isDestinationMode && (lowercaseInput.contains("start") || 
                lowercaseInput.contains("go") || 
                lowercaseInput.contains("navigate"))) {
                selectedDestination?.let { destination ->
                    speechManager.speak("Navigating to ${destination.name}")
                    onNavigate(destination.toDestinationInfo())
                    return@LaunchedEffect
                }
            }
        }
    }
    
    Box(modifier = Modifier.fillMaxSize()) {
        // Full-screen Google Maps
        AndroidView(
            factory = { context ->
                MapView(context).apply {
                    onCreate(null)
                    getMapAsync { map ->
                        googleMap = map
                        map.uiSettings.isZoomControlsEnabled = true
                        map.uiSettings.isMyLocationButtonEnabled = false // We'll provide our own UI
                        map.uiSettings.isMapToolbarEnabled = false
                        
                        // Set default location (San Francisco)
                        val defaultLocation = LatLng(37.7749, -122.4194)
                        map.moveCamera(CameraUpdateFactory.newLatLngZoom(defaultLocation, 10f))
                        
                        // Handle map clicks for custom destination selection
                        map.setOnMapClickListener { latLng ->
                            val customDestination = DestinationSearchResult(
                                name = "Selected Location",
                                address = "${String.format("%.4f", latLng.latitude)}, ${String.format("%.4f", latLng.longitude)}",
                                latitude = latLng.latitude,
                                longitude = latLng.longitude
                            )
                            selectedDestination = customDestination
                            searchQuery = customDestination.name
                            updateMapCamera(googleMap, customDestination)
                        }
                    }
                }
            },
            modifier = Modifier.fillMaxSize()
        ) { mapView ->
            mapView.onResume()
        }
        
        // Bottom search bar overlay
        Column(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
        ) {
            // Selected destination info card
            AnimatedVisibility(
                visible = selectedDestination != null,
                enter = slideInVertically() + fadeIn(),
                exit = slideOutVertically() + fadeOut()
            ) {
                selectedDestination?.let { destination ->
                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp)
                            .padding(bottom = 8.dp),
                        colors = CardDefaults.cardColors(
                            containerColor = MaterialTheme.colorScheme.surfaceContainer
                        ),
                        elevation = CardDefaults.cardElevation(defaultElevation = 8.dp)
                    ) {
                        Column(
                            modifier = Modifier.padding(16.dp)
                        ) {
                            Text(
                                text = destination.name,
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.onSurface
                            )
                            Text(
                                text = destination.address,
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                modifier = Modifier.padding(top = 4.dp)
                            )
                        }
                    }
                }
            }
            
            // Bottom search bar with navigate button - thin container with 4px margin
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp)
                    .padding(bottom = 4.dp), // Only 4px from screen bottom
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.95f)
                ),
                elevation = CardDefaults.cardElevation(defaultElevation = 8.dp)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 12.dp, vertical = 8.dp), // Reduced padding for thinner container
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    // Search field
                    OutlinedTextField(
                        value = searchQuery,
                        onValueChange = { 
                            searchQuery = it
                            if (it.isNotEmpty()) {
                                performDestinationSearch(it) { results ->
                                    searchResults = results
                                    if (results.isNotEmpty()) {
                                        selectedDestination = results[0]
                                        updateMapCamera(googleMap, results[0])
                                    }
                                }
                            }
                        },
                        placeholder = { 
                            Text(
                                text = "Where would you like to go?",
                                style = MaterialTheme.typography.bodyMedium
                            ) 
                        },
                        leadingIcon = {
                            Icon(
                                imageVector = Icons.Default.Search,
                                contentDescription = "Search",
                                tint = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        },
                        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Go),
                        keyboardActions = KeyboardActions(
                            onGo = {
                                // Navigate on Enter key press
                                selectedDestination?.let { destination ->
                                    onNavigate(destination.toDestinationInfo())
                                }
                            }
                        ),
                        modifier = Modifier
                            .weight(1f)
                            .semantics {
                                contentDescription = "Destination search field"
                            },
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedContainerColor = MaterialTheme.colorScheme.surface,
                            unfocusedContainerColor = MaterialTheme.colorScheme.surface,
                            focusedBorderColor = MaterialTheme.colorScheme.primary,
                            unfocusedBorderColor = MaterialTheme.colorScheme.outline
                        ),
                        singleLine = true
                    )
                    
                    // Navigate/Voice Button - Always shows Navigate chevron, sound waves when listening
                    NavigateVoiceButton(
                        isListening = isListening,
                        hasDestination = selectedDestination != null,
                        onVoiceClick = {
                            if (isListening) {
                                speechManager.stopListening()
                            } else {
                                // Re-enable destination mode when starting voice input
                                speechManager.enableDestinationMode()
                                speechManager.startListening()
                            }
                        },
                        onNavigateClick = {
                            selectedDestination?.let { destination ->
                                onNavigate(destination.toDestinationInfo())
                            } ?: run {
                                // Start voice search if no destination - enable destination mode
                                speechManager.enableDestinationMode()
                                speechManager.startListening()
                            }
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Navigate/Voice Button Component

@Composable
fun NavigateVoiceButton(
    isListening: Boolean,
    hasDestination: Boolean,
    onVoiceClick: () -> Unit,
    onNavigateClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    // Animation for voice wave effect
    val infiniteTransition = rememberInfiniteTransition(label = "voice_animation")
    val waveScale by infiniteTransition.animateFloat(
        initialValue = 0.8f,
        targetValue = if (isListening) 1.2f else 0.8f,
        animationSpec = infiniteRepeatable(
            animation = tween(1000, easing = EaseInOut),
            repeatMode = RepeatMode.Reverse
        ),
        label = "wave_scale"
    )
    
    FloatingActionButton(
        onClick = {
            if (hasDestination && !isListening) {
                onNavigateClick()
            } else {
                onVoiceClick()
            }
        },
        modifier = modifier
            .size(56.dp)
            .semantics {
                contentDescription = when {
                    isListening -> "Stop voice input"
                    hasDestination -> "Navigate to destination"
                    else -> "Navigate with voice search"
                }
            },
        containerColor = when {
            isListening -> MaterialTheme.colorScheme.error
            hasDestination -> MaterialTheme.colorScheme.primary
            else -> MaterialTheme.colorScheme.secondary
        },
        contentColor = MaterialTheme.colorScheme.onPrimary
    ) {
        Box(
            contentAlignment = Alignment.Center
        ) {
            when {
                isListening -> {
                    // Voice wave animation inside button
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(2.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        repeat(5) { index ->
                            VoiceWaveBar(
                                isActive = isListening,
                                delay = index * 100,
                                scale = waveScale
                            )
                        }
                    }
                }
                hasDestination -> {
                    // Navigate chevron icon
                    Icon(
                        imageVector = Icons.Default.ArrowForward,
                        contentDescription = null,
                        modifier = Modifier.size(28.dp)
                    )
                }
                else -> {
                    // Voice microphone icon
                    Icon(
                        imageVector = Icons.Default.Mic,
                        contentDescription = null,
                        modifier = Modifier.size(24.dp)
                    )
                }
            }
        }
    }
}

// MARK: - Voice Wave Bar Component

@Composable
fun VoiceWaveBar(
    isActive: Boolean,
    delay: Int,
    scale: Float,
    modifier: Modifier = Modifier
) {
    val infiniteTransition = rememberInfiniteTransition(label = "voice_bar_${delay}")
    val height by infiniteTransition.animateFloat(
        initialValue = 4.dp.value,
        targetValue = if (isActive) (12.dp.value * scale) else 4.dp.value,
        animationSpec = infiniteRepeatable(
            animation = tween(600, easing = EaseInOut, delayMillis = delay),
            repeatMode = RepeatMode.Reverse
        ),
        label = "bar_height_${delay}"
    )
    
    Box(
        modifier = modifier
            .width(2.dp)
            .height(height.dp)
            .clip(RoundedCornerShape(1.dp))
            .background(MaterialTheme.colorScheme.onPrimary)
    )
}


// MARK: - Helper Functions

/**
 * Performs destination search using Google Places API or mock data
 * In production, this would integrate with Google Places API
 */
private fun performDestinationSearch(
    query: String,
    onResults: (List<DestinationSearchResult>) -> Unit
) {
    // Mock search results - replace with actual Google Places API implementation
    val mockResults = listOf(
        DestinationSearchResult(
            name = "Monterey Bay Aquarium",
            address = "886 Cannery Row, Monterey, CA 93940",
            latitude = 36.6183,
            longitude = -121.9018
        ),
        DestinationSearchResult(
            name = "Big Sur",
            address = "Big Sur, CA 93920",
            latitude = 36.2704,
            longitude = -121.8081
        ),
        DestinationSearchResult(
            name = "Santa Barbara",
            address = "Santa Barbara, CA",
            latitude = 34.4208,
            longitude = -119.6982
        ),
        DestinationSearchResult(
            name = "Yosemite National Park",
            address = "Yosemite National Park, CA",
            latitude = 37.8651,
            longitude = -119.5383
        ),
        DestinationSearchResult(
            name = "San Francisco",
            address = "San Francisco, CA",
            latitude = 37.7749,
            longitude = -122.4194
        )
    ).filter { 
        it.name.contains(query, ignoreCase = true) ||
        it.address.contains(query, ignoreCase = true)
    }
    
    onResults(mockResults)
}

/**
 * Updates the Google Maps camera to focus on the selected destination
 */
private fun updateMapCamera(googleMap: GoogleMap?, destination: DestinationSearchResult) {
    googleMap?.let { map ->
        val location = LatLng(destination.latitude, destination.longitude)
        map.clear()
        map.addMarker(
            MarkerOptions()
                .position(location)
                .title(destination.name)
                .snippet(destination.address)
                .icon(BitmapDescriptorFactory.defaultMarker(BitmapDescriptorFactory.HUE_BLUE))
        )
        map.animateCamera(
            CameraUpdateFactory.newLatLngZoom(location, 14f),
            1000,
            null
        )
    }
}

