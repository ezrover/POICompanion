import SwiftUI
import CoreLocation

@available(iOS 15.0, *)
struct SetDestinationScreen: View {
    @StateObject private var speechManager = SpeechManager()
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var autoDiscoverManager = AutoDiscoverManager.shared
    @EnvironmentObject var appStateManager: AppStateManager
    
    @State private var destinationInput = ""
    @State private var isMicMuted = false
    @State private var showVoiceAnimation = false
    @State private var buttonState: ButtonState = .idle
    
    // Voice recognition states
    @State private var isListening = false
    @State private var recognizedText = ""
    @State private var isVoiceDetected = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.4)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Header
                    VStack(spacing: 16) {
                        Text("Set Your Destination")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .accessibilityIdentifier("destinationTitle")
                        
                        Text("Where would you like to explore?")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.9))
                            .accessibilityIdentifier("destinationSubtitle")
                    }
                    .padding(.horizontal)
                    
                    // Main Action Buttons
                    VStack(spacing: 24) {
                        // Manual Destination Entry Card
                        DestinationInputCard(
                            destinationInput: $destinationInput,
                            isMicMuted: $isMicMuted,
                            showVoiceAnimation: $showVoiceAnimation,
                            buttonState: $buttonState,
                            speechManager: speechManager,
                            onNavigate: { destination in
                                handleNavigation(destination: destination)
                            }
                        )
                        
                        // Voice Search Button
                        ActionButton(
                            title: "Voice Search",
                            subtitle: "Tell me where to go",
                            icon: "mic.fill",
                            color: DesignTokens.ButtonColor.voiceBackground,
                            action: {
                                startVoiceSearch()
                            }
                        )
                        .accessibilityIdentifier("voiceSearchButton")
                        
                        // Auto Discover Button (NEW)
                        ActionButton(
                            title: "Auto Discover",
                            subtitle: "Find amazing places nearby",
                            icon: "location.magnifyingglass",
                            color: Color.orange,
                            action: {
                                startAutoDiscover()
                            }
                        )
                        .accessibilityIdentifier("autoDiscoverButton")
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Voice Status Indicator
                    if isListening || !recognizedText.isEmpty {
                        VoiceStatusCard(
                            isListening: isListening,
                            recognizedText: recognizedText
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            setupVoiceRecognition()
        }
        .onReceive(speechManager.$isListening) { listening in
            isListening = listening
        }
        .onReceive(speechManager.$recognizedText) { text in
            recognizedText = text
            if !text.isEmpty {
                destinationInput = text
                handleVoiceInput(text)
            }
        }
        .onReceive(speechManager.$isVoiceDetected) { detected in
            isVoiceDetected = detected
            showVoiceAnimation = detected && isListening
        }
    }
    
    // MARK: - Private Methods
    
    private func setupVoiceRecognition() {
        // AUTO-START VOICE RECOGNITION (Platform Parity requirement)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if !isMicMuted {
                speechManager.startListening()
                print("[SetDestinationScreen] Voice recognition auto-started on screen entry")
            }
        }
    }
    
    private func startVoiceSearch() {
        if !speechManager.isListening {
            speechManager.startListening()
        }
        speechManager.speak("Listening for your destination")
    }
    
    private func startAutoDiscover() {
        print("[SetDestinationScreen] Auto Discover initiated")
        speechManager.speak("Finding amazing places nearby")
        
        Task {
            do {
                // Start auto discovery
                await autoDiscoverManager.startAutoDiscovery()
                
                // Transition to MainPOIView in discovery mode
                await MainActor.run {
                    appStateManager.enterDiscoveryMode()
                }
            } catch {
                print("[SetDestinationScreen] Auto Discovery failed: \(error)")
                speechManager.speak("Sorry, discovery is not available right now")
            }
        }
    }
    
    private func handleVoiceInput(_ input: String) {
        let navigationCommands = ["go", "navigate", "start", "begin"]
        let hasNavigationCommand = navigationCommands.contains { 
            input.lowercased().contains($0) 
        }
        
        if hasNavigationCommand {
            // Extract destination without the command
            var cleanDestination = input
            navigationCommands.forEach { command in
                cleanDestination = cleanDestination.replacingOccurrences(
                    of: command,
                    with: "",
                    options: .caseInsensitive
                ).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            if !cleanDestination.isEmpty {
                handleNavigation(destination: cleanDestination)
            }
        }
    }
    
    private func handleNavigation(destination: String) {
        guard !destination.isEmpty else { return }
        
        print("[SetDestinationScreen] Navigating to: \(destination)")
        speechManager.speak("Navigating to \(destination)")
        
        // Store destination and transition to POI view
        appStateManager.setDestination(destination)
    }
}

