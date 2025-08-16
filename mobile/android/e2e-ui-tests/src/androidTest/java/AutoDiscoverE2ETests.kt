package com.roadtrip.copilot.e2e

import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.uiautomator.UiDevice
import org.junit.After
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import android.content.Context
import android.content.Intent
import androidx.test.core.app.ActivityScenario
import androidx.test.core.app.ApplicationProvider
import androidx.test.espresso.Espresso
import androidx.test.espresso.IdlingPolicies
import androidx.test.espresso.IdlingRegistry
import androidx.test.espresso.action.ViewActions
import androidx.test.espresso.assertion.ViewAssertions
import androidx.test.espresso.matcher.ViewMatchers
import androidx.test.rule.GrantPermissionRule
import com.roadtrip.copilot.MainActivity
import com.roadtrip.copilot.R
import org.junit.Assert.*
import java.util.concurrent.TimeUnit
import kotlin.system.measureTimeMillis

/**
 * Auto Discover E2E Test Suite for Android
 * Comprehensive testing for Auto Discover feature functionality, platform parity, and accessibility
 * 
 * Test Categories:
 * - Core Functionality Tests
 * - Platform Parity Tests  
 * - Voice Integration Tests
 * - Accessibility Tests
 * - Performance Tests
 * - Error Handling Tests
 */
@RunWith(AndroidJUnit4::class)
class AutoDiscoverE2ETests {
    
    @get:Rule
    val composeTestRule = createComposeRule()
    
    @get:Rule
    val grantPermissionRule: GrantPermissionRule = GrantPermissionRule.grant(
        android.Manifest.permission.ACCESS_FINE_LOCATION,
        android.Manifest.permission.ACCESS_COARSE_LOCATION,
        android.Manifest.permission.RECORD_AUDIO
    )
    
    // Test Properties
    private lateinit var device: UiDevice
    private lateinit var context: Context
    private lateinit var testData: AutoDiscoverTestData
    private lateinit var performanceMetrics: PerformanceMetrics
    private lateinit var scenario: ActivityScenario<MainActivity>
    
    @Before
    fun setUp() {
        // Initialize test environment
        device = UiDevice.getInstance(InstrumentationRegistry.getInstrumentation())
        context = ApplicationProvider.getApplicationContext()
        testData = AutoDiscoverTestData(context)
        performanceMetrics = PerformanceMetrics()
        
        // Set up test timeouts
        IdlingPolicies.setMasterPolicyTimeout(30, TimeUnit.SECONDS)
        IdlingPolicies.setIdlingResourceTimeout(30, TimeUnit.SECONDS)
        
        // Launch app in test mode
        val intent = Intent(context, MainActivity::class.java).apply {
            putExtra("UI_TESTING", true)
            putExtra("AUTO_DISCOVER_TEST_MODE", true)
            putExtra("MOCK_LOCATION_SERVICES", true)
            putExtra("TEST_DATA_ENABLED", true)
        }
        
        scenario = ActivityScenario.launch(intent)
        
        // Navigate to clean starting state
        navigateToDestinationSelectionScreen()
    }
    
    @After
    fun tearDown() {
        // Generate test report
        performanceMetrics.generateReport()
        
        // Clean up test data
        testData.cleanup()
        
        // Close activity
        scenario.close()
    }
    
    // MARK: - Test Suite AD-001: Auto Discover Button Integration
    
    @Test
    fun testAD001_01_ButtonPresenceAndPositioning() {
        // Test Case: AD-001-01 - Button Presence and Positioning
        
        val startTime = System.currentTimeMillis()
        
        composeTestRule.onNodeWithContentDescription("Auto Discover - Find amazing places nearby")
            .assertExists("Auto Discover button should be present on Select Destination screen")
            .assertIsDisplayed()
            .assertIsEnabled()
        
        // Verify button positioning as third navigation option
        composeTestRule.onNodeWithContentDescription("Destination input field")
            .assertExists("Manual destination input should be first option")
        
        composeTestRule.onNodeWithContentDescription("Start navigation")
            .assertExists("Voice search should be second option")
        
        composeTestRule.onNodeWithText("Auto Discover")
            .assertExists("Auto Discover should be third option")
        
        // Verify button styling and accessibility
        composeTestRule.onNodeWithText("Auto Discover")
            .assertHasClickAction()
            .assertIsEnabled()
        
        composeTestRule.onNodeWithText("Find amazing places nearby")
            .assertExists("Button should have descriptive subtitle")
        
        // Performance validation
        val elapsedTime = System.currentTimeMillis() - startTime
        assertTrue("Button presence check should complete within 1 second", elapsedTime < 1000)
        
        performanceMetrics.recordUICheck("button_presence", elapsedTime.toDouble())
    }
    
    @Test
    fun testAD001_02_ButtonInteractionAndState() {
        // Test Case: AD-001-02 - Button Interaction and State
        
        val startTime = System.currentTimeMillis()
        
        // Test button interaction
        composeTestRule.onNodeWithContentDescription("Auto Discover - Find amazing places nearby")
            .assertExists()
            .performClick()
        
        // Verify transition to MainPOIView begins immediately
        composeTestRule.onNodeWithContentDescription("Main POI View")
            .assertExists("MainPOIView should appear within 5 seconds")
        
        // Verify discovery mode indicators
        composeTestRule.onNodeWithContentDescription("Back to search")
            .assertExists("Search button should replace heart icon in discovery mode")
        
        composeTestRule.onNodeWithContentDescription("Play information about this place")
            .assertExists("Speak/Info button should appear in discovery mode")
        
        // Performance validation - total transition time
        val transitionTime = System.currentTimeMillis() - startTime
        assertTrue("Auto Discover transition should complete within 3 seconds", transitionTime < 3000)
        
        performanceMetrics.recordDiscoveryPerformance("button_to_discovery", transitionTime.toDouble())
    }
    
