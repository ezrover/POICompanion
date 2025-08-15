package com.roadtrip.copilot.managers

import androidx.lifecycle.ViewModel
import com.roadtrip.copilot.models.POIData
import com.roadtrip.copilot.services.POIDiscoveryOrchestrator
import com.roadtrip.copilot.services.DiscoveryStrategy
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import android.location.Location
import javax.inject.Inject

@HiltViewModel
class AIAgentManager @Inject constructor(
    private val poiOrchestrator: POIDiscoveryOrchestrator
) : ViewModel() {
    
    private val coroutineScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    
    private val _currentPOI = MutableStateFlow<POIData?>(null)
    val currentPOI: StateFlow<POIData?> = _currentPOI.asStateFlow()
    
    private val _isDiscovering = MutableStateFlow(false)
    val isDiscovering: StateFlow<Boolean> = _isDiscovering.asStateFlow()
    
    private val _discoveredPOIs = MutableStateFlow<List<POIData>>(emptyList())
    val discoveredPOIs: StateFlow<List<POIData>> = _discoveredPOIs.asStateFlow()
    
    private var currentPOIIndex = 0
    private var backgroundJob: Job? = null
    private var lastKnownLocation: Location? = null
    
    fun startBackgroundAgents() {
        _isDiscovering.value = true
        
        backgroundJob = coroutineScope.launch {
            // CRITICAL FIX: Use real POI discovery instead of simulation
            while (isActive) {
                delay(10000) // Discovery every 10 seconds
                discoverNewPOI()
            }
        }
        
        println("Background AI agents started with real POI discovery")
    }
    
    fun updateLocation(location: Location) {
        lastKnownLocation = location
        println("Location updated: ${location.latitude}, ${location.longitude}")
    }
    
    fun stopBackgroundAgents() {
        backgroundJob?.cancel()
        _isDiscovering.value = false
        println("Background AI agents stopped")
    }
    
    private suspend fun discoverNewPOI() {
        // CRITICAL FIX: Use real POI discovery instead of mock data
        val location = lastKnownLocation
        if (location == null) {
            println("No location available for POI discovery")
            return
        }
        
        try {
            // Use POIDiscoveryOrchestrator for real POI discovery with hybrid LLM+API approach
            val categories = listOf("restaurant", "attraction", "gas_station", "hotel", "shopping")
            val category = categories.random()
            
            val discoveryResult = poiOrchestrator.discoverPOIs(
                location = location,
                category = category,
                strategy = DiscoveryStrategy.HYBRID,
                maxResults = 5
            )
            
            println("[AIAgentManager] POI Discovery completed in ${discoveryResult.responseTime}ms using ${discoveryResult.strategyUsed}")
            println("[AIAgentManager] Found ${discoveryResult.pois.size} POIs, fallback used: ${discoveryResult.fallbackUsed}")
            
            // Add discovered POIs to our list (avoiding duplicates)
            val currentPOIs = _discoveredPOIs.value.toMutableList()
            val existingIds = currentPOIs.map { it.id }.toSet()
            
            for (poi in discoveryResult.pois) {
                if (!existingIds.contains(poi.id)) {
                    currentPOIs.add(poi)
                    println("[AIAgentManager] Discovered new POI: ${poi.name} (${poi.category}) - Rating: ${poi.rating}★")
                }
            }
            
            _discoveredPOIs.value = currentPOIs
            
            // Update current POI if none selected
            if (_currentPOI.value == null && currentPOIs.isNotEmpty()) {
                _currentPOI.value = currentPOIs.first()
            }
            
        } catch (e: Exception) {
            println("[AIAgentManager] Real POI discovery failed: ${e.message}")
            // Fallback to basic discovery if all else fails
            val fallbackPOI = generateBasicFallbackPOI(location)
            
            val updatedList = _discoveredPOIs.value.toMutableList()
            updatedList.add(fallbackPOI)
            _discoveredPOIs.value = updatedList
            
            // Update current POI if none selected
            if (_currentPOI.value == null) {
                _currentPOI.value = fallbackPOI
            }
            
            println("[AIAgentManager] Using fallback POI: ${fallbackPOI.name}")
        }
    }
    
    private fun generateBasicFallbackPOI(location: Location): POIData {
        println("[AIAgentManager] Using basic fallback POI (real discovery failed)")
        
        return POIData(
            id = "fallback_poi_${System.currentTimeMillis()}",
            name = "Local Point of Interest",
            description = "Local discovery unavailable - check connection",
            category = "attraction",
            latitude = location.latitude + (Math.random() - 0.5) * 0.01, // Small random offset
            longitude = location.longitude + (Math.random() - 0.5) * 0.01,
            distanceFromUser = 1.0,
            rating = 4.0,
            imageURL = null,
            reviewSummary = "Local discovery unavailable - check connection",
            couldEarnRevenue = false
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