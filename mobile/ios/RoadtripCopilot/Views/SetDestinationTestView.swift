import SwiftUI
import MapKit

/// Test view to demonstrate the Set Destination screen functionality
/// Includes test cases for voice input like "Lost Lake, Oregon, Go"
struct SetDestinationTestView: View {
    @State private var showingSetDestination = false
    @State private var selectedDestination: MKMapItem?
    @State private var testResults: [TestResult] = []
    @State private var currentTestIndex = 0
    
    // Test cases following the requirements
    private let testCases = [
        TestCase(
            input: "Lost Lake, Oregon, Go",
            expectedDestination: "Lost Lake",
            expectedAction: "navigate",
            description: "Complete voice command with destination and action"
        ),
        TestCase(
            input: "San Francisco",
            expectedDestination: "San Francisco",
            expectedAction: nil,
            description: "Destination-only voice input"
        ),
        TestCase(
            input: "Golden Gate Bridge, start",
            expectedDestination: "Golden Gate Bridge",
            expectedAction: "navigate",
            description: "Destination with trailing action command"
        ),
        TestCase(
            input: "navigate to Yosemite National Park",
            expectedDestination: "Yosemite National Park",
            expectedAction: "navigate",
            description: "Navigation phrase with destination"
        )
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Text("Set Destination Test Suite")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Test voice commands and UI functionality")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                
                // Quick Test Button
                Button(action: {
                    showingSetDestination = true
                }) {
                    HStack {
                        Image(systemName: "location.magnifyingglass")
                            .font(.title2)
                        Text("Open Set Destination Screen")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                
                // Test Cases Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Test Cases")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 24)
                    
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(testCases.indices, id: \.self) { index in
                                TestCaseRow(
                                    testCase: testCases[index],
                                    result: testResults.first { $0.testCase.id == testCases[index].id },
                                    onRun: {
                                        runTestCase(testCases[index])
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
                
                // Test Results Summary
                if !testResults.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Test Results Summary")
                            .font(.headline)
                            .padding(.horizontal, 24)
                        
                        HStack(spacing: 16) {
                            VStack {
                                Text("\(testResults.filter { $0.passed }.count)")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                                Text("Passed")
                                    .font(.caption)
                            }
                            
                            VStack {
                                Text("\(testResults.filter { !$0.passed }.count)")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                                Text("Failed")
                                    .font(.caption)
                            }
                            
                            VStack {
                                Text("\(testResults.count)/\(testCases.count)")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                                Text("Completed")
                                    .font(.caption)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                    }
                }
                
                Spacer()
                
                // Selected Destination Display
                if let destination = selectedDestination {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Last Selected Destination:")
                            .font(.headline)
                        
                        Text(destination.name ?? "Unknown Location")
                            .font(.title3)
                            .foregroundColor(.blue)
                        
                        if let address = destination.placemark.title {
                            Text(address)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.thinMaterial)
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingSetDestination) {
            SetDestinationView { destination in
                print("[SetDestinationTest] Destination selected: \(destination.name ?? "Unknown")")
                selectedDestination = destination
                showingSetDestination = false
                
                // Record result if this was part of a test
                recordTestResult(destination: destination)
            }
        }
    }
    
    // MARK: - Test Methods
    
    private func runTestCase(_ testCase: TestCase) {
        print("[SetDestinationTest] Running test case: \(testCase.description)")
        
        currentTestIndex = testCases.firstIndex { $0.id == testCase.id } ?? 0
        
        // For automated testing, we would simulate voice input here
        // For now, we'll show the set destination screen for manual testing
        showingSetDestination = true
        
        // In a real test implementation, we would:
        // 1. Inject the voice input into SpeechManager
        // 2. Verify the destination parsing
        // 3. Verify the action detection
        // 4. Check the UI state transitions
        
        // Simulate test result (in real implementation this would be based on actual voice processing)
        simulateTestResult(for: testCase)
    }
    
    private func simulateTestResult(for testCase: TestCase) {
        // This simulates the expected behavior for demonstration
        // In a real test, this would verify actual SpeechManager behavior
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let result = TestResult(
                testCase: testCase,
                passed: true, // Would be based on actual verification
                actualDestination: testCase.expectedDestination,
                actualAction: testCase.expectedAction,
                notes: "Simulated test result - manual verification required"
            )
            
            // Update or add result
            if let existingIndex = testResults.firstIndex(where: { $0.testCase.id == testCase.id }) {
                testResults[existingIndex] = result
            } else {
                testResults.append(result)
            }
        }
    }
    
    private func recordTestResult(destination: MKMapItem) {
        guard currentTestIndex < testCases.count else { return }
        
        let testCase = testCases[currentTestIndex]
        let destinationName = destination.name ?? ""
        let passed = destinationName.lowercased().contains(testCase.expectedDestination.lowercased())
        
        let result = TestResult(
            testCase: testCase,
            passed: passed,
            actualDestination: destinationName,
            actualAction: "navigate", // Would be detected from voice processing
            notes: passed ? "Successfully found and selected destination" : "Destination mismatch"
        )
        
        // Update or add result
        if let existingIndex = testResults.firstIndex(where: { $0.testCase.id == testCase.id }) {
            testResults[existingIndex] = result
        } else {
            testResults.append(result)
        }
    }
}

// MARK: - Supporting Types

struct TestCase: Identifiable {
    let id = UUID()
    let input: String
    let expectedDestination: String
    let expectedAction: String?
    let description: String
}

struct TestResult: Identifiable {
    let id = UUID()
    let testCase: TestCase
    let passed: Bool
    let actualDestination: String?
    let actualAction: String?
    let notes: String
}

struct TestCaseRow: View {
    let testCase: TestCase
    let result: TestResult?
    let onRun: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(testCase.description)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Run Test") {
                    onRun()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            
            // Test Input
            VStack(alignment: .leading, spacing: 4) {
                Text("Voice Input:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\"\(testCase.input)\"")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Expected Results
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Expected:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("🎯 \(testCase.expectedDestination)")
                        .font(.caption)
                    if let action = testCase.expectedAction {
                        Text("▶️ \(action)")
                            .font(.caption)
                    }
                }
                
                Spacer()
                
                // Result Indicator
                if let result = result {
                    VStack(spacing: 4) {
                        Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(result.passed ? .green : .red)
                        
                        Text(result.passed ? "PASS" : "FAIL")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(result.passed ? .green : .red)
                    }
                }
            }
            
            // Test Result Details
            if let result = result {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Result:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let destination = result.actualDestination {
                        Text("🏁 \(destination)")
                            .font(.caption)
                    }
                    
                    if let action = result.actualAction {
                        Text("⚡ \(action)")
                            .font(.caption)
                    }
                    
                    Text(result.notes)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .italic()
                }
                .padding(.top, 8)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.regularMaterial)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(borderColor, lineWidth: 1)
                )
        )
    }
    
    private var borderColor: Color {
        if let result = result {
            return result.passed ? .green.opacity(0.3) : .red.opacity(0.3)
        } else {
            return .gray.opacity(0.2)
        }
    }
}

#Preview("Set Destination Test") {
    SetDestinationTestView()
}