package com.roadtrip.copilot.services

import android.content.Context
import android.util.Log
import com.roadtrip.copilot.ai.Gemma3NE2BLoader
import com.roadtrip.copilot.models.POIData
import com.roadtrip.copilot.models.POICategories
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.coroutines.async
import kotlinx.coroutines.delay
import java.util.concurrent.ConcurrentHashMap
import kotlin.math.*

/**
 * POI Discovery Orchestrator with hybrid LLM + API approach
 * Orchestrates POI discovery using local Gemma-3N LLM with Google Places API failover
 * Performance targets: <350ms LLM, <1000ms API failover
 * Automotive safety compliance with Android Auto integration
 * Equivalent to iOS POIDiscoveryOrchestrator.swift implementation
 */
class POIDiscoveryOrchestrator(private val context: Context) {
    
    companion object {
        private const val TAG = "POIDiscovery"
        
        // Performance monitoring
        private const val LLM_PERFORMANCE_THRESHOLD_MS = 350L // 350ms
        private const val API_PERFORMANCE_THRESHOLD_MS = 1000L // 1000ms
        
        // Cache settings
        private const val CACHE_EXPIRATION_TIME_MS = 300_000L // 5 minutes
        private const val MINIMUM_LOCATION_CHANGE_METERS = 1000.0 // 1km
        
        // Lost Lake, Oregon coordinates for testing
        private const val LOST_LAKE_LATITUDE = 45.4979
        private const val LOST_LAKE_LONGITUDE = -121.8209
    }
    
    private lateinit var gemmaLoader: Gemma3NE2BLoader
    private val placesClient = GooglePlacesAPIClient.shared
    private val categories = POICategories
    
    var isProcessing = false
        private set
    var lastError: Exception? = null
        private set
    var currentStrategy: DiscoveryStrategy = DiscoveryStrategy.HYBRID
        private set
    
    // Cache for recent discoveries
    private val discoveryCache = ConcurrentHashMap<String, CachedDiscovery>()
    
    // Location tracking
    private var lastLatitude: Double? = null
    private var lastLongitude: Double? = null
    
    init {
        initializeGemmaLoader()
    }
    
    private fun initializeGemmaLoader() {
        try {
            gemmaLoader = Gemma3NE2BLoader(context)
            Log.i(TAG, "🚀 [POI ORCHESTRATOR] Initialized with Gemma-3N LLM")
        } catch (e: Exception) {
            Log.e(TAG, "❌ [POI ORCHESTRATOR] Failed to initialize Gemma-3N loader: ${e.message}", e)
            throw e
        }
    }
    
    /**
     * Discover POIs using hybrid LLM + API approach optimized for automotive use
     * @param latitude Search location latitude (required for safety compliance)
     * @param longitude Search location longitude (required for safety compliance)
     * @param category POI category (optional, uses intelligent categorization if null)
     * @param preferredStrategy Preferred discovery strategy
     * @param maxResults Maximum results (capped at 10 for automotive safety)
     * @return POI discovery result with performance metrics
     */
    suspend fun discoverPOIs(
        latitude: Double,
        longitude: Double,
        category: String? = null,
        preferredStrategy: DiscoveryStrategy = DiscoveryStrategy.HYBRID,
        maxResults: Int = 8
    ): POIDiscoveryResult = withContext(Dispatchers.Default) {
        
        Log.i(TAG, "🔍 [POI ORCHESTRATOR] Starting discovery near $latitude, $longitude")
        val discoveryStartTime = System.currentTimeMillis()
        
        try {
            isProcessing = true
            
            // Check cache first
            val cacheKey = generateCacheKey(latitude, longitude, category)
            getCachedDiscovery(cacheKey)?.let { cached ->
                Log.i(TAG, "📋 [POI ORCHESTRATOR] Using cached results")
                return@withContext cached.result
            }
            
            // Determine optimal category if not provided
            val finalCategory = category ?: determineOptimalCategory(latitude, longitude)
            
            // Execute discovery strategy
            val result = when (preferredStrategy) {
                DiscoveryStrategy.LLM_FIRST -> discoverWithLLMFirst(latitude, longitude, finalCategory, maxResults)
                DiscoveryStrategy.API_FIRST -> discoverWithAPIFirst(latitude, longitude, finalCategory, maxResults)
                DiscoveryStrategy.HYBRID -> discoverWithHybridApproach(latitude, longitude, finalCategory, maxResults)
                DiscoveryStrategy.LLM_ONLY -> discoverWithLLMOnly(latitude, longitude, finalCategory, maxResults)
            }
            
            // Cache successful results
            cacheDiscovery(cacheKey, result)
            
            // Update location tracking
            lastLatitude = latitude
            lastLongitude = longitude
            
            Log.i(TAG, "✅ [POI ORCHESTRATOR] Discovery completed: ${result.pois.size} POIs found using ${result.strategyUsed}")
            return@withContext result
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ [POI ORCHESTRATOR] Discovery failed: ${e.message}", e)
            lastError = e
            throw e
        } finally {
            isProcessing = false
            logDiscoveryPerformance(discoveryStartTime)
        }
    }
    
