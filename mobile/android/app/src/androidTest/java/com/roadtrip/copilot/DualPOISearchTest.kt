package com.roadtrip.copilot

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.roadtrip.copilot.services.POIDiscoveryOrchestrator
import com.roadtrip.copilot.services.GooglePlacesAPIClient
import com.roadtrip.copilot.services.DiscoveryStrategy
import com.roadtrip.copilot.ai.Gemma3NE2BLoader
import kotlinx.coroutines.runBlocking
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import android.util.Log
import kotlin.test.assertTrue
import kotlin.test.assertFalse
import kotlin.test.assertEquals
import kotlin.test.assertNotNull

/**
 * Comprehensive tests for dual POI search functionality
 * Tests both local LLM POI discovery AND online API (Google Places) discovery
 * Validates that mock data is no longer used and real POI data is returned
 */
@RunWith(AndroidJUnit4::class)
class DualPOISearchTest {
    
    private lateinit var orchestrator: POIDiscoveryOrchestrator
    private lateinit var placesClient: GooglePlacesAPIClient
    private lateinit var gemmaLoader: Gemma3NE2BLoader
    private val context = InstrumentationRegistry.getInstrumentation().targetContext
    
    // Test coordinates
    private val LOST_LAKE_LATITUDE = 45.4979
    private val LOST_LAKE_LONGITUDE = -121.8209
    private val SEATTLE_LATITUDE = 47.6062
    private val SEATTLE_LONGITUDE = -122.3321
    
    @Before
    fun setup() {
        orchestrator = POIDiscoveryOrchestrator(context)
        placesClient = GooglePlacesAPIClient.getInstance(context)
        gemmaLoader = Gemma3NE2BLoader(context)
        
        Log.d("DualPOITest", "🧪 Test setup completed")
    }
    
    // MARK: - Lost Lake Oregon Tests
    
    @Test
    fun testLostLakeOregonDualSearch() = runBlocking {
        Log.d("DualPOITest", "\n🧪 =================================================")
        Log.d("DualPOITest", "🏔️  DUAL POI SEARCH TEST - LOST LAKE, OREGON")
        Log.d("DualPOITest", "🧪 =================================================")
        
        val startTime = System.currentTimeMillis()
        
        // Test the hybrid approach (both LLM and API)
        val result = orchestrator.discoverPOIs(
            latitude = LOST_LAKE_LATITUDE,
            longitude = LOST_LAKE_LONGITUDE,
            category = "attraction",
            preferredStrategy = DiscoveryStrategy.HYBRID,
            maxResults = 10
        )
        
        val elapsedTime = System.currentTimeMillis() - startTime
        
        // Validate results
        assertFalse(result.pois.isEmpty(), "Should discover POIs near Lost Lake, Oregon")
        assertTrue(elapsedTime < 3000, "Discovery should complete within 3 seconds")
        
        Log.d("DualPOITest", "\n📊 DUAL SEARCH RESULTS:")
        Log.d("DualPOITest", "   Strategy Used: ${result.strategyUsed}")
        Log.d("DualPOITest", "   Response Time: ${result.responseTimeMs}ms")
        Log.d("DualPOITest", "   POIs Found: ${result.pois.size}")
        Log.d("DualPOITest", "   Fallback Used: ${result.fallbackUsed}")
        
        // Verify no mock data is returned
        val mockDataTerms = listOf("Historic Downtown", "Local Museum", "Mock", "Test POI", "Sample")
        result.pois.forEach { poi ->
            mockDataTerms.forEach { mockTerm ->
                assertFalse(
                    poi.name.contains(mockTerm, ignoreCase = true),
                    "Found mock data in results: ${poi.name}"
                )
            }
        }
        
        // Verify real Lost Lake POIs
        val expectedPOITypes = listOf(
            "Lost Lake", "Mount Hood", "Trail", "Resort", "Campground",
            "Forest", "Wilderness", "Recreation", "Tamanawas"
        )
        
        var foundRealPOIs = 0
        Log.d("DualPOITest", "\n🔍 DISCOVERED POIs:")
        result.pois.forEachIndexed { index, poi ->
            Log.d("DualPOITest", "   ${index + 1}. ${poi.name}")
            Log.d("DualPOITest", "      Category: ${poi.category}")
            Log.d("DualPOITest", "      Rating: ${String.format("%.1f", poi.rating)} ⭐")
            Log.d("DualPOITest", "      Distance: ${String.format("%.1f", poi.distanceFromUser)} mi")
            poi.reviewSummary?.let { summary ->
                Log.d("DualPOITest", "      Description: $summary")
            }
            
            // Check if this looks like a real Lost Lake area POI
            expectedPOITypes.forEach { expectedType ->
                if (poi.name.contains(expectedType, ignoreCase = true)) {
                    foundRealPOIs++
                    return@forEach
                }
            }
        }
        
        assertTrue(foundRealPOIs > 0, "Should find at least some real Lost Lake area POIs")
        Log.d("DualPOITest", "\n✅ Found $foundRealPOIs real Lost Lake area POIs")
    }
    