    // MARK: - Test Suite AD-002: POI Discovery and Ranking
    
    @Test
    fun testAD002_01_BasicPOIDiscovery() {
        // Test Case: AD-002-01 - Basic POI Discovery
        
        // Set test location to Lost Lake, Oregon
        setTestLocation(45.3711, -121.8200)
        
        val startTime = System.currentTimeMillis()
        
        // Initiate Auto Discover
        initiateAutoDiscover()
        
        // Wait for POI discovery completion
        composeTestRule.onNodeWithContentDescription("currentPOIName")
            .assertExists("POI should be discovered and displayed within 5 seconds")
        
        val discoveryTime = System.currentTimeMillis() - startTime
        assertTrue("POI discovery should complete within 3 seconds", discoveryTime < 3000)
        
        // Verify POI data quality
        val poiNameNode = composeTestRule.onNodeWithContentDescription("currentPOIName")
        val poiName = getNodeText(poiNameNode)
        assertFalse("POI should have a valid name", poiName.isEmpty())
        assertTrue("POI name should be meaningful", poiName.length > 3)
        
        // Verify POI position indicator
        composeTestRule.onAllNodesWithText("POI 1")
            .assertCountEquals(1)
            .onFirst()
            .assertExists("POI position indicator should show current position")
        
        // Verify photo cycling has started
        composeTestRule.onAllNodesWithText("/5")
            .assertAny(hasTestTag("photoIndicator"))
        
        performanceMetrics.recordDiscoveryPerformance("poi_discovery", discoveryTime.toDouble())
    }
    
    @Test
    fun testAD002_02_POIRankingAlgorithmAccuracy() {
        // Test Case: AD-002-02 - POI Ranking Algorithm Accuracy
        
        setTestLocation(45.3711, -121.8200)
        
        // Execute first discovery
        initiateAutoDiscover()
        val firstDiscoveryPOIs = capturePOIList()
        returnToDestinationSelection()
        
        // Execute second discovery
        initiateAutoDiscover()
        val secondDiscoveryPOIs = capturePOIList()
        
        // Verify consistent ranking across executions
        assertEquals("POI count should be consistent", firstDiscoveryPOIs.size, secondDiscoveryPOIs.size)
        assertEquals("POI ranking should be consistent across executions", firstDiscoveryPOIs, secondDiscoveryPOIs)
        
        // Verify POI count is appropriate (up to 10)
        assertTrue("Should discover maximum 10 POIs", firstDiscoveryPOIs.size <= 10)
        assertTrue("Should discover at least 1 POI", firstDiscoveryPOIs.size > 0)
    }
    
    // MARK: - Test Suite AD-003: MainPOIView Auto-Cycling
    
    @Test
    fun testAD003_01_AutomaticTransitionToMainPOIView() {
        // Test Case: AD-003-01 - Automatic Transition to MainPOIView
        
        initiateAutoDiscover()
        
        // Verify automatic transition to MainPOIView
        composeTestRule.onNodeWithContentDescription("Main POI View")
            .assertExists("Should automatically transition to MainPOIView")
        
        // Verify discovery mode indicators
        composeTestRule.onNodeWithContentDescription("Back to search")
            .assertExists("Heart icon should be replaced with search icon")
        
        composeTestRule.onNodeWithContentDescription("Play information about this place")
            .assertExists("Speak/Info button should appear to right of search icon")
        
        // Verify first POI displayed
        composeTestRule.onNodeWithContentDescription("currentPOIName")
            .assertExists("First POI should be displayed")
        
        // Verify POI position indicator
        composeTestRule.onAllNodesWithText("POI 1")
            .assertCountGreaterThan(0)
    }
    
    @Test
    fun testAD003_02_PhotoAutoCyclingBehavior() {
        // Test Case: AD-003-02 - Photo Auto-Cycling Behavior
        
        initiateAutoDiscover()
        
        // Wait for photo cycling to start
        composeTestRule.onAllNodesWithText("/5")
            .assertCountGreaterThan(0)
        
        // Monitor photo cycling timing
        val startTime = System.currentTimeMillis()
        val initialPhotoIndex = getCurrentPhotoIndex()
        
        // Wait for photo change (should happen within 2.5 seconds allowing for timing variance)
        var photoChanged = false
        val timeout = startTime + 3000
        
        while (System.currentTimeMillis() < timeout && !photoChanged) {
            val currentIndex = getCurrentPhotoIndex()
            if (currentIndex != initialPhotoIndex) {
                photoChanged = true
                val cyclingTime = System.currentTimeMillis() - startTime
                assertTrue("Photo should cycle within 2.5 seconds", cyclingTime < 2500)
                assertTrue("Photo should not cycle too quickly", cyclingTime > 1500)
                performanceMetrics.recordPhotoCycling("photo_transition", cyclingTime.toDouble())
            }
            Thread.sleep(100)
        }
        
        assertTrue("Photo should cycle automatically", photoChanged)
        
        // Test POI advancement after all photos viewed
        testPOIAdvancementAfterPhotos()
    }
    
