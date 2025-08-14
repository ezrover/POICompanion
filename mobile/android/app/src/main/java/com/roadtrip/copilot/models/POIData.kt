package com.roadtrip.copilot.models

data class POIData(
    val id: String,
    val name: String,
    val description: String,
    val category: String,
    val latitude: Double,
    val longitude: Double,
    val distanceFromUser: Double,
    val rating: Double,
    val imageURL: String?,
    val reviewSummary: String?,
    val couldEarnRevenue: Boolean = false,
    val phoneNumber: String? = null,
    val website: String? = null,
    val address: String? = null,
    val isOpen: Boolean = true,
    val priceLevel: Int = 2 // 1-4 scale
) {
    // Helper function to format distance
    fun getFormattedDistance(): String {
        return when {
            distanceFromUser < 1.0 -> String.format("%.1f mi", distanceFromUser)
            distanceFromUser < 10.0 -> String.format("%.1f mi", distanceFromUser)
            else -> String.format("%.0f mi", distanceFromUser)
        }
    }
    
    // Helper function to get category display name using shared POI categories
    fun getCategoryDisplayName(context: android.content.Context? = null): String {
        return if (context != null) {
            POICategories.getCategoryDisplayName(category, context)
        } else {
            // Fallback for backwards compatibility
            when (category.lowercase()) {
                "restaurant" -> "Restaurant"
                "gas_station" -> "Gas Station"
                "hotel" -> "Hotel"
                "attraction" -> "Attraction"
                "shopping" -> "Shopping"
                "park" -> "Park"
                "museum" -> "Museum"
                "entertainment" -> "Entertainment"
                "beach" -> "Beach"
                "viewpoint" -> "Scenic View"
                "historic_site" -> "Historic Site"
                "winery" -> "Winery"
                else -> category.replaceFirstChar { it.uppercase() }
            }
        }
    }
    
    // Helper function to get category icon using shared POI categories  
    fun getCategoryIcon(context: android.content.Context): String {
        return POICategories.getCategoryIcon(category, context)
    }
    
    // Helper function to get discovery weight for earning potential
    fun getDiscoveryWeight(context: android.content.Context): Int {
        return POICategories.getDiscoveryWeight(category, context)
    }
    
    // Helper function to get rating stars
    fun getRatingStars(): String {
        val fullStars = rating.toInt()
        val hasHalfStar = rating - fullStars >= 0.5
        
        return "★".repeat(fullStars) + 
               (if (hasHalfStar) "☆" else "") + 
               "☆".repeat(5 - fullStars - (if (hasHalfStar) 1 else 0))
    }
    
    // Helper function to check if POI is within a certain distance
    fun isWithinDistance(maxDistance: Double): Boolean {
        return distanceFromUser <= maxDistance
    }
}