package com.roadtrip.copilot.ui.screens

import android.content.Intent
import android.net.Uri
import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.semantics.*
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import coil.compose.AsyncImage
import coil.request.ImageRequest
import androidx.compose.ui.draw.scale
import androidx.compose.ui.res.painterResource
import com.roadtrip.copilot.design.DesignTokens
import com.roadtrip.copilot.domain.AutoDiscoverManager
import com.roadtrip.copilot.managers.SpeechManager
import com.roadtrip.copilot.models.POIData
import com.roadtrip.copilot.ai.Gemma3NProcessor
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.util.*

/**
 * MainPOIView - Android implementation for Auto Discover feature
 * Platform parity with iOS MainPOIView.swift
 * Handles both normal POI display and discovery mode with auto-cycling photos
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainPOIView(
    currentPOI: POIData?,
    isDiscoveryMode: Boolean = false,
    onBack: () -> Unit,
    onNavigateToMaps: ((POIData) -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()
    val speechManager = remember { SpeechManager() }
    val autoDiscoverManager = remember { AutoDiscoverManager.getInstance(context) }
    val gemmaProcessor = remember { Gemma3NProcessor(context) }
    val scrollState = rememberScrollState()
    
    // Discovery mode state
    val discoveredPOIs by autoDiscoverManager.discoveredPOIs.collectAsState()
    val currentPOIIndex by autoDiscoverManager.currentPOIIndex.collectAsState()
    val currentPhotoIndex by autoDiscoverManager.currentPhotoIndex.collectAsState()
    val isAutoPhotoActive by autoDiscoverManager.isAutoPhotoActive.collectAsState()
    
    // UI State
    var isReading by remember { mutableStateOf(false) }
    var hasSpokenResponse by remember { mutableStateOf(false) }
    var animatingButton by remember { mutableStateOf<String?>(null) }
    
    // Speech manager states
    val isSpeaking by speechManager.isSpeaking.collectAsState()
    
    // Get the actual current POI (either passed in or from discovery)
    val displayPOI = if (isDiscoveryMode && discoveredPOIs.isNotEmpty()) {
        discoveredPOIs.getOrNull(currentPOIIndex)
    } else {
        currentPOI
    }
    
    // Initialize speech manager
    LaunchedEffect(Unit) {
        speechManager.initialize(context)
    }
    
    // Update reading state based on speech manager
    LaunchedEffect(isSpeaking) {
        isReading = isSpeaking
    }
    
    // Auto-speak POI information when loading in discovery mode
    LaunchedEffect(displayPOI) {
        if (isDiscoveryMode && displayPOI != null && !hasSpokenResponse) {
            delay(500) // Brief delay to let screen settle
            val podcastContent = generatePOIPodcastContent(displayPOI, gemmaProcessor)
            speechManager.speak(podcastContent)
            hasSpokenResponse = true
        }
    }
    
    Box(modifier = modifier.fillMaxSize()) {
        // Background Image with Auto-Cycling Support
        displayPOI?.let { poi ->
            val imageUrl = if (isDiscoveryMode && poi.photos.isNotEmpty()) {
                // Discovery mode - show auto-cycling photos
                poi.photos.getOrNull(currentPhotoIndex) ?: poi.imageURL
            } else {
                // Normal mode - single POI image
                poi.imageURL
            }
            
            AsyncImage(
                model = ImageRequest.Builder(context)
                    .data(imageUrl)
                    .crossfade(true)
                    .build(),
                contentDescription = poi.name,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop,
                placeholder = painterResource(android.R.drawable.ic_menu_gallery)
            )
        }
        
        // Content overlay with gradient background
        Column(
            modifier = Modifier.fillMaxSize()
        ) {
            // Top Status Bar
            TopStatusBar(
                poi = displayPOI,
                isDiscoveryMode = isDiscoveryMode,
                currentPOIIndex = currentPOIIndex,
                totalPOIs = discoveredPOIs.size,
                currentPhotoIndex = currentPhotoIndex,
                totalPhotos = displayPOI?.photos?.size ?: 0,
                onBack = onBack
            )
            
            Spacer(modifier = Modifier.weight(1f))
            
            // POI Information Card
            displayPOI?.let { poi ->
                POIInfoCard(
                    poi = poi,
                    isReading = isReading,
                    onPlayAgain = {
                        if (isReading) {
                            speechManager.stopSpeaking()
                        } else {
                            coroutineScope.launch {
                                val content = generatePOIPodcastContent(poi, gemmaProcessor)
                                speechManager.speak(content)
                            }
                        }
                    }
                )
            }
            
            // Bottom Control Buttons
            BottomControlButtons(
                poi = displayPOI,
                isDiscoveryMode = isDiscoveryMode,
                animatingButton = animatingButton,
                onPrevious = { 
                    animatingButton = "previous"
                    autoDiscoverManager.previousPOI()
                    coroutineScope.launch {
                        delay(600)
                        animatingButton = null
                    }
                },
                onNext = { 
                    animatingButton = "next"
                    autoDiscoverManager.nextPOI()
                    coroutineScope.launch {
                        delay(600)
                        animatingButton = null
                    }
                },
                onFavorite = { 
                    animatingButton = "favorite"
                    /* TODO: Implement favorite */
                    coroutineScope.launch {
                        delay(600)
                        animatingButton = null
                    }
                },
                onSearch = { 
                    animatingButton = "search"
                    onBack()
                    coroutineScope.launch {
                        delay(600)
                        animatingButton = null
                    }
                },
                onSpeak = {
                    animatingButton = "speak"
                    displayPOI?.let { poi ->
                        coroutineScope.launch {
                            val content = generatePOIPodcastContent(poi, gemmaProcessor)
                            speechManager.speak(content)
                            delay(600)
                            animatingButton = null
                        }
                    } ?: run {
                        coroutineScope.launch {
                            delay(600)
                            animatingButton = null
                        }
                    }
                },
                onLike = { 
                    animatingButton = "like"
                    /* TODO: Implement like */
                    coroutineScope.launch {
                        delay(600)
                        animatingButton = null
                    }
                },
                onDislike = { 
                    animatingButton = "dislike"
                    autoDiscoverManager.dislikeCurrentPOI()
                    coroutineScope.launch {
                        delay(600)
                        animatingButton = null
                    }
                },
                onNavigate = {
                    animatingButton = "navigate"
                    displayPOI?.let { poi ->
                        onNavigateToMaps?.invoke(poi) ?: openInMaps(context, poi)
                    }
                    coroutineScope.launch {
                        delay(600)
                        animatingButton = null
                    }
                },
                onCall = {
                    animatingButton = "call"
                    displayPOI?.let { poi -> callPOI(context, poi) }
                    coroutineScope.launch {
                        delay(600)
                        animatingButton = null
                    }
                },
                onExit = {
                    animatingButton = "exit"
                    onBack()
                    coroutineScope.launch {
                        delay(600)
                        animatingButton = null
                    }
                }
            )
        }
    }
    
    // Cleanup speech when leaving screen
    DisposableEffect(Unit) {
        onDispose {
            speechManager.stopSpeaking()
        }
    }
}