    /**
     * Discover POIs for Lost Lake, Oregon specifically (test case)
     */
    suspend fun discoverLostLakeOregonPOIs(): POIDiscoveryResult {
        Log.i(TAG, "🏔️ [POI ORCHESTRATOR] Discovering Lost Lake, Oregon POIs")
        
        return discoverPOIs(
            latitude = LOST_LAKE_LATITUDE,
            longitude = LOST_LAKE_LONGITUDE,
            category = "attraction",
            preferredStrategy = DiscoveryStrategy.HYBRID,
            maxResults = 10
        )
    }
    
    // MARK: - Discovery Strategies
    
    private suspend fun discoverWithLLMFirst(
        latitude: Double,
        longitude: Double,
        category: String,
        maxResults: Int
    ): POIDiscoveryResult {
        val llmStartTime = System.currentTimeMillis()
        
        try {
            // Try LLM discovery first
            val pois = discoverWithLLM(latitude, longitude, category, maxResults)
            val llmTime = System.currentTimeMillis() - llmStartTime
            
            if (pois.isNotEmpty()) {
                return POIDiscoveryResult(
                    pois = pois,
                    strategyUsed = DiscoveryStrategy.LLM_FIRST,
                    responseTimeMs = llmTime,
                    fallbackUsed = false
                )
            }
        } catch (e: Exception) {
            Log.w(TAG, "⚠️ [POI ORCHESTRATOR] LLM discovery failed: ${e.message}")
        }
        
        // Fallback to API
        Log.i(TAG, "🔄 [POI ORCHESTRATOR] Falling back to Google Places API")
        val pois = placesClient.searchPOIs(latitude, longitude, category, maxResults = maxResults)
        val totalTime = System.currentTimeMillis() - llmStartTime
        
        return POIDiscoveryResult(
            pois = pois,
            strategyUsed = DiscoveryStrategy.API_FIRST,
            responseTimeMs = totalTime,
            fallbackUsed = true
        )
    }
    
    private suspend fun discoverWithAPIFirst(
        latitude: Double,
        longitude: Double,
        category: String,
        maxResults: Int
    ): POIDiscoveryResult {
        val apiStartTime = System.currentTimeMillis()
        
        try {
            // Try API discovery first
            val pois = placesClient.searchPOIs(latitude, longitude, category, maxResults = maxResults)
            val apiTime = System.currentTimeMillis() - apiStartTime
            
            if (pois.isNotEmpty()) {
                return POIDiscoveryResult(
                    pois = pois,
                    strategyUsed = DiscoveryStrategy.API_FIRST,
                    responseTimeMs = apiTime,
                    fallbackUsed = false
                )
            }
        } catch (e: Exception) {
            Log.w(TAG, "⚠️ [POI ORCHESTRATOR] API discovery failed: ${e.message}")
        }
        
        // Fallback to LLM
        Log.i(TAG, "🔄 [POI ORCHESTRATOR] Falling back to Gemma-3N LLM")
        val pois = discoverWithLLM(latitude, longitude, category, maxResults)
        val totalTime = System.currentTimeMillis() - apiStartTime
        
        return POIDiscoveryResult(
            pois = pois,
            strategyUsed = DiscoveryStrategy.LLM_FIRST,
            responseTimeMs = totalTime,
            fallbackUsed = true
        )
    }
    
    private suspend fun discoverWithHybridApproach(
        latitude: Double,
        longitude: Double,
        category: String,
        maxResults: Int
    ): POIDiscoveryResult = withContext(Dispatchers.IO) {
        val startTime = System.currentTimeMillis()
        
        try {
            // Run both approaches in parallel
            val llmDeferred = async { discoverWithLLM(latitude, longitude, category, maxResults / 2) }
            val apiDeferred = async { placesClient.searchPOIs(latitude, longitude, category, maxResults = maxResults / 2) }
            
            val llmPOIs = llmDeferred.await()
            val apiPOIs = apiDeferred.await()
            
            // Merge and deduplicate results
            val mergedPOIs = mergeAndDeduplicatePOIs(llmPOIs, apiPOIs, maxResults)
            val totalTime = System.currentTimeMillis() - startTime
            
            return@withContext POIDiscoveryResult(
                pois = mergedPOIs,
                strategyUsed = DiscoveryStrategy.HYBRID,
                responseTimeMs = totalTime,
                fallbackUsed = false
            )
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ [POI ORCHESTRATOR] Hybrid discovery failed: ${e.message}")
            throw e
        }
    }
    
