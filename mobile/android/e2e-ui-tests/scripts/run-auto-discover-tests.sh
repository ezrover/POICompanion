#!/bin/bash

# Auto Discover E2E Test Execution Script for Android
# Comprehensive test runner with performance monitoring and reporting

set -e  # Exit on any error

# Script Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
TEST_RESULTS_DIR="$SCRIPT_DIR/../TestResults"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_DIR="$TEST_RESULTS_DIR/auto_discover_e2e_$TIMESTAMP"

# Test Categories
VALID_CATEGORIES=("core-functionality" "platform-parity" "voice-integration" "accessibility" "performance" "error-handling" "all")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Help function
show_help() {
    cat << EOF
Auto Discover E2E Test Runner for Android

USAGE:
    ./run-auto-discover-tests.sh [OPTIONS]

OPTIONS:
    --category CATEGORY     Run specific test category (default: all)
                           Valid categories: ${VALID_CATEGORIES[*]}
    --device DEVICE        Target device/emulator (default: auto-select)
    --verbose              Enable verbose output
    --no-build             Skip building before testing
    --parallel             Run tests in parallel where possible
    --coverage             Generate code coverage report
    --performance          Enable detailed performance monitoring
    --screenshots          Capture screenshots during test execution
    --emulator             Start emulator if none running
    --help                 Show this help message

EXAMPLES:
    # Run all Auto Discover tests
    ./run-auto-discover-tests.sh

    # Run only core functionality tests
    ./run-auto-discover-tests.sh --category core-functionality

    # Run performance tests with detailed monitoring
    ./run-auto-discover-tests.sh --category performance --performance --verbose

    # Run tests with coverage and screenshots
    ./run-auto-discover-tests.sh --coverage --screenshots --emulator

CATEGORIES:
    core-functionality     Button integration, POI discovery, photo cycling
    platform-parity       Android-specific behavior validation
    voice-integration      Voice commands and audio features
    accessibility          TalkBack compliance and touch targets
    performance           Discovery timing and resource usage
    error-handling        Network failures and permission errors
    all                   Complete test suite (default)

EOF
}

# Parse command line arguments
CATEGORY="all"
DEVICE=""
VERBOSE=false
NO_BUILD=false
PARALLEL=false
COVERAGE=false
PERFORMANCE=false
SCREENSHOTS=false
START_EMULATOR=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --category)
            CATEGORY="$2"
            shift 2
            ;;
        --device)
            DEVICE="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --no-build)
            NO_BUILD=true
            shift
            ;;
        --parallel)
            PARALLEL=true
            shift
            ;;
        --coverage)
            COVERAGE=true
            shift
            ;;
        --performance)
            PERFORMANCE=true
            shift
            ;;
        --screenshots)
            SCREENSHOTS=true
            shift
            ;;
        --emulator)
            START_EMULATOR=true
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Validate category
if [[ ! " ${VALID_CATEGORIES[@]} " =~ " ${CATEGORY} " ]]; then
    log_error "Invalid category: $CATEGORY"
    log_info "Valid categories: ${VALID_CATEGORIES[*]}"
    exit 1
fi

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check Android SDK
    if [[ -z "$ANDROID_HOME" ]]; then
        log_error "ANDROID_HOME not set. Please set up Android SDK."
        exit 1
    fi
    
    # Check ADB
    if ! command -v adb &> /dev/null; then
        log_error "ADB not found. Please add Android SDK platform-tools to PATH."
        exit 1
    fi
    
    # Check Gradle
    if [[ ! -f "$PROJECT_ROOT/android/gradlew" ]]; then
        log_error "Gradle wrapper not found at $PROJECT_ROOT/android/"
        exit 1
    fi
    
    # Check project files
    if [[ ! -f "$PROJECT_ROOT/android/app/build.gradle" ]]; then
        log_error "Android project not found at $PROJECT_ROOT/android/"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Start emulator if requested
