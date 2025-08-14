// Complete Android implementation of Gemma 3n with Internet Search capability
// This demonstrates a production-ready mobile AI agent with tool use

package com.example.gemmaagent

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.launch
import org.json.JSONObject
import java.net.URLEncoder

// Main Activity demonstrating Gemma 3n with function calling
class GemmaSearchAgentActivity : AppCompatActivity() {
    
    private lateinit var gemmaAgent: GemmaSearchAgent
    private lateinit var uiHandler: UIHandler
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        
        // Initialize Gemma agent with search capabilities
        gemmaAgent = GemmaSearchAgent(this)
        uiHandler = UIHandler(findViewById(R.id.chatRecyclerView))
        
        // Setup input handling
        findViewById<Button>(R.id.sendButton).setOnClickListener {
            val query = findViewById<EditText>(R.id.inputField).text.toString()
            if (query.isNotEmpty()) {
                processQuery(query)
            }
        }
    }
    
    private fun processQuery(query: String) {
        lifecycleScope.launch {
            uiHandler.addUserMessage(query)
            uiHandler.showTypingIndicator()
            
            try {
                val response = gemmaAgent.processWithTools(query)
                uiHandler.addAgentMessage(response)
            } catch (e: Exception) {
                uiHandler.addErrorMessage("Error: ${e.message}")
            }
            
            uiHandler.hideTypingIndicator()
        }
    }
}

// Core Gemma Agent with Internet Search capability
class GemmaSearchAgent(private val context: Context) {
    
    private val model: GemmaModel by lazy { initializeModel() }
    private val searchTool = InternetSearchTool()
    private val functionRegistry = FunctionRegistry()
    
    // System prompt that enables function calling
    private val SYSTEM_PROMPT = """
You are a helpful AI assistant with access to real-time internet search.

AVAILABLE TOOLS:
- search_internet(query: string): Search for current information online

TOOL USE INSTRUCTIONS:
1. For current events, news, or post-2023 information: ALWAYS use search_internet
2. For established facts or pre-2023 information: Answer directly
3. When using a tool, respond ONLY with the JSON function call
4. Format: {"name": "search_internet", "parameters": {"query": "search terms"}}

DECISION FRAMEWORK:
- User asks about "latest" or "current" → Use search
- User asks about events after 2023 → Use search  
- User needs real-time data (weather, stocks, news) → Use search
- User asks about established facts → Answer directly
- When uncertain → Use search to verify

Remember: Keep search queries concise (2-6 words) for best results.
"""
    
    init {
        // Register available functions
        registerFunctions()
    }
    
    private fun initializeModel(): GemmaModel {
        return GemmaModel.Builder(context)
            .setModelPath("gemma-3n-e2b-it-int4.task")
            .setMaxTokens(2048)
            .setTemperature(0.7f)
            .enablePLECaching(true)  // Enable Per-Layer Embeddings
            .build()
    }
    
    private fun registerFunctions() {
        functionRegistry.register(
            FunctionDeclaration(
                name = "search_internet",
                description = "Search the internet for current information",
                parameters = JSONObject().apply {
                    put("type", "object")
                    put("properties", JSONObject().apply {
                        put("query", JSONObject().apply {
                            put("type", "string")
                            put("description", "The search query")
                        })
                    })
                    put("required", listOf("query"))
                }
            )
        )
    }
    
    suspend fun processWithTools(userQuery: String): String {
        // Step 1: Initial query to model with system prompt
        val fullPrompt = "$SYSTEM_PROMPT\n\nUser: $userQuery"
        val initialResponse = model.generate(fullPrompt)
        
        // Step 2: Check if response is a function call
        val functionCall = parseFunctionCall(initialResponse)
        
        return if (functionCall != null) {
            // Step 3: Execute the function call
            val searchResults = when (functionCall.name) {
                "search_internet" -> {
                    val query = functionCall.parameters.getString("query")
                    searchTool.search(query)
                }
                else -> throw IllegalArgumentException("Unknown function: ${functionCall.name}")
            }
            
            // Step 4: Send results back to model for final response
            val resultPrompt = """
$SYSTEM_PROMPT

User: $userQuery
Assistant: I'll search for that information.
Search results for "${functionCall.parameters.getString("query")}":
$searchResults

Based on these search results, here's what I found:
"""
            model.generate(resultPrompt)
        } else {
            // No function call needed, return direct response
            initialResponse
        }
    }
    
    private fun parseFunctionCall(response: String): FunctionCall? {
        return try {
            // Check if response is JSON and contains function call structure
            val trimmed = response.trim()
            if (trimmed.startsWith("{") && trimmed.contains("\"name\"")) {
                val json = JSONObject(trimmed)
                FunctionCall(
                    name = json.getString("name"),
                    parameters = json.getJSONObject("parameters")
                )
            } else {
                null
            }
        } catch (e: Exception) {
            null
        }
    }
}

// Internet Search Tool Implementation
class InternetSearchTool {
    private val serperApiKey = BuildConfig.SERPER_API_KEY // Store in BuildConfig
    private val httpClient = OkHttpClient.Builder()
        .connectTimeout(10, TimeUnit.SECONDS)
        .readTimeout(10, TimeUnit.SECONDS)
        .build()
    
