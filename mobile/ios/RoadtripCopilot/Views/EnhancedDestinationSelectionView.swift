import SwiftUI
import MapKit
import CoreLocation
import Foundation
import Combine

struct EnhancedDestinationSelectionView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var speechManager = SpeechManager()
    @StateObject private var userPreferences = UserPreferences()
    
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var selectedDestination: MKMapItem?
    @State private var isListening = false
    @State private var shouldNavigate = false
    @State private var isMicrophoneMuted = false
    @State private var isProcessingNavigation = false
    @State private var showPOIResult = false
    @State private var gemmaResponse = ""
    
    // Search state management to prevent concurrent requests
    @State private var isSearching = false
    @State private var currentSearchTask: MKLocalSearch?
    @State private var lastErrorMessage: String?
    @State private var errorMessageCount = 0
    private let maxRetryAttempts = 2
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )
    
    let savedDestinationName: String?
    let onComplete: (MKMapItem, UserPreferences) -> Void
    
    var body: some View {
        ZStack {
            // Full-screen map (edge to edge)
            Map(coordinateRegion: $region, annotationItems: searchResults) { item in
                MapAnnotation(coordinate: item.placemark.coordinate) {
                    EnhancedDestinationPin(
                        item: item,
                        isSelected: selectedDestination?.name == item.name
                    ) {
                        selectDestination(item)
                    }
                }
            }
            .ignoresSafeArea(.all) // Full edge-to-edge
            
            // Floating search bar at bottom
            VStack {
                Spacer()
                
                // Search bar container
                VStack(spacing: 16) {
                    // CRITICAL FIX: Two-button layout matching Android platform parity
                    HStack(spacing: 12) {
                        // Search field
                        TextField("Search destination...", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.headline)
                            .onSubmit {
                                handleSearchSubmit()
                            }
                            .onChange(of: searchText) { newValue in
                                if !newValue.isEmpty && newValue != speechManager.recognizedText {
                                    searchForDestinations()
                                }
                            }
                        
                        // CRITICAL FIX: Navigate Button (Primary Action) - BORDERLESS DESIGN
                        Button(action: handleNavigateAction) {
                            ZStack {
                                // BORDERLESS DESIGN: Remove background shape - icon-only button
                                Color.clear
                                    .frame(width: 56, height: 56)
                                
                                if isProcessingNavigation {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(.blue) // Use system color for borderless design
                                }
                            }
                        }
                        .disabled(selectedDestination == nil && searchText.isEmpty)
                        .accessibilityLabel("Start navigation")
                        .accessibilityHint("Double tap to start navigation to entered destination")
                        
                        // CRITICAL FIX: Microphone Toggle Button (Secondary Action) - BORDERLESS DESIGN
                        Button(action: handleMicrophoneToggle) {
                            ZStack {
                                // BORDERLESS DESIGN: Remove background shape - icon-only button
                                Color.clear
                                    .frame(width: 56, height: 56)
                                
                                Image(systemName: isListening ? "mic.fill" : "mic")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(isListening ? .green : .primary) // Use system colors for borderless design
                            }
                        }
                        .accessibilityLabel("Microphone")
                        .accessibilityHint("Double tap to toggle microphone")
                    }
                    
                    // Selected destination info (if any)
                    if let destination = selectedDestination {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(destination.name ?? "Selected Location")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                
                                if let address = destination.placemark.title {
                                    Text(address)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            
                            Spacer()
                            
                            // Distance if available
                            if let currentLocation = locationManager.currentLocation {
                                let distance = currentLocation.distance(from: CLLocation(latitude: destination.placemark.coordinate.latitude, longitude: destination.placemark.coordinate.longitude))
                                Text(formatDistance(distance))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 4) // Only 4px from screen bottom, no safe area
                .background(
                    // Much thinner background blur for minimal UI
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .mask(
                            VStack {
                                Spacer()
                                Rectangle()
                                    .frame(height: selectedDestination != nil ? 120 : 80) // Reduced height
                            }
                        )
                        .ignoresSafeArea(.all) // Ignore all safe areas for edge-to-edge
                )
            }
        }
        .onAppear {
            setupInitialState()
        }
        .onDisappear {
            speechManager.disableDestinationMode()
        }
        .onReceive(NotificationCenter.default.publisher(for: .destinationSelected)) { notification in
            handleDestinationNotification(notification)
        }
        .onChange(of: speechManager.recognizedText) { newText in
            // Voice input processing is now handled via notification system in destination mode
            if !speechManager.isDestinationMode && !newText.isEmpty {
                print("[DestinationView] Processing voice input (non-destination mode): '\(newText)'")
                processVoiceInput(newText)
            } else if speechManager.isDestinationMode && !newText.isEmpty {
                print("[DestinationView] Processing voice input in destination mode: '\(newText)'")
                // Check for standalone navigation commands when in destination mode
                let lowercaseText = newText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                let navigationCommands = ["go", "let's go", "start", "navigate", "begin", "start trip", "take me there", "drive"]
                
                if navigationCommands.contains(lowercaseText) && selectedDestination != nil {
                    print("[DestinationView] Standalone navigation command detected with selected destination")
                    if !speechManager.isSpeaking {
                        speechManager.speak("Starting roadtrip to \(selectedDestination?.name ?? "your destination")")
                    }
                    speechManager.disableDestinationMode()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.handleNavigation()
                    }
                }
            }
        }
        .onChange(of: speechManager.isListening) { listening in
            isListening = listening
        }
        .onChange(of: shouldNavigate) { navigate in
            if navigate {
                handleNavigation()
            }
        }
        .sheet(isPresented: $showPOIResult) {
            if let destination = selectedDestination {
                POIResultView(
                    destination: destination,
                    gemmaResponse: gemmaResponse,
                    onComplete: {
                        showPOIResult = false
                        isProcessingNavigation = false
                    }
                )
            }
        }
    }
    
    private func setupInitialState() {
        locationManager.startLocationUpdates()
        userPreferences.setRegionBasedDefaults()
        
        if let location = locationManager.currentLocation {
            region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        }
        
        // If there's a saved destination name, populate the search field
        if let savedName = savedDestinationName {
            searchText = savedName
            // Automatically search for the saved destination
            handleSearchSubmit()
            print("Populated search with saved destination: \(savedName)")
        }
        
        // Auto-start voice search after brief delay to let UI settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            startVoiceSearch()
        }
    }
    
    
    private func handleDestinationNotification(_ notification: Notification) {
        guard let destination = notification.object as? String,
              let userInfo = notification.userInfo else { 
            print("[DestinationView] Invalid destination notification")
            return 
        }
        
        let hasAction = userInfo["hasAction"] as? Bool ?? false
        let action = userInfo["action"] as? String ?? ""
        
        print("[DestinationView] Received destination notification: '\(destination)', hasAction: \(hasAction), action: '\(action)'")
        
        // CRITICAL FIX: Don't search for non-destination text like TTS feedback messages
        let lowercaseDestination = destination.lowercased()
        let feedbackMessages = ["returning to destination selection", "search failed", "please wait", "starting roadtrip"]
        
        // Skip processing if this is a TTS feedback message, not a real destination
        for feedbackMessage in feedbackMessages {
            if lowercaseDestination.contains(feedbackMessage) {
                print("[DestinationView] Ignoring TTS feedback message: '\(destination)'")
                return
            }
        }
        
        // Update search text and perform search only for valid destinations
        DispatchQueue.main.async {
            self.searchText = destination
            self.searchForDestinations()
        }
        
        // If action was detected, provide feedback and auto-navigate when search completes
        if hasAction {
            // CRITICAL FIX: Only navigate with explicit voice navigation commands ("go", "navigate", "start", "begin")
            if !speechManager.isSpeaking {
                speechManager.speak("Starting roadtrip to \(destination)")
            }
            // Wait for search to complete, then navigate
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if self.selectedDestination != nil {
                    print("[DestinationView] Auto-navigating to \(destination) due to explicit voice command")
                    self.handleNavigation()
                } else {
                    print("[DestinationView] Search completed but no destination selected")
                    if !self.speechManager.isSpeaking {
                        self.speechManager.speak("Could not find \(destination). Please try again.")
                    }
                }
            }
        } else {
            // CRITICAL FIX: Destination-only input - show results but require explicit user confirmation
            print("[DestinationView] Destination-only input received, showing search results but requiring user confirmation")
            // No TTS feedback, no auto-navigation - user must tap navigate button or say explicit navigation commands
        }
    }
    
    // CRITICAL FIX: Separate actions for Navigate and Microphone buttons
    private func handleNavigateAction() {
        let startTime = TimestampLogger.logNavigationStart("Navigate Action")
        
        guard selectedDestination != nil || !searchText.isEmpty else {
            TimestampLogger.info("Navigate action triggered but no destination available", category: "Navigation")
            if !speechManager.isSpeaking {
                speechManager.speak("Please select a destination first")
            }
            TimestampLogger.logNavigationEnd("Navigate Action", startTime: startTime)
            return
        }
        
        isProcessingNavigation = true
        
        if selectedDestination != nil {
            TimestampLogger.info("Navigating to selected destination: \(selectedDestination?.name ?? "Unknown")", category: "Navigation")
            handleGemmaIntegrationAndNavigation()
        } else if !searchText.isEmpty {
            TimestampLogger.info("Searching for destination before navigation: \(searchText)", category: "Navigation")
            searchForDestinations()
            // Auto-navigate to first result after search
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if let firstResult = self.searchResults.first {
                    self.selectedDestination = firstResult
                    self.handleGemmaIntegrationAndNavigation()
                }
                self.isProcessingNavigation = false
            }
        }
        
        if selectedDestination != nil {
            TimestampLogger.logNavigationEnd("Navigate Action", startTime: startTime)
        }
    }
    
    private func handleMicrophoneToggle() {
        let startTime = TimestampLogger.logAudioStart("Microphone Toggle")
        
        if isListening {
            TimestampLogger.info("Stopping voice recognition", category: "Voice")
            speechManager.stopListening()
            if !speechManager.isSpeaking {
                speechManager.speak("Microphone off")
            }
        } else {
            TimestampLogger.info("Starting voice recognition", category: "Voice")
            startVoiceSearch()
            if !speechManager.isSpeaking {
                speechManager.speak("Microphone on")
            }
        }
        
        TimestampLogger.logAudioEnd("Microphone Toggle", startTime: startTime)
    }
    
    private func startVoiceSearch() {
        if speechManager.isListening {
            speechManager.stopListening()
        } else {
            // Enable destination mode before starting listening
            speechManager.enableDestinationMode()
            speechManager.startListening()
            TimestampLogger.info("Started voice search in destination mode", category: "Voice")
        }
    }
    
    private func handleSearchSubmit() {
        let trimmedText = searchText.trimmingCharacters(in: .whitespaces)
        guard !trimmedText.isEmpty else { return }
        
        TimestampLogger.info("Search submitted: '\(trimmedText)'", category: "Search")
        
        // CRITICAL FIX: Only search for destinations, do NOT auto-navigate
        searchForDestinations()
        
        // Check for explicit navigation trigger words in search text
        let lowercaseSearch = trimmedText.lowercased()
        let hasNavigationTrigger = lowercaseSearch.contains("navigate") || 
                                   lowercaseSearch.contains("start") || 
                                   lowercaseSearch.contains("go") ||
                                   lowercaseSearch.contains("begin") ||
                                   lowercaseSearch.contains("take me")
        
        if hasNavigationTrigger {
            // TTS feedback for text with navigation trigger words - prevent duplicates
            if !speechManager.isSpeaking {
                speechManager.speak("Starting roadtrip to \(trimmedText)")
            }
            // Wait for search to complete, then navigate if destination found
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if self.selectedDestination != nil {
                    self.handleNavigation()
                } else if !self.speechManager.isSpeaking {
                    // FIXED: Only speak if not already speaking
                    self.speechManager.speak("Please wait for search to complete")
                }
            }
        } else {
            // CRITICAL FIX: Enter key pressed without navigation words - show results but require user confirmation
            print("[DestinationView] Destination-only input, showing search results but requiring user confirmation")
            // No TTS feedback, no auto-navigation - just show search results
        }
    }
    
    private func handleGemmaIntegrationAndNavigation() {
        guard let destination = selectedDestination else {
            speechManager.speak("Please select a destination first")
            isProcessingNavigation = false
            return
        }
        
        let destinationName = destination.name ?? "this location"
        let prompt = "tell me about this place: \(destinationName)"
        
        TimestampLogger.info("Calling Gemma-3N with prompt: \(prompt)", category: "AI")
        
        Task {
            do {
                var response: String
                
                // Check iOS version and use appropriate model manager
                if #available(iOS 16.0, *) {
                    // Load model if not already loaded
                    if !ModelManager.shared.isModelLoaded {
                        try await ModelManager.shared.loadModel()
                    }
                    
                    // Get response from Gemma-3N
                    response = try await ModelManager.shared.predict(input: prompt, maxTokens: 150)
                } else {
                    // Use legacy model manager for iOS 15
                    if !ModelManagerLegacy.shared.isModelLoaded {
                        try await ModelManagerLegacy.shared.loadModel()
                    }
                    
                    response = try await ModelManagerLegacy.shared.predict(input: prompt, maxTokens: 150)
                }
                
                await MainActor.run {
                    self.gemmaResponse = response
                    self.showPOIResult = true
                    TimestampLogger.info("Gemma response received, showing POI result", category: "AI")
                }
            } catch {
                TimestampLogger.info("Gemma integration failed: \(error)", category: "AI")
                
                await MainActor.run {
                    // Fallback response if Gemma fails
                    self.gemmaResponse = "This destination looks interesting! It's a great place to explore and discover new experiences."
                    self.showPOIResult = true
                }
            }
        }
    }
    
    private func handleNavigation() {
        guard let destination = selectedDestination else {
            // Provide audio feedback that destination is required
            speechManager.speak("Please select a destination first")
            return
        }
        
        // FIXED: Remove duplicate TTS here since calling methods already provide feedback
        // This prevents double TTS when navigation is triggered
        TimestampLogger.info("Navigating to \(destination.name ?? "destination")", category: "Navigation")
        
        userPreferences.hasCompletedOnboarding = true
        userPreferences.savePreferences()
        
        // Small delay before navigating to allow any pending TTS to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            onComplete(destination, userPreferences)
        }
    }
    
    private func processVoiceInput(_ input: String) {
        let lowercaseInput = input.lowercased().trimmingCharacters(in: .whitespaces)
        
        print("[DestinationView] Processing voice input: '\(input)'")
        
        // Check for navigation commands first - only proceed if destination is selected
        if lowercaseInput.contains("start") || 
           lowercaseInput.contains("go") || 
           lowercaseInput.contains("navigate") ||
           lowercaseInput.contains("let's go") ||
           lowercaseInput.contains("take me there") ||
           lowercaseInput.contains("begin") ||
           lowercaseInput.contains("start trip") {
            
            print("[DestinationView] Navigation command detected")
            
            if selectedDestination != nil {
                print("[DestinationView] Destination available, triggering navigation")
                // TTS feedback for explicit navigation commands - prevent duplicates
                if !speechManager.isSpeaking {
                    speechManager.speak("Starting roadtrip to \(selectedDestination?.name ?? "your destination")")
                }
                shouldNavigate = true
                return
            } else {
                // Inform user that destination selection is required
                print("[DestinationView] No destination selected for navigation command")
                if !speechManager.isSpeaking {
                    speechManager.speak("Please select a destination first before starting navigation")
                }
                return
            }
        }
        
        // Otherwise, treat as search input and update search bar
        if !input.isEmpty {
            print("[DestinationView] Treating as search input: '\(input)'")
            DispatchQueue.main.async {
                self.searchText = input
                self.searchForDestinations()
            }
        }
    }
    
    private func searchForDestinations() {
        let trimmedQuery = searchText.trimmingCharacters(in: .whitespaces)
        guard !trimmedQuery.isEmpty else { return }
        
        // Prevent concurrent searches
        guard !isSearching else {
            print("[DestinationView] Search already in progress, ignoring new request")
            return
        }
        
        let searchStartTime = TimestampLogger.logSearchStart(trimmedQuery)
        
        // Cancel any existing search
        currentSearchTask?.cancel()
        
        // Set search state
        isSearching = true
        lastErrorMessage = nil
        errorMessageCount = 0
        
        // CRITICAL FIX: Notify LocationManager to avoid reverse geocoding during search
        locationManager.setSearchInProgress(true)
        
        // Perform search with retry logic
        performSearchWithRetry(query: trimmedQuery, attempt: 1, startTime: searchStartTime)
    }
    
    private func performSearchWithRetry(query: String, attempt: Int, startTime: Date = Date()) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = region
        
        let search = MKLocalSearch(request: request)
        currentSearchTask = search
        
        search.start { response, error in
            
            DispatchQueue.main.async {
                // Check if this is still the current search task
                guard search === self.currentSearchTask else {
                    print("[DestinationView] Search result for cancelled request, ignoring")
                    return
                }
                
                self.isSearching = false
                self.currentSearchTask = nil
                
                // CRITICAL FIX: Notify LocationManager that search completed
                self.locationManager.setSearchInProgress(false)
                
                if let error = error {
                    self.handleSearchError(error: error, query: query, attempt: attempt, startTime: startTime)
                    return
                }
                
                guard let response = response else {
                    print("[DestinationView] No search response received")
                    self.handleSearchError(error: NSError(domain: "SearchError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No response received"]), query: query, attempt: attempt, startTime: startTime)
                    return
                }
                
                self.handleSearchSuccess(response: response, query: query, searchStartTime: startTime)
            }
        }
    }
    
    private func handleSearchError(error: Error, query: String, attempt: Int, startTime: Date = Date()) {
        let errorMessage = error.localizedDescription
        print("[DestinationView] Search error (attempt \(attempt)/\(maxRetryAttempts)): \(errorMessage)")
        
        // Check if we should retry
        if attempt < maxRetryAttempts && (errorMessage.contains("timed out") || errorMessage.contains("network")) {
            print("[DestinationView] Retrying search in \(attempt) seconds...")
            
            // Provide user feedback only on first error
            if attempt == 1 {
                self.provideSingleErrorFeedback("Please wait for search to complete")
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(attempt)) {
                if !self.isSearching { // Only retry if no new search has started
                    self.isSearching = true
                    self.performSearchWithRetry(query: query, attempt: attempt + 1, startTime: startTime)
                }
            }
        } else {
            // Final failure after all retries
            self.provideSingleErrorFeedback("Search failed. Please try again.")
            // Ensure search state is reset on final failure
            self.locationManager.setSearchInProgress(false)
        }
    }
    
    private func handleSearchSuccess(response: MKLocalSearch.Response, query: String, searchStartTime: Date) {
        self.searchResults = response.mapItems
        TimestampLogger.logSearchEnd(query, startTime: searchStartTime, resultCount: self.searchResults.count)
        
        if !self.searchResults.isEmpty {
            // CRITICAL FIX: Show search results but do NOT auto-select - require manual user selection
            print("[DestinationView] Search results available, waiting for user selection")
            // Update map region to show first result but don't select it
            let firstResult = self.searchResults[0]
            self.region = MKCoordinateRegion(
                center: firstResult.placemark.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        } else {
            self.provideSingleErrorFeedback("No results found for \(query). Please try a different search.")
        }
    }
    
    private func provideSingleErrorFeedback(_ message: String) {
        // Prevent repeated identical error messages
        guard message != lastErrorMessage || errorMessageCount == 0 else {
            print("[DestinationView] Suppressing repeated error message: '\(message)'")
            return
        }
        
        lastErrorMessage = message
        errorMessageCount += 1
        speechManager.speak(message)
        
        // Reset error message tracking after a delay to allow new searches
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if self.lastErrorMessage == message {
                self.lastErrorMessage = nil
                self.errorMessageCount = 0
            }
        }
    }
    
    private func selectDestination(_ item: MKMapItem) {
        selectedDestination = item
        
        print("[DestinationView] Selected destination: \(item.name ?? "Unknown")")
        
        // Update region to center on selected destination
        region = MKCoordinateRegion(
            center: item.placemark.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        
        // FIXED: Remove TTS here - destination selection should be SILENT
        // TTS will only occur when user explicitly triggers navigation
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .short
        formatter.numberFormatter.maximumFractionDigits = 1
        
        let measurement = Measurement(value: distance, unit: UnitLength.meters)
        return formatter.string(from: measurement)
    }
}

// MARK: - Voice Wave Animation Component

struct VoiceWaveAnimation: View {
    @State private var animationPhases: [Double] = Array(repeating: 0.0, count: 8)
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<8, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.white)
                    .frame(width: 3, height: 4 + animationPhases[index] * 12)
                    .animation(
                        .easeInOut(duration: 0.4 + Double(index) * 0.1)
                        .repeatForever(autoreverses: true),
                        value: animationPhases[index]
                    )
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        for index in 0..<8 {
            animationPhases[index] = 1.0
        }
    }
}

// MARK: - Enhanced Destination Pin Component

struct EnhancedDestinationPin: View {
    let item: MKMapItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack {
                Image(systemName: isSelected ? "mappin.and.ellipse" : "mappin")
                    .font(.title)
                    .foregroundColor(isSelected ? .red : .blue)
                    .scaleEffect(isSelected ? 1.2 : 1.0)
                
                if isSelected {
                    Text(item.name ?? "Location")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.blue)
                        .cornerRadius(8)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isSelected)
    }
}

#Preview {
    EnhancedDestinationSelectionView(savedDestinationName: nil) { destination, preferences in
        print("Selected: \(destination.name ?? "Unknown"), Radius: \(preferences.searchRadiusText)")
    }
}