start_emulator() {
    if [[ "$START_EMULATOR" != true ]]; then
        return
    fi
    
    log_info "Starting Android emulator..."
    
    # Check if emulator is already running
    if adb devices | grep -q "emulator"; then
        log_info "Emulator already running"
        return
    fi
    
    # Get available AVDs
    local avds=$(emulator -list-avds 2>/dev/null | head -1)
    
    if [[ -z "$avds" ]]; then
        log_error "No Android Virtual Devices found. Please create an AVD."
        exit 1
    fi
    
    log_info "Starting emulator: $avds"
    emulator -avd "$avds" -no-window -no-audio -no-snapshot-save -wipe-data &
    
    # Wait for emulator to boot
    log_info "Waiting for emulator to boot..."
    adb wait-for-device
    
    # Wait for system to be ready
    while [[ $(adb shell getprop sys.boot_completed) != "1" ]]; do
        sleep 2
    done
    
    log_success "Emulator started and ready"
}

# Select test device
select_device() {
    if [[ -n "$DEVICE" ]]; then
        log_info "Using specified device: $DEVICE"
        echo "$DEVICE"
        return
    fi
    
    log_info "Auto-selecting test device..."
    
    # Get connected devices
    local devices=$(adb devices | grep -v "List of devices" | grep "device$" | awk '{print $1}' | head -1)
    
    if [[ -z "$devices" ]]; then
        log_error "No connected Android devices found"
        exit 1
    fi
    
    echo "$devices"
}

# Build the project
build_project() {
    if [[ "$NO_BUILD" == true ]]; then
        log_info "Skipping build (--no-build specified)"
        return
    fi
    
    log_info "Building Android project for testing..."
    
    cd "$PROJECT_ROOT/android"
    
    local gradle_args=(
        assembleDebug
        assembleDebugAndroidTest
    )
    
    if [[ "$VERBOSE" == true ]]; then
        ./gradlew "${gradle_args[@]}" --info
    else
        ./gradlew "${gradle_args[@]}" > "$REPORT_DIR/build.log" 2>&1
    fi
    
    if [[ $? -eq 0 ]]; then
        log_success "Build completed successfully"
    else
        log_error "Build failed. Check build.log for details."
        exit 1
    fi
}

# Install test APKs
install_apks() {
    log_info "Installing test APKs..."
    
    cd "$PROJECT_ROOT/android"
    
    # Install main APK
    adb -s "$SELECTED_DEVICE" install -r app/build/outputs/apk/debug/app-debug.apk
    
    # Install test APK
    adb -s "$SELECTED_DEVICE" install -r app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk
    
    log_success "APKs installed successfully"
}

