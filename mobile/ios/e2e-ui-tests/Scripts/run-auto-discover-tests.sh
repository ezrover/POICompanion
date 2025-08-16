#!/bin/bash

# Auto Discover E2E Test Execution Script for iOS
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
Auto Discover E2E Test Runner for iOS

USAGE:
    ./run-auto-discover-tests.sh [OPTIONS]

OPTIONS:
    --category CATEGORY     Run specific test category (default: all)
                           Valid categories: ${VALID_CATEGORIES[*]}
    --device DEVICE        Target device/simulator (default: auto-select)
    --verbose              Enable verbose output
    --no-build             Skip building before testing
    --parallel             Run tests in parallel where possible
    --coverage             Generate code coverage report
    --performance          Enable detailed performance monitoring
    --screenshots          Capture screenshots during test execution
    --help                 Show this help message

EXAMPLES:
    # Run all Auto Discover tests
    ./run-auto-discover-tests.sh

    # Run only core functionality tests
    ./run-auto-discover-tests.sh --category core-functionality

    # Run performance tests with detailed monitoring
    ./run-auto-discover-tests.sh --category performance --performance --verbose

    # Run tests with coverage and screenshots
    ./run-auto-discover-tests.sh --coverage --screenshots

CATEGORIES:
    core-functionality     Button integration, POI discovery, photo cycling
    platform-parity       iOS-specific behavior validation
    voice-integration      Voice commands and audio features
    accessibility          VoiceOver compliance and touch targets
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
    
    # Check Xcode installation
    if ! command -v xcodebuild &> /dev/null; then
        log_error "Xcode command line tools not found. Please install Xcode."
        exit 1
    fi
    
    # Check iOS Simulator
    if ! xcrun simctl list devices | grep -q "iPhone"; then
        log_error "No iOS simulators found. Please install iOS simulator runtimes."
        exit 1
    fi
    
    # Check project files
    if [[ ! -f "$PROJECT_ROOT/ios/RoadtripCopilot.xcodeproj/project.pbxproj" ]]; then
        log_error "iOS project not found at $PROJECT_ROOT/ios/"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Select test device
select_device() {
    if [[ -n "$DEVICE" ]]; then
        log_info "Using specified device: $DEVICE"
        echo "$DEVICE"
        return
    fi
    
    log_info "Auto-selecting test device..."
    
    # Get available iOS simulators
    AVAILABLE_DEVICES=$(xcrun simctl list devices --json | jq -r '.devices[] | .[] | select(.isAvailable == true and (.name | contains("iPhone"))) | .name + " (" + .udid + ")"' | head -1)
    
    if [[ -z "$AVAILABLE_DEVICES" ]]; then
        log_error "No available iOS simulators found"
        exit 1
    fi
    
    echo "$AVAILABLE_DEVICES" | head -1
}

# Build the project
build_project() {
    if [[ "$NO_BUILD" == true ]]; then
        log_info "Skipping build (--no-build specified)"
        return
    fi
    
    log_info "Building iOS project for testing..."
    
    cd "$PROJECT_ROOT/ios"
    
    local build_args=(
        -project RoadtripCopilot.xcodeproj
        -scheme RoadtripCopilot
        -configuration Debug
        -sdk iphonesimulator
        -destination "platform=iOS Simulator,name=$(echo "$SELECTED_DEVICE" | cut -d'(' -f1 | xargs)"
        build-for-testing
    )
    
    if [[ "$VERBOSE" == true ]]; then
        xcodebuild "${build_args[@]}"
    else
        xcodebuild "${build_args[@]}" > "$REPORT_DIR/build.log" 2>&1
    fi
    
    if [[ $? -eq 0 ]]; then
        log_success "Build completed successfully"
    else
        log_error "Build failed. Check build.log for details."
        exit 1
    fi
}

