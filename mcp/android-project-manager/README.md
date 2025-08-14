# Android Project Manager

Automates Android project file management, builds, and project structure maintenance.

## Features

- **Smart File Generation**: Creates Kotlin/Java files with appropriate templates based on naming conventions
- **Package Management**: Automatically handles Android package structure and directories
- **Intelligent Build System**: Gradle build automation with detailed error analysis  
- **Lint Integration**: Automated code quality analysis
- **Project Validation**: Comprehensive project structure verification
- **Dependency Detection**: Identifies required dependencies based on file content

## Usage

```bash
# Add new Kotlin screen with proper package structure
node android-project-manager add-file LocationAuthorizationScreen.kt ui.screens

# Build project with specific Gradle task
node android-project-manager build compileDebugKotlin

# Clean project build artifacts
node android-project-manager clean

# Verify project structure and count files
node android-project-manager verify

# Run lint analysis
node android-project-manager lint
```

## Commands

### `add-file <file-name> <package-path>`
Creates new files with intelligent templates:
- **Screens/Views**: Generates `@Composable` functions for UI components
- **Managers/Services**: Creates `@HiltViewModel` classes with proper injection
- **Generic Classes**: Standard class templates with package structure
- **Auto-creates directories** if they don't exist
- **Detects dependencies** based on file content patterns

Examples:
```bash
# Creates Compose UI screen
node android-project-manager add-file SettingsScreen.kt ui.screens

# Creates Hilt ViewModel manager  
node android-project-manager add-file DataManager.kt managers

# Creates model class
node android-project-manager add-file UserPreferences.kt models
```

### `build [gradle-task]`
Intelligent build system with error analysis:
- **Default task**: `compileDebugKotlin` for fast compilation checking
- **Build time tracking** and performance metrics
- **Error parsing** for Kotlin compilation issues
- **Warning analysis** with deprecation detection
- **Actionable error summaries** (first 15 errors shown)

Common tasks:
```bash
node android-project-manager build compileDebugKotlin    # Fast compilation check
node android-project-manager build assembleDebug        # Full APK build
node android-project-manager build test                 # Run unit tests
```

### `verify`
Comprehensive project validation:
- Checks required files (build.gradle, AndroidManifest.xml, etc.)
- Counts source files by type (Kotlin, Java, XML)  
- Validates Gradle wrapper and version
- Provides project health summary

### `lint`
Android lint analysis with report generation:
- Runs Android lint tools
- Generates HTML reports
- Shows issue counts and summaries
- Links to detailed lint report files

### `clean`
Gradle clean with build artifact removal

## Template Generation

### Compose UI Components
Files ending with `Screen`, `View`, or containing UI indicators:
```kotlin
@Composable
fun LocationAuthorizationScreen() {
    // TODO: Implement LocationAuthorizationScreen
}
```

### Hilt ViewModels
Files ending with `Manager`, `Service`, or similar:
```kotlin
@HiltViewModel
class LocationManager @Inject constructor() : ViewModel() {
    // TODO: Implement LocationManager
}
```

### Generic Classes
Standard class structure with proper package imports

## Package Structure

Automatically creates proper Android package hierarchy:

| Package Path | Full Package | Use Case |
|--------------|--------------|----------|
| `ui.screens` | `com.roadtrip.copilot.ui.screens` | Compose screens |
| `ui.components` | `com.roadtrip.copilot.ui.components` | Reusable UI components |
| `managers` | `com.roadtrip.copilot.managers` | Business logic managers |
| `models` | `com.roadtrip.copilot.models` | Data models |
| `utils` | `com.roadtrip.copilot.utils` | Utility classes |

## Dependency Detection

Automatically identifies required dependencies based on code patterns:

| Pattern | Dependency | Auto-Detection |
|---------|------------|----------------|
| `@Composable` | Jetpack Compose | ✅ |
| `@HiltViewModel` | Hilt DI | ✅ |
| `Room` | Room Database | ✅ |
| `Retrofit` | Network client | ✅ |

## Integration

This tool automates the manual steps performed when creating LocationAuthorizationScreen.kt:

**Before (Manual)**:
1. Create directory structure manually
2. Generate boilerplate Kotlin code
3. Set up proper package imports
4. Run gradlew and parse compilation errors
5. Fix issues and rebuild

**After (Automated)**:
```bash
node android-project-manager add-file LocationAuthorizationScreen.kt ui.screens
node android-project-manager build compileDebugKotlin
```

Reduces 10+ manual steps to 2 automated commands with intelligent error analysis.