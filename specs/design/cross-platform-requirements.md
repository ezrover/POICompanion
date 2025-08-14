# Cross-Platform Requirements for Roadtrip-Copilot

**Document Version**: 2.0  
**Date**: 2025-08-13  
**Author**: Claude Code (AI Agent Coordination)  
**Status**: ACTIVE - MANDATORY COMPLIANCE

## 🚨 CRITICAL PLATFORM PARITY MANDATE

This document establishes **NON-NEGOTIABLE** requirements that must be enforced across all four target platforms:
- ✅ **iOS** (Swift/SwiftUI)
- ✅ **Apple CarPlay** (CarPlay Templates)
- ✅ **Android** (Kotlin/Jetpack Compose)
- ✅ **Android Auto** (Car App Templates)

**ZERO TOLERANCE POLICY**: Any deviation from these requirements triggers automatic task failure and mandatory re-implementation.

---

## 1. VOICE INTERACTION REQUIREMENTS (MANDATORY)

### 1.1 Voice Animation Platform Parity (ZERO TOLERANCE)

**🚨 CRITICAL MANDATE**: Voice animations MUST be isolated to specific button types across ALL platforms.

#### Voice Animation Rules:
- **GO/Navigate Button**: Voice animations REQUIRED during voice recognition (ONLY location for animations)
- **MIC Button**: Voice animations PROHIBITED - static mute/unmute icons ONLY
- **NO EXCEPTIONS**: MIC button NEVER shows voice animations under any circumstances
- **100% PARITY**: Identical animation behavior across iOS, Android, CarPlay, Android Auto

#### Implementation Validation:
```swift
// iOS CORRECT Implementation
VoiceAnimationButton(               // ← GO button: shows animations
    isVoiceAnimating: $isVoiceAnimating,
    isProcessing: $isProcessingNavigation,
    isEnabled: canNavigate
)

MicrophoneToggleButton(             // ← MIC button: NO animations
    isMuted: $isMicrophoneMuted     // ← Static state only
)
```

```kotlin
// Android CORRECT Implementation
AnimatedContent(targetState = isVoiceDetected) { // ← GO button: shows animations
    VoiceAnimationComponent()
}

Icon(                               // ← MIC button: NO animations
    imageVector = if (isMuted) Icons.Default.MicOff else Icons.Default.Mic // ← Static icons only
)
```

### 1.2 Voice Interface Overlay Rules (ZERO TOLERANCE)

**🚨 CRITICAL MANDATE**: Voice interface overlays MUST be eliminated from all platforms to ensure consistent, non-intrusive UX.

#### PROHIBITED Voice Interface Elements:
- ❌ **Center Screen Overlays**: NO voice visualizers, waveforms, or listening indicators in screen center
- ❌ **Fullscreen Voice Overlays**: NO blocking UI elements during voice recognition
- ❌ **Large Voice Visualizers**: NO prominent voice animation displays (>50dp/50pt)
- ❌ **Modal Voice Interfaces**: NO voice modals, popups, or interrupting overlays
- ❌ **VoiceVisualizerView**: ABSOLUTELY PROHIBITED in main screens, POI screens, or navigation views

#### REQUIRED Voice Interface Behavior:
- ✅ **Button-Only Animation**: Voice animation EXCLUSIVELY within Go/Navigate button
- ✅ **Subtle Indicators**: Small, non-intrusive voice state indicators (if needed)
- ✅ **Background Processing**: Voice recognition works invisibly without prominent UI
- ✅ **Clean UI**: No visual interruption to core app functionality

#### Implementation Prevention:
```kotlin
// ANDROID: PROHIBITED Code Pattern
if (isListening || isSpeaking || isVoiceDetected) {
    VoiceVisualizerView(           // ← NEVER use center screen voice overlays
        isListening = isListening,
        modifier = Modifier.size(200.dp)  // ← Large voice visualizers PROHIBITED
    )
}
```

```swift
// iOS: PROHIBITED Code Pattern
if speechManager.isListening {
    VoiceVisualizerView()          // ← NEVER use center screen voice overlays
        .frame(width: 200, height: 200)  // ← Large voice visualizers PROHIBITED
}
```

