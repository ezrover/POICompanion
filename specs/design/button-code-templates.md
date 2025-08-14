# Button Code Templates - Copy-Paste Ready Implementations

## Platform Parity Guaranteed Templates

### iOS (Swift/SwiftUI) Templates

#### 1. Primary Action Button
```swift
/// ✅ CORRECT - Primary Button Template
/// Copy-paste ready implementation ensuring platform parity
struct PrimaryActionButton: View {
    let title: String
    let action: () -> Void
    let isEnabled: Bool
    let isLoading: Bool
    
    init(
        title: String,
        action: @escaping () -> Void,
        isEnabled: Bool = true,
        isLoading: Bool = false
    ) {
        self.title = title
        self.action = action
        self.isEnabled = isEnabled
        self.isLoading = isLoading
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: DesignTokens.ButtonColor.primaryText))
                        .scaleEffect(0.8)
                }
                
                Text(title)
                    .font(DesignTokens.Typography.Button.primaryFont)
                    .foregroundColor(DesignTokens.ButtonColor.primaryText)
            }
            .frame(minWidth: DesignTokens.TouchTarget.minimum, minHeight: DesignTokens.TouchTarget.minimum)
            .padding(DesignTokens.Spacing.ButtonPadding.md)
        }
        .background(isEnabled ? DesignTokens.ButtonColor.primaryBackground : DesignTokens.ButtonColor.disabledBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))  // ✅ 8pt rounded rectangle
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                .stroke(isEnabled ? DesignTokens.ButtonColor.primaryBorder : DesignTokens.ButtonColor.disabledBorder, lineWidth: 2)
        )
        .disabled(!isEnabled || isLoading)
        .animation(DesignTokens.Animation.easeOutCubic.duration(DesignTokens.Animation.base), value: isEnabled)
        .accessibilityLabel(title)
        .accessibilityHint(isEnabled ? "Double tap to \(title.lowercased())" : "Button is disabled")
    }
}
```

#### 2. Voice Control Button (NO CIRCULAR SHAPE)
```swift
/// ✅ CORRECT - Voice Button Template (ROUNDED RECTANGLE ONLY)
/// Absolutely NO circular shapes - enforces design system compliance
struct VoiceControlButton: View {
    let action: () -> Void
    @State private var isListening: Bool
    @State private var animationScale: CGFloat = 1.0
    
    init(action: @escaping () -> Void, isListening: Bool = false) {
        self.action = action
        self._isListening = State(initialValue: isListening)
    }
    
    var body: some View {
        Button(action: {
            action()
            isListening.toggle()
            withAnimation(DesignTokens.Animation.easeInOutCubic.duration(DesignTokens.Animation.base)) {
                animationScale = isListening ? DesignTokens.Animation.scaleActive : 1.0
            }
        }) {
            ZStack {
                // Voice wave animation or microphone icon
                if isListening {
                    VoiceWaveAnimation()
                        .foregroundColor(DesignTokens.ButtonColor.voiceText)
                } else {
                    Image(systemName: "mic")
                        .font(DesignTokens.Typography.Button.iconFont)
                        .foregroundColor(DesignTokens.ButtonColor.voiceText)
                }
            }
            .frame(width: DesignTokens.TouchTarget.comfortable, height: DesignTokens.TouchTarget.comfortable)
        }
        .background(isListening ? DesignTokens.ButtonColor.voiceActive : DesignTokens.ButtonColor.voiceBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))  // ✅ 12pt rounded rectangle (NOT CIRCULAR)
        .scaleEffect(animationScale)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                .stroke(DesignTokens.ButtonColor.voiceBackground, lineWidth: 2)
                .opacity(isListening ? 0.6 : 0)
                .scaleEffect(isListening ? 1.2 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                    value: isListening
                )
        )
        .accessibilityLabel(isListening ? "Stop voice input" : "Start voice input")
        .accessibilityHint("Double tap to toggle voice recognition")
    }
}
```

