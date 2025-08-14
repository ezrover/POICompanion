#!/bin/bash

# iOS Project Build Validation Script
# This script validates that the RoadtripCopilot iOS project is properly configured and can build

set -e

PROJECT_DIR="/Users/naderrahimizad/Projects/AI/POICompanion/mobile/ios"
cd "$PROJECT_DIR"

echo "🔍 Validating iOS Project: RoadtripCopilot"
echo "=============================================="

# 1. Check project file integrity
echo "✅ Checking project.pbxproj integrity..."
plutil -lint RoadtripCopilot.xcodeproj/project.pbxproj
echo "   project.pbxproj is valid"

# 2. Check Info.plist integrity
echo "✅ Checking Info.plist integrity..."
plutil -lint RoadtripCopilot/Info.plist
echo "   Info.plist is valid"

# 3. List all Swift files
echo "✅ Verifying Swift files..."
SWIFT_FILES=$(find RoadtripCopilot -name "*.swift" | wc -l | xargs)
echo "   Found $SWIFT_FILES Swift files"

# 4. Check for required files
REQUIRED_FILES=(
    "RoadtripCopilot/RoadtripCopilotApp.swift"
    "RoadtripCopilot/ContentView.swift" 
    "RoadtripCopilot/Info.plist"
    "RoadtripCopilot/CarPlay/CarPlaySceneDelegate.swift"
    "RoadtripCopilot/TTS/TTSPerformanceMonitor.swift"
    "RoadtripCopilot/TTS/KittenTTSProcessor.swift"
    "RoadtripCopilot/TTS/SixSecondPodcastGenerator.swift"
    "RoadtripCopilot/TTS/VoiceConfiguration.swift"
    "RoadtripCopilot/AI/AIAgentManagerSimple.swift"
    "RoadtripCopilot/Managers/EnhancedTTSManager.swift"
)

echo "✅ Checking required files exist..."
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "   ✅ $file"
    else
        echo "   ❌ MISSING: $file"
        exit 1
    fi
done

# 5. Check project schemes
echo "✅ Checking Xcode project schemes..."
xcodebuild -project RoadtripCopilot.xcodeproj -list > /dev/null
echo "   Project schemes are accessible"

# 6. Check for CarPlay configuration
echo "✅ Checking CarPlay configuration..."
if grep -q "CPSupportsNavigation" RoadtripCopilot/Info.plist && \
   grep -q "CPSupportsAudio" RoadtripCopilot/Info.plist; then
    echo "   CarPlay configuration found"
else
    echo "   ❌ Missing CarPlay configuration"
    exit 1
fi

# 7. Check for required permissions
echo "✅ Checking required permissions..."
REQUIRED_PERMISSIONS=(
    "NSLocationAlwaysAndWhenInUseUsageDescription"
    "NSLocationWhenInUseUsageDescription" 
    "NSMicrophoneUsageDescription"
    "NSSpeechRecognitionUsageDescription"
)

for permission in "${REQUIRED_PERMISSIONS[@]}"; do
    if grep -q "$permission" RoadtripCopilot/Info.plist; then
        echo "   ✅ $permission"
    else
        echo "   ❌ MISSING: $permission"
        exit 1
    fi
done

echo ""
echo "🎉 All validations passed!"
echo "🚗 RoadtripCopilot iOS project is ready to build"
echo ""
echo "Next steps:"
echo "1. Open RoadtripCopilot.xcodeproj in Xcode"
echo "2. Select a simulator or device target"
echo "3. Build and run (Cmd+R)"
echo ""
echo "CarPlay testing:"
echo "1. Use the CarPlay Simulator in Xcode"
echo "2. Enable Hardware > External Displays > CarPlay"
echo "3. Test voice commands and TTS functionality"