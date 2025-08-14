# Roadtrip-Copilot Button Design System

## CRITICAL REGRESSION PREVENTION
**This design system permanently prevents circular border regressions and ensures 100% platform parity**

## Executive Summary

This comprehensive button design system establishes binding specifications for all button implementations across iOS, Android, CarPlay, and Android Auto platforms. Every design decision enforces the ABSOLUTE prohibition of circular borders (clipShape(Circle())) and mandates pixel-perfect consistency across all four platforms.

### Key Violations Prevented
- ❌ **NEVER** use `clipShape(Circle())` or `Circle()` backgrounds on buttons
- ❌ **NEVER** implement platform-specific button styles
- ❌ **NEVER** compromise touch targets for aesthetics
- ❌ **NEVER** use different corner radii for identical button types

### Compliance Requirements
- ✅ **MANDATORY** platform parity across all implementations
- ✅ **MANDATORY** design token usage (no hardcoded values)
- ✅ **MANDATORY** WCAG 2.1 AAA accessibility compliance
- ✅ **MANDATORY** automotive safety standards adherence
- ✅ **MANDATORY** voice recognition auto-start behavior across all platforms
- ✅ **MANDATORY** mic button mute/unmute toggle functionality only

## Design Token System

### Corner Radius Tokens (NO CIRCULAR SHAPES)
```css
:root {
  --radius-none: 0px;
  --radius-xs: 4px;
  --radius-sm: 6px;
  --radius-md: 8px;        /* Primary button standard */
  --radius-lg: 12px;       /* Secondary button standard */
  --radius-xl: 16px;       /* Large element standard */
  --radius-2xl: 20px;      /* Maximum allowed radius */
  
  /* ❌ PROHIBITED: No circular/pill shapes */
  /* --radius-full: 50%; <- NEVER USE THIS */
}
```

### Touch Target Tokens (Cross-Platform Minimum)
```css
:root {
  /* Touch Targets - Platform Parity Requirements */
  --touch-target-min: 44px;          /* iOS minimum / 44pt */
  --touch-target-android-min: 48px;  /* Android minimum / 48dp */
  --touch-target-comfortable: 56px;  /* Automotive recommended */
  --touch-target-large: 64px;        /* Primary actions */
  
  /* Icon Sizes Within Touch Targets */
  --icon-xs: 16px;
  --icon-sm: 20px;
  --icon-md: 24px;
  --icon-lg: 32px;
  --icon-xl: 40px;
}
```

### Color Tokens (WCAG AAA Compliant)
```css
:root {
  /* Primary Action Colors */
  --btn-primary-bg: #1976D2;          /* 8.59:1 contrast ratio */
  --btn-primary-text: #FFFFFF;
  --btn-primary-border: #1976D2;
  
  /* Secondary Action Colors */
  --btn-secondary-bg: #F5F5F5;        /* 15.8:1 contrast ratio */
  --btn-secondary-text: #212121;
  --btn-secondary-border: #E0E0E0;
  
  /* Voice Action Colors */
  --btn-voice-bg: #388E3C;            /* High contrast green */
  --btn-voice-text: #FFFFFF;
  --btn-voice-active: #2E7D32;
  
  /* Danger Action Colors */
  --btn-danger-bg: #D32F2F;
  --btn-danger-text: #FFFFFF;
  --btn-danger-border: #D32F2F;
  
  /* Disabled State Colors */
  --btn-disabled-bg: #BDBDBD;
  --btn-disabled-text: #757575;
  --btn-disabled-border: #BDBDBD;
}
```

### Spacing Tokens
```css
:root {
  /* Button Internal Padding */
  --btn-padding-xs: 8px 12px;
  --btn-padding-sm: 10px 16px;
  --btn-padding-md: 12px 20px;        /* Standard button padding */
  --btn-padding-lg: 16px 24px;        /* Large button padding */
  
  /* Button Margins */
  --btn-margin-xs: 4px;
  --btn-margin-sm: 8px;
  --btn-margin-md: 12px;
  --btn-margin-lg: 16px;
}
```

