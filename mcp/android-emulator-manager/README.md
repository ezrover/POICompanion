# Android Emulator Manager

An MCP tool that automates Android emulator operations for the Roadtrip-Copilot project. **Platform parity equivalent to ios-simulator-manager** - provides identical functionality for Android development and testing.

## Features

- **🚀 Automated Emulator Management**: Boot AVDs, install and launch apps with comprehensive monitoring
- **📊 Real-time Log Monitoring**: Stream and filter logcat output with crash detection and keyword highlighting  
- **📸 Screen Capture**: Take screenshots and device state snapshots for visual validation
- **🔍 App State Monitoring**: Check installation, runtime status, and crash detection
- **🎮 User Interaction Simulation**: Tap gestures, text input, and UI automation capabilities
- **🔨 Build Integration**: Automatically build APKs, install, and launch with validation
- **🧪 UI Testing Framework**: Automated test sequences for continuous speech and voice features
- **⚙️ Device Information**: Comprehensive Android device and system property reporting

## Prerequisites

- **Android SDK** with `adb` and `emulator` tools in PATH
- **Android Studio** with at least one AVD configured
- **Node.js** 14+ for running the MCP tool
- **Gradle** for building Android projects

## Quick Start

```bash
# Navigate to the Android Emulator Manager directory
cd /Users/naderrahimizad/Projects/AI/POICompanion/mcp/android-emulator-manager

# Full automation - build, install, launch with testing
node index.js full

# Launch on specific emulator without building  
node index.js launch Pixel_7_Pro_API_34

# Validate app functionality (build + launch + test)
node index.js validate

# Take a screenshot
node index.js screenshot continuous-speech-test.png

# List available emulators
node index.js list

# Get device information
node index.js info
```

## Command Line Interface

### Basic Operations

```bash
# List all available Android emulators (AVDs)
node index.js list

# Boot default emulator or specific device
node index.js boot                    # Boot first available AVD
node index.js boot Pixel_7_Pro_API_34 # Boot specific AVD

# Build the Android app using Gradle
node index.js build

# Install and launch app on active emulator
node index.js install

# Combined boot + install + launch
node index.js launch [device_name]
```

### Testing & Validation

```bash
# Comprehensive app validation (recommended)
node index.js validate

# Run UI automation tests
node index.js test

# Full end-to-end testing workflow
node index.js full [device_name]

# Take screenshot for visual verification
node index.js screenshot [filename]

# Get comprehensive device information
node index.js info

# Clean shutdown and resource cleanup
node index.js cleanup
```

### Advanced Usage Examples

```bash
# Test continuous speech feature specifically
node index.js full Pixel_7_Pro_API_34

# Quick validation without full testing
node index.js validate

# Screenshot with custom filename
node index.js screenshot "voice-listening-$(date +%Y%m%d-%H%M%S).png"

# Build and validate on specific device
node index.js build && node index.js launch Pixel_6_API_33 && node index.js validate
```

## Programmatic Usage

```javascript
const AndroidEmulatorManager = require('./index.js');

const manager = new AndroidEmulatorManager();

// Full automation flow with options
await manager.runFullFlow({
    deviceName: 'Pixel_7_Pro_API_34',
    buildFirst: true,
    runTests: true,
    takeScreenshots: true,
    monitorLogs: true
});

// Individual operations
await manager.bootEmulator('Pixel_7_Pro_API_34');
await manager.buildApp();
await manager.installAndLaunchApp();
const isValid = await manager.validateApp();
await manager.takeScreenshot('validation-screenshot.png');

// Device information and state
const deviceInfo = await manager.getDeviceInfo();
const isRunning = await manager.isAppRunning();
const hasCrashes = await manager.detectCrashes();

// UI automation
await manager.runUITest([
    { action: 'tap', x: 200, y: 800, description: 'Tap voice button' },
    { action: 'wait', duration: 2000 },
    { action: 'screenshot', filename: 'voice-active.png' },
    { action: 'validate' }
]);

// Cleanup
await manager.cleanup();
```

## Platform Parity Features

This tool provides **100% functional equivalence** with the iOS Simulator Manager:

| Feature | iOS Simulator Manager | Android Emulator Manager | Status |
|---------|----------------------|---------------------------|---------|
| **Device Listing** | `listSimulators()` | `listEmulators()` | ✅ Equivalent |
| **Device Boot** | `bootSimulator()` | `bootEmulator()` | ✅ Equivalent |  
| **App Building** | `buildApp()` (Xcode) | `buildApp()` (Gradle) | ✅ Equivalent |
| **App Installation** | `installAndLaunchApp()` | `installAndLaunchApp()` | ✅ Equivalent |
| **Validation Testing** | `validateAppLaunch()` | `validateApp()` | ✅ Equivalent |
| **Crash Detection** | `monitorForCrashes()` | `detectCrashes()` | ✅ Equivalent |
| **Screenshot Capture** | `takeScreenshot()` | `takeScreenshot()` | ✅ Equivalent |
| **UI Automation** | `runUITest()` | `runUITest()` | ✅ Equivalent |
| **Device Information** | iOS device properties | `getDeviceInfo()` | ✅ Equivalent |
| **Log Monitoring** | `startLogMonitoring()` | `startLogMonitoring()` | ✅ Equivalent |
| **Cleanup & Shutdown** | Simulator cleanup | `cleanup()` | ✅ Equivalent |

## Continuous Speech Testing

