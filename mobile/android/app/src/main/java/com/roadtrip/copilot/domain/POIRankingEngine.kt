package com.roadtrip.copilot.domain

import android.content.Context
import android.content.SharedPreferences
import com.roadtrip.copilot.models.POIData
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlin.math.*

/**
 * POI ranking engine that prioritizes POIs based on multiple factors
 * Platform parity with iOS POIRankingEngine.swift
 */
class POIRankingEngine(private val context: Context) {
    
    // MARK: - Ranking Weights (matching iOS implementation)
    private val ratingWeight: Double = 0.3
    private val proximityWeight: Double = 0.25
    private val popularityWeight: Double = 0.2
    private val categoryWeight: Double = 0.15
    private val reviewCountWeight: Double = 0.1
    
    // MARK: - User Preferences
    private val sharedPreferences: SharedPreferences = 
        context.getSharedPreferences("poi_ranking_prefs", Context.MODE_PRIVATE)
    
    private var preferredCategories: MutableList<String> = mutableListOf()
    private var avoidedCategories: MutableList<String> = mutableListOf()
    
    init {
        loadUserPreferences()
    }
    
    // MARK: - Public Methods
    
    /**
     * Ranks POIs based on multiple factors and user preferences
     */
    suspend fun rankPOIs(pois: List<POIData>, userLatitude: Double, userLongitude: Double): List<POIData> {
        if (pois.isEmpty()) return emptyList()
        
        return withContext(Dispatchers.Default) {
            val rankedPOIs = mutableListOf<Pair<POIData, Double>>()
            
            // Calculate max distance for normalization
            val maxDistance = pois.maxOfOrNull { poi ->
                calculateDistance(userLatitude, userLongitude, poi.latitude, poi.longitude)
            } ?: 1.0
            
            // Calculate scores for each POI
            for (poi in pois) {
                val score = calculatePOIScore(poi, userLatitude, userLongitude, maxDistance)
                rankedPOIs.add(Pair(poi, score))
            }
            
            // Sort by score (highest first)
            rankedPOIs.sortByDescending { it.second }
            
            // Return sorted POIs
            val sortedPOIs = rankedPOIs.map { it.first }
            
            println("[POIRankingEngine] Ranked ${sortedPOIs.size} POIs")
            sortedPOIs
        }
    }
    
    /**
     * Updates user preferences based on interactions
     */
    fun updateUserPreferencesLiked(likedPOI: POIData) {
        val category = likedPOI.category
        
        // Add to preferred categories if not already present
        if (!preferredCategories.contains(category)) {
            preferredCategories.add(category)
            saveUserPreferences()
        }
        
        println("[POIRankingEngine] Updated preferences - liked category: $category")
    }
    
    /**
     * Updates user preferences for disliked POIs
     */
    fun updateUserPreferencesDisliked(dislikedPOI: POIData) {
        val category = dislikedPOI.category
        
        // Add to avoided categories if not already present
        if (!avoidedCategories.contains(category)) {
            avoidedCategories.add(category)
            saveUserPreferences()
        }
        
        println("[POIRankingEngine] Updated preferences - disliked category: $category")
    }
    
    // MARK: - Private Methods
    
    private fun calculatePOIScore(poi: POIData, userLatitude: Double, userLongitude: Double, maxDistance: Double): Double {
        var totalScore = 0.0
        
        // 1. Rating Score (0-1)
        val ratingScore = normalizeRating(poi.rating)
        totalScore += ratingScore * ratingWeight
        
        // 2. Proximity Score (0-1, closer is better)
        val proximityScore = calculateProximityScore(poi, userLatitude, userLongitude, maxDistance)
        totalScore += proximityScore * proximityWeight
        
        // 3. Popularity Score (based on review count)
        val popularityScore = normalizePopularity(poi.reviewCount)
        totalScore += popularityScore * popularityWeight
        
        // 4. Category Preference Score (0-1)
        val categoryScore = calculateCategoryScore(poi)
        totalScore += categoryScore * categoryWeight
        
        // 5. Review Count Score (0-1)
        val reviewScore = normalizeReviewCount(poi.reviewCount)
        totalScore += reviewScore * reviewCountWeight
        
        // Apply bonus factors
        totalScore = applyBonusFactors(totalScore, poi)
        
        return minOf(totalScore, 1.0) // Cap at 1.0
    }
    
    private fun normalizeRating(rating: Double): Double {
        // Normalize rating from 0-5 scale to 0-1 scale
        return minOf(maxOf(rating / 5.0, 0.0), 1.0)
    }
    
    private fun calculateProximityScore(poi: POIData, userLatitude: Double, userLongitude: Double, maxDistance: Double): Double {
        val distance = calculateDistance(userLatitude, userLongitude, poi.latitude, poi.longitude)
        
        // Inverse proximity - closer locations get higher scores
        return 1.0 - (distance / maxDistance)
    }
    
