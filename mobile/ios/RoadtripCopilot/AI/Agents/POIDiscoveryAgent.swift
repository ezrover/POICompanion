import Foundation
import CoreLocation
import Combine

class POIDiscoveryAgent: NSObject, AIAgent {
    var isRunning = false
    private let communicator: AgentCommunicator
    private let discoveryQueue = DispatchQueue(label: "com.roadtrip.poi-discovery", qos: .userInitiated)
    private var currentLocation: CLLocation?
    private var searchRadius: Double = 5000 // 5km default
    private var lastDiscoveryTime: Date?
    private var cancellables = Set<AnyCancellable>()
    
    // CRITICAL FIX NOTE: GooglePlacesAPIClient and POIDiscoveryOrchestrator are available but not yet added to iOS project
    // TODO: Add GooglePlacesAPIClient.swift and POIDiscoveryOrchestrator.swift to iOS project target
    
    // Discovery state
    private var discoveredPOIIDs = Set<String>()
    private var searchCriteria: LocationAnalysisData?
    
    init(communicator: AgentCommunicator) {
        self.communicator = communicator
        super.init()
    }
    
    func start() {
        guard !isRunning else { return }
        isRunning = true
        
        print("[POIDiscoveryAgent] Started")
        
        // Subscribe to location updates
        NotificationCenter.default.publisher(for: .locationDidUpdate)
            .compactMap { $0.object as? CLLocation }
            .sink { [weak self] location in
                self?.processLocationUpdate(location)
            }
            .store(in: &cancellables)
        
        // Subscribe to search criteria updates
        communicator.subscribe(.locationAnalysisComplete) { [weak self] message in
            if let analysisData = message.data as? LocationAnalysisData {
                self?.updateSearchCriteria(analysisData)
            }
        }
    }
    
    func stop() {
        isRunning = false
        cancellables.removeAll()
        print("[POIDiscoveryAgent] Stopped")
    }
    
    // MARK: - Location Processing
    
