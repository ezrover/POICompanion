package com.roadtrip.copilot.ui.components

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.graphics.*
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import kotlin.math.*
import kotlin.random.Random

@Composable
fun VoiceVisualizerView(
    isListening: Boolean,
    isSpeaking: Boolean,
    onTap: () -> Unit,
    modifier: Modifier = Modifier
) {
    var waveformData by remember { mutableStateOf(List(64) { 0.3f }) }
    var glowIntensity by remember { mutableStateOf(0.5f) }
    
    // Pulse animation
    val pulseAnimation by rememberInfiniteTransition(label = "pulse").animateFloat(
        initialValue = 1.0f,
        targetValue = 1.05f,
        animationSpec = infiniteRepeatable(
            animation = tween(2000, easing = EaseInOut),
            repeatMode = RepeatMode.Reverse
        ), label = "pulse"
    )
    
    // Scale animation for listening/speaking
    val scaleAnimation by animateFloatAsState(
        targetValue = if (isListening || isSpeaking) 1.1f else 1.0f,
        animationSpec = tween(300, easing = EaseInOut), label = "scale"
    )
    
    // Update waveform data
    LaunchedEffect(isListening, isSpeaking) {
        while (isListening || isSpeaking) {
            waveformData = updateWaveformData(waveformData, isListening, isSpeaking)
            glowIntensity = if (isListening || isSpeaking) {
                0.8f + Random.nextFloat() * 0.2f
            } else {
                0.3f
            }
            delay(50) // 20 FPS update rate
        }
    }
    
    Box(
        modifier = modifier
            .size(300.dp)
            .clickable { onTap() },
        contentAlignment = Alignment.Center
    ) {
        // Background gradient
        Box(
            modifier = Modifier
                .size(300.dp)
                .clip(CircleShape)
                .background(
                    Brush.radialGradient(
                        colors = listOf(
                            Color.Black.copy(alpha = 0.9f),
                            Color.Blue.copy(alpha = 0.1f),
                            Color.Black.copy(alpha = 0.95f)
                        ),
                        radius = 200f
                    )
                )
        )
        
        // Outer glow rings
        repeat(3) { index ->
            GlowRing(
                size = (200 + index * 20).dp,
                opacity = if (isListening || isSpeaking) (0.8f - index * 0.2f) else 0.2f,
                scale = pulseAnimation + index * 0.05f,
                delay = index * 300
            )
        }
        
        // Main orb
        Box(
            modifier = Modifier
                .size(180.dp)
                .scale(scaleAnimation)
                .clip(CircleShape)
                .background(
                    Brush.radialGradient(
                        colors = listOf(
                            Color.Blue.copy(alpha = 0.3f),
                            Color.Magenta.copy(alpha = 0.5f),
                            Color.Black.copy(alpha = 0.8f)
                        ),
                        center = Offset(0.3f, 0.3f)
                    )
                ),
            contentAlignment = Alignment.Center
        ) {
            // Glass reflection overlay
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(
                        Brush.linearGradient(
                            colors = listOf(
                                Color.White.copy(alpha = 0.3f),
                                Color.Transparent,
                                Color.Transparent,
                                Color.White.copy(alpha = 0.1f)
                            ),
                            start = Offset(0f, 0f),
                            end = Offset(1f, 1f)
                        )
                    )
            )
            
            // Waveform or idle state
            if (isListening || isSpeaking) {
                WaveformDisplay(
                    waveformData = waveformData,
                    isListening = isListening,
                    isSpeaking = isSpeaking,
                    modifier = Modifier.size(140.dp, 80.dp)
                )
            } else {
                // Idle pulse
                Box(
                    modifier = Modifier
                        .size(20.dp)
                        .scale(pulseAnimation)
                        .clip(CircleShape)
                        .background(
                            Brush.radialGradient(
                                colors = listOf(
                                    Color.Blue.copy(alpha = 0.6f),
                                    Color.Blue.copy(alpha = 0.3f),
                                    Color.Transparent
                                )
                            )
                        )
                )
            }
            
            // Microphone icon (when listening)
            if (isListening) {
                Icon(
                    imageVector = Icons.Default.Mic,
                    contentDescription = "Listening",
                    tint = Color.White.copy(alpha = 0.8f),
                    modifier = Modifier
                        .size(24.dp)
                        .offset(y = 60.dp)
                        .scale(1.2f)
                )
            }
        }
        
        // Status text
        Column(
            modifier = Modifier.align(Alignment.BottomCenter),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            AnimatedVisibility(
                visible = isListening || isSpeaking || true,
                enter = fadeIn() + slideInVertically(),
                exit = fadeOut() + slideOutVertically()
            ) {
                Text(
                    text = when {
                        isListening -> "Listening..."
                        isSpeaking -> "Speaking..."
                        else -> "Tap to speak"
                    },
                    color = if (isListening || isSpeaking) Color.White else Color.Gray,
                    fontSize = if (isListening || isSpeaking) 18.sp else 14.sp,
                    fontWeight = if (isListening || isSpeaking) FontWeight.SemiBold else FontWeight.Normal
                )
            }
            
            Spacer(modifier = Modifier.height(40.dp))
        }
    }
}

