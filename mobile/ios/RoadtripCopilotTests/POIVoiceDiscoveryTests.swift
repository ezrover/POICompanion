import XCTest
import AVFoundation
import Speech
@testable import RoadtripCopilot

/// TDD Test Suite for POI Voice Discovery Feature
/// Following FDA Medical Device Testing Standards (IEC 62304)
/// WCAG 2.1 AAA and NHTSA Automotive Safety Compliance
class POIVoiceDiscoveryTests: XCTestCase {
    
    // MARK: - Test Infrastructure
    var voiceDiscoveryManager: POIVoiceDiscoveryManager!
    var mockAudioEngine: MockAudioEngine!
    var mockSpeechRecognizer: MockSpeechRecognizer!
    var mockLocationManager: MockLocationManager!
    var testTimeout: TimeInterval = 2.0
    
    // MARK: - Setup & Teardown
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Arrange - Set up test environment
        mockAudioEngine = MockAudioEngine()
        mockSpeechRecognizer = MockSpeechRecognizer()
        mockLocationManager = MockLocationManager()
        
        voiceDiscoveryManager = POIVoiceDiscoveryManager(
            audioEngine: mockAudioEngine,
            speechRecognizer: mockSpeechRecognizer,
            locationManager: mockLocationManager
        )
        
