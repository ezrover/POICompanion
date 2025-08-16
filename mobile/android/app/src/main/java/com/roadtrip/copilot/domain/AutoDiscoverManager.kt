package com.roadtrip.copilot.domain

import android.content.Context
import android.content.SharedPreferences
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.roadtrip.copilot.managers.LocationManager
import com.roadtrip.copilot.models.POIData
import com.roadtrip.copilot.services.GooglePlacesAPIClient
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.*
import kotlin.coroutines.cancellation.CancellationException

/**
 * AutoDiscoverManager - Android implementation for Auto Discover feature
 * Provides intelligent POI discovery and ranking with auto-cycling photos
 * Platform parity with iOS AutoDiscoverManager
 */
class AutoDiscoverManager private constructor(
    private val context: Context
) : ViewModel() {
    
    companion object {
        @Volatile
        private var INSTANCE: AutoDiscoverManager? = null
        
        fun getInstance(context: Context): AutoDiscoverManager {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: AutoDiscoverManager(context.applicationContext).also { INSTANCE = it }
            }
        }
    }
    
    // MARK: - Published Properties (StateFlow for platform parity)
    private val _isDiscoveryActive = MutableStateFlow(false)
    val isDiscoveryActive: StateFlow<Boolean> = _isDiscoveryActive.asStateFlow()
    
    private val _discoveredPOIs = MutableStateFlow<List<POIData>>(emptyList())
    val discoveredPOIs: StateFlow<List<POIData>> = _discoveredPOIs.asStateFlow()
    
    private val _currentPOIIndex = MutableStateFlow(0)
    val currentPOIIndex: StateFlow<Int> = _currentPOIIndex.asStateFlow()
    
    private val _isAutoPhotoActive = MutableStateFlow(false)
    val isAutoPhotoActive: StateFlow<Boolean> = _isAutoPhotoActive.asStateFlow()
    
    private val _currentPhotoIndex = MutableStateFlow(0)
    val currentPhotoIndex: StateFlow<Int> = _currentPhotoIndex.asStateFlow()
    
    private val _dislikedPOIs = MutableStateFlow<Set<String>>(emptySet())
    val dislikedPOIs: StateFlow<Set<String>> = _dislikedPOIs.asStateFlow()
    
    // MARK: - Private Properties
    private val locationManager = LocationManager(context)
    private val rankingEngine = POIRankingEngine(context)
    private val googlePlacesClient = GooglePlacesAPIClient(context)
    private var autoPhotoTimer: Timer? = null
    private val sharedPreferences: SharedPreferences = 
        context.getSharedPreferences("auto_discover_prefs", Context.MODE_PRIVATE)
    
    // Discovery settings - Platform parity with iOS
    private var searchRadius: Double = 5000.0 // 5km default
    private val maxPOIs = 10
    private val photosPerPOI = 5
    private val photoDisplayDuration: Long = 2000L // 2 seconds
    
    init {
        loadDislikedPOIs()
    }
    
    // MARK: - Public Methods
    
    /**
     * Starts the auto discovery process
     * Platform parity with iOS startAutoDiscovery()
     */
    suspend fun startAutoDiscovery() {
        val currentLocation = getCurrentLocation()
            ?: throw AutoDiscoverError.LocationUnavailable
        
        _isDiscoveryActive.value = true
        
        try {
            // Search for POIs using Google Places API
            val nearbyPOIs = searchNearbyPOIs(currentLocation.latitude, currentLocation.longitude)
            
            // Rank and filter POIs
            val rankedPOIs = rankingEngine.rankPOIs(nearbyPOIs, currentLocation.latitude, currentLocation.longitude)
            
            // Filter out disliked POIs
            val filteredPOIs = rankedPOIs.filter { !_dislikedPOIs.value.contains(it.id) }
            
            // Take top 10
            _discoveredPOIs.value = filteredPOIs.take(maxPOIs)
            
            if (_discoveredPOIs.value.isEmpty()) {
                // Expand search radius if no results
                searchRadius *= 2
                startAutoDiscovery()
                return
            }
            
            _currentPOIIndex.value = 0
            
            // Load photos for each POI
            loadPhotosForAllPOIs()
            
            // Start auto photo cycling
            startAutoPhotoCycling()
            
            println("[AutoDiscoverManager] Discovery started with ${_discoveredPOIs.value.size} POIs")
            
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            println("[AutoDiscoverManager] Discovery failed: ${e.message}")
            _isDiscoveryActive.value = false
            throw AutoDiscoverError.NetworkError
        }
    }
    
    /**
     * Stops auto discovery and returns to normal mode
     */
    fun stopAutoDiscovery() {
        _isDiscoveryActive.value = false
        _isAutoPhotoActive.value = false
        stopAutoPhotoCycling()
        _discoveredPOIs.value = emptyList()
        _currentPOIIndex.value = 0
        _currentPhotoIndex.value = 0
        println("[AutoDiscoverManager] Auto discovery stopped")
    }
    
    /**
     * Navigates to next POI in discovery list
     */
    fun nextPOI() {
        val pois = _discoveredPOIs.value
        if (pois.isEmpty()) return
        
        _currentPOIIndex.value = (_currentPOIIndex.value + 1) % pois.size
        _currentPhotoIndex.value = 0
        
        println("[AutoDiscoverManager] Next POI: ${currentPOI?.name ?: "Unknown"}")
    }
    
    /**
     * Navigates to previous POI in discovery list
     */
    fun previousPOI() {
        val pois = _discoveredPOIs.value
        if (pois.isEmpty()) return
        
        _currentPOIIndex.value = if (_currentPOIIndex.value == 0) pois.size - 1 else _currentPOIIndex.value - 1
        _currentPhotoIndex.value = 0
        
        println("[AutoDiscoverManager] Previous POI: ${currentPOI?.name ?: "Unknown"}")
    }
    
    /**
     * Dislikes current POI and moves to next
     */
    fun dislikeCurrentPOI() {
        val currentPOI = currentPOI ?: return
        
        // Add to disliked list
        val updatedDislikes = _dislikedPOIs.value.toMutableSet()
        updatedDislikes.add(currentPOI.id)
        _dislikedPOIs.value = updatedDislikes
        saveDislikedPOIs()
        
        // Remove from current list
        val currentPOIs = _discoveredPOIs.value.toMutableList()
        if (currentPOIs.size > 1) {
            currentPOIs.removeAt(_currentPOIIndex.value)
            _discoveredPOIs.value = currentPOIs
            
            // Adjust index if needed
            if (_currentPOIIndex.value >= currentPOIs.size) {
                _currentPOIIndex.value = 0
            }
        } else {
            // Last POI disliked, expand search
            viewModelScope.launch {
                searchRadius *= 1.5
                startAutoDiscovery()
            }
        }
        
        _currentPhotoIndex.value = 0
        println("[AutoDiscoverManager] Disliked POI: ${currentPOI.name}")
    }
    
    /**
     * Gets current POI
     */
    val currentPOI: POIData?
        get() {
            val pois = _discoveredPOIs.value
            val index = _currentPOIIndex.value
            return if (index < pois.size) pois[index] else null
        }
    
    /**
     * Gets current POI photos
     */
    val currentPOIPhotos: List<String>
        get() = currentPOI?.photos ?: emptyList()
    
    /**
     * Gets current photo URL
     */
    val currentPhoto: String?
        get() {
            val photos = currentPOIPhotos
            val index = _currentPhotoIndex.value
            return if (index < photos.size) photos[index] else null
        }
    
    // MARK: - Private Methods
    
    private suspend fun getCurrentLocation(): LocationData? {
        return withContext(Dispatchers.IO) {
            try {
                // For now, use a placeholder location (San Francisco) - in real app would use actual location
                // TODO: Integrate with proper location services
                LocationData(37.7749, -122.4194)
            } catch (e: Exception) {
                println("[AutoDiscoverManager] Failed to get current location: ${e.message}")
                null
            }
        }
    }
    
    private suspend fun searchNearbyPOIs(latitude: Double, longitude: Double): List<POIData> {
        return withContext(Dispatchers.IO) {
            try {
                googlePlacesClient.searchNearbyPOIs(latitude, longitude, searchRadius)
            } catch (e: Exception) {
                println("[AutoDiscoverManager] Failed to search nearby POIs: ${e.message}")
                emptyList()
            }
        }
    }
    
    private suspend fun loadPhotosForAllPOIs() {
        withContext(Dispatchers.IO) {
            val pois = _discoveredPOIs.value.toMutableList()
            
            for (i in pois.indices) {
                try {
                    val photos = googlePlacesClient.getPhotosForPOI(
                        pois[i].placeId ?: "",
                        photosPerPOI
                    )
                    pois[i] = pois[i].copy(photos = photos)
                } catch (e: Exception) {
                    println("[AutoDiscoverManager] Failed to load photos for POI ${pois[i].name}: ${e.message}")
                }
            }
            
            _discoveredPOIs.value = pois
        }
    }
    
    private fun startAutoPhotoCycling() {
        if (_discoveredPOIs.value.isEmpty()) return
        
        _isAutoPhotoActive.value = true
        
        autoPhotoTimer = Timer()
        autoPhotoTimer?.scheduleAtFixedRate(object : TimerTask() {
            override fun run() {
                viewModelScope.launch(Dispatchers.Main) {
                    cycleToNextPhoto()
                }
            }
        }, photoDisplayDuration, photoDisplayDuration)
        
        println("[AutoDiscoverManager] Auto photo cycling started")
    }
    
    private fun stopAutoPhotoCycling() {
        autoPhotoTimer?.cancel()
        autoPhotoTimer = null
        _isAutoPhotoActive.value = false
        println("[AutoDiscoverManager] Auto photo cycling stopped")
    }
    
    private fun cycleToNextPhoto() {
        if (!_isAutoPhotoActive.value || _discoveredPOIs.value.isEmpty()) return
        
        val currentPhotos = currentPOIPhotos
        
        if (_currentPhotoIndex.value < currentPhotos.size - 1) {
            // Next photo in current POI
            _currentPhotoIndex.value = _currentPhotoIndex.value + 1
        } else {
            // Finished all photos for current POI, move to next POI
            nextPOI()
        }
    }
    
    // MARK: - Persistence
    
    private fun loadDislikedPOIs() {
        val dislikedSet = sharedPreferences.getStringSet("disliked_pois", emptySet()) ?: emptySet()
        _dislikedPOIs.value = dislikedSet
        println("[AutoDiscoverManager] Loaded ${dislikedSet.size} disliked POIs")
    }
    
    private fun saveDislikedPOIs() {
        sharedPreferences.edit()
            .putStringSet("disliked_pois", _dislikedPOIs.value)
            .apply()
        println("[AutoDiscoverManager] Saved ${_dislikedPOIs.value.size} disliked POIs")
    }
    
    // MARK: - Voice Commands Extension
    
    fun handleVoiceCommand(command: String) {
        val lowercased = command.lowercase()
        
        when {
            lowercased.contains("next") || lowercased.contains("skip") -> nextPOI()
            lowercased.contains("previous") || lowercased.contains("back") -> previousPOI()
            lowercased.contains("dislike") || lowercased.contains("don't like") -> dislikeCurrentPOI()
            lowercased.contains("stop") || lowercased.contains("exit") -> stopAutoDiscovery()
        }
    }
    
    override fun onCleared() {
        super.onCleared()
        stopAutoPhotoCycling()
    }
}

// MARK: - Data Classes

data class LocationData(
    val latitude: Double,
    val longitude: Double
)

// MARK: - Error Types

sealed class AutoDiscoverError : Exception() {
    object LocationUnavailable : AutoDiscoverError()
    object NoResultsFound : AutoDiscoverError()
    object NetworkError : AutoDiscoverError()
    
    override val message: String
        get() = when (this) {
            is LocationUnavailable -> "Location services are not available"
            is NoResultsFound -> "No interesting places found nearby"
            is NetworkError -> "Network connection error"
        }
}