@Composable
private fun GlowRing(
    size: Dp,
    opacity: Float,
    scale: Float,
    delay: Int
) {
    val animatedOpacity by rememberInfiniteTransition(label = "glow").animateFloat(
        initialValue = opacity * 0.5f,
        targetValue = opacity,
        animationSpec = infiniteRepeatable(
            animation = tween(2000, easing = EaseInOut, delayMillis = delay),
            repeatMode = RepeatMode.Reverse
        ), label = "glow_opacity"
    )
    
    Box(
        modifier = Modifier
            .size(size = size)
            .scale(scale)
            .clip(CircleShape)
            .background(
                Brush.radialGradient(
                    colors = listOf(
                        Color.Blue.copy(alpha = animatedOpacity * 0.3f),
                        Color.Magenta.copy(alpha = animatedOpacity * 0.2f),
                        Color.Transparent
                    )
                )
            )
    )
}

@Composable
private fun WaveformDisplay(
    waveformData: List<Float>,
    isListening: Boolean,
    isSpeaking: Boolean,
    modifier: Modifier = Modifier
) {
    val barCount = 32
    val density = LocalDensity.current
    
    Canvas(modifier = modifier) {
        val barWidth = size.width / barCount
        val barSpacing = barWidth * 0.3f
        val actualBarWidth = barWidth - barSpacing
        val centerY = size.height / 2f
        val maxBarHeight = size.height * 0.8f
        
        for (i in 0 until barCount) {
            val dataIndex = (i * waveformData.size / barCount).coerceAtMost(waveformData.size - 1)
            val amplitude = waveformData[dataIndex].coerceIn(0f, 1f)
            
            val barHeight = 8f + (maxBarHeight - 8f) * amplitude
            val x = i * barWidth + barSpacing / 2f
            val y = centerY - barHeight / 2f
            
            // Create gradient colors based on state
            val colors = when {
                isListening -> listOf(
                    Color.Blue.copy(alpha = 0.6f + amplitude * 0.4f),
                    Color.Cyan.copy(alpha = 0.8f + amplitude * 0.2f),
                    Color.White.copy(alpha = amplitude)
                )
                isSpeaking -> listOf(
                    Color.Magenta.copy(alpha = 0.6f + amplitude * 0.4f),
                    Color(0xFFFF6B9D).copy(alpha = 0.8f + amplitude * 0.2f), // Pink
                    Color.White.copy(alpha = amplitude)
                )
                else -> listOf(
                    Color.Gray.copy(alpha = 0.3f),
                    Color.Gray.copy(alpha = 0.5f),
                    Color.Gray.copy(alpha = 0.2f)
                )
            }
            
            drawRoundedBar(
                x = x,
                y = y,
                width = actualBarWidth,
                height = barHeight,
                colors = colors
            )
        }
    }
}

private fun DrawScope.drawRoundedBar(
    x: Float,
    y: Float,
    width: Float,
    height: Float,
    colors: List<Color>
) {
    val brush = Brush.verticalGradient(
        colors = colors,
        startY = y + height,
        endY = y
    )
    
    drawRoundRect(
        brush = brush,
        topLeft = Offset(x, y),
        size = androidx.compose.ui.geometry.Size(width, height),
        cornerRadius = androidx.compose.ui.geometry.CornerRadius(2.dp.toPx())
    )
}

private fun updateWaveformData(
    currentData: List<Float>,
    isListening: Boolean,
    isSpeaking: Boolean
): List<Float> {
    val time = System.currentTimeMillis() / 1000.0
    
    return currentData.mapIndexed { index, _ ->
        when {
            isListening -> {
                // Listening animation - responsive to input
                Random.nextFloat() * (0.2f + 0.6f * (1f + 0.3f * sin(time * 8 + index * 0.5)).toFloat())
            }
            isSpeaking -> {
                // Speaking animation - more varied
                val frequency = 5.0 + index * 0.1
                val amplitude = 0.5 + 0.4 * sin(time * 3 + index * 0.3)
                (0.3f + amplitude * sin(time * frequency)).toFloat().coerceIn(0f, 1f)
            }
            else -> {
                // Idle state
                Random.nextFloat() * 0.3f
            }
        }
    }
}

