import Foundation
import MapKit
import CoreLocation

// MARK: - POI Data Model

struct POIData: Identifiable, Codable, Equatable {
    let id = UUID()
    let name: String
    let location: CLLocation
    let category: String
    let rating: Double
    let imageURL: URL?
    let reviewSummary: String?
    let distanceFromUser: Double
    let couldEarnRevenue: Bool
    let phoneNumber: String?
    let website: String?
    let address: String?
    
    // Custom Codable implementation due to CLLocation
    enum CodingKeys: String, CodingKey {
        case name, category, rating, imageURL, reviewSummary, distanceFromUser, couldEarnRevenue
        case phoneNumber, website, address
        case latitude, longitude
    }
    
    init(name: String, location: CLLocation, category: String, rating: Double = 0.0, 
         imageURL: URL? = nil, reviewSummary: String? = nil, distanceFromUser: Double = 0.0, 
         couldEarnRevenue: Bool = false, phoneNumber: String? = nil, website: String? = nil,
         address: String? = nil) {
        self.name = name
        self.location = location
        self.category = category
        self.rating = rating
        self.imageURL = imageURL
        self.reviewSummary = reviewSummary
        self.distanceFromUser = distanceFromUser
        self.couldEarnRevenue = couldEarnRevenue
        self.phoneNumber = phoneNumber
        self.website = website
        self.address = address
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try container.decode(String.self, forKey: .name)
        category = try container.decode(String.self, forKey: .category)
        rating = try container.decode(Double.self, forKey: .rating)
        imageURL = try container.decodeIfPresent(URL.self, forKey: .imageURL)
        reviewSummary = try container.decodeIfPresent(String.self, forKey: .reviewSummary)
        distanceFromUser = try container.decode(Double.self, forKey: .distanceFromUser)
        couldEarnRevenue = try container.decode(Bool.self, forKey: .couldEarnRevenue)
        phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
        website = try container.decodeIfPresent(String.self, forKey: .website)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        location = CLLocation(latitude: latitude, longitude: longitude)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encode(category, forKey: .category)
        try container.encode(rating, forKey: .rating)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encodeIfPresent(reviewSummary, forKey: .reviewSummary)
        try container.encode(distanceFromUser, forKey: .distanceFromUser)
        try container.encode(couldEarnRevenue, forKey: .couldEarnRevenue)
        try container.encodeIfPresent(phoneNumber, forKey: .phoneNumber)
        try container.encodeIfPresent(website, forKey: .website)
        try container.encodeIfPresent(address, forKey: .address)
        try container.encode(location.coordinate.latitude, forKey: .latitude)
        try container.encode(location.coordinate.longitude, forKey: .longitude)
    }
    
    static func == (lhs: POIData, rhs: POIData) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - App State Management

enum AppScreen {
    case loading
    case destinationSelection
    case mainDashboard
}

class AppStateManager: ObservableObject {
    @Published var currentScreen: AppScreen = .loading
    @Published var selectedDestination: MKMapItem?
    @Published var roadtripStarted: Bool = false
    @Published var savedDestinationName: String? = nil
    
    func startRoadtrip(to destination: MKMapItem) {
        selectedDestination = destination
        roadtripStarted = true
        currentScreen = .mainDashboard
        
        // Store destination for the trip
        UserDefaults.standard.set(destination.name, forKey: "current_destination_name")
        UserDefaults.standard.set(destination.placemark.coordinate.latitude, forKey: "current_destination_lat")
        UserDefaults.standard.set(destination.placemark.coordinate.longitude, forKey: "current_destination_lng")
        
        // Notify CarPlay of roadtrip state change
        NotificationCenter.default.post(name: .roadtripStateChanged, object: nil)
        NotificationCenter.default.post(name: .destinationChanged, object: destination)
        
        print("Roadtrip started to: \(destination.name ?? "Unknown destination")")
    }
    
    func endRoadtrip() {
        selectedDestination = nil
        roadtripStarted = false
        currentScreen = .destinationSelection
        
        // Clear stored destination
        UserDefaults.standard.removeObject(forKey: "current_destination_name")
        UserDefaults.standard.removeObject(forKey: "current_destination_lat")
        UserDefaults.standard.removeObject(forKey: "current_destination_lng")
        
        // Notify CarPlay of roadtrip state change
        NotificationCenter.default.post(name: .roadtripStateChanged, object: nil)
        
        print("Roadtrip ended")
    }
    
