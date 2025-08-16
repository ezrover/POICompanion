import Foundation
import CoreLocation
import ObjectiveC

/// POI ranking engine that prioritizes POIs based on multiple factors
class POIRankingEngine {
    
    // MARK: - Ranking Weights
    private let ratingWeight: Double = 0.3
    private let proximityWeight: Double = 0.25
    private let popularityWeight: Double = 0.2
    private let categoryWeight: Double = 0.15
    private let reviewCountWeight: Double = 0.1
    
    // MARK: - User Preferences
    private var preferredCategories: [String] = []
    private var avoidedCategories: [String] = []
    
    init() {
        loadUserPreferences()
    }
    
    // MARK: - Public Methods
    
    /// Ranks POIs based on multiple factors and user preferences
    func rankPOIs(_ pois: [POI], userLocation: CLLocation) async -> [POI] {
        guard !pois.isEmpty else { return [] }
        
        var rankedPOIs: [(poi: POI, score: Double)] = []
        
        // Calculate max distance for normalization
        let maxDistance = pois.map { poi in
            let poiLocation = CLLocation(latitude: poi.location.latitude,
                                       longitude: poi.location.longitude)
            return userLocation.distance(from: poiLocation)
        }.max() ?? 1.0
        
        // Calculate scores for each POI
        for poi in pois {
            let score = await calculatePOIScore(poi, userLocation: userLocation, maxDistance: maxDistance)
            rankedPOIs.append((poi: poi, score: score))
        }
        
        // Sort by score (highest first)
        rankedPOIs.sort { $0.score > $1.score }
        
        // Return sorted POIs
        let sortedPOIs = rankedPOIs.map { $0.poi }
        
        print("[POIRankingEngine] Ranked \(sortedPOIs.count) POIs")
        return sortedPOIs
    }
    
    /// Updates user preferences based on interactions
    func updateUserPreferences(likedPOI: POI) {
        let category = likedPOI.category.rawValue
        
        // Add to preferred categories if not already present
        if !preferredCategories.contains(category) {
            preferredCategories.append(category)
            saveUserPreferences()
        }
        
        print("[POIRankingEngine] Updated preferences - liked category: \(category)")
    }
    
    /// Updates user preferences for disliked POIs
    func updateUserPreferences(dislikedPOI: POI) {
        let category = dislikedPOI.category.rawValue
        
        // Add to avoided categories if not already present
        if !avoidedCategories.contains(category) {
            avoidedCategories.append(category)
            saveUserPreferences()
        }
        
        print("[POIRankingEngine] Updated preferences - disliked category: \(category)")
    }
    
    // MARK: - Private Methods
    
    private func calculatePOIScore(_ poi: POI, userLocation: CLLocation, maxDistance: Double) async -> Double {
        var totalScore: Double = 0
        
        // 1. Rating Score (0-1)
        let ratingScore = normalizeRating(poi.rating)
        totalScore += ratingScore * ratingWeight
        
        // 2. Proximity Score (0-1, closer is better)
        let proximityScore = calculateProximityScore(poi, userLocation: userLocation, maxDistance: maxDistance)
        totalScore += proximityScore * proximityWeight
        
        // 3. Popularity Score (based on review count)
        let popularityScore = normalizePopularity(poi.reviewCount ?? 0)
        totalScore += popularityScore * popularityWeight
        
        // 4. Category Preference Score (0-1)
        let categoryScore = calculateCategoryScore(poi)
        totalScore += categoryScore * categoryWeight
        
        // 5. Review Count Score (0-1)
        let reviewScore = normalizeReviewCount(poi.reviewCount ?? 0)
        totalScore += reviewScore * reviewCountWeight
        
        // Apply bonus factors
        totalScore = applyBonusFactors(totalScore, poi: poi)
        
        return min(totalScore, 1.0) // Cap at 1.0
    }
    
    private func normalizeRating(_ rating: Double) -> Double {
        // Normalize rating from 0-5 scale to 0-1 scale
        return min(max(rating / 5.0, 0), 1)
    }
    
    private func calculateProximityScore(_ poi: POI, userLocation: CLLocation, maxDistance: Double) -> Double {
        let poiLocation = CLLocation(latitude: poi.location.latitude,
                                   longitude: poi.location.longitude)
        let distance = userLocation.distance(from: poiLocation)
        
        // Inverse proximity - closer locations get higher scores
        return 1.0 - (distance / maxDistance)
    }
    