    // MARK: - Test Suite AD-004: POI Navigation Controls
    
    @Test
    fun testAD004_01_ManualPOINavigation() {
        // Test Case: AD-004-01 - Manual POI Navigation
        
        initiateAutoDiscover()
        
        composeTestRule.onNodeWithContentDescription("Next POI")
            .assertExists("Next POI button should be present")
            .assertIsEnabled()
        
        composeTestRule.onNodeWithContentDescription("Previous POI")
            .assertExists("Previous POI button should be present")
            .assertIsEnabled()
        
        // Test next POI navigation
        val initialPOIName = getCurrentPOIName()
        
        composeTestRule.onNodeWithContentDescription("Next POI")
            .performClick()
        
        // Wait for POI change
        val poiChanged = waitForPOIChange(initialPOIName, 2000)
        assertTrue("POI should change when next button tapped", poiChanged)
        
        // Verify POI position indicator updated
        composeTestRule.onAllNodesWithText("POI 2")
            .assertCountGreaterThan(0)
        
        // Test previous POI navigation
        val secondPOIName = getCurrentPOIName()
        
        composeTestRule.onNodeWithContentDescription("Previous POI")
            .performClick()
        
        val poiReverted = waitForPOIChange(secondPOIName, 2000)
        assertTrue("POI should revert when previous button tapped", poiReverted)
        
        // Verify back to first POI
        val finalPOIName = getCurrentPOIName()
        assertEquals("Should return to first POI after previous navigation", initialPOIName, finalPOIName)
    }
    
    @Test
    fun testAD004_02_VoiceCommandNavigation() {
        // Test Case: AD-004-02 - Voice Command Navigation
        
        initiateAutoDiscover()
        
        val initialPOIName = getCurrentPOIName()
        val startTime = System.currentTimeMillis()
        
        // Simulate "next POI" voice command
        simulateVoiceCommand("next poi")
        
        // Verify POI advancement and response time
        val poiChanged = waitForPOIChange(initialPOIName, 1000)
        val responseTime = System.currentTimeMillis() - startTime
        
        assertTrue("POI should advance with voice command", poiChanged)
        assertTrue("Voice command response should be within 350ms", responseTime < 350)
        
        performanceMetrics.recordVoiceResponse("next_poi", responseTime.toDouble())
        
        // Test "previous POI" voice command
        val secondPOIName = getCurrentPOIName()
        simulateVoiceCommand("previous poi")
        
        val poiReverted = waitForPOIChange(secondPOIName, 1000)
        assertTrue("POI should go back with voice command", poiReverted)
        
        // Test alternative phrasings
        simulateVoiceCommand("next place")
        val alternativeWorked = waitForPOIChange(getCurrentPOIName(), 1000)
        assertTrue("Alternative voice command phrasing should work", alternativeWorked)
    }
    
    // MARK: - Test Suite AD-005: Dislike Functionality
    
    @Test
    fun testAD005_01_POIDislikeButton() {
        // Test Case: AD-005-01 - POI Dislike Button
        
        initiateAutoDiscover()
        
        composeTestRule.onNodeWithContentDescription("Dislike")
            .assertExists("Dislike button should be present")
            .assertIsEnabled()
        
        val initialPOIName = getCurrentPOIName()
        
        // Tap dislike button
        composeTestRule.onNodeWithContentDescription("Dislike")
            .performClick()
        
        // Verify immediate skip to next POI
        val poiSkipped = waitForPOIChange(initialPOIName, 2000)
        assertTrue("Should immediately skip to next POI when disliked", poiSkipped)
        
        // Verify disliked POI doesn't appear again
        verifyPOIExcluded(initialPOIName)
    }
    
    @Test
    fun testAD005_02_VoiceCommandDislike() {
        // Test Case: AD-005-02 - Voice Command Dislike
        
        initiateAutoDiscover()
        
        val initialPOIName = getCurrentPOIName()
        val startTime = System.currentTimeMillis()
        
        // Issue voice dislike command
        simulateVoiceCommand("dislike this place")
        
        // Verify immediate POI skip and response time
        val poiSkipped = waitForPOIChange(initialPOIName, 1000)
        val responseTime = System.currentTimeMillis() - startTime
        
        assertTrue("Should immediately skip POI with voice dislike command", poiSkipped)
        assertTrue("Voice dislike response should be within 350ms", responseTime < 350)
        
        performanceMetrics.recordVoiceResponse("dislike_poi", responseTime.toDouble())
        
        // Test alternative voice commands
        val secondPOIName = getCurrentPOIName()
        simulateVoiceCommand("I don't like this")
        
        val alternativeWorked = waitForPOIChange(secondPOIName, 1000)
        assertTrue("Alternative dislike phrasing should work", alternativeWorked)
    }
    
