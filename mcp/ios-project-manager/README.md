# iOS Project Manager

Automates Xcode project file management and builds, eliminating manual project.pbxproj editing.

## Features

- **Automated File Addition**: Automatically adds files to Xcode project with proper UUIDs
- **Project Structure Management**: Handles PBXBuildFile, PBXFileReference, PBXGroup, and PBXSourcesBuildPhase
- **Smart Build System**: Builds iOS projects with error analysis and actionable feedback
- **Project Validation**: Verifies project file integrity and structure
- **Clean & Verify**: Project maintenance and validation tools

## Usage

```bash
# Add new Swift file to Views group
node ios-project-manager add-file Views/LocationAuthorizationView.swift Views

# Build project for iOS Simulator
node ios-project-manager build RoadtripCopilot iphonesimulator

# Clean project build artifacts
node ios-project-manager clean

# Verify project integrity
node ios-project-manager verify

# Show help
node ios-project-manager help
```

## Commands

### `add-file <file-path> [group-name]`
Automatically adds a new file to the Xcode project:
- Generates proper UUIDs for Xcode project structure
- Adds PBXBuildFile entry for compilation
- Adds PBXFileReference entry for file metadata
- Updates target group/folder structure
- Adds to build phase for source files (.swift, .m)

### `build [scheme] [sdk]`
Builds the iOS project with intelligent error analysis:
- Default scheme: `RoadtripCopilot`
- Default SDK: `iphonesimulator`
- Parses build output for errors and warnings
- Provides actionable error summaries
- Shows first 10 errors for quick diagnosis

### `clean`
Cleans project build artifacts using `xcodebuild clean`

### `verify`
Validates project file structure and integrity:
- Checks for required Xcode project sections
- Counts Swift files and build references
- Validates project.pbxproj syntax

## Examples

```bash
# Scenario: Adding a new SwiftUI view
node ios-project-manager add-file Views/SettingsView.swift Views
node ios-project-manager build
# ✅ File automatically added to project and builds successfully

# Scenario: Quick build verification
node ios-project-manager verify
node ios-project-manager build RoadtripCopilot iphonesimulator
# ✅ Project validated and built in one command sequence

# Scenario: Clean build after major changes
node ios-project-manager clean
node ios-project-manager build
# ✅ Fresh build with clean artifacts
```

## Technical Details

### UUID Generation
- Uses crypto.randomBytes() for secure 24-character hex UUIDs
- Follows Xcode UUID format requirements
- Ensures uniqueness across project file entries

### Project File Management
- Safely parses and modifies project.pbxproj
- Maintains Xcode project file structure
- Handles file type detection based on extensions
- Preserves existing project configuration

### Build Analysis
- Parses xcodebuild output for errors/warnings
- Provides summary statistics
- Shows actionable error details
- Handles build failures gracefully

## Integration

This tool automates the manual steps performed when adding LocationAuthorizationView.swift:

**Before (Manual)**:
1. Generate UUIDs manually
2. Edit project.pbxproj with 4 different sections
3. Run xcodebuild and manually parse output
4. Fix errors and rebuild

**After (Automated)**:
```bash
node ios-project-manager add-file Views/LocationAuthorizationView.swift Views
node ios-project-manager build
```

Reduces 15+ manual steps to 2 automated commands.