#### 3. Icon-Only Button (NO CIRCULAR SHAPE)
```swift
/// ✅ CORRECT - Icon Button Template (SUBTLE ROUNDING ONLY)
/// No circular shapes - uses subtle corner rounding for platform parity
struct IconOnlyButton: View {
    let icon: String
    let action: () -> Void
    let accessibilityLabel: String
    let isSelected: Bool
    
    init(
        icon: String,
        action: @escaping () -> Void,
        accessibilityLabel: String,
        isSelected: Bool = false
    ) {
        self.icon = icon
        self.action = action
        self.accessibilityLabel = accessibilityLabel
        self.isSelected = isSelected
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(DesignTokens.Typography.Button.iconFont)
                .foregroundColor(isSelected ? DesignTokens.ButtonColor.primaryBackground : .primary)
                .frame(width: DesignTokens.TouchTarget.minimum, height: DesignTokens.TouchTarget.minimum)
        }
        .background(
            isSelected ? 
            DesignTokens.ButtonColor.primaryBackground.opacity(0.1) : 
            Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm))  // ✅ 6pt subtle rounding (NOT CIRCULAR)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm)
                .fill(Color.black.opacity(0.04))
                .opacity(0)
        )
        .scaleEffect(isSelected ? DesignTokens.Animation.scaleHover : 1.0)
        .animation(DesignTokens.Animation.easeOutCubic.duration(DesignTokens.Animation.quick), value: isSelected)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
```

#### 4. Secondary Action Button
```swift
/// ✅ CORRECT - Secondary Button Template
struct SecondaryActionButton: View {
    let title: String
    let action: () -> Void
    let isEnabled: Bool
    
    init(title: String, action: @escaping () -> Void, isEnabled: Bool = true) {
        self.title = title
        self.action = action
        self.isEnabled = isEnabled
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignTokens.Typography.Button.secondaryFont)
                .foregroundColor(isEnabled ? DesignTokens.ButtonColor.secondaryText : DesignTokens.ButtonColor.disabledText)
                .frame(minWidth: DesignTokens.TouchTarget.minimum, minHeight: DesignTokens.TouchTarget.minimum)
                .padding(DesignTokens.Spacing.ButtonPadding.md)
        }
        .background(isEnabled ? DesignTokens.ButtonColor.secondaryBackground : DesignTokens.ButtonColor.disabledBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))  // ✅ 8pt consistent with primary
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                .stroke(isEnabled ? DesignTokens.ButtonColor.secondaryBorder : DesignTokens.ButtonColor.disabledBorder, lineWidth: 2)
        )
        .disabled(!isEnabled)
        .accessibilityLabel(title)
    }
}
```

#### 5. Automotive Button (CarPlay Compatible)
```swift
/// ✅ CORRECT - Automotive Button Template
/// Enhanced for CarPlay and driving safety
struct AutomotiveButton: View {
    let title: String
    let action: () -> Void
    let isEnabled: Bool
    
    init(title: String, action: @escaping () -> Void, isEnabled: Bool = true) {
        self.title = title
        self.action = action
        self.isEnabled = isEnabled
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignTokens.Typography.Button.automotiveFont)  // Larger font for automotive
                .foregroundColor(DesignTokens.ButtonColor.primaryText)
                .frame(minWidth: DesignTokens.TouchTarget.comfortable, minHeight: DesignTokens.TouchTarget.comfortable)
                .padding(DesignTokens.Spacing.ButtonPadding.lg)  // Larger padding for automotive
        }
        .background(isEnabled ? DesignTokens.ButtonColor.primaryBackground : DesignTokens.ButtonColor.disabledBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))  // ✅ 12pt for automotive visibility
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                .stroke(isEnabled ? DesignTokens.ButtonColor.primaryBorder : DesignTokens.ButtonColor.disabledBorder, lineWidth: 3)  // Thicker border for automotive
        )
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)  // Enhanced shadow for depth
        .disabled(!isEnabled)
        .focusable()
        .accessibilityLabel(title)
        .accessibilityHint("CarPlay compatible button")
    }
}
```

### Android (Kotlin/Jetpack Compose) Templates

