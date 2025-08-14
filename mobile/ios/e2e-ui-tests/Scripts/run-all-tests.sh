#!/bin/bash

# iOS E2E UI Tests - Complete Test Suite Runner
# This script runs all E2E tests and generates comprehensive reports

set -e

echo "🚀 Starting iOS E2E UI Test Suite"
echo "================================="

# Configuration
PROJECT_PATH="../RoadtripCopilot.xcodeproj"
SCHEME="RoadtripCopilot"
DEVICE="platform=iOS Simulator,name=iPhone 16 Pro"
TEST_TARGET="E2EUITests"
RESULTS_PATH="./TestResults"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_PATH="$RESULTS_PATH/report_$TIMESTAMP"

# Create results directory
mkdir -p "$RESULTS_PATH"
mkdir -p "$REPORT_PATH"

echo "📱 Test Configuration:"
echo "   Project: $PROJECT_PATH"
echo "   Scheme: $SCHEME"
echo "   Device: $DEVICE"
echo "   Results: $REPORT_PATH"
echo ""

# Function to run test and capture results
run_test_suite() {
    local test_name=$1
    local test_class=$2
    
    echo "🧪 Running $test_name..."
    
    xcodebuild test \
        -project "$PROJECT_PATH" \
        -scheme "$SCHEME" \
        -destination "$DEVICE" \
        -only-testing:"$TEST_TARGET/$test_class" \
        -resultBundlePath "$REPORT_PATH/${test_name}_results.xcresult" \
        | tee "$REPORT_PATH/${test_name}_output.log"
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo "✅ $test_name PASSED"
    else
        echo "❌ $test_name FAILED (exit code: $exit_code)"
    fi
    
    echo ""
    return $exit_code
}

# Function to check simulator status
check_simulator() {
    echo "📱 Checking iOS Simulator status..."
    
    # Boot simulator if needed
    xcrun simctl boot "iPhone 16 Pro" 2>/dev/null || true
    
    # Wait for simulator to be ready
    sleep 5
    
    local booted_device=$(xcrun simctl list devices booted | grep "iPhone 16 Pro" | head -1)
    
    if [ -n "$booted_device" ]; then
        echo "✅ iPhone 16 Pro simulator is ready"
    else
        echo "❌ Failed to boot iPhone 16 Pro simulator"
        exit 1
    fi
    
    echo ""
}

# Function to build app for testing
build_for_testing() {
    echo "🔨 Building app for testing..."
    
    xcodebuild build-for-testing \
        -project "$PROJECT_PATH" \
        -scheme "$SCHEME" \
        -destination "$DEVICE" \
        | tee "$REPORT_PATH/build_output.log"
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo "✅ Build successful"
    else
        echo "❌ Build failed (exit code: $exit_code)"
        exit 1
    fi
    
    echo ""
}

# Test execution functions
run_critical_tests() {
    echo "🎯 CRITICAL PATH TESTS"
    echo "====================="
    
    run_test_suite "Critical_Path" "E2ETestRunner/testCriticalPath_LostLakeOregonFlow"
    local critical_result=$?
    
    run_test_suite "Platform_Parity" "E2ETestRunner/testPlatformParity_iOSCarPlaySync"
    local parity_result=$?
    
    return $((critical_result + parity_result))
}

run_accessibility_tests() {
    echo "♿ ACCESSIBILITY TESTS"
    echo "===================="
    
    run_test_suite "Accessibility_Compliance" "E2ETestRunner/testAccessibilityCompliance_AllScreens"
    return $?
}

run_performance_tests() {
    echo "⚡ PERFORMANCE TESTS"
    echo "=================="
    
    run_test_suite "Launch_Performance" "E2ETestRunner/testPerformance_AppLaunchTime"
    local launch_result=$?
    
    run_test_suite "POI_Performance" "E2ETestRunner/testPerformance_POILoadTime"
    local poi_result=$?
    
    return $((launch_result + poi_result))
}

run_error_recovery_tests() {
    echo "🔄 ERROR RECOVERY TESTS"
    echo "======================"
    
    run_test_suite "Network_Failure" "E2ETestRunner/testErrorRecovery_NetworkFailure"
    local network_result=$?
    
    run_test_suite "Invalid_Input" "E2ETestRunner/testErrorRecovery_InvalidDestination"
    local input_result=$?
    
    return $((network_result + input_result))
}

# Generate test report
generate_report() {
    echo "📊 Generating Test Report..."
    
    local report_file="$REPORT_PATH/E2E_Test_Report_$TIMESTAMP.md"
    
    cat > "$report_file" << EOF
# iOS E2E UI Test Report
**Generated**: $(date)
**Device**: iPhone 16 Pro Simulator
**Project**: Roadtrip Copilot iOS

## Test Summary

| Test Suite | Status | Details |
|------------|--------|---------|
| Critical Path | $critical_status | Core user flows |
| Platform Parity | $parity_status | iOS/CarPlay sync |
| Accessibility | $accessibility_status | WCAG compliance |
| Performance | $performance_status | Launch & load times |
| Error Recovery | $error_recovery_status | Failure handling |

## Test Artifacts

### Screenshots
- All test screenshots saved to: \`$REPORT_PATH/\`
- Critical path screenshots: \`*Step_*\`
- Error state screenshots: \`*Error_*\`

### Logs
- Build log: \`build_output.log\`
- Test execution logs: \`*_output.log\`
- Xcode result bundles: \`*.xcresult\`

## Next Steps

EOF

    if [ $total_failures -eq 0 ]; then
        echo "✅ All tests passed - ready for production" >> "$report_file"
    else
        echo "❌ $total_failures test(s) failed - review required" >> "$report_file"
        echo "" >> "$report_file"
        echo "### Failed Tests" >> "$report_file"
        echo "Review individual test logs in the artifacts directory." >> "$report_file"
    fi

    echo "📄 Test report generated: $report_file"
    echo ""
}

# Main execution
main() {
    local start_time=$(date +%s)
    
    # Pre-test setup
    check_simulator
    build_for_testing
    
    # Initialize status variables
    critical_status="❌ FAILED"
    parity_status="❌ FAILED"
    accessibility_status="❌ FAILED"
    performance_status="❌ FAILED"
    error_recovery_status="❌ FAILED"
    
    local total_failures=0
    
    # Run test suites
    if run_critical_tests; then
        critical_status="✅ PASSED"
    else
        ((total_failures++))
    fi
    
    if run_accessibility_tests; then
        accessibility_status="✅ PASSED"
    else
        ((total_failures++))
    fi
    
    if run_performance_tests; then
        performance_status="✅ PASSED"
    else
        ((total_failures++))
    fi
    
    if run_error_recovery_tests; then
        error_recovery_status="✅ PASSED"
    else
        ((total_failures++))
    fi
    
    # Generate final report
    generate_report
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo "🏁 E2E Test Suite Complete"
    echo "========================="
    echo "⏱️  Total Duration: ${duration}s"
    echo "📊 Total Failures: $total_failures"
    echo "📁 Results Path: $REPORT_PATH"
    
    if [ $total_failures -eq 0 ]; then
        echo "🎉 ALL TESTS PASSED! 🎉"
        exit 0
    else
        echo "💥 $total_failures TEST(S) FAILED!"
        exit 1
    fi
}

# Script execution
main "$@"