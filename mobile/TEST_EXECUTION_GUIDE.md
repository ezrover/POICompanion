# Roadtrip-Copilot Mobile Testing Execution Guide

## Overview

This guide provides step-by-step instructions for executing the comprehensive test suite for Roadtrip-Copilot mobile applications on both iOS and Android platforms.

## Prerequisites

### iOS Testing Requirements
- **Xcode 14+** with iOS 14+ Simulator
- **macOS 12+** (Monterey or later)
- **Command Line Tools** installed
- **iOS Simulator** configured for testing
- **Voice Control** and **VoiceOver** enabled for accessibility testing

### Android Testing Requirements
- **Android Studio Arctic Fox** or later
- **Android SDK 28+** (API level 28+)
- **Android Emulator** or physical device
- **TalkBack** and accessibility services configured
- **Gradle 7.0+** for build system

## Test Structure

```
mobile/
├── mobile/ios/RoadtripCopilotTests/
│   ├── Unit/                    # Unit tests for managers and models
│   ├── UI/                      # User interface and flow tests  
│   ├── Integration/             # Cross-component integration tests
│   ├── Performance/             # Performance and response time tests
│   └── Accessibility/           # Accessibility and inclusive design tests
└── android/app/src/
    ├── test/                    # Android unit tests (JUnit)
    └── androidTest/             # Android instrumentation tests (Espresso)
```

## Running Tests

### iOS Test Execution

#### 1. Command Line Execution
```bash
# Navigate to iOS project directory
cd /path/to/project/mobile/ios

# Run all tests
xcodebuild test -scheme RoadtripCopilot -destination 'platform=iOS Simulator,name=iPhone 14 Pro'

# Run specific test suite
xcodebuild test -scheme RoadtripCopilot -destination 'platform=iOS Simulator,name=iPhone 14 Pro' -only-testing:RoadtripCopilotTests/SpeechManagerTests

# Run UI tests only
xcodebuild test -scheme RoadtripCopilot -destination 'platform=iOS Simulator,name=iPhone 14 Pro' -only-testing:RoadtripCopilotTests/OnboardingFlowUITests
```

#### 2. Xcode IDE Execution
1. Open `RoadtripCopilot.xcodeproj` in Xcode
2. Select **Product > Test** (⌘+U)
3. View results in the **Test Navigator**
4. For specific tests: Right-click test class → **Run Tests**

#### 3. Performance Testing
```bash
# Run performance tests with profiling
xcodebuild test -scheme RoadtripCopilot -destination 'platform=iOS Simulator,name=iPhone 14 Pro' -only-testing:RoadtripCopilotTests/VoicePerformanceTests -resultBundlePath TestResults.xcresult

# Analyze results
xcrun xccov view --report TestResults.xcresult
```

### Android Test Execution

#### 1. Command Line Execution
```bash
# Navigate to Android project directory
cd /path/to/project/mobile/android

# Run unit tests
./gradlew test

# Run instrumentation tests (requires emulator/device)
./gradlew connectedAndroidTest

# Run specific test class
./gradlew test --tests SpeechManagerTest

# Run UI tests
./gradlew connectedAndroidTest --tests OnboardingFlowTest
```

#### 2. Android Studio IDE Execution
1. Open project in Android Studio
2. Navigate to test files in **Project Explorer**
3. Right-click test class → **Run Tests**
4. View results in **Run** window
5. For coverage: **Run with Coverage**

#### 3. Performance Testing
```bash
# Run performance tests with profiling
./gradlew connectedAndroidTest --tests VoicePerformanceTest -Pandroid.testInstrumentationRunnerArguments.class=com.roadtrip.copilot.VoicePerformanceTest
```

## Test Categories and Execution Priority

### 1. Core Functionality Tests (Priority: High)
Execute these tests first to ensure basic functionality works:

```bash
# iOS
xcodebuild test -only-testing:RoadtripCopilotTests/SpeechManagerTests
xcodebuild test -only-testing:RoadtripCopilotTests/LocationManagerTests  
xcodebuild test -only-testing:RoadtripCopilotTests/UserPreferencesTests

# Android
./gradlew test --tests SpeechManagerTest
./gradlew connectedAndroidTest --tests OnboardingFlowTest
```

