package com.roadtrip.copilot.managers

import androidx.lifecycle.ViewModel
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.concurrent.TimeUnit
import javax.inject.Inject

@HiltViewModel
class RoadtripSessionManager @Inject constructor() : ViewModel() {
    
    private val _isSessionActive = MutableStateFlow(false)
    val isSessionActive: StateFlow<Boolean> = _isSessionActive.asStateFlow()
    
    private val _sessionStartTime = MutableStateFlow(0L)
    val sessionStartTime: StateFlow<Long> = _sessionStartTime.asStateFlow()
    
    private val _elapsedTime = MutableStateFlow(0L)
    val elapsedTime: StateFlow<Long> = _elapsedTime.asStateFlow()
    
    private val _milesDiscovered = MutableStateFlow(0.0)
    val milesDiscovered: StateFlow<Double> = _milesDiscovered.asStateFlow()
    
    private val _poisDiscovered = MutableStateFlow(0)
    val poisDiscovered: StateFlow<Int> = _poisDiscovered.asStateFlow()
    
    fun startSession() {
        _isSessionActive.value = true
        _sessionStartTime.value = System.currentTimeMillis()
        _elapsedTime.value = 0L
        _milesDiscovered.value = 0.0
        _poisDiscovered.value = 0
        println("Roadtrip session started")
    }
    
    fun endSession() {
        _isSessionActive.value = false
        println("Roadtrip session ended after ${formatElapsedTime()}")
    }
    
    fun pauseSession() {
        // Keep session data but mark as inactive
        _isSessionActive.value = false
        println("Roadtrip session paused")
    }
    
    fun resumeSession() {
        // Resume session if there's existing session data
        if (_sessionStartTime.value != 0L) {
            _isSessionActive.value = true
            println("Roadtrip session resumed")
        }
    }
    
    fun updateElapsedTime() {
        if (_isSessionActive.value) {
            val currentTime = System.currentTimeMillis()
            _elapsedTime.value = currentTime - _sessionStartTime.value
        }
    }
    
    fun addMiles(miles: Double) {
        _milesDiscovered.value += miles
    }
    
    fun incrementPOICount() {
        _poisDiscovered.value += 1
    }
    
    fun formatElapsedTime(): String {
        val elapsed = _elapsedTime.value
        val hours = TimeUnit.MILLISECONDS.toHours(elapsed)
        val minutes = TimeUnit.MILLISECONDS.toMinutes(elapsed) % 60
        val seconds = TimeUnit.MILLISECONDS.toSeconds(elapsed) % 60
        
        return when {
            hours > 0 -> String.format("%d:%02d:%02d", hours, minutes, seconds)
            minutes > 0 -> String.format("%02d:%02d", minutes, seconds)
            else -> String.format("0:%02d", seconds)
        }
    }
    
    fun getSessionStats(): SessionStats {
        return SessionStats(
            duration = formatElapsedTime(),
            milesDiscovered = _milesDiscovered.value,
            poisDiscovered = _poisDiscovered.value,
            isActive = _isSessionActive.value
        )
    }
}

data class SessionStats(
    val duration: String,
    val milesDiscovered: Double,
    val poisDiscovered: Int,
    val isActive: Boolean
)