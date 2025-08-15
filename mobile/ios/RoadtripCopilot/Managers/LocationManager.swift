import Foundation
import CoreLocation
import Combine
import UIKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    // Reverse geocoding state management
    private var isReverseGeocoding = false
    private var lastReverseGeocodingLocation: CLLocation?
    private let reverseGeocodingTimeInterval: TimeInterval = 30.0 // Minimum time between requests
    private var isSearchInProgress = false // Track if search is active to avoid geocoding spam
    
    @Published var currentLocation: CLLocation?
    @Published var currentCity: String?
    @Published var currentState: String?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    // MARK: - Speed Detection Properties
    @Published var currentSpeed: CLLocationSpeed = 0.0 // m/s
    @Published var currentSpeedMPH: Double = 0.0
    @Published var currentSpeedKMH: Double = 0.0
    @Published var maxSpeed: CLLocationSpeed = 0.0
    @Published var averageSpeed: CLLocationSpeed = 0.0
    @Published var isMoving: Bool = false
    
    // Speed calculation properties
    private var speedHistory: [CLLocationSpeed] = []
    private let maxSpeedHistoryCount = 10
    private let movingThreshold: CLLocationSpeed = 0.5 // 0.5 m/s (~1.1 mph)
    
    private var cancellables = Set<AnyCancellable>()
    
    // Helper property for better logging
    private var authorizationStatusString: String {
        switch authorizationStatus {
        case .notDetermined: return "Not Determined"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .authorizedWhenInUse: return "When In Use"
        case .authorizedAlways: return "Always"
        @unknown default: return "Unknown"
        }
    }
    
    override init() {
        super.init()
        setupLocationManager()
        // Get initial authorization status from the instance (preferred in iOS 14+)
        authorizationStatus = locationManager.authorizationStatus
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        // Enhanced accuracy for speed detection
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 5.0 // Update every 5 meters for accurate speed tracking
        
        // Don't automatically request permissions or start updates during setup
        // Let the LocationAuthorizationView handle the permission flow
        print("LocationManager initialized with status: \(authorizationStatusString)")
    }
    
    func requestLocationPermissions() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            print("Location access denied or restricted")
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            break
        }
    }
    
    func startLocationUpdates() {
        guard authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse else {
            print("⚠️ Cannot start location updates: \(authorizationStatusString)")
            return
        }
        
        // Start significant location changes for background operation
        locationManager.startMonitoringSignificantLocationChanges()
        
        // Also start standard location updates when app is active
        if UIApplication.shared.applicationState == .active {
            locationManager.startUpdatingLocation()
        }
        
        print("✅ Started location updates successfully")
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
        }
        
        print("📍 Location authorization changed to: \(authorizationStatusString)")
        
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            print("✅ Location permission granted - ready for updates when needed")
            // PERFORMANCE FIX: Don't automatically start location updates
            // Let views explicitly call startLocationUpdates() when needed
        case .denied, .restricted:
            print("❌ Location access denied or restricted - stopping updates")
            stopLocationUpdates()
        case .notDetermined:
            print("⏳ Location authorization still not determined - waiting for user choice")
            // Don't call requestLocationPermissions again to avoid recursion
        @unknown default:
            print("❓ Unknown authorization status")
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        print("📍 Received location update: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        DispatchQueue.main.async {
            self.currentLocation = location
            
            // Process speed detection
            self.processSpeedUpdate(from: location)
        }
        
        // Reverse geocode to get city and state
        reverseGeocode(location: location)
        
        // Notify AI agents of location change
        NotificationCenter.default.post(
            name: .locationDidUpdate,
            object: location
        )
        
        // Notify speed update
        NotificationCenter.default.post(
            name: .speedDidUpdate,
            object: SpeedInfo(
                speedMPS: currentSpeed,
                speedMPH: currentSpeedMPH,
                speedKMH: currentSpeedKMH,
                isMoving: isMoving
            )
        )
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
    
    // MARK: - Speed Detection
    
    private func processSpeedUpdate(from location: CLLocation) {
        // Get speed from CoreLocation (in m/s)
        let speed = max(0.0, location.speed) // Negative speed indicates invalid data
        
        // Update current speed if valid
        if speed >= 0 {
            currentSpeed = speed
            
            // Convert to different units
            currentSpeedMPH = speed * 2.237 // m/s to mph
            currentSpeedKMH = speed * 3.6   // m/s to km/h
            
            // Update moving state
            isMoving = speed >= movingThreshold
            
            // Track speed history for average calculation
            updateSpeedHistory(speed)
            
            // Update max speed
            if speed > maxSpeed {
                maxSpeed = speed
            }
            
            // Calculate average speed
            calculateAverageSpeed()
            
            print("🚗 Speed update: \(String(format: "%.1f", currentSpeedMPH)) mph, \(String(format: "%.1f", currentSpeedKMH)) km/h, Moving: \(isMoving)")
        } else {
            print("⚠️ Invalid speed data received: \(speed)")
        }
    }
    
    private func updateSpeedHistory(_ speed: CLLocationSpeed) {
        speedHistory.append(speed)
        
        // Maintain history size limit
        if speedHistory.count > maxSpeedHistoryCount {
            speedHistory.removeFirst()
        }
    }
    
    private func calculateAverageSpeed() {
        guard !speedHistory.isEmpty else {
            averageSpeed = 0.0
            return
        }
        
        let totalSpeed = speedHistory.reduce(0.0, +)
        averageSpeed = totalSpeed / Double(speedHistory.count)
    }
    
    // Public methods for speed data access
    func getFormattedSpeed(unit: SpeedUnit = .mph) -> String {
        switch unit {
        case .mph:
            return String(format: "%.0f mph", currentSpeedMPH)
        case .kmh:
            return String(format: "%.0f km/h", currentSpeedKMH)
        case .mps:
            return String(format: "%.1f m/s", currentSpeed)
        }
    }
    
    func getFormattedAverageSpeed(unit: SpeedUnit = .mph) -> String {
        let avgMPH = averageSpeed * 2.237
        let avgKMH = averageSpeed * 3.6
        
        switch unit {
        case .mph:
            return String(format: "%.0f mph", avgMPH)
        case .kmh:
            return String(format: "%.0f km/h", avgKMH)
        case .mps:
            return String(format: "%.1f m/s", averageSpeed)
        }
    }
    
    func getFormattedMaxSpeed(unit: SpeedUnit = .mph) -> String {
        let maxMPH = maxSpeed * 2.237
        let maxKMH = maxSpeed * 3.6
        
        switch unit {
        case .mph:
            return String(format: "%.0f mph", maxMPH)
        case .kmh:
            return String(format: "%.0f km/h", maxKMH)
        case .mps:
            return String(format: "%.1f m/s", maxSpeed)
        }
    }
    
    func resetSpeedTracking() {
        currentSpeed = 0.0
        currentSpeedMPH = 0.0
        currentSpeedKMH = 0.0
        maxSpeed = 0.0
        averageSpeed = 0.0
        isMoving = false
        speedHistory.removeAll()
        
        print("🔄 Speed tracking reset")
    }
    
    // MARK: - Geocoding
    
    private func reverseGeocode(location: CLLocation) {
        // Prevent concurrent reverse geocoding requests
        guard !isReverseGeocoding else {
            print("Reverse geocoding already in progress, skipping")
            return
        }
        
        // CRITICAL FIX: Skip reverse geocoding when search is in progress to reduce network load
        guard !isSearchInProgress else {
            print("Search in progress - skipping reverse geocoding to avoid network conflicts")
            return
        }
        
        // Check if we've recently reverse geocoded this location
        if let lastLocation = lastReverseGeocodingLocation {
            let timeSinceLastRequest = Date().timeIntervalSince(lastLocation.timestamp)
            let distance = location.distance(from: lastLocation)
            
            // Skip if recent request for similar location (within 500m and 30 seconds)
            if distance < 500 && timeSinceLastRequest < reverseGeocodingTimeInterval {
                print("Skipping reverse geocoding - recent request for nearby location")
                return
            }
        }
        
        isReverseGeocoding = true
        lastReverseGeocodingLocation = location
        
        print("Starting reverse geocoding for location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isReverseGeocoding = false
            }
            
            if let error = error {
                let nsError = error as NSError
                print("Reverse geocoding failed: \(error.localizedDescription) (Code: \(nsError.code))")
                
                // Handle specific CLError cases
                if nsError.domain == kCLErrorDomain {
                    switch nsError.code {
                    case CLError.Code.locationUnknown.rawValue:
                        print("Location unknown - continuing with location updates")
                    case CLError.Code.network.rawValue:
                        print("Network error during reverse geocoding - will retry with next location update")
                        // Reset last location to allow retry
                        DispatchQueue.main.async {
                            self.lastReverseGeocodingLocation = nil
                        }
                    case CLError.Code.denied.rawValue:
                        print("Reverse geocoding denied - location permissions may be insufficient")
                    case CLError.Code.geocodeCanceled.rawValue:
                        print("Reverse geocoding was cancelled")
                    case CLError.Code.geocodeFoundNoResult.rawValue:
                        print("Reverse geocoding found no results for location")
                    case CLError.Code.geocodeFoundPartialResult.rawValue:
                        print("Reverse geocoding found partial results")
                    default:
                        print("Unknown reverse geocoding error: \(nsError.code)")
                    }
                }
                return
            }
            
            guard let placemark = placemarks?.first else {
                print("No placemark found in reverse geocoding response")
                return
            }
            
            print("Reverse geocoding successful: \(placemark.locality ?? "Unknown city"), \(placemark.administrativeArea ?? "Unknown state")")
            
            DispatchQueue.main.async {
                self.currentCity = placemark.locality ?? placemark.subAdministrativeArea
                self.currentState = placemark.administrativeArea
            }
            
            // Notify AI agents of location name update
            let locationInfo = LocationInfo(
                coordinate: location.coordinate,
                city: placemark.locality ?? placemark.subAdministrativeArea,
                state: placemark.administrativeArea,
                country: placemark.country
            )
            
            NotificationCenter.default.post(
                name: .locationNameDidUpdate,
                object: locationInfo
            )
        }
    }
    
    // MARK: - Geocoder Utilities
    
    func cancelReverseGeocoding() {
        if isReverseGeocoding {
            geocoder.cancelGeocode()
            isReverseGeocoding = false
            print("Cancelled reverse geocoding operation")
        }
    }
    
    // MARK: - Background Location Handling
    
    func enableBackgroundLocationUpdates() {
        guard authorizationStatus == .authorizedAlways else {
            print("Background location requires 'Always' authorization")
            return
        }
        
        // Check if background location updates is supported and app has background mode
        guard CLLocationManager.significantLocationChangeMonitoringAvailable() else {
            print("Significant location change monitoring not available")
            return
        }
        
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        print("Background location updates enabled")
    }
    
    func disableBackgroundLocationUpdates() {
        locationManager.allowsBackgroundLocationUpdates = false
        locationManager.pausesLocationUpdatesAutomatically = true
        
        print("Background location updates disabled")
    }
    
    // MARK: - Search State Management
    
    func setSearchInProgress(_ inProgress: Bool) {
        isSearchInProgress = inProgress
        print("LocationManager: Search in progress = \(inProgress)")
        
        // If search finished and we have a location, do reverse geocoding
        if !inProgress, let location = currentLocation {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.reverseGeocode(location: location)
            }
        }
    }
}

