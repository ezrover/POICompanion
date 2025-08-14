#!/usr/bin/env node

const { exec, execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

/**
 * Enhanced Mobile Build Verifier with Intelligent Analysis
 * 
 * Features:
 * - Cross-platform build verification (iOS & Android)
 * - Intelligent error analysis and categorization
 * - Build history tracking and trend analysis
 * - Automatic fix suggestions and implementations
 * - Performance metrics and success rate monitoring
 * - Integration with specialized iOS and Android project managers
 */

// Check if the correct number of arguments are provided
if (process.argv.length < 3) {
    console.error('Usage: node mobile-build-verifier <platform|both> [options]');
    console.error('');
    console.error('Platforms:');
    console.error('  ios       Build iOS project only');
    console.error('  android   Build Android project only');
    console.error('  both      Build both iOS and Android projects');
    console.error('');
    console.error('Options:');
    console.error('  --fix        Attempt automatic fixes for common issues');
    console.error('  --history    Show build history and trends');
    console.error('  --clean      Clean before building');
    console.error('  --detailed   Show detailed error analysis');
    console.error('');
    console.error('Examples:');
    console.error('  node mobile-build-verifier ios --clean');
    console.error('  node mobile-build-verifier both --fix --history');
    console.error('  node mobile-build-verifier android --detailed');
    process.exit(1);
}

const platform = process.argv[2];
const shouldAutoFix = process.argv.includes('--fix');
const showHistory = process.argv.includes('--history');
const shouldClean = process.argv.includes('--clean');
const detailedAnalysis = process.argv.includes('--detailed');

const projectRoot = path.resolve(__dirname, '..', '..');
const iosProjectManager = path.join(__dirname, '../ios-project-manager/index.js');
const androidProjectManager = path.join(__dirname, '../android-project-manager/index.js');
const historyDir = path.join(__dirname, 'build-history');

// Ensure history directory exists
if (!fs.existsSync(historyDir)) {
    fs.mkdirSync(historyDir, { recursive: true });
}

// Initialize build history tracking
function loadBuildHistory(platformName) {
    const historyFile = path.join(historyDir, `${platformName}-build-history.json`);
    try {
        return JSON.parse(fs.readFileSync(historyFile, 'utf8'));
    } catch {
        return { 
            builds: [], 
            commonErrors: {}, 
            successRate: 0,
            avgBuildTime: 0,
            lastSuccessful: null,
            trends: {
                improving: false,
                recentFailures: 0
            }
        };
    }
}

function saveBuildHistory(history, platformName) {
    const historyFile = path.join(historyDir, `${platformName}-build-history.json`);
    
    // Calculate metrics
    const recentBuilds = history.builds.slice(-20);
    history.successRate = recentBuilds.length > 0 
        ? (recentBuilds.filter(b => b.success).length / recentBuilds.length * 100)
        : 0;
    
    const successfulBuilds = recentBuilds.filter(b => b.success && b.duration);
    history.avgBuildTime = successfulBuilds.length > 0
        ? successfulBuilds.reduce((sum, b) => sum + b.duration, 0) / successfulBuilds.length
        : 0;
    
    const lastSuccess = history.builds.slice().reverse().find(b => b.success);
    history.lastSuccessful = lastSuccess ? lastSuccess.timestamp : null;
    
    // Trend analysis
    const last5 = history.builds.slice(-5);
    const prev5 = history.builds.slice(-10, -5);
    const recent5Success = last5.filter(b => b.success).length;
    const prev5Success = prev5.filter(b => b.success).length;
    history.trends.improving = recent5Success > prev5Success;
    history.trends.recentFailures = last5.filter(b => !b.success).length;
    
    fs.writeFileSync(historyFile, JSON.stringify(history, null, 2));
}

// Enhanced error analysis with more comprehensive patterns
function analyzeErrors(stderr, stdout, platformName) {
    const errorPatterns = {
        // iOS specific errors
        'ios-missing-files': /cannot find.*\.swift|no such file.*\.swift/i,
        'ios-xcode-signing': /signing|provisioning|certificate|code sign/i,
        'ios-swift-compile': /swift compiler error|cannot convert|type.*does not conform/i,
        'ios-dependency': /pod install|cocoapods/i,
        'ios-version-compat': /is only available in.*or newer|'.*' was introduced in/i,
        
        // Android specific errors  
        'android-gradle': /gradle.*failed|daemon.*failed/i,
        'android-kotlin-compile': /compilation error|unresolved reference|type mismatch/i,
        'android-dependency': /cannot find.*dependency|failed to resolve/i,
        'android-manifest': /androidmanifest|manifest merger failed/i,
        'android-resources': /resource.*not found|failed to process resources/i,
        
        // Common errors
        'missing-dependency': /cannot find|unresolved|missing.*dependency/i,
        'compilation-error': /compilation.*failed|syntax error/i,
        'permission-denied': /permission denied|access denied/i,
        'network-timeout': /timeout|network.*error|connection.*failed/i,
        'out-of-memory': /out of memory|java heap space/i
    };
    
    const detectedErrors = [];
    const fullOutput = stderr + stdout;
    
    for (const [errorType, pattern] of Object.entries(errorPatterns)) {
        if (pattern.test(fullOutput)) {
            detectedErrors.push(errorType);
        }
    }
    
    return detectedErrors;
}

// Enhanced warning analysis with specific patterns and fix suggestions
function analyzeWarnings(buildOutput, platformName) {
    const warningPatterns = {
        // iOS specific warnings
        'deprecated-api': /is deprecated|deprecated in iOS|was deprecated/i,
        'unused-variable': /unused variable|never used|assigned but never used/i,
        'unused-import': /unused import|imported but never used/i,
        'force-unwrapping': /force unwrapping|using '!' is not recommended/i,
        'accessibility': /accessibility|VoiceOver|missing accessibility/i,
        'autolayout': /constraint.*priority|ambiguous layout|unable to satisfy constraints/i,
        'memory-warnings': /memory warning|retain cycle|strong reference cycle/i,
        'thread-safety': /main thread|background thread|not thread safe/i,
        'xcode-destinations': /using the first of multiple matching destinations/i,
        
        // Android specific warnings
        'android-deprecated': /deprecated.*android|was deprecated in API/i,
        'android-unused': /unused.*resource|unused parameter/i,
        'android-lint': /lint.*warning|consider using/i,
        'android-version': /requires API level|minimum supported/i,
        'android-security': /security.*warning|insecure|cleartext/i,
        
        // Common warnings
        'unused-code': /unused|never.*used|dead code/i,
        'type-mismatch': /type.*mismatch|implicit.*conversion/i,
        'format-string': /format.*string|printf.*format/i,
        'comparison': /comparison.*always|tautological/i
    };
    
    const detectedWarnings = [];
    const suggestions = [];
    
    for (const [warningType, pattern] of Object.entries(warningPatterns)) {
        if (pattern.test(buildOutput)) {
            detectedWarnings.push(warningType);
        }
    }
    
    // Provide specific suggestions based on detected warnings
    const warningSuggestions = {
        'deprecated-api': 'Replace deprecated APIs with newer alternatives. Check Apple/Google documentation for migration guides.',
        'unused-variable': 'Remove unused variables or prefix with underscore (_) if intentionally unused.',
        'unused-import': 'Remove unused import statements to clean up code.',
        'force-unwrapping': 'Replace force unwrapping (!) with safe unwrapping (if let, guard let, or ?? nil coalescing).',
        'accessibility': 'Add accessibility labels and hints for VoiceOver support.',
        'autolayout': 'Review Auto Layout constraints for conflicts or missing priorities.',
        'memory-warnings': 'Check for retain cycles, use weak/unowned references appropriately.',
        'thread-safety': 'Ensure UI updates happen on main thread, use DispatchQueue.main.async.',
        'xcode-destinations': 'Specify exact destination with -destination flag to avoid ambiguity (e.g., -destination "platform=iOS Simulator,name=iPhone 16 Pro").',
        'android-deprecated': 'Update deprecated Android APIs to newer equivalents.',
        'android-unused': 'Remove unused resources or code to reduce APK size.',
        'android-lint': 'Run Android Lint and follow suggestions for best practices.',
        'android-version': 'Consider raising minimum SDK version or provide compatibility shims.',
        'android-security': 'Review security practices, avoid cleartext traffic, use HTTPS.',
        'unused-code': 'Remove unused functions, variables, and imports to clean up codebase.',
        'type-mismatch': 'Add explicit type conversions or check type compatibility.',
        'format-string': 'Use proper format specifiers in string formatting.',
        'comparison': 'Review comparison logic for potential logical errors.'
    };
    
    detectedWarnings.forEach(warning => {
        if (warningSuggestions[warning]) {
            suggestions.push(warningSuggestions[warning]);
        }
    });
    
    return suggestions;
}

function suggestFixes(errors, platformName) {
    const fixes = {
        // iOS fixes
        'ios-missing-files': `Add missing files to Xcode project: node ${path.relative(process.cwd(), iosProjectManager)} add-file <filepath> <group>`,
        'ios-xcode-signing': 'Check signing certificates in Xcode → Preferences → Accounts',
        'ios-swift-compile': 'Check Swift syntax and imports in recently modified files',
        'ios-dependency': 'Run: cd mobile/ios && pod install',
        'ios-version-compat': 'Update minimum iOS version in project settings or use backward-compatible APIs',
        
        // Android fixes
        'android-gradle': 'Run: cd mobile/android && ./gradlew --stop && ./gradlew clean',
        'android-kotlin-compile': 'Check Kotlin syntax and imports in recently modified files',
        'android-dependency': 'Update dependencies in build.gradle files',
        'android-manifest': 'Check AndroidManifest.xml for conflicts or missing permissions',
        'android-resources': 'Check resource files for naming conflicts or missing resources',
        
        // Common fixes
        'missing-dependency': `Install dependencies: ${platformName === 'ios' ? 'pod install' : './gradlew build --refresh-dependencies'}`,
        'compilation-error': 'Check syntax and imports in recent changes',
        'permission-denied': 'Run: chmod +x ./gradlew (Android) or check Xcode permissions (iOS)',
        'network-timeout': 'Check internet connection and retry build',
        'out-of-memory': 'Increase build memory: export GRADLE_OPTS="-Xmx4g" (Android) or close other applications'
    };
    
    return errors.map(error => fixes[error] || 'Manual investigation required - check full build output');
}

async function buildPlatform(platformName) {
    console.log(`🔍 Verifying ${platformName} build...`);
    
    const history = loadBuildHistory(platformName);
    const buildStart = new Date();
    const buildResult = {
        timestamp: buildStart.toISOString(),
        platform: platformName,
        success: false,
        duration: 0,
        errors: [],
        fixes: [],
        warnings: 0,
        warningDetails: [],
        warningSuggestions: []
    };
    
    try {
        // Clean if requested
        if (shouldClean) {
            console.log(`🧹 Cleaning ${platformName} project...`);
            if (platformName === 'ios') {
                execSync(`node "${iosProjectManager}" clean`, { stdio: 'pipe' });
            } else {
                execSync(`node "${androidProjectManager}" clean`, { stdio: 'pipe' });
            }
            console.log('   ✅ Clean completed');
        }
        
        // Build using specialized project managers
        console.log(`🔨 Building ${platformName}...`);
        let buildOutput;
        
        if (platformName === 'ios') {
            buildOutput = execSync(`node "${iosProjectManager}" build`, { 
                encoding: 'utf8', 
                stdio: 'pipe'
            });
        } else {
            buildOutput = execSync(`node "${androidProjectManager}" build`, { 
                encoding: 'utf8',
                stdio: 'pipe' 
            });
        }
        
        buildResult.success = true;
        buildResult.duration = (Date.now() - buildStart.getTime()) / 1000;
        
        // Enhanced warning extraction and analysis
        const warningMatches = buildOutput.match(/(warning:|WARNING:).*$/gmi) || [];
        buildResult.warnings = warningMatches.length;
        buildResult.warningDetails = warningMatches;
        
        console.log(`✅ ${platformName.toUpperCase()} build successful (${buildResult.duration.toFixed(1)}s)`);
        
        if (buildResult.warnings > 0) {
            console.log(`   ⚠️  ${buildResult.warnings} warnings detected`);
            console.log(`\n📋 Build Warnings Details:`);
            
            // Group similar warnings and show unique ones with counts
            const warningGroups = {};
            warningMatches.forEach(warning => {
                // Clean up the warning message
                const cleanWarning = warning.replace(/^.*warning:\s*/i, '').trim();
                const shortWarning = cleanWarning.length > 120 ? cleanWarning.substring(0, 120) + '...' : cleanWarning;
                
                if (warningGroups[shortWarning]) {
                    warningGroups[shortWarning].count++;
                } else {
                    warningGroups[shortWarning] = { count: 1, fullText: cleanWarning };
                }
            });
            
            Object.entries(warningGroups).forEach(([warning, info], index) => {
                const countStr = info.count > 1 ? ` (${info.count}x)` : '';
                console.log(`   ${index + 1}. ${warning}${countStr}`);
            });
            
            // Provide warning fix suggestions
            console.log(`\n💡 Warning Fix Suggestions:`);
            const warningSuggestions = analyzeWarnings(buildOutput, platformName);
            buildResult.warningSuggestions = warningSuggestions;
            
            if (warningSuggestions.length > 0) {
                warningSuggestions.forEach((suggestion, i) => console.log(`   ${i + 1}. ${suggestion}`));
            } else {
                console.log('   Most warnings can be safely addressed by reviewing deprecated API usage');
            }
        }
        
    } catch (error) {
        const detectedErrors = analyzeErrors(error.stderr || '', error.stdout || '', platformName);
        const suggestedFixes = suggestFixes(detectedErrors, platformName);
        
        buildResult.errors = detectedErrors;
        buildResult.fixes = suggestedFixes;
        buildResult.duration = (Date.now() - buildStart.getTime()) / 1000;
        
        // Update error frequency tracking
        detectedErrors.forEach(errorType => {
            history.commonErrors[errorType] = (history.commonErrors[errorType] || 0) + 1;
        });
        
        console.error(`❌ ${platformName.toUpperCase()} build failed (${buildResult.duration.toFixed(1)}s)`);
        console.error(`\n🔍 Detected Error Types: ${detectedErrors.length > 0 ? detectedErrors.join(', ') : 'No specific errors detected'}`);
        console.error(`\n💡 Suggested Fixes:`);
        if (suggestedFixes.length > 0) {
            suggestedFixes.forEach((fix, i) => console.error(`   ${i + 1}. ${fix}`));
        } else {
            console.error('   Manual investigation required - check detailed output below');
        }
        
        // ALWAYS show detailed error output on failure (not just with --detailed flag)
        console.error('\n📋 Detailed Error Output:');
        const errorOutput = error.stderr || error.stdout || 'No detailed output available';
        
        // For iOS, extract the actual Swift compilation errors
        if (platformName === 'ios') {
            // Try to get more detailed error info by running swiftc directly on problem files
            try {
                console.error('\n🔴 Attempting to get detailed Swift errors...');
                const swiftErrorCmd = `cd /Users/naderrahimizad/Projects/AI/POICompanion/mobile/ios && xcodebuild -scheme RoadtripCopilot -sdk iphonesimulator -configuration Debug build 2>&1 | grep -A3 -B1 "error:"`;
                const swiftErrors = execSync(swiftErrorCmd, { encoding: 'utf8', stdio: 'pipe' });
                if (swiftErrors) {
                    console.error('🔴 Swift Compilation Errors Found:');
                    console.error(swiftErrors);
                }
            } catch (detailError) {
                // If grep finds errors, it will be in the output
                if (detailError.stdout) {
                    console.error('🔴 Swift Compilation Errors:');
                    console.error(detailError.stdout);
                }
            }
        }
        
        // Show truncated output if very long
        if (errorOutput.length > 5000) {
            console.error(errorOutput.substring(errorOutput.length - 5000));
            console.error('\n... (output truncated, showing last 5000 characters)');
        } else {
            console.error(errorOutput);
        }
        
        if (shouldAutoFix) {
            console.log('\n🛠️ Attempting automatic fixes...');
            await attemptAutoFixes(detectedErrors, platformName);
        }
    }
    
    // Save build history
    history.builds.push(buildResult);
    if (history.builds.length > 100) {
        history.builds = history.builds.slice(-100); // Keep last 100 builds
    }
    saveBuildHistory(history, platformName);
    
    return buildResult;
}

async function attemptAutoFixes(errors, platformName) {
    for (const error of errors) {
        console.log(`   🔧 Attempting fix for: ${error}`);
        
        try {
            switch (error) {
                case 'ios-dependency':
                    execSync('cd mobile/ios && pod install', { stdio: 'inherit' });
                    console.log('   ✅ Pod install completed');
                    break;
                    
                case 'android-gradle':
                    execSync('cd mobile/android && ./gradlew --stop', { stdio: 'pipe' });
                    execSync('cd mobile/android && ./gradlew clean', { stdio: 'pipe' });
                    console.log('   ✅ Gradle daemon restarted and project cleaned');
                    break;
                    
                case 'permission-denied':
                    if (platformName === 'android') {
                        execSync('chmod +x mobile/android/gradlew', { stdio: 'pipe' });
                        console.log('   ✅ Gradle wrapper permissions fixed');
                    }
                    break;
                    
                default:
                    console.log(`   ⚠️  No automatic fix available for: ${error}`);
            }
        } catch (fixError) {
            console.log(`   ❌ Auto-fix failed for ${error}: ${fixError.message}`);
        }
    }
}

function showBuildHistory(platformName) {
    const history = loadBuildHistory(platformName);
    const recentBuilds = history.builds.slice(-10);
    
    console.log(`\n📊 ${platformName.toUpperCase()} Build History:`);
    console.log(`   Success Rate: ${history.successRate.toFixed(1)}% (recent builds)`);
    console.log(`   Avg Build Time: ${history.avgBuildTime.toFixed(1)}s`);
    console.log(`   Last Successful: ${history.lastSuccessful ? new Date(history.lastSuccessful).toLocaleString() : 'Never'}`);
    console.log(`   Recent Failures: ${history.trends.recentFailures}`);
    console.log(`   Trend: ${history.trends.improving ? '📈 Improving' : '📉 Declining'}`);
    
    if (Object.keys(history.commonErrors).length > 0) {
        console.log('\n🚨 Most Common Errors:');
        Object.entries(history.commonErrors)
            .sort(([,a], [,b]) => b - a)
            .slice(0, 5)
            .forEach(([error, count]) => {
                console.log(`   ${error}: ${count} occurrences`);
            });
    }
    
    if (recentBuilds.length > 0) {
        console.log('\n📈 Recent Build Results:');
        recentBuilds.slice(-5).forEach(build => {
            const status = build.success ? '✅' : '❌';
            const date = new Date(build.timestamp).toLocaleString();
            const duration = build.duration ? `(${build.duration.toFixed(1)}s)` : '';
            console.log(`   ${status} ${date} ${duration}`);
        });
    }
}

// Main execution logic
async function main() {
    if (platform === 'both') {
        console.log('🔄 Building both iOS and Android platforms...');
        
        const [iosResult, androidResult] = await Promise.allSettled([
            buildPlatform('ios'),
            buildPlatform('android')
        ]);
        
        console.log('\n📊 Cross-Platform Build Summary:');
        console.log(`   iOS: ${iosResult.status === 'fulfilled' && iosResult.value.success ? '✅ SUCCESS' : '❌ FAILED'}`);
        console.log(`   Android: ${androidResult.status === 'fulfilled' && androidResult.value.success ? '✅ SUCCESS' : '❌ FAILED'}`);
        
        const overallSuccess = iosResult.status === 'fulfilled' && iosResult.value.success &&
                              androidResult.status === 'fulfilled' && androidResult.value.success;
        
        if (overallSuccess) {
            console.log('\n🎉 All platforms built successfully!');
        } else {
            console.log('\n⚠️  Some builds failed. Check platform-specific errors above.');
            process.exit(1);
        }
        
        if (showHistory) {
            showBuildHistory('ios');
            showBuildHistory('android');
        }
        
    } else {
        // Single platform build or help
        if (platform === "help" || platform === "--help" || platform === "-h") {
            showUsageHelp();
            return;
        }
        
        if (!["ios", "android"].includes(platform)) {
            console.error(`Unknown platform: ${platform}`);
            console.error("Supported platforms: ios, android, both");
            showUsageHelp();
            process.exit(1);
        }        
        const result = await buildPlatform(platform);
        
        if (showHistory) {
            showBuildHistory(platform);
        }
        
        if (!result.success) {
            process.exit(1);
        }
    }
}

// Run main function
main().catch(error => {
    console.error('❌ Build verifier error:', error.message);
    process.exit(1);
});


function showUsageHelp() {
    console.log(`
📱🤖 Enhanced Mobile Build Verifier

USAGE:
  node mobile-build-verifier <platform> [options]

PLATFORMS:
  ios       Build iOS project only
  android   Build Android project only  
  both      Build both iOS and Android projects

OPTIONS:
  --fix        Attempt automatic fixes for common issues
  --history    Show build history and trend analysis
  --clean      Clean before building
  --detailed   Show detailed error output for debugging

EXAMPLES:
  node mobile-build-verifier ios
  node mobile-build-verifier both --fix
  node mobile-build-verifier android --clean --history
  node mobile-build-verifier ios --detailed --fix

FEATURES:
  🎯 Cross-platform coordination     Build both platforms simultaneously
  🔍 Intelligent error analysis     Categorize and fix common build issues
  📊 Build history tracking         Monitor success rates and trends
  🛠️ Automatic fix attempts         Resolve common problems automatically
  📈 Performance metrics           Track build times and optimization
  💡 Actionable recommendations    Get specific fix suggestions

This tool transforms mobile development from reactive debugging to proactive
build management with intelligent automation and comprehensive analytics.
`);
}
