import Foundation
import CoreLocation
import SwiftUI
import Combine
import ObjectiveC

@MainActor
class AutoDiscoverManager: NSObject, ObservableObject {
    static let shared = AutoDiscoverManager()
    
    // MARK: - Published Properties
    @Published var isDiscoveryActive = false
    @Published var discoveredPOIs: [POI] = []
    @Published var currentPOIIndex = 0
    @Published var isAutoPhotoActive = false
    @Published var currentPhotoIndex = 0
    @Published var dislikedPOIs = Set<String>()
    
    // MARK: - Private Properties
    private let locationManager = LocationManager.shared
    private let rankingEngine = POIRankingEngine()
    private let googlePlacesClient = GooglePlacesAPIClient()
    private var autoPhotoTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // Discovery settings
    private var searchRadius: CLLocationDistance = 5000 // 5km default
    private let maxPOIs = 10
    private let photosPerPOI = 5
    private let photoDisplayDuration: TimeInterval = 2.0
    
    override init() {
        super.init()
        loadDislikedPOIs()
        setupLocationUpdates()
    }
    
    // MARK: - Public Methods
    
    /// Starts the auto discovery process
    func startAutoDiscovery() async {
        guard let currentLocation = await getCurrentLocation() else {
            print("[AutoDiscoverManager] No location available for discovery")
            throw AutoDiscoverError.locationUnavailable
        }
        
        isDiscoveryActive = true
        
        do {
            // Search for POIs
            let nearbyPOIs = try await searchNearbyPOIs(location: currentLocation)
            
            // Rank and filter POIs
            let rankedPOIs = await rankingEngine.rankPOIs(nearbyPOIs, userLocation: currentLocation)
            
            // Filter out disliked POIs
            let filteredPOIs = rankedPOIs.filter { !dislikedPOIs.contains($0.id) }
            
            // Take top 10
            discoveredPOIs = Array(filteredPOIs.prefix(maxPOIs))
            
            if discoveredPOIs.isEmpty {
                // Expand search radius if no results
                searchRadius *= 2
                await startAutoDiscovery()
                return
            }
            
            currentPOIIndex = 0
            
            // Load photos for each POI
            await loadPhotosForAllPOIs()
            
            // Start auto photo cycling
            startAutoPhotoCycling()
            
            print("[AutoDiscoverManager] Discovery started with \(discoveredPOIs.count) POIs")
            
        } catch {
            print("[AutoDiscoverManager] Discovery failed: \(error)")
            isDiscoveryActive = false
            throw error
        }
    }
    
    /// Stops auto discovery and returns to normal mode
    func stopAutoDiscovery() {
        isDiscoveryActive = false
        isAutoPhotoActive = false
        stopAutoPhotoCycling()
        discoveredPOIs.removeAll()
        currentPOIIndex = 0
        currentPhotoIndex = 0
        print("[AutoDiscoverManager] Auto discovery stopped")
    }
    
    /// Navigates to next POI in discovery list
    func nextPOI() {
        guard !discoveredPOIs.isEmpty else { return }
        
        currentPOIIndex = (currentPOIIndex + 1) % discoveredPOIs.count
        currentPhotoIndex = 0
        
        print("[AutoDiscoverManager] Next POI: \(currentPOI?.name ?? "Unknown")")
    }
    
    /// Navigates to previous POI in discovery list
    func previousPOI() {
        guard !discoveredPOIs.isEmpty else { return }
        
        currentPOIIndex = currentPOIIndex == 0 ? discoveredPOIs.count - 1 : currentPOIIndex - 1
        currentPhotoIndex = 0
        
        print("[AutoDiscoverManager] Previous POI: \(currentPOI?.name ?? "Unknown")")
    }
    
    /// Dislikes current POI and moves to next
    func dislikeCurrentPOI() {
        guard let currentPOI = currentPOI else { return }
        
        // Add to disliked list
        dislikedPOIs.insert(currentPOI.id)
        saveDislikedPOIs()
        
        // Remove from current list
        if discoveredPOIs.count > 1 {
            discoveredPOIs.remove(at: currentPOIIndex)
            
            // Adjust index if needed
            if currentPOIIndex >= discoveredPOIs.count {
                currentPOIIndex = 0
            }
        } else {
            // Last POI disliked, expand search
            Task {
                searchRadius *= 1.5
                await startAutoDiscovery()
            }
        }
        
        currentPhotoIndex = 0
        print("[AutoDiscoverManager] Disliked POI: \(currentPOI.name)")
    }
    
    /// Gets current POI
    var currentPOI: POI? {
        guard currentPOIIndex < discoveredPOIs.count else { return nil }
        return discoveredPOIs[currentPOIIndex]
    }
    
    /// Gets current POI photos
    var currentPOIPhotos: [URL] {
        return currentPOI?.photos ?? []
    }
    