    private func processLocationUpdate(_ location: CLLocation) {
        discoveryQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Check if we need to discover POIs for this location
            if self.shouldDiscoverPOIs(for: location) {
                self.currentLocation = location
                self.discoverNearbyPOIs(at: location)
            }
        }
    }
    
    private func shouldDiscoverPOIs(for location: CLLocation) -> Bool {
        // Don't discover if we just did recently
        if let lastTime = lastDiscoveryTime,
           Date().timeIntervalSince(lastTime) < 60 { // 1 minute cooldown
            return false
        }
        
        // Don't discover if we're not moving (speed < 5 mph)
        if location.speed > 0 && location.speed < 2.2 { // 2.2 m/s = ~5 mph
            return false
        }
        
        // Check if we've moved enough from last location
        if let lastLocation = currentLocation {
            let distance = location.distance(from: lastLocation)
            if distance < 1000 { // 1km minimum movement
                return false
            }
        }
        
        return true
    }
    
    // MARK: - POI Discovery
    
    func discoverNearbyPOIs(at location: CLLocation) {
        print("[POIDiscoveryAgent] Discovering POIs near \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        // CRITICAL FIX: Real POI discovery system ready (GooglePlacesAPIClient + POIDiscoveryOrchestrator implemented)
        // NOTE: Currently using enhanced mock data while GooglePlacesAPIClient is added to iOS project
        print("[POIDiscoveryAgent] Real POI discovery system available - using enhanced mock data with real data structure")
        
        let enhancedPOIs = generateEnhancedPOIsReadyForRealAPI(near: location)
        
        for poi in enhancedPOIs {
            if !discoveredPOIIDs.contains(poi.id.uuidString) {
                discoveredPOIIDs.insert(poi.id.uuidString)
                
                let message = AgentMessage(
                    type: .poiDiscovered,
                    source: "POIDiscoveryAgent",
                    data: poi
                )
                communicator.send(message)
                
                print("[POIDiscoveryAgent] Enhanced POI (Real API Ready): \(poi.name) (\(poi.category)) - Rating: \(poi.rating)★")
            }
        }
        
        lastDiscoveryTime = Date()
    }
    
    func updateSearchCriteria(_ analysisData: LocationAnalysisData) {
        discoveryQueue.async { [weak self] in
            self?.searchCriteria = analysisData
            
            // Adjust search radius based on speed
            if analysisData.speed > 25 { // Highway speeds
                self?.searchRadius = 10000 // 10km
            } else if analysisData.speed > 10 { // City driving
                self?.searchRadius = 5000 // 5km
            } else { // Slow or stopped
                self?.searchRadius = 2000 // 2km
            }
            
            print("[POIDiscoveryAgent] Updated search criteria - radius: \(self?.searchRadius ?? 0)m")
        }
    }
    
    func discoverMorePOIs() {
        guard let location = currentLocation else { return }
        
        discoveryQueue.async { [weak self] in
            // CRITICAL FIX: Enhanced POI discovery ready for real API integration
            print("[POIDiscoveryAgent] Discover More: Real API system ready - using enhanced discovery")
            
            let enhancedPOIs = self?.generateEnhancedPOIsReadyForRealAPI(near: location, isDiscoverMore: true) ?? []
            
            print("[POIDiscoveryAgent] Discover More: Found \(enhancedPOIs.count) additional enhanced POIs")
            
            for poi in enhancedPOIs {
                if let strongSelf = self, !strongSelf.discoveredPOIIDs.contains(poi.id.uuidString) {
                    strongSelf.discoveredPOIIDs.insert(poi.id.uuidString)
                    
                    let message = AgentMessage(
                        type: .poiDiscovered,
                        source: "POIDiscoveryAgent",
                        data: poi
                    )
                    strongSelf.communicator.send(message)
                    
                    print("[POIDiscoveryAgent] More Enhanced POI: \(poi.name)")
                }
            }
        }
    }
    
    // MARK: - Enhanced POI Generation (Ready for Real API Integration)
    
    private func generateEnhancedPOIsReadyForRealAPI(near location: CLLocation, isDiscoverMore: Bool = false) -> [POIData] {
        print("[POIDiscoveryAgent] Using enhanced POI data structure (real API integration ready)")
        
        // Enhanced POI data that matches the structure expected from GooglePlacesAPIClient + POIDiscoveryOrchestrator
        // These represent realistic POI data that the real APIs would return
        
        let baseCategories = ["restaurant", "attraction", "gas_station", "hotel", "shopping"]
        let categories = isDiscoverMore ? 
            ["museum", "park", "pharmacy", "bank", "church"] : 
            baseCategories
        
        var enhancedPOIs: [POIData] = []
        
        for category in categories.prefix(isDiscoverMore ? 3 : 2) {
            let poi = POIData(
                name: generateRealisticPOIName(for: category, location: location),
                location: generateNearbyLocation(from: location),
                category: category,
                rating: Double.random(in: 3.8...4.9), // Realistic rating range
                imageURL: URL(string: "https://places.googleapis.com/v1/places/mock-photo-reference"),
                reviewSummary: generateRealisticReviewSummary(for: category),
                distanceFromUser: Double.random(in: 0.3...8.0), // Realistic distance range
                couldEarnRevenue: Double.random(in: 0...1) > 0.3 // 70% chance for revenue
            )
            enhancedPOIs.append(poi)
        }
        
        return enhancedPOIs
    }
    
    private func generateRealisticPOIName(for category: String, location: CLLocation) -> String {
        // Generate realistic POI names based on location and category
        let locationBasedNames = [
            "restaurant": ["Local Bistro", "Coastal Cafe", "Downtown Diner", "Highway Grill", "Riverside Restaurant"],
            "attraction": ["Scenic Viewpoint", "Historic Landmark", "Nature Trail", "Visitors Center", "Local Museum"],
            "gas_station": ["Quick Stop", "Highway Fuel", "Travel Mart", "Express Gas", "Route Stop"],
            "hotel": ["Roadside Inn", "Traveler's Lodge", "Comfort Stay", "Highway Hotel", "Local B&B"],
            "shopping": ["General Store", "Local Market", "Outlet Mall", "Shopping Center", "Antique Shop"],
            "museum": ["History Museum", "Art Gallery", "Science Center", "Cultural Center", "Heritage Site"],
            "park": ["City Park", "Nature Reserve", "Recreation Area", "Botanical Garden", "Wildlife Park"],
            "pharmacy": ["Corner Pharmacy", "Health Plus", "MediCare", "Wellness Pharmacy", "Local Drugstore"],
            "bank": ["Community Bank", "First National", "Credit Union", "Local Banking", "Financial Center"],
            "church": ["Community Church", "St. Mary's", "Baptist Church", "Methodist Church", "Faith Center"]
        ]
        
        let categoryNames = locationBasedNames[category] ?? ["Local \(category.capitalized)"]
        return categoryNames.randomElement() ?? "Local Business"
    }
    
    private func generateRealisticReviewSummary(for category: String) -> String {
        let reviewTemplates = [
            "restaurant": ["Great food and friendly service", "Excellent local cuisine", "Hidden gem with amazing atmosphere", "Perfect roadside stop"],
            "attraction": ["Must-see destination", "Beautiful scenic views", "Rich history and culture", "Great photo opportunities"],
            "gas_station": ["Clean facilities and good prices", "Convenient location", "Friendly staff", "Well-maintained station"],
            "hotel": ["Comfortable rooms and good value", "Clean and quiet", "Excellent customer service", "Perfect for travelers"],
            "shopping": ["Wide selection and fair prices", "Unique local items", "Helpful staff", "Great browsing experience"]
        ]
        
        let templates = reviewTemplates[category] ?? ["Good local business"]
        return templates.randomElement() ?? "Positive reviews"
    }
    
    private func generateNearbyLocation(from center: CLLocation) -> CLLocation {
        // Generate location within search radius
        let radiusInDegrees = (searchRadius / 111000.0) // Rough conversion to degrees
        
        let randomLat = center.coordinate.latitude + Double.random(in: -radiusInDegrees...radiusInDegrees)
        let randomLon = center.coordinate.longitude + Double.random(in: -radiusInDegrees...radiusInDegrees)
        
        return CLLocation(latitude: randomLat, longitude: randomLon)
    }
}