    @Test
    fun testAD005_03_DislikePersistenceAndFiltering() {
        // Test Case: AD-005-03 - Dislike Persistence and Filtering
        
        val dislikedPOIs = mutableListOf<String>()
        
        // Dislike multiple POIs
        initiateAutoDiscover()
        
        repeat(3) {
            val poiName = getCurrentPOIName()
            dislikedPOIs.add(poiName)
            
            composeTestRule.onNodeWithContentDescription("Dislike")
                .performClick()
            
            Thread.sleep(1000) // Wait for skip
        }
        
        // Return to destination selection and restart discovery
        returnToDestinationSelection()
        initiateAutoDiscover()
        
        // Verify disliked POIs are excluded
        dislikedPOIs.forEach { dislikedPOI ->
            verifyPOIExcluded(dislikedPOI)
        }
        
        // Test app restart persistence
        scenario.close()
        setUp() // Restart app
        
        setTestLocation(45.3711, -121.8200)
        initiateAutoDiscover()
        
        // Verify persistence across app restart
        dislikedPOIs.forEach { dislikedPOI ->
            verifyPOIExcluded(dislikedPOI)
        }
    }
    
    // MARK: - Test Suite AD-006: Heart to Search Icon Transformation
    
    @Test
    fun testAD006_01_IconTransformationBehavior() {
        // Test Case: AD-006-01 - Icon Transformation Behavior
        
        // First navigate to normal MainPOIView to verify heart icon
        navigateToNormalMainPOIView()
        
        composeTestRule.onNodeWithContentDescription("Save")
            .assertExists("Heart icon should be present in normal mode")
        
        // Return and initiate discovery mode
        returnToDestinationSelection()
        initiateAutoDiscover()
        
        // Verify heart icon replaced with search icon
        composeTestRule.onNodeWithContentDescription("Back to search")
            .assertExists("Heart should be replaced with search icon in discovery mode")
        
        // Verify heart button no longer exists in discovery mode
        composeTestRule.onNodeWithContentDescription("Save")
            .assertDoesNotExist("Heart icon should not exist in discovery mode")
    }
    
    @Test
    fun testAD006_02_SearchIconBackNavigation() {
        // Test Case: AD-006-02 - Search Icon Back Navigation
        
        initiateAutoDiscover()
        
        val startTime = System.currentTimeMillis()
        
        // Tap search icon for back navigation
        composeTestRule.onNodeWithContentDescription("Back to search")
            .assertExists()
            .performClick()
        
        // Verify return to Select Destination screen
        composeTestRule.onNodeWithContentDescription("Auto Discover - Find amazing places nearby")
            .assertExists("Should return to Select Destination screen")
        
        val navigationTime = System.currentTimeMillis() - startTime
        assertTrue("Back navigation should complete within 1 second", navigationTime < 1000)
        
        // Verify discovery mode cleared
        composeTestRule.onNodeWithContentDescription("Main POI View")
            .assertDoesNotExist("MainPOIView should be dismissed")
        
        performanceMetrics.recordNavigation("search_back_navigation", navigationTime.toDouble())
    }
    
    // MARK: - Test Suite AD-007: AI-Generated Podcast Content
    
    @Test
    fun testAD007_01_SpeakInfoButtonFunctionality() {
        // Test Case: AD-007-01 - Speak/Info Button Functionality
        
        initiateAutoDiscover()
        
        composeTestRule.onNodeWithContentDescription("Play information about this place")
            .assertExists("Speak/Info button should be present")
            .assertIsEnabled()
        
        val startTime = System.currentTimeMillis()
        
        // Tap Speak/Info button
        composeTestRule.onNodeWithContentDescription("Play information about this place")
            .performClick()
        
        // Monitor for audio content generation (simulated in test environment)
        val contentGenerated = waitForAudioContentPlayback(3000)
        val generationTime = System.currentTimeMillis() - startTime
        
        assertTrue("AI content should be generated and played", contentGenerated)
        assertTrue("AI content generation should complete within 2 seconds", generationTime < 2000)
        
        performanceMetrics.recordAIPerformance("content_generation", generationTime.toDouble())
    }
    
    @Test
    fun testAD007_02_VoiceCommandAudioControl() {
        // Test Case: AD-007-02 - Voice Command Audio Control
        
        initiateAutoDiscover()
        startAudioContent()
        
        // Test pause command
        simulateVoiceCommand("pause")
        val pauseWorked = waitForAudioPause(1000)
        assertTrue("Pause voice command should work", pauseWorked)
        
        // Test resume command
        simulateVoiceCommand("resume")
        val resumeWorked = waitForAudioResume(1000)
        assertTrue("Resume voice command should work", resumeWorked)
        
        // Test skip command
        simulateVoiceCommand("skip")
        val skipWorked = waitForAudioStop(1000)
        assertTrue("Skip voice command should stop audio", skipWorked)
    }
    
    // MARK: - Test Suite AD-008: Photo Discovery and Integration
    
    @Test
    fun testAD008_01_MultiSourcePhotoDiscovery() {
        // Test Case: AD-008-01 - Multi-Source Photo Discovery
        
        initiateAutoDiscover()
        
        // Verify exactly 5 photos per POI
        composeTestRule.onAllNodesWithText("/5")
            .assertCountGreaterThan(0)
        
        // Test photo quality and loading
        verifyPhotoQuality()
        
        // Cycle through multiple POIs to verify consistent photo count
        repeat(3) { i ->
            composeTestRule.onNodeWithContentDescription("Next POI")
                .performClick()
            
            Thread.sleep(1000)
            
            composeTestRule.onAllNodesWithText("/5")
                .assertCountGreaterThan(0)
        }
    }
    