### Animation Tokens
```css
:root {
  /* Animation Durations */
  --animation-quick: 150ms;
  --animation-base: 200ms;
  --animation-slow: 300ms;
  
  /* Easing Functions */
  --ease-out-cubic: cubic-bezier(0.33, 1, 0.68, 1);
  --ease-in-out-cubic: cubic-bezier(0.65, 0, 0.35, 1);
  
  /* Scale Factors */
  --scale-press: 0.95;
  --scale-hover: 1.02;
  --scale-active: 1.1;
}
```

## Voice Interaction Requirements (MANDATORY ACROSS ALL PLATFORMS)

### 🚨 AUTOMATIC VOICE RECOGNITION START
**WHEN** the user navigates to specific screens, the system **SHALL** automatically start voice recognition:

#### Target Screens for Auto-Start:
- **SetDestinationScreen**: Voice recognition MUST auto-start on entry
- **VoiceConfirmationScreen**: Voice recognition MUST auto-start on entry
- **NO exceptions**: Auto-start is MANDATORY on these screens
- **NO user interaction**: Voice recognition begins without button tap

#### Platform Implementation Requirements:
- **iOS**: Use `LaunchedEffect` or `onAppear` with 100ms delay for screen stability
- **Android**: Use `LaunchedEffect` with proper lifecycle management  
- **CarPlay**: Must maintain auto-start behavior within CarPlay template constraints
- **Android Auto**: Must maintain auto-start behavior within Auto template constraints

### 🚨 MICROPHONE BUTTON BEHAVIOR
**WHEN** the user taps the microphone button, the system **SHALL** perform mute/unmute toggle ONLY:

#### Mandatory Mic Button Behavior:
- **PRIMARY FUNCTION**: Mute/unmute toggle exclusively
- **PROHIBITED FUNCTION**: Does NOT start/stop voice recognition sessions
- **SESSION CONTINUITY**: Voice session continues during mute operations
- **VISUAL FEEDBACK**: Clear indication of muted vs unmuted state
- **AUDIO FEEDBACK**: Optional audio cue for mute/unmute state change

#### Platform-Specific Implementation:
- **iOS**: Toggle audio session mute state, maintain recognition session
- **Android**: Use SpeechManager mute/unmute methods, preserve audio focus
- **CarPlay**: Respect CarPlay audio session management during mute operations
- **Android Auto**: Maintain Auto audio session during mute/unmute operations

### 🚨 BORDERLESS BUTTON DESIGN
**ALL buttons** across all platforms **SHALL** use borderless, icon-only design:

#### Mandatory Design Properties:
- **NO borders**: No outline, stroke, or visible border elements
- **NO circular shapes**: Use rounded rectangles with design token corner radii only
- **ICON ONLY**: Only the icon/symbol should be visible
- **TRANSPARENT BACKGROUND**: Buttons should appear as floating icons
- **DESIGN TOKENS**: Use 8dp, 12dp, 16dp corner radii from design token system

#### Prohibited Design Patterns:
- ❌ **CircleShape** (Android) - NEVER USE
- ❌ **clipShape(Circle())** (iOS) - NEVER USE  
- ❌ **Outlined borders** - NO visible button borders
- ❌ **Square backgrounds** - NO background shapes visible
- ❌ **Platform-specific styling** - Must be identical across platforms

### 🚨 VOICE ANIMATION SEPARATION RULES
**CRITICAL PLATFORM PARITY REQUIREMENT**: Voice animations must be strictly separated between button types to prevent user confusion and maintain consistent UX across all platforms.

#### Animation Exclusivity Requirements:
**GO/Navigate Button Animation Behavior**:
- ✅ **SHALL** show voice animations during voice recognition
- ✅ **SHALL** display animated voice wave indicators when speech is detected
- ✅ **SHALL** be the ONLY button type allowed to show voice activity animations

