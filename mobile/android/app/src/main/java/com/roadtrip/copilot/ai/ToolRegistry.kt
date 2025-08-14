package com.roadtrip.copilot.ai

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.net.URL
import java.net.URLEncoder

/**
 * Tool registry for function calling in Gemma-3N
 */
class ToolRegistry {
    private val tools = mutableMapOf<String, Tool>()
    
    init {
        registerDefaultTools()
    }
    
    fun register(tool: Tool) {
        tools[tool.name] = tool
    }
    
    fun getTool(name: String): Tool? = tools[name]
    
    fun getAllTools(): List<Tool> = tools.values.toList()
    
    private fun registerDefaultTools() {
        // POI Search Tool
        register(Tool(
            name = "search_poi",
            description = "Search for points of interest near a location",
            parameters = mapOf(
                "location" to "The location to search near (city name or coordinates)",
                "category" to "Category of POI (restaurant, hotel, attraction, etc.)"
            ),
            execute = { params ->
                val location = params["location"] as? String ?: ""
                val category = params["category"] as? String ?: "attraction"
                
                // Mock POI results for now - will be replaced with real API
                """
                Found POIs near $location:
                1. Historic Downtown ($category) - 4.5★ - 0.5 miles
                2. Local Museum ($category) - 4.7★ - 1.2 miles
                3. Scenic Overlook ($category) - 4.8★ - 2.3 miles
                4. Hidden Gem Cafe ($category) - 4.6★ - 0.8 miles
                5. Artisan Market ($category) - 4.4★ - 1.5 miles
                """.trimIndent()
            }
        ))
        
        // POI Details Tool
        register(Tool(
            name = "get_poi_details",
            description = "Get detailed information about a specific POI",
            parameters = mapOf(
                "poi_name" to "Name of the point of interest"
            ),
            execute = { params ->
                val poiName = params["poi_name"] as? String ?: "Unknown POI"
                
                """
                $poiName Details:
                - Rating: 4.6/5 (324 reviews)
                - Hours: 9 AM - 6 PM daily
                - Description: A must-visit local attraction with stunning views
                - Highlights: Photo opportunities, local history, gift shop
                - Admission: $12 adults, $8 children
                - Phone: (555) 123-4567
                - Website: www.example.com/${poiName.lowercase().replace(" ", "-")}
                """.trimIndent()
            }
        ))
        
        // Internet Search Tool
        register(Tool(
            name = "search_internet",
            description = "Search the internet for current information",
            parameters = mapOf(
                "query" to "The search query"
            ),
            execute = { params ->
                val query = params["query"] as? String ?: ""
                performDuckDuckGoSearch(query)
            }
        ))
        
        // Directions Tool
        register(Tool(
            name = "get_directions",
            description = "Get navigation directions between two locations",
            parameters = mapOf(
                "from" to "Starting location",
                "to" to "Destination location"
            ),
            execute = { params ->
                val from = params["from"] as? String ?: "Current Location"
                val to = params["to"] as? String ?: "Destination"
                
                """
                Directions from $from to $to:
                - Distance: 15.3 miles
                - Duration: 22 minutes
                - Route: Take Highway 101 North for 12 miles, exit at Main St
                - Traffic: Light traffic, no delays
                - Fuel stops: 2 gas stations along the route
                """.trimIndent()
            }
        ))
    }
    
    private suspend fun performDuckDuckGoSearch(query: String): String = withContext(Dispatchers.IO) {
        try {
            val encodedQuery = URLEncoder.encode(query, "UTF-8")
            val url = URL("https://api.duckduckgo.com/?q=$encodedQuery&format=json&no_html=1")
            
            val connection = url.openConnection()
            connection.setRequestProperty("Accept", "application/json")
            
            val response = connection.getInputStream().bufferedReader().use { it.readText() }
            val json = JSONObject(response)
            
            val results = StringBuilder()
            
            // Extract abstract
            val abstract = json.optString("Abstract", "")
            if (abstract.isNotEmpty()) {
                results.append(abstract).append("\n")
            }
            
            // Extract answer
            val answer = json.optString("Answer", "")
            if (answer.isNotEmpty()) {
                results.append("Direct Answer: ").append(answer).append("\n")
            }
            
            // Extract related topics
            val relatedTopics = json.optJSONArray("RelatedTopics")
            if (relatedTopics != null) {
                for (i in 0 until minOf(3, relatedTopics.length())) {
                    val topic = relatedTopics.optJSONObject(i)
                    val text = topic?.optString("Text", "")
                    if (!text.isNullOrEmpty()) {
                        results.append("\nRelated ${i + 1}: ").append(text).append("\n")
                    }
                }
            }
            
            if (results.isEmpty()) {
                "No specific results found for: $query"
            } else {
                results.toString()
            }
        } catch (e: Exception) {
            "Search error: ${e.message}"
        }
    }
}

/**
 * Tool definition
 */
data class Tool(
    val name: String,
    val description: String,
    val parameters: Map<String, String>,
    val execute: suspend (Map<String, Any>) -> String
)

/**
 * Function call parser
 */
data class FunctionCall(
    val name: String,
    val parameters: Map<String, Any>
) {
    companion object {
        fun parse(response: String): FunctionCall? {
            val trimmed = response.trim()
            
            // Look for JSON function call pattern
            val jsonStart = trimmed.indexOf('{')
            val jsonEnd = trimmed.lastIndexOf('}')
            
            if (jsonStart == -1 || jsonEnd == -1 || jsonStart > jsonEnd) {
                return null
            }
            
            val jsonString = trimmed.substring(jsonStart, jsonEnd + 1)
            
            return try {
                val json = JSONObject(jsonString)
                val name = json.getString("name")
                val parameters = json.getJSONObject("parameters")
                
                val paramMap = mutableMapOf<String, Any>()
                parameters.keys().forEach { key ->
                    paramMap[key] = parameters.get(key)
                }
                
                FunctionCall(name, paramMap)
            } catch (e: Exception) {
                null
            }
        }
    }
}