The tool includes specialized testing for the **continuous speech listening feature** to maintain platform parity:

```bash
# Test continuous speech functionality
node index.js full

# Manual continuous speech test sequence
node index.js test
```

**Test Sequence**:
1. **Launch App** → Verify app starts successfully
2. **Navigate to Destination Screen** → Ensure proper screen transition  
3. **Activate Voice Button** → Tap coordinates for voice input
4. **Monitor Speech State** → Visual verification of listening animation
5. **Validate Continuous Listening** → Ensure speech doesn't stop after first input
6. **Test Navigation Commands** → Verify "go", "navigate", "start" command detection
7. **Screenshot Documentation** → Capture state for visual validation

## Android Auto Integration Testing

```bash
# Test Android Auto functionality (when available)
node index.js full --android-auto

# Validate automotive templates and voice commands
node index.js test --automotive-mode
```

## Configuration

The tool automatically detects:
- **Project Root**: `/Users/naderrahimizad/Projects/AI/POICompanion`
- **Android Project Path**: `mobile/android`
- **Package Name**: `com.roadtrip.copilot`
- **Main Activity**: `.MainActivity`
- **APK Location**: `app/build/outputs/apk/debug/app-debug.apk`

### Environment Variables

```bash
# Optional: Specify Android SDK path
export ANDROID_SDK_ROOT=/path/to/android-sdk

# Optional: Specify AVD path
export ANDROID_AVD_HOME=/path/to/avd

# Optional: Custom emulator timeout
export EMULATOR_BOOT_TIMEOUT=120000
```

## Troubleshooting

### Common Issues

**Emulator Won't Boot**:
```bash
# Check available AVDs
node index.js list

# Ensure Android emulator is in PATH
emulator -list-avds

# Cold boot if needed
emulator -avd Your_AVD_Name -wipe-data
```

**App Installation Fails**:
```bash
# Build first
node index.js build

# Check APK exists
ls mobile/android/app/build/outputs/apk/debug/

# Manual installation
adb install -r mobile/android/app/build/outputs/apk/debug/app-debug.apk
```

**ADB Connection Issues**:
```bash
# Restart ADB server
adb kill-server && adb start-server

# Check connected devices
adb devices

# Reset emulator connection
adb disconnect && adb connect
```

**Speech Testing Issues**:
```bash
# Enable microphone permissions
adb shell pm grant com.roadtrip.copilot android.permission.RECORD_AUDIO

# Check logcat for speech recognition errors
adb logcat | grep -i speech
```

### Performance Optimization

- **Use Hardware Acceleration**: Ensure HAXM/Hypervisor is enabled
- **Allocate Sufficient RAM**: 4GB+ recommended for smooth operation
- **Enable GPU Acceleration**: Use `-gpu host` for better graphics performance
- **Optimize AVD Configuration**: Use appropriate API level and system images

## Integration with Development Workflow

### Mobile Build Verifier Integration

```bash
# Use with mobile-build-verifier for comprehensive testing
node /mcp/mobile-build-verifier/index.js android --clean
node index.js validate
```

### MCP Server Integration

Add to `.claude/settings.local.json`:

```json
{
  "mcpServers": {
    "android-emulator-manager": {
      "command": "node",
      "args": ["/Users/naderrahimizad/Projects/AI/POICompanion/mcp/android-emulator-manager/index.js"]
    }
  }
}
```

## API Reference

### Core Methods

- **`listEmulators()`** → Array of available Android emulators with status
- **`bootEmulator(deviceName?)`** → Boot specified or default emulator
- **`buildApp()`** → Build Android APK using Gradle
- **`installAndLaunchApp()`** → Install and launch app with validation
- **`validateApp(timeoutMs?)`** → Comprehensive app functionality validation
- **`detectCrashes()`** → Check logcat for crash indicators and exceptions
- **`takeScreenshot(filename?)`** → Capture emulator screen state
- **`runUITest(testSteps[])`** → Execute automated UI interaction sequence
- **`getDeviceInfo()`** → Comprehensive device and system information
- **`cleanup()`** → Clean shutdown and resource management

### Test Step Actions

```javascript
// Available test step actions for runUITest()
const testSteps = [
    { action: 'tap', x: 100, y: 200, description: 'Tap button' },
    { action: 'type', text: 'Hello World', description: 'Enter text' },
    { action: 'wait', duration: 3000, description: 'Wait 3 seconds' },
    { action: 'screenshot', filename: 'state.png', description: 'Capture state' },
    { action: 'validate', description: 'Check app is running' }
];
```

## Contributing

This tool maintains **strict platform parity** with iOS Simulator Manager. Any new features must be implemented equivalently in both tools.

### Development Guidelines

1. **Feature Parity**: Every iOS simulator feature must have Android equivalent
2. **Error Handling**: Comprehensive error recovery and user-friendly messages
3. **Performance**: Efficient resource usage and cleanup procedures
4. **Testing**: All features must be testable through automated sequences
5. **Documentation**: Complete API documentation and usage examples

## Platform Parity Validation

To verify platform parity with iOS:

```bash
# Run both tools and compare capabilities
node /mcp/ios-simulator-manager/index.js --help
node /mcp/android-emulator-manager/index.js help

# Test equivalent functionality
node /mcp/ios-simulator-manager/index.js run --screenshot  
node /mcp/android-emulator-manager/index.js full

# Compare output and feature coverage
```

## License

ISC - Platform parity maintained with ios-simulator-manager under same licensing terms.