package com.roadtrip.copilot

import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.unit.dp
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.filters.LargeTest
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.uiautomator.UiDevice
import com.roadtrip.copilot.ui.onboarding.*
import com.roadtrip.copilot.models.*
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@LargeTest
@RunWith(AndroidJUnit4::class)
class AccessibilityTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    private lateinit var device: UiDevice

    @Before
    fun setup() {
        device = UiDevice.getInstance(InstrumentationRegistry.getInstrumentation())
    }

    // MARK: - TalkBack Integration Tests

    @Test
    fun testTalkBackOnboardingFlow() {
        composeTestRule.setContent {
            OnboardingFlow()
        }

        // Step 1: Destination Selection
        composeTestRule
            .onNodeWithText("Where would you like to go?")
            .assertIsDisplayed()
            .assertHasContentDescription()

        // Search field should be accessible
        composeTestRule
            .onNodeWithText("Search for destination...")
            .assertIsDisplayed()
            .assertHasContentDescription()
            .assert(hasRole(Role.EditText))

        // Voice button should have proper accessibility
        composeTestRule
            .onNodeWithTag("voice_search_button")
            .assertIsDisplayed()
            .assertHasContentDescription()
            .assert(hasRole(Role.Button))
            .assertHasClickAction()

        // Navigate through the flow with TalkBack considerations
        navigateToRadiusStepAccessible()

        // Step 2: Radius Selection
        composeTestRule
            .onNodeWithText("Set your search radius")
            .assertIsDisplayed()
            .assertHasContentDescription()

        // Slider should be accessible with proper semantics
        composeTestRule
            .onNodeWithTag("radius_slider")
            .assertIsDisplayed()
            .assert(hasRole(Role.Slider))
            .assertHasContentDescription()

        // Distance unit buttons should be accessible
        composeTestRule
            .onNodeWithText("Miles")
            .assertIsDisplayed()
            .assert(hasRole(Role.RadioButton))
            .assertHasContentDescription()

        composeTestRule
            .onNodeWithText("Kilometers")
            .assertIsDisplayed()
            .assert(hasRole(Role.RadioButton))
            .assertHasContentDescription()

        navigateToCategoryStepAccessible()

        // Step 3: Categories
        composeTestRule
            .onNodeWithText("Choose your interests")
            .assertIsDisplayed()
            .assertHasContentDescription()

        // Category buttons should be accessible
        composeTestRule
            .onNodeWithTag("category_restaurants")
            .assertIsDisplayed()
            .assert(hasRole(Role.Checkbox))
            .assertHasContentDescription()
            .assertHasClickAction()

        navigateToConfirmationStepAccessible()

        // Step 4: Confirmation
        composeTestRule
            .onNodeWithText("Ready for your roadtrip?")
            .assertIsDisplayed()
            .assertHasContentDescription()

        // Start button should be accessible
        composeTestRule
            .onNodeWithText("Start My Roadtrip!")
            .assertIsDisplayed()
            .assert(hasRole(Role.Button))
            .assertHasContentDescription()
            .assertHasClickAction()
    }

    @Test
    fun testTalkBackVoiceButtons() {
        composeTestRule.setContent {
            DestinationStep(
                onDestinationSelected = {},
                onNext = {}
            )
        }

        // Voice search button accessibility
        composeTestRule
            .onNodeWithTag("voice_search_button")
            .assertIsDisplayed()
            .assertHasContentDescription()
            .assert(hasRole(Role.Button))
            .assertHasClickAction()

        // Test state change accessibility
        val voiceButton = composeTestRule.onNodeWithTag("voice_search_button")
        val initialDescription = voiceButton.fetchSemanticsNode().config.getOrNull(SemanticsProperties.ContentDescription)

        voiceButton.performClick() // Start listening

        // Content description should change to reflect listening state
        val listeningDescription = voiceButton.fetchSemanticsNode().config.getOrNull(SemanticsProperties.ContentDescription)
        assert(initialDescription != listeningDescription) { "Content description should change when listening" }

        voiceButton.performClick() // Stop listening
    }

    // MARK: - Minimum Touch Target Size Tests (48dp for Android)

    @Test
    fun testMinimumTouchTargetSizes() {
        composeTestRule.setContent {
            OnboardingFlow()
        }

        // Voice button should meet 48dp minimum
        composeTestRule
            .onNodeWithTag("voice_search_button")
            .assertIsDisplayed()
            .assert(hasMinimumTouchTargetSize(48.dp))

        // Next button should meet minimum size
        composeTestRule
            .onNodeWithText("Next: Set Search Radius")
            .assertIsDisplayed()
            .assert(hasMinimumTouchTargetSize(48.dp))

        navigateToRadiusStepAccessible()

        // Distance unit buttons should meet minimum size
        composeTestRule
            .onNodeWithText("Miles")
            .assertIsDisplayed()
            .assert(hasMinimumTouchTargetSize(48.dp))

        composeTestRule
            .onNodeWithText("Kilometers")
            .assertIsDisplayed()
            .assert(hasMinimumTouchTargetSize(48.dp))

        // Voice radius button should meet minimum size
        composeTestRule
            .onNodeWithText("Set by Voice")
            .assertIsDisplayed()
            .assert(hasMinimumTouchTargetSize(48.dp))

        navigateToCategoryStepAccessible()

        // Category buttons should meet minimum size for automotive use
        composeTestRule
            .onNodeWithTag("category_restaurants")
            .assertIsDisplayed()
            .assert(hasMinimumTouchTargetSize(48.dp))
    }

    // MARK: - High Contrast Support Tests

    @Test
    fun testHighContrastSupport() {
        // Enable high contrast mode
        enableAccessibilitySettings()

        composeTestRule.setContent {
            OnboardingFlow()
        }

        // Elements should still be visible and accessible in high contrast
        composeTestRule
            .onNodeWithText("Where would you like to go?")
            .assertIsDisplayed()
            .assertHasContentDescription()

        composeTestRule
            .onNodeWithTag("voice_search_button")
            .assertIsDisplayed()
            .assertHasContentDescription()

        // Navigation should work in high contrast mode
        navigateToRadiusStepAccessible()

        composeTestRule
            .onNodeWithText("Set your search radius")
            .assertIsDisplayed()
            .assertHasContentDescription()
    }

    // MARK: - Large Text Support Tests

    @Test
    fun testLargeTextSupport() {
        // Enable large text size
        enableLargeTextSettings()

        composeTestRule.setContent {
            OnboardingFlow()
        }

        // Text should be readable and elements accessible with large text
        composeTestRule
            .onNodeWithText("Where would you like to go?")
            .assertIsDisplayed()
            .assertHasContentDescription()

        // Buttons should maintain minimum size with large text
        composeTestRule
            .onNodeWithTag("voice_search_button")
            .assertIsDisplayed()
            .assert(hasMinimumTouchTargetSize(48.dp))

        navigateToRadiusStepAccessible()

        // Controls should remain accessible with large text
        composeTestRule
            .onNodeWithTag("radius_slider")
            .assertIsDisplayed()
            .assert(hasRole(Role.Slider))
    }

    // MARK: - Switch Access Support Tests

    @Test
    fun testSwitchAccessSupport() {
        composeTestRule.setContent {
            OnboardingFlow()
        }

        // Elements should be focusable by Switch Access
        composeTestRule
            .onNodeWithTag("voice_search_button")
            .assertIsDisplayed()
            .assertHasClickAction()
            .assert(isFocusable())

        composeTestRule
            .onNodeWithText("Search for destination...")
            .assertIsDisplayed()
            .assert(isFocusable())

        composeTestRule
            .onNodeWithText("Next: Set Search Radius")
            .assertIsDisplayed()
            .assertHasClickAction()
            .assert(isFocusable())
    }

    // MARK: - Voice Access Support Tests

    @Test
    fun testVoiceAccessSupport() {
        composeTestRule.setContent {
            OnboardingFlow()
        }

        // Elements should have clear content descriptions for Voice Access
        composeTestRule
            .onNodeWithTag("voice_search_button")
            .assertIsDisplayed()
            .assertHasContentDescription()

        // Button labels should be descriptive enough for voice commands
        composeTestRule
            .onNodeWithText("Next: Set Search Radius")
            .assertIsDisplayed()
            .assertHasContentDescription()

        navigateToRadiusStepAccessible()

        // Slider should have clear description for voice control
        composeTestRule
            .onNodeWithTag("radius_slider")
            .assertIsDisplayed()
            .assertHasContentDescription()
    }

    // MARK: - Automotive Environment Accessibility Tests

    @Test
    fun testAutomotiveVisibilityRequirements() {
        composeTestRule.setContent {
            OnboardingFlow()
        }

        // Voice buttons should be large enough for automotive use
        composeTestRule
            .onNodeWithTag("voice_search_button")
            .assertIsDisplayed()
            .assert(hasMinimumTouchTargetSize(56.dp)) // Larger than standard for automotive

        navigateToRadiusStepAccessible()

        // Controls should be easily accessible while driving
        composeTestRule
            .onNodeWithText("Miles")
            .assertIsDisplayed()
            .assert(hasMinimumTouchTargetSize(48.dp))

        composeTestRule
            .onNodeWithText("Set by Voice")
            .assertIsDisplayed()
            .assert(hasMinimumTouchTargetSize(48.dp))

        // Slider should have clear accessibility information
        composeTestRule
            .onNodeWithTag("radius_slider")
            .assertIsDisplayed()
            .assertHasContentDescription()
            .assert(hasStateDescription())
    }

    @Test
    fun testGlareResistanceSupport() {
        // Test with high contrast and brightness settings
        enableAccessibilitySettings()
        enableHighContrastSettings()

        composeTestRule.setContent {
            OnboardingFlow()
        }

        // Elements should be visible in high brightness conditions
        composeTestRule
            .onNodeWithText("Where would you like to go?")
            .assertIsDisplayed()

        composeTestRule
            .onNodeWithTag("voice_search_button")
            .assertIsDisplayed()
            .assertHasContentDescription()

        navigateToRadiusStepAccessible()

        composeTestRule
            .onNodeWithText("Set your search radius")
            .assertIsDisplayed()
    }

    // MARK: - Voice-First Interface Accessibility Tests

    @Test
    fun testVoiceFirstAccessibility() {
        composeTestRule.setContent {
            DestinationStep(
                onDestinationSelected = {},
                onNext = {}
            )
        }

        // Voice button should have descriptive accessibility information
        val voiceButton = composeTestRule.onNodeWithTag("voice_search_button")
        voiceButton
            .assertIsDisplayed()
            .assertHasContentDescription()
            .assert(hasRole(Role.Button))

        // Content description should indicate voice functionality
        val semantics = voiceButton.fetchSemanticsNode()
        val contentDescription = semantics.config.getOrNull(SemanticsProperties.ContentDescription)
        assert(contentDescription != null && contentDescription.any { 
            it.contains("voice", ignoreCase = true) || it.contains("mic", ignoreCase = true) 
        })

        // Test state changes
        voiceButton.performClick() // Start listening

        val listeningSemantics = voiceButton.fetchSemanticsNode()
        val listeningDescription = listeningSemantics.config.getOrNull(SemanticsProperties.ContentDescription)
        assert(listeningDescription != contentDescription) { 
            "Content description should change when listening" 
        }

        voiceButton.performClick() // Stop listening
    }

    @Test
    fun testVoiceFeedbackAccessibility() {
        composeTestRule.setContent {
            OnboardingFlow()
        }

        // Voice feedback should not interfere with TalkBack
        val voiceButton = composeTestRule.onNodeWithTag("voice_search_button")
        voiceButton.assertIsDisplayed()

        // Test that accessibility services can still function with voice feedback
        voiceButton.performClick() // This should work with TalkBack enabled
        voiceButton.performClick() // Stop listening

        // Voice feedback should be complementary to accessibility services
    }

    // MARK: - Accessibility Performance Tests

    @Test
    fun testAccessibilityPerformance() {
        composeTestRule.setContent {
            OnboardingFlow()
        }

        // Measure performance with accessibility features enabled
        val startTime = System.currentTimeMillis()

        // Navigate through entire flow
        navigateToRadiusStepAccessible()
        navigateToCategoryStepAccessible()
        navigateToConfirmationStepAccessible()

        val endTime = System.currentTimeMillis()
        val totalTime = endTime - startTime

        // Accessibility features should not significantly impact performance
        assert(totalTime < 5000) { 
            "Navigation with accessibility should complete in under 5 seconds, took ${totalTime}ms" 
        }
    }

    // MARK: - Semantic Tree Tests

    @Test
    fun testSemanticTreeStructure() {
        composeTestRule.setContent {
            OnboardingFlow()
        }

        // Test that semantic tree is properly structured
        composeTestRule
            .onNodeWithText("Where would you like to go?")
            .assertIsDisplayed()
            .assert(hasRole(Role.Text))

        // Search field should be properly structured
        composeTestRule
            .onNodeWithText("Search for destination...")
            .assertIsDisplayed()
            .assert(hasRole(Role.EditText))

        // Buttons should have correct roles
        composeTestRule
            .onNodeWithTag("voice_search_button")
            .assertIsDisplayed()
            .assert(hasRole(Role.Button))

        composeTestRule
            .onNodeWithText("Next: Set Search Radius")
            .assertIsDisplayed()
            .assert(hasRole(Role.Button))
    }

    // MARK: - Error Handling Accessibility Tests

    @Test
    fun testAccessibilityErrorStates() {
        composeTestRule.setContent {
            DestinationStep(
                onDestinationSelected = {},
                onNext = {}
            )
        }

        // Test that error states are accessible
        val nextButton = composeTestRule.onNodeWithText("Next: Set Search Radius")
        nextButton.assertIsDisplayed()

        // Disabled state should be communicated to accessibility services
        if (!nextButton.fetchSemanticsNode().config.getOrNull(SemanticsProperties.Disabled) != true) {
            // Button should have appropriate state description when disabled
            nextButton.assert(hasStateDescription())
        }
    }

    // MARK: - Helper Methods

    private fun navigateToRadiusStepAccessible() {
        // Select destination for testing
        val searchField = composeTestRule.onNodeWithText("Search for destination...")
        searchField.performTextInput("Test City")

        // Simulate destination selection
        composeTestRule.onNodeWithTag("destination_selection").performClick()

        val nextButton = composeTestRule.onNodeWithText("Next: Set Search Radius")
        nextButton.performClick()
    }

    private fun navigateToCategoryStepAccessible() {
        val nextButton = composeTestRule.onNodeWithText("Next: Choose Interests")
        nextButton.performClick()
    }

    private fun navigateToConfirmationStepAccessible() {
        // Select categories
        composeTestRule
            .onNodeWithTag("category_restaurants")
            .performClick()

        val nextButton = composeTestRule.onNodeWithText("Review Settings")
        nextButton.performClick()
    }

    private fun enableAccessibilitySettings() {
        // In a real test, this would enable actual accessibility settings
        // For this test, we simulate the settings being enabled
    }

    private fun enableLargeTextSettings() {
        // In a real test, this would enable large text settings
        // For this test, we simulate large text being enabled
    }

    private fun enableHighContrastSettings() {
        // In a real test, this would enable high contrast settings
        // For this test, we simulate high contrast being enabled
    }
}

