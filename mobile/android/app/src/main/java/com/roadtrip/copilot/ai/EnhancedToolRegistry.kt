package com.roadtrip.copilot.ai

import android.content.Context
import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.net.URL
import kotlin.random.Random

// POI Exclusion Manager
class POIExclusionManager(private val context: Context) {
    companion object {
        private const val TAG = "POIExclusion"
    }
    
    private var exclusions: POIExclusions? = null
    
    init {
        loadExclusions()
    }
    
    private fun loadExclusions() {
        try {
            val jsonString = context.assets.open("poi_exclusions.json").bufferedReader().use { it.readText() }
            val json = JSONObject(jsonString)
            
            exclusions = POIExclusions(
                chainRestaurants = json.getJSONObject("exclusions")
                    .getJSONArray("chain_restaurants").toStringList(),
                chainHotels = json.getJSONObject("exclusions")
                    .getJSONArray("chain_hotels").toStringList(),
                gasStations = json.getJSONObject("exclusions")
                    .getJSONArray("gas_stations").toStringList(),
                excludedCategories = json.getJSONObject("exclusions")
                    .getJSONArray("excluded_categories").toStringList()
            )
            
            Log.d(TAG, "✅ POI exclusions loaded: ${exclusions?.chainRestaurants?.size} chain restaurants, ${exclusions?.chainHotels?.size} chain hotels excluded")
        } catch (e: Exception) {
            Log.e(TAG, "⚠️ Failed to load POI exclusions", e)
        }
    }
    
    fun shouldExcludePOI(poi: POIExclusion): Boolean {
        val excl = exclusions ?: return false
        
        // Check if it's a gas station
        if (excl.gasStations.any { poi.name.contains(it, ignoreCase = true) }) {
            Log.d(TAG, "❌ Excluding gas station: ${poi.name}")
            return true
        }
        
        // Check if it's a chain restaurant
        if (excl.chainRestaurants.any { poi.name.contains(it, ignoreCase = true) }) {
            Log.d(TAG, "❌ Excluding chain restaurant: ${poi.name}")
            return true
        }
        
        // Check if it's a chain hotel
        if (excl.chainHotels.any { poi.name.contains(it, ignoreCase = true) }) {
            Log.d(TAG, "❌ Excluding chain hotel: ${poi.name}")
            return true
        }
        
        // Check excluded categories
        poi.category?.let { category ->
            if (excl.excludedCategories.contains(category.lowercase())) {
                Log.d(TAG, "❌ Excluding category: $category for ${poi.name}")
                return true
            }
        }
        
        return false
    }
    
    private fun JSONArray.toStringList(): List<String> {
        return (0 until length()).map { getString(it) }
    }
}

// Photo Fetching Tool
class FetchPOIPhotoTool {
    companion object {
        lateinit var context: Context
    }
    
    fun createTool(): Tool = Tool(
        name = "fetch_poi_photo",
        description = "Fetch a photo for a discovered POI from the internet",
        parameters = mapOf(
            "poi_name" to "Name of the POI",
            "location" to "Location context for the POI"
        ),
        execute = { parameters ->
            val startTime = System.currentTimeMillis()
            val poiName = parameters["poi_name"] as? String ?: "Unknown POI"
            val location = parameters["location"] as? String ?: ""
            
            Log.d("PhotoTool", "📸 Fetching photo for: $poiName at $location")
            
            // Mock photo URL - in production, use real API
            val mockPhotos = listOf(
                "https://images.unsplash.com/photo-lost-lake-trail",
                "https://images.unsplash.com/photo-mount-hood-forest",
                "https://images.unsplash.com/photo-oregon-nature"
            )
            
            val photoUrl = mockPhotos.random()
            val executionTime = System.currentTimeMillis() - startTime
            
            """{
                "status": "success",
                "poi_name": "$poiName",
                "photo_url": "$photoUrl",
                "execution_time_ms": $executionTime,
                "source": "unsplash"
            }"""
        }
    )
}

// Social Media Reviews Tool
class FetchSocialReviewsTool {
    fun createTool(): Tool = Tool(
        name = "fetch_social_reviews",
        description = "Fetch social media reviews and mentions for podcast generation",
        parameters = mapOf(
            "poi_name" to "Name of the POI",
            "location" to "Location context",
            "sources" to "Review sources to check"
        ),
        execute = { parameters ->
            val poiName = parameters["poi_name"] as? String ?: "Unknown POI"
            val location = parameters["location"] as? String ?: ""
            
            Log.d("ReviewTool", "📝 Fetching reviews for: $poiName")
            
            // Mock reviews for demonstration
            val mockReviews = """
            {
                "status": "success",
                "poi_name": "$poiName",
                "total_reviews": 3,
                "selected_reviews": [
                    {
                        "author": "John D.",
                        "rating": 4.5,
                        "text": "Amazing views of Mount Hood from Lost Lake. Well-maintained trail.",
                        "date": "2025-08-10"
                    },
                    {
                        "author": "Sarah M.",
                        "rating": 5.0,
                        "text": "Lost Lake is a hidden gem! Crystal clear water.",
                        "date": "2025-08-05"
                    }
                ],
                "average_rating": 4.5,
                "podcast_ready": true
            }
            """.trimIndent()
            
            mockReviews
        }
    )
}

// Enhanced Tool Registry
class EnhancedToolRegistry(context: Context) {
    
    private val baseRegistry = ToolRegistry()
    private val exclusionManager = POIExclusionManager(context)
    
    init {
        FetchPOIPhotoTool.context = context
        registerEnhancedTools()
    }
    
    private fun registerEnhancedTools() {
        // Register photo fetching tool
        baseRegistry.register(FetchPOIPhotoTool().createTool())
        
        // Register social reviews tool
        baseRegistry.register(FetchSocialReviewsTool().createTool())
        
        Log.d("EnhancedRegistry", "✅ Enhanced tools registered: fetch_poi_photo, fetch_social_reviews")
    }
    
    fun getTool(name: String): Tool? = baseRegistry.getTool(name)
    
    // Apply exclusions to search results
    suspend fun executeSearchPOIWithExclusions(parameters: Map<String, Any>): String {
        // Call the search_poi tool
        val searchTool = baseRegistry.getTool("search_poi") ?: return "Error: search_poi tool not found"
        val resultString = searchTool.execute(parameters)
        
        // Parse the result to filter excluded POIs
        // For now, return the filtered result as string
        Log.d("EnhancedRegistry", "🔍 Applying POI exclusions...")
        
        // Check for chain exclusions in the result string
        val chainRestaurants = listOf("McDonald's", "Burger King", "Subway", "Starbucks")
        val gasStations = listOf("Shell", "Chevron", "Exxon", "BP")
        
        var filteredResult = resultString
        for (chain in chainRestaurants + gasStations) {
            if (filteredResult.contains(chain)) {
                Log.d("EnhancedRegistry", "❌ Excluding: $chain")
                // Remove lines containing the chain name
                filteredResult = filteredResult.lines()
                    .filter { !it.contains(chain) }
                    .joinToString("\n")
            }
        }
        
        return filteredResult
    }
}

// Data Models
data class POIExclusions(
    val chainRestaurants: List<String>,
    val chainHotels: List<String>,
    val gasStations: List<String>,
    val excludedCategories: List<String>
)

data class POIExclusion(
    val name: String,
    val category: String?,
    val location: String?,
    val distance: Double?
)