# Run specific test category
run_test_category() {
    local category=$1
    log_info "Running $category tests..."
    
    cd "$PROJECT_ROOT/android"
    
    local test_args=(
        connectedAndroidTest
        -Pandroid.testInstrumentationRunnerArguments.class=com.roadtrip.copilot.e2e.AutoDiscoverE2ETests
    )
    
    # Add category-specific test filters
    case $category in
        "core-functionality")
            test_args+=(-Pandroid.testInstrumentationRunnerArguments.method="testAD001_01_ButtonPresenceAndPositioning,testAD001_02_ButtonInteractionAndState,testAD002_01_BasicPOIDiscovery,testAD002_02_POIRankingAlgorithmAccuracy,testAD003_01_AutomaticTransitionToMainPOIView,testAD003_02_PhotoAutoCyclingBehavior")
            ;;
        "platform-parity")
            test_args+=(-Pandroid.testInstrumentationRunnerArguments.method="testAD010_01_CrossPlatformBehaviorConsistency")
            ;;
        "voice-integration")
            test_args+=(-Pandroid.testInstrumentationRunnerArguments.method="testAD004_02_VoiceCommandNavigation,testAD005_02_VoiceCommandDislike,testAD007_01_SpeakInfoButtonFunctionality,testAD007_02_VoiceCommandAudioControl")
            ;;
        "accessibility")
            test_args+=(-Pandroid.testInstrumentationRunnerArguments.method="testAD011_01_ScreenReaderCompatibility,testAD011_02_TouchTargetAndVisualRequirements")
            ;;
        "performance")
            test_args+=(-Pandroid.testInstrumentationRunnerArguments.method="testAD012_01_DiscoveryPerformance,testAD012_02_MemoryAndBatteryUsage")
            ;;
        "error-handling")
            test_args+=(-Pandroid.testInstrumentationRunnerArguments.method="testAD013_01_NetworkFailureHandling,testAD013_02_LocationAndPermissionErrors")
            ;;
        "all")
            # Run all AutoDiscoverE2ETests (no filter)
            ;;
    esac
    
    # Add coverage if requested
    if [[ "$COVERAGE" == true ]]; then
        test_args+=(-Pandroid.testInstrumentationRunnerArguments.coverage=true)
    fi
    
    # Add performance monitoring if requested
    if [[ "$PERFORMANCE" == true ]]; then
        test_args+=(-Pandroid.testInstrumentationRunnerArguments.performance=true)
    fi
    
    # Add screenshot capture if requested
    if [[ "$SCREENSHOTS" == true ]]; then
        test_args+=(-Pandroid.testInstrumentationRunnerArguments.screenshots=true)
    fi
    
    # Execute tests
    if [[ "$VERBOSE" == true ]]; then
        ./gradlew "${test_args[@]}" --info
    else
        ./gradlew "${test_args[@]}" > "$REPORT_DIR/${category}_test.log" 2>&1
    fi
    
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        log_success "$category tests passed"
    else
        log_error "$category tests failed (exit code: $exit_code)"
        return $exit_code
    fi
    
    return 0
}

# Extract test results
extract_results() {
    log_info "Extracting test results..."
    
    # Create summary directory
    mkdir -p "$REPORT_DIR/summary"
    
    cd "$PROJECT_ROOT/android"
    
    # Copy test reports
    if [[ -d "app/build/reports/androidTests/connected" ]]; then
        cp -r app/build/reports/androidTests/connected "$REPORT_DIR/test-reports"
    fi
    
    # Copy test results
    if [[ -d "app/build/outputs/androidTest-results/connected" ]]; then
        cp -r app/build/outputs/androidTest-results/connected "$REPORT_DIR/test-results"
    fi
    
    # Extract JUnit XML results
    find app/build/outputs/androidTest-results -name "*.xml" -exec cp {} "$REPORT_DIR/summary/" \; 2>/dev/null || true
    
    # Extract screenshots if captured
    if [[ "$SCREENSHOTS" == true ]]; then
        local screenshot_dir="$REPORT_DIR/screenshots"
        mkdir -p "$screenshot_dir"
        
        # Pull screenshots from device
        adb -s "$SELECTED_DEVICE" shell find /sdcard/Pictures/Screenshots -name "*.png" 2>/dev/null | while read -r screenshot; do
            adb -s "$SELECTED_DEVICE" pull "$screenshot" "$screenshot_dir/" 2>/dev/null || true
        done
    fi
}

# Generate coverage report
generate_coverage_report() {
    if [[ "$COVERAGE" != true ]]; then
        return
    fi
    
    log_info "Generating code coverage report..."
    
    cd "$PROJECT_ROOT/android"
    
    # Pull coverage data from device
    adb -s "$SELECTED_DEVICE" shell "run-as com.roadtrip.copilot cat /data/data/com.roadtrip.copilot/coverage.ec" > "$REPORT_DIR/coverage.ec" 2>/dev/null || true
    
    if [[ -f "$REPORT_DIR/coverage.ec" ]]; then
        # Generate coverage report using Gradle
        ./gradlew jacocoTestReport > "$REPORT_DIR/coverage.log" 2>&1 || true
        
        # Copy coverage reports
        if [[ -d "app/build/reports/jacoco" ]]; then
            cp -r app/build/reports/jacoco "$REPORT_DIR/coverage-reports"
        fi
        
        log_success "Coverage report generated"
    else
        log_warning "No coverage data found"
    fi
}

