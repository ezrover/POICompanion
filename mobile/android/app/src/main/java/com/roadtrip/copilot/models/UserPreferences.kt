package com.roadtrip.copilot.models

import android.content.Context
import android.content.SharedPreferences
import androidx.lifecycle.ViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.*

// MARK: - POI Categories

enum class POICategory(val id: String, val displayName: String, val icon: String) {
    RESTAURANTS("restaurants", "Restaurants", "restaurant"),
    GAS_STATIONS("gas_stations", "Gas Stations", "local_gas_station"),
    ATTRACTIONS("attractions", "Tourist Attractions", "photo_camera"),
    LODGING("lodging", "Hotels & Lodging", "hotel"),
    SHOPPING("shopping", "Shopping", "shopping_bag"),
    PARKS("parks", "Parks & Nature", "park"),
    MUSEUMS("museums", "Museums", "museum"),
    ENTERTAINMENT("entertainment", "Entertainment", "theaters"),
    BEACHES("beaches", "Beaches", "beach_access"),
    VIEWPOINTS("viewpoints", "Scenic Viewpoints", "landscape"),
    HISTORIC_SITES("historic_sites", "Historic Sites", "account_balance"),
    WINERIES("wineries", "Wineries & Breweries", "wine_bar");
    
    val voiceAliases: List<String>
        get() = when (this) {
            RESTAURANTS -> listOf("restaurants", "food", "dining", "eateries", "cafes")
            GAS_STATIONS -> listOf("gas stations", "fuel", "gas", "petrol stations")
            ATTRACTIONS -> listOf("attractions", "tourist spots", "sights", "sightseeing")
            LODGING -> listOf("hotels", "lodging", "accommodation", "motels", "inns")
            SHOPPING -> listOf("shopping", "stores", "malls", "retail")
            PARKS -> listOf("parks", "nature", "outdoor", "hiking", "trails")
            MUSEUMS -> listOf("museums", "galleries", "exhibits")
            ENTERTAINMENT -> listOf("entertainment", "theaters", "cinemas", "shows")
            BEACHES -> listOf("beaches", "coastline", "ocean", "seaside")
            VIEWPOINTS -> listOf("viewpoints", "scenic views", "overlooks", "vistas")
            HISTORIC_SITES -> listOf("historic sites", "historical", "landmarks", "monuments")
            WINERIES -> listOf("wineries", "breweries", "wine tasting", "vineyards")
        }
}

// MARK: - Distance Unit

enum class DistanceUnit(val id: String, val displayName: String, val shortName: String) {
    MILES("miles", "Miles", "mi"),
    KILOMETERS("kilometers", "Kilometers", "km");
    
    companion object {
        fun getDefault(): DistanceUnit {
            // Use system locale to determine default unit
            val locale = Locale.getDefault()
            val countryCode = locale.country
            
            // Countries that use kilometers
            val metricCountries = setOf("CA", "GB", "AU", "DE", "FR", "IT", "ES", "NL", "BE", "CH", "AT", "SE", "NO", "DK", "FI")
            return if (metricCountries.contains(countryCode)) KILOMETERS else MILES
        }
    }
}

// MARK: - User Preferences Manager

class UserPreferencesManager(private val context: Context) : ViewModel() {
    private val sharedPrefs: SharedPreferences = context.getSharedPreferences("user_preferences", Context.MODE_PRIVATE)
    
    private val _searchRadius = MutableStateFlow(5.0)
    val searchRadius: StateFlow<Double> = _searchRadius.asStateFlow()
    
    private val _distanceUnit = MutableStateFlow(DistanceUnit.getDefault())
    val distanceUnit: StateFlow<DistanceUnit> = _distanceUnit.asStateFlow()
    
    private val _selectedPOICategories = MutableStateFlow(POICategory.values().toSet())
    val selectedPOICategories: StateFlow<Set<POICategory>> = _selectedPOICategories.asStateFlow()
    
    private val _hasCompletedOnboarding = MutableStateFlow(false)
    val hasCompletedOnboarding: StateFlow<Boolean> = _hasCompletedOnboarding.asStateFlow()
    
    init {
        loadPreferences()
    }
    
    // MARK: - Setters
    
    fun setSearchRadius(radius: Double) {
        if (radius in 1.0..10.0) {
            _searchRadius.value = radius
        }
    }
    
    fun setDistanceUnit(unit: DistanceUnit) {
        _distanceUnit.value = unit
    }
    
    fun toggleCategory(category: POICategory) {
        val currentCategories = _selectedPOICategories.value.toMutableSet()
        if (currentCategories.contains(category)) {
            currentCategories.remove(category)
        } else {
            currentCategories.add(category)
        }
        _selectedPOICategories.value = currentCategories
    }
    
