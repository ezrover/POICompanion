import SwiftUI

/// Voice-animated Start/Navigate button component following the design specification
/// Features dynamic voice wave animation during speech detection with automotive safety compliance
struct VoiceAnimationButton: View {
    @Binding var isVoiceAnimating: Bool
    @Binding var isProcessing: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    @State private var animationPhase = 0.0
    @State private var pulseScale = 1.0
    @State private var isButtonVisible = true
    
    // Animation constants following design spec
    private let buttonSize: CGFloat = 56 // Automotive safety requirement
    private let animationDuration = 0.8
    private let silenceTimeout = 2.0
    
    var body: some View {
        // CRITICAL FIX: Always ensure button visibility
        Button(action: {
            // Ensure button stays visible during action
            withAnimation(.none) {
                isButtonVisible = true
            }
            action()
        }) {
            ZStack {
                // BORDERLESS DESIGN: Remove background shape - icon-only button
                // Background removed to comply with BORDERLESS BUTTON ENFORCEMENT
                Color.clear
                    .frame(width: buttonSize, height: buttonSize)
                    .scaleEffect(pulseScale)
                    .animation(.easeInOut(duration: 0.15), value: pulseScale)
                
                // BORDERLESS DESIGN: Always visible icon content only
                Group {
                    if isVoiceAnimating {
                        VoiceWaveAnimation()
                            .foregroundColor(.blue) // Use system color for borderless design
                    } else if isProcessing {
                        ProcessingSpinner()
                            .foregroundColor(.blue) // Use system color for borderless design
                    } else {
                        NavigationIcon()
                            .foregroundColor(.blue) // Use system color for borderless design
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
                .opacity(isButtonVisible ? 1.0 : 0.8) // Ensure always visible
            }
        }
        .buttonStyle(VoiceButtonStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.6)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(isEnabled ? [] : .notEnabled)
        .onAppear {
            // CRITICAL FIX: Ensure visibility on appear
            isButtonVisible = true
        }
        .onChange(of: isVoiceAnimating) { animating in
            // CRITICAL FIX: Maintain visibility during animation changes
            withAnimation(.easeInOut(duration: 0.2)) {
                isButtonVisible = true
            }
            
            if animating {
                startVoiceAnimation()
            } else {
                stopVoiceAnimation()
            }
        }
        .onChange(of: isProcessing) { processing in
            // CRITICAL FIX: Maintain visibility during processing state changes
            withAnimation(.easeInOut(duration: 0.2)) {
                isButtonVisible = true
            }
        }
    }
    
    // MARK: - Computed Properties
    
    // BORDERLESS DESIGN: Remove background gradient - not needed for icon-only buttons
    
    private var shadowColor: Color {
        if isVoiceAnimating {
            return Color.blue.opacity(0.4)
        } else if isProcessing {
            return Color.orange.opacity(0.3)
        } else {
            return Color.black.opacity(0.2)
        }
    }
    
    private var shadowRadius: CGFloat {
        isVoiceAnimating ? 12 : 6
    }
    
    private var shadowOffset: CGFloat {
        isVoiceAnimating ? 0 : 2
    }
    
    private var accessibilityLabel: String {
        if isProcessing {
            return "Processing navigation"
        } else if isVoiceAnimating {
            return "Processing voice input"
        } else {
            return "Start navigation"
        }
    }
    
    private var accessibilityHint: String {
        if !isEnabled {
            return "Enter a destination to enable navigation"
        } else {
            return "Double tap to start navigation. Voice commands: go, navigate, start"
        }
    }
    
    // MARK: - Animation Methods
    
    private func startVoiceAnimation() {
        print("[VoiceAnimationButton] Starting voice animation")
        
        // CRITICAL FIX: Ensure button remains visible during animation
        isButtonVisible = true
        
        // Schedule automatic stop after silence timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + silenceTimeout) {
            if self.isVoiceAnimating {
                print("[VoiceAnimationButton] Auto-stopping voice animation after silence timeout")
                self.isVoiceAnimating = false
                self.isButtonVisible = true // Maintain visibility
            }
        }
    }
    
    private func stopVoiceAnimation() {
        print("[VoiceAnimationButton] Stopping voice animation")
        
        // CRITICAL FIX: Maintain visibility when stopping animation
        withAnimation(.easeOut(duration: 0.3)) {
            animationPhase = 0.0
            isButtonVisible = true
        }
    }
    
    // MARK: - Icon Components
    
    @ViewBuilder
    private func NavigationIcon() -> some View {
        // BORDERLESS DESIGN: Navigation icon with system colors
        Image(systemName: "arrow.right")
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(.blue)
            .opacity(1.0) // Explicit opacity to prevent visibility issues
    }
    
    @ViewBuilder
    private func ProcessingSpinner() -> some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            .scaleEffect(0.8)
    }
    
    @ViewBuilder
    private func VoiceWaveAnimation() -> some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { index in
                VoiceWaveBar(
                    index: index,
                    isAnimating: isVoiceAnimating
                )
            }
        }
    }
}

// MARK: - Supporting Components

/// Individual voice wave bar for animation
struct VoiceWaveBar: View {
    let index: Int
    let isAnimating: Bool
    
    @State private var height: CGFloat = 3
    
    private let minHeight: CGFloat = 3
    private let maxHeight: CGFloat = 18
    
    var body: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(Color.blue)
            .frame(width: 3, height: height)
            .animation(
                .easeInOut(duration: 0.4)
                .repeatForever(autoreverses: true)
                .delay(Double(index) * 0.1),
                value: height
            )
            .onAppear {
                if isAnimating {
                    startAnimation()
                }
            }
            .onChange(of: isAnimating) { animating in
                // CRITICAL FIX: Smooth animation state changes
                withAnimation(.easeInOut(duration: 0.2)) {
                    if animating {
                        startAnimation()
                    } else {
                        stopAnimation()
                    }
                }
            }
    }
    
    private func startAnimation() {
        height = CGFloat.random(in: minHeight...maxHeight)
    }
    
    private func stopAnimation() {
        height = minHeight
    }
}

/// Custom button style for voice animation button
struct VoiceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Voice Animation Button - Idle") {
    VStack(spacing: 20) {
        VoiceAnimationButton(
            isVoiceAnimating: .constant(false),
            isProcessing: .constant(false),
            isEnabled: true
        ) {
            print("Navigation button tapped")
        }
        
        Text("Idle State")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .padding()
}

#Preview("Voice Animation Button - Animating") {
    VStack(spacing: 20) {
        VoiceAnimationButton(
            isVoiceAnimating: .constant(true),
            isProcessing: .constant(false),
            isEnabled: true
        ) {
            print("Navigation button tapped")
        }
        
        Text("Voice Animating")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .padding()
}

#Preview("Voice Animation Button - Processing") {
    VStack(spacing: 20) {
        VoiceAnimationButton(
            isVoiceAnimating: .constant(false),
            isProcessing: .constant(true),
            isEnabled: true
        ) {
            print("Navigation button tapped")
        }
        
        Text("Processing State")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .padding()
}

#Preview("Voice Animation Button - Disabled") {
    VStack(spacing: 20) {
        VoiceAnimationButton(
            isVoiceAnimating: .constant(false),
            isProcessing: .constant(false),
            isEnabled: false
        ) {
            print("Navigation button tapped")
        }
        
        Text("Disabled State")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .padding()
}