@Composable
private fun TopStatusBar(
    poi: POIData?,
    isDiscoveryMode: Boolean,
    currentPOIIndex: Int,
    totalPOIs: Int,
    currentPhotoIndex: Int,
    totalPhotos: Int,
    onBack: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(
                androidx.compose.ui.graphics.Brush.verticalGradient(
                    colors = listOf(
                        Color.Black.copy(alpha = 0.7f),
                        Color.Black.copy(alpha = 0.3f),
                        Color.Transparent
                    )
                )
            )
            .padding(16.dp)
    ) {
        // Back button and title
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.fillMaxWidth()
        ) {
            IconButton(
                onClick = onBack,
                modifier = Modifier.semantics {
                    contentDescription = "Back to destination selection"
                }
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        Icons.Default.ChevronLeft,
                        contentDescription = null,
                        tint = Color.White,
                        modifier = Modifier.size(24.dp)
                    )
                    Text(
                        "Back",
                        color = Color.White,
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
            }
            
            Spacer(modifier = Modifier.weight(1f))
            
            // Discovery mode indicators
            if (isDiscoveryMode && totalPOIs > 0) {
                Column(
                    horizontalAlignment = Alignment.End
                ) {
                    if (totalPhotos > 0) {
                        Text(
                            "${currentPhotoIndex + 1}/$totalPhotos",
                            color = Color.White.copy(alpha = 0.8f),
                            style = MaterialTheme.typography.bodySmall
                        )
                    }
                    Text(
                        "POI ${currentPOIIndex + 1}/$totalPOIs",
                        color = Color.White.copy(alpha = 0.8f),
                        style = MaterialTheme.typography.bodySmall
                    )
                }
            }
        }
        
        // POI name if available
        poi?.let {
            Spacer(modifier = Modifier.height(8.dp))
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    if (isDiscoveryMode) Icons.Default.Search else Icons.Default.LocationOn,
                    contentDescription = null,
                    tint = Color.White,
                    modifier = Modifier.size(20.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    it.name,
                    color = Color.White,
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
        }
    }
}

