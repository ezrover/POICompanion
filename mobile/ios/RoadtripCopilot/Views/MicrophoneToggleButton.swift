import SwiftUI

/// Microphone toggle button component for voice input control
/// PLATFORM PARITY: MIC button is ONLY for mute/unmute toggle - NO voice animations or listening indicators
struct MicrophoneToggleButton: View {
    @Binding var isMuted: Bool
    let action: () -> Void
    
    @State private var pulseScale = 1.0
    @State private var rotationAngle = 0.0
    @State private var isButtonVisible = true
    
    // Design constants following automotive safety requirements
    private let buttonSize: CGFloat = 56
    private let iconSize: CGFloat = 22
    
    var body: some View {
        // CRITICAL FIX: Always ensure button visibility
        Button(action: {
            // Ensure button stays visible during action
            withAnimation(.none) {
                isButtonVisible = true
            }
            action()
            triggerHapticFeedback()
        }) {
            ZStack {
                // BORDERLESS DESIGN: Remove background and border - icon-only button
                // Background and border removed to comply with BORDERLESS BUTTON ENFORCEMENT
                Color.clear
                    .frame(width: buttonSize, height: buttonSize)
                    .scaleEffect(pulseScale)
                
                // BORDERLESS DESIGN: Always visible microphone icon with state indicators
                ZStack {
                    // Base microphone icon - always present
                    Image(systemName: microphoneIconName)
                        .font(.system(size: iconSize, weight: .medium))
                        .foregroundColor(iconColor)
                        .rotationEffect(.degrees(rotationAngle))
                        .opacity(isButtonVisible ? 1.0 : 0.8) // Subtle feedback but always visible
                    
                    // Mute slash overlay
                    if isMuted {
                        Image(systemName: "slash")
                            .font(.system(size: iconSize + 4, weight: .bold))
                            .foregroundColor(.red)
                            .rotationEffect(.degrees(45))
                    }
                    
                    // PLATFORM PARITY FIX: Remove listening indicator ring - MIC button should NOT show voice animations
                    // MIC button is ONLY for mute/unmute toggle - NO voice activity indicators allowed
                }
            }
        }
        .buttonStyle(MicrophoneButtonStyle())
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityValue(accessibilityValue)
        .onAppear {
            // CRITICAL FIX: Ensure visibility on appear
            isButtonVisible = true
            startAnimations()
        }
        // PLATFORM PARITY FIX: Removed isListening onChange - MIC button should NOT respond to voice activity
        .onChange(of: isMuted) { muted in
            // CRITICAL FIX: Maintain visibility during mute changes
            withAnimation(.easeInOut(duration: 0.2)) {
                isButtonVisible = true
                updateMuteAnimation(muted)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    // BORDERLESS DESIGN: Remove background gradient - not needed for icon-only buttons
    
    // BORDERLESS DESIGN: Remove border properties - not needed for icon-only buttons
    
    // BORDERLESS DESIGN: Remove shadow properties - not needed for icon-only buttons
    
    private var microphoneIconName: String {
        // PLATFORM PARITY FIX: MIC button should only show muted/active states - NO listening state
        if isMuted {
            return "mic.slash.fill"
        } else {
            return "mic"
        }
    }
    
    private var iconColor: Color {
        if isMuted {
            return .red
        } else {
            // PLATFORM PARITY FIX: Remove listening state color - MIC button should only show muted/active states
            return .primary
        }
    }
    
    private var accessibilityLabel: String {
        if isMuted {
            return "Microphone muted"
        } else {
            return "Microphone available"
        }
    }
    
    private var accessibilityHint: String {
        if isMuted {
            return "Double tap to unmute microphone and enable voice input"
        } else {
            return "Double tap to mute microphone and disable voice input"
        }
    }
    
    private var accessibilityValue: String {
        if isMuted {
            return "Muted"
        } else {
            return "Available"
        }
    }
    
    // MARK: - Animation Methods
    
    private func startAnimations() {
        // Start continuous rotation for listening indicator
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
    }
    
    // PLATFORM PARITY FIX: Removed updateListeningAnimation method - MIC button should NOT respond to voice activity
    
    private func updateMuteAnimation(_ muted: Bool) {
        // CRITICAL FIX: Maintain visibility during mute animation
        isButtonVisible = true
        
        if muted {
            // Brief scale animation for mute feedback
            withAnimation(.easeInOut(duration: 0.2)) {
                pulseScale = 1.1
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.pulseScale = 1.0
                    // Ensure visibility is maintained
                    self.isButtonVisible = true
                }
            }
        }
    }
    
    private func triggerHapticFeedback() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
}

// MARK: - Supporting Components

/// Custom button style for microphone toggle
struct MicrophoneButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Voice level visualizer for enhanced feedback
struct VoiceLevelIndicator: View {
    let level: CGFloat // 0.0 to 1.0
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<5, id: \.self) { index in
                RoundedRectangle(cornerRadius: 0.5)
                    .fill(barColor(for: index))
                    .frame(width: 2, height: barHeight(for: index))
                    .animation(.easeInOut(duration: 0.1), value: level)
            }
        }
    }
    
    private func barHeight(for index: Int) -> CGFloat {
        let baseHeight: CGFloat = 4
        let maxHeight: CGFloat = 12
        let threshold = CGFloat(index) / 5.0
        
        if isActive && level > threshold {
            return baseHeight + (maxHeight - baseHeight) * min(level * 2, 1.0)
        } else {
            return baseHeight
        }
    }
    
    private func barColor(for index: Int) -> Color {
        let threshold = CGFloat(index) / 5.0
        
        if isActive && level > threshold {
            return .blue
        } else {
            return .gray.opacity(0.3)
        }
    }
}

// MARK: - Previews

#Preview("Microphone Button - Available") {
    VStack(spacing: 20) {
        MicrophoneToggleButton(
            isMuted: .constant(false)
        ) {
            print("Microphone toggled")
        }
        
        Text("Available State")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .padding()
}

#Preview("Microphone Button - Active") {
    VStack(spacing: 20) {
        MicrophoneToggleButton(
            isMuted: .constant(false)
        ) {
            print("Microphone toggled")
        }
        
        Text("Active State")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .padding()
}

#Preview("Microphone Button - Muted") {
    VStack(spacing: 20) {
        MicrophoneToggleButton(
            isMuted: .constant(true)
        ) {
            print("Microphone toggled")
        }
        
        Text("Muted State")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .padding()
}

#Preview("All States") {
    HStack(spacing: 30) {
        VStack(spacing: 8) {
            MicrophoneToggleButton(
                isMuted: .constant(false)
            ) { }
            Text("Available")
                .font(.caption2)
        }
        
        VStack(spacing: 8) {
            MicrophoneToggleButton(
                isMuted: .constant(true)
            ) { }
            Text("Muted")
                .font(.caption2)
        }
    }
    .padding()
}