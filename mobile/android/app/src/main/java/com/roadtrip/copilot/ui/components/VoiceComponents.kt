package com.roadtrip.copilot.ui.components

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import com.roadtrip.copilot.design.DesignTokens
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.geometry.center
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.delay
import kotlin.math.*

// CRITICAL PLATFORM PARITY FIX: Large secondary speech animation removed for iOS parity
// This component was causing UX inconsistency between iOS and Android
/*
@Composable
fun EnhancedVoiceVisualizerOverlay(
    isListening: Boolean,
    isSpeaking: Boolean,
    onTap: () -> Unit,
    modifier: Modifier = Modifier
) {
    val density = LocalDensity.current
    var amplitude by remember { mutableStateOf(0.5f) }
    
    LaunchedEffect(isListening, isSpeaking) {
        if (isListening || isSpeaking) {
            while (true) {
                // Reduced amplitude variation for smoother animation
                amplitude = 0.4f + (kotlin.random.Random.nextFloat() * 0.4f)
                delay(150) // Slightly slower updates to reduce computational load
            }
        } else {
            amplitude = 0.1f
        }
    }
    
    Box(
        modifier = modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        // Animated background waves
        VoiceWaveAnimation(
            isActive = isListening || isSpeaking,
            amplitude = amplitude,
            color = if (isListening) 
                MaterialTheme.colorScheme.primary.copy(alpha = 0.3f)
            else 
                MaterialTheme.colorScheme.secondary.copy(alpha = 0.3f)
        )
        
        // Center microphone button
        FloatingActionButton(
            onClick = onTap,
            modifier = Modifier.size(80.dp),
            containerColor = if (isListening) 
                MaterialTheme.colorScheme.error 
            else 
                MaterialTheme.colorScheme.primary
        ) {
            Icon(
                imageVector = Icons.Default.Mic,
                contentDescription = if (isListening) "Stop listening" else "Start listening",
                modifier = Modifier.size(32.dp),
                tint = Color.White
            )
        }
        
        // Status text
        if (isListening || isSpeaking) {
            Text(
                text = if (isListening) "Listening..." else "Speaking...",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurface,
                modifier = Modifier
                    .padding(top = 120.dp)
                    .background(
                        Color.Black.copy(alpha = 0.7f),
                        RoundedCornerShape(DesignTokens.CornerRadius.lg)
                    )
                    .padding(horizontal = 16.dp, vertical = 8.dp)
            )
        }
    }
}
*/

@Composable
fun VoiceWaveAnimation(
    isActive: Boolean,
    amplitude: Float,
    color: Color,
    modifier: Modifier = Modifier
) {
    val infiniteTransition = rememberInfiniteTransition(label = "voice_wave_animation")
    
    // Reduced animation complexity for better performance
    val primaryWaveScale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = if (isActive) 1f + (amplitude * 0.5f).coerceAtMost(0.3f) else 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(900, easing = EaseInOut),
            repeatMode = RepeatMode.Reverse
        ),
        label = "primary_wave"
    )
    
    val secondaryWaveScale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = if (isActive) 1f + (amplitude * 0.3f).coerceAtMost(0.2f) else 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(1100, easing = EaseInOut),
            repeatMode = RepeatMode.Reverse
        ),
        label = "secondary_wave"
    )
    
    // Optimize Canvas rendering with stable calculations
    Canvas(
        modifier = modifier.size(180.dp) // Slightly smaller for better performance
    ) {
        val center = size.center
        val baseRadius = size.minDimension / 8
        
        // Draw optimized concentric circles with stable alpha values
        drawCircle(
            color = color.copy(alpha = 0.2f),
            radius = baseRadius * 2f * primaryWaveScale,
            center = center
        )
        
        drawCircle(
            color = color.copy(alpha = 0.3f),
            radius = baseRadius * 1.5f * secondaryWaveScale,
            center = center
        )
        
        // Center circle for visual stability
        drawCircle(
            color = color.copy(alpha = 0.5f),
            radius = baseRadius,
            center = center
        )
    }
}

/**
 * Voice Animation Component matching design spec requirements
 * Shows animated sound waves during speech detection
 * Follows Material Design 3 patterns and accessibility guidelines
 */
@Composable
fun VoiceAnimationComponent(
    isActive: Boolean,
    modifier: Modifier = Modifier,
    color: Color = Color.White,
    waveCount: Int = 5
) {
    // Stable key for recomposition optimization
    val animationKey = remember(isActive) { isActive }
    
    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(2.dp, Alignment.CenterHorizontally),
        verticalAlignment = Alignment.CenterVertically
    ) {
        repeat(waveCount) { index ->
            key("wave_bar_$index") {
                VoiceWaveBar(
                    isActive = animationKey,
                    delay = index * 80, // Slightly faster for smoother appearance
                    color = color
                )
            }
        }
    }
}

@Composable
private fun VoiceWaveBar(
    isActive: Boolean,
    delay: Int,
    color: Color
) {
    val infiniteTransition = rememberInfiniteTransition(label = "voice_wave_bar_$delay")
    
    // Smooth height animation with reduced computational overhead
    val height by infiniteTransition.animateFloat(
        initialValue = 4.dp.value,
        targetValue = if (isActive) (16 + (delay / 40).coerceAtMost(4)).dp.value else 4.dp.value,
        animationSpec = infiniteRepeatable(
            animation = tween(
                durationMillis = 600, // Faster animation for responsiveness
                delayMillis = delay,
                easing = FastOutSlowInEasing
            ),
            repeatMode = RepeatMode.Reverse
        ),
        label = "wave_bar_height_$delay"
    )
    
    // Simplified alpha animation to reduce recomposition
    val alpha by infiniteTransition.animateFloat(
        initialValue = 0.7f,
        targetValue = if (isActive) 1.0f else 0.7f,
        animationSpec = infiniteRepeatable(
            animation = tween(
                durationMillis = 600,
                delayMillis = delay,
                easing = LinearEasing // Smoother for alpha changes
            ),
            repeatMode = RepeatMode.Reverse
        ),
        label = "wave_bar_alpha_$delay"
    )
    
    // Optimized rendering with stable modifier
    Box(
        modifier = Modifier
            .width(3.dp)
            .height(height.dp)
            .clip(RoundedCornerShape(1.5.dp))
            .background(color.copy(alpha = alpha))
    )
}

/**
 * Reduced Motion Alternative for Voice Animation
 * Provides static alternative for users with motion sensitivity
 */
@Composable
fun VoiceAnimationReducedMotion(
    isActive: Boolean,
    modifier: Modifier = Modifier,
    color: Color = Color.White
) {
    val alpha by animateFloatAsState(
        targetValue = if (isActive) 1.0f else 0.6f,
        animationSpec = tween(300),
        label = "voice_icon_alpha"
    )
    
    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(2.dp, Alignment.CenterHorizontally),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Static bars that just fade in/out
        repeat(5) {
            Box(
                modifier = Modifier
                    .width(3.dp)
                    .height((8 + it * 2).dp)
                    .clip(RoundedCornerShape(2.dp))
                    .background(color.copy(alpha = alpha))
            )
        }
    }
}