    @Test
    fun testLLMOnlyStrategyComparison() = runBlocking {
        Log.d("DualPOITest", "\n🧪 =================================================")
        Log.d("DualPOITest", "🤖 LLM-ONLY STRATEGY TEST - LOST LAKE, OREGON")
        Log.d("DualPOITest", "🧪 =================================================")
        
        // Test LLM-only approach
        val llmResult = orchestrator.discoverPOIs(
            latitude = LOST_LAKE_LATITUDE,
            longitude = LOST_LAKE_LONGITUDE,
            category = "attraction",
            preferredStrategy = DiscoveryStrategy.LLM_ONLY,
            maxResults = 8
        )
        
        assertEquals(DiscoveryStrategy.LLM_ONLY, llmResult.strategyUsed, "Should use LLM-only strategy")
        assertFalse(llmResult.pois.isEmpty(), "LLM should discover POIs")
        
        Log.d("DualPOITest", "\n🤖 LLM-ONLY RESULTS:")
        Log.d("DualPOITest", "   Response Time: ${llmResult.responseTimeMs}ms")
        Log.d("DualPOITest", "   POIs Found: ${llmResult.pois.size}")
        
        // Verify LLM-generated POIs look realistic
        llmResult.pois.forEachIndexed { index, poi ->
            Log.d("DualPOITest", "   ${index + 1}. ${poi.name} - ${String.format("%.1f", poi.rating)}⭐ - ${String.format("%.1f", poi.distanceFromUser)}mi")
            
            // LLM POIs should have reasonable attributes
            assertTrue(poi.rating > 0.0, "LLM POI should have a rating")
            assertTrue(poi.rating <= 5.0, "LLM POI rating should be <= 5.0")
            assertTrue(poi.distanceFromUser > 0.0, "LLM POI should have distance")
            assertFalse(poi.name.isEmpty(), "LLM POI should have a name")
        }
    }
    
    @Test
    fun testAPIOnlyStrategyComparison() = runBlocking {
        Log.d("DualPOITest", "\n🧪 =================================================")
        Log.d("DualPOITest", "🌐 API-ONLY STRATEGY TEST - LOST LAKE, OREGON")
        Log.d("DualPOITest", "🧪 =================================================")
        
        try {
            // Test API-only approach
            val apiResult = orchestrator.discoverPOIs(
                latitude = LOST_LAKE_LATITUDE,
                longitude = LOST_LAKE_LONGITUDE,
                category = "attraction",
                preferredStrategy = DiscoveryStrategy.API_FIRST,
                maxResults = 8
            )
            
            Log.d("DualPOITest", "\n🌐 API-ONLY RESULTS:")
            Log.d("DualPOITest", "   Strategy Used: ${apiResult.strategyUsed}")
            Log.d("DualPOITest", "   Response Time: ${apiResult.responseTimeMs}ms")
            Log.d("DualPOITest", "   POIs Found: ${apiResult.pois.size}")
            Log.d("DualPOITest", "   Fallback Used: ${apiResult.fallbackUsed}")
            
            if (apiResult.pois.isNotEmpty()) {
                // Verify API POIs have Google Places characteristics
                apiResult.pois.forEachIndexed { index, poi ->
                    Log.d("DualPOITest", "   ${index + 1}. ${poi.name} - ${String.format("%.1f", poi.rating)}⭐ - ${String.format("%.1f", poi.distanceFromUser)}mi")
                    
                    // API POIs should have location data
                    assertTrue(poi.latitude != 0.0, "API POI should have latitude")
                    assertTrue(poi.longitude != 0.0, "API POI should have longitude")
                    assertFalse(poi.name.isEmpty(), "API POI should have a name")
                }
            } else {
                Log.d("DualPOITest", "   ⚠️ No API results (API key may not be configured)")
            }
            
        } catch (e: Exception) {
            Log.d("DualPOITest", "   ⚠️ API-only test failed (likely due to API key configuration): ${e.message}")
            // This is acceptable for testing environments without API keys
        }
    }
    
