# Roadtrip-Copilot Mobile Apps

This directory contains the native mobile applications for iOS and Android with CarPlay/Android Auto integration.

## 🏗️ Architecture Overview

### Mobile-First AI Architecture
- **Unified Gemma 3n Model**: Single AI model handling all agent functions
- **Background Operation**: Continuous location monitoring and POI discovery
- **CarPlay/Android Auto**: Native automotive integration
- **Voice-First Interface**: Hands-free, safety-compliant operation
- **Privacy-First**: Location processing stays on device

## 📱 Platform Implementation

### iOS App (`/ios/`)
**Technology Stack:**
- Swift 5.9+ with SwiftUI
- CarPlay SDK integration
- Core Location for GPS
- Speech Recognition framework
- AVFoundation for audio

**Key Features:**
- Native CarPlay templates for automotive display
- Background location updates with navigation mode
- Animated speech recognition UI
- Weather integration with location services
- AI agent communication system

### Android App (`/android/`)
**Technology Stack:**
- Kotlin 1.9+ with Jetpack Compose
- Android Auto Car App Library
- Foreground Service for background operation
- Media Session for audio control
- Google Play Services Location

**Key Features:**
- Android Auto navigation templates
- Foreground service with persistent notification
- Rich notification system with images
- Media session controls from lock screen
- Google Assistant integration support

## 🚗 HMI Dashboard Features

### Core UI Components
1. **POI Image Display** - Shows discovered places with photos
2. **Animated Speech Control** - Visual feedback for voice interaction
3. **Control Buttons** - Favorite, Like, Dislike, Previous, Next
4. **Status Bar** - Current location, weather, app status
5. **Background Agents** - AI processing without user intervention

### Voice Recognition
- **Wake Word Detection**: "Hey Roadtrip" (when supported)
- **Voice Commands**: Favorite, Like, Dislike, Skip, Navigate
- **6-Second Audio Summaries**: Quick POI reviews for safety
- **Automotive Optimization**: Noise cancellation, hands-free operation

## 🤖 AI Agent System

### Agent Communication Framework
```
┌─────────────────────────────────────────┐
│            AgentCommunicator            │
├─────────────────────────────────────────┤
│  • Message routing between agents       │
│  • Async event-driven communication     │
│  • Thread-safe message queues          │
└─────────────────────────────────────────┘
                     │
    ┌────────────────┼────────────────┐
    ▼                ▼                ▼
┌─────────┐    ┌─────────┐    ┌─────────┐
│   POI   │    │ Speech  │    │Location │
│Discovery│    │Manager  │    │Analysis │
│ Agent   │    │ Agent   │    │ Agent   │
└─────────┘    └─────────┘    └─────────┘
    │                │                │
    └────────────────┼────────────────┘
                     ▼
            ┌─────────────────┐
            │   UI Updates    │
            │ (Main Thread)   │
            └─────────────────┘
```

### Background Agents
1. **POIDiscoveryAgent** - Finds nearby places using location
2. **ReviewDistillationAgent** - Processes reviews into 6-second summaries
3. **ContentGenerationAgent** - Creates UGC content for revenue
4. **LocationAnalysisAgent** - Analyzes driving patterns and context
5. **UserPreferenceAgent** - Learns from user interactions
6. **RevenueTrackingAgent** - Tracks monetization opportunities
7. **ReferralAgent** - Manages viral referral system
8. **VoiceInteractionAgent** - Processes voice commands and responses

## 🎯 Background Operation Strategy

### iOS Implementation
**Primary: CarPlay Mode (100% functionality)**
- CPNavigationSession for continuous background privileges
- Voice control via CPVoiceControlTemplate
- Rich POI display with CPPointOfInterestTemplate

**Fallback: Navigation App Mode (80% functionality)**
- Background location with navigation app registration
- Rich notifications with image attachments
- Live Activities for persistent display (iOS 16+)

### Android Implementation
**Primary: Foreground Service (95% functionality)**
- Continuous background execution with notification
- Media Session for lock screen and car audio control
- Rich notifications with custom layouts and actions