# Run specific test category
run_test_category() {
    local category=$1
    log_info "Running $category tests..."
    
    cd "$PROJECT_ROOT/ios"
    
    local test_args=(
        -project RoadtripCopilot.xcodeproj
        -scheme RoadtripCopilot
        -configuration Debug
        -sdk iphonesimulator
        -destination "platform=iOS Simulator,name=$(echo "$SELECTED_DEVICE" | cut -d'(' -f1 | xargs)"
        -resultBundlePath "$REPORT_DIR/${category}_results.xcresult"
        test-without-building
    )
    
    # Add coverage if requested
    if [[ "$COVERAGE" == true ]]; then
        test_args+=(-enableCodeCoverage YES)
    fi
    
    # Add category-specific test filters
    case $category in
        "core-functionality")
            test_args+=(-only-testing "AutoDiscoverE2ETests/testAD001_01_ButtonPresenceAndPositioning")
            test_args+=(-only-testing "AutoDiscoverE2ETests/testAD001_02_ButtonInteractionAndState")
            test_args+=(-only-testing "AutoDiscoverE2ETests/testAD002_01_BasicPOIDiscovery")
            test_args+=(-only-testing "AutoDiscoverE2ETests/testAD002_02_POIRankingAlgorithmAccuracy")
            test_args+=(-only-testing "AutoDiscoverE2ETests/testAD003_01_AutomaticTransitionToMainPOIView")
            test_args+=(-only-testing "AutoDiscoverE2ETests/testAD003_02_PhotoAutoCyclingBehavior")
            ;;
        "platform-parity")
            test_args+=(-only-testing "AutoDiscoverE2ETests/testAD010_01_CrossPlatformBehaviorConsistency")
            ;;
        "voice-integration")
            test_args+=(-only-testing "AutoDiscoverE2ETests/testAD004_02_VoiceCommandNavigation")
            test_args+=(-only-testing "AutoDiscoverE2ETests/testAD005_02_VoiceCommandDislike")
            test_args+=(-only-testing "AutoDiscoverE2ETests/testAD007_01_SpeakInfoButtonFunctionality")
            test_args+=(-only-testing "AutoDiscoverE2ETests/testAD007_02_VoiceCommandAudioControl")
            ;;
        "accessibility")
            test_args+=(-only-testing "AutoDiscoverE2ETests/testAD011_01_ScreenReaderCompatibility")
            test_args+=(-only-testing "AutoDiscoverE2ETests/testAD011_02_TouchTargetAndVisualRequirements")
            ;;
        "performance")
            test_args+=(-only-testing "AutoDiscoverE2ETests/testAD012_01_DiscoveryPerformance")
            test_args+=(-only-testing "AutoDiscoverE2ETests/testAD012_02_MemoryAndBatteryUsage")
            ;;
        "error-handling")
            test_args+=(-only-testing "AutoDiscoverE2ETests/testAD013_01_NetworkFailureHandling")
            test_args+=(-only-testing "AutoDiscoverE2ETests/testAD013_02_LocationAndPermissionErrors")
            ;;
        "all")
            # Run all AutoDiscoverE2ETests
            test_args+=(-only-testing "AutoDiscoverE2ETests")
            ;;
    esac
    
    # Execute tests
    if [[ "$VERBOSE" == true ]]; then
        xcodebuild "${test_args[@]}"
    else
        xcodebuild "${test_args[@]}" > "$REPORT_DIR/${category}_test.log" 2>&1
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
    
    # Extract results from .xcresult bundles
    for result_bundle in "$REPORT_DIR"/*.xcresult; do
        if [[ -f "$result_bundle" ]]; then
            local bundle_name=$(basename "$result_bundle" .xcresult)
            
            # Extract test summary
            xcrun xcresulttool get --format json --path "$result_bundle" > "$REPORT_DIR/summary/${bundle_name}_summary.json"
            
            # Extract test details
            xcrun xcresulttool get tests --format json --path "$result_bundle" > "$REPORT_DIR/summary/${bundle_name}_tests.json"
            
            # Extract screenshots if available and requested
            if [[ "$SCREENSHOTS" == true ]]; then
                local screenshot_dir="$REPORT_DIR/screenshots/$bundle_name"
                mkdir -p "$screenshot_dir"
                
                # Extract screenshot references
                xcrun xcresulttool get attachments --path "$result_bundle" --output-dir "$screenshot_dir" 2>/dev/null || true
            fi
        fi
    done
}

# Generate coverage report
generate_coverage_report() {
    if [[ "$COVERAGE" != true ]]; then
        return
    fi
    
    log_info "Generating code coverage report..."
    
    # Find coverage data
    local coverage_data=$(find "$REPORT_DIR" -name "*.xcresult" -exec xcrun xcresulttool get --format json --path {} \; | jq -r '.actions[] | .buildResult.coverage.targets[] | .files[] | .path' | head -1)
    
    if [[ -n "$coverage_data" ]]; then
        echo "Coverage data found: $coverage_data" > "$REPORT_DIR/coverage_summary.txt"
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
    
    # Extract performance metrics from test logs
    local perf_report="$REPORT_DIR/performance_report.txt"
    
    cat > "$perf_report" << EOF
Auto Discover E2E Performance Report - iOS
==========================================
Generated: $(date)
Device: $SELECTED_DEVICE

Performance Metrics:
EOF
    
    # Extract performance data from test outputs
    grep -h "Performance:" "$REPORT_DIR"/*.log 2>/dev/null >> "$perf_report" || echo "No performance data found" >> "$perf_report"
    
    log_success "Performance report generated: $perf_report"
}

# Generate final report
generate_final_report() {
    log_info "Generating final test report..."
    
    local final_report="$REPORT_DIR/FINAL_REPORT.md"
    
    cat > "$final_report" << EOF
# Auto Discover E2E Test Results - iOS

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

## Test Results Summary

EOF
    
    # Add test results for each category
    local overall_status="PASSED"
    
    for result_file in "$REPORT_DIR"/*_test.log; do
        if [[ -f "$result_file" ]]; then
            local category_name=$(basename "$result_file" _test.log)
            
            if grep -q "BUILD SUCCEEDED" "$result_file" 2>/dev/null; then
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
- Result bundles: \`*.xcresult\`
- Test summaries: \`summary/*_summary.json\`
EOF
    
    if [[ "$COVERAGE" == true ]]; then
        echo "- Coverage report: \`coverage_summary.txt\`" >> "$final_report"
    fi
    
    if [[ "$PERFORMANCE" == true ]]; then
        echo "- Performance report: \`performance_report.txt\`" >> "$final_report"
    fi
    
    if [[ "$SCREENSHOTS" == true ]]; then
        echo "- Screenshots: \`screenshots/\`" >> "$final_report"
    fi
    
    cat >> "$final_report" << EOF

## Next Steps

EOF
    
    if [[ "$overall_status" == "FAILED" ]]; then
        cat >> "$final_report" << EOF
❌ **Tests failed.** Review individual test logs and fix failing tests before proceeding.

1. Check specific failure details in test logs
2. Verify platform parity requirements
3. Ensure voice recognition is properly configured
4. Re-run tests after fixes: \`./run-auto-discover-tests.sh --category $CATEGORY\`
EOF
    else
        cat >> "$final_report" << EOF
✅ **All tests passed!** Auto Discover feature is ready for deployment.

1. Review performance metrics if generated
2. Verify coverage meets requirements (>90%)
3. Run Android equivalent tests for platform parity validation
4. Proceed with integration testing
EOF
    fi
    
    log_success "Final report generated: $final_report"
    
    # Display summary
    echo
    log_info "TEST EXECUTION SUMMARY"
    echo "======================="
    echo "Category: $CATEGORY"
    echo "Status: $overall_status"
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
    
    # Kill any hanging simulators if needed
    xcrun simctl shutdown all 2>/dev/null || true
    
    # Return to original directory
    cd "$SCRIPT_DIR"
}

# Main execution
main() {
    local START_TIME=$(date +%s)
    
    # Set up trap for cleanup
    trap cleanup EXIT
    
    # Create report directory
    mkdir -p "$REPORT_DIR"
    
    log_info "Starting Auto Discover E2E Tests for iOS"
    log_info "Category: $CATEGORY"
    log_info "Report Directory: $REPORT_DIR"
    
    # Execute test pipeline
    check_prerequisites
    SELECTED_DEVICE=$(select_device)
    log_info "Selected device: $SELECTED_DEVICE"
    
    build_project
    
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
    generate_final_report
}

# Execute main function
main "$@"