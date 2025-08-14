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
class FetchPOIPhotoTool : Tool {
    override val name = "fetch_poi_photo"
    override val description = "Fetch a photo for a discovered POI from the internet"
    
    override suspend fun execute(parameters: Map<String, Any>): Map<String, Any> = withContext(Dispatchers.IO) {
        val startTime = System.currentTimeMillis()
        
        val poiName = parameters["poi_name"] as? String
            ?: throw IllegalArgumentException("poi_name is required")
        
        val location = parameters["location"] as? String ?: ""
        
        Log.d("PhotoTool", "📸 Fetching photo for: $poiName at $location")
        
        // Simulate photo search and fetch
        val searchQuery = "$poiName $location".replace(" ", "%20")
        
        val photoUrl = searchForPhoto(searchQuery)
        
        return@withContext if (photoUrl != null) {
            // Download and cache the photo
            val cachedPath = downloadAndCachePhoto(photoUrl, poiName)
            
            val executionTime = System.currentTimeMillis() - startTime
            
            mapOf(
                "status" to "success",
                "poi_name" to poiName,
                "photo_url" to photoUrl,
                "cached_path" to (cachedPath ?: ""),
                "execution_time_ms" to executionTime,
                "source" to "unsplash"
            )
        } else {
            mapOf(
                "status" to "no_photo_found",
                "poi_name" to poiName,
                "placeholder" to true,
                "execution_time_ms" to (System.currentTimeMillis() - startTime)
            )
        }
    }
    
    private suspend fun searchForPhoto(query: String): String? {
        // Mock photo URL - in production, use real API
        val mockPhotos = listOf(
            "https://images.unsplash.com/photo-lost-lake-trail",
            "https://images.unsplash.com/photo-mount-hood-forest",
            "https://images.unsplash.com/photo-oregon-nature"
        )
        
        // Simulate API delay
        delay(200)
        
        return mockPhotos.random()
    }
    
    private fun downloadAndCachePhoto(url: String, poiName: String): String? {
        // Create cache directory
        val cacheDir = File(context.cacheDir, "poi_photos")
        if (!cacheDir.exists()) {
            cacheDir.mkdirs()
        }
        
        val fileName = "${poiName.replace(" ", "_")}.jpg"
        val file = File(cacheDir, fileName)
        
        Log.d("PhotoTool", "💾 Caching photo to: ${file.absolutePath}")
        
        // Mock cache - in production, actually download
        return file.absolutePath
    }
    
    companion object {
        lateinit var context: Context
    }
}

// Social Media Reviews Tool
class FetchSocialReviewsTool : Tool {
    override val name = "fetch_social_reviews"
    override val description = "Fetch social media reviews and mentions for podcast generation"
    
    override suspend fun execute(parameters: Map<String, Any>): Map<String, Any> = withContext(Dispatchers.IO) {
        val startTime = System.currentTimeMillis()
        
        val poiName = parameters["poi_name"] as? String
            ?: throw IllegalArgumentException("poi_name is required")
        
        val location = parameters["location"] as? String ?: ""
        val sources = (parameters["sources"] as? List<String>) ?: listOf("tripadvisor", "yelp", "google")
        
        Log.d("ReviewTool", "📝 Fetching reviews for: $poiName from ${sources.joinToString(", ")}")
        
        val allReviews = mutableListOf<Map<String, Any>>()
        
        for (source in sources) {
            val reviews = fetchReviewsFromSource(source, poiName, location)
            allReviews.addAll(reviews)
        }
        
        // Sort by rating and recency
        allReviews.sortByDescending { (it["rating"] as? Double) ?: 0.0 }
        
        // Take top 5 reviews for podcast generation
        val topReviews = allReviews.take(5)
        
        val executionTime = System.currentTimeMillis() - startTime
        
        Log.d("ReviewTool", "✅ Found ${allReviews.size} reviews, selected top ${topReviews.size} for podcast")
        
        return@withContext mapOf(
            "status" to "success",
            "poi_name" to poiName,
            "total_reviews" to allReviews.size,
            "selected_reviews" to topReviews,
            "sources_checked" to sources,
            "execution_time_ms" to executionTime,
            "podcast_ready" to true,
            "average_rating" to calculateAverageRating(allReviews)
        )
    }
    
    private suspend fun fetchReviewsFromSource(
        source: String,
        poi: String,
        location: String
    ): List<Map<String, Any>> {
        // Simulate API delay
        delay(150)
        
        // Mock reviews - in production, use real APIs
        val mockReviews = listOf(
            mapOf(
                "source" to source,
                "author" to "John D.",
                "rating" to 4.5,
                "text" to "Amazing views of Mount Hood from Lost Lake. The trail is well-maintained and perfect for families.",
                "date" to "2025-08-10",
                "helpful_count" to 42
            ),
            mapOf(
                "source" to source,
                "author" to "Sarah M.",
                "rating" to 5.0,
                "text" to "Lost Lake is a hidden gem! Crystal clear water and the reflection of Mount Hood is breathtaking.",
                "date" to "2025-08-05",
                "helpful_count" to 78
            ),
            mapOf(
                "source" to source,
                "author" to "Mike R.",
                "rating" to 4.0,
                "text" to "Great camping spot. Sites are spacious and the lake access is wonderful. Gets busy on weekends.",
                "date" to "2025-07-28",
                "helpful_count" to 31
            )
        )
        
        Log.d("ReviewTool", "  📊 $source: Found ${mockReviews.size} reviews")
        
        return mockReviews
    }
    
    private fun calculateAverageRating(reviews: List<Map<String, Any>>): Double {
        val ratings = reviews.mapNotNull { it["rating"] as? Double }
        return if (ratings.isEmpty()) 0.0 else ratings.average()
    }
}

// Enhanced Tool Registry
class EnhancedToolRegistry(context: Context) : ToolRegistry() {
    
    private val exclusionManager = POIExclusionManager(context)
    
    init {
        FetchPOIPhotoTool.context = context
        registerEnhancedTools()
    }
    
    private fun registerEnhancedTools() {
        // Register photo fetching tool
        super.register(FetchPOIPhotoTool())
        
        // Register social reviews tool
        super.register(FetchSocialReviewsTool())
        
        Log.d("EnhancedRegistry", "✅ Enhanced tools registered: fetch_poi_photo, fetch_social_reviews")
    }
    
    // Apply exclusions to search results
    suspend fun executeSearchPOIWithExclusions(parameters: Map<String, Any>): Map<String, Any> {
        // Call the search_poi tool
        val searchTool = getTool("search_poi") ?: return mapOf("error" to "search_poi tool not found")
        val result = searchTool.execute(parameters)
        
        val pois = (result["pois"] as? List<Map<String, Any>>) ?: return result
        
        // Filter out excluded POIs
        val filteredPOIs = mutableListOf<Map<String, Any>>()
        var excludedCount = 0
        
        for (poiData in pois) {
            val poi = POIExclusion(
                name = poiData["name"] as? String ?: "",
                category = poiData["category"] as? String,
                location = poiData["location"] as? String,
                distance = poiData["distance"] as? Double
            )
            
            if (!exclusionManager.shouldExcludePOI(poi)) {
                filteredPOIs.add(poiData)
            } else {
                excludedCount++
            }
        }
        
        Log.d("EnhancedRegistry", "🔍 Filtered POIs: ${pois.size} → ${filteredPOIs.size} (excluded $excludedCount)")
        
        return result.toMutableMap().apply {
            this["pois"] = filteredPOIs
            this["excluded_count"] = excludedCount
        }
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