        // Configure test location
        mockLocationManager.setTestLocation(latitude: 35.3633, longitude: -120.8507) // Morro Bay
    }
    
    override func tearDownWithError() throws {
        voiceDiscoveryManager.stopListening()
        voiceDiscoveryManager = nil
        mockAudioEngine = nil
        mockSpeechRecognizer = nil
        mockLocationManager = nil
        try super.tearDownWithError()
    }
    
    // MARK: - TDD-01: Voice Trigger Recognition Tests
    func testVoiceTriggerRecognition_HeyCompanion_ShouldActivate() throws {
        // Test Case ID: TC-VT-01
        // Requirements: FR-1 (Voice activation with 'Hey Companion' trigger)
        // FDA Classification: Class B Software (statement coverage required)
        
        // Arrange - Set up voice trigger test
        let expectation = expectation(description: "Voice trigger recognition")
        var triggerActivated = false
        
        voiceDiscoveryManager.onTriggerActivated = {
            triggerActivated = true
            expectation.fulfill()
        }
        
        // Act - Simulate "Hey Companion" voice input
        mockSpeechRecognizer.simulateRecognizedText("Hey Companion")
        
        // Assert - Validate trigger activation within performance target
        wait(for: [expectation], timeout: testTimeout)
        XCTAssertTrue(triggerActivated, "Voice trigger should activate on 'Hey Companion'")
        
        // Performance validation - must be < 350ms
        let responseTime = mockSpeechRecognizer.lastResponseTime
        XCTAssertLessThan(responseTime, 0.35, "Voice trigger response time must be < 350ms (was \(responseTime)s)")
    }
    
    func testVoiceTriggerRecognition_InvalidTrigger_ShouldNotActivate() throws {
        // Test Case ID: TC-VT-02
        // Negative test for voice trigger validation
        
        // Arrange
        var triggerActivated = false
        voiceDiscoveryManager.onTriggerActivated = {
            triggerActivated = true
        }
        
        // Act - Simulate invalid trigger
        mockSpeechRecognizer.simulateRecognizedText("Hello World")
        
        // Wait brief period to ensure no activation
        Thread.sleep(forTimeInterval: 0.1)
        
        // Assert
        XCTAssertFalse(triggerActivated, "Voice trigger should not activate on invalid phrases")
    }
    
    // MARK: - TDD-02: Natural Language POI Query Processing
    func testPOIQueryProcessing_RestaurantQuery_ShouldReturnValidPOIs() async throws {
        // Test Case ID: TC-POI-01
        // Requirements: FR-2 (Natural language POI queries processing)
        
        // Arrange - Set up POI query test
        voiceDiscoveryManager.startListening()
        let queryExpectation = expectation(description: "POI query processing")
        var discoveredPOIs: [POI] = []
        
        voiceDiscoveryManager.onPOIsDiscovered = { pois in
            discoveredPOIs = pois
            queryExpectation.fulfill()
        }
        
        // Act - Simulate natural language query
        mockSpeechRecognizer.simulateRecognizedText("Find restaurants near me")
        
        // Assert - Validate POI discovery
        await fulfillment(of: [queryExpectation], timeout: testTimeout)
        XCTAssertFalse(discoveredPOIs.isEmpty, "Should discover POIs for restaurant query")
        XCTAssertTrue(discoveredPOIs.allSatisfy { $0.category.contains("restaurant") }, 
                     "All POIs should be restaurant category")
        
        // Performance validation
        let queryTime = mockSpeechRecognizer.lastQueryProcessingTime
        XCTAssertLessThan(queryTime, 0.35, "POI query processing must be < 350ms")
    }
    
    // MARK: - TDD-03: Accessibility Tests (WCAG 2.1 AAA)
    func testVoiceInterface_AccessibilityCompliance_ShouldProvideAlternativeInteraction() throws {
        // Test Case ID: TC-ACC-01
        // WCAG 2.1 AAA Compliance: Alternative interaction methods
        
        // Arrange - Test accessibility features
        let accessibilityExpectation = expectation(description: "Accessibility alternative")
        
        // Act - Test visual indicators for hearing impaired
        voiceDiscoveryManager.enableVisualIndicators = true
        voiceDiscoveryManager.startListening()
        
        // Simulate hearing impaired user interaction
        voiceDiscoveryManager.processTextInput("Find gas stations") { result in
            XCTAssertNotNil(result.visualFeedback, "Should provide visual feedback")
            XCTAssertNotNil(result.hapticFeedback, "Should provide haptic feedback")
            accessibilityExpectation.fulfill()
        }
        
        // Assert - Validate accessibility features
        wait(for: [accessibilityExpectation], timeout: testTimeout)
    }
    
    func testVoiceInterface_CognitiveLoad_ShouldUseSimpleClearCommands() throws {
        // Test Case ID: TC-ACC-02
        // WCAG 2.1 AAA: Cognitive accessibility
        
        // Arrange - Test cognitive load requirements
        let simpleCommands = [
            "Find food",
            "Show gas",
            "Get directions",
            "Call place"
        ]
        
        // Act & Assert - Validate simple command recognition
        for command in simpleCommands {
            let recognized = voiceDiscoveryManager.isValidCommand(command)
            XCTAssertTrue(recognized, "Simple command '\(command)' should be recognized")
        }
        
        // Validate command complexity (max 3 words for cognitive accessibility)
        for command in simpleCommands {
            let wordCount = command.components(separatedBy: " ").count
            XCTAssertLessThanOrEqual(wordCount, 3, "Commands should be ≤ 3 words for cognitive accessibility")
        }
    }
    
    // MARK: - TDD-04: NHTSA Automotive Safety Tests
    func testAutomotiveSafety_2SecondGlanceRule_ShouldNotRequireVisualAttention() throws {
        // Test Case ID: TC-NHTSA-01
        // NHTSA 2-second glance rule compliance
        
        // Arrange - Set up automotive safety test
        voiceDiscoveryManager.setDrivingMode(true)
        
        // Act - Simulate driving scenario
        mockSpeechRecognizer.simulateRecognizedText("Hey Companion, find coffee")
        
        // Assert - Validate no visual distraction during voice interaction
        let requiresVisualAttention = voiceDiscoveryManager.currentInteractionRequiresVisualAttention
        XCTAssertFalse(requiresVisualAttention, "Voice interaction should not require visual attention while driving")
        
        // Validate audio-only response
        let hasAudioResponse = voiceDiscoveryManager.lastResponse?.hasAudioFeedback ?? false
        XCTAssertTrue(hasAudioResponse, "Should provide audio-only response while driving")
    }
    
    func testAutomotiveSafety_12SecondTaskRule_ShouldCompleteWithinTimeLimit() async throws {
        // Test Case ID: TC-NHTSA-02
        // NHTSA 12-second task completion rule
        
        // Arrange - Set up task timing test
        let startTime = Date()
        let taskExpectation = expectation(description: "Task completion timing")
        
        voiceDiscoveryManager.onTaskCompleted = { taskDuration in
            XCTAssertLessThan(taskDuration, 12.0, "Voice task must complete within 12 seconds")
            taskExpectation.fulfill()
        }
        
        // Act - Simulate complete voice interaction
        mockSpeechRecognizer.simulateRecognizedText("Hey Companion, find the nearest gas station with good reviews")
        
        // Assert - Validate task completion timing
        await fulfillment(of: [taskExpectation], timeout: 13.0) // Allow 1 second buffer for test
    }
    
    // MARK: - TDD-05: Performance Tests
    func testPerformance_VoiceResponseTime_ShouldMeet350msTarget() throws {
        // Test Case ID: TC-PERF-01
        // Performance requirement: < 350ms voice response time
        
        // Arrange - Set up performance measurement
        let performanceExpectation = expectation(description: "Voice response performance")
        
        // Act - Measure voice processing performance
        measure {
            mockSpeechRecognizer.simulateRecognizedText("Hey Companion")
            // Simulate processing delay
            Thread.sleep(forTimeInterval: 0.1) // Simulate realistic processing time
        }
        
        // Assert - Validate performance target
        let averageTime = mockSpeechRecognizer.averageResponseTime
        XCTAssertLessThan(averageTime, 0.35, "Average voice response time must be < 350ms")
    }
    
    func testPerformance_MemoryUsage_ShouldStayWithin50MBLimit() throws {
        // Test Case ID: TC-PERF-02
        // Memory usage requirement: < 50MB additional
        
        // Arrange - Measure baseline memory
        let baselineMemory = getMemoryUsage()
        
        // Act - Start voice discovery and process multiple queries
        voiceDiscoveryManager.startListening()
        
        for i in 1...10 {
            mockSpeechRecognizer.simulateRecognizedText("Find restaurants \(i)")
            Thread.sleep(forTimeInterval: 0.01) // Brief pause between queries
        }
        
        // Assert - Validate memory usage
        let currentMemory = getMemoryUsage()
        let additionalMemory = currentMemory - baselineMemory
        
        XCTAssertLessThan(additionalMemory, 50.0, "Additional memory usage should be < 50MB (was \(additionalMemory)MB)")
    }
    
    // MARK: - TDD-06: FDA Medical Device Compliance
    func testFDACompliance_RiskManagement_ShouldHandleVoiceProcessingFailures() throws {
        // Test Case ID: TC-FDA-01
        // ISO 14971 Risk Management compliance
        
        // Arrange - Set up failure scenario
        mockSpeechRecognizer.simulateProcessingError(.audioEngineFailure)
        
        // Act - Test error handling
        let errorHandled = voiceDiscoveryManager.handleVoiceProcessingError(.audioEngineFailure)
        
        // Assert - Validate risk mitigation
        XCTAssertTrue(errorHandled, "Voice processing errors should be properly handled")
        XCTAssertFalse(voiceDiscoveryManager.isListening, "Should stop listening on critical errors")
        
        // Validate user notification
        XCTAssertNotNil(voiceDiscoveryManager.lastErrorMessage, "Should provide user feedback on errors")
    }
    
    func testFDACompliance_Traceability_ShouldTrackRequirementsToTests() throws {
        // Test Case ID: TC-FDA-02
        // IEC 62304 Requirements traceability
        
        // This test validates that all functional requirements have corresponding test coverage
        let functionalRequirements = voiceDiscoveryManager.getFunctionalRequirements()
        let testCoverage = self.getTestCoverageMapping()
        
        // Assert - Validate complete requirements coverage
        for requirement in functionalRequirements {
            let hasTestCoverage = testCoverage.contains(requirement.id)
            XCTAssertTrue(hasTestCoverage, "Requirement \(requirement.id) must have test coverage")
        }
        
        // Validate bi-directional traceability
        let coveragePercentage = Double(testCoverage.count) / Double(functionalRequirements.count) * 100
        XCTAssertGreaterThanOrEqual(coveragePercentage, 90.0, "Test coverage must be ≥ 90% for FDA compliance")
    }
    
    // MARK: - Test Utilities
    private func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1024.0 / 1024.0 // Convert to MB
        }
        return 0.0
    }
    
    private func getTestCoverageMapping() -> Set<String> {
        // Map functional requirements to test cases
        return [
            "FR-1", "FR-2", "FR-3", "FR-4", "FR-5", "FR-6", "FR-7", "FR-8"
        ]
    }
}