    private func normalizePopularity(_ reviewCount: Int) -> Double {
        // Logarithmic scale for review count to prevent outliers from dominating
        if reviewCount <= 0 { return 0 }
        
        let logReviews = Foundation.log(Double(reviewCount) + 1)
        let maxLogReviews = Foundation.log(1001) // Assume max of 1000 reviews
        
        return min(logReviews / maxLogReviews, 1.0)
    }
    
    private func calculateCategoryScore(_ poi: POI) -> Double {
        let category = poi.category.rawValue
        
        // Boost preferred categories
        if preferredCategories.contains(category) {
            return 1.0
        }
        
        // Penalize avoided categories
        if avoidedCategories.contains(category) {
            return 0.2
        }
        
        // Default score for neutral categories
        return 0.6
    }
    
    private func normalizeReviewCount(_ reviewCount: Int) -> Double {
        // More reviews generally indicate higher credibility
        switch reviewCount {
        case 0...5:
            return 0.2
        case 6...20:
            return 0.4
        case 21...50:
            return 0.6
        case 51...100:
            return 0.8
        default:
            return 1.0
        }
    }
    
    private func applyBonusFactors(_ baseScore: Double, poi: POI) -> Double {
        var score = baseScore
        
        // Highly rated bonus (4.5+ stars)
        if poi.rating >= 4.5 {
            score += 0.1
        }
        
        // High review count bonus (100+ reviews)
        if (poi.reviewCount ?? 0) >= 100 {
            score += 0.05
        }
        
        // Recent/trending bonus (if available)
        if poi.isRecentlyOpened ?? false {
            score += 0.05
        }
        
        // Photo availability bonus
        if poi.hasPhotos ?? false {
            score += 0.02
        }
        
        return score
    }
    
    // MARK: - Time-based Filtering
    
    /// Filters POIs based on current time and operating hours
    func filterByOperatingHours(_ pois: [POI]) -> [POI] {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentWeekday = calendar.component(.weekday, from: now)
        
        return pois.filter { poi in
            // If no operating hours info, assume open
            guard let operatingHours = poi.operatingHours else { return true }
            
            // Check if open at current time
            return isOpenAt(operatingHours: operatingHours, hour: currentHour, weekday: currentWeekday)
        }
    }
    
    private func isOpenAt(operatingHours: [String: String], hour: Int, weekday: Int) -> Bool {
        // Simplified operating hours check
        // In real implementation, would parse operating hours format
        
        let weekdayNames = ["", "sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
        guard weekday < weekdayNames.count else { return true }
        
        let dayName = weekdayNames[weekday]
        
        // If no info for this day, assume open
        guard let dayHours = operatingHours[dayName] else { return true }
        
        // If closed, return false
        if dayHours.lowercased().contains("closed") {
            return false
        }
        
        // Simplified check - in real implementation would parse actual hours
        return true
    }
    
    // MARK: - Distance-based Filtering
    
    /// Filters POIs by maximum distance
    func filterByDistance(_ pois: [POI], userLocation: CLLocation, maxDistance: CLLocationDistance) -> [POI] {
        return pois.filter { poi in
            let poiLocation = CLLocation(latitude: poi.location.latitude,
                                       longitude: poi.location.longitude)
            let distance = userLocation.distance(from: poiLocation)
            return distance <= maxDistance
        }
    }
    
    // MARK: - Persistence
    
    private func loadUserPreferences() {
        preferredCategories = UserDefaults.standard.stringArray(forKey: "preferredPOICategories") ?? []
        avoidedCategories = UserDefaults.standard.stringArray(forKey: "avoidedPOICategories") ?? []
        
        print("[POIRankingEngine] Loaded preferences - preferred: \(preferredCategories.count), avoided: \(avoidedCategories.count)")
    }
    
    private func saveUserPreferences() {
        UserDefaults.standard.set(preferredCategories, forKey: "preferredPOICategories")
        UserDefaults.standard.set(avoidedCategories, forKey: "avoidedPOICategories")
        
        print("[POIRankingEngine] Saved user preferences")
    }
}

// MARK: - POI Model Extensions

extension POI {
    var isRecentlyOpened: Bool? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.isRecentlyOpened) as? Bool
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.isRecentlyOpened, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var hasPhotos: Bool? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.hasPhotos) as? Bool
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.hasPhotos, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var operatingHours: [String: String]? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.operatingHours) as? [String: String]
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.operatingHours, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var reviewCount: Int? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.reviewCount) as? Int
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.reviewCount, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

private struct AssociatedKeys {
    static var isRecentlyOpened = "isRecentlyOpened"
    static var hasPhotos = "hasPhotos"
    static var operatingHours = "operatingHours"
    static var reviewCount = "reviewCount"
}