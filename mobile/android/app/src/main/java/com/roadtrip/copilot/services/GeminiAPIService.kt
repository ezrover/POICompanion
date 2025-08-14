package com.roadtrip.copilot.services

import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import java.io.IOException
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine

/**
 * Gemini API Service for complex language tasks
 * Uses Google's Gemini API as a fallback for tasks requiring sophisticated processing
 * such as distilling social media comments and extracting recommendations
 */
class GeminiAPIService {
    
    companion object {
        private const val TAG = "GeminiAPIService"
        private const val API_KEY = "AIzaSyCE-l9KGCpE6pR-q7csHCkzmS7ugcu_9DU"
        private const val BASE_URL = "https://generativelanguage.googleapis.com/v1beta"
        private const val MODEL = "gemini-pro"
        
        @Volatile
        private var INSTANCE: GeminiAPIService? = null
        
        fun getInstance(): GeminiAPIService {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: GeminiAPIService().also { INSTANCE = it }
            }
        }
    }
    
    private val client = OkHttpClient.Builder()
        .connectTimeout(30, java.util.concurrent.TimeUnit.SECONDS)
        .readTimeout(30, java.util.concurrent.TimeUnit.SECONDS)
        .build()
    
    private val json = Json { 
        ignoreUnknownKeys = true
        isLenient = true
    }
    
    private val _isProcessing = MutableStateFlow(false)
    val isProcessing: StateFlow<Boolean> = _isProcessing
    
    // API Models
    @Serializable
    data class GeminiRequest(
        val contents: List<Content>,
        val generationConfig: GenerationConfig? = null
    ) {
        @Serializable
        data class Content(
            val parts: List<Part>,
            val role: String = "user"
        )
        
        @Serializable
        data class Part(
            val text: String
        )
        
        @Serializable
        data class GenerationConfig(
            val temperature: Double? = 0.7,
            val topK: Int? = 40,
            val topP: Double? = 0.95,
            val maxOutputTokens: Int? = 1000
        )
    }
    
    @Serializable
    data class GeminiResponse(
        val candidates: List<Candidate>? = null,
        val error: ApiError? = null
    ) {
        @Serializable
        data class Candidate(
            val content: Content,
            val finishReason: String? = null
        ) {
            @Serializable
            data class Content(
                val parts: List<Part>,
                val role: String
            )
            
            @Serializable
            data class Part(
                val text: String
            )
        }
        
        @Serializable
        data class ApiError(
            val code: Int,
            val message: String,
            val status: String
        )
    }
    
    /**
     * Distill social media comments to extract insights and recommendations
     */
    suspend fun distillSocialMediaComments(
        comments: List<String>,
        location: String,
        category: String? = null
    ): DistilledInsights = withContext(Dispatchers.IO) {
        val prompt = """
            Analyze these social media comments about $location and extract:
            1. Top recommendations (restaurants, attractions, activities)
            2. Key insights about the location
            3. Common themes and sentiments
            4. Hidden gems or local secrets mentioned
            5. Practical tips for visitors
            
            Comments:
            ${comments.joinToString("\n---\n")}
            
            Provide a structured analysis with specific recommendations.
        """.trimIndent()
        
        val response = sendRequest(prompt, temperature = 0.7)
        parseDistilledInsights(response)
    }
    
    /**
     * Extract POI recommendations from unstructured text
     */
    suspend fun extractPOIRecommendations(
        text: String,
        location: String,
        preferences: List<String> = emptyList()
    ): List<POIRecommendation> = withContext(Dispatchers.IO) {
        val preferencesText = if (preferences.isEmpty()) "" else "User preferences: ${preferences.joinToString(", ")}"
        
        val prompt = """
            Extract specific point of interest recommendations from this text about $location.
            $preferencesText
            
            Text:
            $text
            
            For each POI, provide:
            - Name
            - Category (restaurant, attraction, hotel, etc.)
            - Why it's recommended
            - Best time to visit
            - Estimated cost
            - Any special tips
            
            Format as a clear list.
        """.trimIndent()
        
        val response = sendRequest(prompt, temperature = 0.5)
        parsePOIRecommendations(response)
    }
    
    /**
     * Generate personalized travel itinerary
     */
    suspend fun generateItinerary(
        location: String,
        duration: String,
        interests: List<String>,
        budget: String? = null
    ): TravelItinerary = withContext(Dispatchers.IO) {
        val budgetText = budget?.let { "Budget: $it" } ?: "Budget: Flexible"
        
        val prompt = """
            Create a detailed travel itinerary for $location.
            Duration: $duration
            Interests: ${interests.joinToString(", ")}
            $budgetText
            
            Include:
            - Day-by-day schedule
            - Specific POIs to visit with timings
            - Restaurant recommendations for each meal
            - Transportation tips
            - Estimated costs
            - Alternative options for bad weather
            
            Make it practical and actionable.
        """.trimIndent()
        
        val response = sendRequest(prompt, temperature = 0.8, maxTokens = 2000)
        parseItinerary(response)
    }
    
    /**
     * Analyze reviews to provide summary insights
     */
    suspend fun analyzeReviews(
        reviews: List<String>,
        poiName: String
    ): ReviewAnalysis = withContext(Dispatchers.IO) {
        val prompt = """
            Analyze these reviews for $poiName and provide:
            
            1. Overall sentiment (positive/neutral/negative with percentage)
            2. Top 3 things people love
            3. Top 3 common complaints
            4. Unique features mentioned
            5. Best for what type of visitor
            6. Summary recommendation
            
            Reviews:
            ${reviews.joinToString("\n---\n")}
        """.trimIndent()
        
        val response = sendRequest(prompt, temperature = 0.6)
        parseReviewAnalysis(response)
    }
    
    /**
     * Core API request method
     */
    private suspend fun sendRequest(
        prompt: String,
        temperature: Double = 0.7,
        maxTokens: Int = 1000
    ): String = suspendCoroutine { continuation ->
        _isProcessing.value = true
        
        val endpoint = "$BASE_URL/models/$MODEL:generateContent?key=$API_KEY"
        
        val requestBody = GeminiRequest(
            contents = listOf(
                GeminiRequest.Content(
                    parts = listOf(GeminiRequest.Part(text = prompt))
                )
            ),
            generationConfig = GeminiRequest.GenerationConfig(
                temperature = temperature,
                topK = 40,
                topP = 0.95,
                maxOutputTokens = maxTokens
            )
        )
        
        val jsonBody = json.encodeToString(GeminiRequest.serializer(), requestBody)
        
        val request = Request.Builder()
            .url(endpoint)
            .post(jsonBody.toRequestBody("application/json".toMediaType()))
            .build()
        
        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                _isProcessing.value = false
                Log.e(TAG, "API request failed", e)
                continuation.resumeWithException(e)
            }
            
            override fun onResponse(call: Call, response: Response) {
                _isProcessing.value = false
                
                try {
                    val responseBody = response.body?.string() ?: ""
                    
                    if (!response.isSuccessful) {
                        Log.e(TAG, "API error: ${response.code} - $responseBody")
                        continuation.resumeWithException(
                            Exception("API error: ${response.code}")
                        )
                        return
                    }
                    
                    val geminiResponse = json.decodeFromString(
                        GeminiResponse.serializer(),
                        responseBody
                    )
                    
                    geminiResponse.error?.let { error ->
                        Log.e(TAG, "Gemini error: ${error.message}")
                        continuation.resumeWithException(
                            Exception("Gemini error: ${error.message}")
                        )
                        return
                    }
                    
                    val text = geminiResponse.candidates
                        ?.firstOrNull()
                        ?.content
                        ?.parts
                        ?.firstOrNull()
                        ?.text
                    
                    if (text != null) {
                        continuation.resume(text)
                    } else {
                        continuation.resumeWithException(
                            Exception("No content in response")
                        )
                    }
                    
                } catch (e: Exception) {
                    Log.e(TAG, "Response parsing error", e)
                    continuation.resumeWithException(e)
                }
            }
        })
    }
    
    // Parsing methods
    private fun parseDistilledInsights(response: String): DistilledInsights {
        return DistilledInsights(
            recommendations = extractListItems(response, "recommendations"),
            insights = extractListItems(response, "insights"),
            themes = extractListItems(response, "themes"),
            hiddenGems = extractListItems(response, "hidden gems"),
            tips = extractListItems(response, "tips"),
            rawResponse = response
        )
    }
    
    private fun parsePOIRecommendations(response: String): List<POIRecommendation> {
        val recommendations = mutableListOf<POIRecommendation>()
        val lines = response.lines()
        var currentPOI: POIRecommendation? = null
        
        for (line in lines) {
            val trimmed = line.trim()
            
            when {
                trimmed.startsWith("Name:") || trimmed.startsWith("- ") -> {
                    currentPOI?.let { recommendations.add(it) }
                    val name = trimmed.removePrefix("Name:")
                        .removePrefix("- ")
                        .trim()
                    currentPOI = POIRecommendation(name = name)
                }
                currentPOI != null -> {
                    when {
                        trimmed.startsWith("Category:") -> {
                            currentPOI.category = trimmed.removePrefix("Category:").trim()
                        }
                        trimmed.startsWith("Why:") || trimmed.startsWith("Reason:") -> {
                            currentPOI.reason = trimmed
                                .removePrefix("Why:")
                                .removePrefix("Reason:")
                                .trim()
                        }
                        trimmed.startsWith("Best time:") -> {
                            currentPOI.bestTime = trimmed.removePrefix("Best time:").trim()
                        }
                        trimmed.startsWith("Cost:") -> {
                            currentPOI.estimatedCost = trimmed.removePrefix("Cost:").trim()
                        }
                        trimmed.startsWith("Tips:") -> {
                            currentPOI.tips = trimmed.removePrefix("Tips:").trim()
                        }
                    }
                }
            }
        }
        
        currentPOI?.let { recommendations.add(it) }
        return recommendations
    }
    
    private fun parseItinerary(response: String): TravelItinerary {
        return TravelItinerary(
            days = extractDays(response),
            transportation = extractSection(response, "Transportation"),
            estimatedCost = extractSection(response, "Cost"),
            alternativeOptions = extractListItems(response, "Alternative"),
            rawItinerary = response
        )
    }
    
    private fun parseReviewAnalysis(response: String): ReviewAnalysis {
        return ReviewAnalysis(
            sentiment = extractSection(response, "sentiment") ?: "Neutral",
            positives = extractListItems(response, "love"),
            negatives = extractListItems(response, "complaints"),
            uniqueFeatures = extractListItems(response, "unique"),
            bestFor = extractSection(response, "best for") ?: "General visitors",
            summary = extractSection(response, "summary") ?: response
        )
    }
    
    // Helper methods
    private fun extractListItems(text: String, section: String): List<String> {
        val items = mutableListOf<String>()
        val lines = text.lines()
        var inSection = false
        
        for (line in lines) {
            if (line.lowercase().contains(section.lowercase())) {
                inSection = true
                continue
            }
            
            if (inSection) {
                val trimmed = line.trim()
                when {
                    trimmed.startsWith("-") || 
                    trimmed.startsWith("•") || 
                    trimmed.startsWith("*") -> {
                        val item = trimmed.drop(1).trim()
                        if (item.isNotEmpty()) {
                            items.add(item)
                        }
                    }
                    trimmed.isEmpty() || trimmed.contains(":") -> {
                        if (items.isNotEmpty()) break
                    }
                }
            }
        }
        
        return items
    }
    
    private fun extractSection(text: String, section: String): String? {
        text.lines().forEach { line ->
            if (line.lowercase().contains(section.lowercase())) {
                val parts = line.split(":")
                if (parts.size > 1) {
                    return parts.drop(1).joinToString(":").trim()
                }
            }
        }
        return null
    }
    
    private fun extractDays(text: String): List<ItineraryDay> {
        val days = mutableListOf<ItineraryDay>()
        val lines = text.lines()
        var currentDay: ItineraryDay? = null
        
        for (line in lines) {
            when {
                line.lowercase().contains("day ") -> {
                    currentDay?.let { days.add(it) }
                    currentDay = ItineraryDay(title = line, activities = mutableListOf())
                }
                currentDay != null -> {
                    val trimmed = line.trim()
                    if (trimmed.isNotEmpty() && 
                        (trimmed.startsWith("-") || trimmed.startsWith("•"))) {
                        currentDay.activities.add(trimmed)
                    }
                }
            }
        }
        
        currentDay?.let { days.add(it) }
        return days
    }
}

// Data Models
data class DistilledInsights(
    val recommendations: List<String>,
    val insights: List<String>,
    val themes: List<String>,
    val hiddenGems: List<String>,
    val tips: List<String>,
    val rawResponse: String
)

data class POIRecommendation(
    val name: String,
    var category: String? = null,
    var reason: String? = null,
    var bestTime: String? = null,
    var estimatedCost: String? = null,
    var tips: String? = null
)

data class TravelItinerary(
    val days: List<ItineraryDay>,
    val transportation: String?,
    val estimatedCost: String?,
    val alternativeOptions: List<String>,
    val rawItinerary: String
)

data class ItineraryDay(
    val title: String,
    val activities: MutableList<String>
)

data class ReviewAnalysis(
    val sentiment: String,
    val positives: List<String>,
    val negatives: List<String>,
    val uniqueFeatures: List<String>,
    val bestFor: String,
    val summary: String
)