import SwiftUI
import CoreLocation
import AVFoundation
import MapKit

struct ContentView: View {
    @ObservedObject var locationManager = LocationManager.shared
    @StateObject private var speechManager = SpeechManager()
    @StateObject private var agentManager = AIAgentManager()
    @EnvironmentObject var appStateManager: AppStateManager
    @EnvironmentObject var roadtripSession: RoadtripSession
    
    @State private var animatingButton: String? = nil
    
    var body: some View {
        ZStack {
            // Fullscreen Background Image
            Group {
                if let currentPOI = agentManager.currentPOI {
                    AsyncImage(url: currentPOI.imageURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            )
                    }
                } else {
                    // Default Morro Rock image
                    Image("MorroRock")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            
            // Content overlay
            VStack(spacing: 0) {
                // Add proper safe area padding at the top
                Color.clear
                    .frame(height: 16) // Add 16 pixels total to top safe area to prevent clipping
                
                // Top Status Bar with semi-transparent background
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Spacer().frame(width: 6) // 6px left padding
                        
                        // Back Button
                        Button(action: {
                            appStateManager.returnToDestinationSelection()
                            roadtripSession.pauseSession()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                Text("Back")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 8) // Increase touch target for automotive
                            .padding(.vertical, 4)
                        }
                        .accessibilityLabel("Back to destination selection")
                        
                        Spacer()
                        
                        // Destination Info with Distance in center (moved from second row)
                        if appStateManager.isInActiveRoadtrip {
                            HStack(spacing: 4) {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.white)
                                    .font(.caption)
                                
                                Text("To: \(appStateManager.destinationInfo), Trip: \(formattedDistanceToDestination)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                        } else {
                            Text("Roadtrip-Copilot")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        // Speed and Location Info Stack
                        VStack(alignment: .trailing, spacing: 2) {
                            // Speed display (compact format)
                            HStack(spacing: 4) {
                                Image(systemName: "speedometer")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                
                                Text("\(Int(locationManager.currentSpeedMPH)) mph")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .animation(.easeInOut(duration: 0.3), value: locationManager.currentSpeedMPH)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Capsule())
                            
                            // Location Info - Single line to prevent breaking
                            HStack(spacing: 4) {
                                if let city = locationManager.currentCity, let state = locationManager.currentState {
                                    Text("\(city), \(state)")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                } else if let city = locationManager.currentCity {
                                    Text(city)
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                } else if let state = locationManager.currentState {
                                    Text(state)
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                    
                }
                .padding(.horizontal, 16) // Automotive standard: 16px minimum edge margins
                .padding(.vertical, 16) // Increased vertical padding to prevent clipping
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.7), Color.black.opacity(0.3), Color.clear]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                Spacer()
                
                // POI Name Overlay (if available)
                if let currentPOI = agentManager.currentPOI {
                    VStack {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.white)
                            Text(currentPOI.name)
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding()
                        .background(Color.black.opacity(0.6))
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                }
                
                // Bottom Control Buttons with compact gray background
                VStack {
                    HStack {
                    // Previous Button
                    VoiceAnimatedButton(
                        action: { agentManager.previousPOI() },
                        icon: "chevron.left.circle.fill",
                        label: "Previous",
                        color: .purple,
                        actionKey: "previous",
                        isAnimating: animatingButton == "previous"
                    )
                    
                    Spacer()
                    
                    // Save/Favorite Button
                    VoiceAnimatedButton(
                        action: { agentManager.favoriteCurrentPOI() },
                        icon: "heart.fill",
                        label: "Save",
                        color: .red,
                        actionKey: "save",
                        isAnimating: animatingButton == "save"
                    )
                    
                    Spacer()
                    
                    // Like Button
                    VoiceAnimatedButton(
                        action: { agentManager.likeCurrentPOI() },
                        icon: "hand.thumbsup.fill",
                        label: "Like",
                        color: .green,
                        actionKey: "like",
                        isAnimating: animatingButton == "like"
                    )
                    
                    Spacer()
                    
                    // Dislike Button
                    VoiceAnimatedButton(
                        action: { agentManager.dislikeCurrentPOI() },
                        icon: "hand.thumbsdown.fill",
                        label: "Dislike",
                        color: .orange,
                        actionKey: "dislike",
                        isAnimating: animatingButton == "dislike"
                    )
                    
                    Spacer()
                    
                    // Navigate Button with Speech Animation
                    VoiceAnimatedButton(
                        action: { handleNavigateAction() },
                        icon: "location.fill",
                        label: "Navigate",
                        color: .blue,
                        actionKey: "navigate",
                        isAnimating: animatingButton == "navigate",
                        showVoiceWave: speechManager.isVoiceDetected || speechManager.isSpeaking
                    )
                    
                    Spacer()
                    
                    // Call Button
                    VoiceAnimatedButton(
                        action: { handleCallAction() },
                        icon: "phone.fill",
                        label: "Call",
                        color: Color(red: 0.0, green: 0.7, blue: 0.0),
                        actionKey: "call",
                        isAnimating: animatingButton == "call"
                    )
                    
                    Spacer()
                    
                    // Exit Button (moved to second-to-last position) - Returns to destination selection like back button
                    VoiceAnimatedButton(
                        action: {
                            appStateManager.returnToDestinationSelection()
                            roadtripSession.pauseSession()
                        },
                        icon: "xmark.circle.fill",
                        label: "Exit",
                        color: .red,
                        actionKey: "exit",
                        isAnimating: animatingButton == "exit"
                    )
                    
                    Spacer()
                    
                    // Next Button (moved to last position)
                    VoiceAnimatedButton(
                        action: { agentManager.nextPOI() },
                        icon: "chevron.right.circle.fill",
                        label: "Next",
                        color: .purple,
                        actionKey: "next",
                        isAnimating: animatingButton == "next"
                    )
                    }
                    .padding(.horizontal, 4) // 4px margin from screen edges
                    .padding(.top, 8) // 8px top margin for better visibility
                    
                    // Consistent bottom spacing
                    Spacer()
                        .frame(height: 12)
                }
                .background(
                    // Reduced height gray bar for smaller icon-only buttons
                    Rectangle()
                        .fill(Color.black.opacity(0.4))
                        .frame(maxWidth: .infinity)
                        .frame(height: 68) // Reduced height for smaller buttons
                        .ignoresSafeArea() // Extend to edges
                )
            }
            .edgesIgnoringSafeArea(.bottom) // Allow bottom bar to extend to edge
        }
        .onAppear {
            setupBackgroundOperations()
            setupVoiceCommandObservers()
            setupAppLifecycleObservers()
            
            // Auto-start speech recognition when entering main screen
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                speechManager.startListening()
            }
        }
    }
    
    private func setupBackgroundOperations() {
        locationManager.startLocationUpdates()
        locationManager.enableBackgroundLocationUpdates()
        agentManager.startBackgroundAgents()
    }
    
    private func setupAppLifecycleObservers() {
        // Monitor app state changes to maintain speech recognition in background
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            print("App entered background - maintaining speech recognition")
            // Speech recognition continues in background thanks to audio session configuration
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            print("App entering foreground - ensuring speech recognition is active")
            // Ensure speech recognition is still active when returning to foreground
            if !speechManager.isListening {
                speechManager.startListening()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            print("App became active")
            // Refresh any UI state that might have changed while in background
        }
    }
    
    private func setupVoiceCommandObservers() {
        // Listen for button animation commands
        NotificationCenter.default.addObserver(
            forName: .voiceCommandButtonAnimation,
            object: nil,
            queue: .main
        ) { notification in
            if let action = notification.object as? String {
                animateButton(action)
            }
        }
        
        // Listen for voice command actions
        NotificationCenter.default.addObserver(
            forName: .voiceCommandAction,
            object: nil,
            queue: .main
        ) { notification in
            if let data = notification.object as? [String: String],
               let action = data["action"] {
                executeButtonAction(action)
            }
        }
        
        // Listen for app foreground requests
        NotificationCenter.default.addObserver(
            forName: .bringAppToForeground,
            object: nil,
            queue: .main
        ) { _ in
            // Bring app to foreground by making a system call or triggering UI update
            // This will make the UI responsive when voice commands are received in background
            if let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
               let window = windowScene.windows.first {
                window.makeKeyAndVisible()
            }
        }
    }
    
    private func animateButton(_ action: String) {
        animatingButton = action
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            animatingButton = nil
        }
    }
    
    private func executeButtonAction(_ action: String) {
        switch action {
        case "save":
            agentManager.favoriteCurrentPOI()
        case "like":
            agentManager.likeCurrentPOI()
        case "dislike":
            agentManager.dislikeCurrentPOI()
        case "next":
            agentManager.nextPOI()
        case "previous":
            agentManager.previousPOI()
        case "navigate":
            handleNavigateAction()
        case "call":
            handleCallAction()
        case "exit", "back": // CRITICAL FIX: Add back voice command support
            print("[ContentView] Back/Exit command received - returning to destination selection")
            speechManager.speak("Going back to destination selection")
            appStateManager.returnToDestinationSelection()
            roadtripSession.pauseSession()
        default:
            break
        }
    }
    
    private func handleNavigateAction() {
        guard let currentPOI = agentManager.currentPOI else {
            print("No current POI available for navigation")
            speechManager.speak("No destination selected for navigation")
            return
        }
        
        let latitude = currentPOI.location.coordinate.latitude
        let longitude = currentPOI.location.coordinate.longitude
        let name = currentPOI.name
        
        print("Navigate action triggered for \(name) at \(latitude), \(longitude)")
        
        // Create MKMapItem for the POI
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = name
        
        // Open in Apple Maps with navigation
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault,
            MKLaunchOptionsShowsTrafficKey: true
        ])
        