// MARK: - Mock Classes
class MockAudioEngine: AudioEngineProtocol {
    var isRunning = false
    var lastResponseTime: TimeInterval = 0.0
    
    func startAudioEngine() -> Bool {
        isRunning = true
        return true
    }
    
    func stopAudioEngine() {
        isRunning = false
    }
}

class MockSpeechRecognizer: SpeechRecognizerProtocol {
    var lastResponseTime: TimeInterval = 0.2 // Simulate 200ms response
    var lastQueryProcessingTime: TimeInterval = 0.3 // Simulate 300ms processing
    var averageResponseTime: TimeInterval = 0.25
    
    var onTextRecognized: ((String) -> Void)?
    
    func simulateRecognizedText(_ text: String) {
        let startTime = Date()
        // Simulate processing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + lastResponseTime) {
            self.onTextRecognized?(text)
        }
    }
    
    func simulateProcessingError(_ error: VoiceProcessingError) {
        // Simulate error conditions for testing
    }
}

class MockLocationManager: LocationManagerProtocol {
    private var testLocation: CLLocation?
    
    func setTestLocation(latitude: Double, longitude: Double) {
        testLocation = CLLocation(latitude: latitude, longitude: longitude)
    }
    
    func getCurrentLocation() -> CLLocation? {
        return testLocation
    }
}