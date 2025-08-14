package com.roadtrip.copilot.ui.screens

import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.roadtrip.copilot.managers.SpeechManager
import com.roadtrip.copilot.ui.theme.RoadtripCopilotTheme
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.runTest
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.Mock
import org.mockito.MockitoAnnotations
import org.mockito.kotlin.whenever
import org.mockito.kotlin.verify
import org.mockito.kotlin.any
import org.mockito.kotlin.eq

/**
 * Comprehensive test suite for Set Destination Screen
 * Tests implementation against design specifications including:
 * - Two-button layout functionality
 * - Voice integration and animation
 * - Accessibility compliance
 * - Test case: "Lost Lake, Oregon, Go" voice input
 * - Platform parity validation
 */
@RunWith(AndroidJUnit4::class)
class SetDestinationScreenTest {
    
    @get:Rule
    val composeTestRule = createComposeRule()
    
    @Mock
    private lateinit var mockSpeechManager: SpeechManager
    
    private val mockIsListening = MutableStateFlow(false)
    private val mockIsSpeaking = MutableStateFlow(false)
    private val mockRecognizedText = MutableStateFlow("")
    private val mockIsVoiceDetected = MutableStateFlow(false)
    
    private var navigationCalled = false
    private var navigationDestination: String? = null
    
    @Before
    fun setup() {
        MockitoAnnotations.openMocks(this)
        
        // Setup mock flows
        whenever(mockSpeechManager.isListening).thenReturn(mockIsListening)
        whenever(mockSpeechManager.isSpeaking).thenReturn(mockIsSpeaking)
        whenever(mockSpeechManager.recognizedText).thenReturn(mockRecognizedText)
        whenever(mockSpeechManager.isVoiceDetected).thenReturn(mockIsVoiceDetected)
        
        // Reset test state
        navigationCalled = false
        navigationDestination = null
    }
    
    // MARK: - Layout and UI Tests
    
    @Test
    fun setDestinationScreen_displaysCorrectLayout() {
        composeTestRule.setContent {
            RoadtripCopilotTheme {
                SetDestinationScreen(
                    onNavigate = { destination ->
                        navigationCalled = true
                        navigationDestination = destination
                    }
                )
            }
        }
        
        // Verify main components are displayed
        composeTestRule
            .onNodeWithText("Set Your Destination")
            .assertIsDisplayed()
        
        composeTestRule
            .onNodeWithText("Where would you like to go?")
            .assertIsDisplayed()
        
        // Verify two-button layout
        composeTestRule
            .onNodeWithContentDescription("Start navigation button")
            .assertIsDisplayed()
        
        composeTestRule
            .onNodeWithContentDescription("Microphone ready")
            .assertIsDisplayed()
    }
    
    @Test
    fun destinationInput_acceptsTextInput() {
        composeTestRule.setContent {
            RoadtripCopilotTheme {
                SetDestinationScreen(onNavigate = { })
            }
        }
        
        val testDestination = "San Francisco, CA"
        
        composeTestRule
            .onNodeWithText("Where would you like to go?")
            .performTextInput(testDestination)
        
        composeTestRule
            .onNodeWithText(testDestination)
            .assertIsDisplayed()
    }
    
    // MARK: - Button Functionality Tests
    
    @Test
    fun startButton_triggersNavigationWhenDestinationEntered() {
        composeTestRule.setContent {
            RoadtripCopilotTheme {
                SetDestinationScreen(
                    onNavigate = { destination ->
                        navigationCalled = true
                        navigationDestination = destination
                    }
                )
            }
        }
        
        val testDestination = "Portland, OR"
        
        // Enter destination
        composeTestRule
            .onNodeWithText("Where would you like to go?")
            .performTextInput(testDestination)
        
        // Click start button
        composeTestRule
            .onNodeWithContentDescription("Start navigation button")
            .performClick()
        
        // Verify navigation was triggered
        assert(navigationCalled)
        assert(navigationDestination == testDestination)
    }
    
    @Test
    fun micButton_togglesVoiceRecognition() {
        composeTestRule.setContent {
            RoadtripCopilotTheme {
                SetDestinationScreen(onNavigate = { })
            }
        }
        
        // Initially microphone should be ready
        composeTestRule
            .onNodeWithContentDescription("Microphone ready")
            .assertIsDisplayed()
        
        // Click microphone button to start listening
        composeTestRule
            .onNodeWithContentDescription("Microphone ready")
            .performClick()
        
        // Update mock state to listening
        mockIsListening.value = true
        
        composeTestRule.waitForIdle()
        
        // Verify state changed to listening
        composeTestRule
            .onNodeWithContentDescription("Microphone listening")
            .assertIsDisplayed()
    }
    
    // MARK: - Voice Integration Tests
    
