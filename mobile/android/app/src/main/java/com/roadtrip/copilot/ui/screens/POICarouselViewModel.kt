package com.roadtrip.copilot.ui.screens

import android.app.Application
import android.util.Log
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateMapOf
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.roadtrip.copilot.ai.EnhancedToolRegistry
import kotlinx.coroutines.launch

class POICarouselViewModel(application: Application) : AndroidViewModel(application) {
    
    companion object {
        private const val TAG = "POICarouselVM"
        
        val mockPOIs = listOf(
            POIItem(
                id = "1",
                name = "Lost Lake Trail",
                category = "Hiking",
                distance = 0.1,
                rating = 4.5,
                description = "A scenic 3.4-mile loop trail around Lost Lake with stunning views of Mount Hood.",
                tags = listOf("Easy-Moderate", "Dog-Friendly", "Lake Views", "Photography")
            ),
            POIItem(
                id = "2",
                name = "Lost Lake Resort",
                category = "Lodging",
                distance = 0.2,
                rating = 4.3,
                description = "Peaceful lakeside resort offering rustic cabins, boat rentals, and a general store.",
                tags = listOf("Cabins", "Boat Rental", "Restaurant", "WiFi")
            ),
            POIItem(
                id = "3",
                name = "Tamanawas Falls Trail",
                category = "Hiking",
                distance = 8.7,
                rating = 4.7,
                description = "Moderate 3.6-mile hike to a spectacular 100-foot waterfall through old-growth forest.",
                tags = listOf("Waterfall", "Moderate", "Forest", "Photography")
            )
        )
    }
    
    val pois = mutableStateListOf<POIItem>()
    val photos = mutableStateMapOf<String, String>()
    val reviews = mutableStateMapOf<String, List<Review>>()
    
    private val toolRegistry = EnhancedToolRegistry(application)
    
    fun loadPOIs(items: List<POIItem>) {
        pois.clear()
        pois.addAll(items)
        Log.d(TAG, "📍 Loaded ${items.size} POIs for carousel")
    }
    
    fun startFetchingData() {
        viewModelScope.launch {
            fetchPhotosAndReviews()
        }
    }
    
    private suspend fun fetchPhotosAndReviews() {
        for (poi in pois) {
            // Fetch photo
            val photoTool = toolRegistry.getTool("fetch_poi_photo")
            if (photoTool != null) {
                try {
                    val resultJson = photoTool.execute(
                        mapOf(
                            "poi_name" to poi.name,
                            "location" to "Lost Lake, Oregon"
                        )
                    )
                    
                    // Parse JSON string result
                    val result = try {
                        org.json.JSONObject(resultJson)
                    } catch (e: Exception) {
                        null
                    }
                    
                    if (result != null) {
                        Log.d(TAG, "📸 Photo fetch result for ${poi.name}: ${result.optString("status")}")
                        
                        // Store photo URL
                        val photoUrl = result.optString("photo_url")
                        if (photoUrl.isNotEmpty()) {
                            photos[poi.id] = photoUrl
                        }
                        
                        // Log execution time
                        val executionTime = result.optLong("execution_time_ms", 0)
                        Log.d(TAG, "   Execution time: ${executionTime}ms")
                    }
                    
                } catch (e: Exception) {
                    Log.e(TAG, "❌ Failed to fetch photo for ${poi.name}", e)
                }
            }
            
            // Fetch reviews
            val reviewTool = toolRegistry.getTool("fetch_social_reviews")
            if (reviewTool != null) {
                try {
                    val resultJson = reviewTool.execute(
                        mapOf(
                            "poi_name" to poi.name,
                            "location" to "Lost Lake, Oregon",
                            "sources" to listOf("tripadvisor", "yelp", "google")
                        )
                    )
                    
                    // Parse JSON string result
                    val result = try {
                        org.json.JSONObject(resultJson)
                    } catch (e: Exception) {
                        null
                    }
                    
                    if (result != null) {
                        val selectedReviewsArray = result.optJSONArray("selected_reviews")
                        
                        if (selectedReviewsArray != null) {
                            val mappedReviews = mutableListOf<Review>()
                            
                            for (i in 0 until selectedReviewsArray.length()) {
                                val reviewObj = selectedReviewsArray.getJSONObject(i)
                                try {
                                    mappedReviews.add(Review(
                                        author = reviewObj.getString("author"),
                                        rating = reviewObj.getDouble("rating"),
                                        text = reviewObj.getString("text"),
                                        date = reviewObj.optString("date", ""),
                                        source = reviewObj.optString("source", "")
                                    ))
                                } catch (e: Exception) {
                                    // Skip invalid review
                                }
                            }
                            
                            reviews[poi.id] = mappedReviews
                            
                            Log.d(TAG, "📝 Fetched ${mappedReviews.size} reviews for ${poi.name}")
                            Log.d(TAG, "   Average rating: ${result.optDouble("average_rating", 0.0)}")
                            Log.d(TAG, "   Podcast ready: ${result.optBoolean("podcast_ready", false)}")
                        }
                    }
                    
                } catch (e: Exception) {
                    Log.e(TAG, "❌ Failed to fetch reviews for ${poi.name}", e)
                }
            }
        }
        
        // Log summary
        Log.d(TAG, "✅ Data fetching complete:")
        Log.d(TAG, "   Photos fetched: ${photos.size}")
        Log.d(TAG, "   POIs with reviews: ${reviews.size}")
    }
    
    fun navigateToPOI(index: Int) {
        if (index < pois.size) {
            val poi = pois[index]
            Log.d(TAG, "🗺️ Navigating to: ${poi.name}")
            // Trigger navigation intent
        }
    }
    
    fun sharePOI(index: Int) {
        if (index < pois.size) {
            val poi = pois[index]
            Log.d(TAG, "📤 Sharing: ${poi.name}")
            // Trigger share intent
        }
    }
    
    fun logNavigation(index: Int, direction: String) {
        if (index < pois.size) {
            val poi = pois[index]
            Log.d(TAG, "🔄 Navigated $direction to: ${poi.name} (index: $index)")
        }
    }
}