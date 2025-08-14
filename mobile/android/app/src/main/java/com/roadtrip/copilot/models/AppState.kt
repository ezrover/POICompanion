package com.roadtrip.copilot.models

// MARK: - App Screen States

enum class AppScreen {
    DESTINATION_SELECTION,
    POI_RESULT,
    MAIN_DASHBOARD
}

// MARK: - Destination Data

data class DestinationInfo(
    val name: String,
    val address: String,
    val latitude: Double,
    val longitude: Double,
    val estimatedDuration: Long? = null,
    val distance: Double? = null
)

// MARK: - Navigation State

enum class NavigationState {
    PLANNING,
    NAVIGATING,
    ARRIVED,
    EXPLORING
}