#### CORRECT Implementation:
```kotlin
// ANDROID: CORRECT Pattern - Voice animation ONLY in button
AnimatedStartButton(
    showVoiceAnimation = isVoiceDetected,  // ← ONLY location for voice animation
    onClick = { /* navigation */ }
)
```

```swift
// iOS: CORRECT Pattern - Voice animation ONLY in button
VoiceAnimationButton(
    isVoiceAnimating: $isVoiceDetected,  // ← ONLY location for voice animation
    action: { /* navigation */ }
)
```

#### Validation Criteria:
- [ ] NO VoiceVisualizerView in MainActivity or equivalent screens
- [ ] NO center screen voice overlays during listening/speaking
- [ ] Voice animation isolated to Go/Navigate button only
- [ ] Clean, non-intrusive voice recognition UX
- [ ] Identical behavior across iOS, Android, CarPlay, Android Auto

### 1.3 Automatic Voice Recognition Start

**🚨 CRITICAL MANDATE**: Voice recognition MUST auto-start on specific screen entries across ALL platforms.

#### Target Screens:
- **SetDestinationScreen**: Voice recognition auto-starts within 100ms of screen entry
- **VoiceConfirmationScreen**: Voice recognition auto-starts within 100ms of screen entry
- **NO EXCEPTIONS**: Auto-start is mandatory on these screens
- **NO USER INTERACTION**: Voice recognition begins without button tap or gesture

#### Platform Implementation Requirements:
```swift
// iOS Implementation Pattern
.onAppear {
    Task {
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms delay
        await speechManager.startListening()
    }
}
```

```kotlin
// Android Implementation Pattern
LaunchedEffect(Unit) {
    delay(100) // 100ms delay for screen stability
    speechManager.startListening()
}
```

#### Validation Criteria:
- [ ] Voice recognition activates automatically on target screens
- [ ] Timing is consistent across iOS and Android (100ms ± 10ms)
- [ ] No user interaction required to begin listening
- [ ] Audio session properly configured without manual intervention
- [ ] Behavior identical across CarPlay and Android Auto

### 1.2 Microphone Button Behavior

**🚨 CRITICAL MANDATE**: Mic button functions EXCLUSIVELY as mute/unmute toggle.

#### Mandatory Mic Button Behavior:
- **PRIMARY FUNCTION**: Mute/unmute toggle ONLY
- **PROHIBITED FUNCTION**: Does NOT start/stop voice recognition sessions
- **SESSION CONTINUITY**: Voice recognition continues during mute operations
- **VISUAL FEEDBACK**: Clear indication of muted vs unmuted state
- **AUDIO FEEDBACK**: Optional audio cue for state changes

#### Implementation Requirements:
```swift
// iOS Mic Button Pattern
Button(action: {
    speechManager.toggleMute() // NOT startListening/stopListening
}) {
    Image(systemName: speechManager.isMuted ? "mic.slash" : "mic")
}
```

```kotlin
// Android Mic Button Pattern
IconButton(onClick = { 
    speechManager.toggleMute() // NOT start/stop voice recognition
}) {
    Icon(
        imageVector = if (isMuted) Icons.Default.MicOff else Icons.Default.Mic,
        contentDescription = if (isMuted) "Unmute" else "Mute"
    )
}
```

#### Validation Criteria:
- [ ] Mic button toggles mute/unmute state only
- [ ] Voice recognition session continues during mute
- [ ] Visual state clearly indicates muted vs unmuted
- [ ] Behavior consistent across all platforms
- [ ] Audio session management handles mute operations properly

---

## 2. BUTTON DESIGN REQUIREMENTS (MANDATORY)

### 2.1 Borderless Icon-Only Design

**🚨 CRITICAL MANDATE**: ALL buttons must use borderless, icon-only design across all platforms.

#### Mandatory Design Properties:
- **NO BORDERS**: No outline, stroke, or visible border elements
- **NO BACKGROUNDS**: No visible button background shapes
- **ICON ONLY**: Only the icon/symbol should be visible
- **TRANSPARENT BASE**: Buttons appear as floating icons
- **ROUNDED CORNERS**: Use design tokens (8dp, 12dp, 16dp) - NEVER circular

