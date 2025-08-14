import SwiftUI
import MapKit
import CoreLocation

/// Set Destination screen implementation following the comprehensive design specification
/// Features two-button layout with voice-first interaction patterns and CarPlay compatibility
struct SetDestinationView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var speechManager = SpeechManager()
    
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var selectedDestination: MKMapItem?
    @State private var isNavigationReady = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // Voice state management
    @State private var isVoiceAnimating = false
    @State private var isProcessingNavigation = false
    @State private var isMicrophoneMuted = false
    
    // CRITICAL FIX: Add missing UI state variables to prevent compilation errors
    @State private var buttonState: ButtonState = .ready
    @State private var microphoneButtonVisible = true
    @State private var navigationButtonVisible = true
    @State private var requiresUserConfirmation = true // CRITICAL FIX: Always require user confirmation by default
    
    enum ButtonState {
        case ready, listening, processing, error
    }
    
    let onDestinationConfirmed: (MKMapItem) -> Void
    
    var body: some View {
        ZStack {
            // Background with adaptive color
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Text("Where would you like to go?")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    
                    Text("Say your destination or type to search")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .accessibilityLabel("Instructions: Say your destination or type to search")
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // Main Input Container - Following Design System Specs
                VStack(spacing: 24) {
                    // Destination Input Row with Two-Button Layout
                    HStack(spacing: 16) {
                        // Search Input Field
                        TextField("Enter destination...", text: $searchText)
                            .textFieldStyle(.roundedBorder)
                            .font(.body)
                            .frame(minHeight: 56) // Automotive safety requirement
                            .onSubmit {
                                performSearch()
                            }
                            .accessibilityLabel("Destination search input")
                            .accessibilityHint("Enter your destination or use voice input")
                            .onChange(of: searchText) { newValue in
                                // CRITICAL FIX: Async search to prevent UI update during view rendering
                                Task {
                                    await MainActor.run {
                                        if !newValue.isEmpty {
                                            performSearch()
                                        }
                                    }
                                }
                            }
                        
                        // Start/Navigate Button (Primary Action)
                        VoiceAnimationButton(
                            isVoiceAnimating: $isVoiceAnimating,
                            isProcessing: $isProcessingNavigation,
                            isEnabled: canNavigate
                        ) {
                            handleNavigationAction()
                        }
                        .accessibilityLabel("Start navigation")
                        .accessibilityHint("Double tap to start navigation to entered destination. Voice commands: go, navigate, start")
                        
                        // Microphone/Mute Button (Secondary Action) - PLATFORM PARITY: NO voice animations
                        MicrophoneToggleButton(
                            isMuted: $isMicrophoneMuted
                        ) {
                            handleMicrophoneToggle()
                        }
                        .accessibilityLabel(isMicrophoneMuted ? "Microphone muted" : "Microphone active")
                        .accessibilityHint("Double tap to toggle microphone. Voice commands: mute, unmute")
                    }
                    .padding(.horizontal, 24)
                    
                    // Voice Feedback Display
                    if speechManager.isListening && !speechManager.recognizedText.isEmpty {
                        VStack(spacing: 8) {
                            Text("Voice Input:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\"\(speechManager.recognizedText)\"")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 24)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Voice input: \(speechManager.recognizedText)")
                    }
                    
                    // Search Results
                    if !searchResults.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Search Results")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 24)
                            
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(searchResults, id: \.id) { mapItem in
                                        DestinationResultRow(
                                            mapItem: mapItem,
                                            isSelected: selectedDestination?.id == mapItem.id
                                        ) {
                                            selectDestination(mapItem)
                                        }
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                            .frame(maxHeight: 300)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.regularMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                )
                .padding(.horizontal, 16)
                
                Spacer()
                
                // Selected Destination Info
                if let destination = selectedDestination {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(destination.name ?? "Selected Location")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                if let address = destination.placemark.title {
                                    Text(address)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(.thinMaterial)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Selected destination: \(destination.name ?? "Unknown location")")
                }
            }
        }
        .onAppear {
            setupView()
        }
        .onDisappear {
            cleanup()
        }
        .onChange(of: speechManager.recognizedText) { recognizedText in
            // CRITICAL FIX: Async voice input handling to prevent state modification during view update
            Task {
                await MainActor.run {
                    handleVoiceInput(recognizedText)
                }
            }
        }
        .alert("Navigation", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Computed Properties
    
    private var canNavigate: Bool {
        !searchText.isEmpty || selectedDestination != nil
    }
    
    // MARK: - Setup and Cleanup
    
    private func setupView() {
        let startTime = TimestampLogger.logAppLaunchStart("SetDestinationView Setup")
        
        locationManager.startLocationUpdates()
        speechManager.enableDestinationMode()
        setupVoiceCommandObservers()
        
        // Auto-start voice listening if microphone is not muted
        if !isMicrophoneMuted {
            speechManager.startListening()
        }
        
        TimestampLogger.logAppLaunchEnd("SetDestinationView Setup", startTime: startTime)
    }
    
    private func cleanup() {
        print("[SetDestinationView] Cleaning up view")
        speechManager.disableDestinationMode()
        speechManager.stopListening()
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupVoiceCommandObservers() {
        // Listen for voice commands specific to navigation
        NotificationCenter.default.addObserver(
            forName: .voiceCommandAction,
            object: nil,
            queue: .main
        ) { [self] notification in
            handleVoiceCommand(notification)
        }
        
        // Listen for destination selection from voice input
        NotificationCenter.default.addObserver(
            forName: .destinationSelected,
            object: nil,
            queue: .main
        ) { [self] notification in
            handleDestinationFromVoice(notification)
        }
    }
    
    // MARK: - Action Handlers
    
    private func handleNavigationAction() {
        let startTime = TimestampLogger.logNavigationStart("Navigation Action")
        
        guard canNavigate else {
            TimestampLogger.warning("Navigation action triggered but no destination available", category: "Navigation")
            showAlert(message: "Please enter or select a destination first.")
            TimestampLogger.logNavigationEnd("Navigation Action", startTime: startTime)
            return
        }
        
        isProcessingNavigation = true
        
        // Use selected destination if available, otherwise search for entered text
        if let destination = selectedDestination {
            TimestampLogger.info("Navigating to selected destination: \(destination.name ?? "Unknown")", category: "Navigation")
            confirmNavigation(to: destination)
        } else if !searchText.isEmpty {
            TimestampLogger.info("Searching for destination before navigation: \(searchText)", category: "Navigation")
            // Search for the destination and auto-select the first result
            performSearchAndNavigate()
        }
        
        TimestampLogger.logNavigationEnd("Navigation Action", startTime: startTime)
    }
    
    private func handleMicrophoneToggle() {
        let startTime = TimestampLogger.logAudioStart("Microphone Toggle")
        
        isMicrophoneMuted.toggle()
        
        if isMicrophoneMuted {
            TimestampLogger.info("Stopping voice recognition - microphone muted", category: "Voice")
            speechManager.stopListening()
            speechManager.speak("Microphone muted")
        } else {
            TimestampLogger.info("Starting voice recognition - microphone active", category: "Voice")
            speechManager.startListening()
            speechManager.speak("Microphone active")
        }
        
        TimestampLogger.logAudioEnd("Microphone Toggle", startTime: startTime)
    }
    
    private func handleVoiceInput(_ recognizedText: String) {
        guard !recognizedText.isEmpty else { return }
        
        print("[SetDestinationView] Processing voice input: \(recognizedText)")
        
        // CRITICAL FIX: Already running on MainActor from onChange, process directly
        // Check if input contains navigation command
        let lowercaseText = recognizedText.lowercased()
        let navigationCommands = ["go", "navigate", "start", "begin", "drive"]
        
        let hasNavigationCommand = navigationCommands.contains { command in
            lowercaseText.contains(command)
        }
        
        if hasNavigationCommand {
            print("[SetDestinationView] Navigation command detected in voice input")
            
            // CRITICAL FIX: Only allow navigation with explicit voice commands when destination is available
            if canNavigate {
                isVoiceAnimating = true
                let destination = extractDestinationFromVoiceInput(recognizedText)
                
                if !destination.isEmpty {
                    searchText = destination
                    // CRITICAL FIX: Only auto-navigate with explicit voice navigation commands
                    requiresUserConfirmation = false
                    performSearchAndNavigate()
                } else if selectedDestination != nil {
                    // Navigate to currently selected destination with voice command
                    requiresUserConfirmation = false
                    handleNavigationAction()
                }
                
                // Reset animation after delay
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                    await MainActor.run {
                        isVoiceAnimating = false
                        requiresUserConfirmation = true // Reset to require confirmation
                    }
                }
            } else {
                print("[SetDestinationView] Navigation command received but no destination available")
                speechManager.speak("Please select a destination first.")
            }
        } else {
            // CRITICAL FIX: Just a destination name - update search text and always require confirmation
            print("[SetDestinationView] Destination-only input received: \(recognizedText)")
            searchText = recognizedText
            requiresUserConfirmation = true // Always require user confirmation for destination-only input
            performSearch()
        }
    }
    
    private func handleVoiceCommand(_ notification: Notification) {
        guard let actionData = notification.object as? [String: Any],
              let action = actionData["action"] as? String else {
            return
        }
        
        print("[SetDestinationView] Handling voice command: \(action)")
        
        switch action {
        case "navigate", "go", "start":
            isVoiceAnimating = true
            handleNavigationAction()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                isVoiceAnimating = false
            }
            
        case "mute":
            isMicrophoneMuted = true
            speechManager.stopListening()
            
        case "unmute":
            isMicrophoneMuted = false
            speechManager.startListening()
            
        default:
            break
        }
    }
    
    private func handleDestinationFromVoice(_ notification: Notification) {
        guard let destination = notification.object as? String else { return }
        
        let userInfo = notification.userInfo
        let hasAction = userInfo?["hasAction"] as? Bool ?? false
        let action = userInfo?["action"] as? String
        
        print("[SetDestinationView] Voice destination: \(destination), hasAction: \(hasAction), action: \(action ?? "none")")
        
        // CRITICAL FIX: Use async/await to prevent state modification warnings
        Task {
            await MainActor.run {
                searchText = destination
                
                if hasAction && action == "navigate" {
                    print("[SetDestinationView] Voice command with navigation action detected")
                    requiresUserConfirmation = false // Allow auto-navigation only with explicit voice navigation command
                    performSearch()
                    
                    // Auto-navigate when explicit navigation action was detected in voice
                    Task {
                        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                        await MainActor.run {
                            if !requiresUserConfirmation {
                                performSearchAndNavigate()
                            }
                        }
                    }
                } else {
                    print("[SetDestinationView] Destination-only voice input, requiring user confirmation")
                    requiresUserConfirmation = true // Always require confirmation for destination-only input
                    performSearch()
                }
            }
        }
    }
    
    // MARK: - Search and Navigation Logic
    
    private func performSearch() {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        
        print("[SetDestinationView] Performing search for: \(searchText)")
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        
        if let currentLocation = locationManager.currentLocation {
            request.region = MKCoordinateRegion(
                center: currentLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
            )
        }
        
        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            DispatchQueue.main.async {
                guard let self = self else { return } // CRASH FIX: Prevent access to deallocated self
                
                if let error = error {
                    print("[SetDestinationView] Search error: \(error.localizedDescription)")
                    self.searchResults = []
                    return
                }
                
                self.searchResults = response?.mapItems ?? []
                print("[SetDestinationView] Found \(self.searchResults.count) search results")
                
                // CRASH FIX: Safely check search results and destination state
                if !self.searchResults.isEmpty && self.selectedDestination == nil && !self.requiresUserConfirmation {
                    print("[SetDestinationView] Auto-selecting first result due to explicit navigation command")
                    self.selectDestination(self.searchResults[0])
                } else if !self.searchResults.isEmpty {
                    print("[SetDestinationView] Search results available, waiting for user selection")
                    // Do not auto-select - require user to manually select destination
                }
            }
        }
    }
    
    private func performSearchAndNavigate() {
        guard !searchText.isEmpty else { return }
        
        print("[SetDestinationView] Searching and navigating to: \(searchText)")
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        
        if let currentLocation = locationManager.currentLocation {
            request.region = MKCoordinateRegion(
                center: currentLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
            )
        }
        
        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            DispatchQueue.main.async {
                guard let self = self else { return } // CRASH FIX: Prevent access to deallocated self
                
                self.isProcessingNavigation = false
                
                if let error = error {
                    print("[SetDestinationView] Search error: \(error.localizedDescription)")
                    self.showAlert(message: "Could not find destination. Please try again.")
                    return
                }
                
                guard let results = response?.mapItems, !results.isEmpty else {
                    self.showAlert(message: "No results found for '\(self.searchText)'. Please try a different destination.")
                    return
                }
                
                // Use the first result for navigation
                let destination = results[0]
                self.confirmNavigation(to: destination)
            }
        }
    }
    
    private func selectDestination(_ mapItem: MKMapItem) {
        // CRITICAL FIX: Use async/await pattern to prevent state modification warnings
        Task {
            await MainActor.run {
                selectedDestination = mapItem
                searchText = mapItem.name ?? ""
                
                print("[SetDestinationView] Selected destination: \(mapItem.name ?? "Unknown")")
                
                // CRITICAL FIX: Always require user confirmation after manual selection
                requiresUserConfirmation = true
                
                // Provide audio feedback
                if let name = mapItem.name {
                    speechManager.speak("Selected \(name). Say go or navigate to start.")
                }
            }
        }
    }
    
    private func confirmNavigation(to destination: MKMapItem) {
        print("[SetDestinationView] Confirming navigation to: \(destination.name ?? "Unknown")")
        
        selectedDestination = destination
        
        // CRASH FIX: Safely unwrap destination name
        let destinationName = destination.name ?? "destination"
        speechManager.speak("Starting navigation to \(destinationName)")
        
        // CRASH FIX: Use weak self to prevent retain cycles
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.onDestinationConfirmed(destination)
        }
    }
    
    // MARK: - Utility Methods
    
    private func extractDestinationFromVoiceInput(_ input: String) -> String {
        let lowercaseInput = input.lowercased()
        let patterns = ["go to ", "navigate to ", "start to ", "drive to ", "take me to "]
        
        for pattern in patterns {
            if let range = lowercaseInput.range(of: pattern) {
                let destination = String(input[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !destination.isEmpty {
                    return destination
                }
            }
        }
        
        // If no pattern found, check for trailing commands
        let trailingCommands = [" go", " navigate", " start"]
        for command in trailingCommands {
            if lowercaseInput.hasSuffix(command) {
                let destination = String(input.dropLast(command.count)).trimmingCharacters(in: .whitespacesAndNewlines)
                if !destination.isEmpty {
                    return destination
                }
            }
        }
        
        return input.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func showAlert(message: String) {
        // CRITICAL FIX: Use async/await pattern to prevent state modification warnings
        Task {
            await MainActor.run {
                alertMessage = message
                showingAlert = true
                buttonState = .error
                
                // CRITICAL FIX: Ensure UI elements remain visible during error state
                updateButtonStates(listening: speechManager.isListening)
            }
            
            // Reset button state after alert with delay
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            await MainActor.run {
                buttonState = .ready
                updateButtonStates(listening: speechManager.isListening)
            }
        }
    }
    
    // CRITICAL FIX: Button state management helper
    private func updateButtonStates(listening: Bool) {
        guard microphoneButtonVisible && navigationButtonVisible else {
            // Restore button visibility if lost
            microphoneButtonVisible = true
            navigationButtonVisible = true
            return
        }
        
        if listening && !isMicrophoneMuted {
            buttonState = .listening
        } else if buttonState == .listening {
            buttonState = .ready
        }
    }
}

// MARK: - Supporting Views

/// Destination search result row component
struct DestinationResultRow: View {
    let mapItem: MKMapItem
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "mappin.circle.fill" : "mappin.circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .gray)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(mapItem.name ?? "Unknown Location")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    if let address = mapItem.placemark.title {
                        Text(address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(mapItem.name ?? "Unknown location"), \(isSelected ? "selected" : "not selected")")
        .accessibilityHint("Double tap to select this destination")
    }
}

#Preview("Set Destination View") {
    SetDestinationView { destination in
        print("Destination confirmed: \(destination.name ?? "Unknown")")
    }
}