# iOS Simulator Manager

An MCP tool that automates iOS simulator operations for the Roadtrip-Copilot project.

## Features

- **Automated Simulator Management**: Boot simulators, install and launch apps
- **Real-time Log Monitoring**: Stream and filter simulator logs with keyword highlighting
- **Screen Capture**: Take screenshots and record videos of the simulator
- **App State Monitoring**: Check installation and runtime status
- **User Interaction Simulation**: Tap gestures and text input simulation
- **Build Integration**: Automatically build, install, and launch apps

## Usage

### Command Line Interface

```bash
# Full automation - build, install, launch with screenshot
node ios-simulator-manager.js run --screenshot

# Launch on specific device without building
node ios-simulator-manager.js run "iPhone 15 Pro" --no-build

# Monitor logs only
node ios-simulator-manager.js logs "Speech"

# Take a screenshot
node ios-simulator-manager.js screenshot ~/Desktop/app.png

# List available simulators
node ios-simulator-manager.js list

# Get app state
node ios-simulator-manager.js state

# Reset simulator to clean state
node ios-simulator-manager.js reset
```

### Programmatic Usage

```javascript
const IOSSimulatorManager = require('./index.js');

const manager = new IOSSimulatorManager();

// Full automation flow
await manager.runFullFlow({
    deviceName: 'iPhone 16',
    screenshot: true,
    monitoring: true,
    build: true
});

// Individual operations
await manager.bootSimulator('iPhone 16');
await manager.buildApp();
await manager.installAndLaunchApp();
await manager.startLogMonitoring('Roadtrip-Copilot');
const screenshotPath = await manager.takeScreenshot();
```

## Key Features for AI Development

### Build Verification
- Automatically detects correct Xcode scheme and bundle identifier
- Builds for iOS Simulator with proper configuration
- Handles build errors with detailed reporting

### Log Monitoring
- Real-time log streaming with intelligent filtering
- Highlights errors, warnings, and app-specific messages
- Filters for relevant keywords (Speech, CarPlay, Destination, etc.)

### Visual Verification
- Screenshots for UI verification
- Video recording for interaction flows
- Screen capture at specific moments in app lifecycle

### App State Tracking
- Installation status verification
- Runtime state monitoring
- App container path resolution

## Integration with Mobile Development Workflow

This tool integrates seamlessly with the existing mobile development workflow:

1. **Build Verification**: Use after `mobile-build-verifier` succeeds
2. **Testing**: Combine with `mobile-test-runner` for end-to-end testing
3. **Debugging**: Real-time log monitoring during development
4. **Documentation**: Screenshot capture for specs and documentation

## Error Handling

The tool provides comprehensive error handling:
- Build failure detection with suggested fixes
- Simulator boot timeout handling
- App installation verification
- Log streaming error recovery

## Configuration

The tool automatically detects:
- Project structure and paths
- Xcode scheme names (`RoadtripCopilot`)
- Bundle identifiers (`com.hmi2.roadtrip-copilot`)
- Available simulators and their states

## Performance Considerations

- Uses background processes for log monitoring
- Implements proper process cleanup on exit
- Handles simulator state caching for efficiency
- Provides timeout controls for long-running operations

## Future Enhancements

- CarPlay simulator integration
- Automated UI testing with gesture sequences
- Performance metrics collection
- Integration with CI/CD pipelines
- Multi-device testing coordination