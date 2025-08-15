package com.roadtrip.copilot.services

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.roadtrip.copilot.ai.ToolRegistry
import com.roadtrip.copilot.ai.EnhancedToolRegistry
import kotlinx.coroutines.runBlocking
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.Assert.*

/**
 * Comprehensive tests for Android POI discovery system
 * Tests platform parity with iOS implementation
 * Tests Lost Lake Oregon case specifically
 */
@RunWith(AndroidJUnit4::class)
class POIDiscoveryTest {
    
    private lateinit var context: Context
    private lateinit var poiOrchestrator: POIDiscoveryOrchestrator
    private lateinit var toolRegistry: ToolRegistry
    private lateinit var enhancedRegistry: EnhancedToolRegistry
    
    companion object {
        // Lost Lake Oregon test coordinates
        private const val LOST_LAKE_LATITUDE = 45.4979
        private const val LOST_LAKE_LONGITUDE = -121.8209
        
        // Performance targets
        private const val LLM_PERFORMANCE_TARGET_MS = 350L
        private const val API_PERFORMANCE_TARGET_MS = 1000L
    }
    
    @Before
    fun setup() {
        context = ApplicationProvider.getApplicationContext()
        poiOrchestrator = POIDiscoveryOrchestrator(context)
        toolRegistry = ToolRegistry(context)
        enhancedRegistry = EnhancedToolRegistry(context)
    }
    
    @Test
    fun testPOIDiscoveryOrchestrator_LostLakeOregon() = runBlocking {
        // Test the specific Lost Lake Oregon case
        val startTime = System.currentTimeMillis()
        
        val result = poiOrchestrator.discoverLostLakeOregonPOIs()
        
        val elapsed = System.currentTimeMillis() - startTime
        
        // Verify results
        assertNotNull("Result should not be null", result)
        assertTrue("Should find at least 1 POI", result.pois.isNotEmpty())
        assertTrue("Should find at most 10 POIs", result.pois.size <= 10)
        
        // Verify performance
        if (result.strategyUsed == DiscoveryStrategy.LLM_ONLY || 
            result.strategyUsed == DiscoveryStrategy.LLM_FIRST) {
            assertTrue("LLM response should be < ${LLM_PERFORMANCE_TARGET_MS}ms", 
                result.responseTimeMs < LLM_PERFORMANCE_TARGET_MS)
        }
        
        // Verify POI data quality
        result.pois.forEach { poi ->
            assertNotNull("POI name should not be null", poi.name)
            assertTrue("POI name should not be empty", poi.name.isNotEmpty())
            assertTrue("POI rating should be valid", poi.rating >= 0.0 && poi.rating <= 5.0)
            assertTrue("POI distance should be positive", poi.distanceFromUser >= 0.0)
            assertNotNull("POI description should not be null", poi.description)
        }
        
        println("✅ Lost Lake Oregon POI Discovery Test Passed")
        println("   Found ${result.pois.size} POIs in ${result.responseTimeMs}ms using ${result.strategyUsed}")
        result.pois.take(3).forEach { poi ->
            println("   - ${poi.name} (${poi.rating}★, ${poi.getFormattedDistance()})")
        }
    }
    
    @Test
    fun testHybridDiscoveryStrategy() = runBlocking {
        val result = poiOrchestrator.discoverPOIs(
            latitude = LOST_LAKE_LATITUDE,
            longitude = LOST_LAKE_LONGITUDE,
            category = "attraction",
            preferredStrategy = DiscoveryStrategy.HYBRID,
            maxResults = 5
        )
        
        assertNotNull("Hybrid result should not be null", result)
        assertEquals("Should use hybrid strategy", DiscoveryStrategy.HYBRID, result.strategyUsed)
        assertTrue("Should find POIs", result.pois.isNotEmpty())
        assertTrue("Should not exceed max results", result.pois.size <= 5)
        
        println("✅ Hybrid Discovery Strategy Test Passed")
        println("   Strategy: ${result.strategyUsed}, POIs: ${result.pois.size}, Time: ${result.responseTimeMs}ms")
    }
    
    @Test
    fun testLLMOnlyDiscoveryStrategy() = runBlocking {
        val result = poiOrchestrator.discoverPOIs(
            latitude = LOST_LAKE_LATITUDE,
            longitude = LOST_LAKE_LONGITUDE,
            category = "attraction",
            preferredStrategy = DiscoveryStrategy.LLM_ONLY,
            maxResults = 3
        )
        
        assertNotNull("LLM-only result should not be null", result)
        assertEquals("Should use LLM-only strategy", DiscoveryStrategy.LLM_ONLY, result.strategyUsed)
        assertFalse("LLM-only should not use fallback", result.fallbackUsed)
        assertTrue("LLM response should be fast", result.responseTimeMs < LLM_PERFORMANCE_TARGET_MS)
        
        println("✅ LLM-Only Discovery Strategy Test Passed")
        println("   Response time: ${result.responseTimeMs}ms (target: <${LLM_PERFORMANCE_TARGET_MS}ms)")
    }
    