    private fun calculateDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double): Double {
        val earthRadius = 6371000.0 // meters
        
        val dLat = Math.toRadians(lat2 - lat1)
        val dLon = Math.toRadians(lon2 - lon1)
        
        val a = sin(dLat / 2) * sin(dLat / 2) +
                cos(Math.toRadians(lat1)) * cos(Math.toRadians(lat2)) *
                sin(dLon / 2) * sin(dLon / 2)
        
        val c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        return earthRadius * c
    }
    
    private fun normalizePopularity(reviewCount: Int): Double {
        // Logarithmic scale for review count to prevent outliers from dominating
        if (reviewCount <= 0) return 0.0
        
        val logReviews = ln(reviewCount.toDouble() + 1)
        val maxLogReviews = ln(1001.0) // Assume max of 1000 reviews
        
        return minOf(logReviews / maxLogReviews, 1.0)
    }
    
    private fun calculateCategoryScore(poi: POIData): Double {
        val category = poi.category
        
        // Boost preferred categories
        if (preferredCategories.contains(category)) {
            return 1.0
        }
        
        // Penalize avoided categories
        if (avoidedCategories.contains(category)) {
            return 0.2
        }
        
        // Default score for neutral categories
        return 0.6
    }
    
    private fun normalizeReviewCount(reviewCount: Int): Double {
        // More reviews generally indicate higher credibility
        return when (reviewCount) {
            in 0..5 -> 0.2
            in 6..20 -> 0.4
            in 21..50 -> 0.6
            in 51..100 -> 0.8
            else -> 1.0
        }
    }
    
    private fun applyBonusFactors(baseScore: Double, poi: POIData): Double {
        var score = baseScore
        
        // Highly rated bonus (4.5+ stars)
        if (poi.rating >= 4.5) {
            score += 0.1
        }
        
        // High review count bonus (100+ reviews)
        if (poi.reviewCount >= 100) {
            score += 0.05
        }
        
        // Photo availability bonus
        if (poi.photos.isNotEmpty()) {
            score += 0.02
        }
        
        // Price level bonus (if available and reasonable)
        poi.priceLevel?.let { priceLevel ->
            if (priceLevel <= 2) { // Affordable places get a small bonus
                score += 0.02
            }
        }
        
        return score
    }
    
    // MARK: - Time-based Filtering
    
    /**
     * Filters POIs based on current time and operating hours
     */
    fun filterByOperatingHours(pois: List<POIData>): List<POIData> {
        // Simplified implementation - in real app would parse operating hours
        // For now, return all POIs (assume open)
        return pois
    }
    
    // MARK: - Distance-based Filtering
    
    /**
     * Filters POIs by maximum distance
     */
    fun filterByDistance(pois: List<POIData>, userLatitude: Double, userLongitude: Double, maxDistance: Double): List<POIData> {
        return pois.filter { poi ->
            val distance = calculateDistance(userLatitude, userLongitude, poi.latitude, poi.longitude)
            distance <= maxDistance
        }
    }
    
    // MARK: - Persistence
    
    private fun loadUserPreferences() {
        preferredCategories = sharedPreferences.getStringSet("preferred_poi_categories", emptySet())?.toMutableList() ?: mutableListOf()
        avoidedCategories = sharedPreferences.getStringSet("avoided_poi_categories", emptySet())?.toMutableList() ?: mutableListOf()
        
        println("[POIRankingEngine] Loaded preferences - preferred: ${preferredCategories.size}, avoided: ${avoidedCategories.size}")
    }
    
    private fun saveUserPreferences() {
        sharedPreferences.edit()
            .putStringSet("preferred_poi_categories", preferredCategories.toSet())
            .putStringSet("avoided_poi_categories", avoidedCategories.toSet())
            .apply()
        
        println("[POIRankingEngine] Saved user preferences")
    }
}

// MARK: - POI Model Extensions

/**
 * Extension to add additional properties to POIData for ranking
 */
data class EnhancedPOIData(
    val poi: POIData,
    val isRecentlyOpened: Boolean? = null,
    val hasPhotos: Boolean? = null,
    val operatingHours: Map<String, String>? = null,
    val priceLevel: Int? = null
) {
    // Delegate POIData properties
    val id: String get() = poi.id
    val name: String get() = poi.name
    val description: String get() = poi.description
    val latitude: Double get() = poi.latitude
    val longitude: Double get() = poi.longitude
    val category: String get() = poi.category
    val rating: Double get() = poi.rating
    val reviewCount: Int get() = poi.reviewCount
    val photos: List<String> get() = poi.photos
}