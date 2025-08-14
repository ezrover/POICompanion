package com.roadtrip.copilot

import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.filters.LargeTest
import com.roadtrip.copilot.ui.onboarding.*
import com.roadtrip.copilot.models.*
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@LargeTest
@RunWith(AndroidJUnit4::class)
class OnboardingFlowTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    // MARK: - Complete Onboarding Flow Tests

    @Test
    fun testCompleteOnboardingFlow() {
        // Start the onboarding flow
        composeTestRule.setContent {
            OnboardingFlow()
        }

        // Step 1: Welcome/Destination Selection
        composeTestRule
            .onNodeWithText("Where would you like to go?")
            .assertIsDisplayed()

        // Test search functionality
        composeTestRule
            .onNodeWithText("Search for destination...")
            .performTextInput("San Francisco")

        // Select destination (simulate)
        composeTestRule
            .onNodeWithTag("destination_selection")
            .performClick()

        // Proceed to next step
        composeTestRule
            .onNodeWithText("Next: Set Search Radius")
            .assertIsEnabled()
            .performClick()

        // Step 2: Radius Selection
        composeTestRule
            .onNodeWithText("Set your search radius")
            .assertIsDisplayed()

        // Test radius slider
        composeTestRule
            .onNodeWithTag("radius_slider")
            .performTouchInput { swipeRight() }

        // Test distance unit toggle
        composeTestRule
            .onNodeWithText("Kilometers")
            .performClick()

        composeTestRule
            .onNodeWithText("Miles")
            .performClick()

        // Proceed to categories
        composeTestRule
            .onNodeWithText("Next: Choose Interests")
            .performClick()

        // Step 3: Category Selection
        composeTestRule
            .onNodeWithText("Choose your interests")
            .assertIsDisplayed()

        // Test "All" button
        composeTestRule
            .onNodeWithText("All")
            .performClick()

        // Verify categories are selected
        composeTestRule
            .onNodeWithText("12 categories selected")
            .assertIsDisplayed()

        // Test "Clear" button
        composeTestRule
            .onNodeWithText("Clear")
            .performClick()

        // Select individual categories
        composeTestRule
            .onNodeWithTag("category_restaurants")
            .performClick()

        composeTestRule
            .onNodeWithTag("category_parks")
            .performClick()

        composeTestRule
            .onNodeWithTag("category_attractions")
            .performClick()

        // Proceed to confirmation
        composeTestRule
            .onNodeWithText("Review Settings")
            .assertIsEnabled()
            .performClick()

        // Step 4: Confirmation
        composeTestRule
            .onNodeWithText("Ready for your roadtrip?")
            .assertIsDisplayed()

        // Verify settings summary
        composeTestRule
            .onNodeWithText("Destination")
            .assertIsDisplayed()

        composeTestRule
            .onNodeWithText("Search Radius")
            .assertIsDisplayed()

        composeTestRule
            .onNodeWithText("Interests")
            .assertIsDisplayed()

        // Complete onboarding
        composeTestRule
            .onNodeWithText("Start My Roadtrip!")
            .performClick()

        // Verify completion
        composeTestRule.waitForIdle()
    }

    // MARK: - Individual Step Tests

    @Test
    fun testDestinationStepInteractions() {
        composeTestRule.setContent {
            DestinationStep(
                onDestinationSelected = {},
                onNext = {}
            )
        }

        // Test search field
        composeTestRule
            .onNodeWithText("Search for destination...")
            .assertIsDisplayed()
            .performTextInput("Los Angeles")

        // Test voice search button
        composeTestRule
            .onNodeWithTag("voice_search_button")
            .assertIsDisplayed()
            .performClick()

        // Test next button disabled state (no destination selected)
        composeTestRule
            .onNodeWithText("Next: Set Search Radius")
            .assertIsNotEnabled()
    }

    @Test 
    fun testRadiusStepInteractions() {
        composeTestRule.setContent {
            RadiusStep(
                userPreferences = UserPreferences(),
                onNext = {},
                onBack = {}
            )
        }

        // Test radius display
        composeTestRule
            .onNodeWithTag("radius_display")
            .assertIsDisplayed()

        // Test slider interaction
        composeTestRule
            .onNodeWithTag("radius_slider")
            .assertIsDisplayed()
            .performTouchInput { swipeRight() }

        // Test unit toggle
        composeTestRule
            .onNodeWithText("Kilometers")
            .performClick()
            .assertIsSelected()

        composeTestRule
            .onNodeWithText("Miles")
            .performClick()
            .assertIsSelected()

        // Test voice input
        composeTestRule
            .onNodeWithText("Set by Voice")
            .performClick()

        // Test navigation buttons
        composeTestRule
            .onNodeWithText("Back")
            .assertIsDisplayed()

        composeTestRule
            .onNodeWithText("Next: Choose Interests")
            .assertIsEnabled()
    }

    @Test
    fun testCategoryStepInteractions() {
        composeTestRule.setContent {
            CategoryStep(
                userPreferences = UserPreferences(),
                onNext = {},
                onBack = {}
            )
        }

        // Test category grid display
        composeTestRule
            .onNodeWithTag("categories_grid")
            .assertIsDisplayed()

        // Test individual category selection
        composeTestRule
            .onNodeWithTag("category_restaurants")
            .assertIsDisplayed()
            .performClick()

        // Test "All" functionality
        composeTestRule
            .onNodeWithText("All")
            .performClick()

        // Verify count update
        composeTestRule
            .onNodeWithText("12 categories selected")
            .assertIsDisplayed()

        // Test "Clear" functionality
        composeTestRule
            .onNodeWithText("Clear")
            .performClick()

        // Next button should be disabled with no categories
        composeTestRule
            .onNodeWithText("Review Settings")
            .assertIsNotEnabled()

        // Select category to enable next
        composeTestRule
            .onNodeWithTag("category_restaurants")
            .performClick()

        composeTestRule
            .onNodeWithText("Review Settings")
            .assertIsEnabled()

        // Test voice selection
        composeTestRule
            .onNodeWithText("Voice")
            .performClick()
    }

    @Test
    fun testConfirmationStepDisplay() {
        composeTestRule.setContent {
            ConfirmationStep(
                selectedDestination = "San Francisco",
                userPreferences = UserPreferences().apply {
                    searchRadius = 5.0
                    selectedCategories = setOf(POICategory.RESTAURANTS)
                },
                onConfirm = {},
                onBack = {}
            )
        }

        // Verify summary cards
        composeTestRule
            .onNodeWithText("Destination")
            .assertIsDisplayed()

        composeTestRule
            .onNodeWithText("Search Radius")
            .assertIsDisplayed()

        composeTestRule
            .onNodeWithText("Interests")
            .assertIsDisplayed()

        // Test navigation buttons
        composeTestRule
            .onNodeWithText("Back to Categories")
            .assertIsDisplayed()

        composeTestRule
            .onNodeWithText("Start My Roadtrip!")
            .assertIsDisplayed()
            .assertIsEnabled()

        // Test back navigation
        composeTestRule
            .onNodeWithText("Back to Categories")
            .performClick()
    }

    // MARK: - Navigation Tests

    @Test
    fun testBackNavigation() {
        var currentStep = OnboardingStep.DESTINATION

        composeTestRule.setContent {
            OnboardingFlow(
                currentStep = currentStep,
                onStepChanged = { currentStep = it }
            )
        }

        // Navigate forward through all steps
        navigateToConfirmationStep()

        // Navigate back through steps
        composeTestRule
            .onNodeWithText("Back to Categories")
            .performClick()

        composeTestRule
            .onNodeWithText("Choose your interests")
            .assertIsDisplayed()

        composeTestRule
            .onNodeWithText("Back")
            .performClick()

        composeTestRule
            .onNodeWithText("Set your search radius")
            .assertIsDisplayed()

        composeTestRule
            .onNodeWithText("Back")
            .performClick()

        composeTestRule
            .onNodeWithText("Where would you like to go?")
            .assertIsDisplayed()
    }

    @Test
    fun testStepProgression() {
        composeTestRule.setContent {
            OnboardingFlow()
        }

        // Step 1: Next disabled without destination
        composeTestRule
            .onNodeWithText("Next: Set Search Radius")
            .assertIsNotEnabled()

        // Select destination
        selectDestinationForTesting()

        composeTestRule
            .onNodeWithText("Next: Set Search Radius")
            .assertIsEnabled()
            .performClick()

        // Step 2: Next always enabled (has default radius)
        composeTestRule
            .onNodeWithText("Next: Choose Interests")
            .assertIsEnabled()
            .performClick()

        // Step 3: Next disabled without categories
        composeTestRule
            .onNodeWithText("Clear")
            .performClick()

        composeTestRule
            .onNodeWithText("Review Settings")
            .assertIsNotEnabled()

        // Select categories
        selectCategoriesForTesting()

        composeTestRule
            .onNodeWithText("Review Settings")
            .assertIsEnabled()
            .performClick()

        // Step 4: Start button always enabled
        composeTestRule
            .onNodeWithText("Start My Roadtrip!")
            .assertIsEnabled()
    }

    // MARK: - Voice Integration Tests

    @Test
    fun testVoiceButtonsAccessibility() {
        composeTestRule.setContent {
            OnboardingFlow()
        }

        // Test voice button touch targets (minimum 48dp)
        composeTestRule
            .onNodeWithTag("voice_search_button")
            .assertIsDisplayed()
            .assert(hasMinimumTouchTargetSize())

        navigateToRadiusStep()

        composeTestRule
            .onNodeWithText("Set by Voice")
            .assert(hasMinimumTouchTargetSize())

        navigateToCategoryStep()

        composeTestRule
            .onNodeWithText("Voice")
            .assert(hasMinimumTouchTargetSize())
    }

    @Test
    fun testVoiceButtonStates() {
        composeTestRule.setContent {
            DestinationStep(
                onDestinationSelected = {},
                onNext = {}
            )
        }

        val voiceButton = composeTestRule.onNodeWithTag("voice_search_button")

        // Test initial state
        voiceButton.assertIsDisplayed()

        // Test listening state
        voiceButton.performClick()
        
        // Voice button should show listening state
        composeTestRule.waitForIdle()

        // Stop listening
        voiceButton.performClick()
    }

    // MARK: - Accessibility Tests

    @Test
    fun testAccessibilityLabels() {
        composeTestRule.setContent {
            OnboardingFlow()
        }

        // Test search field accessibility
        composeTestRule
            .onNodeWithText("Search for destination...")
            .assertIsDisplayed()
            .assertHasNoClickAction() // Text field, not button

        // Test voice button accessibility
        composeTestRule
            .onNodeWithTag("voice_search_button")
            .assertIsDisplayed()
            .assertHasClickAction()

        // Test next button accessibility
        composeTestRule
            .onNodeWithText("Next: Set Search Radius")
            .assertIsDisplayed()
            .assertHasClickAction()
    }

    @Test
    fun testSemanticNavigation() {
        composeTestRule.setContent {
            OnboardingFlow()
        }

        // Test that semantic navigation works correctly
        composeTestRule
            .onNodeWithText("Where would you like to go?")
            .assertIsDisplayed()

        // Test semantic ordering
        composeTestRule
            .onAllNodesWithText("Search for destination...")
            .assertCountEquals(1)

        composeTestRule
            .onAllNodesWithTag("voice_search_button")
            .assertCountEquals(1)
    }

    // MARK: - Performance Tests

    @Test
    fun testOnboardingFlowPerformance() {
        val startTime = System.currentTimeMillis()

        composeTestRule.setContent {
            OnboardingFlow()
        }

        // Complete the flow
        navigateToConfirmationStep()

        val endTime = System.currentTimeMillis()
        val totalTime = endTime - startTime

        // Onboarding should complete quickly (under 5 seconds for UI)
        assert(totalTime < 5000) { "Onboarding flow took ${totalTime}ms, should be under 5000ms" }
    }

    @Test
    fun testCategorySelectionPerformance() {
        composeTestRule.setContent {
            CategoryStep(
                userPreferences = UserPreferences(),
                onNext = {},
                onBack = {}
            )
        }

        val startTime = System.currentTimeMillis()

        // Select and deselect all categories rapidly
        repeat(10) {
            composeTestRule
                .onNodeWithText("All")
                .performClick()

            composeTestRule
                .onNodeWithText("Clear")
                .performClick()
        }

        val endTime = System.currentTimeMillis()
        val totalTime = endTime - startTime

        // Should handle rapid selections efficiently
        assert(totalTime < 2000) { "Category selection took ${totalTime}ms, should be under 2000ms" }
    }

    // MARK: - Error Handling Tests

    @Test
    fun testInvalidDestinationHandling() {
        composeTestRule.setContent {
            DestinationStep(
                onDestinationSelected = {},
                onNext = {}
            )
        }

        // Enter invalid destination
        composeTestRule
            .onNodeWithText("Search for destination...")
            .performTextInput("Invalid Location 123!@#")

        // Next button should remain disabled
        composeTestRule
            .onNodeWithText("Next: Set Search Radius")
            .assertIsNotEnabled()
    }

    @Test
    fun testEmptyCategorySelection() {
        composeTestRule.setContent {
            CategoryStep(
                userPreferences = UserPreferences(),
                onNext = {},
                onBack = {}
            )
        }

        // Clear all categories
        composeTestRule
            .onNodeWithText("Clear")
            .performClick()

        // Verify count shows 0
        composeTestRule
            .onNodeWithText("0 categories selected")
            .assertIsDisplayed()

        // Next button should be disabled
        composeTestRule
            .onNodeWithText("Review Settings")
            .assertIsNotEnabled()
    }

    // MARK: - Helper Methods

    private fun navigateToRadiusStep() {
        selectDestinationForTesting()

        composeTestRule
            .onNodeWithText("Next: Set Search Radius")
            .performClick()

        composeTestRule
            .onNodeWithText("Set your search radius")
            .assertIsDisplayed()
    }

    private fun navigateToCategoryStep() {
        navigateToRadiusStep()

        composeTestRule
            .onNodeWithText("Next: Choose Interests")
            .performClick()

        composeTestRule
            .onNodeWithText("Choose your interests")
            .assertIsDisplayed()
    }

    private fun navigateToConfirmationStep() {
        navigateToCategoryStep()

        selectCategoriesForTesting()

        composeTestRule
            .onNodeWithText("Review Settings")
            .performClick()

        composeTestRule
            .onNodeWithText("Ready for your roadtrip?")
            .assertIsDisplayed()
    }

    private fun selectDestinationForTesting() {
        composeTestRule
            .onNodeWithText("Search for destination...")
            .performTextInput("Test City")

        // Simulate destination selection
        composeTestRule
            .onNodeWithTag("destination_selection")
            .performClick()
    }

    private fun selectCategoriesForTesting() {
        // Select a few categories
        composeTestRule
            .onNodeWithTag("category_restaurants")
            .performClick()

        composeTestRule
            .onNodeWithTag("category_parks")
            .performClick()
    }
}

// MARK: - Custom Matchers

private fun hasMinimumTouchTargetSize() = SemanticsMatcher("has minimum touch target size") { node ->
    val size = node.layoutInfo.size
    size.width >= 48.dp.value && size.height >= 48.dp.value
}

// MARK: - Test Data Classes

enum class OnboardingStep {
    DESTINATION,
    RADIUS,
    CATEGORIES,
    CONFIRMATION
}

data class UserPreferences(
    var searchRadius: Double = 5.0,
    var distanceUnit: DistanceUnit = DistanceUnit.MILES,
    var selectedCategories: Set<POICategory> = emptySet()
)

enum class DistanceUnit {
    MILES, KILOMETERS
}

enum class POICategory {
    RESTAURANTS, PARKS, ATTRACTIONS, GAS_STATIONS, LODGING,
    SHOPPING, MUSEUMS, ENTERTAINMENT, BEACHES, VIEWPOINTS,
    HISTORIC_SITES, WINERIES
}