        speechManager.speak("Opening navigation to \(name)")
        print("Opened Apple Maps for navigation to \(name)")
    }
    
    private func handleCallAction() {
        guard let currentPOI = agentManager.currentPOI else {
            print("No current POI available for calling")
            speechManager.speak("No location selected for calling")
            return
        }
        
        guard let phoneNumber = currentPOI.phoneNumber, !phoneNumber.isEmpty else {
            print("No phone number available for \(currentPOI.name)")
            speechManager.speak("No phone number available for this location")
            return
        }
        
        // Clean phone number (remove any formatting characters except + and digits)
        let cleanPhoneNumber = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.union(CharacterSet(charactersIn: "+")).inverted).joined()
        
        guard !cleanPhoneNumber.isEmpty else {
            print("Invalid phone number format: \(phoneNumber)")
            speechManager.speak("Invalid phone number format")
            return
        }
        
        // Create phone URL
        guard let phoneURL = URL(string: "tel://\(cleanPhoneNumber)") else {
            print("Could not create phone URL from: \(cleanPhoneNumber)")
            speechManager.speak("Could not create phone call")
            return
        }
        
        // Check if device can make phone calls
        if UIApplication.shared.canOpenURL(phoneURL) {
            UIApplication.shared.open(phoneURL, options: [:]) { success in
                if success {
                    print("Opened phone app to call \(cleanPhoneNumber) for \(currentPOI.name)")
                } else {
                    print("Failed to open phone app")
                }
            }
            speechManager.speak("Calling \(currentPOI.name)")
        } else {
            print("Device cannot make phone calls")
            speechManager.speak("Phone calls not available on this device")
        }
    }
    
    private var formattedElapsedTime: String {
        let elapsedTime = roadtripSession.elapsedTime
        let hours = Int(elapsedTime) / 3600
        let minutes = Int(elapsedTime) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private var formattedDistanceToDestination: String {
        guard let currentLocation = locationManager.currentLocation,
              let destination = appStateManager.selectedDestination else {
            return "0m"
        }
        
        let destinationLocation = CLLocation(
            latitude: destination.placemark.coordinate.latitude,
            longitude: destination.placemark.coordinate.longitude
        )
        
        let distanceInMeters = currentLocation.distance(from: destinationLocation)
        let distanceInMiles = distanceInMeters * 0.000621371 // Convert meters to miles
        
        // Format based on distance
        if distanceInMiles < 0.1 {
            return "0m"
        } else if distanceInMiles < 1.0 {
            return String(format: "%.1fm", distanceInMiles)
        } else if distanceInMiles < 10.0 {
            return String(format: "%.1fm", distanceInMiles)
        } else {
            return String(format: "%.0fm", distanceInMiles)
        }
    }
}

