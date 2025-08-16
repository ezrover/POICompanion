package com.roadtrip.copilot.services

import android.content.Context
import android.content.pm.PackageManager
import android.util.Log
import com.roadtrip.copilot.models.POIData
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.coroutines.delay
import org.json.JSONObject
import java.net.URL
import java.net.URLEncoder
import java.text.DecimalFormat
import kotlin.math.*

/**
 * Google Places API client for POI discovery with automotive safety compliance
 * Performance target: <1000ms response time
 * Equivalent to iOS GooglePlacesAPIClient.swift implementation
 */
class GooglePlacesAPIClient(private val context: Context) {
    
    companion object {
        private const val TAG = "GooglePlacesAPI"
        
        // Performance monitoring
        private const val PERFORMANCE_THRESHOLD_MS = 1000L // 1000ms target
        private const val MINIMUM_REQUEST_INTERVAL_MS = 100L // 100ms between requests
        
        // Automotive safety limits
        private const val MAX_RADIUS_METERS = 50000 // Max 50km for safety
        private const val MAX_RESULTS = 20 // Max 20 results for automotive UI
        
        @Volatile
        private var INSTANCE: GooglePlacesAPIClient? = null
        
        fun getInstance(context: Context): GooglePlacesAPIClient {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: GooglePlacesAPIClient(context.applicationContext).also { INSTANCE = it }
            }
        }
    }
    
    // CRITICAL FIX: Use proper configuration system for API key
    private val apiKey: String by lazy {
        // Priority: BuildConfig -> Manifest meta-data -> Default placeholder
        try {
            // Check BuildConfig for API key (from gradle.properties or build.gradle)
            val buildConfigApiKey = context.getString(context.resources.getIdentifier(
                "google_places_api_key", "string", context.packageName
            ))
            if (buildConfigApiKey.isNotEmpty() && buildConfigApiKey != "YOUR_GOOGLE_PLACES_API_KEY") {
                return@lazy buildConfigApiKey
            }
        } catch (e: Exception) {
            Log.w(TAG, "Could not load API key from resources: ${e.message}")
        }
        
        try {
            // Check manifest meta-data
            val appInfo = context.packageManager.getApplicationInfo(
                context.packageName, PackageManager.GET_META_DATA
            )
            val manifestApiKey = appInfo.metaData?.getString("com.google.android.geo.API_KEY")
            if (!manifestApiKey.isNullOrEmpty()) {
                return@lazy manifestApiKey
            }
        } catch (e: Exception) {
            Log.w(TAG, "Could not load API key from manifest: ${e.message}")
        }
        
        // For now, use placeholder - will be configured in strings.xml or manifest
        Log.w(TAG, "⚠️ No API key configured. Add google_places_api_key to strings.xml or manifest")
        "CONFIGURE_GOOGLE_PLACES_API_KEY_IN_STRINGS_XML"
    }
    private val baseURL = "https://maps.googleapis.com/maps/api/place"
    
    var isProcessing = false
        private set
    var lastError: Exception? = null
        private set
    
    // Rate limiting
    private var lastRequestTime: Long = 0
    
    /**
     * Search for POIs near a location with automotive safety optimizations
     * @param latitude Center point latitude for search
     * @param longitude Center point longitude for search
     * @param category POI category to search for
     * @param radiusMeters Search radius in meters (max 50km for safety)
     * @param maxResults Maximum number of results (limited to 20 for automotive safety)
     * @return List of discovered POIs
     */
    suspend fun searchPOIs(
        latitude: Double,
        longitude: Double,
        category: String,
        radiusMeters: Double = 5000.0,
        maxResults: Int = 10
    ): List<POIData> = withContext(Dispatchers.IO) {
        
        Log.i(TAG, "🔍 [PLACES API] Starting POI search near $latitude, $longitude")
        val requestStartTime = System.currentTimeMillis()
        
        try {
            // Rate limiting check
            val currentTime = System.currentTimeMillis()
            if (currentTime - lastRequestTime < MINIMUM_REQUEST_INTERVAL_MS) {
                delay(MINIMUM_REQUEST_INTERVAL_MS - (currentTime - lastRequestTime))
            }
            lastRequestTime = System.currentTimeMillis()
            
            isProcessing = true
            
            // Validate inputs for automotive safety
            val safeRadius = min(radiusMeters, MAX_RADIUS_METERS.toDouble())
            val safeMaxResults = min(maxResults, MAX_RESULTS)
            
            // Convert category to Google Places type
            val placeType = mapCategoryToGoogleType(category)
            
            // Build request URL
            val location = "$latitude,$longitude"
            val encodedLocation = URLEncoder.encode(location, "UTF-8")
            val encodedType = URLEncoder.encode(placeType, "UTF-8")
            
            val endpoint = "$baseURL/nearbysearch/json" +
                    "?location=$encodedLocation" +
                    "&radius=${safeRadius.toInt()}" +
                    "&type=$encodedType" +
                    "&key=$apiKey"
            
            // Make request with performance monitoring
            val url = URL(endpoint)
            val connection = url.openConnection()
            connection.setRequestProperty("Accept", "application/json")
            connection.connectTimeout = 8000 // 8 second timeout
            connection.readTimeout = 10000 // 10 second read timeout
            
            val response = connection.getInputStream().bufferedReader().use { it.readText() }
            
            // Parse response
            val jsonResponse = JSONObject(response)
            val status = jsonResponse.optString("status")
            
            if (status != "OK" && status != "ZERO_RESULTS") {
                val errorMessage = jsonResponse.optString("error_message", "Unknown error")
                Log.e(TAG, "❌ [PLACES API] API error: $status - $errorMessage")
                throw Exception("Google Places API error ($status): $errorMessage")
            }
            
            // Convert results to POIData
            val results = jsonResponse.optJSONArray("results") ?: return@withContext emptyList()
            val pois = mutableListOf<POIData>()
            
            for (i in 0 until minOf(results.length(), safeMaxResults)) {
                val place = results.getJSONObject(i)
                val poi = convertPlaceToPOI(place, latitude, longitude, category)
                if (poi != null) {
                    pois.add(poi)
                }
            }
            
            // Log performance
            val elapsed = System.currentTimeMillis() - requestStartTime
            if (elapsed > PERFORMANCE_THRESHOLD_MS) {
                Log.w(TAG, "⚠️ [PLACES API] Slow request: ${elapsed}ms (target: ${PERFORMANCE_THRESHOLD_MS}ms)")
            } else {
                Log.i(TAG, "✅ [PLACES API] Request completed in ${elapsed}ms")
            }
            
            Log.i(TAG, "✅ [PLACES API] Found ${pois.size} POIs for category '$category'")
            return@withContext pois
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ [PLACES API] Request failed: ${e.message}", e)
            lastError = e
            throw e
        } finally {
            isProcessing = false
        }
    }
    
    /**
     * Get detailed information about a specific POI
     */
    suspend fun getPOIDetails(placeId: String): PlaceDetails = withContext(Dispatchers.IO) {
        Log.i(TAG, "📋 [PLACES API] Getting details for place ID: $placeId")
        
        val fields = "name,rating,formatted_phone_number,opening_hours,website,reviews,photos"
        val encodedPlaceId = URLEncoder.encode(placeId, "UTF-8")
        val encodedFields = URLEncoder.encode(fields, "UTF-8")
        
        val endpoint = "$baseURL/details/json" +
                "?place_id=$encodedPlaceId" +
                "&fields=$encodedFields" +
                "&key=$apiKey"
        
        val url = URL(endpoint)
        val connection = url.openConnection()
        connection.setRequestProperty("Accept", "application/json")
        
        val response = connection.getInputStream().bufferedReader().use { it.readText() }
        val jsonResponse = JSONObject(response)
        
        val status = jsonResponse.optString("status")
        if (status != "OK") {
            val errorMessage = jsonResponse.optString("error_message", "Unknown error")
            throw Exception("Google Places API error ($status): $errorMessage")
        }
        
        val result = jsonResponse.getJSONObject("result")
        return@withContext PlaceDetails(
            name = result.optString("name", ""),
            rating = result.optDouble("rating", 0.0),
            phoneNumber = result.optString("formatted_phone_number"),
            website = result.optString("website"),
            isOpenNow = result.optJSONObject("opening_hours")?.optBoolean("open_now"),
            weekdayText = result.optJSONObject("opening_hours")
                ?.optJSONArray("weekday_text")
                ?.let { array ->
                    (0 until array.length()).map { array.getString(it) }
                },
            reviews = result.optJSONArray("reviews")?.let { array ->
                (0 until minOf(array.length(), 3)).map { index ->
                    val review = array.getJSONObject(index)
                    PlaceReview(
                        text = review.optString("text", ""),
                        rating = review.optInt("rating", 0),
                        authorName = review.optString("author_name", ""),
                        time = review.optLong("time", 0)
                    )
                }
            } ?: emptyList(),
            photos = result.optJSONArray("photos")?.let { array ->
                (0 until minOf(array.length(), 3)).map { index ->
                    val photo = array.getJSONObject(index)
                    PlacePhoto(
                        photoReference = photo.optString("photo_reference", ""),
                        height = photo.optInt("height", 0),
                        width = photo.optInt("width", 0)
                    )
                }
            } ?: emptyList()
        )
    }
    
    /**
     * Search for nearby POIs for Auto Discover feature
     * Platform parity with iOS implementation
     */
    suspend fun searchNearbyPOIs(
        latitude: Double,
        longitude: Double,
        radius: Double
    ): List<POIData> = withContext(Dispatchers.IO) {
        Log.i(TAG, "🔍 [AUTO DISCOVER] Starting nearby POI search")
        
        val pois = mutableListOf<POIData>()
        
        // Search multiple categories for diverse results
        val categories = listOf(
            "restaurant", "tourist_attraction", "park", "museum", 
            "shopping_mall", "lodging", "gas_station"
        )
        
        for (category in categories) {
            try {
                val categoryPOIs = searchPOIs(
                    latitude = latitude,
                    longitude = longitude,
                    category = category,
                    radiusMeters = radius,
                    maxResults = 5 // Limit per category to avoid too many results
                )
                pois.addAll(categoryPOIs)
                
                // Small delay between requests to avoid rate limiting
                delay(50)
                
            } catch (e: Exception) {
                Log.w(TAG, "Failed to search category $category: ${e.message}")
            }
        }
        
        Log.i(TAG, "✅ [AUTO DISCOVER] Found ${pois.size} total POIs")
        return@withContext pois
    }
    
    /**
     * Get photos for a specific POI
     */
    suspend fun getPhotosForPOI(placeId: String, maxPhotos: Int): List<String> = withContext(Dispatchers.IO) {
        if (placeId.isEmpty()) return@withContext emptyList()
        
        try {
            val details = getPOIDetails(placeId)
            return@withContext details.photos.take(maxPhotos).map { photo ->
                "$baseURL/photo?maxwidth=800&photoreference=${photo.photoReference}&key=$apiKey"
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to get photos for place $placeId: ${e.message}")
            return@withContext emptyList()
        }
    }
    
    // MARK: - Helper Methods
    
    private fun mapCategoryToGoogleType(category: String): String {
        // Map POI categories to Google Places types
        return when (category.lowercase()) {
            "restaurant", "food" -> "restaurant"
            "gas_station" -> "gas_station"
            "lodging", "hotel" -> "lodging"
            "attraction", "tourist_attraction" -> "tourist_attraction"
            "park" -> "park"
            "museum" -> "museum"
            "shopping" -> "shopping_mall"
            "hospital" -> "hospital"
            "pharmacy" -> "pharmacy"
            "bank" -> "bank"
            "atm" -> "atm"
            "church" -> "church"
            "school" -> "school"
            else -> "point_of_interest"
        }
    }
    
    private fun convertPlaceToPOI(
        place: JSONObject, 
        searchLat: Double, 
        searchLng: Double, 
        category: String
    ): POIData? {
        val geometry = place.optJSONObject("geometry") ?: return null
        val location = geometry.optJSONObject("location") ?: return null
        
        val lat = location.optDouble("lat", 0.0)
        val lng = location.optDouble("lng", 0.0)
        
        if (lat == 0.0 && lng == 0.0) return null
        
        // Calculate distance using Haversine formula
        val distance = calculateDistance(searchLat, searchLng, lat, lng)
        
        val name = place.optString("name", "Unknown Place")
        val rating = place.optDouble("rating", 0.0)
        val vicinity = place.optString("vicinity", "")
        val placeId = place.optString("place_id", "")
        
        // Generate image URL from photos
        val photos = place.optJSONArray("photos")
        val imageURL = if (photos != null && photos.length() > 0) {
            val photo = photos.getJSONObject(0)
            val photoReference = photo.optString("photo_reference")
            if (photoReference.isNotEmpty()) {
                "$baseURL/photo?maxwidth=400&photoreference=$photoReference&key=$apiKey"
            } else null
        } else null
        
        // Get review summary and count
        val reviews = place.optJSONArray("reviews")
        val reviewSummary = if (reviews != null && reviews.length() > 0) {
            reviews.getJSONObject(0).optString("text", null)
        } else null
        val reviewCount = place.optInt("user_ratings_total", 0)
        
        // Get photo references for Auto Discover
        val photoReferences = mutableListOf<String>()
        if (photos != null) {
            for (i in 0 until minOf(photos.length(), 5)) {
                val photo = photos.getJSONObject(i)
                val photoRef = photo.optString("photo_reference")
                if (photoRef.isNotEmpty()) {
                    val photoUrl = "$baseURL/photo?maxwidth=800&photoreference=$photoRef&key=$apiKey"
                    photoReferences.add(photoUrl)
                }
            }
        }
        
        return POIData(
            id = placeId.ifEmpty { generatePOIId(name, lat, lng) },
            name = name,
            description = vicinity.ifEmpty { "A point of interest near your location" },
            category = category,
            latitude = lat,
            longitude = lng,
            distanceFromUser = distance,
            rating = rating,
            imageURL = imageURL,
            reviewSummary = reviewSummary,
            couldEarnRevenue = rating >= 4.0, // High-rated places more likely to earn revenue
            address = vicinity.ifEmpty { null },
            priceLevel = place.optInt("price_level", 2),
            
            // Auto Discover Feature Properties
            reviewCount = reviewCount,
            photos = photoReferences,
            placeId = placeId,
            isRecentlyOpened = null, // Not available from basic search
            operatingHours = null // Would need details call
        )
    }
    
    private fun calculateDistance(lat1: Double, lng1: Double, lat2: Double, lng2: Double): Double {
        val earthRadius = 6371.0 // Earth radius in kilometers
        
        val dLat = Math.toRadians(lat2 - lat1)
        val dLng = Math.toRadians(lng2 - lng1)
        
        val a = sin(dLat / 2) * sin(dLat / 2) +
                cos(Math.toRadians(lat1)) * cos(Math.toRadians(lat2)) *
                sin(dLng / 2) * sin(dLng / 2)
        
        val c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        // Convert to miles for consistency with iOS implementation
        return earthRadius * c * 0.621371
    }
    
    private fun generatePOIId(name: String, lat: Double, lng: Double): String {
        val formatter = DecimalFormat("#.####")
        val latStr = formatter.format(lat)
        val lngStr = formatter.format(lng)
        return "${name.hashCode()}_${latStr}_${lngStr}"
    }
}

// MARK: - Data Models

data class PlaceDetails(
    val name: String,
    val rating: Double,
    val phoneNumber: String?,
    val website: String?,
    val isOpenNow: Boolean?,
    val weekdayText: List<String>?,
    val reviews: List<PlaceReview>,
    val photos: List<PlacePhoto>
)

data class PlaceReview(
    val text: String,
    val rating: Int,
    val authorName: String,
    val time: Long
)

data class PlacePhoto(
    val photoReference: String,
    val height: Int,
    val width: Int
)