**MIC Button Animation Prohibition**:
- ❌ **SHALL NEVER** show voice animations under any circumstances
- ❌ **SHALL NEVER** display voice activity indicators or animations
- ❌ **SHALL NEVER** pulse, animate, or visually respond to voice activity
- ✅ **SHALL ONLY** show static mute/unmute state icons

#### Platform-Specific Implementation:
**iOS Implementation**:
```swift
// ✅ CORRECT - GO Button with voice animation
VoiceAnimationButton(
    isVoiceAnimating: $isVoiceAnimating, // ← Connected to voice activity
    action: { handleNavigation() }
)

// ✅ CORRECT - MIC Button without voice animation
MicrophoneToggleButton(
    isMuted: $isMicrophoneMuted, // ← Only mute state, NO voice activity
    action: { toggleMicrophone() }
)
```

**Android Implementation**:
```kotlin
// ✅ CORRECT - GO Button with voice animation
AnimatedContent(
    targetState = isVoiceDetected // ← Connected to voice activity
) { voiceDetected ->
    if (voiceDetected) {
        VoiceAnimationComponent() // ← Animation ONLY on GO button
    } else {
        NavigationIcon()
    }
}

// ✅ CORRECT - MIC Button without voice animation
IconButton(onClick = { toggleMicrophone() }) {
    Icon(
        imageVector = if (isMuted) Icons.Default.MicOff else Icons.Default.Mic,
        // ← Static icons only, NO VoiceAnimationComponent
    )
}
```

#### Prohibited Patterns:
```swift
// ❌ INCORRECT - Voice animation on MIC button
VoiceAnimationButton(
    isVoiceAnimating: $isListening, // ← NEVER connect MIC to voice activity
    action: { toggleMicrophone() }
)
```

```kotlin
// ❌ INCORRECT - Voice animation component on MIC button
"listening" -> VoiceAnimationComponent( // ← NEVER use on MIC button
    isActive = true
)
```

#### Validation Requirements:
- **Code Review**: All button implementations must be validated for animation separation
- **Testing**: Manual testing must confirm MIC buttons show NO voice animations
- **Platform Parity**: Animation behavior must be identical across iOS, Android, CarPlay, Android Auto
- **Regression Prevention**: Automated checks must prevent voice animation reappearance on MIC buttons

## Button Category Specifications

### 1. Primary Action Buttons
**Usage**: Navigation start, destination confirmation, primary CTAs
```css
.btn-primary {
  /* Mandatory Specifications */
  min-width: var(--touch-target-min);
  min-height: var(--touch-target-min);
  padding: var(--btn-padding-md);
  background: var(--btn-primary-bg);
  color: var(--btn-primary-text);
  border: 2px solid var(--btn-primary-border);
  border-radius: var(--radius-md);        /* 8px - NO CIRCLES */
  
  /* Typography */
  font-size: 16px;
  font-weight: 600;
  line-height: 1.5;
  
  /* Accessibility */
  cursor: pointer;
  outline: none;
  
  /* States */
  transition: all var(--animation-base) var(--ease-out-cubic);
}

.btn-primary:hover {
  background: #1565C0;
  transform: scale(var(--scale-hover));
}

.btn-primary:active {
  background: #0D47A1;
  transform: scale(var(--scale-press));
}

.btn-primary:focus {
  outline: 3px solid #1976D2;
  outline-offset: 2px;
}

.btn-primary:disabled {
  background: var(--btn-disabled-bg);
  color: var(--btn-disabled-text);
  border-color: var(--btn-disabled-border);
  cursor: not-allowed;
  transform: none;
}
```

### 2. Voice Control Buttons
**Usage**: Microphone toggle, voice activation, audio controls

