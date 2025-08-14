package com.roadtrip.copilot.ui.screens

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import com.roadtrip.copilot.design.DesignTokens
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.lifecycle.viewmodel.compose.viewModel
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.MapView
import com.google.android.gms.maps.model.*
import com.roadtrip.copilot.managers.*
import com.roadtrip.copilot.models.*
import kotlinx.coroutines.delay

data class DestinationSearchResult(
    val name: String,
    val address: String,
    val latitude: Double,
    val longitude: Double
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DestinationSelectionScreen(
    onDestinationSelected: (DestinationSearchResult) -> Unit
) {
    val speechManager: SpeechManager = viewModel()
    val locationManager: LocationManager = viewModel()
    
    var searchQuery by remember { mutableStateOf("") }
    var searchResults by remember { mutableStateOf<List<DestinationSearchResult>>(emptyList()) }
    var selectedDestination by remember { mutableStateOf<DestinationSearchResult?>(null) }
    var showConfirmation by remember { mutableStateOf(false) }
    var googleMap by remember { mutableStateOf<GoogleMap?>(null) }
    
    val context = LocalContext.current
    
    // Initialize speech manager
    LaunchedEffect(Unit) {
        speechManager.initialize(context)
        setupDestinationSpeechRecognition(speechManager, searchQuery) { query ->
            searchQuery = query
            // Trigger search
            performDestinationSearch(query) { results ->
                searchResults = results
                // Auto-select first result from voice
                if (results.isNotEmpty()) {
                    selectedDestination = results[0]
                    updateMapCamera(googleMap, results[0])
                }
            }
        }
    }
    
    // Listen for recognized speech
    val recognizedText by speechManager.recognizedText.collectAsState()
    val isListening by speechManager.isListening.collectAsState()
    val isSpeaking by speechManager.isSpeaking.collectAsState()
    
    LaunchedEffect(recognizedText) {
        if (recognizedText.isNotEmpty() && !isListening) {
            processVoiceDestination(recognizedText) { destination ->
                searchQuery = destination
                performDestinationSearch(destination) { results ->
                    searchResults = results
                    if (results.isNotEmpty()) {
                        selectedDestination = results[0]
                        updateMapCamera(googleMap, results[0])
                        speechManager.speak("Found ${results[0].name}")
                    }
                }
            }
        }
    }
    
    Box(modifier = Modifier.fillMaxSize()) {
        // Google Maps
        AndroidView(
            factory = { context ->
                MapView(context).apply {
                    onCreate(null)
                    getMapAsync { map ->
                        googleMap = map
                        map.uiSettings.isZoomControlsEnabled = true
                        map.uiSettings.isMyLocationButtonEnabled = true
                        
                        // Set default location (San Francisco)
                        val defaultLocation = LatLng(37.7749, -122.4194)
                        map.moveCamera(CameraUpdateFactory.newLatLngZoom(defaultLocation, 10f))
                        
                        // Add markers for search results
                        map.setOnMapClickListener { latLng ->
                            // Handle map clicks for custom destination selection
                            val customDestination = DestinationSearchResult(
                                name = "Custom Location",
                                address = "${latLng.latitude}, ${latLng.longitude}",
                                latitude = latLng.latitude,
                                longitude = latLng.longitude
                            )
                            selectedDestination = customDestination
                        }
                    }
                }
            },
            modifier = Modifier.fillMaxSize()
        ) { mapView ->
            mapView.onResume()
        }
        
        // Overlay UI
        Column(
            modifier = Modifier.fillMaxSize()
        ) {
            // Top Search Section
            Column(
                modifier = Modifier
                    .background(
                        Brush.verticalGradient(
                            colors = listOf(
                                Color.Black.copy(alpha = 0.8f),
                                Color.Black.copy(alpha = 0.4f),
                                Color.Transparent
                            )
                        )
                    )
                    .padding(16.dp)
            ) {
                Spacer(modifier = Modifier.height(40.dp)) // Status bar padding
                
                Text(
                    text = "Where would you like to go?",
                    fontSize = 24.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.White,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth()
                )
                
                Spacer(modifier = Modifier.height(16.dp))
                
                // Search Row
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    OutlinedTextField(
                        value = searchQuery,
                        onValueChange = { searchQuery = it },
                        placeholder = { Text("Search for destination...") },
                        leadingIcon = {
                            Icon(
                                imageVector = Icons.Default.Search,
                                contentDescription = "Search"
                            )
                        },
                        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                        keyboardActions = KeyboardActions(
                            onSearch = {
                                performDestinationSearch(searchQuery) { results ->
                                    searchResults = results
                                }
                            }
                        ),
                        modifier = Modifier.weight(1f),
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedContainerColor = Color.White,
                            unfocusedContainerColor = Color.White
                        )
                    )
                    
                    Spacer(modifier = Modifier.width(8.dp))
                    
                    // Voice Input Button
                    Button(
                        onClick = {
                            if (isListening) {
                                speechManager.stopListening()
                            } else {
                                speechManager.startListening()
                            }
                        },
                        modifier = Modifier
                            .size(56.dp)
                            .scale(if (isListening) 1.1f else 1.0f),
                        shape = RoundedCornerShape(DesignTokens.CornerRadius.lg),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = if (isListening) Color.Red else Color.Blue
                        )
                    ) {
                        Icon(
                            imageVector = if (isListening) Icons.Default.MicOff else Icons.Default.Mic,
                            contentDescription = "Voice Input",
                            tint = Color.White
                        )
                    }
                }
                
                // Voice Feedback
                AnimatedVisibility(visible = isListening || isSpeaking || recognizedText.isNotEmpty()) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(top = 8.dp)
                    ) {
                        if (isListening) {
                            Text(
                                text = "Say your destination...",
                                color = Color.White,
                                fontSize = 16.sp,
                                modifier = Modifier.fillMaxWidth(),
                                textAlign = TextAlign.Center
                            )
                            
                            // Simple voice visualizer
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.Center
                            ) {
                                repeat(8) { index ->
                                    VoiceBar(isActive = isListening, delay = index * 100)
                                }
                            }
                        }
                        
                        if (recognizedText.isNotEmpty()) {
                            Text(
                                text = "\"$recognizedText\"",
                                color = Color.Cyan,
                                fontSize = 14.sp,
                                modifier = Modifier.fillMaxWidth(),
                                textAlign = TextAlign.Center
                            )
                        }
                    }
                }
            }
            
            Spacer(modifier = Modifier.weight(1f))
            
            // Bottom Controls
            Column(
                modifier = Modifier
                    .background(
                        Brush.verticalGradient(
                            colors = listOf(
                                Color.Transparent,
                                Color.Black.copy(alpha = 0.4f),
                                Color.Black.copy(alpha = 0.8f)
                            )
                        )
                    )
                    .padding(16.dp)
            ) {
                // Selected Destination Info
                selectedDestination?.let { destination ->
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        colors = CardDefaults.cardColors(containerColor = Color.White.copy(alpha = 0.9f))
                    ) {
                        Column(
                            modifier = Modifier.padding(16.dp)
                        ) {
                            Text(
                                text = destination.name,
                                fontSize = 18.sp,
                                fontWeight = FontWeight.Bold
                            )
                            Text(
                                text = destination.address,
                                fontSize = 14.sp,
                                color = Color.Gray
                            )
                        }
                    }
                    
                    Spacer(modifier = Modifier.height(16.dp))
                }
                
                // Set Destination Button
                Button(
                    onClick = {
                        selectedDestination?.let {
                            showConfirmation = true
                        }
                    },
                    enabled = selectedDestination != null,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(56.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = if (selectedDestination != null) Color.Blue else Color.Gray
                    )
                ) {
                    Icon(
                        imageVector = Icons.Default.LocationOn,
                        contentDescription = null,
                        modifier = Modifier.size(24.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "Set Destination",
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }
    }
    
    // Confirmation Dialog
    if (showConfirmation && selectedDestination != null) {
        AlertDialog(
            onDismissRequest = { showConfirmation = false },
            title = { Text("Confirm Destination") },
            text = { 
                Text("Ready to start your roadtrip to ${selectedDestination?.name}?")
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        selectedDestination?.let { destination ->
                            onDestinationSelected(destination)
                        }
                        showConfirmation = false
                    }
                ) {
                    Text("Start Roadtrip")
                }
            },
            dismissButton = {
                TextButton(onClick = { showConfirmation = false }) {
                    Text("Cancel")
                }
            }
        )
    }
}