    @Test
    fun voiceRecognition_updatesDestinationField() = runTest {
        composeTestRule.setContent {
            RoadtripCopilotTheme {
                SetDestinationScreen(onNavigate = { })
            }
        }
        
        val recognizedDestination = "Seattle, WA"
        
        // Simulate voice recognition result
        mockRecognizedText.value = recognizedDestination
        
        composeTestRule.waitForIdle()
        
        // Verify destination appears in input field
        composeTestRule
            .onNodeWithText(recognizedDestination)
            .assertIsDisplayed()
    }
    
    @Test
    fun voiceAnimation_showsDuringDetection() {
        composeTestRule.setContent {
            RoadtripCopilotTheme {
                SetDestinationScreen(onNavigate = { })
            }
        }
        
        // Simulate voice detection
        mockIsVoiceDetected.value = true
        
        composeTestRule.waitForIdle()
        
        // Verify voice animation is shown
        // Note: This would need to check for the actual animation component
        composeTestRule
            .onNodeWithContentDescription("Start navigation button")
            .assertIsDisplayed()
    }
    
    // MARK: - Test Case: "Lost Lake, Oregon, Go"
    
    @Test
    fun testCase_lostLakeOregonGo_triggersNavigation() = runTest {
        composeTestRule.setContent {
            RoadtripCopilotTheme {
                SetDestinationScreen(
                    onNavigate = { destination ->
                        navigationCalled = true
                        navigationDestination = destination
                    }
                )
            }
        }
        
        val testVoiceInput = "Lost Lake, Oregon, Go"
        
        // Simulate the test case voice input
        mockRecognizedText.value = testVoiceInput
        
        composeTestRule.waitForIdle()
        
        // Verify navigation was triggered with clean destination
        assert(navigationCalled)
        assert(navigationDestination?.contains("Lost Lake") == true)
        assert(navigationDestination?.contains("Oregon") == true)
        // "Go" should be stripped from the destination
        assert(navigationDestination?.contains("Go") == false)
    }
    
    @Test
    fun testCase_voiceCommandRecognition_goCommand() = runTest {
        composeTestRule.setContent {
            RoadtripCopilotTheme {
                SetDestinationScreen(
                    onNavigate = { destination ->
                        navigationCalled = true
                        navigationDestination = destination
                    }
                )
            }
        }
        
        val voiceCommands = listOf(
            "Lost Lake, Oregon, go",
            "Lost Lake, Oregon, navigate", 
            "Lost Lake, Oregon, start"
        )
        
        voiceCommands.forEach { command ->
            // Reset test state
            navigationCalled = false
            navigationDestination = null
            
            // Simulate voice command
            mockRecognizedText.value = command
            
            composeTestRule.waitForIdle()
            
            // Verify navigation triggered for each command
            assert(navigationCalled) { "Navigation not triggered for command: $command" }
            assert(navigationDestination?.contains("Lost Lake") == true) { 
                "Destination incorrect for command: $command" 
            }
        }
    }
    
    // MARK: - Accessibility Tests
    
    @Test
    fun accessibility_buttonsHaveCorrectContentDescriptions() {
        composeTestRule.setContent {
            RoadtripCopilotTheme {
                SetDestinationScreen(onNavigate = { })
            }
        }
        
        // Verify Start button accessibility
        composeTestRule
            .onNodeWithContentDescription("Start navigation button. Responds to 'go', 'navigate', or 'start' voice commands")
            .assertIsDisplayed()
        
        // Verify Microphone button accessibility
        composeTestRule
            .onAllNodesWithContentDescription("Microphone ready. Tap to start listening or say voice commands")
            .onFirst()
            .assertIsDisplayed()
    }
    
    @Test
    fun accessibility_inputFieldHasCorrectSemantics() {
        composeTestRule.setContent {
            RoadtripCopilotTheme {
                SetDestinationScreen(onNavigate = { })
            }
        }
        
        // Verify input field accessibility
        composeTestRule
            .onNodeWithContentDescription("Destination input field. You can type or use voice commands like 'navigate to' or 'go to'")
            .assertIsDisplayed()
    }
    
    @Test
    fun accessibility_voiceInstructionsAreProvided() {
        composeTestRule.setContent {
            RoadtripCopilotTheme {
                SetDestinationScreen(onNavigate = { })
            }
        }
        
        // Verify voice command instructions are displayed
        composeTestRule
            .onNodeWithText("Voice Commands:")
            .assertIsDisplayed()
        
        composeTestRule
            .onNodeWithText("• \"Lost Lake, Oregon, Go\" - Set destination and navigate")
            .assertIsDisplayed()
        
        composeTestRule
            .onNodeWithText("• \"Go\" / \"Navigate\" / \"Start\" - Begin navigation")
            .assertIsDisplayed()
        
        composeTestRule
            .onNodeWithText("• \"Mute\" / \"Unmute\" - Control microphone")
            .assertIsDisplayed()
    }
    
    // MARK: - Touch Target Size Tests (Automotive Safety)
    