**🚨 CRITICAL VOICE INTERACTION REQUIREMENTS:**
- **MANDATORY**: Voice recognition MUST auto-start on SetDestinationScreen entry
- **MANDATORY**: Voice recognition MUST auto-start on VoiceConfirmationScreen entry
- **MANDATORY**: Mic button is ONLY for mute/unmute toggle (NOT start/stop)
- **MANDATORY**: Voice session continues during mute operations
- **MANDATORY**: NO user interaction required to begin listening
- **MANDATORY**: Applies to iOS, Android, CarPlay, Android Auto

```css
.btn-voice {
  /* ❌ CRITICAL: NO CIRCULAR BACKGROUNDS */
  min-width: var(--touch-target-comfortable);  /* 56px for automotive */
  min-height: var(--touch-target-comfortable);
  padding: var(--btn-padding-sm);
  background: var(--btn-voice-bg);
  color: var(--btn-voice-text);
  border: 2px solid var(--btn-voice-bg);
  border-radius: var(--radius-lg);        /* 12px - ROUNDED RECTANGLE ONLY */
  
  /* Voice-Specific Properties */
  position: relative;
  overflow: hidden;
  
  /* Icon Sizing */
  font-size: var(--icon-lg);              /* 32px icon */
  
  /* States */
  transition: all var(--animation-base) var(--ease-out-cubic);
}

.btn-voice:active,
.btn-voice.listening {
  background: var(--btn-voice-active);
  animation: voice-pulse 1.5s ease-in-out infinite;
}

.btn-voice.muted {
  background: var(--btn-disabled-bg);
  color: var(--btn-disabled-text);
  animation: none;
}

@keyframes voice-pulse {
  0%, 100% { 
    box-shadow: 0 0 0 0 rgba(56, 142, 60, 0.7);
  }
  50% { 
    box-shadow: 0 0 0 10px rgba(56, 142, 60, 0);
  }
}
```

### 3. Secondary Action Buttons
**Usage**: Settings, menu items, list selections
```css
.btn-secondary {
  min-width: var(--touch-target-min);
  min-height: var(--touch-target-min);
  padding: var(--btn-padding-md);
  background: var(--btn-secondary-bg);
  color: var(--btn-secondary-text);
  border: 2px solid var(--btn-secondary-border);
  border-radius: var(--radius-md);        /* 8px consistent */
  
  /* Typography */
  font-size: 16px;
  font-weight: 500;
  
  /* States */
  transition: all var(--animation-base) var(--ease-out-cubic);
}

.btn-secondary:hover {
  background: #EEEEEE;
  border-color: #BDBDBD;
}

.btn-secondary:active {
  background: #E0E0E0;
  transform: scale(var(--scale-press));
}
```

### 4. Icon-Only Buttons
**Usage**: Navigation controls, quick actions, toolbar buttons
```css
.btn-icon {
  /* ❌ CRITICAL: NO CIRCULAR BACKGROUNDS - SQUARE/ROUNDED RECTANGLE ONLY */
  width: var(--touch-target-min);         /* 44px square */
  height: var(--touch-target-min);
  padding: 0;
  background: transparent;
  border: none;
  border-radius: var(--radius-sm);        /* 6px subtle rounding */
  
  /* Icon */
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: var(--icon-lg);              /* 32px icon in 44px container */
  
  /* States */
  transition: all var(--animation-quick) var(--ease-out-cubic);
}

.btn-icon:hover {
  background: rgba(0, 0, 0, 0.04);
}

.btn-icon:active {
  background: rgba(0, 0, 0, 0.08);
  transform: scale(var(--scale-press));
}
```

