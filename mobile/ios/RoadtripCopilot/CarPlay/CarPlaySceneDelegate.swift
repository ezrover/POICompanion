import UIKit
import CarPlay
import MapKit
import CoreLocation

class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    private var interfaceController: CPInterfaceController?
    private var currentScreen: CarPlayScreen = .welcome
    private var searchResults: [MKMapItem] = []
    private var selectedDestination: MKMapItem?
    private var currentPOI: POIData?
    
    // Shared managers
    private let locationManager = LocationManager.shared
    private let appStateManager = AppStateManager()
    private let speechManager = SpeechManager()
    private var agentManager: AIAgentManager?
    
    enum CarPlayScreen {
        case welcome
        case destinationSelection
        case mainDashboard
    }

    /// CarPlay connected - automatically launch destination selection
    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        print("[CarPlay] Connected to CarPlay via templateApplicationScene")
        self.interfaceController = interfaceController
        
        // Initialize CarPlay interface
        initializeCarPlayInterface()
    }
    
    // MARK: - CarPlay Interface Initialization
    
    private func initializeCarPlayInterface() {
        print("[CarPlay] Initializing CarPlay interface")
        
        // Start location services
        locationManager.startLocationUpdates()
        
        // Set up state synchronization with main app
        setupStateObservers()
        
        // Set up voice command observers
        setupVoiceObservers()
        
        // Set up speed monitoring for CarPlay display updates
        setupSpeedMonitoring()
        
        // Set up listener for already connected scenarios
        setupExistingConnectionObserver()
        
        // Auto-launch based on app state
        if appStateManager.isInActiveRoadtrip {
            setupMainDashboard()
        } else {
            setupDestinationSelection()
        }
    }
    
    private func setupExistingConnectionObserver() {
        // Listen for already connected CarPlay scenarios
        NotificationCenter.default.addObserver(
            forName: .carPlayAlreadyConnected,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            print("[CarPlay] Received carPlayAlreadyConnected notification")
            
            // If we have a scene but no interface controller, try to establish connection
            if let scene = notification.object as? CPTemplateApplicationScene,
               self?.interfaceController == nil {
                print("[CarPlay] Attempting to establish interface controller for existing scene")
                
                // This scenario happens when app launches with CarPlay already connected
                // We need to manually establish the interface controller
                self?.handleExistingCarPlayScene(scene)
            }
        }
    }
    
    private func handleExistingCarPlayScene(_ scene: CPTemplateApplicationScene) {
        print("[CarPlay] Handling existing CarPlay scene")
        
        // CRITICAL FIX: Properly handle existing CarPlay connection using Apple's recommended approach
        // When app launches with CarPlay already connected, we need to establish the interface properly
        
        // Store the scene for potential interface controller creation
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // The key insight: For existing connections, we need to wait for the proper
            // templateApplicationScene:didConnect delegate call, but ensure we're ready for it
            
            if self.interfaceController == nil {
                print("[CarPlay] Preparing for existing CarPlay scene connection")
                
                // The system will call templateApplicationScene:didConnect when ready
                // But we need to ensure our scene is properly prepared
                
                // Set a reasonable timeout to check if connection was established
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    if self.interfaceController == nil {
                        print("[CarPlay] Interface controller still not established")
                        print("[CarPlay] The system should call templateApplicationScene:didConnect when ready")
                        
                        // Note: CPInterfaceController cannot be created directly
                        // It must be provided by the system through the delegate callback
                        // If we reach here, there may be a CarPlay system issue
                        
                        // Log diagnostic information for debugging
                        print("[CarPlay] Scene delegate may not be called - CarPlay system issue")
                    } else {
                        print("[CarPlay] Interface controller successfully established for existing scene")
                    }
                }
            } else {
                print("[CarPlay] Interface controller already exists - initializing interface")
                self.initializeCarPlayInterface()
            }
        }
    }

    /// CarPlay disconnected  
    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        print("[CarPlay] Disconnected from CarPlay")
        self.interfaceController = nil
        self.agentManager = nil
    }
    
    // MARK: - Screen Setup Methods
    
    private func setupDestinationSelection() {
        currentScreen = .destinationSelection
        print("[CarPlay] Setting up destination selection")
        
        let searchItem = CPListItem(
            text: "Search Destination",
            detailText: "Say or type your destination"
        )
        searchItem.handler = { [weak self] item, completion in
            self?.showDestinationSearch()
            completion()
        }
        
        let savedTripsItem = CPListItem(
            text: "Recent Trips",
            detailText: "Continue a previous roadtrip"
        )
        savedTripsItem.handler = { [weak self] item, completion in
            self?.showSavedTrips()
            completion()
        }
        
        let nearbyItem = CPListItem(
            text: "Explore Nearby",
            detailText: "Discover places around you"
        )
        nearbyItem.handler = { [weak self] item, completion in
            self?.startNearbyExploration()
            completion()
        }
        
        // Add current location and speed item if available
        var items = [searchItem, savedTripsItem, nearbyItem]
        if let city = locationManager.currentCity, let state = locationManager.currentState {
            let speedInfo = locationManager.isMoving ? 
                " • \(locationManager.getFormattedSpeed(unit: .mph))" : ""
            let locationItem = CPListItem(
                text: "Current Location",
                detailText: "\(city), \(state)\(speedInfo)"
            )
            locationItem.isEnabled = false // Just for info display
            items.insert(locationItem, at: 0)
        }
        
        let section = CPListSection(items: items)
        let listTemplate = CPListTemplate(title: "Where to?", sections: [section])
        
        // Add voice control button with real voice functionality
        let voiceButton = CPBarButton(title: speechManager.isListening ? "Stop" : "Voice") { [weak self] _ in
            self?.handleVoiceButtonTap()
        }
        listTemplate.leadingNavigationBarButtons = [voiceButton]
        
        interfaceController?.setRootTemplate(listTemplate, animated: true, completion: nil)
    }
    
    private func setupMainDashboard() {
        currentScreen = .mainDashboard
        print("[CarPlay] Setting up main dashboard with POI discovery")
        
        // Initialize agent manager if needed
        if agentManager == nil {
            agentManager = AIAgentManager()
            agentManager?.startBackgroundAgents()
        }
        
        // Start POI observation
        observePOIUpdates()
        
        // Show POI discovery view immediately
        showPOIDiscoveryView()
    }
    
    private func observePOIUpdates() {
        // This will be called when POI changes are detected
        // The notification observer is already set up in setupStateObservers
    }
    
    private func showPOIDiscoveryView() {
        print("[CarPlay] Showing POI discovery view")
        
        // Get current POI or show discovery message
        if let currentPOI = agentManager?.currentPOI {
            showPOIFullView(currentPOI)
        } else {
            showDiscoveryTemplate()
        }
    }
    
    private func showPOIFullView(_ poi: POIData) {
        print("[CarPlay] Showing full POI view for: \(poi.name)")
        
        var items: [CPListItem] = []
        
        // POI Information with current speed
        let speedInfo = locationManager.isMoving ? 
            " • Current: \(locationManager.getFormattedSpeed(unit: .mph))" : ""
        let nameItem = CPListItem(
            text: poi.name,
            detailText: "\(poi.category) • \(String(format: "%.1f", poi.distanceFromUser)) miles ahead\(speedInfo)"
        )
        nameItem.isEnabled = false
        items.append(nameItem)
        
        // Review summary if available  
        if let reviewSummary = poi.reviewSummary {
            let reviewItem = CPListItem(
                text: "About",
                detailText: reviewSummary
            )
            reviewItem.isEnabled = false
            items.append(reviewItem)
        }
        
        // Discovery badge if first discovery
        if poi.couldEarnRevenue {
            let revenueItem = CPListItem(
                text: "🎉 First Discovery!",
                detailText: "This place could earn you FREE roadtrips"
            )
            revenueItem.isEnabled = false
            items.append(revenueItem)
        }
        
        // Action buttons
        let saveItem = CPListItem(text: "⭐ Save to Favorites", detailText: nil)
        saveItem.handler = { [weak self] _, completion in
            self?.agentManager?.favoriteCurrentPOI()
            self?.speechManager.speak("Saved to favorites")
            completion()
        }
        items.append(saveItem)
        
        let likeItem = CPListItem(text: "👍 Like", detailText: nil)
        likeItem.handler = { [weak self] _, completion in
            self?.agentManager?.likeCurrentPOI()
            self?.speechManager.speak("Liked")
            completion()
        }
        items.append(likeItem)
        
        let dislikeItem = CPListItem(text: "👎 Pass", detailText: nil)
        dislikeItem.handler = { [weak self] _, completion in
            self?.agentManager?.dislikeCurrentPOI()
            self?.agentManager?.nextPOI()
            self?.speechManager.speak("Moving to next place")
            completion()
        }
        items.append(dislikeItem)
        
        let navigateItem = CPListItem(text: "🗺️ Navigate", detailText: nil)
        navigateItem.handler = { [weak self] _, completion in
            self?.handleCarPlayNavigation()
            completion()
        }
        items.append(navigateItem)
        
        // Add call button if phone number available
        if let phoneNumber = poi.phoneNumber, !phoneNumber.isEmpty {
            let callItem = CPListItem(text: "📞 Call", detailText: nil)
            callItem.handler = { [weak self] _, completion in
                self?.handleCarPlayCall()
                completion()
            }
            items.append(callItem)
        }
        
        let nextItem = CPListItem(text: "➡️ Next Place", detailText: nil)
        nextItem.handler = { [weak self] _, completion in
            self?.agentManager?.nextPOI()
            completion()
        }
        items.append(nextItem)
        
        let previousItem = CPListItem(text: "⬅️ Previous Place", detailText: nil)
        previousItem.handler = { [weak self] _, completion in
            self?.agentManager?.previousPOI()
            completion()
        }
        items.append(previousItem)
        
        // Create sections
        let infoSection = CPListSection(items: Array(items.prefix(3)))
        let actionsSection = CPListSection(items: Array(items.dropFirst(3)))
        
        let listTemplate = CPListTemplate(title: "Discovery", sections: [infoSection, actionsSection])
        
        // Add navigation buttons
        let backButton = CPBarButton(title: "← Back") { [weak self] _ in
            self?.setupDestinationSelection()
        }
        
        let voiceButton = CPBarButton(title: speechManager.isListening ? "Stop" : "Voice") { [weak self] _ in
            self?.handleVoiceButtonTap()
        }
        
        listTemplate.leadingNavigationBarButtons = [backButton]
        listTemplate.trailingNavigationBarButtons = [voiceButton]
        
        interfaceController?.setRootTemplate(listTemplate, animated: true, completion: nil)
        
        // Announce the POI
        announcePOI(poi)
    }
    
    private func announcePOI(_ poi: POIData) {
        let announcement = "Found \(poi.name), a \(poi.category) \(String(format: "%.1f", poi.distanceFromUser)) miles ahead."
        speechManager.speak(announcement)
    }
    
    private func showDiscoveryTemplate() {
        // Create a discovery template while waiting for POIs
        var items: [CPListItem] = []
        
        let discoveryItem = CPListItem(
            text: "Discovering amazing places...",
            detailText: "Finding points of interest along your route"
        )
        discoveryItem.isEnabled = false
        items.append(discoveryItem)
        
        // Action items
        let exploreItem = CPListItem(text: "Start Exploring", detailText: "Begin discovery")
        exploreItem.handler = { [weak self] _, completion in
            self?.agentManager?.nextPOI()
            completion()
        }
        items.append(exploreItem)
        
        let section = CPListSection(items: items)
        let listTemplate = CPListTemplate(title: "Roadtrip Discovery", sections: [section])
        
        // Add navigation buttons
        let backButton = CPBarButton(title: "← Back") { [weak self] _ in
            self?.setupDestinationSelection()
        }
        
        let voiceButton = CPBarButton(title: speechManager.isListening ? "Stop" : "Voice") { [weak self] _ in
            self?.handleVoiceButtonTap()
        }
        
        listTemplate.leadingNavigationBarButtons = [backButton]
        listTemplate.trailingNavigationBarButtons = [voiceButton]
        
        interfaceController?.setRootTemplate(listTemplate, animated: true, completion: nil)
    }
    
    // MARK: - Search and Navigation
    
    private func showDestinationSearch() {
        print("[CarPlay] Showing destination search - Set Destination Screen")
        
        // Enable destination mode for raw destination input
        speechManager.enableDestinationMode()
        
        // Create the enhanced Set Destination interface following design spec
        var items: [CPListItem] = []
        
        // Voice Search Item (Primary Action) - Automotive Safety 44pt minimum
        let voiceSearchItem = CPListItem(
            text: "🎙️ Voice Search", 
            detailText: speechManager.isListening ? "Listening..." : "Say your destination"
        )
        voiceSearchItem.handler = { [weak self] item, completion in
            self?.handleCarPlayVoiceSearch()
            completion()
        }
        items.append(voiceSearchItem)
        
        // Quick Actions Section
        let navigateItem = CPListItem(text: "▶️ Navigate", detailText: "Start navigation")
        navigateItem.handler = { [weak self] item, completion in
            self?.handleCarPlayNavigateCommand()
            completion()
        }
        navigateItem.isEnabled = selectedDestination != nil
        items.append(navigateItem)
        
        let micToggleItem = CPListItem(
            text: speechManager.isListening ? "🔇 Mute" : "🎤 Unmute",
            detailText: speechManager.isListening ? "Turn off microphone" : "Turn on microphone"
        )
        micToggleItem.handler = { [weak self] item, completion in
            self?.handleCarPlayMicrophoneToggle()
            completion()
        }
        items.append(micToggleItem)
        
        // Recent/Popular Destinations Section
        let recentSearches = ["San Francisco", "Los Angeles", "Seattle", "Portland"]
        let destinationItems = recentSearches.map { location in
            let item = CPListItem(text: location, detailText: "Popular destination")
            item.handler = { [weak self] item, completion in
                self?.selectCarPlayDestination(location)
                completion()
            }
            return item
        }
        
        // Create sections following design spec layout
        let actionsSection = CPListSection(items: Array(items.prefix(3)))
        let destinationsSection = CPListSection(items: destinationItems, header: "Popular Destinations", sectionIndexTitle: nil)
        
        let searchTemplate = CPListTemplate(
            title: "Set Destination", 
            sections: [actionsSection, destinationsSection]
        )
        
        // Add navigation buttons - Following automotive safety guidelines
        let backButton = CPBarButton(title: "← Back") { [weak self] _ in
            self?.speechManager.disableDestinationMode()
            self?.setupDestinationSelection()
        }
        
        let voiceButton = CPBarButton(title: speechManager.isListening ? "Stop" : "Voice") { [weak self] _ in
            self?.handleVoiceButtonTap()
        }
        
        searchTemplate.leadingNavigationBarButtons = [backButton]
        searchTemplate.trailingNavigationBarButtons = [voiceButton]
        
        interfaceController?.pushTemplate(searchTemplate, animated: true, completion: nil)
    }
    
    // MARK: - CarPlay Set Destination Actions
    
    private func handleCarPlayVoiceSearch() {
        print("[CarPlay] Voice search activated")
        speechManager.enableDestinationMode()
        
        if speechManager.isListening {
            speechManager.stopListening()
        } else {
            speechManager.startListening()
        }
        
        // Refresh template to show updated state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showDestinationSearch()
        }
    }
    
    private func handleCarPlayNavigateCommand() {
        print("[CarPlay] Navigate command activated")
        
        guard let destination = selectedDestination else {
            speechManager.speak("Please select a destination first")
            return
        }
        
        speechManager.speak("Starting navigation to \(destination.name ?? "destination")")
        startRoadtrip(to: destination)
    }
    
    private func handleCarPlayMicrophoneToggle() {
        print("[CarPlay] Microphone toggle activated")
        
        if speechManager.isListening {
            speechManager.stopListening()
            speechManager.speak("Microphone muted")
        } else {
            speechManager.startListening()
            speechManager.speak("Microphone active")
        }
        
        // Refresh template to show updated state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showDestinationSearch()
        }
    }
    
    private func selectCarPlayDestination(_ destination: String) {
        print("[CarPlay] Selected destination: \(destination)")
        
        // Perform search for the selected destination
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = destination
        
        if let currentLocation = locationManager.currentLocation {
            request.region = MKCoordinateRegion(
                center: currentLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
            )
        }
        
        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            DispatchQueue.main.async {
                guard let response = response, 
                      let firstResult = response.mapItems.first,
                      error == nil else {
                    print("[CarPlay] Search error for \(destination): \(error?.localizedDescription ?? "Unknown")")
                    self?.speechManager.speak("Could not find \(destination)")
                    return
                }
                
                // Store selected destination and provide feedback
                self?.selectedDestination = firstResult
                self?.speechManager.speak("Selected \(destination)")
                
                // Refresh template to show updated state with selected destination
                self?.showDestinationSearch()
            }
        }
    }
    
    private func showSavedTrips() {
        print("[CarPlay] Showing saved trips")
        
        // Mock saved trips - in real app, load from UserDefaults or Core Data
        let savedTrips = [
            ("San Francisco Bay Area", "Last trip: 2 days ago"),
            ("Pacific Coast Highway", "Last trip: 1 week ago"),
            ("Yosemite National Park", "Last trip: 2 weeks ago")
        ]
        
        let items = savedTrips.map { trip in
            let item = CPListItem(text: trip.0, detailText: trip.1)
            item.handler = { [weak self] item, completion in
                self?.searchForDestination(trip.0)
                completion()
            }
            return item
        }
        
        let section = CPListSection(items: items)
        let savedTemplate = CPListTemplate(title: "Saved Trips", sections: [section])
        
        // Add back button - icon-only text design
        let backButton = CPBarButton(title: "Back") { [weak self] _ in
            self?.setupDestinationSelection()
        }
        savedTemplate.leadingNavigationBarButtons = [backButton]
        
        interfaceController?.pushTemplate(savedTemplate, animated: true, completion: nil)
    }
    
    private func startNearbyExploration() {
        print("[CarPlay] Starting nearby exploration")
        
        // Start roadtrip with current location as destination
        if let currentLocation = locationManager.currentLocation {
            let placemark = MKPlacemark(coordinate: currentLocation.coordinate)
            let destination = MKMapItem(placemark: placemark)
            destination.name = "Current Area"
            
            startRoadtrip(to: destination)
        }
    }
    
    private func searchForDestination(_ query: String) {
        print("[CarPlay] Searching for destination: \(query)")
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        
        if let currentLocation = locationManager.currentLocation {
            request.region = MKCoordinateRegion(
                center: currentLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
            )
        }
        
        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            DispatchQueue.main.async {
                guard let response = response, error == nil else {
                    print("[CarPlay] Search error: \(error?.localizedDescription ?? "Unknown")")
                    self?.speechManager.speak("Could not find \(query). Please try again.")
                    return
                }
                
                self?.showSearchResults(response.mapItems, for: query)
            }
        }
    }
    
    private func searchForDestinationAndStart(_ query: String) {
        print("[CarPlay] Searching for destination and auto-starting: \(query)")
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        
        if let currentLocation = locationManager.currentLocation {
            request.region = MKCoordinateRegion(
                center: currentLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
            )
        }
        
        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            DispatchQueue.main.async {
                guard let response = response, error == nil else {
                    print("[CarPlay] Search error: \(error?.localizedDescription ?? "Unknown")")
                    self?.speechManager.speak("Could not find \(query). Please try again.")
                    return
                }
                
                guard let firstResult = response.mapItems.first else {
                    print("[CarPlay] No search results for \(query)")
                    self?.speechManager.speak("No results found for \(query). Please try a different destination.")
                    return
                }
                
                // Auto-start the roadtrip with the first result
                print("[CarPlay] Auto-starting roadtrip to: \(firstResult.name ?? "Unknown")")
                self?.startRoadtrip(to: firstResult)
            }
        }
    }
    
    private func showSearchResults(_ results: [MKMapItem], for query: String) {
        print("[CarPlay] Showing \(results.count) search results for \(query)")
        
        let items = results.prefix(10).map { mapItem in
            let item = CPListItem(
                text: mapItem.name ?? "Unknown Location",
                detailText: mapItem.placemark.title ?? "No address"
            )
            item.handler = { [weak self] item, completion in
                self?.startRoadtrip(to: mapItem)
                completion()
            }
            return item
        }
        
        let section = CPListSection(items: items)
        let resultsTemplate = CPListTemplate(title: "Results for \"\(query)\"", sections: [section])
        
        // Add back button - icon-only text design
        let backButton = CPBarButton(title: "Back") { [weak self] _ in
            self?.interfaceController?.popTemplate(animated: true, completion: nil)
        }
        resultsTemplate.leadingNavigationBarButtons = [backButton]
        
        interfaceController?.pushTemplate(resultsTemplate, animated: true, completion: nil)
    }
    
    private func startRoadtrip(to destination: MKMapItem) {
        print("[CarPlay] Starting roadtrip to: \(destination.name ?? "Unknown")")
        
        selectedDestination = destination
        appStateManager.startRoadtrip(to: destination)
        
        // Initialize agent manager
        agentManager = AIAgentManager()
        agentManager?.startBackgroundAgents()
        
        // Switch to main dashboard
        setupMainDashboard()
    }
    
    // MARK: - Voice Control
    
    private func handleVoiceButtonTap() {
        print("[CarPlay] Voice button tapped")
        
        if speechManager.isListening {
            speechManager.stopListening()
            // Update button titles on both screens
            updateVoiceButtonStates()
        } else {
            speechManager.startListening()
            // Update button titles on both screens
            updateVoiceButtonStates()
            
            // Show voice listening feedback
            showVoiceListeningFeedback()
        }
    }
    
    private func updateVoiceButtonStates() {
        // This would need to be implemented by refreshing the current template
        // CarPlay doesn't allow dynamic button title updates, so we refresh the screen
        if currentScreen == .destinationSelection {
            setupDestinationSelection()
        } else if currentScreen == .mainDashboard {
            setupMainDashboard()
        }
    }
    
    private func showVoiceListeningFeedback() {
        // Create a simple alert to show voice listening state
        let alert = CPAlertTemplate(
            titleVariants: ["Listening for voice command..."],
            actions: [
                CPAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
                    self?.speechManager.stopListening()
                    self?.updateVoiceButtonStates()
                }
            ]
        )
        
        interfaceController?.presentTemplate(alert, animated: true, completion: nil)
        
        // Auto-dismiss when listening stops
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.monitorVoiceListening(alertTemplate: alert)
        }
    }
    
    private func monitorVoiceListening(alertTemplate: CPAlertTemplate) {
        if !speechManager.isListening {
            interfaceController?.dismissTemplate(animated: true, completion: nil)
            updateVoiceButtonStates()
            return
        }
        
        // Check again after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.monitorVoiceListening(alertTemplate: alertTemplate)
        }
    }
    
    private func speakCurrentPOI() {
        guard let currentPOI = agentManager?.currentPOI else {
            print("[CarPlay] No current POI to speak about")
            return
        }
        
        print("[CarPlay] Speaking about current POI: \(currentPOI.name)")
        // In a real implementation, this would use EnhancedTTSManager
    }
    
    // MARK: - Dashboard Actions
    
    private func handleCarPlayNavigation() {
        guard let currentPOI = agentManager?.currentPOI else {
            print("[CarPlay] No current POI for navigation")
            return
        }
        
        let coordinate = currentPOI.location.coordinate
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = currentPOI.name
        
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault,
            MKLaunchOptionsShowsTrafficKey: true
        ])
        
        print("[CarPlay] Opened navigation to \(currentPOI.name)")
    }
    
    private func handleCarPlayCall() {
        guard let currentPOI = agentManager?.currentPOI,
              let phoneNumber = currentPOI.phoneNumber,
              !phoneNumber.isEmpty else {
            print("[CarPlay] No phone number available")
            return
        }
        
        let cleanPhoneNumber = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.union(CharacterSet(charactersIn: "+")).inverted).joined()
        
        guard let phoneURL = URL(string: "tel://\(cleanPhoneNumber)") else {
            print("[CarPlay] Invalid phone number format")
            return
        }
        
        if UIApplication.shared.canOpenURL(phoneURL) {
            UIApplication.shared.open(phoneURL, options: [:])
            print("[CarPlay] Initiated call to \(cleanPhoneNumber)")
        }
    }
    
    private func refreshDashboard() {
        if currentScreen == .mainDashboard {
            showPOIDiscoveryView()
        }
    }
    
    // MARK: - Speed Monitoring
    
    private func setupSpeedMonitoring() {
        // Listen for speed updates to refresh CarPlay display
        NotificationCenter.default.addObserver(
            forName: .speedDidUpdate,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleSpeedUpdate(notification)
        }
    }
    
    private func handleSpeedUpdate(_ notification: Notification) {
        guard let speedInfo = notification.object as? SpeedInfo else { return }
        
        // Update CarPlay display if speed change is significant
        if shouldUpdateCarPlayForSpeed(speedInfo) {
            refreshCarPlayDisplay()
        }
    }
    
    private var lastUpdatedSpeed: Double = 0.0
    
    private func shouldUpdateCarPlayForSpeed(_ speedInfo: SpeedInfo) -> Bool {
        // Only update CarPlay for significant speed changes to avoid UI churn
        let speedThreshold: Double = 5.0 // Update every 5 mph change
        
        let speedChange = abs(speedInfo.speedMPH - lastUpdatedSpeed)
        
        if speedChange >= speedThreshold || speedInfo.isMoving != (lastUpdatedSpeed > 0) {
            lastUpdatedSpeed = speedInfo.speedMPH
            return true
        }
        
        return false
    }
    
    private func refreshCarPlayDisplay() {
        // Refresh the current CarPlay screen to show updated speed
        switch currentScreen {
        case .destinationSelection:
            setupDestinationSelection()
        case .mainDashboard:
            showPOIDiscoveryView()
        case .welcome:
            break
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatTripProgress() -> String {
        // Mock trip progress - in real app, use RoadtripSession
        let currentSpeed = locationManager.isMoving ? 
            " • \(locationManager.getFormattedSpeed(unit: .mph))" : ""
        return "2h 15m • 127 miles • 3 stops\(currentSpeed)"
    }
    
    // MARK: - State Synchronization
    
    private func setupStateObservers() {
        // Observe app state changes
        NotificationCenter.default.addObserver(
            forName: .roadtripStateChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.syncWithMainApp()
        }
        
        // Observe POI changes
        NotificationCenter.default.addObserver(
            forName: .currentPOIChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let poi = notification.object as? POIData {
                self?.currentPOI = poi
                self?.refreshDashboard()
            }
        }
        
        // Observe destination changes
        NotificationCenter.default.addObserver(
            forName: .destinationChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.syncWithMainApp()
        }
        
        // Observe destination selection from voice input
        NotificationCenter.default.addObserver(
            forName: .destinationSelected,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let destination = notification.object as? String else {
                print("[CarPlay] Invalid destination in notification")
                return
            }
            
            let userInfo = notification.userInfo
            let hasAction = userInfo?["hasAction"] as? Bool ?? false
            let action = userInfo?["action"] as? String
            
            print("[CarPlay] Received destination: '\(destination)', hasAction: \(hasAction), action: '\(action ?? "none")'")
            
            if hasAction && action == "navigate" {
                // Auto-navigate when action keyword was detected
                self?.speechManager.speak("Starting roadtrip to \(destination)")
                // Perform search and auto-start trip when found
                self?.searchForDestinationAndStart(destination)
            } else {
                // FIXED: Remove TTS for destination-only voice input
                // This prevents the infinite loop when user says just destination name
                print("[CarPlay] Destination selected without action - staying silent")
                self?.searchForDestination(destination)
            }
        }
    }
    
    private func syncWithMainApp() {
        // Sync state between CarPlay and main app
        if appStateManager.isInActiveRoadtrip && currentScreen != .mainDashboard {
            setupMainDashboard()
        } else if !appStateManager.isInActiveRoadtrip && currentScreen != .destinationSelection {
            setupDestinationSelection()
        }
    }
    
    // MARK: - Voice Command Integration
    
    private func setupVoiceObservers() {
        // Listen for voice command actions
        NotificationCenter.default.addObserver(
            forName: .voiceCommandAction,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleVoiceCommand(notification)
        }
        
        // Listen for general voice commands
        NotificationCenter.default.addObserver(
            forName: .voiceCommandReceived,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let command = notification.object as? String {
                self?.processCarPlayVoiceCommand(command)
            }
        }
        
        // Listen for speech state changes to update UI
        NotificationCenter.default.addObserver(
            forName: .speechDidFinish,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateVoiceButtonStates()
        }
    }
    
    private func handleVoiceCommand(_ notification: Notification) {
        guard let actionData = notification.object as? [String: Any],
              let action = actionData["action"] as? String else {
            return
        }
        
        print("[CarPlay] Handling voice command action: \(action)")
        
        switch action {
        case "save":
            agentManager?.favoriteCurrentPOI()
            speechManager.speak("Saved to favorites")
            
        case "like":
            agentManager?.likeCurrentPOI()
            refreshDashboard()
            speechManager.speak("Liked")
            
        case "dislike":
            agentManager?.dislikeCurrentPOI()
            agentManager?.nextPOI()
            refreshDashboard()
            speechManager.speak("Skipped to next place")
            
        case "next":
            agentManager?.nextPOI()
            refreshDashboard()
            speechManager.speak("Next location")
            
        case "previous":
            agentManager?.previousPOI()
            refreshDashboard()
            speechManager.speak("Previous location")
            
        case "navigate":
            handleCarPlayNavigation()
            speechManager.speak("Getting directions")
            
        case "call":
            handleCarPlayCall()
            speechManager.speak("Calling location")
            
        case "exit":
            if currentScreen == .mainDashboard {
                setupDestinationSelection()
                speechManager.speak("Returning to destination selection")
            }
            
        default:
            print("[CarPlay] Unknown voice command action: \(action)")
        }
    }
    
    private func processCarPlayVoiceCommand(_ command: String) {
        let lowercaseCommand = command.lowercased()
        
        print("[CarPlay] Processing voice command: \(command)")
        
        // Handle destination search commands
        if currentScreen == .destinationSelection {
            // If in destination selection mode and speech manager is in destination mode,
            // any voice input is treated as a destination
            if speechManager.isDestinationMode {
                // Let the SpeechManager handle destination mode processing
                return
            }
            
            // Handle specific navigation commands when not in destination mode
            if lowercaseCommand.contains("search") || lowercaseCommand.contains("find") || 
               lowercaseCommand.contains("go to") || lowercaseCommand.contains("navigate to") {
                
                // Parse destination and action from the command
                let result = parseDestinationAndAction(command)
                
                if result.action == "navigate" {
                    speechManager.speak("Starting roadtrip to \(result.destination)")
                } else {
                    speechManager.speak("Searching for \(result.destination)")
                }
                
                if !result.destination.isEmpty {
                    searchForDestination(result.destination)
                    return
                }
            }
            
            if lowercaseCommand.contains("nearby") || lowercaseCommand.contains("explore") {
                startNearbyExploration()
                speechManager.speak("Exploring nearby locations")
                return
            }
            
            if lowercaseCommand.contains("saved") || lowercaseCommand.contains("recent") {
                showSavedTrips()
                speechManager.speak("Showing recent trips")
                return
            }
        }
        
        // Fallback to general command processing
        speechManager.speak("I didn't understand that command")
    }
    
    struct DestinationActionResult {
        let destination: String
        let action: String?
    }
    
    private func parseDestinationAndAction(_ text: String) -> DestinationActionResult {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercaseText = trimmedText.lowercased()
        
        print("[CarPlay] Parsing destination and action from: '\(trimmedText)'")
        
        // Action keywords that trigger automatic navigation
        let actionKeywords = ["start", "go", "discover", "view", "navigate", "explore", "show", "begin"]
        let navigationPhrases = ["navigate to", "go to", "drive to", "take me to", "start trip to", "begin trip to"]
        
        // Check for navigation phrases first (higher priority)
        for phrase in navigationPhrases {
            if let range = lowercaseText.range(of: phrase) {
                let destination = String(trimmedText[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !destination.isEmpty {
                    print("[CarPlay] Found navigation phrase '\(phrase)' with destination '\(destination)'")
                    return DestinationActionResult(destination: destination, action: "navigate")
                }
            }
        }
        
        // Check for action at the beginning
        for keyword in actionKeywords {
            if lowercaseText.hasPrefix("\(keyword) ") {
                let destination = String(trimmedText.dropFirst(keyword.count + 1)).trimmingCharacters(in: .whitespacesAndNewlines)
                if !destination.isEmpty {
                    print("[CarPlay] Found action keyword '\(keyword)' at beginning with destination '\(destination)'")
                    return DestinationActionResult(destination: destination, action: "navigate")
                }
            }
        }
        
        // Check for action at the end (with comma or without)
        for keyword in actionKeywords {
            // Pattern: "destination, action" or "destination action"
            let patterns = [", \(keyword)", " \(keyword)"]
            
            for pattern in patterns {
                if lowercaseText.hasSuffix(pattern) {
                    let destination = String(trimmedText.dropLast(pattern.count)).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !destination.isEmpty {
                        print("[CarPlay] Found action keyword '\(keyword)' at end with destination '\(destination)'")
                        return DestinationActionResult(destination: destination, action: "navigate")
                    }
                }
            }
            
            // Pattern: "destination,action" (no space after comma)
            if lowercaseText.hasSuffix(",\(keyword)") {
                let destination = String(trimmedText.dropLast(keyword.count + 1)).trimmingCharacters(in: .whitespacesAndNewlines)
                if !destination.isEmpty {
                    print("[CarPlay] Found action keyword '\(keyword)' at end (no space) with destination '\(destination)'")
                    return DestinationActionResult(destination: destination, action: "navigate")
                }
            }
        }
        
        // No action keyword found - just return destination
        print("[CarPlay] No action keyword found, treating as destination only: '\(trimmedText)'")
        return DestinationActionResult(destination: trimmedText, action: nil)
    }
    
    private func extractDestinationFromCommand(_ command: String) -> String {
        let lowercaseCommand = command.lowercased()
        
        // Common patterns for destination extraction
        let patterns = [
            "go to ",
            "navigate to ",
            "find ",
            "search for ",
            "take me to ",
            "drive to "
        ]
        
        for pattern in patterns {
            if let range = lowercaseCommand.range(of: pattern) {
                let destination = String(command[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                return destination
            }
        }
        
        // If no pattern found, return the whole command cleaned up
        return command.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let roadtripStateChanged = Notification.Name("roadtripStateChanged")
    static let currentPOIChanged = Notification.Name("currentPOIChanged")
    static let destinationChanged = Notification.Name("destinationChanged")
    static let carPlayConnected = Notification.Name("carPlayConnected")
    static let carPlayAlreadyConnected = Notification.Name("carPlayAlreadyConnected")
}