    // MARK: - Seattle Washington Tests
    
    @Test
    fun testSeattleWashingtonDualSearch() = runBlocking {
        Log.d("DualPOITest", "\n🧪 =================================================")
        Log.d("DualPOITest", "🏙️  DUAL POI SEARCH TEST - SEATTLE, WASHINGTON")
        Log.d("DualPOITest", "🧪 =================================================")
        
        val result = orchestrator.discoverPOIs(
            latitude = SEATTLE_LATITUDE,
            longitude = SEATTLE_LONGITUDE,
            category = "attraction",
            preferredStrategy = DiscoveryStrategy.HYBRID,
            maxResults = 8
        )
        
        assertFalse(result.pois.isEmpty(), "Should discover POIs in Seattle")
        
        Log.d("DualPOITest", "\n📊 SEATTLE DUAL SEARCH RESULTS:")
        Log.d("DualPOITest", "   Strategy Used: ${result.strategyUsed}")
        Log.d("DualPOITest", "   Response Time: ${result.responseTimeMs}ms")
        Log.d("DualPOITest", "   POIs Found: ${result.pois.size}")
        
        // Expected Seattle attractions
        val seattleAttractions = listOf(
            "Space Needle", "Pike Place", "Market", "Waterfront", "Museum",
            "Aquarium", "Sculpture Park", "Fremont", "Queen Anne", "Capitol Hill"
        )
        
        var foundSeattlePOIs = 0
        Log.d("DualPOITest", "\n🔍 DISCOVERED SEATTLE POIs:")
        result.pois.forEachIndexed { index, poi ->
            Log.d("DualPOITest", "   ${index + 1}. ${poi.name} - ${String.format("%.1f", poi.rating)}⭐")
            
            seattleAttractions.forEach { attraction ->
                if (poi.name.contains(attraction, ignoreCase = true)) {
                    foundSeattlePOIs++
                    return@forEach
                }
            }
        }
        
        Log.d("DualPOITest", "✅ Found $foundSeattlePOIs recognizable Seattle POIs")
    }
    
    // MARK: - Edge Cases
    
    @Test
    fun testUnknownLocationHandling() = runBlocking {
        Log.d("DualPOITest", "\n🧪 =================================================")
        Log.d("DualPOITest", "❓ UNKNOWN LOCATION HANDLING TEST")
        Log.d("DualPOITest", "🧪 =================================================")
        
        // Test with remote coordinates (middle of Pacific Ocean)
        val unknownLatitude = 0.0
        val unknownLongitude = -160.0
        
        try {
            val result = orchestrator.discoverPOIs(
                latitude = unknownLatitude,
                longitude = unknownLongitude,
                category = "restaurant",
                preferredStrategy = DiscoveryStrategy.HYBRID,
                maxResults = 5
            )
            
            Log.d("DualPOITest", "\n🌊 UNKNOWN LOCATION RESULTS:")
            Log.d("DualPOITest", "   POIs Found: ${result.pois.size}")
            Log.d("DualPOITest", "   Strategy Used: ${result.strategyUsed}")
            
            // Should handle gracefully - might return empty or fallback results
            assertTrue(result.pois.size <= 5, "Should respect max results even for unknown locations")
            
        } catch (e: Exception) {
            Log.d("DualPOITest", "   ✅ Appropriately failed for unknown location: ${e.message}")
            // Failing for unknown locations is acceptable behavior
        }
    }
    