### 5. System Integration Buttons (CarPlay/Android Auto)
**Usage**: CarPlay and Android Auto compatible buttons
```css
.btn-automotive {
  /* Enhanced for automotive environments */
  min-width: var(--touch-target-comfortable);  /* 56px for easy targeting */
  min-height: var(--touch-target-comfortable);
  padding: var(--btn-padding-lg);
  background: var(--btn-primary-bg);
  color: var(--btn-primary-text);
  border: 3px solid var(--btn-primary-border);  /* Thicker border for visibility */
  border-radius: var(--radius-lg);              /* 12px for automotive */
  
  /* Enhanced Typography */
  font-size: 18px;                              /* Larger for readability */
  font-weight: 700;                             /* Bolder for visibility */
  
  /* Enhanced Contrast */
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
  
  /* Automotive-Specific States */
  transition: all var(--animation-quick) var(--ease-out-cubic);  /* Faster for safety */
}

.btn-automotive:focus {
  outline: 4px solid #FFC107;              /* High-contrast focus for automotive */
  outline-offset: 2px;
}
```

## Anti-Pattern Prevention

### ❌ NEVER DO THIS (Prohibited Patterns)
```css
/* ❌ CIRCULAR BUTTONS - ABSOLUTELY PROHIBITED */
.btn-circle {
  border-radius: 50%;                     /* NEVER USE */
  clip-path: circle(50%);                 /* NEVER USE */
}

/* ❌ PLATFORM-SPECIFIC STYLING */
.btn-ios-specific {
  -webkit-appearance: button;             /* NEVER USE */
  border-radius: 10px;                    /* Use tokens only */
}

.btn-android-specific {
  elevation: 4dp;                         /* NEVER USE */
  border-radius: 4dp;                     /* Use tokens only */
}

/* ❌ HARDCODED VALUES */
.btn-hardcoded {
  width: 40px;                           /* Use tokens */
  height: 40px;                          /* Use tokens */
  background: #FF0000;                   /* Use color tokens */
  border-radius: 20px;                   /* Use radius tokens */
}

/* ❌ INSUFFICIENT TOUCH TARGETS */
.btn-too-small {
  width: 30px;                           /* Below 44px minimum */
  height: 30px;                          /* Below 44px minimum */
}
```

### ✅ CORRECT PATTERNS (Approved Implementations)
```css
/* ✅ PROPER BUTTON IMPLEMENTATION */
.btn-correct {
  min-width: var(--touch-target-min);
  min-height: var(--touch-target-min);
  border-radius: var(--radius-md);        /* Token-based */
  background: var(--btn-primary-bg);      /* Token-based */
  color: var(--btn-primary-text);         /* Token-based */
}

/* ✅ PROPER ICON BUTTON */
.btn-icon-correct {
  width: var(--touch-target-min);
  height: var(--touch-target-min);
  border-radius: var(--radius-sm);        /* Subtle rounding, NOT circular */
  background: transparent;
}

/* ✅ PROPER VOICE BUTTON */
.btn-voice-correct {
  min-width: var(--touch-target-comfortable);
  min-height: var(--touch-target-comfortable);
  border-radius: var(--radius-lg);        /* ROUNDED RECTANGLE, NOT CIRCLE */
  background: var(--btn-voice-bg);
}
```

## Platform-Specific Implementation Guidelines

### iOS (Swift/SwiftUI) Implementation

#### Required SwiftUI Patterns
```swift
// ✅ CORRECT - Primary Button
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(minWidth: 44, minHeight: 44)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
        }
        .background(Color(red: 0.098, green: 0.463, blue: 0.824))  // #1976D2
        .clipShape(RoundedRectangle(cornerRadius: 8))             // ✅ CORRECT - 8px rounded rectangle
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(red: 0.098, green: 0.463, blue: 0.824), lineWidth: 2)
        )
    }
}

// ✅ CORRECT - Voice Button (NO CIRCULAR SHAPE)
struct VoiceButton: View {
    let action: () -> Void
    @State private var isListening: Bool = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "mic")
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
        }
        .background(Color(red: 0.220, green: 0.557, blue: 0.235))  // #388E3C
        .clipShape(RoundedRectangle(cornerRadius: 12))             // ✅ CORRECT - 12px rounded rectangle
        .scaleEffect(isListening ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isListening)
    }
}

// ✅ CORRECT - Icon Button (NO CIRCULAR SHAPE)
struct IconButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(.primary)
                .frame(width: 44, height: 44)
        }
        .background(Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))              // ✅ CORRECT - 6px subtle rounding
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.black.opacity(0.04))
                .opacity(0)
        )
    }
}

// ❌ PROHIBITED PATTERNS - NEVER USE THESE
/*
struct ProhibitedCircularButton: View {
    var body: some View {
        Button("Don't Use") {}
            .clipShape(Circle())                                   // ❌ NEVER USE
            .background(Circle().fill(Color.blue))                 // ❌ NEVER USE
    }
}
*/
```