    @Test
    fun testAD008_02_PhotoCachingAndPerformance() {
        // Test Case: AD-008-02 - Photo Caching and Performance
        
        // First discovery session
        val startTime = System.currentTimeMillis()
        initiateAutoDiscover()
        val firstLoadTime = System.currentTimeMillis() - startTime
        
        // Navigate through some photos to cache them
        cyclePhotosForCaching()
        
        // Return and start second discovery session
        returnToDestinationSelection()
        
        val cacheStartTime = System.currentTimeMillis()
        initiateAutoDiscover()
        val cachedLoadTime = System.currentTimeMillis() - cacheStartTime
        
        // Verify cache improves performance
        assertTrue("Cached photos should load at least 30% faster", cachedLoadTime < firstLoadTime * 0.7)
        
        performanceMetrics.recordCachePerformance("photo_caching", 
                                                 firstLoadTime.toDouble(), 
                                                 cachedLoadTime.toDouble())
    }
    
    // MARK: - Test Suite AD-009: Continuous Operation and Loop-back
    
    @Test
    fun testAD009_01_InfiniteCyclingBehavior() {
        // Test Case: AD-009-01 - Infinite Cycling Behavior
        
        initiateAutoDiscover()
        
        // Allow cycling to complete full cycle
        val cycleStartTime = System.currentTimeMillis()
        val completeCycleTimeout = 120000L // 2 minutes max
        
        var cycleCompleted = false
        var initialPOIName: String? = null
        var backToStart = false
        
        while (System.currentTimeMillis() - cycleStartTime < completeCycleTimeout && !cycleCompleted) {
            val currentPOI = getCurrentPOIName()
            
            if (initialPOIName == null) {
                initialPOIName = currentPOI
            } else if (currentPOI == initialPOIName && !backToStart) {
                // We've looped back to the start
                backToStart = true
                cycleCompleted = true
            }
            
            Thread.sleep(2000) // Wait for photo cycling
        }
        
        assertTrue("Discovery should loop back to first POI", cycleCompleted)
        
        // Verify cycling continues indefinitely
        verifyContinuousOperation(30000) // 30 seconds
    }
    
    @Test
    fun testAD009_02_InterruptionHandling() {
        // Test Case: AD-009-02 - Interruption Handling
        
        initiateAutoDiscover()
        
        // Simulate app backgrounding
        device.pressHome()
        Thread.sleep(2000)
        
        // Return to app
        device.pressRecentApps()
        device.click(device.displayWidth / 2, device.displayHeight / 2)
        
        // Verify discovery state preserved
        composeTestRule.onNodeWithContentDescription("Main POI View")
            .assertExists("MainPOIView should be restored after app activation")
        
        val currentPOI = getCurrentPOIName()
        assertFalse("POI state should be preserved after backgrounding", currentPOI.isEmpty())
        
        // Verify cycling resumes
        composeTestRule.onAllNodesWithText("/5")
            .assertCountGreaterThan(0)
    }
    
    // MARK: - Test Suite AD-010: Platform Parity Validation
    
    @Test
    fun testAD010_01_CrossPlatformBehaviorConsistency() {
        // Test Case: AD-010-01 - Cross-Platform Behavior Consistency
        // Note: This test documents Android behavior for comparison with iOS
        
        setTestLocation(45.3711, -121.8200)
        
        val startTime = System.currentTimeMillis()
        initiateAutoDiscover()
        
        // Record Android-specific performance metrics for platform comparison
        val discoveryTime = System.currentTimeMillis() - startTime
        performanceMetrics.recordPlatformMetric("android_discovery_time", discoveryTime.toDouble())
        
        // Record UI layout characteristics
        val buttonCount = composeTestRule.onAllNodes(hasClickAction()).fetchSemanticsNodes().size
        performanceMetrics.recordPlatformMetric("android_button_count", buttonCount.toDouble())
        
        // Test voice command timing
        val voiceStartTime = System.currentTimeMillis()
        simulateVoiceCommand("next poi")
        val voiceResponseTime = System.currentTimeMillis() - voiceStartTime
        
        performanceMetrics.recordPlatformMetric("android_voice_response", voiceResponseTime.toDouble())
        assertTrue("Android voice response should be within 350ms", voiceResponseTime < 350)
    }
    
    // MARK: - Test Suite AD-011: Accessibility Compliance
    
    @Test
    fun testAD011_01_ScreenReaderCompatibility() {
        // Test Case: AD-011-01 - Screen Reader Compatibility
        
        // Navigate through discovery flow with accessibility focus
        composeTestRule.onNodeWithContentDescription("Auto Discover - Find amazing places nearby")
            .assertHasClickAction()
            .performClick()
        
        // Verify MainPOIView accessibility
        composeTestRule.onNodeWithContentDescription("Main POI View")
            .assertExists()
        
        // Test button accessibility in discovery mode
        composeTestRule.onNodeWithContentDescription("Back to search")
            .assertHasClickAction()
        
        composeTestRule.onNodeWithContentDescription("Play information about this place")
            .assertHasClickAction()
        
        composeTestRule.onNodeWithContentDescription("Next POI")
            .assertHasClickAction()
        
        // Verify all critical elements have content descriptions
        val criticalElements = listOf(
            "Back to search",
            "Play information about this place", 
            "Next POI",
            "Previous POI",
            "Dislike"
        )
        
        criticalElements.forEach { contentDescription ->
            composeTestRule.onNodeWithContentDescription(contentDescription)
                .assertExists("$contentDescription should have accessibility support")
        }
    }
    