**Expected Results:**
- ✅ All 7 voice commands recognized correctly
- ✅ Speech synthesis starts within 200ms
- ✅ User preferences save/load properly
- ✅ Location services initialize correctly

### 2. Voice Command Integration Tests (Priority: High)
Test the complete voice command flow:

```bash
# iOS
xcodebuild test -only-testing:RoadtripCopilotTests/VoiceCommandIntegrationTests

# Android
./gradlew connectedAndroidTest --tests VoiceCommandIntegrationTest
```

**Expected Results:**
- ✅ Voice commands trigger appropriate actions within 350ms
- ✅ Button animations sync with voice recognition
- ✅ Audio feedback plays correctly
- ✅ All command alternatives work properly

### 3. Performance Tests (Priority: High)
Validate automotive response time requirements:

```bash
# iOS
xcodebuild test -only-testing:RoadtripCopilotTests/VoicePerformanceTests

# Android  
./gradlew connectedAndroidTest --tests VoicePerformanceTest
```

**Performance Benchmarks:**
- ✅ Voice command processing: < 350ms
- ✅ TTS startup: < 200ms
- ✅ Button animations: < 100ms
- ✅ Memory usage: < 150MB baseline
- ✅ Battery impact: < 5% per hour

### 4. UI/UX Flow Tests (Priority: Medium)
Test complete user journeys:

```bash
# iOS
xcodebuild test -only-testing:RoadtripCopilotTests/OnboardingFlowUITests

# Android
./gradlew connectedAndroidTest --tests OnboardingFlowTest
```

**Expected Results:**
- ✅ 4-step onboarding completes successfully
- ✅ Navigation works forward and backward
- ✅ Form validation prevents invalid submissions
- ✅ Voice inputs work on all steps

### 5. Accessibility Tests (Priority: Medium)
Ensure inclusive design compliance:

```bash
# iOS (with VoiceOver enabled)
xcodebuild test -only-testing:RoadtripCopilotTests/AccessibilityTests

# Android (with TalkBack enabled)  
./gradlew connectedAndroidTest --tests AccessibilityTest
```

**Expected Results:**
- ✅ All interactive elements have minimum 44pt/48dp touch targets
- ✅ VoiceOver/TalkBack navigation works correctly
- ✅ Content descriptions are meaningful
- ✅ High contrast mode supported
- ✅ Dynamic type scaling works up to 200%

## Continuous Integration Setup

### GitHub Actions Workflow
Create `.github/workflows/mobile-tests.yml`:

```yaml
name: Mobile App Tests

on:
  push:
    paths: ['mobile/**']
  pull_request:
    paths: ['mobile/**']

jobs:
  ios-tests:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: latest-stable
      - name: Run iOS Tests
        run: |
          cd mobile/ios
          xcodebuild test -scheme RoadtripCopilot -destination 'platform=iOS Simulator,name=iPhone 14 Pro' -resultBundlePath TestResults.xcresult
      - name: Upload Test Results
        uses: actions/upload-artifact@v3
        with:
          name: ios-test-results
          path: mobile/ios/TestResults.xcresult

  android-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Java
        uses: actions/setup-java@v3
        with:
          java-version: '11'
          distribution: 'temurin'
      - name: Setup Android SDK
        uses: android-actions/setup-android@v2
      - name: Run Android Tests
        run: |
          cd mobile/android
          ./gradlew test
          ./gradlew connectedAndroidTest
```

### Local Pre-commit Hooks
Create `.pre-commit-config.yaml`:

```yaml
repos:
  - repo: local
    hooks:
      - id: ios-unit-tests
        name: iOS Unit Tests
        entry: bash -c 'cd mobile/ios && xcodebuild test -scheme RoadtripCopilot -destination "platform=iOS Simulator,name=iPhone 14 Pro" -only-testing:RoadtripCopilotTests/SpeechManagerTests'
        language: system
        files: mobile/ios/.*\.swift$
        
      - id: android-unit-tests
        name: Android Unit Tests
        entry: bash -c 'cd mobile/android && ./gradlew test'
        language: system
        files: mobile/android/.*\.kt$
```

## Test Data and Mock Setup