#### CarPlay Adaptations
```swift
// CarPlay-specific button styling
extension PrimaryButton {
    func carPlayStyle() -> some View {
        self
            .font(.system(size: 17, weight: .semibold))            // CarPlay font size
            .frame(minWidth: 44, minHeight: 44)                    // CarPlay touch targets
            .background(Color(.systemBlue))                        // CarPlay system color
            .clipShape(RoundedRectangle(cornerRadius: 8))          // ✅ CORRECT - consistent radius
    }
}
```

### Android (Kotlin/Jetpack Compose) Implementation

#### Required Compose Patterns
```kotlin
// ✅ CORRECT - Primary Button
@Composable
fun PrimaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Button(
        onClick = onClick,
        modifier = modifier
            .defaultMinSize(minWidth = 44.dp, minHeight = 44.dp),
        shape = RoundedCornerShape(8.dp),                          // ✅ CORRECT - 8dp rounded rectangle
        colors = ButtonDefaults.buttonColors(
            containerColor = Color(0xFF1976D2),                   // #1976D2
            contentColor = Color.White
        ),
        border = BorderStroke(2.dp, Color(0xFF1976D2))
    ) {
        Text(
            text = text,
            fontSize = 16.sp,
            fontWeight = FontWeight.SemiBold,
            modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp)
        )
    }
}

// ✅ CORRECT - Voice Button (NO CIRCULAR SHAPE)
@Composable
fun VoiceButton(
    onClick: () -> Unit,
    isListening: Boolean = false,
    modifier: Modifier = Modifier
) {
    val scale by animateFloatAsState(
        targetValue = if (isListening) 1.1f else 1.0f,
        animationSpec = tween(200, easing = EaseInOut)
    )
    
    Button(
        onClick = onClick,
        modifier = modifier
            .size(56.dp)
            .scale(scale),
        shape = RoundedCornerShape(12.dp),                         // ✅ CORRECT - 12dp rounded rectangle
        colors = ButtonDefaults.buttonColors(
            containerColor = Color(0xFF388E3C),                   // #388E3C
            contentColor = Color.White
        ),
        contentPadding = PaddingValues(0.dp)
    ) {
        Icon(
            imageVector = Icons.Default.Mic,
            contentDescription = "Voice input",
            modifier = Modifier.size(32.dp)
        )
    }
}

// ✅ CORRECT - Icon Button (NO CIRCULAR SHAPE)
@Composable
fun IconButton(
    icon: ImageVector,
    contentDescription: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    IconButton(
        onClick = onClick,
        modifier = modifier.size(44.dp)
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Color.Transparent,
                    RoundedCornerShape(6.dp)                       // ✅ CORRECT - 6dp subtle rounding
                ),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = contentDescription,
                modifier = Modifier.size(32.dp),
                tint = MaterialTheme.colorScheme.onSurface
            )
        }
    }
}

// ❌ PROHIBITED PATTERNS - NEVER USE THESE
/*
@Composable
fun ProhibitedCircularButton() {
    Button(
        onClick = {},
        shape = CircleShape,                                       // ❌ NEVER USE
        modifier = Modifier.clip(CircleShape)                     // ❌ NEVER USE
    ) {
        Text("Don't Use")
    }
}
*/
```

