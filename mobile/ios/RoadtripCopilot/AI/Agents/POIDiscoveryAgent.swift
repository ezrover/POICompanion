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
    
    // CRITICAL FIX: Use POIDiscoveryOrchestrator instead of mock data
    @available(iOS 16.0, *)
    private lazy var poiOrchestrator = POIDiscoveryOrchestrator.shared
    
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
        
        // CRITICAL FIX: Use real POI discovery instead of mock data
        if #available(iOS 16.0, *) {
            Task {
                do {
                    // Determine optimal category based on search criteria
                    let category = searchCriteria?.nearbyCategories.first ?? "attraction"
                    
                    // Use POIDiscoveryOrchestrator for real POI discovery with hybrid LLM+API approach
                    let discoveryResult = try await poiOrchestrator.discoverPOIs(
                        near: location,
                        category: category,
                        preferredStrategy: .hybrid,
                        maxResults: 8
                    )
                    
                    print("[POIDiscoveryAgent] POI Discovery completed in \(String(format: "%.0f", discoveryResult.responseTime * 1000))ms using \(discoveryResult.strategyUsed)")
                    print("[POIDiscoveryAgent] Found \(discoveryResult.pois.count) POIs, fallback used: \(discoveryResult.fallbackUsed)")
                    
                    // Process discovered POIs
                    for poi in discoveryResult.pois {
                        // Check if we already discovered this POI
                        if !discoveredPOIIDs.contains(poi.id.uuidString) {
                            discoveredPOIIDs.insert(poi.id.uuidString)
                            
                            // Send discovery message
                            let message = AgentMessage(
                                type: .poiDiscovered,
                                source: "POIDiscoveryAgent",
                                data: poi
                            )
                            communicator.send(message)
                            
                            print("[POIDiscoveryAgent] Discovered: \(poi.name) (\(poi.category)) - Rating: \(poi.rating)★")
                        }
                    }
                    
                } catch {
                    print("[POIDiscoveryAgent] Real POI discovery failed: \(error.localizedDescription)")
                    // Fallback to basic mock data if all else fails
                    let fallbackPOIs = generateBasicFallbackPOIs(near: location)
                    
                    for poi in fallbackPOIs {
                        if !discoveredPOIIDs.contains(poi.id.uuidString) {
                            discoveredPOIIDs.insert(poi.id.uuidString)
                            
                            let message = AgentMessage(
                                type: .poiDiscovered,
                                source: "POIDiscoveryAgent",
                                data: poi
                            )
                            communicator.send(message)
                            
                            print("[POIDiscoveryAgent] Fallback POI: \(poi.name)")
                        }
                    }
                }
            }
        } else {
            // iOS 15 fallback - use basic mock data
            let fallbackPOIs = generateBasicFallbackPOIs(near: location)
            
            for poi in fallbackPOIs {
                if !discoveredPOIIDs.contains(poi.id.uuidString) {
                    discoveredPOIIDs.insert(poi.id.uuidString)
                    
                    let message = AgentMessage(
                        type: .poiDiscovered,
                        source: "POIDiscoveryAgent",
                        data: poi
                    )
                    communicator.send(message)
                    
                    print("[POIDiscoveryAgent] iOS 15 Fallback POI: \(poi.name)")
                }
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
            // Expand search radius for more POIs
            let originalRadius = self?.searchRadius ?? 5000
            self?.searchRadius = originalRadius * 2
            
            self?.discoverNearbyPOIs(at: location)
            
            // Reset radius
            self?.searchRadius = originalRadius
        }
    }
    
    // MARK: - Mock Data Generation
    
    private func generateMockPOIs(near location: CLLocation) -> [POIData] {
        let categories = searchCriteria?.nearbyCategories ?? ["restaurant", "attraction", "gas_station", "hotel"]
        var pois: [POIData] = []
        
        for category in categories.prefix(3) { // Limit to 3 categories per discovery
            let poi = POIData(
                name: generatePOIName(for: category),
                location: generateNearbyLocation(from: location),
                category: category,
                rating: Double.random(in: 3.5...5.0),
                imageURL: URL(string: "https://example.com/poi-image.jpg"),
                reviewSummary: nil, // Will be filled by ReviewDistillationAgent
                distanceFromUser: Double.random(in: 0.5...5.0),
                couldEarnRevenue: Bool.random() // Simulate first-discovery validation
            )
            pois.append(poi)
        }
        
        return pois
    }
    
    private func generatePOIName(for category: String) -> String {
        let names = [
            "restaurant": ["The Local Diner", "Sunset Grill", "Mountain View Cafe", "Rustic Table"],
            "attraction": ["Historic Lighthouse", "Scenic Overlook", "Art Gallery", "Nature Trail"],
            "gas_station": ["QuickStop Fuel", "Highway Express", "FuelMart", "Travel Center"],
            "hotel": ["Comfort Inn", "Roadside Lodge", "Traveler's Rest", "Highway Motel"]
        ]
        
        let categoryNames = names[category] ?? ["Unknown Place"]
        return categoryNames.randomElement() ?? "Unknown Place"
    }
    
    private func generateNearbyLocation(from center: CLLocation) -> CLLocation {
        // Generate location within search radius
        let radiusInDegrees = (searchRadius / 111000.0) // Rough conversion to degrees
        
        let randomLat = center.coordinate.latitude + Double.random(in: -radiusInDegrees...radiusInDegrees)
        let randomLon = center.coordinate.longitude + Double.random(in: -radiusInDegrees...radiusInDegrees)
        
        return CLLocation(latitude: randomLat, longitude: randomLon)
    }
}