    fun selectAllCategories() {
        _selectedPOICategories.value = POICategory.values().toSet()
    }
    
    fun clearAllCategories() {
        _selectedPOICategories.value = emptySet()
    }
    
    fun setOnboardingCompleted(completed: Boolean) {
        _hasCompletedOnboarding.value = completed
    }
    
    // MARK: - Persistence
    
    fun savePreferences() {
        with(sharedPrefs.edit()) {
            putFloat("poi_search_radius", _searchRadius.value.toFloat())
            putString("distance_unit", _distanceUnit.value.id)
            putBoolean("has_completed_onboarding", _hasCompletedOnboarding.value)
            
            val categoryIds = _selectedPOICategories.value.map { it.id }.toSet()
            putStringSet("selected_poi_categories", categoryIds)
            
            apply()
        }
        
        println("User preferences saved: ${_searchRadius.value} ${_distanceUnit.value.shortName}, ${_selectedPOICategories.value.size} categories")
    }
    
    private fun loadPreferences() {
        val radius = sharedPrefs.getFloat("poi_search_radius", 5.0f).toDouble()
        _searchRadius.value = if (radius == 0.0) 5.0 else radius
        
        val unitId = sharedPrefs.getString("distance_unit", DistanceUnit.getDefault().id)
        _distanceUnit.value = DistanceUnit.values().find { it.id == unitId } ?: DistanceUnit.getDefault()
        
        _hasCompletedOnboarding.value = sharedPrefs.getBoolean("has_completed_onboarding", false)
        
        val categoryIds = sharedPrefs.getStringSet("selected_poi_categories", emptySet()) ?: emptySet()
        if (categoryIds.isNotEmpty()) {
            _selectedPOICategories.value = POICategory.values().filter { it.id in categoryIds }.toSet()
        }
        
        // Ensure we have at least some categories selected
        if (_selectedPOICategories.value.isEmpty()) {
            _selectedPOICategories.value = POICategory.values().toSet()
        }
    }
    
    // MARK: - Validation
    
    fun isRadiusValid(): Boolean = _searchRadius.value in 1.0..10.0
    
    fun hasCategoriesSelected(): Boolean = _selectedPOICategories.value.isNotEmpty()
    
    fun canProceed(): Boolean = isRadiusValid() && hasCategoriesSelected()
    
    // MARK: - Voice Command Processing
    
    fun processRadiusVoiceCommand(command: String): Boolean {
        val lowercaseCommand = command.lowercase()
        val components = lowercaseCommand.split("\\s+".toRegex())
        
        for (i in components.indices) {
            val component = components[i]
            val radius = component.toDoubleOrNull()
            
            if (radius != null && radius in 1.0..10.0) {
                setSearchRadius(radius)
                
                // Check for unit specification in next word
                if (i + 1 < components.size) {
                    val nextWord = components[i + 1]
                    when {
                        nextWord.contains("km") || nextWord.contains("kilometer") -> {
                            setDistanceUnit(DistanceUnit.KILOMETERS)
                        }
                        nextWord.contains("mi") || nextWord.contains("mile") -> {
                            setDistanceUnit(DistanceUnit.MILES)
                        }
                    }
                }
                
                return true
            }
        }
        
        return false
    }
    
    fun processCategoryVoiceCommand(command: String): Set<POICategory> {
        val lowercaseCommand = command.lowercase()
        val recognizedCategories = mutableSetOf<POICategory>()
        
        for (category in POICategory.values()) {
            for (alias in category.voiceAliases) {
                if (lowercaseCommand.contains(alias)) {
                    recognizedCategories.add(category)
                    break
                }
            }
        }
        
        return recognizedCategories
    }
    
    // MARK: - Helper Methods
    
    fun getSearchRadiusText(): String {
        return "${_searchRadius.value.toInt()} ${_distanceUnit.value.shortName}"
    }
    
    fun getCategoryDisplayNames(): List<String> {
        return _selectedPOICategories.value.map { it.displayName }
    }
}

// MARK: - Onboarding Steps

enum class OnboardingStep(val title: String) {
    DESTINATION("Where would you like to go?"),
    RADIUS("Set your search radius"),
    CATEGORIES("Choose your interests"),
    CONFIRMATION("Ready for your roadtrip?");
    
    companion object {
        fun fromIndex(index: Int): OnboardingStep? {
            return values().getOrNull(index)
        }
        
        fun getIndex(step: OnboardingStep): Int {
            return values().indexOf(step)
        }
    }
}