# Generate performance report
generate_performance_report() {
    if [[ "$PERFORMANCE" != true ]]; then
        return
    fi
    
    log_info "Generating performance report..."
    
    local perf_report="$REPORT_DIR/performance_report.txt"
    
    cat > "$perf_report" << EOF
Auto Discover E2E Performance Report - Android
===============================================
Generated: $(date)
Device: $SELECTED_DEVICE

Device Information:
EOF
    
    # Get device information
    adb -s "$SELECTED_DEVICE" shell getprop ro.product.model >> "$perf_report"
    adb -s "$SELECTED_DEVICE" shell getprop ro.build.version.release >> "$perf_report"
    
    echo "" >> "$perf_report"
    echo "Performance Metrics:" >> "$perf_report"
    
    # Extract performance data from test outputs
    grep -h "Performance:" "$REPORT_DIR"/*.log 2>/dev/null >> "$perf_report" || echo "No performance data found" >> "$perf_report"
    
    log_success "Performance report generated: $perf_report"
}

# Pull device logs
pull_device_logs() {
    log_info "Pulling device logs..."
    
    # Pull logcat for the test period
    adb -s "$SELECTED_DEVICE" logcat -d -v time "*:V" > "$REPORT_DIR/logcat.txt" 2>/dev/null || true
    
    # Filter app-specific logs
    grep "com.roadtrip.copilot" "$REPORT_DIR/logcat.txt" > "$REPORT_DIR/app_logcat.txt" 2>/dev/null || true
    
    log_success "Device logs captured"
}

# Generate final report
generate_final_report() {
    log_info "Generating final test report..."
    
    local final_report="$REPORT_DIR/FINAL_REPORT.md"
    
    cat > "$final_report" << EOF
# Auto Discover E2E Test Results - Android

**Execution Date:** $(date)  
**Test Category:** $CATEGORY  
**Device:** $SELECTED_DEVICE  
**Report Directory:** $REPORT_DIR

## Test Configuration

- **Verbose Output:** $VERBOSE
- **Build Skipped:** $NO_BUILD  
- **Parallel Execution:** $PARALLEL
- **Code Coverage:** $COVERAGE
- **Performance Monitoring:** $PERFORMANCE
- **Screenshots:** $SCREENSHOTS
- **Emulator Started:** $START_EMULATOR

## Device Information

EOF
    
    # Add device information
    echo "- **Model:** $(adb -s "$SELECTED_DEVICE" shell getprop ro.product.model)" >> "$final_report"
    echo "- **Android Version:** $(adb -s "$SELECTED_DEVICE" shell getprop ro.build.version.release)" >> "$final_report"
    echo "- **API Level:** $(adb -s "$SELECTED_DEVICE" shell getprop ro.build.version.sdk)" >> "$final_report"
    
    cat >> "$final_report" << EOF

## Test Results Summary

EOF
    
    # Add test results for each category
    local overall_status="PASSED"
    
    for result_file in "$REPORT_DIR"/*_test.log; do
        if [[ -f "$result_file" ]]; then
            local category_name=$(basename "$result_file" _test.log)
            
            if grep -q "BUILD SUCCESSFUL" "$result_file" 2>/dev/null; then
                echo "- **$category_name:** ✅ PASSED" >> "$final_report"
            else
                echo "- **$category_name:** ❌ FAILED" >> "$final_report"
                overall_status="FAILED"
            fi
        fi
    done
    
    cat >> "$final_report" << EOF

## Overall Status: $overall_status

## Files Generated

- Test logs: \`*_test.log\`
- Test reports: \`test-reports/\`
- Test results: \`test-results/\`
- JUnit XML: \`summary/*.xml\`
- Device logs: \`logcat.txt\`, \`app_logcat.txt\`
EOF
    
    if [[ "$COVERAGE" == true ]]; then
        echo "- Coverage reports: \`coverage-reports/\`" >> "$final_report"
    fi
    
    if [[ "$PERFORMANCE" == true ]]; then
        echo "- Performance report: \`performance_report.txt\`" >> "$final_report"
    fi
    
    if [[ "$SCREENSHOTS" == true ]]; then
        echo "- Screenshots: \`screenshots/\`" >> "$final_report"
    fi
    
    cat >> "$final_report" << EOF

## Platform Parity

This Android test suite should be compared with the iOS equivalent for platform parity validation:

- **iOS Test Script:** \`/mobile/ios/e2e-ui-tests/Scripts/run-auto-discover-tests.sh\`
- **Comparison Points:** 
  - Discovery timing (should be within 10ms)
  - Voice command response (should be within 350ms)
  - UI behavior consistency
  - Feature availability parity

## Next Steps

EOF
    
    if [[ "$overall_status" == "FAILED" ]]; then
        cat >> "$final_report" << EOF
❌ **Tests failed.** Review individual test logs and fix failing tests before proceeding.

1. Check specific failure details in test logs
2. Review device logs for crashes or errors
3. Verify platform parity with iOS implementation
4. Ensure voice recognition and permissions are properly configured
5. Re-run tests after fixes: \`./run-auto-discover-tests.sh --category $CATEGORY\`
EOF
    else
        cat >> "$final_report" << EOF
✅ **All tests passed!** Auto Discover feature is ready for deployment.

1. Review performance metrics if generated
2. Verify coverage meets requirements (>90%)
3. Compare with iOS test results for platform parity validation
4. Run cross-platform integration tests
5. Proceed with staging deployment
EOF
    fi
    
    log_success "Final report generated: $final_report"
    
    # Display summary
    echo
    log_info "TEST EXECUTION SUMMARY"
    echo "======================="
    echo "Category: $CATEGORY"
    echo "Status: $overall_status"
    echo "Device: $SELECTED_DEVICE"
    echo "Report: $final_report"
    echo "Duration: $(($(date +%s) - $START_TIME)) seconds"
    echo
    
    if [[ "$overall_status" == "FAILED" ]]; then
        log_error "Some tests failed. Check the final report for details."
        return 1
    else
        log_success "All tests passed successfully!"
        return 0
    fi
}

# Cleanup function
cleanup() {
    log_info "Cleaning up..."
    
    # Uninstall test APKs
    adb -s "$SELECTED_DEVICE" uninstall com.roadtrip.copilot 2>/dev/null || true
    adb -s "$SELECTED_DEVICE" uninstall com.roadtrip.copilot.test 2>/dev/null || true
    
    # Return to original directory
    cd "$SCRIPT_DIR"
}

# Main execution
main() {
    START_TIME=$(date +%s)
    
    # Set up trap for cleanup
    trap cleanup EXIT
    
    # Create report directory
    mkdir -p "$REPORT_DIR"
    
    log_info "Starting Auto Discover E2E Tests for Android"
    log_info "Category: $CATEGORY"
    log_info "Report Directory: $REPORT_DIR"
    
    # Execute test pipeline
    check_prerequisites
    start_emulator
    SELECTED_DEVICE=$(select_device)
    log_info "Selected device: $SELECTED_DEVICE"
    
    build_project
    install_apks
    
    # Run tests based on category
    if [[ "$CATEGORY" == "all" ]]; then
        local categories=("core-functionality" "platform-parity" "voice-integration" "accessibility" "performance" "error-handling")
        for cat in "${categories[@]}"; do
            run_test_category "$cat" || true  # Continue even if some categories fail
        done
    else
        run_test_category "$CATEGORY"
    fi
    
    # Post-processing
    extract_results
    generate_coverage_report
    generate_performance_report
    pull_device_logs
    generate_final_report
}

# Execute main function
main "$@"