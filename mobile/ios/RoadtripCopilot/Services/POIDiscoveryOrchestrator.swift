//
//  POIDiscoveryOrchestrator.swift
//  RoadtripCopilot
//
//  Orchestrates POI discovery using local Gemma-3N LLM with Google Places API failover
//  Performance targets: <350ms LLM, <1000ms API failover
//  Automotive safety compliance with CarPlay/Android Auto integration
//

import Foundation
import CoreLocation
import Combine
import os.log

/// POI Discovery Orchestrator with hybrid LLM + API approach
@available(iOS 16.0, *)
class POIDiscoveryOrchestrator: ObservableObject {
    
    // MARK: - Properties
    static let shared = POIDiscoveryOrchestrator()
    
    @Published var isProcessing = false
    @Published var lastError: Error?
    @Published var currentStrategy: DiscoveryStrategy = .hybrid
    
    private let gemmaLoader: Gemma3NE2BLoader
    private let placesClient = GooglePlacesAPIClient.shared
    private let categories = POICategories.shared
    private let logger = Logger(subsystem: "com.hmi2.roadtrip-copilot", category: "POIDiscovery")
    
    // Performance monitoring
    private var discoveryStartTime: Date?
    private let llmPerformanceThreshold: TimeInterval = 0.35 // 350ms
    private let apiPerformanceThreshold: TimeInterval = 1.0  // 1000ms
    
    // Cache for recent discoveries
    private var discoveryCache: [String: CachedDiscovery] = [:]
    private let cacheExpirationTime: TimeInterval = 300 // 5 minutes
    
    // Location-specific optimization
    private var lastLocation: CLLocation?
    private let minimumLocationChange: Double = 1000 // 1km
    
    private init() {
        do {
            self.gemmaLoader = try Gemma3NE2BLoader()
            logger.info("🚀 [POI ORCHESTRATOR] Initialized with Gemma-3N LLM")
        } catch {
            fatalError("Failed to initialize Gemma-3N loader: \(error)")
        }
    }
    
    // MARK: - Public Discovery Interface
    
    /// Discover POIs using hybrid LLM + API approach optimized for automotive use
    /// - Parameters:
    ///   - location: Search location (required for safety compliance)
    ///   - category: POI category (optional, uses intelligent categorization if nil)
    ///   - preferredStrategy: Preferred discovery strategy
    ///   - maxResults: Maximum results (capped at 10 for automotive safety)
    /// - Returns: Array of discovered POIs with performance metrics
    func discoverPOIs(
        near location: CLLocation,
        category: String? = nil,
        preferredStrategy: DiscoveryStrategy = .hybrid,
        maxResults: Int = 8
    ) async throws -> POIDiscoveryResult {
        
        logger.info("🔍 [POI ORCHESTRATOR] Starting discovery near \(location.coordinate.latitude), \(location.coordinate.longitude)")
        discoveryStartTime = Date()
        
        isProcessing = true
        defer { 
            isProcessing = false 
            logDiscoveryPerformance()
        }
        
        // Check cache first
        let cacheKey = generateCacheKey(location: location, category: category)
        if let cached = getCachedDiscovery(key: cacheKey) {
            logger.info("📋 [POI ORCHESTRATOR] Using cached results")
            return cached.result
        }
        
        // Determine optimal category if not provided
        let finalCategory = category ?? await determineOptimalCategory(for: location)
        
        // Execute discovery strategy
        let result: POIDiscoveryResult
        
        switch preferredStrategy {
        case .llmFirst:
            result = try await discoverWithLLMFirst(location: location, category: finalCategory, maxResults: maxResults)
        case .apiFirst:
            result = try await discoverWithAPIFirst(location: location, category: finalCategory, maxResults: maxResults)
        case .hybrid:
            result = try await discoverWithHybridApproach(location: location, category: finalCategory, maxResults: maxResults)
        case .llmOnly:
            result = try await discoverWithLLMOnly(location: location, category: finalCategory, maxResults: maxResults)
        }
        
        // Cache successful results
        cacheDiscovery(key: cacheKey, result: result)
        
        // Update location tracking
        lastLocation = location
        
        logger.info("✅ [POI ORCHESTRATOR] Discovery completed: \(result.pois.count) POIs found using \(result.strategyUsed)")
        return result
    }
    