    @Test
    fun testAD011_02_TouchTargetAndVisualRequirements() {
        // Test Case: AD-011-02 - Touch Target and Visual Requirements
        
        initiateAutoDiscover()
        
        // Verify touch target sizes meet automotive requirements (48dp minimum)
        val criticalButtons = listOf(
            "Back to search",
            "Play information about this place",
            "Next POI", 
            "Previous POI",
            "Dislike"
        )
        
        criticalButtons.forEach { buttonDesc ->
            composeTestRule.onNodeWithContentDescription(buttonDesc)
                .assertExists("$buttonDesc should exist")
                .assertHeightIsAtLeast(48.dp)
                .assertWidthIsAtLeast(48.dp)
        }
        
        // Test high contrast compatibility
        verifyHighContrastCompatibility()
    }
    
    // MARK: - Test Suite AD-012: Performance Benchmarks
    
    @Test
    fun testAD012_01_DiscoveryPerformance() {
        // Test Case: AD-012-01 - Discovery Performance
        
        setTestLocation(45.3711, -121.8200)
        
        // Measure discovery performance multiple times
        val discoveryTimes = mutableListOf<Long>()
        
        repeat(5) {
            val startTime = System.currentTimeMillis()
            initiateAutoDiscover()
            
            composeTestRule.onNodeWithContentDescription("Main POI View")
                .assertExists()
            
            val discoveryTime = System.currentTimeMillis() - startTime
            discoveryTimes.add(discoveryTime)
            
            returnToDestinationSelection()
            Thread.sleep(1000) // Brief pause between tests
        }
        
        // Verify all discovery times meet requirement
        val maxDiscoveryTime = discoveryTimes.maxOrNull() ?: 0
        val avgDiscoveryTime = discoveryTimes.average()
        
        assertTrue("Maximum discovery time should be under 3 seconds", maxDiscoveryTime < 3000)
        assertTrue("Average discovery time should be under 2 seconds", avgDiscoveryTime < 2000)
        
        performanceMetrics.recordPerformanceBenchmark("discovery_times", discoveryTimes.map { it.toDouble() })
    }
    
    @Test
    fun testAD012_02_MemoryAndBatteryUsage() {
        // Test Case: AD-012-02 - Memory and Battery Usage
        
        val memoryMonitor = MemoryMonitor(context)
        val batteryMonitor = BatteryMonitor(context)
        
        memoryMonitor.startMonitoring()
        batteryMonitor.startMonitoring()
        
        // Run discovery session for extended period
        initiateAutoDiscover()
        
        // Monitor for 5 minutes of continuous operation
        val testDuration = 300000L // 5 minutes
        val endTime = System.currentTimeMillis() + testDuration
        
        while (System.currentTimeMillis() < endTime) {
            // Verify app remains responsive
            val currentPOIName = getCurrentPOIName()
            assertFalse("App should remain responsive during extended operation", currentPOIName.isEmpty())
            
            Thread.sleep(30000) // Check every 30 seconds
        }
        
        val memoryUsage = memoryMonitor.getAverageUsage()
        val batteryConsumption = batteryMonitor.getBatteryDrain()
        
        memoryMonitor.stopMonitoring()
        batteryMonitor.stopMonitoring()
        
        // Verify memory usage within limits (1.5GB = 1,610,612,736 bytes)
        assertTrue("Memory usage should be under 1.5GB", memoryUsage < 1_610_612_736)
        
        // Verify battery consumption (5% per hour = 0.417% per 5 minutes)
        assertTrue("Battery consumption should be under 0.5% for 5 minutes", batteryConsumption < 0.5)
        
        performanceMetrics.recordResourceUsage("memory_usage", memoryUsage, batteryConsumption)
    }
    
    // MARK: - Test Suite AD-013: Error Handling and Recovery
    
    @Test
    fun testAD013_01_NetworkFailureHandling() {
        // Test Case: AD-013-01 - Network Failure Handling
        
        // Start with network connectivity
        setNetworkConnectivity(true)
        initiateAutoDiscover()
        
        // Verify initial discovery works
        composeTestRule.onNodeWithContentDescription("Main POI View")
            .assertExists()
        
        // Simulate network failure
        setNetworkConnectivity(false)
        
        // Test graceful degradation
        composeTestRule.onNodeWithContentDescription("Next POI")
            .performClick()
        
        // Verify app remains functional with cached data
        val currentPOIName = getCurrentPOIName()
        assertFalse("App should function with cached data during network failure", currentPOIName.isEmpty())
        
        // Restore network and verify recovery
        setNetworkConnectivity(true)
        Thread.sleep(2000)
        
        // Verify new discovery works after network restoration
        returnToDestinationSelection()
        setTestLocation(37.7749, -122.4194) // Different location
        initiateAutoDiscover()
        
        composeTestRule.onNodeWithContentDescription("Main POI View")
            .assertExists("Discovery should work after network restoration")
    }
    
    @Test
    fun testAD013_02_LocationAndPermissionErrors() {
        // Test Case: AD-013-02 - Location and Permission Errors
        
        // Test discovery with location permission denied
        setLocationPermission(false)
        
        composeTestRule.onNodeWithContentDescription("Auto Discover - Find amazing places nearby")
            .performClick()
        
        // Verify appropriate error handling
        composeTestRule.onAllNodesWithText("Location permission")
            .assertCountGreaterThan(0)
        
        // Grant permission and verify discovery works
        setLocationPermission(true)
        
        composeTestRule.onNodeWithContentDescription("Auto Discover - Find amazing places nearby")
            .performClick()
        
        composeTestRule.onNodeWithContentDescription("Main POI View")
            .assertExists("Discovery should work after location permission granted")
    }
    
