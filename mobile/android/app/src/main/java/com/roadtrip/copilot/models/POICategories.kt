package com.roadtrip.copilot.models

import android.content.Context

/**
 * POI Categories utility for shared category management
 * This ensures platform parity across iOS, CarPlay, Android, and Android Auto
 */
object POICategories {
    
    fun getCategoryDisplayName(categoryId: String, context: Context): String {
        // For now, provide basic category mapping
        // TODO: Load from shared JSON file
        return when (categoryId.lowercase()) {
            "restaurant", "food" -> "Food & Dining"
            "gas_station", "fuel" -> "Gas Stations"
            "hotel", "lodging", "accommodation" -> "Hotels & Motels"
            "attraction", "tourist_attraction" -> "Tourist Attractions"
            "shopping", "store" -> "Shopping"
            "park", "nature" -> "Parks & Nature"
            "museum" -> "Museums"
            "entertainment" -> "Entertainment"
            "beach" -> "Beaches"
            "scenic_spot", "viewpoint" -> "Scenic Views"
            "historic_site" -> "Historic Sites"
            "winery" -> "Wineries"
            "cafe" -> "Cafés & Coffee"
            "bar" -> "Bars & Nightlife"
            "bakery" -> "Bakeries"
            "campground" -> "Camping & RV"
            "aquarium", "zoo" -> "Aquariums & Zoos"
            "mall" -> "Shopping Malls"
            "atm", "bank" -> "ATM & Banking"
            "pharmacy" -> "Pharmacies"
            "hospital" -> "Medical Services"
            "ev_charging" -> "EV Charging"
            else -> categoryId.replaceFirstChar { it.uppercase() }
        }
    }
    
    fun getCategoryIcon(categoryId: String, context: Context): String {
        return when (categoryId.lowercase()) {
            "restaurant", "food" -> "🍔"
            "gas_station", "fuel" -> "⛽"
            "hotel", "lodging", "accommodation" -> "🏨"
            "attraction", "tourist_attraction" -> "🗽"
            "shopping", "store" -> "🛍️"
            "park", "nature" -> "🌳"
            "museum" -> "🏛️"
            "entertainment" -> "🎭"
            "beach" -> "🏖️"
            "scenic_spot", "viewpoint" -> "🏔️"
            "historic_site" -> "🏛️"
            "winery" -> "🍷"
            "cafe" -> "☕"
            "bar" -> "🍺"
            "bakery" -> "🥖"
            "campground" -> "⛺"
            "aquarium", "zoo" -> "🐠"
            "mall" -> "🏬"
            "atm", "bank" -> "🏦"
            "pharmacy" -> "💊"
            "hospital" -> "🏥"
            "ev_charging" -> "🔌"
            else -> "📍"
        }
    }
    
    fun getDiscoveryWeight(categoryId: String, context: Context): Int {
        return when (categoryId.lowercase()) {
            "restaurant", "food" -> 45
            "scenic_spot", "viewpoint" -> 65
            "hidden_gem" -> 85
            "entertainment" -> 55
            "shopping" -> 25
            "nature", "park" -> 70
            "attraction" -> 60
            "accommodation", "hotel" -> 35
            else -> 35
        }
    }
    
    fun matchCategoryFromVoiceKeywords(query: String, context: Context): String? {
        val lowercaseQuery = query.lowercase()
        
        return when {
            lowercaseQuery.containsAny("restaurant", "food", "eat", "hungry", "lunch", "dinner", "breakfast") -> "food"
            lowercaseQuery.containsAny("park", "beach", "hike", "scenic", "view", "nature", "outdoors", "waterfall", "trail") -> "nature"
            lowercaseQuery.containsAny("hotel", "motel", "stay", "sleep", "lodge", "inn", "camping", "camp") -> "accommodation"
            lowercaseQuery.containsAny("gas", "fuel", "atm", "bank", "pharmacy", "hospital", "medical") -> "services"
            lowercaseQuery.containsAny("attraction", "museum", "fun", "entertainment", "see", "visit", "tour") -> "attractions"
            lowercaseQuery.containsAny("shop", "store", "mall", "buy", "shopping", "market") -> "shopping"
            lowercaseQuery.containsAny("emergency", "help", "urgent") -> "services"
            else -> null
        }
    }
}

private fun String.containsAny(vararg keywords: String): Boolean {
    return keywords.any { this.contains(it) }
}