    func returnToDestinationSelection() {
        // Keep destination data but return to selection screen to allow changing destination
        currentScreen = .destinationSelection
        print("Returned to destination selection screen")
    }
    
    func loadSavedDestination() {
        // Always go to destination selection first - let user decide whether to resume
        currentScreen = .destinationSelection
        
        // If there's a saved destination, set it for the search input to populate
        if let destinationName = UserDefaults.standard.string(forKey: "current_destination_name") {
            savedDestinationName = destinationName
            print("Found saved destination: \(destinationName) - will populate search input")
        } else {
            savedDestinationName = nil
            print("No saved destination found")
        }
    }
    
    func clearSavedDestination() {
        // Helper method to clear saved destinations for testing
        UserDefaults.standard.removeObject(forKey: "current_destination_name")
        UserDefaults.standard.removeObject(forKey: "current_destination_lat")
        UserDefaults.standard.removeObject(forKey: "current_destination_lng")
        savedDestinationName = nil
        selectedDestination = nil
        roadtripStarted = false
        print("Cleared all saved destination data")
    }
    
    var destinationInfo: String {
        guard let destination = selectedDestination else {
            return "No destination selected"
        }
        
        return destination.name ?? "Unknown destination"
    }
}

// MARK: - Destination Data Model

struct DestinationInfo {
    let name: String
    let address: String?
    let coordinate: CLLocationCoordinate2D
    let estimatedDuration: TimeInterval?
    let distance: CLLocationDistance?
    
    init(from mapItem: MKMapItem) {
        self.name = mapItem.name ?? "Unknown Location"
        self.address = mapItem.placemark.title
        self.coordinate = mapItem.placemark.coordinate
        self.estimatedDuration = nil // Would be calculated from routing
        self.distance = nil // Would be calculated from routing
    }
}

// MARK: - Roadtrip Session Data

class RoadtripSession: ObservableObject {
    @Published var startTime: Date?
    @Published var currentLocation: CLLocation?
    @Published var destinationReached: Bool = false
    @Published var poisDiscovered: [POIData] = []
    @Published var totalDistance: CLLocationDistance = 0
    @Published var elapsedTime: TimeInterval = 0
    
    private var timer: Timer?
    
    func startSession() {
        startTime = Date()
        startTimer()
        print("Roadtrip session started")
    }
    
    func endSession() {
        timer?.invalidate()
        timer = nil
        
        // Save session data
        saveSessionData()
        
        print("Roadtrip session ended. Duration: \(elapsedTime) seconds, POIs discovered: \(poisDiscovered.count)")
    }
    
    func pauseSession() {
        // Pause timer but keep session data
        timer?.invalidate()
        timer = nil
        print("Roadtrip session paused")
    }
    
    func resumeSession() {
        // Resume timer if session was paused
        if startTime != nil {
            startTimer()
            print("Roadtrip session resumed")
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if let startTime = self.startTime {
                self.elapsedTime = Date().timeIntervalSince(startTime)
            }
        }
    }
    
    func addDiscoveredPOI(_ poi: POIData) {
        poisDiscovered.append(poi)
        print("Discovered POI: \(poi.name)")
    }
    
    private func saveSessionData() {
        // Save session data to UserDefaults or Core Data
        let sessionData: [String: Any] = [
            "start_time": startTime?.timeIntervalSince1970 ?? 0,
            "elapsed_time": elapsedTime,
            "total_distance": totalDistance,
            "pois_count": poisDiscovered.count
        ]
        
        UserDefaults.standard.set(sessionData, forKey: "last_roadtrip_session")
    }
}

// MARK: - Navigation State

enum NavigationState {
    case planning
    case navigating
    case arrived
    case exploring
}

extension AppStateManager {
    var navigationState: NavigationState {
        if !roadtripStarted {
            return .planning
        } else if selectedDestination != nil {
            return .navigating
        } else {
            return .exploring
        }
    }
    
    var isInActiveRoadtrip: Bool {
        return roadtripStarted && selectedDestination != nil
    }
}