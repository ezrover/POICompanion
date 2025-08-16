import SwiftUI
import CoreLocation
import AVFoundation
import MapKit

struct MainPOIView: View {
    @ObservedObject var locationManager = LocationManager.shared
    @StateObject private var speechManager = SpeechManager()
    @StateObject private var agentManager = AIAgentManager()
    @StateObject private var autoDiscoverManager = AutoDiscoverManager.shared
    @EnvironmentObject var appStateManager: AppStateManager
    @EnvironmentObject var roadtripSession: RoadtripSession
    
    @State private var animatingButton: String? = nil
    @State private var isDiscoveryMode = false
    
    var body: some View {
        ZStack {
            // Fullscreen Background Image with Auto-Cycling Support
            Group {
                if isDiscoveryMode, let currentPhoto = autoDiscoverManager.currentPhoto {
                    // Discovery mode - show auto-cycling photos
                    AsyncImage(url: currentPhoto) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .transition(.opacity)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            )
                    }
                    .animation(.easeInOut(duration: 0.5), value: autoDiscoverManager.currentPhotoIndex)
                } else if let currentPOI = agentManager.currentPOI {
                    // Normal mode - single POI image
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
                        .accessibilityIdentifier("backButton")
                        
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
                                    .accessibilityIdentifier("destinationInfo")
                            }
                        } else {
                            Text("Roadtrip-Copilot")
                                .font(.headline)
                                .foregroundColor(.white)
                                .accessibilityIdentifier("appTitle")
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
                                    .accessibilityIdentifier("speedIndicator")
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
                                        .accessibilityIdentifier("locationInfo")
                                } else if let city = locationManager.currentCity {
                                    Text(city)
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                        .accessibilityIdentifier("locationInfo")
                                } else if let state = locationManager.currentState {
                                    Text(state)
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                        .accessibilityIdentifier("locationInfo")
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
                if let currentPOI = (isDiscoveryMode ? autoDiscoverManager.currentPOI : agentManager.currentPOI) {
                    VStack {
                        HStack {
                            Image(systemName: isDiscoveryMode ? "location.magnifyingglass" : "location.fill")
                                .foregroundColor(.white)
                            Text(currentPOI.name)
                                .font(.headline)
                                .foregroundColor(.white)
                                .accessibilityIdentifier("currentPOIName")
                            
                            Spacer()
                            
                            // Discovery mode indicators
                            if isDiscoveryMode {
                                // Photo indicator
                                Text("\(autoDiscoverManager.currentPhotoIndex + 1)/\(autoDiscoverManager.currentPOIPhotos.count)")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                // POI position indicator
                                Text("POI \(autoDiscoverManager.currentPOIIndex + 1)/\(autoDiscoverManager.discoveredPOIs.count)")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
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
                        action: { 
                            if isDiscoveryMode {
                                autoDiscoverManager.previousPOI()
                            } else {
                                agentManager.previousPOI()
                            }
                        },
                        icon: "chevron.left.circle.fill",
                        label: "Previous",
                        color: .purple,
                        actionKey: "previous",
                        isAnimating: animatingButton == "previous"
                    )
                    .accessibilityIdentifier("previousPOIButton")
                    
                    Spacer()
                    
                    // Save/Favorite Button (Normal Mode) OR Search Button (Discovery Mode)
                    if isDiscoveryMode {
                        VoiceAnimatedButton(
                            action: { 
                                // Return to destination selection (back button functionality)
                                autoDiscoverManager.stopAutoDiscovery()
                                appStateManager.returnToDestinationSelection()
                                roadtripSession.pauseSession()
                            },
                            icon: "magnifyingglass",
                            label: "Search",
                            color: .blue,
                            actionKey: "search",
                            isAnimating: animatingButton == "search"
                        )
                        .accessibilityIdentifier("searchButton")
                    } else {
                        VoiceAnimatedButton(
                            action: { agentManager.favoriteCurrentPOI() },
                            icon: "heart.fill",
                            label: "Save",
                            color: .red,
                            actionKey: "save",
                            isAnimating: animatingButton == "save"
                        )
                        .accessibilityIdentifier("savePOIButton")
                    }
                    
                    Spacer()
                    
                    // Speak/Info Button (Discovery Mode Only)
                    if isDiscoveryMode {
                        VoiceAnimatedButton(
                            action: { handleSpeakInfoAction() },
                            icon: "speaker.wave.2.fill",
                            label: "Speak",
                            color: Color.purple,
                            actionKey: "speak",
                            isAnimating: animatingButton == "speak"
                        )
                        .accessibilityIdentifier("speakInfoButton")
                        
                        Spacer()
                    }
                    
                    // Like Button
                    VoiceAnimatedButton(
                        action: { agentManager.likeCurrentPOI() },
                        icon: "hand.thumbsup.fill",
                        label: "Like",
                        color: .green,
                        actionKey: "like",
                        isAnimating: animatingButton == "like"
                    )
                    .accessibilityIdentifier("likePOIButton")
                    
                    Spacer()
                    
                    // Dislike Button
                    VoiceAnimatedButton(
                        action: { 
                            if isDiscoveryMode {
                                autoDiscoverManager.dislikeCurrentPOI()
                            } else {
                                agentManager.dislikeCurrentPOI()
                            }
                        },
                        icon: "hand.thumbsdown.fill",
                        label: "Dislike",
                        color: .orange,
                        actionKey: "dislike",
                        isAnimating: animatingButton == "dislike"
                    )
                    .accessibilityIdentifier("dislikePOIButton")
                    
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
                    .accessibilityIdentifier("navigatePOIButton")
                    
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
                    .accessibilityIdentifier("callPOIButton")
                    
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
                    .accessibilityIdentifier("exitPOIButton")
                    
                    Spacer()
                    
                    // Next Button (moved to last position)
                    VoiceAnimatedButton(
                        action: { 
                            if isDiscoveryMode {
                                autoDiscoverManager.nextPOI()
                            } else {
                                agentManager.nextPOI()
                            }
                        },
                        icon: "chevron.right.circle.fill",
                        label: "Next",
                        color: .purple,
                        actionKey: "next",
                        isAnimating: animatingButton == "next"
                    )
                    .accessibilityIdentifier("nextPOIButton")
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
            
            // Check if we're in discovery mode
            isDiscoveryMode = autoDiscoverManager.isDiscoveryActive
            
            // Auto-start speech recognition when entering main screen
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                speechManager.startListening()
            }
        }
        .onReceive(autoDiscoverManager.$isDiscoveryActive) { active in
            isDiscoveryMode = active
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
            if isDiscoveryMode {
                autoDiscoverManager.nextPOI()
            } else {
                agentManager.nextPOI()
            }
        case "previous":
            if isDiscoveryMode {
                autoDiscoverManager.previousPOI()
            } else {
                agentManager.previousPOI()
            }
        case "navigate":
            handleNavigateAction()
        case "call":
            handleCallAction()
        case "speak", "info":
            if isDiscoveryMode {
                handleSpeakInfoAction()
            }
        case "search", "back", "exit":
            if isDiscoveryMode {
                print("[MainPOIView] Search/Back command received in discovery mode - returning to destination selection")
                autoDiscoverManager.stopAutoDiscovery()
                speechManager.speak("Returning to destination selection")
                appStateManager.returnToDestinationSelection()
                roadtripSession.pauseSession()
            } else {
                print("[MainPOIView] Back/Exit command received - returning to destination selection")
                speechManager.speak("Going back to destination selection")
                appStateManager.returnToDestinationSelection()
                roadtripSession.pauseSession()
            }
        case "dislike":
            if isDiscoveryMode {
                autoDiscoverManager.dislikeCurrentPOI()
            } else {
                agentManager.dislikeCurrentPOI()
            }
        default:
            break
        }
    }
    
    private func handleSpeakInfoAction() {
        guard let currentPOI = (isDiscoveryMode ? autoDiscoverManager.currentPOI : agentManager.currentPOI) else {
            print("No current POI available for speak info")
            speechManager.speak("No location information available")
            return
        }
        
        // Generate AI podcast content about the current POI
        let podcastContent = generatePOIPodcastContent(for: currentPOI)
        speechManager.speak(podcastContent)
        
        print("[MainPOIView] Speaking info about \(currentPOI.name)")
    }
    
    private func generatePOIPodcastContent(for poi: POI) -> String {
        // Basic podcast content generation
        // In a full implementation, this would use Gemma-3N to generate rich content
        
        var content = "Here's what I know about \(poi.name). "
        
        if !poi.description.isEmpty {
            content += "\(poi.description) "
        }
        
        if poi.rating > 0 {
            let ratingDescription = poi.rating >= 4.5 ? "excellent" : poi.rating >= 4.0 ? "very good" : poi.rating >= 3.5 ? "good" : "average"
            content += "This place has \(ratingDescription) reviews with a \(String(format: "%.1f", poi.rating)) star rating. "
        }
        
        // Add category information
        content += "It's categorized as \(poi.category.displayName). "
        
        // Add location context
        content += "This location offers a unique experience for roadtrip explorers. "
        
        content += "Would you like to navigate there or continue exploring?"
        
        return content
    }
    
    private func handleNavigateAction() {
        guard let currentPOI = (isDiscoveryMode ? autoDiscoverManager.currentPOI : agentManager.currentPOI) else {
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
    MainPOIView()
}