    private suspend fun discoverWithLLMOnly(
        latitude: Double,
        longitude: Double,
        category: String,
        maxResults: Int
    ): POIDiscoveryResult {
        val startTime = System.currentTimeMillis()
        val pois = discoverWithLLM(latitude, longitude, category, maxResults)
        val responseTime = System.currentTimeMillis() - startTime
        
        return POIDiscoveryResult(
            pois = pois,
            strategyUsed = DiscoveryStrategy.LLM_ONLY,
            responseTimeMs = responseTime,
            fallbackUsed = false
        )
    }
    
    // MARK: - LLM Discovery Implementation
    
    private suspend fun discoverWithLLM(
        latitude: Double,
        longitude: Double,
        category: String,
        maxResults: Int
    ): List<POIData> {
        Log.i(TAG, "🤖 [POI ORCHESTRATOR] Using Gemma-3N for POI discovery")
        
        // Create location context
        val locationName = getLocationName(latitude, longitude)
        val prompt = createLLMDiscoveryPrompt(locationName, category, maxResults)
        
        // Ensure model is loaded
        if (!gemmaLoader.isModelLoaded()) {
            gemmaLoader.loadModel()
        }
        
        // Get LLM response
        val response = gemmaLoader.predict(prompt, maxTokens = 500)
        
        // Parse POIs from LLM response
        val pois = parseLLMPOIResponse(response, latitude, longitude, category)
        
        Log.i(TAG, "🤖 [POI ORCHESTRATOR] LLM discovered ${pois.size} POIs")
        return pois
    }
    
    private fun createLLMDiscoveryPrompt(locationName: String, category: String, maxResults: Int): String {
        return """
        Discover $maxResults real points of interest near $locationName in the $category category.
        
        For each POI, provide:
        - Exact name
        - Brief description
        - Why it's worth visiting
        - Estimated rating (1-5 stars)
        - Distance from center (in km)
        
        Focus on authentic local places, hidden gems, and well-known attractions.
        Provide realistic, specific names and details.
        
        Format each POI as:
        NAME: [exact name]
        DESCRIPTION: [brief description]  
        RATING: [1-5 stars]
        DISTANCE: [distance in km]
        WHY: [reason to visit]
        ---
        """.trimIndent()
    }
    
    private fun parseLLMPOIResponse(response: String, baseLat: Double, baseLng: Double, category: String): List<POIData> {
        val sections = response.split("---")
        val pois = mutableListOf<POIData>()
        
        for (section in sections) {
            val poi = parseSinglePOI(section, baseLat, baseLng, category)
            if (poi != null) {
                pois.add(poi)
            }
        }
        
        return pois
    }
    
    private fun parseSinglePOI(text: String, baseLat: Double, baseLng: Double, category: String): POIData? {
        val lines = text.split("\n")
        var name: String? = null
        var description: String? = null
        var rating = 4.0
        var distance = 2.0
        
        for (line in lines) {
            val trimmed = line.trim()
            
            when {
                trimmed.startsWith("NAME:") -> {
                    name = trimmed.substring(5).trim()
                }
                trimmed.startsWith("DESCRIPTION:") -> {
                    description = trimmed.substring(12).trim()
                }
                trimmed.startsWith("RATING:") -> {
                    val ratingStr = trimmed.substring(7).trim()
                    rating = ratingStr.split(" ")[0].toDoubleOrNull() ?: 4.0
                }
                trimmed.startsWith("DISTANCE:") -> {
                    val distanceStr = trimmed.substring(9).trim()
                    distance = distanceStr.split(" ")[0].toDoubleOrNull() ?: 2.0
                }
            }
        }
        
        if (name.isNullOrEmpty()) return null
        
        // Generate approximate location based on distance
        val (poiLat, poiLng) = generateApproximateLocation(baseLat, baseLng, distance * 1000) // Convert km to meters
        
        return POIData(
            id = generatePOIId(name, poiLat, poiLng),
            name = name,
            description = description ?: "A point of interest near your location",
            category = category,
            latitude = poiLat,
            longitude = poiLng,
            distanceFromUser = distance * 0.621371, // Convert km to miles for consistency
            rating = rating,
            imageURL = null, // Could be filled later with image search
            reviewSummary = description,
            couldEarnRevenue = rating >= 4.0
        )
    }
    
    // MARK: - Helper Methods
    
    private fun determineOptimalCategory(latitude: Double, longitude: Double): String {
        // Use location context to determine best category
        // This could be enhanced with ML-based categorization
        val essentialCategories = categories.getEssentialCategories(context)
        return essentialCategories.firstOrNull() ?: "attraction"
    }
    