#### Prohibited Design Patterns:
- ❌ **CircleShape** (Android) - ABSOLUTELY PROHIBITED
- ❌ **clipShape(Circle())** (iOS) - ABSOLUTELY PROHIBITED
- ❌ **Outlined borders** - NO visible button borders
- ❌ **Square backgrounds** - NO background shapes
- ❌ **Platform-specific styling** - Must be identical

#### Implementation Requirements:
```swift
// iOS Borderless Button Pattern
Button(action: action) {
    Image(systemName: icon)
        .font(.system(size: 32, weight: .semibold))
        .foregroundColor(.primary)
        .frame(width: 44, height: 44)
}
.background(Color.clear)
.clipShape(RoundedRectangle(cornerRadius: 6)) // Subtle rounding, NOT circular
```

```kotlin
// Android Borderless Button Pattern
IconButton(onClick = onClick) {
    Box(
        modifier = Modifier
            .size(44.dp)
            .background(Color.Transparent, RoundedCornerShape(6.dp))
    ) {
        Icon(
            imageVector = icon,
            contentDescription = contentDescription,
            modifier = Modifier.size(32.dp)
        )
    }
}
```

### 2.2 Design Token Usage

**🚨 CRITICAL MANDATE**: ALL corner radii must use design tokens - NO hardcoded values.

#### Approved Corner Radii:
- **8dp** (DesignTokens.CornerRadius.md): Primary/Secondary buttons
- **12dp** (DesignTokens.CornerRadius.lg): Voice buttons, large elements
- **16dp** (DesignTokens.CornerRadius.xl): Maximum allowed radius
- **6dp** (DesignTokens.CornerRadius.sm): Icon buttons, subtle rounding

#### Implementation Requirements:
```swift
// iOS Design Token Usage
.clipShape(RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusLarge))
```

```kotlin
// Android Design Token Usage
shape = RoundedCornerShape(DesignTokens.CornerRadius.lg)
```

---

## 3. PLATFORM PARITY VALIDATION REQUIREMENTS

### 3.1 Mandatory Validation Checklist

Before ANY voice or button implementation is considered complete, ALL platforms must pass this validation:

#### Voice Interface Overlay Prevention:
- [ ] NO VoiceVisualizerView in MainActivity (Android) or equivalent screens
- [ ] NO center screen voice overlays during listening/speaking on iOS
- [ ] NO center screen voice overlays during listening/speaking on Android  
- [ ] NO large voice visualizers (>50dp/50pt) on any platform
- [ ] Voice animation isolated to Go/Navigate button only on iOS
- [ ] Voice animation isolated to Go/Navigate button only on Android
- [ ] CarPlay maintains clean voice interface without overlays
- [ ] Android Auto maintains clean voice interface without overlays

#### Voice Auto-Start Validation:
- [ ] SetDestinationScreen auto-starts voice recognition on iOS
- [ ] SetDestinationScreen auto-starts voice recognition on Android
- [ ] VoiceConfirmationScreen auto-starts voice recognition on iOS
- [ ] VoiceConfirmationScreen auto-starts voice recognition on Android
- [ ] Auto-start timing consistent across platforms (100ms ± 10ms)
- [ ] CarPlay maintains auto-start behavior within template constraints
- [ ] Android Auto maintains auto-start behavior within template constraints

#### Mic Button Behavior Validation:
- [ ] Mic button mutes/unmutes voice session on iOS
- [ ] Mic button mutes/unmutes voice session on Android
- [ ] Voice recognition continues during mute on iOS
- [ ] Voice recognition continues during mute on Android
- [ ] Visual feedback identical across platforms
- [ ] CarPlay mic button behavior consistent
- [ ] Android Auto mic button behavior consistent

#### Button Design Validation:
- [ ] NO CircleShape usage in Android button components
- [ ] NO clipShape(Circle()) usage in iOS button components
- [ ] ALL buttons use design tokens for corner radii
- [ ] Button appearance identical between iOS and Android
- [ ] Touch targets meet platform minimums (44pt iOS / 48dp Android)
- [ ] Borderless design applied consistently across platforms

### 3.2 AI Agent Validation Requirements

