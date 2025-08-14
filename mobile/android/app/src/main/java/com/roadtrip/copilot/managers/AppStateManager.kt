package com.roadtrip.copilot.managers

import androidx.lifecycle.ViewModel
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject

// Import from models package
import com.roadtrip.copilot.models.AppScreen
import com.roadtrip.copilot.models.DestinationInfo

@HiltViewModel
class AppStateManager @Inject constructor() : ViewModel() {
    
    private val _currentScreen = MutableStateFlow(AppScreen.DESTINATION_SELECTION)
    val currentScreen: StateFlow<AppScreen> = _currentScreen.asStateFlow()
    
    private val _isInActiveRoadtrip = MutableStateFlow(false)
    val isInActiveRoadtrip: StateFlow<Boolean> = _isInActiveRoadtrip.asStateFlow()
    
    private val _destinationInfo = MutableStateFlow<DestinationInfo?>(null)
    val destinationInfo: String
        get() = _destinationInfo.value?.name ?: "No destination set"
    
    // POI Result state
    private val _poiResultData = MutableStateFlow<POIResultData?>(null)
    val poiResultData: StateFlow<POIResultData?> = _poiResultData.asStateFlow()
    
    data class POIResultData(
        val destinationName: String,
        val destinationAddress: String?,
        val gemmaResponse: String
    )
    
    fun startRoadtrip(destination: DestinationInfo) {
        _destinationInfo.value = destination
        _isInActiveRoadtrip.value = true
        _currentScreen.value = AppScreen.MAIN_DASHBOARD
        println("Started roadtrip to: ${destination.name}")
    }
    
    fun endRoadtrip() {
        _isInActiveRoadtrip.value = false
        _currentScreen.value = AppScreen.DESTINATION_SELECTION
        _destinationInfo.value = null
        println("Ended roadtrip")
    }
    
    fun returnToDestinationSelection() {
        // Keep destination info but return to selection screen to allow changing destination
        _currentScreen.value = AppScreen.DESTINATION_SELECTION
        println("Returned to destination selection screen")
    }
    
    fun getDestinationInfo(): DestinationInfo? = _destinationInfo.value
    
    fun showPOIResult(destinationName: String, destinationAddress: String?, gemmaResponse: String) {
        _poiResultData.value = POIResultData(destinationName, destinationAddress, gemmaResponse)
        _currentScreen.value = AppScreen.POI_RESULT
        println("Showing POI result for: $destinationName")
    }
    
    fun returnFromPOIResult() {
        _poiResultData.value = null
        _currentScreen.value = AppScreen.DESTINATION_SELECTION
        println("Returned from POI result to destination selection")
    }
}