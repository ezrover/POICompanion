import Foundation
import UIKit

// MARK: - POI Exclusion Manager
class POIExclusionManager {
    static let shared = POIExclusionManager()
    
    private var exclusions: POIExclusions?
    
    init() {
        loadExclusions()
    }
    
    private func loadExclusions() {
        guard let url = Bundle.main.url(forResource: "poi_exclusions", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(POIExclusions.self, from: data) else {
            print("⚠️ Failed to load POI exclusions")
            return
        }
        
        exclusions = decoded
        print("✅ POI exclusions loaded: \(exclusions?.exclusions.chainRestaurants.count ?? 0) chain restaurants, \(exclusions?.exclusions.chainHotels.count ?? 0) chain hotels excluded")
    }
    
    func shouldExcludePOI(_ poi: POI) -> Bool {
        guard let exclusions = exclusions else { return false }
        
        // Check if it's a gas station
        if exclusions.exclusions.gasStations.contains(where: { poi.name.contains($0) }) {
            print("❌ Excluding gas station: \(poi.name)")
            return true
        }
        
        // Check if it's a chain restaurant
        if exclusions.exclusions.chainRestaurants.contains(where: { poi.name.contains($0) }) {
            print("❌ Excluding chain restaurant: \(poi.name)")
            return true
        }
        
        // Check if it's a chain hotel
        if exclusions.exclusions.chainHotels.contains(where: { poi.name.contains($0) }) {
            print("❌ Excluding chain hotel: \(poi.name)")
            return true
        }
        
        // Check excluded categories
        if let category = poi.category,
           exclusions.exclusions.excludedCategories.contains(category.lowercased()) {
            print("❌ Excluding category: \(category) for \(poi.name)")
            return true
        }
        
        return false
    }
}

// MARK: - Photo Fetching Tool
class FetchPOIPhotoTool: Tool {
    var name: String = "fetch_poi_photo"
    var description: String = "Fetch a photo for a discovered POI from the internet"
    
    func execute(parameters: [String: Any]) async throws -> [String: Any] {
        let startTime = Date()
        
        guard let poiName = parameters["poi_name"] as? String else {
            throw ToolError.invalidParameters
        }
        
        let location = parameters["location"] as? String ?? ""
        
        print("📸 Fetching photo for: \(poiName) at \(location)")
        
        // Simulate photo search and fetch
        let searchQuery = "\(poiName) \(location)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        // Use Unsplash or Pexels API (mock for now)
        let photoUrl = await searchForPhoto(query: searchQuery)
        
        if let photoUrl = photoUrl {
            // Download and cache the photo
            let cachedPath = await downloadAndCachePhoto(url: photoUrl, poiName: poiName)
            
            let executionTime = Date().timeIntervalSince(startTime) * 1000
            
            return [
                "status": "success",
                "poi_name": poiName,
                "photo_url": photoUrl,
                "cached_path": cachedPath ?? "",
                "execution_time_ms": executionTime,
                "source": "unsplash"
            ]
        } else {
            // Fallback to placeholder
            return [
                "status": "no_photo_found",
                "poi_name": poiName,
                "placeholder": true,
                "execution_time_ms": Date().timeIntervalSince(startTime) * 1000
            ]
        }
    }
    
    private func searchForPhoto(query: String) async -> String? {
        // Mock photo URL - in production, use real API
        let mockPhotos = [
            "https://images.unsplash.com/photo-lost-lake-trail",
            "https://images.unsplash.com/photo-mount-hood-forest",
            "https://images.unsplash.com/photo-oregon-nature"
        ]
        
        // Simulate API delay
        try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
        
        return mockPhotos.randomElement()
    }
    
    private func downloadAndCachePhoto(url: String, poiName: String) async -> String? {
        // Create cache directory
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("poi_photos")
        
        if let cacheDir = cacheDir {
            try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
            
            let fileName = "\(poiName.replacingOccurrences(of: " ", with: "_")).jpg"
            let filePath = cacheDir.appendingPathComponent(fileName)
            
            print("💾 Caching photo to: \(filePath.path)")
            
            // Mock cache - in production, actually download
            return filePath.path
        }
        
        return nil
    }
}

// MARK: - Social Media Reviews Tool
class FetchSocialReviewsTool: Tool {
    var name: String = "fetch_social_reviews"
    var description: String = "Fetch social media reviews and mentions for podcast generation"
    
    func execute(parameters: [String: Any]) async throws -> [String: Any] {
        let startTime = Date()
        
        guard let poiName = parameters["poi_name"] as? String else {
            throw ToolError.invalidParameters
        }
        
        let location = parameters["location"] as? String ?? ""
        let sources = parameters["sources"] as? [String] ?? ["tripadvisor", "yelp", "google"]
        
        print("📝 Fetching reviews for: \(poiName) from \(sources.joined(separator: ", "))")
        
        var allReviews: [[String: Any]] = []
        
        for source in sources {
            let reviews = await fetchReviewsFromSource(source: source, poi: poiName, location: location)
            allReviews.append(contentsOf: reviews)
        }
        
        // Sort by rating and recency
        allReviews.sort { (r1, r2) in
            let rating1 = r1["rating"] as? Double ?? 0
            let rating2 = r2["rating"] as? Double ?? 0
            return rating1 > rating2
        }
        
        // Take top 5 reviews for podcast generation
        let topReviews = Array(allReviews.prefix(5))
        
        let executionTime = Date().timeIntervalSince(startTime) * 1000
        
        print("✅ Found \(allReviews.count) reviews, selected top \(topReviews.count) for podcast")
        
        return [
            "status": "success",
            "poi_name": poiName,
            "total_reviews": allReviews.count,
            "selected_reviews": topReviews,
            "sources_checked": sources,
            "execution_time_ms": executionTime,
            "podcast_ready": true,
            "average_rating": calculateAverageRating(reviews: allReviews)
        ]
    }
    