// MARK: - Supporting Views

struct DestinationInputCard: View {
    @Binding var destinationInput: String
    @Binding var isMicMuted: Bool
    @Binding var showVoiceAnimation: Bool
    @Binding var buttonState: ButtonState
    let speechManager: SpeechManager
    let onNavigate: (String) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                // Destination Input Field
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.secondary)
                    
                    TextField("Where would you like to go?", text: $destinationInput)
                        .font(.body)
                        .onSubmit {
                            if !destinationInput.isEmpty {
                                onNavigate(destinationInput)
                            }
                        }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
                
                // Go/Navigate Button
                Button(action: {
                    if !destinationInput.isEmpty {
                        onNavigate(destinationInput)
                    }
                }) {
                    Group {
                        if showVoiceAnimation {
                            VoiceWaveAnimation()
                                .frame(width: 24, height: 24)
                        } else {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title2)
                        }
                    }
                    .foregroundColor(destinationInput.isEmpty ? .secondary : .white)
                    .frame(width: DesignTokens.TouchTarget.minimum, height: DesignTokens.TouchTarget.minimum)
                }
                .background(destinationInput.isEmpty ? Color.secondary.opacity(0.3) : DesignTokens.ButtonColor.primaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
                .disabled(destinationInput.isEmpty)
                .accessibilityIdentifier("navigateButton")
                
                // Mic Button (Mute/Unmute Toggle Only)
                Button(action: {
                    isMicMuted.toggle()
                    if isMicMuted {
                        speechManager.mute()
                    } else {
                        speechManager.unmute()
                    }
                }) {
                    Image(systemName: isMicMuted ? "mic.slash.fill" : "mic.fill")
                        .font(.title2)
                        .foregroundColor(isMicMuted ? .red : .white)
                        .frame(width: DesignTokens.TouchTarget.minimum, height: DesignTokens.TouchTarget.minimum)
                }
                .background(isMicMuted ? Color.red.opacity(0.2) : DesignTokens.ButtonColor.voiceBackground)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
                .accessibilityIdentifier("micButton")
            }
        }
        .padding(20)
        .background(Color(.systemBackground).opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct ActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
            .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct VoiceStatusCard: View {
    let isListening: Bool
    let recognizedText: String
    
    var body: some View {
        VStack(spacing: 8) {
            if isListening {
                HStack {
                    VoiceWaveAnimation()
                        .frame(width: 20, height: 20)
                    Text("Listening...")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
            }
            
            if !recognizedText.isEmpty {
                Text("Recognized: \"\(recognizedText)\"")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
        .animation(.easeInOut(duration: 0.3), value: isListening)
        .animation(.easeInOut(duration: 0.3), value: recognizedText)
    }
}

// MARK: - Button State Enum

enum ButtonState {
    case idle
    case voiceDetecting
    case processing
    case success
    case error
}

// MARK: - Voice Wave Animation

struct VoiceWaveAnimation: View {
    @State private var animating = false
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<4) { index in
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 3, height: animating ? 15 : 5)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(Double(index) * 0.1),
                        value: animating
                    )
            }
        }
        .onAppear {
            animating = true
        }
    }
}

#Preview {
    if #available(iOS 15.0, *) {
        SetDestinationScreen()
            .environmentObject(AppStateManager())
    }
}