    /// Discover POIs for Lost Lake, Oregon specifically (test case)
    func discoverLostLakeOregonPOIs() async throws -> POIDiscoveryResult {
        let lostLakeLocation = CLLocation(latitude: 45.4979, longitude: -121.8209) // Lost Lake, Oregon
        
        logger.info("🏔️ [POI ORCHESTRATOR] Discovering Lost Lake, Oregon POIs")
        
        return try await discoverPOIs(
            near: lostLakeLocation,
            category: "attraction",
            preferredStrategy: .hybrid,
            maxResults: 10
        )
    }
    
    // MARK: - Discovery Strategies
    
    private func discoverWithLLMFirst(location: CLLocation, category: String, maxResults: Int) async throws -> POIDiscoveryResult {
        let llmStartTime = Date()
        
        do {
            // Try LLM discovery first
            let pois = try await discoverWithLLM(location: location, category: category, maxResults: maxResults)
            let llmTime = Date().timeIntervalSince(llmStartTime)
            
            if !pois.isEmpty {
                return POIDiscoveryResult(
                    pois: pois,
                    strategyUsed: .llmFirst,
                    responseTime: llmTime,
                    fallbackUsed: false
                )
            }
        } catch {
            logger.warning("⚠️ [POI ORCHESTRATOR] LLM discovery failed: \(error.localizedDescription)")
        }
        
        // Fallback to API
        logger.info("🔄 [POI ORCHESTRATOR] Falling back to Google Places API")
        let apiStartTime = Date()
        let pois = try await placesClient.searchPOIs(near: location, category: category, maxResults: maxResults)
        let totalTime = Date().timeIntervalSince(llmStartTime)
        
        return POIDiscoveryResult(
            pois: pois,
            strategyUsed: .apiFirst,
            responseTime: totalTime,
            fallbackUsed: true
        )
    }
    
    private func discoverWithAPIFirst(location: CLLocation, category: String, maxResults: Int) async throws -> POIDiscoveryResult {
        let apiStartTime = Date()
        
        do {
            // Try API discovery first
            let pois = try await placesClient.searchPOIs(near: location, category: category, maxResults: maxResults)
            let apiTime = Date().timeIntervalSince(apiStartTime)
            
            if !pois.isEmpty {
                return POIDiscoveryResult(
                    pois: pois,
                    strategyUsed: .apiFirst,
                    responseTime: apiTime,
                    fallbackUsed: false
                )
            }
        } catch {
            logger.warning("⚠️ [POI ORCHESTRATOR] API discovery failed: \(error.localizedDescription)")
        }
        
        // Fallback to LLM
        logger.info("🔄 [POI ORCHESTRATOR] Falling back to Gemma-3N LLM")
        let llmStartTime = Date()
        let pois = try await discoverWithLLM(location: location, category: category, maxResults: maxResults)
        let totalTime = Date().timeIntervalSince(apiStartTime)
        
        return POIDiscoveryResult(
            pois: pois,
            strategyUsed: .llmFirst,
            responseTime: totalTime,
            fallbackUsed: true
        )
    }
    