#### Android Auto Adaptations
```kotlin
// Android Auto-specific button styling
@Composable
fun PrimaryButton.AutomotiveStyle(
    text: String,
    onClick: () -> Unit
) {
    Button(
        onClick = onClick,
        modifier = Modifier.defaultMinSize(minWidth = 48.dp, minHeight = 48.dp),
        shape = RoundedCornerShape(12.dp),                         // Enhanced radius for automotive
        colors = ButtonDefaults.buttonColors(
            containerColor = Color(0xFF1976D2),
            contentColor = Color.White
        ),
        border = BorderStroke(3.dp, Color(0xFF1976D2)),           // Thicker border for visibility
        elevation = ButtonDefaults.elevatedButtonElevation(
            defaultElevation = 2.dp,
            pressedElevation = 8.dp
        )
    ) {
        Text(
            text = text,
            fontSize = 18.sp,                                      // Larger font for automotive
            fontWeight = FontWeight.Bold,                          // Bolder weight for visibility
            modifier = Modifier.padding(horizontal = 24.dp, vertical = 16.dp)
        )
    }
}
```

## Validation and Enforcement

### Automated Validation Script

Create the following validation script that can be run as part of CI/CD:

```bash
#!/bin/bash
# button-validation.sh

echo "🔍 Validating Button Design System Compliance..."

# Check for prohibited circular patterns
echo "Checking for prohibited circular patterns..."
CIRCLE_VIOLATIONS=$(grep -r "clipShape(Circle\|Circle()\|border-radius.*50%\|CircleShape" mobile/ 2>/dev/null || true)

if [ ! -z "$CIRCLE_VIOLATIONS" ]; then
    echo "❌ CRITICAL: Circular button patterns detected!"
    echo "$CIRCLE_VIOLATIONS"
    exit 1
fi

# Check for hardcoded values instead of tokens
echo "Checking for hardcoded values..."
HARDCODED_VIOLATIONS=$(grep -r "cornerRadius.*[0-9]\|RoundedCornerShape([0-9]\|border-radius.*[0-9]px" mobile/ --exclude-dir=build 2>/dev/null || true)

if [ ! -z "$HARDCODED_VIOLATIONS" ]; then
    echo "⚠️  WARNING: Hardcoded values detected. Use design tokens instead."
    echo "$HARDCODED_VIOLATIONS"
fi

# Check for proper touch targets
echo "Checking touch target compliance..."
SMALL_TARGETS=$(grep -r "\.size(4[0-3]\|width.*4[0-3]\|height.*4[0-3]" mobile/ --exclude-dir=build 2>/dev/null || true)

if [ ! -z "$SMALL_TARGETS" ]; then
    echo "⚠️  WARNING: Touch targets below 44px/44dp detected!"
    echo "$SMALL_TARGETS"
fi

echo "✅ Button validation complete!"
```

### Pre-commit Hook

Add to `.git/hooks/pre-commit`:

```bash
#!/bin/bash
# Run button validation before commits
./scripts/button-validation.sh

if [ $? -ne 0 ]; then
    echo "❌ Button validation failed. Commit rejected."
    echo "Please fix button compliance issues before committing."
    exit 1
fi
```

### Code Review Checklist

#### Mandatory Review Items
- [ ] NO usage of `clipShape(Circle())` for buttons
- [ ] NO usage of `CircleShape` in Compose
- [ ] NO circular `border-radius: 50%` in CSS
- [ ] ALL buttons use design tokens (no hardcoded values)
- [ ] Touch targets meet minimum 44px/48dp requirements
- [ ] Visual appearance matches between iOS and Android
- [ ] Color contrast meets WCAG 2.1 AAA standards (7:1 ratio)
- [ ] Voice buttons use rounded rectangles, NOT circles
- [ ] Icon buttons use subtle corner radius (6px), NOT circles
- [ ] Animation timing consistent across platforms (200ms)
- [ ] Accessibility labels present and consistent
- [ ] CarPlay/Android Auto compatibility maintained