    private func fetchReviewsFromSource(source: String, poi: String, location: String) async -> [[String: Any]] {
        // Simulate API delay
        try? await Task.sleep(nanoseconds: 150_000_000) // 150ms
        
        // Mock reviews - in production, use real APIs
        let mockReviews: [[String: Any]] = [
            [
                "source": source,
                "author": "John D.",
                "rating": 4.5,
                "text": "Amazing views of Mount Hood from Lost Lake. The trail is well-maintained and perfect for families.",
                "date": "2025-08-10",
                "helpful_count": 42
            ],
            [
                "source": source,
                "author": "Sarah M.",
                "rating": 5.0,
                "text": "Lost Lake is a hidden gem! Crystal clear water and the reflection of Mount Hood is breathtaking.",
                "date": "2025-08-05",
                "helpful_count": 78
            ],
            [
                "source": source,
                "author": "Mike R.",
                "rating": 4.0,
                "text": "Great camping spot. Sites are spacious and the lake access is wonderful. Gets busy on weekends.",
                "date": "2025-07-28",
                "helpful_count": 31
            ]
        ]
        
        print("  📊 \(source): Found \(mockReviews.count) reviews")
        
        return mockReviews
    }
    
    private func calculateAverageRating(reviews: [[String: Any]]) -> Double {
        let ratings = reviews.compactMap { $0["rating"] as? Double }
        guard !ratings.isEmpty else { return 0 }
        return ratings.reduce(0, +) / Double(ratings.count)
    }
}

// MARK: - Enhanced Tool Registry
class EnhancedToolRegistry: ToolRegistry {
    
    override init() {
        super.init()
        registerEnhancedTools()
    }
    
    private func registerEnhancedTools() {
        // Register photo fetching tool
        register(FetchPOIPhotoTool())
        
        // Register social reviews tool
        register(FetchSocialReviewsTool())
        
        print("✅ Enhanced tools registered: fetch_poi_photo, fetch_social_reviews")
    }
    
    // Override search_poi to apply exclusions
    override func executeSearchPOI(parameters: [String: Any]) async throws -> [String: Any] {
        let result = try await super.executeSearchPOI(parameters: parameters)
        
        guard var pois = result["pois"] as? [[String: Any]] else {
            return result
        }
        
        // Filter out excluded POIs
        let exclusionManager = POIExclusionManager.shared
        var filteredPOIs: [[String: Any]] = []
        var excludedCount = 0
        
        for poiData in pois {
            let poi = POI(from: poiData)
            if !exclusionManager.shouldExcludePOI(poi) {
                filteredPOIs.append(poiData)
            } else {
                excludedCount += 1
            }
        }
        
        print("🔍 Filtered POIs: \(pois.count) → \(filteredPOIs.count) (excluded \(excludedCount))")
        
        var updatedResult = result
        updatedResult["pois"] = filteredPOIs
        updatedResult["excluded_count"] = excludedCount
        
        return updatedResult
    }
}

// MARK: - Data Models
struct POIExclusions: Codable {
    let exclusions: Exclusions
    let preferences: Preferences
    
    struct Exclusions: Codable {
        let chainRestaurants: [String]
        let chainHotels: [String]
        let gasStations: [String]
        let excludedCategories: [String]
        
        enum CodingKeys: String, CodingKey {
            case chainRestaurants = "chain_restaurants"
            case chainHotels = "chain_hotels"
            case gasStations = "gas_stations"
            case excludedCategories = "excluded_categories"
        }
    }
    
    struct Preferences: Codable {
        let focusOn: [String]
        let photoRequirements: PhotoRequirements
        let reviewSources: [String]
        
        enum CodingKeys: String, CodingKey {
            case focusOn = "focus_on"
            case photoRequirements = "photo_requirements"
            case reviewSources = "review_sources"
        }
    }
    
    struct PhotoRequirements: Codable {
        let minWidth: Int
        let minHeight: Int
        let preferredAspectRatio: String
        let maxFileSizeMb: Int
        let formats: [String]
        
        enum CodingKeys: String, CodingKey {
            case minWidth = "min_width"
            case minHeight = "min_height"
            case preferredAspectRatio = "preferred_aspect_ratio"
            case maxFileSizeMb = "max_file_size_mb"
            case formats
        }
    }
}

struct POI {
    let name: String
    let category: String?
    let location: String?
    let distance: Double?
    
    init(from dictionary: [String: Any]) {
        self.name = dictionary["name"] as? String ?? ""
        self.category = dictionary["category"] as? String
        self.location = dictionary["location"] as? String
        self.distance = dictionary["distance"] as? Double
    }
}

enum ToolError: Error {
    case invalidParameters
    case executionFailed
    case networkError
}