    private func discoverWithHybridApproach(location: CLLocation, category: String, maxResults: Int) async throws -> POIDiscoveryResult {
        let startTime = Date()
        
        // Run both approaches in parallel
        async let llmTask: [POIData] = discoverWithLLM(location: location, category: category, maxResults: maxResults / 2)
        async let apiTask: [POIData] = placesClient.searchPOIs(near: location, category: category, maxResults: maxResults / 2)
        
        do {
            let (llmPOIs, apiPOIs) = try await (llmTask, apiTask)
            
            // Merge and deduplicate results
            let mergedPOIs = mergeAndDeduplicatePOIs(llmPOIs: llmPOIs, apiPOIs: apiPOIs, maxResults: maxResults)
            let totalTime = Date().timeIntervalSince(startTime)
            
            return POIDiscoveryResult(
                pois: mergedPOIs,
                strategyUsed: .hybrid,
                responseTime: totalTime,
                fallbackUsed: false
            )
            
        } catch {
            logger.error("❌ [POI ORCHESTRATOR] Hybrid discovery failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func discoverWithLLMOnly(location: CLLocation, category: String, maxResults: Int) async throws -> POIDiscoveryResult {
        let startTime = Date()
        let pois = try await discoverWithLLM(location: location, category: category, maxResults: maxResults)
        let responseTime = Date().timeIntervalSince(startTime)
        
        return POIDiscoveryResult(
            pois: pois,
            strategyUsed: .llmOnly,
            responseTime: responseTime,
            fallbackUsed: false
        )
    }
    
    // MARK: - LLM Discovery Implementation
    
    private func discoverWithLLM(location: CLLocation, category: String, maxResults: Int) async throws -> [POIData] {
        logger.info("🤖 [POI ORCHESTRATOR] Using Gemma-3N for POI discovery")
        
        // Create location context
        let locationName = await getLocationName(for: location)
        let prompt = createLLMDiscoveryPrompt(locationName: locationName, category: category, maxResults: maxResults)
        
        // Get LLM response
        let response = try await gemmaLoader.predict(input: prompt, maxTokens: 500)
        
        // Parse POIs from LLM response
        let pois = parseLLMPOIResponse(response, baseLocation: location, category: category)
        
        logger.info("🤖 [POI ORCHESTRATOR] LLM discovered \(pois.count) POIs")
        return pois
    }
    
    private func createLLMDiscoveryPrompt(locationName: String, category: String, maxResults: Int) -> String {
        return """
        Discover \(maxResults) real points of interest near \(locationName) in the \(category) category.
        
        For each POI, provide:
        - Exact name
        - Brief description
        - Why it's worth visiting
        - Estimated rating (1-5 stars)
        - Distance from center (in km)
        
        Focus on authentic local places, hidden gems, and well-known attractions.
        Provide realistic, specific names and details.
        
        Format each POI as:
        NAME: [exact name]
        DESCRIPTION: [brief description]  
        RATING: [1-5 stars]
        DISTANCE: [distance in km]
        WHY: [reason to visit]
        ---
        """
    }
    
    private func parseLLMPOIResponse(_ response: String, baseLocation: CLLocation, category: String) -> [POIData] {
        let sections = response.components(separatedBy: "---")
        var pois: [POIData] = []
        
        for section in sections {
            if let poi = parseSinglePOI(from: section, baseLocation: baseLocation, category: category) {
                pois.append(poi)
            }
        }
        
        return pois
    }
    
    private func parseSinglePOI(from text: String, baseLocation: CLLocation, category: String) -> POIData? {
        let lines = text.components(separatedBy: "\n")
        var name: String?
        var description: String?
        var rating: Double = 4.0
        var distance: Double = 2.0
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmed.hasPrefix("NAME:") {
                name = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if trimmed.hasPrefix("DESCRIPTION:") {
                description = String(trimmed.dropFirst(12)).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if trimmed.hasPrefix("RATING:") {
                let ratingStr = String(trimmed.dropFirst(7)).trimmingCharacters(in: .whitespacesAndNewlines)
                rating = Double(ratingStr.components(separatedBy: " ").first ?? "4.0") ?? 4.0
            } else if trimmed.hasPrefix("DISTANCE:") {
                let distanceStr = String(trimmed.dropFirst(9)).trimmingCharacters(in: .whitespacesAndNewlines)
                distance = Double(distanceStr.components(separatedBy: " ").first ?? "2.0") ?? 2.0
            }
        }
        
        guard let poiName = name, !poiName.isEmpty else { return nil }
        
        // Generate approximate location based on distance
        let poiLocation = generateApproximateLocation(from: baseLocation, distance: distance * 1000) // Convert km to meters
        
        return POIData(
            name: poiName,
            location: poiLocation,
            category: category,
            rating: rating,
            imageURL: nil, // Could be filled later with image search
            reviewSummary: description,
            distanceFromUser: distance,
            couldEarnRevenue: rating >= 4.0
        )
    }
    
    // MARK: - Helper Methods
    
    private func determineOptimalCategory(for location: CLLocation) async -> String {
        // Use location context to determine best category
        // This could be enhanced with ML-based categorization
        let essentialCategories = categories.getEssentialCategories()
        return essentialCategories.first ?? "attraction"
    }
    
    private func getLocationName(for location: CLLocation) async -> String {
        // Use reverse geocoding to get location name
        // For now, return coordinate-based description
        return "coordinates \(String(format: "%.4f", location.coordinate.latitude)), \(String(format: "%.4f", location.coordinate.longitude))"
    }
    
    private func generateApproximateLocation(from center: CLLocation, distance: Double) -> CLLocation {
        // Generate a location within the specified distance
        let randomBearing = Double.random(in: 0...(2 * Double.pi))
        let randomDistance = Double.random(in: 0...distance)
        
        let earth_radius = 6371000.0 // Earth radius in meters
        let lat1 = center.coordinate.latitude * Double.pi / 180.0
        let lon1 = center.coordinate.longitude * Double.pi / 180.0
        
        let lat2 = asin(sin(lat1) * cos(randomDistance / earth_radius) +
                       cos(lat1) * sin(randomDistance / earth_radius) * cos(randomBearing))
        let lon2 = lon1 + atan2(sin(randomBearing) * sin(randomDistance / earth_radius) * cos(lat1),
                               cos(randomDistance / earth_radius) - sin(lat1) * sin(lat2))
        
        return CLLocation(latitude: lat2 * 180.0 / Double.pi, longitude: lon2 * 180.0 / Double.pi)
    }
    
    private func mergeAndDeduplicatePOIs(llmPOIs: [POIData], apiPOIs: [POIData], maxResults: Int) -> [POIData] {
        var allPOIs: [POIData] = []
        var seenNames = Set<String>()
        
        // Add LLM POIs first (prioritize local knowledge)
        for poi in llmPOIs {
            let normalizedName = poi.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            if !seenNames.contains(normalizedName) {
                allPOIs.append(poi)
                seenNames.insert(normalizedName)
            }
        }
        
        // Add API POIs (avoid duplicates)
        for poi in apiPOIs {
            let normalizedName = poi.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            if !seenNames.contains(normalizedName) {
                allPOIs.append(poi)
                seenNames.insert(normalizedName)
            }
        }
        
        // Sort by rating and distance, then limit results
        return Array(allPOIs.sorted { poi1, poi2 in
            if poi1.rating != poi2.rating {
                return poi1.rating > poi2.rating
            }
            return poi1.distanceFromUser < poi2.distanceFromUser
        }.prefix(maxResults))
    }
    
    // MARK: - Cache Management
    
    private func generateCacheKey(location: CLLocation, category: String?) -> String {
        let lat = String(format: "%.3f", location.coordinate.latitude)
        let lng = String(format: "%.3f", location.coordinate.longitude)
        let cat = category ?? "default"
        return "\(lat)_\(lng)_\(cat)"
    }
    
    private func getCachedDiscovery(key: String) -> CachedDiscovery? {
        guard let cached = discoveryCache[key] else { return nil }
        
        // Check if cache is still valid
        if Date().timeIntervalSince(cached.timestamp) > cacheExpirationTime {
            discoveryCache.removeValue(forKey: key)
            return nil
        }
        
        return cached
    }
    
    private func cacheDiscovery(key: String, result: POIDiscoveryResult) {
        discoveryCache[key] = CachedDiscovery(result: result, timestamp: Date())
        
        // Clean old cache entries
        cleanExpiredCache()
    }
    
    private func cleanExpiredCache() {
        let now = Date()
        discoveryCache = discoveryCache.filter { _, cached in
            now.timeIntervalSince(cached.timestamp) <= cacheExpirationTime
        }
    }
    
    private func logDiscoveryPerformance() {
        guard let startTime = discoveryStartTime else { return }
        let elapsed = Date().timeIntervalSince(startTime)
        
        if elapsed > apiPerformanceThreshold {
            logger.warning("⚠️ [POI ORCHESTRATOR] Slow discovery: \(String(format: "%.0f", elapsed * 1000))ms")
        } else {
            logger.info("✅ [POI ORCHESTRATOR] Discovery completed in \(String(format: "%.0f", elapsed * 1000))ms")
        }
    }
}

// MARK: - Data Models

enum DiscoveryStrategy: String, CaseIterable {
    case hybrid = "hybrid"           // Use both LLM and API, merge results
    case llmFirst = "llm_first"      // Try LLM first, fallback to API
    case apiFirst = "api_first"      // Try API first, fallback to LLM
    case llmOnly = "llm_only"        // Use only LLM (for offline scenarios)
}

struct POIDiscoveryResult {
    let pois: [POIData]
    let strategyUsed: DiscoveryStrategy
    let responseTime: TimeInterval
    let fallbackUsed: Bool
}

struct CachedDiscovery {
    let result: POIDiscoveryResult
    let timestamp: Date
}

// MARK: - Error Handling

enum POIDiscoveryError: LocalizedError {
    case noLLMAvailable
    case noAPIAvailable
    case allStrategiesFailed
    case invalidLocation
    case cacheCorrupted
    
    var errorDescription: String? {
        switch self {
        case .noLLMAvailable:
            return "Local LLM is not available"
        case .noAPIAvailable:
            return "Google Places API is not available"
        case .allStrategiesFailed:
            return "All POI discovery strategies failed"
        case .invalidLocation:
            return "Invalid location provided for POI discovery"
        case .cacheCorrupted:
            return "POI discovery cache is corrupted"
        }
    }
}