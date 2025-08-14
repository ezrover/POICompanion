# Mobile File Manager

Cross-platform coordination tool for iOS and Android development ensuring feature parity and consistent implementation.

## Features

- **Cross-Platform Coordination**: Automatically adds features to both iOS and Android projects
- **Feature Parity Tracking**: Monitors implementation consistency between platforms  
- **Unified Build System**: Builds both platforms together with consolidated reporting
- **Smart Naming Conventions**: Automatically converts View ↔ Screen naming patterns
- **Implementation Tracking**: Generates checklists and progress notes
- **Sync Analysis**: Identifies platform discrepancies and synchronization issues

## Usage

```bash
# Add UI component to both platforms
node mobile-file-manager add-view LocationAuthorizationView "Location permission gate"

# Add business logic to both platforms  
node mobile-file-manager add-manager NotificationManager "Push notification handling"

# Build both iOS and Android together
node mobile-file-manager build-all

# Check platform synchronization
node mobile-file-manager sync-check

# Analyze feature parity
node mobile-file-manager feature-parity
```

## Commands

### `add-view <name> [description]`
Creates UI components on both platforms:
- **iOS**: Creates `{Name}.swift` in Views group
- **Android**: Creates `{Name}Screen.kt` in ui.screens package  
- **Auto-conversion**: LocationView → LocationScreen
- **Templates**: SwiftUI @Composable and Jetpack Compose patterns

### `add-manager <name> [description]`  
Creates business logic managers on both platforms:
- **iOS**: Creates `{Name}.swift` in Managers group
- **Android**: Creates `{Name}.kt` in managers package
- **Consistency**: Same class name and structure patterns
- **Templates**: iOS class and Android @HiltViewModel patterns

### `build-all`
Builds both platforms with consolidated reporting:
- Parallel iOS and Android builds
- Success/failure summary for each platform
- First-level error reporting
- Overall build status (passes only if both succeed)

### `sync-check`
Analyzes platform synchronization:
- Counts Views vs Screens (iOS vs Android)
- Counts Managers across platforms
- Identifies sync discrepancies (>2 file difference triggers warning)
- Provides sync recommendations

### `feature-parity`
Checks implementation parity for core features:
- **Location Authorization**: iOS LocationAuthorizationView ↔ Android LocationAuthorizationScreen
- **Location Management**: iOS LocationManager ↔ Android LocationManager  
- **Speech Recognition**: iOS SpeechManager ↔ Android SpeechManager
- **Weather Integration**: iOS WeatherManager ↔ Android WeatherManager
- **Parity Score**: Percentage of features implemented on both platforms

## Naming Conventions

| iOS Pattern | Android Pattern | Purpose |
|-------------|-----------------|---------|
| `LocationView.swift` | `LocationScreen.kt` | UI Components |
| `DataManager.swift` | `DataManager.kt` | Business Logic |
| `Utils.swift` | `Utils.kt` | Utilities |
| `Views/` group | `ui.screens` package | UI Organization |
| `Managers/` group | `managers` package | Logic Organization |

## Implementation Notes

### Auto-Generated Checklists
Each cross-platform addition creates implementation notes:
```markdown
# LocationAuthorizationView Implementation Notes

**Type**: View
**Created**: 2024-01-15
**Description**: Location permission gate

## Implementation Checklist

### iOS (Swift)
- [ ] Basic implementation structure
- [ ] SwiftUI integration
- [ ] CarPlay integration (if applicable)

### Android (Kotlin)  
- [ ] Basic implementation structure
- [ ] Jetpack Compose integration
- [ ] Android Auto integration (if applicable)

### Cross-Platform
- [ ] Feature parity verification
- [ ] Consistent API/interface
- [ ] Testing on both platforms
```

## Integration with Other MCP Tools

This tool orchestrates the iOS and Android project managers:

```bash
# Internal calls to specialized tools
node ios-project-manager add-file Views/LocationView.swift Views
node android-project-manager add-file LocationScreen.kt ui.screens
node ios-project-manager build
node android-project-manager build  
```

## Examples

### Complete Feature Addition
```bash
# Add location authorization to both platforms
node mobile-file-manager add-view LocationAuthorizationView "Blocks app until location permission granted"

# Output:
# 🔄 Adding cross-platform view: LocationAuthorizationView
#    📝 Description: Blocks app until location permission granted
# 
# 📱 Adding to iOS project...
#    ✅ iOS: Added successfully
# 
# 🤖 Adding to Android project...
#    ✅ Android: Added successfully
# 
# ✅ Cross-platform view LocationAuthorizationView added successfully!
#    📄 iOS: Views/LocationAuthorizationView.swift
#    📄 Android: ui/screens/LocationAuthorizationScreen.kt
#    📝 Implementation notes: .claude/implementation-notes/LocationAuthorizationView-implementation.md
```

### Build Verification
```bash
node mobile-file-manager build-all

# Output:
# 🔨 Building all platforms...
# 
# 📱 Building iOS...
#    ✅ iOS build successful
# 
# 🤖 Building Android...
#    ✅ Android build successful
# 
# 📊 Build Summary:
#    iOS: ✅ SUCCESS
#    Android: ✅ SUCCESS
# 
# 🎉 All platforms built successfully!
```

### Parity Analysis
```bash
node mobile-file-manager feature-parity

# Output:
# 🎯 Analyzing feature parity...
# 
# 📊 Feature Parity Analysis:
#    ✅ Location Permission Gate: Both platforms implemented
#    ✅ Location Management: Both platforms implemented
#    ⚠️  Speech Recognition: iOS only (missing Android)
#    ❌ Weather Integration: Missing on both platforms
# 
# 📈 Feature Parity Score: 50% (2/4)
#    ⚠️  Feature parity needs attention
```

## Benefits

**Before Cross-Platform Tool:**
1. Create iOS file manually
2. Add to Xcode project with UUIDs
3. Create Android file separately
4. Set up Android package structure
5. Build iOS and check for errors
6. Build Android and check for errors
7. Manually track feature parity
8. No synchronization monitoring

**After Mobile File Manager:**
```bash
node mobile-file-manager add-view NewFeatureView "Feature description"  
node mobile-file-manager build-all
node mobile-file-manager feature-parity
```

Reduces 15+ manual steps across two platforms to 3 automated commands with intelligent parity tracking.

This tool ensures consistent cross-platform development, preventing iOS/Android feature drift and maintaining implementation quality across both mobile platforms.