**Enhanced: Android Auto (100% functionality)**
- Navigation templates with full driving privileges
- Voice commands integrated with car systems
- Seamless background execution

## 📍 Location & Privacy

### Location Processing
- **GPS Monitoring**: Continuous background location updates
- **City Resolution**: Reverse geocoding to city/state names
- **Privacy Compliance**: Location stays on device, only city-level transmission
- **Battery Optimization**: Adaptive update intervals based on movement

### Weather Integration
- **Real-time Weather**: Current conditions with location updates
- **Weather Icons**: SF Symbols (iOS) / Material Icons (Android)
- **Status Display**: Top-right corner of HMI dashboard

## 🎙️ Speech & Audio

### Speech Recognition
- **Always-On Listening**: Background voice command detection
- **Automotive Optimization**: Noise cancellation, 95% accuracy target
- **Command Processing**: Natural language intent recognition
- **Privacy**: On-device processing when possible

### Speech Synthesis
- **6-Second Format**: Quick POI summaries for driving safety
- **Natural Voices**: Automotive-optimized TTS
- **Audio Ducking**: Respectful interruption of other audio
- **CarPlay/Android Auto**: Native audio system integration

## 🚀 Getting Started

### iOS Development Setup
```bash
cd mobile/ios/
# Open RoadtripCopilot.xcodeproj in Xcode
# Set up CarPlay entitlements
# Configure Info.plist with location permissions
# Build and test on device with CarPlay capability
```

### Android Development Setup
```bash
cd mobile/android/
# Open in Android Studio
# Configure AndroidManifest.xml permissions
# Set up Android Auto Desktop Head Unit for testing
# Build and test with Foreground Service permissions
```

## 🧪 Testing Strategy

### CarPlay/Android Auto Testing
- **Simulator Testing**: iOS CarPlay Simulator, Android Auto DHU
- **Device Testing**: Physical CarPlay/Android Auto units
- **Voice Testing**: Automotive noise conditions
- **Background Testing**: Extended driving simulation

### Performance Targets
- **Voice Latency**: <350ms first token generation
- **Location Updates**: 30-60 second intervals while moving
- **Battery Impact**: <5% consumption per hour
- **Memory Usage**: <1GB total for all agents
- **UI Responsiveness**: <2 second max response time

## 📋 Development Checklist

### iOS Implementation
- [x] SwiftUI HMI dashboard with control buttons
- [x] CarPlay integration with templates
- [x] Background location services
- [x] Speech recognition and synthesis
- [x] AI agent communication system
- [x] Weather integration
- [x] Info.plist permissions configuration
- [ ] Core ML integration for on-device AI
- [ ] Comprehensive testing suite

### Android Implementation
- [x] Jetpack Compose HMI dashboard
- [x] Android Auto Car App Service
- [x] Foreground Service for background operation
- [x] Media Session for audio control
- [x] Rich notification system
- [x] Location services with background support
- [x] AI agent framework
- [ ] MediaPipe integration for on-device AI
- [ ] Google Assistant Actions setup

## 🔧 Next Development Phase

### Immediate Tasks (Week 1-2)
1. **Core ML/MediaPipe Integration** - Add on-device AI processing
2. **Database Integration** - Connect to Supabase backend
3. **API Client** - Implement backend communication
4. **Testing Framework** - Unit and integration tests

### Short-term Goals (Week 3-4)
1. **Real POI Discovery** - Replace mock data with live APIs
2. **Revenue Tracking** - Implement UGC monetization
3. **Voice Optimization** - Achieve <350ms latency target
4. **Performance Optimization** - Memory and battery efficiency

The mobile apps are now scaffolded with complete architecture supporting:
- ✅ CarPlay/Android Auto integration
- ✅ Background operation with location services
- ✅ Voice-first HMI dashboard
- ✅ AI agent communication system
- ✅ Weather integration
- ✅ Animated speech controls
- ✅ Privacy-compliant location handling

Ready for the next development phase with backend integration and AI processing implementation.