// MARK: - Voice Animated Button Component (Icon-Only Platform Parity Design)
struct VoiceAnimatedButton: View {
    let action: () -> Void
    let icon: String
    let label: String
    let color: Color
    let actionKey: String
    let isAnimating: Bool
    let showVoiceWave: Bool
    
    init(action: @escaping () -> Void, icon: String, label: String, color: Color, actionKey: String, isAnimating: Bool, showVoiceWave: Bool = false) {
        self.action = action
        self.icon = icon
        self.label = label
        self.color = color
        self.actionKey = actionKey
        self.isAnimating = isAnimating
        self.showVoiceWave = showVoiceWave
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Icon-only design - no circular background (48pt touch target, 32pt icon)
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 48, height: 48) // 48pt touch target matching Android Auto
                
                if showVoiceWave && actionKey == "navigate" {
                    // Show voice wave animation for navigate button
                    VoiceWaveAnimation()
                        .scaleEffect(0.6) // Smaller scale for icon-only design
                } else {
                    // Show icon only - no background circle
                    Image(systemName: icon)
                        .font(.system(size: 32, weight: .semibold)) // 32pt icon size
                        .foregroundColor(isAnimating ? color.opacity(0.8) : color)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1) // Subtle shadow for visibility
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                }
            }
            .scaleEffect(isAnimating ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: isAnimating)
            .animation(.easeInOut(duration: 0.3), value: showVoiceWave)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(label)
        .accessibilityHint("Double tap to \(label.lowercased())")
    }
}


// MARK: - HMI Button Style (Icon-Only Platform Parity Design)
struct HMIButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}


#Preview {
    ContentView()
}