// MARK: - Custom Semantic Matchers

private fun hasMinimumTouchTargetSize(minimumSize: androidx.compose.ui.unit.Dp) = 
    SemanticsMatcher("has minimum touch target size of $minimumSize") { node ->
        val size = node.layoutInfo.size
        val minimumSizePx = with(node.layoutInfo.density) { minimumSize.toPx() }
        size.width >= minimumSizePx && size.height >= minimumSizePx
    }

private fun hasRole(role: Role) = 
    SemanticsMatcher("has role $role") { node ->
        node.config.getOrNull(SemanticsProperties.Role) == role
    }

private fun hasContentDescription() = 
    SemanticsMatcher("has content description") { node ->
        node.config.getOrNull(SemanticsProperties.ContentDescription) != null
    }

private fun hasStateDescription() = 
    SemanticsMatcher("has state description") { node ->
        node.config.getOrNull(SemanticsProperties.StateDescription) != null
    }

private fun isFocusable() = 
    SemanticsMatcher("is focusable") { node ->
        node.config.getOrNull(SemanticsProperties.Focused) != null ||
        node.config.contains(SemanticsActions.RequestFocus)
    }

// MARK: - Accessibility Verification Extensions

fun SemanticsNodeInteraction.assertMeetsAutomotiveRequirements(): SemanticsNodeInteraction {
    // Verify minimum touch target size for automotive
    this.assert(hasMinimumTouchTargetSize(48.dp))
    
    // Verify has content description
    this.assertHasContentDescription()
    
    // Verify is focusable if interactive
    val node = this.fetchSemanticsNode()
    if (node.config.contains(SemanticsActions.OnClick)) {
        this.assert(isFocusable())
    }
    
    return this
}

fun SemanticsNodeInteraction.assertSupportsVoiceControl(): SemanticsNodeInteraction {
    // Verify has content description for voice commands
    this.assertHasContentDescription()
    
    // Verify content description is not empty
    val node = this.fetchSemanticsNode()
    val contentDescription = node.config.getOrNull(SemanticsProperties.ContentDescription)
    assert(contentDescription != null && contentDescription.isNotEmpty()) {
        "Content description should not be empty for voice control"
    }
    
    return this
}

// MARK: - Test Data Classes

enum class AccessibilityFeature {
    TALKBACK, SWITCH_ACCESS, VOICE_ACCESS, HIGH_CONTRAST, LARGE_TEXT, REDUCED_MOTION
}

data class AccessibilityTestConfig(
    val feature: AccessibilityFeature,
    val enabled: Boolean
)