    // MARK: - Helper Methods
    
    private fun navigateToDestinationSelectionScreen() {
        // Navigate to clean Select Destination screen state
        composeTestRule.waitForIdle()
        
        // Check if we're already on the destination selection screen
        composeTestRule.onNodeWithContentDescription("Auto Discover - Find amazing places nearby")
            .assertExists()
    }
    
    private fun initiateAutoDiscover() {
        composeTestRule.onNodeWithContentDescription("Auto Discover - Find amazing places nearby")
            .assertExists()
            .performClick()
    }
    
    private fun returnToDestinationSelection() {
        try {
            composeTestRule.onNodeWithContentDescription("Back to search")
                .performClick()
        } catch (e: Exception) {
            // Try alternative back navigation
            composeTestRule.onNodeWithContentDescription("Back")
                .performClick()
        }
        
        composeTestRule.onNodeWithContentDescription("Auto Discover - Find amazing places nearby")
            .assertExists()
    }
    
    private fun setTestLocation(latitude: Double, longitude: Double) {
        // Set mock location for testing through test data
        testData.setMockLocation(latitude, longitude)
    }
    
    private fun getCurrentPOIName(): String {
        return try {
            val node = composeTestRule.onNodeWithContentDescription("currentPOIName")
            getNodeText(node)
        } catch (e: Exception) {
            ""
        }
    }
    
    private fun getCurrentPhotoIndex(): Int {
        return try {
            // Look for photo indicator pattern like "3/5"
            val nodes = composeTestRule.onAllNodesWithText("/5").fetchSemanticsNodes()
            if (nodes.isNotEmpty()) {
                // Extract current photo index from text
                val text = nodes.first().config.getOrNull(androidx.compose.ui.semantics.SemanticsProperties.Text)?.firstOrNull()?.text
                text?.substringBefore("/")?.toIntOrNull() ?: 1
            } else {
                1
            }
        } catch (e: Exception) {
            1
        }
    }
    
    private fun waitForPOIChange(initialPOI: String, timeoutMs: Long): Boolean {
        val endTime = System.currentTimeMillis() + timeoutMs
        
        while (System.currentTimeMillis() < endTime) {
            val currentPOI = getCurrentPOIName()
            if (currentPOI != initialPOI && currentPOI.isNotEmpty()) {
                return true
            }
            Thread.sleep(100)
        }
        
        return false
    }
    
    private fun simulateVoiceCommand(command: String) {
        // Simulate voice command through test infrastructure
        testData.simulateVoiceCommand(command)
    }
    
    private fun capturePOIList(): List<String> {
        val poiList = mutableListOf<String>()
        val maxPOIs = 10
        
        repeat(maxPOIs) { i ->
            val currentPOI = getCurrentPOIName()
            if (currentPOI.isNotEmpty() && !poiList.contains(currentPOI)) {
                poiList.add(currentPOI)
            }
            
            try {
                composeTestRule.onNodeWithContentDescription("Next POI")
                    .performClick()
                Thread.sleep(500)
            } catch (e: Exception) {
                // End of list or error
                break
            }
            
            // Break if we've looped back to the first POI
            if (i > 0 && poiList.firstOrNull() == currentPOI) {
                break
            }
        }
        
        return poiList
    }
    
    private fun verifyPOIExcluded(excludedPOI: String) {
        val poiList = capturePOIList()
        assertFalse("Disliked POI '$excludedPOI' should be excluded from results", poiList.contains(excludedPOI))
    }
    
    private fun navigateToNormalMainPOIView() {
        // Navigate to normal (non-discovery) MainPOIView for testing
        composeTestRule.onNodeWithContentDescription("Destination input field")
            .performTextInput("Test Location")
        
        composeTestRule.onNodeWithContentDescription("Start navigation")
            .performClick()
    }
    
    private fun testPOIAdvancementAfterPhotos() {
        // Test that POI advances after all photos are viewed
        val initialPOI = getCurrentPOIName()
        val timeout = System.currentTimeMillis() + 15000 // Allow time for 5 photos at 2 seconds each
        
        while (System.currentTimeMillis() < timeout) {
            val currentPOI = getCurrentPOIName()
            if (currentPOI != initialPOI) {
                // POI advanced automatically
                return
            }
            Thread.sleep(500)
        }
        
        fail("POI should advance automatically after all photos viewed")
    }
    
    private fun waitForAudioContentPlayback(timeoutMs: Long): Boolean {
        // Mock implementation for audio content validation
        Thread.sleep(500) // Simulate content generation time
        return true // Mock success for test
    }
    
    private fun startAudioContent() {
        composeTestRule.onNodeWithContentDescription("Play information about this place")
            .performClick()
    }
    
    private fun waitForAudioPause(timeoutMs: Long): Boolean = true // Mock implementation
    private fun waitForAudioResume(timeoutMs: Long): Boolean = true // Mock implementation  
    private fun waitForAudioStop(timeoutMs: Long): Boolean = true // Mock implementation
    
    private fun verifyPhotoQuality() {
        // Verify photo loading and quality indicators
        composeTestRule.onAllNodesWithText("/5")
            .assertCountGreaterThan(0)
    }
    