#### 1. Primary Action Button
```kotlin
/// ✅ CORRECT - Primary Button Template
/// Matches iOS implementation exactly for platform parity
@Composable
fun PrimaryActionButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    isEnabled: Boolean = true,
    isLoading: Boolean = false
) {
    val scale by animateFloatAsState(
        targetValue = if (isEnabled) 1.0f else 0.95f,
        animationSpec = DesignTokens.Animation.baseTween
    )
    
    Button(
        onClick = onClick,
        modifier = modifier
            .defaultMinSize(
                minWidth = DesignTokens.TouchTarget.minimum,
                minHeight = DesignTokens.TouchTarget.minimum
            )
            .scale(scale),
        enabled = isEnabled && !isLoading,
        shape = RoundedCornerShape(DesignTokens.CornerRadius.md),  // ✅ 8dp rounded rectangle
        colors = DesignTokens.ButtonStyles.primaryButtonStyle(),
        border = DesignTokens.ButtonStyles.primaryBorder,
        contentPadding = DesignTokens.Spacing.ButtonPadding.md
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.Center
        ) {
            if (isLoading) {
                CircularProgressIndicator(
                    modifier = Modifier.size(16.dp),
                    color = DesignTokens.ButtonColor.primaryText,
                    strokeWidth = 2.dp
                )
                Spacer(modifier = Modifier.width(8.dp))
            }
            
            Text(
                text = text,
                fontSize = DesignTokens.Typography.Button.primaryFontSize,
                fontWeight = DesignTokens.Typography.Button.primaryFontWeight
            )
        }
    }
}
```

#### 2. Voice Control Button (NO CIRCULAR SHAPE)
```kotlin
/// ✅ CORRECT - Voice Button Template (ROUNDED RECTANGLE ONLY)
/// Absolutely NO CircleShape - enforces design system compliance
@Composable
fun VoiceControlButton(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    isListening: Boolean = false
) {
    val scale by animateFloatAsState(
        targetValue = if (isListening) DesignTokens.Animation.scaleActive else 1.0f,
        animationSpec = DesignTokens.Animation.baseTween
    )
    
    val pulseScale by animateFloatAsState(
        targetValue = if (isListening) 1.2f else 1.0f,
        animationSpec = infiniteRepeatable(
            animation = tween(1500, easing = EaseInOut),
            repeatMode = RepeatMode.Reverse
        )
    )
    
    Box(modifier = modifier) {
        // Pulse animation overlay for listening state
        if (isListening) {
            Box(
                modifier = Modifier
                    .size(DesignTokens.TouchTarget.comfortable)
                    .scale(pulseScale)
                    .background(
                        DesignTokens.ButtonColor.voiceBackground.copy(alpha = 0.3f),
                        RoundedCornerShape(DesignTokens.CornerRadius.lg)  // ✅ Matching shape (NOT CIRCULAR)
                    )
                    .align(Alignment.Center)
            )
        }
        
        Button(
            onClick = onClick,
            modifier = Modifier
                .size(DesignTokens.TouchTarget.comfortable)
                .scale(scale),
            shape = RoundedCornerShape(DesignTokens.CornerRadius.lg),  // ✅ 12dp rounded rectangle (NOT CIRCULAR)
            colors = DesignTokens.ButtonStyles.voiceButtonStyle(),
            contentPadding = PaddingValues(0.dp)
        ) {
            if (isListening) {
                VoiceWaveAnimation()
            } else {
                Icon(
                    imageVector = Icons.Default.Mic,
                    contentDescription = "Voice input",
                    modifier = Modifier.size(DesignTokens.IconSize.lg),
                    tint = DesignTokens.ButtonColor.voiceText
                )
            }
        }
    }
}
```

#### 3. Icon-Only Button (NO CIRCULAR SHAPE)
```kotlin
/// ✅ CORRECT - Icon Button Template (SUBTLE ROUNDING ONLY)
/// No CircleShape - uses subtle corner rounding for platform parity
@Composable
fun IconOnlyButton(
    icon: ImageVector,
    contentDescription: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    isSelected: Boolean = false
) {
    val scale by animateFloatAsState(
        targetValue = if (isSelected) DesignTokens.Animation.scaleHover else 1.0f,
        animationSpec = DesignTokens.Animation.quickTween
    )
    
    IconButton(
        onClick = onClick,
        modifier = modifier.size(DesignTokens.TouchTarget.minimum)
    ) {
        Box(
            modifier = Modifier
                .size(DesignTokens.TouchTarget.minimum)
                .scale(scale)
                .background(
                    if (isSelected) 
                        DesignTokens.ButtonColor.primaryBackground.copy(alpha = 0.1f)
                    else 
                        Color.Transparent,
                    RoundedCornerShape(DesignTokens.CornerRadius.sm)  // ✅ 6dp subtle rounding (NOT CIRCULAR)
                ),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = contentDescription,
                modifier = Modifier.size(DesignTokens.IconSize.lg),
                tint = if (isSelected) 
                    DesignTokens.ButtonColor.primaryBackground 
                else 
                    MaterialTheme.colorScheme.onSurface
            )
        }
    }
}
```

