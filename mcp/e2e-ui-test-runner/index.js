#!/usr/bin/env node

/**
 * E2E UI Test Runner MCP Tool
 * Comprehensive end-to-end UI testing for iOS and Android platforms
 * Provides unified test execution, reporting, and platform parity validation
 */

const { execSync, spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

class E2EUITestRunner {
    constructor() {
        this.timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        this.basePath = path.join(__dirname, '..', '..');
        this.iosTestPath = path.join(this.basePath, 'mobile', 'ios', 'e2e-ui-tests');
        this.androidTestPath = path.join(this.basePath, 'mobile', 'android', 'e2e-ui-tests');
        this.resultsPath = path.join(__dirname, 'test-results');
        this.currentReportPath = null;
        
        // Ensure results directory exists
        if (!fs.existsSync(this.resultsPath)) {
            fs.mkdirSync(this.resultsPath, { recursive: true });
        }
    }

    /**
     * Execute command with output capture
     */
    exec(command, options = {}) {
        const defaultOptions = {
            encoding: 'utf8',
            stdio: options.silent ? 'pipe' : 'inherit',
            cwd: options.cwd || process.cwd()
        };
        
        try {
            const output = execSync(command, { ...defaultOptions, ...options });
            return { success: true, output };
        } catch (error) {
            if (!options.silent) {
                console.error(`❌ Command failed: ${command}`);
                console.error(error.message);
            }
            return { success: false, error: error.message, output: error.stdout?.toString() };
        }
    }

    /**
     * Main test runner
     */
    async runTests(platform, options = {}) {
        console.log(`🚀 Starting E2E UI Tests for ${platform.toUpperCase()}`);
        console.log('='.repeat(60));
        
        // Initialize report path
        this.currentReportPath = path.join(this.resultsPath, `${platform}_${this.timestamp}`);
        fs.mkdirSync(this.currentReportPath, { recursive: true });
        
        let result;
        switch (platform.toLowerCase()) {
            case 'ios':
                result = await this.runIOSTests(options);
                break;
            case 'android':
                result = await this.runAndroidTests(options);
                break;
            case 'both':
                result = await this.runBothPlatforms(options);
                break;
            default:
                console.error(`❌ Invalid platform: ${platform}. Use 'ios', 'android', or 'both'`);
                return false;
        }
        
        // Generate final report
        this.generateReport(platform, result);
        
        return result;
    }

    /**
     * Run iOS E2E tests
     */
    async runIOSTests(options) {
        console.log('📱 Running iOS E2E Tests...\n');
        
        const results = {
            platform: 'iOS',
            startTime: new Date(),
            tests: {},
            summary: {
                total: 0,
                passed: 0,
                failed: 0
            }
        };
        
        // Check if Xcode project exists
        const projectPath = path.join(this.basePath, 'mobile', 'ios', 'RoadtripCopilot.xcodeproj');
        if (!fs.existsSync(projectPath)) {
            console.error('❌ iOS project not found at:', projectPath);
            return results;
        }
        
        // Boot iOS Simulator if needed
        if (!options.skipSimulator) {
            console.log('📱 Checking iOS Simulator...');
            this.bootIOSSimulator();
        }
        
        // Build app for testing
        if (!options.skipBuild) {
            console.log('🔨 Building iOS app for testing...');
            const buildResult = this.exec(
                `xcodebuild build-for-testing -project "${projectPath}" -scheme "RoadtripCopilot" -destination "platform=iOS Simulator,name=iPhone 16 Pro"`,
                { cwd: path.join(this.basePath, 'mobile', 'ios'), silent: true }
            );
            
            if (!buildResult.success) {
                console.error('❌ iOS build failed');
                results.summary.failed++;
                return results;
            }
            console.log('✅ iOS build successful\n');
        }
        
        // Run test suites
        const testSuites = [
            { 
                name: 'Critical Path', 
                test: 'E2ETestRunner/testCriticalPath_LostLakeOregonFlow',
                critical: true 
            },
            { 
                name: 'Platform Parity', 
                test: 'E2ETestRunner/testPlatformParity_iOSCarPlaySync',
                critical: true 
            },
            { 
                name: 'Accessibility', 
                test: 'E2ETestRunner/testAccessibilityCompliance_AllScreens',
                critical: true 
            },
            { 
                name: 'Performance', 
                test: 'E2ETestRunner/testPerformance_AppLaunchTime',
                critical: false 
            },
            { 
                name: 'Error Recovery', 
                test: 'E2ETestRunner/testErrorRecovery_NetworkFailure',
                critical: false 
            }
        ];
        
        for (const suite of testSuites) {
            if (options.criticalOnly && !suite.critical) continue;
            
            console.log(`🧪 Running ${suite.name} tests...`);
            const testResult = this.runIOSTestSuite(suite, projectPath);
            results.tests[suite.name] = testResult;
            results.summary.total++;
            
            if (testResult.passed) {
                results.summary.passed++;
                console.log(`✅ ${suite.name} tests PASSED\n`);
            } else {
                results.summary.failed++;
                console.log(`❌ ${suite.name} tests FAILED\n`);
                if (options.failFast) break;
            }
        }
        
        results.endTime = new Date();
        results.duration = (results.endTime - results.startTime) / 1000;
        
        return results;
    }

    /**
     * Run Android E2E tests
     */
    async runAndroidTests(options) {
        console.log('🤖 Running Android E2E Tests...\n');
        
        const results = {
            platform: 'Android',
            startTime: new Date(),
            tests: {},
            summary: {
                total: 0,
                passed: 0,
                failed: 0
            }
        };
        
        // Check if Android project exists
        const projectPath = path.join(this.basePath, 'mobile', 'android');
        if (!fs.existsSync(projectPath)) {
            console.error('❌ Android project not found at:', projectPath);
            return results;
        }
        
        // Boot Android Emulator if needed
        if (!options.skipEmulator) {
            console.log('🤖 Checking Android Emulator...');
            this.bootAndroidEmulator();
        }
        
        // Build app for testing
        if (!options.skipBuild) {
            console.log('🔨 Building Android app for testing...');
            const buildResult = this.exec(
                './gradlew assembleDebug assembleDebugAndroidTest',
                { cwd: projectPath, silent: true }
            );
            
            if (!buildResult.success) {
                console.error('❌ Android build failed');
                results.summary.failed++;
                return results;
            }
            console.log('✅ Android build successful\n');
        }
        
        // Install app on device
        console.log('📲 Installing Android app...');
        this.exec('./gradlew installDebug installDebugAndroidTest', { cwd: projectPath, silent: true });
        
        // Run test suites
        const testSuites = [
            { 
                name: 'Critical Path', 
                test: 'E2ETestRunner#testCriticalPath_LostLakeOregonFlow',
                critical: true 
            },
            { 
                name: 'Platform Parity iOS', 
                test: 'E2ETestRunner#testPlatformParity_iOSBehaviorMatch',
                critical: true 
            },
            { 
                name: 'Platform Parity Auto', 
                test: 'E2ETestRunner#testPlatformParity_AndroidAutoSync',
                critical: true 
            },
            { 
                name: 'Accessibility', 
                test: 'E2ETestRunner#testAccessibilityCompliance_AllScreens',
                critical: true 
            },
            { 
                name: 'Performance', 
                test: 'E2ETestRunner#testPerformance_AppLaunchTime',
                critical: false 
            },
            { 
                name: 'Error Recovery', 
                test: 'E2ETestRunner#testErrorRecovery_NetworkFailure',
                critical: false 
            }
        ];
        
        for (const suite of testSuites) {
            if (options.criticalOnly && !suite.critical) continue;
            
            console.log(`🧪 Running ${suite.name} tests...`);
            const testResult = this.runAndroidTestSuite(suite, projectPath);
            results.tests[suite.name] = testResult;
            results.summary.total++;
            
            if (testResult.passed) {
                results.summary.passed++;
                console.log(`✅ ${suite.name} tests PASSED\n`);
            } else {
                results.summary.failed++;
                console.log(`❌ ${suite.name} tests FAILED\n`);
                if (options.failFast) break;
            }
        }
        
        // Collect device info and screenshots
        this.collectAndroidArtifacts();
        
        results.endTime = new Date();
        results.duration = (results.endTime - results.startTime) / 1000;
        
        return results;
    }

    /**
     * Run tests on both platforms
     */
    async runBothPlatforms(options) {
        console.log('📱🤖 Running E2E Tests on Both Platforms...\n');
        
        const results = {
            platform: 'Both',
            ios: await this.runIOSTests(options),
            android: await this.runAndroidTests(options),
            platformParity: null
        };
        
        // Validate platform parity
        results.platformParity = this.validatePlatformParity(results.ios, results.android);
        
        return results;
    }

    /**
     * Run individual iOS test suite
     */
    runIOSTestSuite(suite, projectPath) {
        const result = {
            name: suite.name,
            passed: false,
            duration: 0,
            output: '',
            screenshots: []
        };
        
        const startTime = Date.now();
        
        const testResult = this.exec(
            `xcodebuild test -project "${projectPath}" -scheme "RoadtripCopilot" ` +
            `-destination "platform=iOS Simulator,name=iPhone 16 Pro" ` +
            `-only-testing:RoadtripCopilotUITests/${suite.test}`,
            { 
                cwd: path.join(this.basePath, 'mobile', 'ios'),
                silent: true 
            }
        );
        
        result.duration = (Date.now() - startTime) / 1000;
        result.passed = testResult.success;
        result.output = testResult.output || testResult.error || '';
        
        // Save test output
        const outputFile = path.join(this.currentReportPath, `ios_${suite.name.replace(/\s/g, '_')}.log`);
        fs.writeFileSync(outputFile, result.output);
        
        return result;
    }

    /**
     * Run individual Android test suite
     */
    runAndroidTestSuite(suite, projectPath) {
        const result = {
            name: suite.name,
            passed: false,
            duration: 0,
            output: '',
            screenshots: []
        };
        
        const startTime = Date.now();
        
        const testResult = this.exec(
            `./gradlew connectedAndroidTest ` +
            `-Pandroid.testInstrumentationRunnerArguments.class=com.roadtrip.copilot.e2e.${suite.test}`,
            { 
                cwd: projectPath,
                silent: true 
            }
        );
        
        result.duration = (Date.now() - startTime) / 1000;
        result.passed = testResult.success;
        result.output = testResult.output || testResult.error || '';
        
        // Save test output
        const outputFile = path.join(this.currentReportPath, `android_${suite.name.replace(/\s/g, '_')}.log`);
        fs.writeFileSync(outputFile, result.output);
        
        return result;
    }

    /**
     * Boot iOS Simulator
     */
    bootIOSSimulator() {
        // Check if simulator is already running
        const devices = this.exec('xcrun simctl list devices booted', { silent: true });
        
        if (!devices.output || !devices.output.includes('iPhone 16 Pro')) {
            console.log('🚀 Booting iPhone 16 Pro simulator...');
            this.exec('xcrun simctl boot "iPhone 16 Pro"', { silent: true });
            
            // Open Simulator app
            this.exec('open -a Simulator', { silent: true });
            
            // Wait for boot
            this.exec('sleep 5', { silent: true });
        }
        
        console.log('✅ iOS Simulator ready\n');
    }

    /**
     * Boot Android Emulator
     */
    bootAndroidEmulator() {
        // Check if emulator is already running
        const devices = this.exec('adb devices', { silent: true });
        
        if (!devices.output || !devices.output.includes('emulator')) {
            console.log('🚀 Starting Android emulator...');
            
            // Try to start default emulator (assumes one is configured)
            const emulators = this.exec('emulator -list-avds', { silent: true });
            if (emulators.output) {
                const avdName = emulators.output.trim().split('\n')[0];
                if (avdName) {
                    // Start emulator in background
                    spawn('emulator', ['-avd', avdName, '-no-snapshot'], {
                        detached: true,
                        stdio: 'ignore'
                    }).unref();
                    
                    // Wait for device
                    console.log('⏳ Waiting for emulator to boot...');
                    this.exec('adb wait-for-device', { silent: true });
                    
                    // Wait for boot completion
                    let booted = false;
                    for (let i = 0; i < 30; i++) {
                        const bootComplete = this.exec('adb shell getprop sys.boot_completed', { silent: true });
                        if (bootComplete.output && bootComplete.output.trim() === '1') {
                            booted = true;
                            break;
                        }
                        this.exec('sleep 2', { silent: true });
                    }
                    
                    if (!booted) {
                        console.error('⚠️ Emulator boot timeout');
                    }
                }
            }
        }
        
        // Disable animations for testing
        this.exec('adb shell settings put global window_animation_scale 0', { silent: true });
        this.exec('adb shell settings put global transition_animation_scale 0', { silent: true });
        this.exec('adb shell settings put global animator_duration_scale 0', { silent: true });
        
        console.log('✅ Android Emulator ready\n');
    }

    /**
     * Collect Android test artifacts
     */
    collectAndroidArtifacts() {
        // Pull screenshots from device
        this.exec(`adb pull /sdcard/screenshots/ "${this.currentReportPath}/"`, { silent: true });
        
        // Copy test reports
        const androidReportsPath = path.join(this.basePath, 'mobile', 'android', 'app', 'build', 'reports');
        if (fs.existsSync(androidReportsPath)) {
            this.exec(`cp -r "${androidReportsPath}" "${this.currentReportPath}/android_reports"`, { silent: true });
        }
    }

    /**
     * Validate platform parity between iOS and Android
     */
    validatePlatformParity(iosResults, androidResults) {
        const parityReport = {
            passed: true,
            issues: [],
            criticalTests: {
                ios: {},
                android: {}
            }
        };
        
        // Check critical test parity
        const criticalTests = ['Critical Path', 'Platform Parity', 'Accessibility'];
        
        for (const testName of criticalTests) {
            const iosTest = iosResults.tests[testName];
            const androidTest = androidResults.tests[testName] || androidResults.tests[`${testName} iOS`];
            
            if (iosTest) parityReport.criticalTests.ios[testName] = iosTest.passed;
            if (androidTest) parityReport.criticalTests.android[testName] = androidTest.passed;
            
            if (iosTest && androidTest) {
                if (iosTest.passed !== androidTest.passed) {
                    parityReport.passed = false;
                    parityReport.issues.push(
                        `Platform parity violation: ${testName} - iOS: ${iosTest.passed ? 'PASSED' : 'FAILED'}, Android: ${androidTest.passed ? 'PASSED' : 'FAILED'}`
                    );
                }
            }
        }
        
        // Check overall pass rates
        const iosPassRate = iosResults.summary.passed / iosResults.summary.total;
        const androidPassRate = androidResults.summary.passed / androidResults.summary.total;
        
        if (Math.abs(iosPassRate - androidPassRate) > 0.1) {
            parityReport.passed = false;
            parityReport.issues.push(
                `Significant pass rate difference: iOS: ${(iosPassRate * 100).toFixed(1)}%, Android: ${(androidPassRate * 100).toFixed(1)}%`
            );
        }
        
        return parityReport;
    }

    /**
     * Generate comprehensive test report
     */
    generateReport(platform, results) {
        console.log('\n' + '='.repeat(60));
        console.log('📊 E2E UI TEST REPORT');
        console.log('='.repeat(60));
        
        const reportPath = path.join(this.currentReportPath, 'E2E_Test_Report.md');
        let reportContent = `# E2E UI Test Report\n\n`;
        reportContent += `**Platform**: ${platform.toUpperCase()}\n`;
        reportContent += `**Date**: ${new Date().toISOString()}\n`;
        reportContent += `**Results Path**: ${this.currentReportPath}\n\n`;
        
        if (platform === 'both') {
            // Both platforms report
            reportContent += this.generatePlatformReport('iOS', results.ios);
            reportContent += this.generatePlatformReport('Android', results.android);
            
            // Platform parity section
            reportContent += `## Platform Parity Validation\n\n`;
            if (results.platformParity.passed) {
                reportContent += `✅ **Platform Parity PASSED**\n\n`;
                console.log('✅ Platform Parity: PASSED');
            } else {
                reportContent += `❌ **Platform Parity FAILED**\n\n`;
                reportContent += `### Issues:\n`;
                results.platformParity.issues.forEach(issue => {
                    reportContent += `- ${issue}\n`;
                });
                console.log('❌ Platform Parity: FAILED');
                console.log('Issues:', results.platformParity.issues);
            }
            
            // Overall summary
            const totalTests = results.ios.summary.total + results.android.summary.total;
            const totalPassed = results.ios.summary.passed + results.android.summary.passed;
            const totalFailed = results.ios.summary.failed + results.android.summary.failed;
            
            console.log(`\n📊 Overall Summary:`);
            console.log(`   Total Tests: ${totalTests}`);
            console.log(`   Passed: ${totalPassed}`);
            console.log(`   Failed: ${totalFailed}`);
            console.log(`   Pass Rate: ${((totalPassed / totalTests) * 100).toFixed(1)}%`);
            
        } else {
            // Single platform report
            reportContent += this.generatePlatformReport(platform, results);
            
            console.log(`\n📊 ${platform.toUpperCase()} Test Summary:`);
            console.log(`   Total Tests: ${results.summary.total}`);
            console.log(`   Passed: ${results.summary.passed}`);
            console.log(`   Failed: ${results.summary.failed}`);
            console.log(`   Duration: ${results.duration?.toFixed(2)}s`);
            console.log(`   Pass Rate: ${((results.summary.passed / results.summary.total) * 100).toFixed(1)}%`);
        }
        
        // Add artifacts section
        reportContent += `\n## Test Artifacts\n\n`;
        reportContent += `- Test logs: ${this.currentReportPath}/*.log\n`;
        reportContent += `- Screenshots: ${this.currentReportPath}/screenshots/\n`;
        reportContent += `- Test reports: ${this.currentReportPath}/*_reports/\n`;
        
        // Write report
        fs.writeFileSync(reportPath, reportContent);
        
        console.log(`\n📄 Full report saved to: ${reportPath}`);
        console.log('='.repeat(60));
        
        // Return success/failure for CLI exit code
        if (platform === 'both') {
            return results.platformParity.passed && 
                   results.ios.summary.failed === 0 && 
                   results.android.summary.failed === 0;
        } else {
            return results.summary.failed === 0;
        }
    }

    /**
     * Generate report section for a single platform
     */
    generatePlatformReport(platform, results) {
        let report = `## ${platform.toUpperCase()} Test Results\n\n`;
        
        report += `### Summary\n`;
        report += `- Total Tests: ${results.summary.total}\n`;
        report += `- Passed: ${results.summary.passed}\n`;
        report += `- Failed: ${results.summary.failed}\n`;
        report += `- Duration: ${results.duration?.toFixed(2)}s\n`;
        report += `- Pass Rate: ${((results.summary.passed / results.summary.total) * 100).toFixed(1)}%\n\n`;
        
        report += `### Test Details\n\n`;
        report += `| Test Suite | Status | Duration |\n`;
        report += `|------------|--------|----------|\n`;
        
        for (const [name, test] of Object.entries(results.tests)) {
            const status = test.passed ? '✅ PASSED' : '❌ FAILED';
            report += `| ${name} | ${status} | ${test.duration.toFixed(2)}s |\n`;
        }
        
        report += '\n';
        
        return report;
    }

    /**
     * List available test suites
     */
    listTestSuites() {
        console.log('📋 Available E2E UI Test Suites\n');
        
        console.log('iOS Test Suites:');
        console.log('  • Critical Path - Lost Lake Oregon flow');
        console.log('  • Platform Parity - iOS/CarPlay sync');
        console.log('  • Accessibility - VoiceOver compliance');
        console.log('  • Performance - Launch and load times');
        console.log('  • Error Recovery - Network and input handling\n');
        
        console.log('Android Test Suites:');
        console.log('  • Critical Path - Lost Lake Oregon flow');
        console.log('  • Platform Parity iOS - iOS behavior matching');
        console.log('  • Platform Parity Auto - Android Auto sync');
        console.log('  • Accessibility - TalkBack compliance');
        console.log('  • Performance - Launch and load times');
        console.log('  • Error Recovery - Network and input handling\n');
        
        console.log('Platform Options:');
        console.log('  • ios - Run iOS tests only');
        console.log('  • android - Run Android tests only');
        console.log('  • both - Run both platforms with parity validation\n');
    }

    /**
     * Clean test artifacts
     */
    cleanArtifacts() {
        console.log('🧹 Cleaning test artifacts...');
        
        // Clean iOS artifacts
        const iosResultsPath = path.join(this.basePath, 'mobile', 'ios', 'TestResults');
        if (fs.existsSync(iosResultsPath)) {
            this.exec(`rm -rf "${iosResultsPath}"`, { silent: true });
        }
        
        // Clean Android artifacts
        const androidResultsPath = path.join(this.basePath, 'mobile', 'android', 'app', 'build', 'reports');
        if (fs.existsSync(androidResultsPath)) {
            this.exec(`rm -rf "${androidResultsPath}"`, { silent: true });
        }
        
        // Clean local results (keep last 5)
        const results = fs.readdirSync(this.resultsPath)
            .filter(f => fs.statSync(path.join(this.resultsPath, f)).isDirectory())
            .sort()
            .reverse();
        
        if (results.length > 5) {
            results.slice(5).forEach(dir => {
                this.exec(`rm -rf "${path.join(this.resultsPath, dir)}"`, { silent: true });
            });
        }
        
        console.log('✅ Test artifacts cleaned\n');
    }
}

// CLI interface
async function main() {
    const args = process.argv.slice(2);
    const command = args[0];
    const runner = new E2EUITestRunner();
    
    switch (command) {
        case 'test':
        case 'run':
            const platform = args[1] || 'both';
            const options = {
                criticalOnly: args.includes('--critical'),
                skipBuild: args.includes('--skip-build'),
                skipSimulator: args.includes('--skip-simulator'),
                skipEmulator: args.includes('--skip-emulator'),
                failFast: args.includes('--fail-fast'),
                verbose: args.includes('--verbose')
            };
            
            const success = await runner.runTests(platform, options);
            process.exit(success ? 0 : 1);
            break;
            
        case 'list':
            runner.listTestSuites();
            break;
            
        case 'clean':
            runner.cleanArtifacts();
            break;
            
        case 'report':
            const reportPath = runner.resultsPath;
            console.log(`📁 Test results location: ${reportPath}`);
            const reports = fs.readdirSync(reportPath)
                .filter(f => fs.statSync(path.join(reportPath, f)).isDirectory())
                .sort()
                .reverse()
                .slice(0, 5);
            
            if (reports.length > 0) {
                console.log('\n📊 Recent test reports:');
                reports.forEach(report => {
                    console.log(`  • ${report}`);
                });
            } else {
                console.log('No test reports found. Run tests first.');
            }
            break;
            
        default:
            console.log(`
🧪 E2E UI Test Runner MCP Tool

A comprehensive end-to-end UI testing tool for iOS and Android platforms
with platform parity validation and detailed reporting.

Usage: node e2e-ui-test-runner <command> [options]

Commands:
  test <platform> [options]  Run E2E UI tests
  list                       List available test suites
  clean                      Clean test artifacts
  report                     Show recent test reports

Platforms:
  ios                        Run iOS tests only
  android                    Run Android tests only
  both                       Run both platforms with parity validation (default)

Options:
  --critical                 Run critical tests only
  --skip-build              Skip building apps (use existing builds)
  --skip-simulator          Skip iOS simulator boot check
  --skip-emulator           Skip Android emulator boot check
  --fail-fast               Stop on first test failure
  --verbose                 Show detailed output

Examples:
  node e2e-ui-test-runner test ios
  node e2e-ui-test-runner test android --critical
  node e2e-ui-test-runner test both --fail-fast
  node e2e-ui-test-runner list
  node e2e-ui-test-runner clean

For AI Agents:
  Always use 'test both' to ensure platform parity validation
  Run after every feature implementation
  Include test reports in feature completion documentation

Test Results:
  Reports are saved to: ${runner.resultsPath}
  Each run creates a timestamped directory with:
    - E2E_Test_Report.md (comprehensive report)
    - Test logs for each suite
    - Screenshots and artifacts
    - Platform parity validation results
`);
    }
}

// Export for use as module
module.exports = E2EUITestRunner;

// Run if called directly
if (require.main === module) {
    main().catch(error => {
        console.error('❌ Fatal error:', error);
        process.exit(1);
    });
}