#### Voice Interaction Review Items (NEW MANDATORY REQUIREMENTS)
- [ ] Voice recognition auto-starts on SetDestinationScreen entry
- [ ] Voice recognition auto-starts on VoiceConfirmationScreen entry
- [ ] Mic button functions as mute/unmute toggle ONLY
- [ ] Mic button does NOT start/stop voice recognition sessions
- [ ] Voice session continues during mute operations
- [ ] Auto-start behavior identical across iOS and Android
- [ ] Borderless button design applied to ALL buttons
- [ ] NO visible borders or background shapes on any buttons
- [ ] Platform parity validated for voice auto-start timing
- [ ] Audio session management properly handles mute/unmute

## Migration Guide

### Fixing Existing Non-Compliant Buttons

#### Step 1: Identify Violations
Run the validation script to identify all non-compliant buttons:
```bash
./scripts/button-validation.sh
```

#### Step 2: Replace Circular Patterns

**iOS - Replace Circular Buttons:**
```swift
// ❌ BEFORE (Circular - WRONG)
Button("Action") {}
    .clipShape(Circle())
    .background(Circle().fill(Color.blue))

// ✅ AFTER (Rounded Rectangle - CORRECT)
Button("Action") {}
    .frame(width: 44, height: 44)
    .background(Color.blue)
    .clipShape(RoundedRectangle(cornerRadius: 8))
```

**Android - Replace Circular Patterns:**
```kotlin
// ❌ BEFORE (Circular - WRONG)
Button(
    onClick = {},
    shape = CircleShape
) {}

// ✅ AFTER (Rounded Rectangle - CORRECT)
Button(
    onClick = {},
    shape = RoundedCornerShape(8.dp)
) {}
```

#### Step 3: Implement Design Tokens

**Replace hardcoded values with tokens:**
```swift
// ❌ BEFORE (Hardcoded - WRONG)
.clipShape(RoundedRectangle(cornerRadius: 12))

// ✅ AFTER (Token-based - CORRECT)
.clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusLarge))
```

#### Step 4: Validate Platform Parity

Ensure identical appearance across platforms:
- Run both iOS and Android apps side-by-side
- Compare button sizes, colors, and corner radii
- Test touch targets with accessibility tools
- Validate CarPlay and Android Auto implementations

### Implementation Priority

1. **CRITICAL** - Fix all circular button patterns immediately
2. **HIGH** - Implement design token system
3. **MEDIUM** - Add validation scripts and pre-commit hooks
4. **LOW** - Enhance existing compliant buttons with improved animations

## Success Metrics

### Platform Parity Validation
- [ ] 100% identical button appearance across iOS/Android
- [ ] 100% identical touch target sizes
- [ ] 100% identical corner radius values
- [ ] 100% identical color usage
- [ ] 100% identical animation timing

### Accessibility Compliance
- [ ] WCAG 2.1 AAA color contrast (7:1+)
- [ ] Minimum 44px/48dp touch targets
- [ ] Screen reader compatibility
- [ ] Keyboard navigation support
- [ ] High contrast mode support

### Automotive Safety Standards
- [ ] CarPlay design guideline compliance
- [ ] Android Auto Material Design compliance
- [ ] Enhanced visibility for driving conditions
- [ ] Appropriate font sizes for automotive (18sp+)
- [ ] Quick interaction patterns (<2 second glance rule)

## Enforcement Commitment

This design system is **BINDING** and **NON-NEGOTIABLE**. Any deviation from these specifications requires explicit approval from the design system maintainer and must include:

1. **Justification** - Clear business or technical reason for deviation
2. **Impact Assessment** - Platform parity implications
3. **Migration Plan** - How to return to compliance
4. **Timeline** - When compliance will be restored

**The circular border regression ENDS HERE. This design system ensures it never happens again.**