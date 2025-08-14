package com.roadtrip.copilot.managers

import androidx.lifecycle.ViewModel
import com.roadtrip.copilot.models.POIData
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject

@HiltViewModel
class AIAgentManager @Inject constructor() : ViewModel() {
    
    private val coroutineScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    
    private val _currentPOI = MutableStateFlow<POIData?>(null)
    val currentPOI: StateFlow<POIData?> = _currentPOI.asStateFlow()
    
    private val _isDiscovering = MutableStateFlow(false)
    val isDiscovering: StateFlow<Boolean> = _isDiscovering.asStateFlow()
    
    private val _discoveredPOIs = MutableStateFlow<List<POIData>>(emptyList())
    val discoveredPOIs: StateFlow<List<POIData>> = _discoveredPOIs.asStateFlow()
    
    private var currentPOIIndex = 0
    private var backgroundJob: Job? = null
    
    fun startBackgroundAgents() {
        _isDiscovering.value = true
        
        backgroundJob = coroutineScope.launch {
            // Simulate continuous POI discovery
            while (isActive) {
                delay(10000) // Discovery every 10 seconds
                discoverNewPOI()
            }
        }
        
        println("Background AI agents started")
    }
    
    fun stopBackgroundAgents() {
        backgroundJob?.cancel()
        _isDiscovering.value = false
        println("Background AI agents stopped")
    }
    
    private suspend fun discoverNewPOI() {
        // Simulate AI-discovered POI
        val newPOI = generateSimulatedPOI()
        
        val updatedList = _discoveredPOIs.value.toMutableList()
        updatedList.add(newPOI)
        _discoveredPOIs.value = updatedList
        
        // Update current POI if none selected
        if (_currentPOI.value == null) {
            _currentPOI.value = newPOI
        }
        
        println("Discovered new POI: ${newPOI.name}")
    }
    
    private fun generateSimulatedPOI(): POIData {
        val samplePOIs = listOf(
            POIData(
                id = "poi_${System.currentTimeMillis()}",
                name = "Seaside Café",
                description = "Charming beachside café with ocean views",
                category = "restaurant",
                latitude = 37.7749 + (Math.random() - 0.5) * 0.1,
                longitude = -122.4194 + (Math.random() - 0.5) * 0.1,
                distanceFromUser = Math.random() * 10.0,
                rating = 4.0 + Math.random(),
                imageURL = "https://example.com/cafe.jpg",
                reviewSummary = "Great coffee and pastries with stunning ocean views",
                couldEarnRevenue = Math.random() > 0.7
            ),
            POIData(
                id = "poi_${System.currentTimeMillis()}",
                name = "Hidden Waterfall",
                description = "Secret waterfall accessible by short hiking trail",
                category = "attraction",
                latitude = 37.7749 + (Math.random() - 0.5) * 0.1,
                longitude = -122.4194 + (Math.random() - 0.5) * 0.1,
                distanceFromUser = Math.random() * 15.0,
                rating = 4.5 + Math.random() * 0.5,
                imageURL = "https://example.com/waterfall.jpg",
                reviewSummary = "Beautiful hidden gem, perfect for nature lovers",
                couldEarnRevenue = Math.random() > 0.8
            ),
            POIData(
                id = "poi_${System.currentTimeMillis()}",
                name = "Vintage Gas Station",
                description = "Historic Route 66 gas station turned museum",
                category = "gas_station",
                latitude = 37.7749 + (Math.random() - 0.5) * 0.1,
                longitude = -122.4194 + (Math.random() - 0.5) * 0.1,
                distanceFromUser = Math.random() * 8.0,
                rating = 4.2 + Math.random() * 0.8,
                imageURL = "https://example.com/vintage_gas.jpg",
                reviewSummary = "Nostalgic stop with great photo opportunities",
                couldEarnRevenue = Math.random() > 0.6
            )
        )
        
        return samplePOIs.random().copy(
            id = "poi_${System.currentTimeMillis()}_${Math.random().hashCode()}"
        )
    }
    
    fun favoriteCurrentPOI() {
        _currentPOI.value?.let { poi ->
            println("Favorited POI: ${poi.name}")
            // In a real app, save to user favorites
        }
    }
    
    fun likeCurrentPOI() {
        _currentPOI.value?.let { poi ->
            println("Liked POI: ${poi.name}")
            // In a real app, update user preferences
        }
    }
    
    fun dislikeCurrentPOI() {
        _currentPOI.value?.let { poi ->
            println("Disliked POI: ${poi.name}")
            // In a real app, update user preferences
            nextPOI() // Automatically move to next
        }
    }
    
    fun nextPOI() {
        val pois = _discoveredPOIs.value
        if (pois.isNotEmpty()) {
            currentPOIIndex = (currentPOIIndex + 1) % pois.size
            _currentPOI.value = pois[currentPOIIndex]
            println("Moved to next POI: ${pois[currentPOIIndex].name}")
        }
    }
    
    fun previousPOI() {
        val pois = _discoveredPOIs.value
        if (pois.isNotEmpty()) {
            currentPOIIndex = if (currentPOIIndex > 0) currentPOIIndex - 1 else pois.size - 1
            _currentPOI.value = pois[currentPOIIndex]
            println("Moved to previous POI: ${pois[currentPOIIndex].name}")
        }
    }
    
    override fun onCleared() {
        super.onCleared()
        stopBackgroundAgents()
    }
}