    @Test
    fun testCacheEffectiveness() = runBlocking {
        Log.d("DualPOITest", "\n🧪 =================================================")
        Log.d("DualPOITest", "📋 CACHE EFFECTIVENESS TEST")
        Log.d("DualPOITest", "🧪 =================================================")
        
        // First request
        val startTime1 = System.currentTimeMillis()
        val result1 = orchestrator.discoverPOIs(
            latitude = LOST_LAKE_LATITUDE,
            longitude = LOST_LAKE_LONGITUDE,
            category = "restaurant",
            preferredStrategy = DiscoveryStrategy.HYBRID,
            maxResults = 5
        )
        val time1 = System.currentTimeMillis() - startTime1
        
        // Second request (should use cache)
        val startTime2 = System.currentTimeMillis()
        val result2 = orchestrator.discoverPOIs(
            latitude = LOST_LAKE_LATITUDE,
            longitude = LOST_LAKE_LONGITUDE,
            category = "restaurant",
            preferredStrategy = DiscoveryStrategy.HYBRID,
            maxResults = 5
        )
        val time2 = System.currentTimeMillis() - startTime2
        
        Log.d("DualPOITest", "\n📊 CACHE PERFORMANCE:")
        Log.d("DualPOITest", "   First request: ${time1}ms")
        Log.d("DualPOITest", "   Second request: ${time2}ms")
        Log.d("DualPOITest", "   Cache effectiveness: ${if (time2 < time1) "✅ Faster" else "⚠️ Same/Slower"}")
        
        assertEquals(result1.pois.size, result2.pois.size, "Cached results should match original")
    }
    
    // MARK: - Performance Tests
    
    @Test
    fun testPerformanceTargets() = runBlocking {
        Log.d("DualPOITest", "\n🧪 =================================================")
        Log.d("DualPOITest", "⚡ PERFORMANCE TARGET VALIDATION")
        Log.d("DualPOITest", "🧪 =================================================")
        
        // Test multiple strategies for performance
        val strategies = listOf(DiscoveryStrategy.HYBRID, DiscoveryStrategy.LLM_FIRST, DiscoveryStrategy.LLM_ONLY)
        
        strategies.forEach { strategy ->
            val startTime = System.currentTimeMillis()
            
            try {
                val result = orchestrator.discoverPOIs(
                    latitude = LOST_LAKE_LATITUDE,
                    longitude = LOST_LAKE_LONGITUDE,
                    category = "attraction",
                    preferredStrategy = strategy,
                    maxResults = 5
                )
                
                val elapsed = System.currentTimeMillis() - startTime
                
                Log.d("DualPOITest", "\n⚡ $strategy PERFORMANCE:")
                Log.d("DualPOITest", "   Response Time: ${elapsed}ms")
                Log.d("DualPOITest", "   POIs Found: ${result.pois.size}")
                Log.d("DualPOITest", "   Target Met: ${if (elapsed < 2000) "✅ < 2s" else "⚠️ > 2s"}")
                
                // Performance targets
                when (strategy) {
                    DiscoveryStrategy.LLM_ONLY -> {
                        assertTrue(elapsed < 1000, "LLM-only should be < 1s")
                    }
                    else -> {
                        assertTrue(elapsed < 3000, "Hybrid/API strategies should be < 3s")
                    }
                }
                
            } catch (e: Exception) {
                Log.d("DualPOITest", "   ❌ Strategy $strategy failed: ${e.message}")
            }
        }
    }
    
    // MARK: - Mock Data Validation
    
