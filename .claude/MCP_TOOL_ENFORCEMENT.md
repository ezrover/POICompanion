# MCP Tool Enforcement for iOS and Android Developers

## 🔴 CRITICAL: MANDATORY MCP TOOL USAGE

All iOS and Android developer agents MUST use MCP tools for ALL operations. Direct command execution is STRICTLY PROHIBITED.

## iOS Developer Agent Requirements

### Required MCP Tools

1. **ios_project_manage** - MANDATORY for file operations
   - `add-files`: Add new Swift/SwiftUI files to Xcode project
   - `sync-project`: Verify build after adding files
   - `update-plist`: Modify Info.plist
   - `add-deps`: Add CocoaPods dependencies

2. **ios_simulator_test** - MANDATORY for testing
   - `lost-lake-test`: Run complete Lost Lake flow
   - `validate-buttons`: Check button implementations
   - `test-accessibility`: Test with VoiceOver
   - `test-carplay`: Test CarPlay integration

3. **mobile_build_verify** - MANDATORY for builds
   - Use with `platform: "ios"`
   - NEVER use `xcodebuild` directly

4. **e2e_ui_test_run** - MANDATORY for E2E tests
   - Use with `platform: "ios"` or `"both"`

### Prohibited Commands (AUTOMATIC TASK FAILURE)
- ❌ `xcodebuild`
- ❌ `xcrun simctl`
- ❌ `swift build/test`
- ❌ Manual `.pbxproj` editing
- ❌ `pod install`

### Required Workflow
1. Create files with Write/Edit tools
2. Use `ios_project_manage` with `action: "add-files"`
3. Verify with `ios_project_manage` with `action: "sync-project"`
4. Test with `ios_simulator_test`

## Android Developer Agent Requirements

### Required MCP Tools

1. **android_project_manage** - MANDATORY for file operations
   - `add-files`: Add new Kotlin files to project
   - `sync-gradle`: Sync gradle after changes
   - `update-manifest`: Modify AndroidManifest.xml
   - `add-deps`: Add gradle dependencies

2. **android_emulator_test** - MANDATORY for testing
   - `lost-lake-test`: Run complete Lost Lake flow
   - `validate-components`: Check UI components
   - `monitor-performance`: Monitor app performance
   - `test-voice-interface`: Test voice recognition

3. **mobile_build_verify** - MANDATORY for builds
   - Use with `platform: "android"`
   - NEVER use `./gradlew` directly

4. **e2e_ui_test_run** - MANDATORY for E2E tests
   - Use with `platform: "android"` or `"both"`

### Prohibited Commands (AUTOMATIC TASK FAILURE)
- ❌ `./gradlew`
- ❌ `adb` commands
- ❌ Manual gradle file editing
- ❌ Direct emulator launching

### Required Workflow
1. Create files with Write/Edit tools
2. Use `android_project_manage` with `action: "add-files"`
3. Verify with `android_project_manage` with `action: "sync-gradle"`
4. Test with `android_emulator_test`

## Enforcement

- The `agent-judge` agent will validate MCP tool usage
- Any direct command execution results in IMMEDIATE TASK FAILURE
- All file additions MUST use project management tools
- All testing MUST use simulator/emulator tools
- All builds MUST use build verification tools

## Example Usage

### iOS File Addition
```javascript
// ✅ CORRECT
mcp__poi-companion__ios_project_manage({
  "action": "add-files",
  "files": ["RoadtripCopilot/NewFeature.swift"],
  "targetName": "RoadtripCopilot",
  "group": "Features"
})

// ❌ WRONG - TASK FAILURE
bash("xcodebuild -project RoadtripCopilot.xcodeproj")
```

### Android Testing
```javascript
// ✅ CORRECT
mcp__poi-companion__android_emulator_test({
  "action": "lost-lake-test"
})

// ❌ WRONG - TASK FAILURE
bash("./gradlew connectedAndroidTest")
```

## Summary

The MCP server provides comprehensive tools for iOS and Android development. These tools:
- Eliminate the need for direct command execution
- Ensure consistent project management
- Provide simulated test results when actual devices aren't available
- Maintain platform parity through standardized workflows

All developer agents MUST use these tools exclusively. Violation of this policy results in immediate task failure and potential agent termination.