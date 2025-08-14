package com.roadtrip.copilot.ui.components

import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.unit.dp
import kotlin.math.*
import kotlin.random.Random

@Composable
fun ListeningAnimation(modifier: Modifier = Modifier) {
    val infiniteTransition = rememberInfiniteTransition(label = "listening")
    
    // Multiple pulsing circles
    repeat(3) { index ->
        val scale by infiniteTransition.animateFloat(
            initialValue = 1f,
            targetValue = 1.3f,
            animationSpec = infiniteRepeatable(
                animation = tween(1000, easing = EaseInOut, delayMillis = index * 200),
                repeatMode = RepeatMode.Reverse
            ), label = "listening_scale_$index"
        )
        
        val alpha by infiniteTransition.animateFloat(
            initialValue = 0.7f,
            targetValue = 0f,
            animationSpec = infiniteRepeatable(
                animation = tween(1000, easing = EaseInOut, delayMillis = index * 200),
                repeatMode = RepeatMode.Reverse
            ), label = "listening_alpha_$index"
        )
        
        Box(
            modifier = Modifier
                .size((60 + index * 20).dp)
                .scale(scale)
                .clip(CircleShape),
            contentAlignment = Alignment.Center
        ) {
            Canvas(
                modifier = Modifier.fillMaxSize()
            ) {
                drawCircle(
                    color = Color.Blue.copy(alpha = alpha),
                    radius = size.minDimension / 2f,
                    style = androidx.compose.ui.graphics.drawscope.Stroke(width = 3.dp.toPx())
                )
            }
        }
    }
    
    // Central microphone icon effect
    val pulseScale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 1.2f,
        animationSpec = infiniteRepeatable(
            animation = tween(800, easing = EaseInOut),
            repeatMode = RepeatMode.Reverse
        ), label = "mic_pulse"
    )
    
    Box(
        modifier = modifier,
        contentAlignment = Alignment.Center
    ) {
        Box(
            modifier = Modifier
                .size(24.dp)
                .scale(pulseScale)
                .clip(CircleShape)
        ) {
            Canvas(modifier = Modifier.fillMaxSize()) {
                drawCircle(
                    color = Color.Blue,
                    radius = size.minDimension / 2f
                )
            }
        }
    }
}

@Composable
fun SpeakingAnimation(modifier: Modifier = Modifier) {
    var barHeights by remember { mutableStateOf(List(5) { 10f }) }
    
    LaunchedEffect(Unit) {
        while (true) {
            barHeights = List(5) { Random.nextFloat() * 20 + 8 }
            kotlinx.coroutines.delay(80)
        }
    }
    
    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(3.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        barHeights.forEachIndexed { index, height ->
            val animatedHeight by animateFloatAsState(
                targetValue = height,
                animationSpec = tween(300, easing = EaseInOut, delayMillis = index * 50), 
                label = "bar_height_$index"
            )
            
            Canvas(
                modifier = Modifier
                    .width(4.dp)
                    .height(animatedHeight.dp)
            ) {
                drawRoundRect(
                    color = Color.Green,
                    cornerRadius = androidx.compose.ui.geometry.CornerRadius(2.dp.toPx())
                )
            }
        }
    }
}

@Composable
fun PulsingCircle(
    color: Color,
    maxRadius: Float,
    animationDuration: Int = 2000,
    modifier: Modifier = Modifier
) {
    val infiniteTransition = rememberInfiniteTransition(label = "pulse")
    
    val radius by infiniteTransition.animateFloat(
        initialValue = maxRadius * 0.3f,
        targetValue = maxRadius,
        animationSpec = infiniteRepeatable(
            animation = tween(animationDuration, easing = EaseInOut),
            repeatMode = RepeatMode.Reverse
        ), label = "pulse_radius"
    )
    
    val alpha by infiniteTransition.animateFloat(
        initialValue = 0.8f,
        targetValue = 0.1f,
        animationSpec = infiniteRepeatable(
            animation = tween(animationDuration, easing = EaseInOut),
            repeatMode = RepeatMode.Reverse
        ), label = "pulse_alpha"
    )
    
    Canvas(modifier = modifier) {
        drawCircle(
            color = color.copy(alpha = alpha),
            radius = radius
        )
    }
}

@Composable
fun WaveformBar(
    height: Float,
    color: Color,
    animationDuration: Int = 100,
    modifier: Modifier = Modifier
) {
    val animatedHeight by animateFloatAsState(
        targetValue = height,
        animationSpec = tween(animationDuration, easing = EaseInOut), label = "waveform_height"
    )
    
    Canvas(
        modifier = modifier
            .width(3.dp)
            .height(animatedHeight.dp)
    ) {
        drawRoundRect(
            color = color,
            cornerRadius = androidx.compose.ui.geometry.CornerRadius(1.5.dp.toPx())
        )
    }
}

@Composable
fun GlowEffect(
    isActive: Boolean,
    glowColor: Color = Color.Blue,
    modifier: Modifier = Modifier
) {
    val alpha by animateFloatAsState(
        targetValue = if (isActive) 0.6f else 0.1f,
        animationSpec = tween(300, easing = EaseInOut), label = "glow_alpha"
    )
    
    val scale by animateFloatAsState(
        targetValue = if (isActive) 1.2f else 1f,
        animationSpec = tween(300, easing = EaseInOut), label = "glow_scale"
    )
    
    Box(
        modifier = modifier
            .scale(scale)
            .clip(CircleShape)
    ) {
        Canvas(modifier = Modifier.fillMaxSize()) {
            drawCircle(
                color = glowColor.copy(alpha = alpha),
                radius = size.minDimension / 2f
            )
        }
    }
}