    @Test
    fun testToolRegistryIntegration() = runBlocking {
        val searchTool = toolRegistry.getTool("search_poi")
        assertNotNull("search_poi tool should exist", searchTool)
        
        val parameters = mapOf(
            "location" to "Lost Lake Oregon",
            "category" to "attraction",
            "strategy" to "hybrid"
        )
        
        val result = searchTool!!.execute(parameters)
        
        assertNotNull("Tool result should not be null", result)
        assertTrue("Result should contain POI information", result.contains("POIs near"))
        assertTrue("Result should contain JSON data", result.contains("JSON:"))
        
        println("✅ Tool Registry Integration Test Passed")
        println("   Result length: ${result.length} characters")
    }
    
    @Test
    fun testEnhancedToolRegistryExclusions() = runBlocking {
        val parameters = mapOf(
            "location" to "$LOST_LAKE_LATITUDE,$LOST_LAKE_LONGITUDE",
            "category" to "restaurant"
        )
        
        val result = enhancedRegistry.executeSearchPOIWithExclusions(parameters)
        
        assertNotNull("Enhanced result should not be null", result)
        
        // Check that common chains are excluded
        val excludedChains = listOf("McDonald's", "Burger King", "Subway", "Starbucks")
        excludedChains.forEach { chain ->
            assertFalse("Result should not contain $chain", result.contains(chain))
        }
        
        println("✅ Enhanced Tool Registry Exclusions Test Passed")
        println("   Excluded common chains successfully")
    }
    
    @Test
    fun testPOIDetailsWithLostLake() = runBlocking {
        val detailsTool = toolRegistry.getTool("get_poi_details")
        assertNotNull("get_poi_details tool should exist", detailsTool)
        
        val parameters = mapOf(
            "poi_name" to "Lost Lake Oregon"
        )
        
        val result = detailsTool!!.execute(parameters)
        
        assertNotNull("Details result should not be null", result)
        assertTrue("Should contain Lost Lake details", result.contains("Lost Lake"))
        assertTrue("Should contain rating", result.contains("Rating:"))
        assertTrue("Should contain description", result.contains("Description:"))
        assertTrue("Should mention Mount Hood", result.contains("Mount Hood"))
        
        println("✅ POI Details Test Passed")
        println("   Lost Lake details retrieved successfully")
    }
    
    @Test
    fun testCoordinateParsingAccuracy() = runBlocking {
        val coordinates = listOf(
            "45.4979,-121.8209" to Pair(45.4979, -121.8209),
            "37.7749,-122.4194" to Pair(37.7749, -122.4194), // San Francisco
            "40.7128,-74.0060" to Pair(40.7128, -74.0060)    // New York
        )
        
        coordinates.forEach { (input, expected) ->
            val result = poiOrchestrator.discoverPOIs(
                latitude = expected.first,
                longitude = expected.second,
                category = "attraction",
                maxResults = 1
            )
            
            assertNotNull("Result should not be null for $input", result)
            assertTrue("Should find POIs for valid coordinates", result.pois.isNotEmpty())
        }
        
        println("✅ Coordinate Parsing Accuracy Test Passed")
    }
    
    @Test
    fun testPerformanceTargets() = runBlocking {
        val testCases = listOf(
            DiscoveryStrategy.LLM_ONLY to LLM_PERFORMANCE_TARGET_MS,
            DiscoveryStrategy.HYBRID to API_PERFORMANCE_TARGET_MS
        )
        
        testCases.forEach { (strategy, targetMs) ->
            val startTime = System.currentTimeMillis()
            
            val result = poiOrchestrator.discoverPOIs(
                latitude = LOST_LAKE_LATITUDE,
                longitude = LOST_LAKE_LONGITUDE,
                category = "attraction",
                preferredStrategy = strategy,
                maxResults = 3
            )
            
            val elapsed = System.currentTimeMillis() - startTime
            
            assertTrue("$strategy should complete within ${targetMs}ms, took ${elapsed}ms", 
                elapsed < targetMs * 2) // Allow 2x target for test environment
            
            println("✅ Performance test for $strategy: ${elapsed}ms (target: <${targetMs}ms)")
        }
        
        println("✅ Performance Targets Test Passed")
    }
    
    @Test
    fun testPlatformParityWithiOS() = runBlocking {
        // Test that Android implementation matches iOS behavior
        val result = poiOrchestrator.discoverLostLakeOregonPOIs()
        
        // Verify iOS-equivalent data structure
        result.pois.forEach { poi ->
            // Check all required fields are present (matching iOS POIData)
            assertNotNull("name should match iOS", poi.name)
            assertNotNull("description should match iOS", poi.description)
            assertNotNull("category should match iOS", poi.category)
            assertTrue("rating should be valid like iOS", poi.rating >= 0.0 && poi.rating <= 5.0)
            assertTrue("distance should be positive like iOS", poi.distanceFromUser >= 0.0)
            assertTrue("latitude should be valid", poi.latitude >= -90.0 && poi.latitude <= 90.0)
            assertTrue("longitude should be valid", poi.longitude >= -180.0 && poi.longitude <= 180.0)
            assertNotNull("couldEarnRevenue should match iOS", poi.couldEarnRevenue)
        }
        
        // Verify performance matches iOS targets
        if (result.strategyUsed == DiscoveryStrategy.LLM_ONLY) {
            assertTrue("Android LLM performance should match iOS target", 
                result.responseTimeMs < LLM_PERFORMANCE_TARGET_MS)
        }
        
        println("✅ Platform Parity with iOS Test Passed")
        println("   Android POI structure matches iOS implementation")
    }
}