package com.roadtrip.copilot.ui.screens

import android.content.Intent
import android.net.Uri
import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.roadtrip.copilot.design.DesignTokens
import com.roadtrip.copilot.managers.SpeechManager
import kotlinx.coroutines.delay

/**
 * POI Result Screen - Platform Parity with iOS POIResultView
 * Displays Gemma-3N response about the destination and automatically speaks it
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun POIResultScreen(
    destinationName: String,
    destinationAddress: String?,
    gemmaResponse: String,
    onBack: () -> Unit
) {
    val context = LocalContext.current
    val speechManager = remember { SpeechManager() }
    val scrollState = rememberScrollState()
    
    // UI State
    var isReading by remember { mutableStateOf(false) }
    var hasSpokenResponse by remember { mutableStateOf(false) }
    
    // Speech manager states
    val isSpeaking by speechManager.isSpeaking.collectAsState()
    
    // Initialize speech manager
    LaunchedEffect(Unit) {
        speechManager.initialize(context)
    }
    
    // Auto-speak the response when screen loads (Platform Parity with iOS)
    LaunchedEffect(Unit) {
        if (!hasSpokenResponse) {
            delay(500) // Brief delay to let screen settle
            speechManager.speak(gemmaResponse)
            hasSpokenResponse = true
        }
    }
    
    // Update reading state based on speech manager
    LaunchedEffect(isSpeaking) {
        isReading = isSpeaking
    }
    
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
    ) {
        // Top App Bar
        TopAppBar(
            title = { 
                Text(
                    "Destination Info",
                    fontWeight = FontWeight.Medium
                )
            },
            navigationIcon = {
                IconButton(onClick = onBack) {
                    Icon(
                        Icons.Default.ArrowBack,
                        contentDescription = "Back"
                    )
                }
            },
            colors = TopAppBarDefaults.topAppBarColors(
                containerColor = MaterialTheme.colorScheme.surface
            )
        )
        
        // Content
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(scrollState)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            // Destination Header Card
            Card(
                modifier = Modifier.fillMaxWidth(),
                elevation = CardDefaults.cardElevation(defaultElevation = 4.dp),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.surface
                )
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Text(
                        text = destinationName,
                        style = MaterialTheme.typography.headlineMedium,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    
                    destinationAddress?.let { address ->
                        Text(
                            text = address,
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            lineHeight = 20.sp
                        )
                    }
                }
            }
            
            // AI Response Card
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.secondaryContainer
                )
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
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
                            color = MaterialTheme.colorScheme.onSecondaryContainer
                        )
                        
                        Spacer(modifier = Modifier.weight(1f))
                        
                        // Audio indicator - Platform Parity with iOS
                        AnimatedVisibility(
                            visible = isReading,
                            enter = fadeIn(),
                            exit = fadeOut()
                        ) {
                            Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                                repeat(3) { index ->
                                    val animatedScale by animateFloatAsState(
                                        targetValue = if (isReading) 1.0f else 0.5f,
                                        animationSpec = infiniteRepeatable(
                                            animation = tween<Float>(500),
                                            repeatMode = RepeatMode.Reverse
                                        ),
                                        label = "audio_indicator_$index"
                                    )
                                    
                                    Box(
                                        modifier = Modifier
                                            .size(6.dp)
                                            .clip(RoundedCornerShape(50))
                                            .background(MaterialTheme.colorScheme.primary)
                                            .then(
                                                if (isReading) Modifier.size((6 * animatedScale).dp)
                                                else Modifier
                                            )
                                    )
                                }
                            }
                        }
                    }
                    
                    // Response Text
                    Text(
                        text = gemmaResponse,
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onSecondaryContainer,
                        lineHeight = 24.sp
                    )
                    
                    // Audio Controls - Platform Parity with iOS
                    Row {
                        Button(
                            onClick = {
                                if (isReading) {
                                    speechManager.stopSpeaking()
                                } else {
                                    speechManager.speak(gemmaResponse)
                                }
                            },
                            colors = ButtonDefaults.buttonColors(
                                containerColor = MaterialTheme.colorScheme.primary
                            )
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
            
            Spacer(modifier = Modifier.weight(1f))
            
            // Action Buttons
            Column(
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                // Get Directions Button
                Button(
                    onClick = {
                        openInMaps(context, destinationName, destinationAddress)
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(56.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = MaterialTheme.colorScheme.primary
                    ),
                    shape = RoundedCornerShape(DesignTokens.CornerRadius.md)
                ) {
                    Icon(
                        Icons.Default.LocationOn,
                        contentDescription = "Get Directions",
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        "Get Directions",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold
                    )
                }
                
                // Back to Search Button
                OutlinedButton(
                    onClick = onBack,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(48.dp),
                    shape = RoundedCornerShape(DesignTokens.CornerRadius.md),
                    border = androidx.compose.foundation.BorderStroke(
                        width = 2.dp,
                        color = MaterialTheme.colorScheme.primary
                    )
                ) {
                    Text(
                        "Back to Search",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Medium,
                        color = MaterialTheme.colorScheme.primary
                    )
                }
            }
        }
    }
    
    // Cleanup speech when leaving screen
    DisposableEffect(Unit) {
        onDispose {
            speechManager.stopSpeaking()
        }
    }
}

private fun openInMaps(context: android.content.Context, destinationName: String, destinationAddress: String?) {
    val query = destinationAddress ?: destinationName
    val uri = Uri.parse("geo:0,0?q=${Uri.encode(query)}")
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