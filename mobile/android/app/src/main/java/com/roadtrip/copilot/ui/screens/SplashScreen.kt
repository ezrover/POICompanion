package com.roadtrip.copilot.ui.screens

import androidx.compose.animation.core.*
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.roadtrip.copilot.R
import com.roadtrip.copilot.ai.Gemma3NProcessor
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@Composable
fun SplashScreen(
    onLoadingComplete: () -> Unit
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    
    // Initialize Gemma3N processor
    val gemmaProcessor = remember { Gemma3NProcessor(context) }
    
    // Collect states
    val isModelLoaded by gemmaProcessor.isModelLoaded.collectAsState()
    val loadingProgress by gemmaProcessor.loadingProgress.collectAsState()
    val loadingStatus by gemmaProcessor.loadingStatus.collectAsState()
    val modelVariant by gemmaProcessor.modelVariant.collectAsState()
    
    // Loading states
    var loadingFailed by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf("") }
    
    // Animation state
    val infiniteTransition = rememberInfiniteTransition(label = "logo_rotation")
    val rotation by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 360f,
        animationSpec = infiniteRepeatable(
            animation = tween(1500, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "rotation"
    )
    
    // Start loading on first composition
    LaunchedEffect(Unit) {
        startLoading(
            gemmaProcessor = gemmaProcessor,
            onSuccess = {
                scope.launch {
                    // Wait a moment to show success state
                    delay(500)
                    onLoadingComplete()
                }
            },
            onError = { error ->
                loadingFailed = true
                errorMessage = error.message ?: "Unknown error occurred"
            }
        )
    }
    
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
            modifier = Modifier.padding(horizontal = 24.dp)
        ) {
            Spacer(modifier = Modifier.weight(1f))
            
            // Logo with rotation animation
            Box(
                modifier = Modifier
                    .size(150.dp)
                    .rotate(if (loadingFailed) 0f else rotation),
                contentAlignment = Alignment.Center
            ) {
                Image(
                    painter = painterResource(id = R.drawable.app_logo),
                    contentDescription = "Roadtrip Copilot Logo",
                    modifier = Modifier.fillMaxSize()
                )
            }
            
            Spacer(modifier = Modifier.weight(1f))
            
            // Loading status section
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.padding(bottom = 40.dp)
            ) {
                // Status text
                Text(
                    text = loadingStatus,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.padding(bottom = 12.dp)
                )
                
                // Progress bar
                if (loadingProgress > 0 && loadingProgress < 1 && !loadingFailed) {
                    LinearProgressIndicator(
                        progress = { loadingProgress.toFloat() },
                        modifier = Modifier
                            .fillMaxWidth(0.6f)
                            .height(4.dp),
                        color = MaterialTheme.colorScheme.primary,
                        trackColor = MaterialTheme.colorScheme.surfaceVariant
                    )
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    // Progress percentage
                    Text(
                        text = "${(loadingProgress * 100).toInt()}%",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                
                // Model variant info when loaded
                if (isModelLoaded) {
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    Row(
                        horizontalArrangement = Arrangement.Center,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            painter = painterResource(id = android.R.drawable.checkbox_on_background),
                            contentDescription = "Success",
                            tint = Color.Green,
                            modifier = Modifier.size(16.dp)
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(
                            text = "Gemma-3N ${modelVariant.modelName} ready",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
                
                // Error state
                if (loadingFailed) {
                    Card(
                        modifier = Modifier
                            .fillMaxWidth(0.8f)
                            .padding(top = 16.dp),
                        colors = CardDefaults.cardColors(
                            containerColor = MaterialTheme.colorScheme.errorContainer
                        )
                    ) {
                        Column(
                            modifier = Modifier.padding(16.dp),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(
                                    painter = painterResource(id = android.R.drawable.ic_dialog_alert),
                                    contentDescription = "Error",
                                    tint = MaterialTheme.colorScheme.error,
                                    modifier = Modifier.size(20.dp)
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(
                                    text = "Failed to load AI model",
                                    style = MaterialTheme.typography.labelMedium,
                                    color = MaterialTheme.colorScheme.error,
                                    fontWeight = FontWeight.SemiBold
                                )
                            }
                            
                            Spacer(modifier = Modifier.height(8.dp))
                            
                            Text(
                                text = errorMessage,
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onErrorContainer,
                                textAlign = TextAlign.Center
                            )
                            
                            Spacer(modifier = Modifier.height(12.dp))
                            
                            Button(
                                onClick = {
                                    loadingFailed = false
                                    errorMessage = ""
                                    scope.launch {
                                        retryLoading(
                                            gemmaProcessor = gemmaProcessor,
                                            onSuccess = {
                                                scope.launch {
                                                    delay(500)
                                                    onLoadingComplete()
                                                }
                                            },
                                            onError = { error ->
                                                loadingFailed = true
                                                errorMessage = error.message ?: "Unknown error occurred"
                                            }
                                        )
                                    }
                                },
                                colors = ButtonDefaults.buttonColors(
                                    containerColor = MaterialTheme.colorScheme.error
                                )
                            ) {
                                Icon(
                                    painter = painterResource(id = android.R.drawable.ic_popup_sync),
                                    contentDescription = "Retry",
                                    modifier = Modifier.size(16.dp)
                                )
                                Spacer(modifier = Modifier.width(4.dp))
                                Text(
                                    text = "Retry",
                                    style = MaterialTheme.typography.labelMedium
                                )
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Clean up when composable leaves composition
    DisposableEffect(Unit) {
        onDispose {
            gemmaProcessor.cleanup()
        }
    }
}

private suspend fun startLoading(
    gemmaProcessor: Gemma3NProcessor,
    onSuccess: () -> Unit,
    onError: (Exception) -> Unit
) {
    try {
        gemmaProcessor.loadModel()
        onSuccess()
    } catch (e: Exception) {
        onError(e)
    }
}

private suspend fun retryLoading(
    gemmaProcessor: Gemma3NProcessor,
    onSuccess: () -> Unit,
    onError: (Exception) -> Unit
) {
    try {
        gemmaProcessor.loadModel()
        onSuccess()
    } catch (e: Exception) {
        onError(e)
    }
}