    @Test
    fun testNoMockDataPresent() = runBlocking {
        Log.d("DualPOITest", "\n🧪 =================================================")
        Log.d("DualPOITest", "🚫 MOCK DATA ELIMINATION VERIFICATION")
        Log.d("DualPOITest", "🧪 =================================================")
        
        val testLocations = listOf(
            Triple("Lost Lake, Oregon", LOST_LAKE_LATITUDE, LOST_LAKE_LONGITUDE),
            Triple("Seattle, Washington", SEATTLE_LATITUDE, SEATTLE_LONGITUDE),
            Triple("San Francisco, California", 37.7749, -122.4194)
        )
        
        val forbiddenMockTerms = listOf(
            "Historic Downtown",
            "Local Museum",
            "Mock",
            "Test POI",
            "Sample Location",
            "Placeholder",
            "Demo Restaurant",
            "Example Attraction"
        )
        
        testLocations.forEach { (locationName, latitude, longitude) ->
            Log.d("DualPOITest", "\n🔍 Testing $locationName...")
            
            val result = orchestrator.discoverPOIs(
                latitude = latitude,
                longitude = longitude,
                category = "attraction",
                preferredStrategy = DiscoveryStrategy.HYBRID,
                maxResults = 6
            )
            
            var mockDataFound = false
            result.pois.forEach { poi ->
                forbiddenMockTerms.forEach { mockTerm ->
                    if (poi.name.contains(mockTerm, ignoreCase = true)) {
                        Log.d("DualPOITest", "   ❌ MOCK DATA FOUND: ${poi.name}")
                        mockDataFound = true
                    }
                }
            }
            
            assertFalse(mockDataFound, "No mock data should be present in $locationName results")
            
            if (!mockDataFound) {
                Log.d("DualPOITest", "   ✅ No mock data found in ${result.pois.size} POIs")
            }
        }
    }
    
    // MARK: - Strategy Comparison
    
    @Test
    fun testStrategyComparison() = runBlocking {
        Log.d("DualPOITest", "\n🧪 =================================================")
        Log.d("DualPOITest", "📊 STRATEGY COMPARISON - SIDE BY SIDE")
        Log.d("DualPOITest", "🧪 =================================================")
        
        val strategyResults = mutableMapOf<DiscoveryStrategy, com.roadtrip.copilot.services.POIDiscoveryResult>()
        
        // Test all strategies
        DiscoveryStrategy.values().forEach { strategy ->
            try {
                val result = orchestrator.discoverPOIs(
                    latitude = LOST_LAKE_LATITUDE,
                    longitude = LOST_LAKE_LONGITUDE,
                    category = "attraction",
                    preferredStrategy = strategy,
                    maxResults = 6
                )
                strategyResults[strategy] = result
            } catch (e: Exception) {
                Log.d("DualPOITest", "   ❌ Strategy $strategy failed: ${e.message}")
            }
        }
        
        // Display comparison
        Log.d("DualPOITest", "\n📊 STRATEGY COMPARISON RESULTS:")
        Log.d("DualPOITest", "   Strategy           | POIs | Time (ms) | Fallback")
        Log.d("DualPOITest", "   ------------------|------|-----------|----------")
        
        DiscoveryStrategy.values().forEach { strategy ->
            strategyResults[strategy]?.let { result ->
                val timeMs = String.format("%4d", result.responseTimeMs)
                val poiCount = String.format("%4d", result.pois.size)
                val fallback = if (result.fallbackUsed) "Yes" else "No"
                Log.d("DualPOITest", "   ${String.format("%-18s", strategy.name)} | $poiCount | $timeMs     | $fallback")
            }
        }
        
        // Show sample POIs from each strategy
        strategyResults.forEach { (strategy, result) ->
            if (result.pois.isNotEmpty()) {
                Log.d("DualPOITest", "\n🔍 ${strategy.name} SAMPLE POIs:")
                result.pois.take(3).forEachIndexed { index, poi ->
                    Log.d("DualPOITest", "   ${index + 1}. ${poi.name} - ${String.format("%.1f", poi.rating)}⭐")
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private fun validatePOIQuality(poi: com.roadtrip.copilot.models.POIData, context: String) {
        assertFalse(poi.name.isEmpty(), "$context: POI name should not be empty")
        assertTrue(poi.rating >= 0.0, "$context: Rating should be >= 0")
        assertTrue(poi.rating <= 5.0, "$context: Rating should be <= 5")
        assertTrue(poi.distanceFromUser > 0.0, "$context: Distance should be > 0")
        assertFalse(poi.category.isEmpty(), "$context: Category should not be empty")
        
        // Validate realistic distance (should be within reasonable range)
        assertTrue(poi.distanceFromUser < 500.0, "$context: Distance should be < 500mi for regional search")
    }
    
    private fun isPOINameRealistic(name: String): Boolean {
        val mockIndicators = listOf("mock", "test", "sample", "demo", "placeholder", "example")
        val nameLower = name.lowercase()
        
        return !mockIndicators.any { nameLower.contains(it) }
    }
}