@Composable
private fun POIInfoCard(
    poi: POIData,
    isReading: Boolean,
    onPlayAgain: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = Color.Black.copy(alpha = 0.6f)
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Header with audio indicator
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Icon(
                    Icons.Default.Psychology,
                    contentDescription = "AI Information",
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(24.dp)
                )
                
                Text(
                    "AI Information",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = Color.White
                )
                
                Spacer(modifier = Modifier.weight(1f))
                
                // Audio indicator
                AnimatedVisibility(
                    visible = isReading,
                    enter = fadeIn(),
                    exit = fadeOut()
                ) {
                    VoiceWaveIndicator()
                }
            }
            
            // POI description
            Text(
                text = poi.description.ifEmpty { "Discover this amazing location and what makes it special!" },
                style = MaterialTheme.typography.bodyLarge,
                color = Color.White,
                lineHeight = 24.sp
            )
            
            // POI details row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column {
                    Text(
                        "Rating: ${String.format("%.1f", poi.rating)} ⭐",
                        style = MaterialTheme.typography.bodyMedium,
                        color = Color.White.copy(alpha = 0.9f)
                    )
                    Text(
                        "Distance: ${poi.getFormattedDistance()}",
                        style = MaterialTheme.typography.bodyMedium,
                        color = Color.White.copy(alpha = 0.9f)
                    )
                }
                
                Column(horizontalAlignment = Alignment.End) {
                    Text(
                        "Category: ${poi.getCategoryDisplayName()}",
                        style = MaterialTheme.typography.bodyMedium,
                        color = Color.White.copy(alpha = 0.9f)
                    )
                    if (poi.reviewCount > 0) {
                        Text(
                            "${poi.reviewCount} reviews",
                            style = MaterialTheme.typography.bodyMedium,
                            color = Color.White.copy(alpha = 0.9f)
                        )
                    }
                }
            }
            
            // Audio Controls
            Row {
                Button(
                    onClick = onPlayAgain,
                    colors = ButtonDefaults.buttonColors(
                        containerColor = MaterialTheme.colorScheme.primary
                    ),
                    shape = RoundedCornerShape(DesignTokens.CornerRadius.md)
                ) {
                    Icon(
                        if (isReading) Icons.Default.Pause else Icons.Default.PlayArrow,
                        contentDescription = if (isReading) "Pause" else "Play Again",
                        modifier = Modifier.size(16.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = if (isReading) "Pause" else "Play Again",
                        fontWeight = FontWeight.Medium
                    )
                }
            }
        }
    }
}

