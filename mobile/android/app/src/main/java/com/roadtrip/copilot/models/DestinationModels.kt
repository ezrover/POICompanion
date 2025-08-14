package com.roadtrip.copilot.models

data class DestinationSearchResult(
    val name: String,
    val latitude: Double,
    val longitude: Double,
    val address: String = "",
    val placeId: String = "",
    val types: List<String> = emptyList()
) {
    fun toDestinationInfo(): DestinationInfo {
        return DestinationInfo(
            name = name,
            address = address,
            latitude = latitude,
            longitude = longitude
        )
    }
}