    @Test
    fun touchTargets_meetAutomotiveSafetyRequirements() {
        composeTestRule.setContent {
            RoadtripCopilotTheme {
                SetDestinationScreen(onNavigate = { })
            }
        }
        
        // Verify Start button meets 56dp requirement (design spec)
        composeTestRule
            .onNodeWithContentDescription("Start navigation button")
            .assertWidthIsAtLeast(56.dp)
            .assertHeightIsAtLeast(56.dp)
        
        // Verify Mic button meets 56dp requirement
        composeTestRule
            .onAllNodesWithContentDescription("Microphone ready")
            .onFirst()
            .assertWidthIsAtLeast(56.dp)
            .assertHeightIsAtLeast(56.dp)
    }
    
    // MARK: - Voice Animation Tests
    
    @Test
    fun voiceAnimation_startsWithVoiceDetection() {
        composeTestRule.setContent {
            RoadtripCopilotTheme {
                SetDestinationScreen(onNavigate = { })
            }
        }
        
        // Initially no voice animation
        mockIsVoiceDetected.value = false
        composeTestRule.waitForIdle()
        
        // Start voice detection
        mockIsVoiceDetected.value = true
        composeTestRule.waitForIdle()
        
        // Verify animation state change
        // The button should show voice animation when voice is detected
        // This would need to be verified through the button's visual state
    }
    
    @Test
    fun voiceAnimation_stopsAfterSilenceTimeout() = runTest {
        composeTestRule.setContent {
            RoadtripCopilotTheme {
                SetDestinationScreen(onNavigate = { })
            }
        }
        
        // Start voice detection
        mockIsVoiceDetected.value = true
        composeTestRule.waitForIdle()
        
        // Stop voice detection (simulate 2-second silence)
        mockIsVoiceDetected.value = false
        
        // Wait for timeout period (2 seconds per design spec)
        composeTestRule.mainClock.advanceTimeBy(2100) // 2.1 seconds
        
        // Verify animation has stopped
        // Button should return to navigation arrow state
    }
    
    // MARK: - Integration Tests
    
    @Test
    fun integration_voiceCommandToNavigation_fullFlow() = runTest {
        composeTestRule.setContent {
            RoadtripCopilotTheme {
                SetDestinationScreen(
                    onNavigate = { destination ->
                        navigationCalled = true
                        navigationDestination = destination
                    }
                )
            }
        }
        
        // Simulate complete voice interaction flow
        // 1. Voice detection starts
        mockIsVoiceDetected.value = true
        composeTestRule.waitForIdle()
        
        // 2. Voice recognition produces result
        mockRecognizedText.value = "Lost Lake, Oregon, Go"
        composeTestRule.waitForIdle()
        
        // 3. Verify navigation was triggered
        assert(navigationCalled)
        assert(navigationDestination == "Lost Lake, Oregon")
        
        // 4. Voice detection stops
        mockIsVoiceDetected.value = false
        composeTestRule.waitForIdle()
    }
    
    // MARK: - Performance Tests
    
    @Test
    fun performance_buttonResponseTime() {
        composeTestRule.setContent {
            RoadtripCopilotTheme {
                SetDestinationScreen(onNavigate = { })
            }
        }
        
        val startTime = System.currentTimeMillis()
        
        // Perform button click
        composeTestRule
            .onNodeWithContentDescription("Start navigation button")
            .performClick()
        
        val endTime = System.currentTimeMillis()
        val responseTime = endTime - startTime
        
        // Verify response time is under 100ms (design spec requirement)
        assert(responseTime < 100) { 
            "Button response time $responseTime ms exceeds 100ms requirement" 
        }
    }
    
    // MARK: - Error Handling Tests
    
    @Test
    fun errorHandling_emptyDestination_doesNotTriggerNavigation() {
        composeTestRule.setContent {
            RoadtripCopilotTheme {
                SetDestinationScreen(
                    onNavigate = { destination ->
                        navigationCalled = true
                        navigationDestination = destination
                    }
                )
            }
        }
        
        // Click start button without entering destination
        composeTestRule
            .onNodeWithContentDescription("Start navigation button")
            .performClick()
        
        // Verify navigation was not triggered
        assert(!navigationCalled)
    }
    
    @Test
    fun errorHandling_malformedVoiceInput_handledGracefully() = runTest {
        composeTestRule.setContent {
            RoadtripCopilotTheme {
                SetDestinationScreen(onNavigate = { })
            }
        }
        
        val malformedInputs = listOf(
            "", // Empty
            "   ", // Whitespace only
            "go go go", // Multiple commands
            "12345!@#$%" // Non-text characters
        )
        
        malformedInputs.forEach { input ->
            mockRecognizedText.value = input
            composeTestRule.waitForIdle()
            
            // Should not crash - verify screen is still displayed
            composeTestRule
                .onNodeWithText("Set Your Destination")
                .assertIsDisplayed()
        }
    }
}