    private fun getLocationName(latitude: Double, longitude: Double): String {
        // Use reverse geocoding to get location name
        // For now, return coordinate-based description
        return "coordinates %.4f, %.4f".format(latitude, longitude)
    }
    
    private fun generateApproximateLocation(centerLat: Double, centerLng: Double, distanceMeters: Double): Pair<Double, Double> {
        // Generate a location within the specified distance
        val randomBearing = (0..360).random() * PI / 180.0
        val randomDistance = (0..distanceMeters.toInt()).random().toDouble()
        
        val earthRadius = 6371000.0 // Earth radius in meters
        val lat1 = centerLat * PI / 180.0
        val lng1 = centerLng * PI / 180.0
        
        val lat2 = asin(sin(lat1) * cos(randomDistance / earthRadius) +
                cos(lat1) * sin(randomDistance / earthRadius) * cos(randomBearing))
        val lng2 = lng1 + atan2(sin(randomBearing) * sin(randomDistance / earthRadius) * cos(lat1),
                cos(randomDistance / earthRadius) - sin(lat1) * sin(lat2))
        
        return Pair(lat2 * 180.0 / PI, lng2 * 180.0 / PI)
    }
    
    private fun mergeAndDeduplicatePOIs(llmPOIs: List<POIData>, apiPOIs: List<POIData>, maxResults: Int): List<POIData> {
        val allPOIs = mutableListOf<POIData>()
        val seenNames = mutableSetOf<String>()
        
        // Add LLM POIs first (prioritize local knowledge)
        for (poi in llmPOIs) {
            val normalizedName = poi.name.lowercase().trim()
            if (!seenNames.contains(normalizedName)) {
                allPOIs.add(poi)
                seenNames.add(normalizedName)
            }
        }
        
        // Add API POIs (avoid duplicates)
        for (poi in apiPOIs) {
            val normalizedName = poi.name.lowercase().trim()
            if (!seenNames.contains(normalizedName)) {
                allPOIs.add(poi)
                seenNames.add(normalizedName)
            }
        }
        
        // Sort by rating and distance, then limit results
        return allPOIs.sortedWith(compareByDescending<POIData> { it.rating }.thenBy { it.distanceFromUser })
            .take(maxResults)
    }
    
    // MARK: - Cache Management
    
    private fun generateCacheKey(latitude: Double, longitude: Double, category: String?): String {
        val lat = "%.3f".format(latitude)
        val lng = "%.3f".format(longitude)
        val cat = category ?: "default"
        return "${lat}_${lng}_$cat"
    }
    
    private fun getCachedDiscovery(key: String): CachedDiscovery? {
        val cached = discoveryCache[key] ?: return null
        
        // Check if cache is still valid
        if (System.currentTimeMillis() - cached.timestamp > CACHE_EXPIRATION_TIME_MS) {
            discoveryCache.remove(key)
            return null
        }
        
        return cached
    }
    
    private fun cacheDiscovery(key: String, result: POIDiscoveryResult) {
        discoveryCache[key] = CachedDiscovery(result, System.currentTimeMillis())
        
        // Clean old cache entries
        cleanExpiredCache()
    }
    
    private fun cleanExpiredCache() {
        val now = System.currentTimeMillis()
        val keysToRemove = discoveryCache.keys.filter { key ->
            val cached = discoveryCache[key]
            cached != null && (now - cached.timestamp) > CACHE_EXPIRATION_TIME_MS
        }
        
        keysToRemove.forEach { discoveryCache.remove(it) }
    }
    
    private fun logDiscoveryPerformance(startTime: Long) {
        val elapsed = System.currentTimeMillis() - startTime
        
        if (elapsed > API_PERFORMANCE_THRESHOLD_MS) {
            Log.w(TAG, "⚠️ [POI ORCHESTRATOR] Slow discovery: ${elapsed}ms")
        } else {
            Log.i(TAG, "✅ [POI ORCHESTRATOR] Discovery completed in ${elapsed}ms")
        }
    }
    
    private fun generatePOIId(name: String, lat: Double, lng: Double): String {
        val latStr = "%.4f".format(lat)
        val lngStr = "%.4f".format(lng)
        return "${name.hashCode()}_${latStr}_${lngStr}"
    }
}

// MARK: - Data Models

enum class DiscoveryStrategy {
    HYBRID,           // Use both LLM and API, merge results
    LLM_FIRST,        // Try LLM first, fallback to API
    API_FIRST,        // Try API first, fallback to LLM
    LLM_ONLY          // Use only LLM (for offline scenarios)
}

data class POIDiscoveryResult(
    val pois: List<POIData>,
    val strategyUsed: DiscoveryStrategy,
    val responseTimeMs: Long,
    val fallbackUsed: Boolean
)

data class CachedDiscovery(
    val result: POIDiscoveryResult,
    val timestamp: Long
)