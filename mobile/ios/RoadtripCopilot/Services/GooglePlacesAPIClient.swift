//
//  GooglePlacesAPIClient.swift
//  RoadtripCopilot
//
//  Google Places API client for POI discovery failover
//  Performance target: <1000ms response time
//

import Foundation
import CoreLocation
import os.log

/// Google Places API client for POI discovery with automotive safety compliance
@available(iOS 15.0, *)
class GooglePlacesAPIClient: ObservableObject {
    
    // MARK: - Properties
    static let shared = GooglePlacesAPIClient()
    
    @Published var isProcessing = false
    @Published var lastError: Error?
    
    private let apiKey = "YOUR_GOOGLE_PLACES_API_KEY" // Replace with actual API key
    private let baseURL = "https://maps.googleapis.com/maps/api/place"
    private let session: URLSession
    private let logger = Logger(subsystem: "com.hmi2.roadtrip-copilot", category: "GooglePlacesAPI")
    
    // Performance monitoring
    private var requestStartTime: Date?
    private let performanceThreshold: TimeInterval = 1.0 // 1000ms target
    
    // Rate limiting
    private var lastRequestTime: Date?
    private let minimumRequestInterval: TimeInterval = 0.1 // 100ms between requests
    
    private init() {
        // Configure session for automotive use (timeout settings)
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8.0 // 8 second timeout
        config.timeoutIntervalForResource = 10.0 // 10 second resource timeout
        config.waitsForConnectivity = false // Don't wait for connectivity
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Public API
    
    /// Search for POIs near a location with automotive safety optimizations
    /// - Parameters:
    ///   - location: Center point for search
    ///   - category: POI category to search for
    ///   - radius: Search radius in meters (max 50km for safety)
    ///   - maxResults: Maximum number of results (limited to 20 for automotive safety)
    /// - Returns: Array of discovered POIs
    func searchPOIs(
        near location: CLLocation,
        category: String,
        radius: Double = 5000,
        maxResults: Int = 10
    ) async throws -> [POIData] {
        
        logger.info("🔍 [PLACES API] Starting POI search near \(location.coordinate.latitude), \(location.coordinate.longitude)")
        requestStartTime = Date()
        
        // Rate limiting check
        if let lastTime = lastRequestTime,
           Date().timeIntervalSince(lastTime) < minimumRequestInterval {
            try await Task.sleep(nanoseconds: UInt64(minimumRequestInterval * 1_000_000_000))
        }
        lastRequestTime = Date()
        
        isProcessing = true
        defer { 
            isProcessing = false 
            logPerformance()
        }
        
        // Validate inputs for automotive safety
        let safeRadius = min(radius, 50000) // Max 50km for safety
        let safeMaxResults = min(maxResults, 20) // Max 20 results for automotive UI
        
        // Convert category to Google Places type
        let placeType = mapCategoryToGoogleType(category)
        
        // Build request URL
        let endpoint = "\(baseURL)/nearbysearch/json"
        var components = URLComponents(string: endpoint)!
        
        components.queryItems = [
            URLQueryItem(name: "location", value: "\(location.coordinate.latitude),\(location.coordinate.longitude)"),
            URLQueryItem(name: "radius", value: "\(Int(safeRadius))"),
            URLQueryItem(name: "type", value: placeType),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        guard let url = components.url else {
            throw PlacesAPIError.invalidURL
        }
        
        do {
            // Make request with performance monitoring
            let (data, response) = try await session.data(from: url)
            
            // Validate response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PlacesAPIError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                logger.error("❌ [PLACES API] HTTP error: \(httpResponse.statusCode)")
                throw PlacesAPIError.httpError(statusCode: httpResponse.statusCode)
            }
            
            // Parse response
            let placesResponse = try JSONDecoder().decode(GooglePlacesResponse.self, from: data)
            
            // Check API status
            guard placesResponse.status == "OK" || placesResponse.status == "ZERO_RESULTS" else {
                logger.error("❌ [PLACES API] API error: \(placesResponse.status)")
                throw PlacesAPIError.apiError(status: placesResponse.status, message: placesResponse.errorMessage)
            }
            
            // Convert to POIData
            let pois = placesResponse.results.prefix(safeMaxResults).compactMap { place in
                convertPlaceToPOI(place, originalLocation: location, category: category)
            }
            
            logger.info("✅ [PLACES API] Found \(pois.count) POIs for category '\(category)'")
            return pois
            
        } catch {
            logger.error("❌ [PLACES API] Request failed: \(error.localizedDescription)")
            lastError = error
            throw error
        }
    }
    
    /// Get detailed information about a specific POI
    func getPOIDetails(placeId: String) async throws -> PlaceDetails {
        logger.info("📋 [PLACES API] Getting details for place ID: \(placeId)")
        
        let endpoint = "\(baseURL)/details/json"
        var components = URLComponents(string: endpoint)!
        
        components.queryItems = [
            URLQueryItem(name: "place_id", value: placeId),
            URLQueryItem(name: "fields", value: "name,rating,formatted_phone_number,opening_hours,website,reviews,photos"),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        guard let url = components.url else {
            throw PlacesAPIError.invalidURL
        }
        
        let (data, _) = try await session.data(from: url)
        let response = try JSONDecoder().decode(PlaceDetailsResponse.self, from: data)
        
        guard response.status == "OK" else {
            throw PlacesAPIError.apiError(status: response.status, message: response.errorMessage)
        }
        
        return response.result
    }
    
    // MARK: - Helper Methods
    
    private func mapCategoryToGoogleType(_ category: String) -> String {
        // Map POI categories to Google Places types
        let mapping: [String: String] = [
            "restaurant": "restaurant",
            "food": "restaurant",
            "gas_station": "gas_station",
            "lodging": "lodging",
            "hotel": "lodging",
            "attraction": "tourist_attraction",
            "tourist_attraction": "tourist_attraction",
            "park": "park",
            "museum": "museum",
            "shopping": "shopping_mall",
            "hospital": "hospital",
            "pharmacy": "pharmacy",
            "bank": "bank",
            "atm": "atm",
            "church": "church",
            "school": "school"
        ]
        
        return mapping[category.lowercased()] ?? "point_of_interest"
    }
    
    private func convertPlaceToPOI(_ place: GooglePlace, originalLocation: CLLocation, category: String) -> POIData? {
        guard let lat = place.geometry?.location.lat,
              let lng = place.geometry?.location.lng else {
            return nil
        }
        
        let poiLocation = CLLocation(latitude: lat, longitude: lng)
        let distance = originalLocation.distance(from: poiLocation) / 1000.0 // Convert to km
        
        return POIData(
            name: place.name,
            location: poiLocation,
            category: category,
            rating: place.rating ?? 0.0,
            imageURL: place.photos?.first?.photoReference.flatMap { photoRef in
                URL(string: "\(baseURL)/photo?maxwidth=400&photoreference=\(photoRef)&key=\(apiKey)")
            },
            reviewSummary: place.reviews?.first?.text,
            distanceFromUser: distance,
            couldEarnRevenue: place.rating ?? 0.0 >= 4.0 // High-rated places more likely to earn revenue
        )
    }
    
    private func logPerformance() {
        guard let startTime = requestStartTime else { return }
        let elapsed = Date().timeIntervalSince(startTime)
        
        if elapsed > performanceThreshold {
            logger.warning("⚠️ [PLACES API] Slow request: \(String(format: "%.0f", elapsed * 1000))ms (target: \(Int(performanceThreshold * 1000))ms)")
        } else {
            logger.info("✅ [PLACES API] Request completed in \(String(format: "%.0f", elapsed * 1000))ms")
        }
    }
}

// MARK: - Data Models

struct GooglePlacesResponse: Codable {
    let results: [GooglePlace]
    let status: String
    let errorMessage: String?
    
    enum CodingKeys: String, CodingKey {
        case results, status
        case errorMessage = "error_message"
    }
}

struct GooglePlace: Codable {
    let placeId: String
    let name: String
    let rating: Double?
    let priceLevel: Int?
    let vicinity: String?
    let geometry: PlaceGeometry?
    let photos: [PlacePhoto]?
    let reviews: [PlaceReview]?
    
    enum CodingKeys: String, CodingKey {
        case name, rating, vicinity, geometry, photos, reviews
        case placeId = "place_id"
        case priceLevel = "price_level"
    }
}

struct PlaceGeometry: Codable {
    let location: PlaceLocation
}

struct PlaceLocation: Codable {
    let lat: Double
    let lng: Double
}

struct PlacePhoto: Codable {
    let photoReference: String
    let height: Int
    let width: Int
    
    enum CodingKeys: String, CodingKey {
        case height, width
        case photoReference = "photo_reference"
    }
}

struct PlaceReview: Codable {
    let text: String
    let rating: Int
    let authorName: String
    let time: Int
    
    enum CodingKeys: String, CodingKey {
        case text, rating, time
        case authorName = "author_name"
    }
}

// Place Details Models
struct PlaceDetailsResponse: Codable {
    let result: PlaceDetails
    let status: String
    let errorMessage: String?
    
    enum CodingKeys: String, CodingKey {
        case result, status
        case errorMessage = "error_message"
    }
}

struct PlaceDetails: Codable {
    let name: String
    let rating: Double?
    let formattedPhoneNumber: String?
    let website: String?
    let openingHours: OpeningHours?
    let reviews: [PlaceReview]?
    let photos: [PlacePhoto]?
    
    enum CodingKeys: String, CodingKey {
        case name, rating, website, reviews, photos
        case formattedPhoneNumber = "formatted_phone_number"
        case openingHours = "opening_hours"
    }
}

struct OpeningHours: Codable {
    let openNow: Bool
    let weekdayText: [String]?
    
    enum CodingKeys: String, CodingKey {
        case weekdayText = "weekday_text"
        case openNow = "open_now"
    }
}

// MARK: - Error Handling

enum PlacesAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case apiError(status: String, message: String?)
    case rateLimitExceeded
    case noResults
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Google Places API URL"
        case .invalidResponse:
            return "Invalid response from Google Places API"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .apiError(let status, let message):
            return "Google Places API error (\(status)): \(message ?? "Unknown error")"
        case .rateLimitExceeded:
            return "Google Places API rate limit exceeded"
        case .noResults:
            return "No POIs found for the specified criteria"
        }
    }
}