    /// Gets current photo URL
    var currentPhoto: URL? {
        let photos = currentPOIPhotos
        guard currentPhotoIndex < photos.count else { return nil }
        return photos[currentPhotoIndex]
    }
    
    // MARK: - Private Methods
    
    private func getCurrentLocation() async -> CLLocation? {
        return locationManager.currentLocation
    }
    
    private func setupLocationUpdates() {
        locationManager.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                // Update discovery when location changes significantly
                Task { @MainActor in
                    await self?.handleLocationUpdate(location)
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleLocationUpdate(_ location: CLLocation) async {
        // Restart discovery if user moves significantly and discovery is active
        if isDiscoveryActive {
            // Check if moved more than 1km
            if let firstPOI = discoveredPOIs.first {
                let poiLocation = CLLocation(latitude: firstPOI.location.coordinate.latitude,
                                           longitude: firstPOI.location.coordinate.longitude)
                let distance = location.distance(from: poiLocation)
                
                if distance > 1000 { // 1km
                    print("[AutoDiscoverManager] Location changed significantly, restarting discovery")
                    await startAutoDiscovery()
                }
            }
        }
    }
    
    private func searchNearbyPOIs(location: CLLocation) async throws -> [POI] {
        return try await googlePlacesClient.searchNearbyPOIs(
            location: location.coordinate,
            radius: searchRadius
        )
    }
    
    private func loadPhotosForAllPOIs() async {
        for i in 0..<discoveredPOIs.count {
            do {
                let photos = try await googlePlacesClient.getPhotosForPOI(
                    placeId: discoveredPOIs[i].placeId ?? "",
                    maxPhotos: photosPerPOI
                )
                discoveredPOIs[i].photos = photos
            } catch {
                print("[AutoDiscoverManager] Failed to load photos for POI \(discoveredPOIs[i].name): \(error)")
            }
        }
    }
    
    private func startAutoPhotoCycling() {
        guard !discoveredPOIs.isEmpty else { return }
        
        isAutoPhotoActive = true
        
        autoPhotoTimer = Timer.scheduledTimer(withTimeInterval: photoDisplayDuration, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.cycleToNextPhoto()
            }
        }
        
        print("[AutoDiscoverManager] Auto photo cycling started")
    }
    
    private func stopAutoPhotoCycling() {
        autoPhotoTimer?.invalidate()
        autoPhotoTimer = nil
        isAutoPhotoActive = false
        print("[AutoDiscoverManager] Auto photo cycling stopped")
    }
    
    private func cycleToNextPhoto() async {
        guard isAutoPhotoActive && !discoveredPOIs.isEmpty else { return }
        
        let currentPhotos = currentPOIPhotos
        
        if currentPhotoIndex < currentPhotos.count - 1 {
            // Next photo in current POI
            currentPhotoIndex += 1
        } else {
            // Finished all photos for current POI, move to next POI
            nextPOI()
        }
    }
    
    // MARK: - Persistence
    
    private func loadDislikedPOIs() {
        if let data = UserDefaults.standard.data(forKey: "dislikedPOIs"),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            dislikedPOIs = decoded
        }
        print("[AutoDiscoverManager] Loaded \(dislikedPOIs.count) disliked POIs")
    }
    
    private func saveDislikedPOIs() {
        if let encoded = try? JSONEncoder().encode(dislikedPOIs) {
            UserDefaults.standard.set(encoded, forKey: "dislikedPOIs")
            print("[AutoDiscoverManager] Saved \(dislikedPOIs.count) disliked POIs")
        }
    }
}

// MARK: - Error Types

enum AutoDiscoverError: Error, LocalizedError {
    case locationUnavailable
    case noResultsFound
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .locationUnavailable:
            return "Location services are not available"
        case .noResultsFound:
            return "No interesting places found nearby"
        case .networkError:
            return "Network connection error"
        }
    }
}

// MARK: - POI Model Extension

extension POI {
    var photos: [URL] {
        get {
            return _photos ?? []
        }
        set {
            _photos = newValue
        }
    }
    
    private var _photos: [URL]? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.photos) as? [URL]
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.photos, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

private struct AssociatedKeys {
    static var photos = "photos"
}

// MARK: - Voice Commands Extension

extension AutoDiscoverManager {
    func handleVoiceCommand(_ command: String) {
        let lowercased = command.lowercased()
        
        if lowercased.contains("next") || lowercased.contains("skip") {
            nextPOI()
        } else if lowercased.contains("previous") || lowercased.contains("back") {
            previousPOI()
        } else if lowercased.contains("dislike") || lowercased.contains("don't like") {
            dislikeCurrentPOI()
        } else if lowercased.contains("stop") || lowercased.contains("exit") {
            stopAutoDiscovery()
        }
    }
}