@Composable
private fun BottomControlButtons(
    poi: POIData?,
    isDiscoveryMode: Boolean,
    animatingButton: String?,
    onPrevious: () -> Unit,
    onNext: () -> Unit,
    onFavorite: () -> Unit,
    onSearch: () -> Unit,
    onSpeak: () -> Unit,
    onLike: () -> Unit,
    onDislike: () -> Unit,
    onNavigate: () -> Unit,
    onCall: () -> Unit,
    onExit: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(Color.Black.copy(alpha = 0.4f))
            .height(68.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 4.dp, vertical = 8.dp),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Previous Button
            VoiceAnimatedButton(
                action = onPrevious,
                icon = Icons.Default.ChevronLeft,
                label = "Previous",
                color = Color(0xFF9C27B0), // Purple
                actionKey = "previous",
                isAnimating = animatingButton == "previous"
            )
            
            // Save/Favorite Button (Normal Mode) OR Search Button (Discovery Mode)
            if (isDiscoveryMode) {
                VoiceAnimatedButton(
                    action = onSearch,
                    icon = Icons.Default.Search,
                    label = "Search",
                    color = Color(0xFF2196F3), // Blue
                    actionKey = "search",
                    isAnimating = animatingButton == "search"
                )
            } else {
                VoiceAnimatedButton(
                    action = onFavorite,
                    icon = Icons.Default.Favorite,
                    label = "Save",
                    color = Color(0xFFF44336), // Red
                    actionKey = "favorite",
                    isAnimating = animatingButton == "favorite"
                )
            }
            
            // Speak/Info Button (Discovery Mode Only)
            if (isDiscoveryMode) {
                VoiceAnimatedButton(
                    action = onSpeak,
                    icon = Icons.Default.VolumeUp,
                    label = "Speak",
                    color = Color(0xFF9C27B0), // Purple
                    actionKey = "speak",
                    isAnimating = animatingButton == "speak"
                )
            }
            
            // Like Button
            VoiceAnimatedButton(
                action = onLike,
                icon = Icons.Default.ThumbUp,
                label = "Like",
                color = Color(0xFF4CAF50), // Green
                actionKey = "like",
                isAnimating = animatingButton == "like"
            )
            
            // Dislike Button
            VoiceAnimatedButton(
                action = onDislike,
                icon = Icons.Default.ThumbDown,
                label = "Dislike",
                color = Color(0xFFFF9800), // Orange
                actionKey = "dislike",
                isAnimating = animatingButton == "dislike"
            )
            
            // Navigate Button
            VoiceAnimatedButton(
                action = onNavigate,
                icon = Icons.Default.LocationOn,
                label = "Navigate",
                color = Color(0xFF2196F3), // Blue
                actionKey = "navigate",
                isAnimating = animatingButton == "navigate"
            )
            
            // Call Button
            VoiceAnimatedButton(
                action = onCall,
                icon = Icons.Default.Phone,
                label = "Call",
                color = Color(0xFF4CAF50), // Green
                actionKey = "call",
                isAnimating = animatingButton == "call"
            )
            
            // Exit Button
            VoiceAnimatedButton(
                action = onExit,
                icon = Icons.Default.Close,
                label = "Exit",
                color = Color(0xFFF44336), // Red
                actionKey = "exit",
                isAnimating = animatingButton == "exit"
            )
            
            // Next Button
            VoiceAnimatedButton(
                action = onNext,
                icon = Icons.Default.ChevronRight,
                label = "Next",
                color = Color(0xFF9C27B0), // Purple
                actionKey = "next",
                isAnimating = animatingButton == "next"
            )
        }
    }
}

@Composable
private fun VoiceAnimatedButton(
    action: () -> Unit,
    icon: ImageVector,
    label: String,
    color: Color,
    actionKey: String,
    isAnimating: Boolean
) {
    IconButton(
        onClick = action,
        modifier = Modifier
            .size(DesignTokens.TouchTarget.comfortable) // 56dp touch target
            .semantics {
                contentDescription = label
                role = Role.Button
            }
    ) {
        Icon(
            imageVector = icon,
            contentDescription = label,
            modifier = Modifier
                .size(32.dp)
                .then(
                    if (isAnimating) Modifier.scale(1.2f) else Modifier
                ),
            tint = if (isAnimating) color.copy(alpha = 0.8f) else color
        )
    }
}

