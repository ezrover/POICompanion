# Roadtrip-Copilot Build Instructions

## Prerequisites

### iOS Development
- macOS with Xcode 15.0 or later
- iOS 15.0+ deployment target
- Apple Developer Account (for device deployment)
- CarPlay Entitlements (for production CarPlay integration)

### Android Development
- Android Studio Hedgehog (2023.1.1) or later
- Android SDK API Level 34
- Gradle 8.4
- Google Maps API Key

## Project Structure

```
mobile/
├── ios/
│   └── RoadtripCopilot.xcodeproj    # Xcode project
├── android/                         # Android Studio project
└── README.md
```

## iOS Setup

### 1. Open iOS Project
```bash
cd mobile/ios
open RoadtripCopilot.xcodeproj
```

### 2. Configure Bundle ID and Team
1. Select `RoadtripCopilot` project in navigator
2. Under "Signing & Capabilities":
   - Set your Team
   - Change Bundle Identifier to your domain (e.g., `com.yourcompany.roadtrip-copilot`)

### 3. Required Capabilities
The project requires these capabilities (already configured in Info.plist):
- Location Services (Always and When In Use)
- Speech Recognition
- Microphone Access
- Background Modes (Location, Background Processing)
- CarPlay (Navigation)

### 4. Build and Run
1. Select target device or simulator
2. Press Cmd+R to build and run

### 5. CarPlay Testing
- Use CarPlay Simulator in Xcode
- Or connect to physical CarPlay system
- Ensure CarPlay entitlements are configured in Apple Developer Portal

## Android Setup

### 1. Open Android Project
```bash
cd mobile/android
# Open in Android Studio or use command line:
./gradlew build
```

### 2. Configure Google Maps API Key
1. Get a Google Maps API Key from [Google Cloud Console](https://console.cloud.google.com/)
2. Enable these APIs:
   - Maps SDK for Android
   - Places API
   - Directions API
3. Edit `gradle.properties`:
   ```
   MAPS_API_KEY=your_actual_api_key_here
   ```

### 3. Permissions Configuration
The app requires these permissions (configured in AndroidManifest.xml):
- Location (Fine, Coarse, Background)
- Microphone (Speech Recognition)
- Foreground Service
- Notifications
- Network Access

### 4. Build and Run
```bash
./gradlew assembleDebug
./gradlew installDebug
```

Or use Android Studio:
1. Sync Project with Gradle Files
2. Select device/emulator
3. Click Run button

### 5. Android Auto Testing
1. Install Android Auto app on phone
2. Enable Developer Mode in Android Auto
3. Select "Unknown sources" in Android Auto settings
4. Connect to Android Auto head unit or use desktop head unit

## Key Features Implementation Status

### ✅ Completed Features
- [x] Enhanced destination selection with onboarding
- [x] Voice recognition for 7 main commands
- [x] POI category selection (12 categories)  
- [x] Search radius configuration (1-10 mi/km)
- [x] Automotive-optimized UI with large touch targets
- [x] CarPlay and Android Auto integration
- [x] Background location services
- [x] Speech synthesis feedback
- [x] Real-time voice visualizer
- [x] Multi-step onboarding flow
- [x] User preference persistence

### 🚧 Integration Required
- [ ] Google Maps API key configuration
- [ ] Real POI data source integration
- [ ] Backend API connectivity
- [ ] Production CarPlay entitlements
- [ ] App Store/Play Store submission

## Development Notes

### iOS Specific
- Uses SwiftUI for modern iOS development
- Implements MapKit for native mapping
- Speech framework for voice recognition
- Background location with proper power management

### Android Specific  
- Jetpack Compose for modern Android UI
- Google Maps SDK for mapping functionality
- Android Speech Recognition API
- Foreground service for background operation

### Voice Commands Supported
- **"Save"** / "Favorite" / "Bookmark" → Save POI
- **"Like"** / "Love" / "Good" → Like POI
- **"Dislike"** / "Skip" / "Bad" → Dislike POI  
- **"Next"** / "Forward" → Next POI
- **"Previous"** / "Back" → Previous POI
- **"Navigate"** / "Directions" → Get directions
- **"Call"** / "Phone" → Call location

### Testing Recommendations

1. **Simulator Testing**: Test basic UI and flows
2. **Device Testing**: Test location, speech, and background operation
3. **CarPlay/Android Auto**: Test automotive integration
4. **Voice Commands**: Test all voice recognition patterns
5. **Background Operation**: Test location tracking during navigation

## Troubleshooting

### iOS Issues
- **Build Errors**: Check iOS deployment target (15.0+)
- **CarPlay Not Working**: Verify entitlements and provisioning profile
- **Speech Recognition**: Test on physical device (not simulator)
- **Location Permission**: Check Info.plist usage descriptions

### Android Issues  
- **Maps Not Loading**: Verify Google Maps API key configuration
- **Build Errors**: Check SDK versions and Gradle sync
- **Android Auto**: Enable developer mode and unknown sources
- **Background Location**: Test on API 29+ for background restrictions

## Production Deployment

### iOS App Store
1. Configure production provisioning profiles
2. Add CarPlay entitlements via Apple Developer Portal
3. Archive and upload via Xcode or Transporter

### Google Play Store
1. Generate signed APK/AAB
2. Configure Play Console listing
3. Submit for review

## API Keys Required

### Google Services (Android)
- Google Maps API Key
- Places API access
- Directions API access

### Apple Services (iOS)
- MapKit (included with iOS)
- CarPlay entitlements (production only)

## Support

For development issues:
1. Check build logs and error messages
2. Verify all dependencies are properly installed
3. Ensure proper API key configuration
4. Test on physical devices for location and speech features

The project is configured with proper automotive UX patterns and should work seamlessly once API keys are configured and proper permissions are granted.