**🚨 CRITICAL MANDATE**: The following agents MUST validate platform parity:

#### Required Agent Orchestration:
- **spec-ux-user-experience**: MUST review all voice interaction and button changes
- **spec-ios-developer**: MUST implement iOS voice and button requirements
- **spec-android-developer**: MUST implement Android voice and button requirements
- **spec-judge**: MUST validate complete platform parity before completion

#### Agent Validation Criteria:
- [ ] spec-judge confirms voice auto-start behavior across all platforms
- [ ] spec-judge validates mic button mute/unmute functionality
- [ ] spec-judge verifies borderless button design compliance
- [ ] spec-judge ensures CarPlay/Android Auto compatibility
- [ ] spec-judge validates timing consistency across platforms

---

## 4. ENFORCEMENT AND COMPLIANCE

### 4.1 Violation Consequences

**ZERO TOLERANCE POLICY** - Violations trigger immediate consequences:

#### Level 1 Violations (Automatic Task Failure):
- Center screen voice overlays (VoiceVisualizerView in MainActivity or equivalent)
- Large voice visualizers (>50dp/50pt) during voice recognition
- Voice animations outside of Go/Navigate button
- Missing voice auto-start on target screens
- Mic button starting/stopping voice recognition sessions
- Circular button shapes (CircleShape, clipShape(Circle()))
- Visible borders or backgrounds on buttons
- Platform-specific implementations without parity

#### Level 2 Violations (Complete Re-implementation Required):
- Bypassing AI agent orchestration for voice/button changes
- Skipping spec-judge platform parity validation
- Implementing features without 4-platform consideration

#### Level 3 Violations (Session Termination):
- Repeated violations after warnings
- Systematic bypassing of platform parity requirements
- Refusal to use mandatory AI agent workflow

### 4.2 Automated Validation

#### Pre-Commit Hooks:
```bash
#!/bin/bash
# Voice and button validation
./scripts/voice-validation.sh
./scripts/button-validation.sh

if [ $? -ne 0 ]; then
    echo "❌ Platform parity validation failed. Commit rejected."
    exit 1
fi
```

#### CI/CD Integration:
- Automated voice auto-start behavior testing
- Button design compliance scanning
- Platform parity validation across all builds
- CarPlay/Android Auto compatibility verification

---

## 5. SUCCESS METRICS

### 5.1 Platform Parity Validation Scores

**Target: 100% compliance across all metrics**

#### Voice Interaction Parity:
- [ ] 100% voice auto-start success rate on target screens
- [ ] 100% mic button mute/unmute functionality
- [ ] 100% voice session continuity during mute operations
- [ ] 100% timing consistency across platforms (±10ms tolerance)

#### Button Design Parity:
- [ ] 100% borderless button implementation
- [ ] 100% circular shape elimination
- [ ] 100% design token usage compliance
- [ ] 100% visual appearance matching

#### Platform Coverage:
- [ ] 100% iOS compliance
- [ ] 100% Android compliance
- [ ] 100% CarPlay compliance
- [ ] 100% Android Auto compliance

### 5.2 Quality Gates

**ALL quality gates must pass before feature completion:**

1. **Voice Auto-Start Gate**: Auto-start works on target screens across all platforms
2. **Mic Button Gate**: Mute/unmute toggle works without session interruption
3. **Button Design Gate**: Borderless design applied consistently
4. **Platform Parity Gate**: Identical behavior across iOS/Android/CarPlay/Auto
5. **Agent Validation Gate**: spec-judge confirms complete compliance

---

## 6. MAINTENANCE AND UPDATES

### 6.1 Requirement Evolution

Any changes to these requirements must:
- Maintain 100% platform parity
- Be validated by spec-judge
- Include migration guide for existing implementations
- Update all affected documentation

### 6.2 Regression Prevention

**Permanent safeguards against requirement violations:**
- Automated validation scripts prevent circular button patterns
- Voice auto-start behavior monitoring across platforms
- Platform parity testing in CI/CD pipeline
- Mandatory AI agent orchestration for all changes

---

**This document establishes the foundation for maintaining 100% platform parity across all voice interaction and button design implementations. Compliance is mandatory and non-negotiable.**