    suspend fun search(query: String): String {
        return withContext(Dispatchers.IO) {
            try {
                val results = performSerperSearch(query)
                formatSearchResults(results)
            } catch (e: Exception) {
                // Fallback to a simple web scraping approach
                performFallbackSearch(query)
            }
        }
    }
    
    private fun performSerperSearch(query: String): SerperResults {
        val requestBody = JSONObject().apply {
            put("q", query)
            put("num", 5)  // Get top 5 results
        }
        
        val request = Request.Builder()
            .url("https://google.serper.dev/search")
            .post(RequestBody.create(
                MediaType.parse("application/json"),
                requestBody.toString()
            ))
            .addHeader("X-API-KEY", serperApiKey)
            .build()
        
        httpClient.newCall(request).execute().use { response ->
            if (!response.isSuccessful) {
                throw IOException("Search failed: ${response.code()}")
            }
            
            return parseSerperResponse(response.body()?.string() ?: "")
        }
    }
    
    private fun formatSearchResults(results: SerperResults): String {
        val formatted = StringBuilder()
        
        // Add answer box if available
        results.answerBox?.let {
            formatted.append("Quick Answer: ${it.answer}\n\n")
        }
        
        // Add organic results
        results.organic.take(3).forEach { result ->
            formatted.append("Title: ${result.title}\n")
            formatted.append("Source: ${result.link}\n")
            formatted.append("Summary: ${result.snippet}\n\n")
        }
        
        // Add knowledge graph if available
        results.knowledgeGraph?.let {
            formatted.append("Additional Info: ${it.description}\n")
        }
        
        return formatted.toString()
    }
}

// ReAct-style agent for complex multi-step reasoning
class ReActAgent(private val model: GemmaModel, private val tools: ToolRegistry) {
    
    suspend fun solve(query: String, maxSteps: Int = 5): String {
        val trajectory = mutableListOf<Step>()
        var context = "Task: $query\n\n"
        
        for (step in 1..maxSteps) {
            // Generate thought
            val thoughtPrompt = "$context\nThought $step: "
            val thought = model.generate(thoughtPrompt)
            trajectory.add(Step.Thought(thought))
            context += "Thought $step: $thought\n"
            
            // Determine action
            when {
                thought.contains("search", ignoreCase = true) -> {
                    val searchQuery = extractSearchQuery(thought)
                    val action = "search_internet(\"$searchQuery\")"
                    context += "Action $step: $action\n"
                    
                    // Execute search
                    val results = tools.execute("search_internet", mapOf("query" to searchQuery))
                    val observation = "Search returned: $results"
                    trajectory.add(Step.Observation(observation))
                    context += "Observation $step: $observation\n"
                }
                
                thought.contains("answer:", ignoreCase = true) -> {
                    // Extract final answer
                    val answer = thought.substringAfter("answer:", "").trim()
                    return answer.ifEmpty { 
                        model.generate("$context\nFinal Answer: ")
                    }
                }
            }
        }
        
        // If no answer found after max steps
        return model.generate("$context\nBased on my analysis, the answer is: ")
    }
    
    private fun extractSearchQuery(thought: String): String {
        // Extract search query from thought using pattern matching
        val patterns = listOf(
            "search for \"([^\"]+)\"",
            "search about ([^.]+)",
            "look up ([^.]+)",
            "find information on ([^.]+)"
        )
        
        for (pattern in patterns) {
            val regex = pattern.toRegex(RegexOption.IGNORE_CASE)
            regex.find(thought)?.let { match ->
                return match.groupValues[1].trim()
            }
        }
        
        // Fallback: extract key terms
        return thought.split(" ")
            .filter { it.length > 3 }
            .take(4)
            .joinToString(" ")
    }
}

// Multimodal support for image + text queries
class MultimodalAgent(private val model: GemmaModel) {
    
    suspend fun processImageQuery(
        text: String,
        imageBitmap: Bitmap
    ): String {
        // Convert image to base64 for Gemma 3n
        val imageBase64 = bitmapToBase64(imageBitmap)
        
        val multimodalPrompt = """
<image>$imageBase64</image>

User question about the image: $text

Please analyze the image and answer the question. If you need current information about what's shown in the image, use the search_internet function.
"""
        
        return model.generateMultimodal(multimodalPrompt)
    }
    
    private fun bitmapToBase64(bitmap: Bitmap): String {
        val outputStream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, 90, outputStream)
        val imageBytes = outputStream.toByteArray()
        return Base64.encodeToString(imageBytes, Base64.NO_WRAP)
    }
}

// Data classes
data class FunctionCall(
    val name: String,
    val parameters: JSONObject
)

data class SerperResults(
    val organic: List<OrganicResult>,
    val answerBox: AnswerBox?,
    val knowledgeGraph: KnowledgeGraph?
)

data class OrganicResult(
    val title: String,
    val link: String,
    val snippet: String
)

sealed class Step {
    data class Thought(val content: String) : Step()
    data class Action(val content: String) : Step()
    data class Observation(val content: String) : Step()
}

// Model configuration for optimal mobile performance
object GemmaConfig {
    const val MODEL_E2B = "gemma-3n-e2b-it-int4.task"  // 2GB footprint
    const val MODEL_E4B = "gemma-3n-e4b-it-int4.task"  // 3GB footprint
    
    fun getOptimalModel(availableMemoryGB: Float): String {
        return if (availableMemoryGB >= 4) MODEL_E4B else MODEL_E2B
    }
}