### Voice Command Test Data
```swift
// iOS Test Data
let testVoiceCommands = [
    ("save this amazing restaurant", "save"),
    ("I love this place", "like"), 
    ("skip this location", "dislike"),
    ("next point of interest", "next"),
    ("go back to previous", "previous"),
    ("get directions here", "navigate"),
    ("call this business", "call")
]
```

### Performance Test Configuration
```kotlin
// Android Performance Config
data class PerformanceConfig(
    val maxVoiceProcessingTime: Long = 350, // milliseconds
    val maxTTSStartTime: Long = 200,
    val maxButtonResponseTime: Long = 100,
    val maxMemoryUsage: Long = 150 * 1024 * 1024 // 150MB
)
```

## Troubleshooting Common Issues

### iOS Testing Issues

#### 1. Simulator Voice Recognition Not Working
```bash
# Enable Dictation in Simulator
# Settings → General → Keyboard → Enable Dictation
# Hardware → Audio Input → Default System Audio Input
```

#### 2. Permission Dialogs Blocking Tests
```swift
// Add to setUp() method
app.resetAuthorizationStatus(for: .microphone)
app.resetAuthorizationStatus(for: .speechRecognition)
```

#### 3. Memory Leaks in Performance Tests
```swift
// Wrap tests in autoreleasepool
func testMemoryUsage() {
    autoreleasepool {
        // Test code here
    }
}
```

### Android Testing Issues

#### 1. Emulator Audio Not Working
```bash
# Start emulator with audio support
emulator -avd TestDevice -audio-out on -audio-in on
```

#### 2. Permission Handling in Tests
```kotlin
// Grant permissions before test
@Before
fun grantPermissions() {
    InstrumentationRegistry.getInstrumentation().uiAutomation.executeShellCommand(
        "pm grant ${context.packageName} android.permission.RECORD_AUDIO"
    )
}
```

#### 3. Test Flakiness Due to Timing
```kotlin
// Use IdlingResource for async operations
@get:Rule
val idlingResourceRule = IdlingResourceRule()

@Test
fun testAsyncOperation() {
    // Register idling resource
    IdlingRegistry.getInstance().register(speechManagerIdlingResource)
    
    // Perform test
    composeTestRule.onNodeWithTag("voice_button").performClick()
    
    // Unregister
    IdlingRegistry.getInstance().unregister(speechManagerIdlingResource)
}
```

## Test Reporting and Analysis

### Code Coverage Reports

#### iOS Coverage
```bash
# Generate coverage report
xcodebuild test -scheme RoadtripCopilot -destination 'platform=iOS Simulator,name=iPhone 14 Pro' -enableCodeCoverage YES -resultBundlePath TestResults.xcresult

# View coverage
xcrun xccov view --report TestResults.xcresult
```

#### Android Coverage  
```bash
# Generate coverage report
./gradlew createDebugCoverageReport

# View report
open app/build/reports/coverage/debug/index.html
```

### Performance Analysis

#### iOS Instruments Integration
```bash
# Profile performance tests
xcrun xctrace record --template 'Time Profiler' --launch -- xcodebuild test -scheme RoadtripCopilot -only-testing:RoadtripCopilotTests/VoicePerformanceTests
```

#### Android Profiling
```bash
# Profile with systrace
python systrace.py -t 10 -o myapp.html -a com.roadtrip.copilot
```

## Success Criteria

### Test Pass Requirements
- **Unit Tests**: 95% pass rate minimum
- **Integration Tests**: 90% pass rate minimum  
- **Performance Tests**: All benchmarks met
- **Accessibility Tests**: 100% pass rate required
- **Code Coverage**: 85% minimum across core functionality

### Performance Benchmarks
- Voice command processing: < 350ms (95th percentile)
- TTS startup: < 200ms average
- Memory usage: < 150MB baseline
- UI responsiveness: 60 FPS maintained
- Battery impact: < 5% per hour of active use

### Accessibility Compliance
- WCAG 2.1 AA compliance
- VoiceOver/TalkBack full compatibility
- Minimum touch targets: 44pt (iOS) / 48dp (Android)
- Voice Control support
- High contrast and dynamic type support

This comprehensive test execution guide ensures the Roadtrip-Copilot mobile applications meet the highest standards for automotive voice-first interfaces while maintaining accessibility and performance requirements.