@Composable
private fun VoiceWaveIndicator() {
    Row(
        horizontalArrangement = Arrangement.spacedBy(2.dp)
    ) {
        repeat(3) { index ->
            val animatedHeight by animateFloatAsState(
                targetValue = 1.0f,
                animationSpec = infiniteRepeatable(
                    animation = tween(600),
                    repeatMode = RepeatMode.Reverse
                ),
                label = "audio_indicator_$index"
            )
            
            Box(
                modifier = Modifier
                    .width(4.dp)
                    .height((8 * animatedHeight).dp)
                    .clip(RoundedCornerShape(2.dp))
                    .background(MaterialTheme.colorScheme.primary)
            )
        }
    }
}

// Helper function to generate POI podcast content
private suspend fun generatePOIPodcastContent(poi: POIData, gemmaProcessor: Gemma3NProcessor): String {
    return try {
        // Use Gemma-3N to generate rich podcast content
        val discoveryInput = com.roadtrip.copilot.ai.DiscoveryInput(
            latitude = poi.latitude,
            longitude = poi.longitude,
            radius = 1.0,
            categories = listOf(poi.category),
            context = "Generate an engaging podcast description for ${poi.name}: ${poi.description}"
        )
        
        val result = gemmaProcessor.processDiscovery(discoveryInput)
        result.podcastScript.ifEmpty { generateBasicPodcastContent(poi) }
    } catch (e: Exception) {
        println("[MainPOIView] Gemma podcast generation failed: ${e.message}")
        generateBasicPodcastContent(poi)
    }
}

// Fallback content generation
private fun generateBasicPodcastContent(poi: POIData): String {
    var content = "Here's what I know about ${poi.name}. "
    
    if (poi.description.isNotEmpty()) {
        content += "${poi.description} "
    }
    
    if (poi.rating > 0) {
        val ratingDescription = when {
            poi.rating >= 4.5 -> "excellent"
            poi.rating >= 4.0 -> "very good"
            poi.rating >= 3.5 -> "good"
            else -> "average"
        }
        content += "This place has $ratingDescription reviews with a ${String.format("%.1f", poi.rating)} star rating. "
    }
    
    // Add category information
    content += "It's categorized as ${poi.getCategoryDisplayName()}. "
    
    if (poi.reviewCount > 0) {
        content += "With ${poi.reviewCount} reviews from visitors, "
    }
    
    // Add location context
    content += "This location offers a unique experience for roadtrip explorers. "
    
    content += "Would you like to navigate there or continue exploring?"
    
    return content
}

private fun openInMaps(context: android.content.Context, poi: POIData) {
    val query = poi.address ?: poi.name
    val uri = Uri.parse("geo:${poi.latitude},${poi.longitude}?q=${Uri.encode(query)}")
    val mapIntent = Intent(Intent.ACTION_VIEW, uri)
    mapIntent.setPackage("com.google.android.apps.maps")
    
    // Fallback to generic map intent if Google Maps not available
    if (mapIntent.resolveActivity(context.packageManager) != null) {
        context.startActivity(mapIntent)
    } else {
        val genericMapIntent = Intent(Intent.ACTION_VIEW, uri)
        context.startActivity(genericMapIntent)
    }
}

private fun callPOI(context: android.content.Context, poi: POIData) {
    poi.phoneNumber?.let { phoneNumber ->
        val cleanPhoneNumber = phoneNumber.filter { it.isDigit() || it == '+' }
        if (cleanPhoneNumber.isNotEmpty()) {
            val phoneUri = Uri.parse("tel:$cleanPhoneNumber")
            val callIntent = Intent(Intent.ACTION_DIAL, phoneUri)
            context.startActivity(callIntent)
        }
    }
}