#### 4. Secondary Action Button
```kotlin
/// ✅ CORRECT - Secondary Button Template
@Composable
fun SecondaryActionButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    isEnabled: Boolean = true
) {
    Button(
        onClick = onClick,
        modifier = modifier.defaultMinSize(
            minWidth = DesignTokens.TouchTarget.minimum,
            minHeight = DesignTokens.TouchTarget.minimum
        ),
        enabled = isEnabled,
        shape = RoundedCornerShape(DesignTokens.CornerRadius.md),  // ✅ 8dp consistent with primary
        colors = DesignTokens.ButtonStyles.secondaryButtonStyle(),
        border = DesignTokens.ButtonStyles.secondaryBorder,
        contentPadding = DesignTokens.Spacing.ButtonPadding.md
    ) {
        Text(
            text = text,
            fontSize = DesignTokens.Typography.Button.secondaryFontSize,
            fontWeight = DesignTokens.Typography.Button.secondaryFontWeight
        )
    }
}
```

#### 5. Automotive Button (Android Auto Compatible)
```kotlin
/// ✅ CORRECT - Automotive Button Template
/// Enhanced for Android Auto and driving safety
@Composable
fun AutomotiveButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    isEnabled: Boolean = true
) {
    Button(
        onClick = onClick,
        modifier = modifier.defaultMinSize(
            minWidth = DesignTokens.TouchTarget.comfortable,
            minHeight = DesignTokens.TouchTarget.comfortable
        ),
        enabled = isEnabled,
        shape = RoundedCornerShape(DesignTokens.CornerRadius.lg),  // ✅ 12dp for automotive visibility
        colors = DesignTokens.ButtonStyles.primaryButtonStyle(),
        border = DesignTokens.ButtonStyles.automotiveBorder,  // Thicker border for automotive
        elevation = ButtonDefaults.elevatedButtonElevation(
            defaultElevation = 2.dp,
            pressedElevation = 8.dp
        ),
        contentPadding = DesignTokens.Spacing.ButtonPadding.lg  // Larger padding for automotive
    ) {
        Text(
            text = text,
            fontSize = DesignTokens.Typography.Button.automotiveFontSize,  // Larger font for automotive
            fontWeight = DesignTokens.Typography.Button.automotiveFontWeight
        )
    }
}
```

### Voice Wave Animation Component (Cross-Platform)

#### iOS Voice Wave Animation
```swift
/// ✅ Voice Wave Animation - iOS Implementation
struct VoiceWaveAnimation: View {
    @State private var animationPhases: [CGFloat] = Array(repeating: 0.3, count: 8)
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<8, id: \.self) { index in
                Rectangle()
                    .fill(DesignTokens.ButtonColor.voiceText)
                    .frame(width: 3, height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 2))  // ✅ Rounded rectangle bars
                    .scaleEffect(y: animationPhases[index])
                    .animation(
                        Animation.easeInOut(duration: 0.8 + Double(index) * 0.1)
                            .repeatForever(autoreverses: true),
                        value: animationPhases[index]
                    )
            }
        }
        .onAppear {
            for index in 0..<8 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                    animationPhases[index] = 1.0
                }
            }
        }
    }
}
```