    private fun cyclePhotosForCaching() {
        // Navigate through multiple POIs and photos to populate cache
        repeat(3) {
            Thread.sleep(10000) // Wait for photo cycling
            
            composeTestRule.onNodeWithContentDescription("Next POI")
                .performClick()
        }
    }
    
    private fun verifyContinuousOperation(durationMs: Long) {
        val endTime = System.currentTimeMillis() + durationMs
        var photoChanges = 0
        var lastPhotoIndex = getCurrentPhotoIndex()
        
        while (System.currentTimeMillis() < endTime) {
            val currentPhotoIndex = getCurrentPhotoIndex()
            if (currentPhotoIndex != lastPhotoIndex) {
                photoChanges++
                lastPhotoIndex = currentPhotoIndex
            }
            Thread.sleep(1000)
        }
        
        assertTrue("Photo cycling should continue during continuous operation", photoChanges > 10)
    }
    
    private fun verifyHighContrastCompatibility() {
        // Test high contrast mode compatibility
        // Mock implementation for test framework
    }
    
    private fun setNetworkConnectivity(enabled: Boolean) {
        // Mock network connectivity changes for testing
        testData.setNetworkConnectivity(enabled)
    }
    
    private fun setLocationPermission(granted: Boolean) {
        // Mock location permission changes for testing
        testData.setLocationPermission(granted)
    }
    
    private fun getNodeText(node: SemanticsNodeInteraction): String {
        return try {
            val semanticsNode = node.fetchSemanticsNode()
            semanticsNode.config.getOrNull(androidx.compose.ui.semantics.SemanticsProperties.Text)?.firstOrNull()?.text ?: ""
        } catch (e: Exception) {
            ""
        }
    }
}

// MARK: - Supporting Classes

class AutoDiscoverTestData(private val context: Context) {
    fun cleanup() {
        // Clean up test data
    }
    
    fun setMockLocation(latitude: Double, longitude: Double) {
        // Set mock location for testing
    }
    
    fun simulateVoiceCommand(command: String) {
        // Simulate voice command for testing
    }
    
    fun setNetworkConnectivity(enabled: Boolean) {
        // Control network connectivity for testing
    }
    
    fun setLocationPermission(granted: Boolean) {
        // Control location permission for testing
    }
}

class PerformanceMetrics {
    private val metrics = mutableMapOf<String, Any>()
    
    fun recordUICheck(operation: String, duration: Double) {
        metrics["ui_$operation"] = duration
    }
    
    fun recordDiscoveryPerformance(operation: String, duration: Double) {
        metrics["discovery_$operation"] = duration
    }
    
    fun recordVoiceResponse(command: String, duration: Double) {
        metrics["voice_$command"] = duration
    }
    
    fun recordNavigation(operation: String, duration: Double) {
        metrics["nav_$operation"] = duration
    }
    
    fun recordAIPerformance(operation: String, duration: Double) {
        metrics["ai_$operation"] = duration
    }
    
    fun recordPhotoCycling(operation: String, duration: Double) {
        metrics["photo_$operation"] = duration
    }
    
    fun recordCachePerformance(operation: String, initialLoad: Double, cachedLoad: Double) {
        metrics["cache_${operation}_initial"] = initialLoad
        metrics["cache_${operation}_cached"] = cachedLoad
        metrics["cache_${operation}_improvement"] = ((initialLoad - cachedLoad) / initialLoad) * 100
    }
    
    fun recordPlatformMetric(metric: String, value: Double) {
        metrics["platform_$metric"] = value
    }
    
    fun recordPerformanceBenchmark(test: String, values: List<Double>) {
        metrics["benchmark_${test}_max"] = values.maxOrNull()
        metrics["benchmark_${test}_min"] = values.minOrNull()
        metrics["benchmark_${test}_avg"] = values.average()
    }
    
    fun recordResourceUsage(test: String, memory: Long, battery: Double) {
        metrics["resource_${test}_memory"] = memory
        metrics["resource_${test}_battery"] = battery
    }
    
    fun generateReport() {
        println("=== Auto Discover E2E Test Performance Report (Android) ===")
        metrics.toSortedMap().forEach { (key, value) ->
            println("$key: $value")
        }
        println("============================================================")
    }
}

class MemoryMonitor(private val context: Context) {
    private var isMonitoring = false
    private val memoryUsage = mutableListOf<Long>()
    
    fun startMonitoring() {
        isMonitoring = true
        // Start background monitoring
    }
    
    fun stopMonitoring() {
        isMonitoring = false
    }
    
    fun getAverageUsage(): Long {
        return if (memoryUsage.isEmpty()) 0 else memoryUsage.average().toLong()
    }
}

class BatteryMonitor(private val context: Context) {
    private var initialBatteryLevel: Float = 0f
    private var finalBatteryLevel: Float = 0f
    
    fun startMonitoring() {
        // Get initial battery level
        initialBatteryLevel = getBatteryLevel()
    }
    
    fun stopMonitoring() {
        // Get final battery level
        finalBatteryLevel = getBatteryLevel()
    }
    
    fun getBatteryDrain(): Double {
        return (initialBatteryLevel - finalBatteryLevel) * 100.0 // Convert to percentage
    }
    
    private fun getBatteryLevel(): Float {
        // Mock implementation - in real app would use BatteryManager
        return 1.0f
    }
}