// MARK: - Location Info Model

struct LocationInfo {
    let coordinate: CLLocationCoordinate2D
    let city: String?
    let state: String?
    let country: String?
    
    var latitude: Double { coordinate.latitude }
    var longitude: Double { coordinate.longitude }
}

// MARK: - Speed Info Model

struct SpeedInfo {
    let speedMPS: CLLocationSpeed  // meters per second
    let speedMPH: Double          // miles per hour
    let speedKMH: Double          // kilometers per hour
    let isMoving: Bool
    
    var formattedSpeedMPH: String {
        String(format: "%.0f mph", speedMPH)
    }
    
    var formattedSpeedKMH: String {
        String(format: "%.0f km/h", speedKMH)
    }
}

// MARK: - Speed Unit Enum

enum SpeedUnit: CaseIterable {
    case mph  // miles per hour
    case kmh  // kilometers per hour  
    case mps  // meters per second
    
    var displayName: String {
        switch self {
        case .mph: return "mph"
        case .kmh: return "km/h"
        case .mps: return "m/s"
        }
    }
    
    var longDisplayName: String {
        switch self {
        case .mph: return "Miles per hour"
        case .kmh: return "Kilometers per hour"
        case .mps: return "Meters per second"
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let locationDidUpdate = Notification.Name("locationDidUpdate")
    static let locationNameDidUpdate = Notification.Name("locationNameDidUpdate")
    static let speedDidUpdate = Notification.Name("speedDidUpdate")
}