#### Android Voice Wave Animation
```kotlin
/// ✅ Voice Wave Animation - Android Implementation
@Composable
fun VoiceWaveAnimation() {
    val animatedHeights = remember {
        (0..7).map { Animatable(0.3f) }
    }
    
    LaunchedEffect(Unit) {
        animatedHeights.forEachIndexed { index, animatable ->
            launch {
                delay(index * 100L)
                animatable.animateTo(
                    targetValue = 1.0f,
                    animationSpec = infiniteRepeatable(
                        animation = tween(
                            durationMillis = 800 + index * 100,
                            easing = EaseInOut
                        ),
                        repeatMode = RepeatMode.Reverse
                    )
                )
            }
        }
    }
    
    Row(
        horizontalArrangement = Arrangement.spacedBy(2.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        animatedHeights.forEach { height ->
            Box(
                modifier = Modifier
                    .width(3.dp)
                    .height(20.dp)
                    .scaleEffect(scaleY = height.value)
                    .background(
                        DesignTokens.ButtonColor.voiceText,
                        RoundedCornerShape(2.dp)  // ✅ Rounded rectangle bars
                    )
            )
        }
    }
}
```

## Integration Examples

### Usage in Your Views

#### iOS Usage Examples
```swift
// In your SwiftUI views
struct ExampleContentView: View {
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.ButtonMargin.md) {
            // Primary action
            PrimaryActionButton(title: "Start Navigation") {
                // Handle navigation start
            }
            
            // Voice input
            VoiceControlButton {
                // Handle voice input
            }
            
            // Secondary actions
            HStack {
                IconOnlyButton(icon: "heart", accessibilityLabel: "Like") {
                    // Handle like
                }
                
                IconOnlyButton(icon: "bookmark", accessibilityLabel: "Save") {
                    // Handle save
                }
            }
        }
    }
}
```

#### Android Usage Examples
```kotlin
// In your Composable functions
@Composable
fun ExampleContent() {
    Column(
        verticalArrangement = Arrangement.spacedBy(DesignTokens.Spacing.ButtonMargin.md)
    ) {
        // Primary action
        PrimaryActionButton(
            text = "Start Navigation",
            onClick = { /* Handle navigation start */ }
        )
        
        // Voice input
        VoiceControlButton(
            onClick = { /* Handle voice input */ }
        )
        
        // Secondary actions
        Row(
            horizontalArrangement = Arrangement.spacedBy(DesignTokens.Spacing.ButtonMargin.sm)
        ) {
            IconOnlyButton(
                icon = Icons.Default.Favorite,
                contentDescription = "Like",
                onClick = { /* Handle like */ }
            )
            
            IconOnlyButton(
                icon = Icons.Default.Bookmark,
                contentDescription = "Save",
                onClick = { /* Handle save */ }
            )
        }
    }
}
```

## Validation Checklist for Each Template

When implementing buttons using these templates, verify:

- [ ] ✅ **NO circular shapes** used anywhere
- [ ] ✅ **Design tokens** used for all values
- [ ] ✅ **Touch targets** meet minimum requirements (44px/48dp)
- [ ] ✅ **Platform parity** maintained between iOS and Android
- [ ] ✅ **Accessibility** labels and hints provided
- [ ] ✅ **Animation timing** consistent across platforms
- [ ] ✅ **Color contrast** meets WCAG AAA standards
- [ ] ✅ **Focus states** properly implemented
- [ ] ✅ **Disabled states** handled correctly
- [ ] ✅ **Loading states** implemented where needed

## Common Mistakes to Avoid

### ❌ NEVER DO THIS:
```swift
// iOS - WRONG
Button("Don't Use") {}
    .clipShape(Circle())                    // ❌ CIRCULAR SHAPE
    .frame(width: 40, height: 40)          // ❌ HARDCODED SIZE
    .background(Color.blue)                // ❌ HARDCODED COLOR
```

```kotlin
// Android - WRONG
Button(
    onClick = {},
    shape = CircleShape,                   // ❌ CIRCULAR SHAPE
    modifier = Modifier.size(40.dp),       // ❌ HARDCODED SIZE
    colors = ButtonDefaults.buttonColors(
        containerColor = Color.Blue        // ❌ HARDCODED COLOR
    )
) {}
```

### ✅ ALWAYS DO THIS:
```swift
// iOS - CORRECT
PrimaryActionButton(title: "Correct Usage") {
    // Handle action
}
```

```kotlin
// Android - CORRECT
PrimaryActionButton(
    text = "Correct Usage",
    onClick = { /* Handle action */ }
)
```

These templates guarantee 100% platform parity and prevent circular border regressions forever.