@Composable
fun VoiceBar(isActive: Boolean, delay: Int) {
    val infiniteTransition = rememberInfiniteTransition(label = "voice_bar")
    val height by infiniteTransition.animateFloat(
        initialValue = 4.dp.value,
        targetValue = if (isActive) 20.dp.value else 4.dp.value,
        animationSpec = infiniteRepeatable(
            animation = tween(500, easing = EaseInOut, delayMillis = delay),
            repeatMode = RepeatMode.Reverse
        ), label = "bar_height"
    )
    
    Box(
        modifier = Modifier
            .width(3.dp)
            .height(height.dp)
            .padding(horizontal = 1.dp)
            .clip(RoundedCornerShape(2.dp))
            .background(if (isActive) Color.Red else Color.Gray)
    )
}

// Helper functions
private fun setupDestinationSpeechRecognition(
    speechManager: SpeechManager,
    currentQuery: String,
    onQueryUpdate: (String) -> Unit
) {
    // This would integrate with the speech manager's voice command system
    // For now, we'll handle it through direct speech recognition
}

private fun processVoiceDestination(
    voiceInput: String,
    onDestinationExtracted: (String) -> Unit
) {
    val lowercaseInput = voiceInput.lowercase()
    
    val triggers = listOf(
        "go to", "take me to", "navigate to", "drive to", 
        "set destination to", "destination"
    )
    
    for (trigger in triggers) {
        val index = lowercaseInput.indexOf(trigger)
        if (index != -1) {
            val destination = voiceInput.substring(index + trigger.length).trim()
            if (destination.isNotEmpty()) {
                onDestinationExtracted(destination)
                return
            }
        }
    }
    
    // If no trigger found, use the entire input as destination
    onDestinationExtracted(voiceInput.trim())
}

private fun performDestinationSearch(
    query: String,
    onResults: (List<DestinationSearchResult>) -> Unit
) {
    // Mock search results - in real implementation, this would use Google Places API
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
        )
    ).filter { it.name.contains(query, ignoreCase = true) }
    
    onResults(mockResults)
}

private fun updateMapCamera(googleMap: GoogleMap?, destination: DestinationSearchResult) {
    googleMap?.let { map ->
        val location = LatLng(destination.latitude, destination.longitude)
        map.clear()
        map.addMarker(
            MarkerOptions()
                .position(location)
                .title(destination.name)
                .snippet(destination.address)
        )
        map.animateCamera(CameraUpdateFactory.newLatLngZoom(location, 12f))
    }
}