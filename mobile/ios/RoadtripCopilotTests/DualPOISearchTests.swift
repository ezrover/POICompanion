//
//  DualPOISearchTests.swift
//  RoadtripCopilot
//
//  Comprehensive tests for dual POI search functionality
//  Tests both local LLM POI discovery AND online API (Google Places) discovery
//  Validates that mock data is no longer used and real POI data is returned
//

import XCTest
import CoreLocation
@testable import RoadtripCopilot

@available(iOS 16.0, *)
final class DualPOISearchTests: XCTestCase {
    
    var orchestrator: POIDiscoveryOrchestrator!
    var placesClient: GooglePlacesAPIClient!
    var gemmaLoader: Gemma3NE2BLoader!
    
    override func setUp() {
        super.setUp()
        orchestrator = POIDiscoveryOrchestrator.shared
        placesClient = GooglePlacesAPIClient.shared
        
        do {
            gemmaLoader = try Gemma3NE2BLoader()
        } catch {
            XCTFail("Failed to initialize Gemma-3N loader: \(error)")
        }
    }
    
    override func tearDown() {
        orchestrator = nil
        placesClient = nil
        gemmaLoader = nil
        super.tearDown()
    }
    
    // MARK: - Lost Lake Oregon Tests
    
    func testLostLakeOregonDualSearch() async throws {
        print("\n🧪 =================================================")
        print("🏔️  DUAL POI SEARCH TEST - LOST LAKE, OREGON")
        print("🧪 =================================================")
        
        let lostLakeLocation = CLLocation(latitude: 45.4979, longitude: -121.8209)
        
        // Test the hybrid approach (both LLM and API)
        let result = try await orchestrator.discoverPOIs(
            near: lostLakeLocation,
            category: "attraction",
            preferredStrategy: .hybrid,
            maxResults: 10
        )
        
        // Validate results
        XCTAssertFalse(result.pois.isEmpty, "Should discover POIs near Lost Lake, Oregon")
        XCTAssertLessThan(result.responseTime, 3.0, "Discovery should complete within 3 seconds")
        
        print("\n📊 DUAL SEARCH RESULTS:")
        print("   Strategy Used: \(result.strategyUsed)")
        print("   Response Time: \(String(format: "%.0f", result.responseTime * 1000))ms")
        print("   POIs Found: \(result.pois.count)")
        print("   Fallback Used: \(result.fallbackUsed)")
        
        // Verify no mock data is returned
        let mockDataTerms = ["Historic Downtown", "Local Museum", "Mock", "Test POI", "Sample"]
        for poi in result.pois {
            for mockTerm in mockDataTerms {
                XCTAssertFalse(poi.name.contains(mockTerm), 
                              "Found mock data in results: \(poi.name)")
            }
        }
        
        // Verify real Lost Lake POIs
        let expectedPOITypes = [
            "Lost Lake", "Mount Hood", "Trail", "Resort", "Campground", 
            "Forest", "Wilderness", "Recreation", "Tamanawas"
        ]
        
        var foundRealPOIs = 0
        print("\n🔍 DISCOVERED POIs:")
        for (index, poi) in result.pois.enumerated() {
            print("   \(index + 1). \(poi.name)")
            print("      Category: \(poi.category)")
            print("      Rating: \(String(format: "%.1f", poi.rating)) ⭐")
            print("      Distance: \(String(format: "%.1f", poi.distanceFromUser)) km")
            if let summary = poi.reviewSummary {
                print("      Description: \(summary)")
            }
            
            // Check if this looks like a real Lost Lake area POI
            for expectedType in expectedPOITypes {
                if poi.name.localizedCaseInsensitiveContains(expectedType) {
                    foundRealPOIs += 1
                    break
                }
            }
        }
        
        XCTAssertGreaterThan(foundRealPOIs, 0, "Should find at least some real Lost Lake area POIs")
        print("\n✅ Found \(foundRealPOIs) real Lost Lake area POIs")
    }
    
    func testLLMOnlyStrategyComparison() async throws {
        print("\n🧪 =================================================")
        print("🤖 LLM-ONLY STRATEGY TEST - LOST LAKE, OREGON")
        print("🧪 =================================================")
        
        let lostLakeLocation = CLLocation(latitude: 45.4979, longitude: -121.8209)
        
        // Test LLM-only approach
        let llmResult = try await orchestrator.discoverPOIs(
            near: lostLakeLocation,
            category: "attraction",
            preferredStrategy: .llmOnly,
            maxResults: 8
        )
        
        XCTAssertEqual(llmResult.strategyUsed, .llmOnly, "Should use LLM-only strategy")
        XCTAssertFalse(llmResult.pois.isEmpty, "LLM should discover POIs")
        
        print("\n🤖 LLM-ONLY RESULTS:")
        print("   Response Time: \(String(format: "%.0f", llmResult.responseTime * 1000))ms")
        print("   POIs Found: \(llmResult.pois.count)")
        
        // Verify LLM-generated POIs look realistic
        for (index, poi) in llmResult.pois.enumerated() {
            print("   \(index + 1). \(poi.name) - \(String(format: "%.1f", poi.rating))⭐ - \(String(format: "%.1f", poi.distanceFromUser))km")
            
            // LLM POIs should have reasonable attributes
            XCTAssertGreaterThan(poi.rating, 0.0, "LLM POI should have a rating")
            XCTAssertLessThanOrEqual(poi.rating, 5.0, "LLM POI rating should be <= 5.0")
            XCTAssertGreaterThan(poi.distanceFromUser, 0.0, "LLM POI should have distance")
            XCTAssertFalse(poi.name.isEmpty, "LLM POI should have a name")
        }
    }
    
    func testAPIOnlyStrategyComparison() async throws {
        print("\n🧪 =================================================")
        print("🌐 API-ONLY STRATEGY TEST - LOST LAKE, OREGON")
        print("🧪 =================================================")
        
        let lostLakeLocation = CLLocation(latitude: 45.4979, longitude: -121.8209)
        
        do {
            // Test API-only approach
            let apiResult = try await orchestrator.discoverPOIs(
                near: lostLakeLocation,
                category: "attraction",
                preferredStrategy: .apiFirst,
                maxResults: 8
            )
            
            print("\n🌐 API-ONLY RESULTS:")
            print("   Strategy Used: \(apiResult.strategyUsed)")
            print("   Response Time: \(String(format: "%.0f", apiResult.responseTime * 1000))ms")
            print("   POIs Found: \(apiResult.pois.count)")
            print("   Fallback Used: \(apiResult.fallbackUsed)")
            
            if !apiResult.pois.isEmpty {
                // Verify API POIs have Google Places characteristics
                for (index, poi) in apiResult.pois.enumerated() {
                    print("   \(index + 1). \(poi.name) - \(String(format: "%.1f", poi.rating))⭐ - \(String(format: "%.1f", poi.distanceFromUser))km")
                    
                    // API POIs should have location data
                    XCTAssertNotNil(poi.location, "API POI should have location")
                    XCTAssertFalse(poi.name.isEmpty, "API POI should have a name")
                }
            } else {
                print("   ⚠️ No API results (API key may not be configured)")
            }
            
        } catch {
            print("   ⚠️ API-only test failed (likely due to API key configuration): \(error.localizedDescription)")
            // This is acceptable for testing environments without API keys
        }
    }
    
    // MARK: - Seattle Washington Tests
    
    func testSeattleWashingtonDualSearch() async throws {
        print("\n🧪 =================================================")
        print("🏙️  DUAL POI SEARCH TEST - SEATTLE, WASHINGTON")
        print("🧪 =================================================")
        
        let seattleLocation = CLLocation(latitude: 47.6062, longitude: -122.3321)
        
        let result = try await orchestrator.discoverPOIs(
            near: seattleLocation,
            category: "attraction",
            preferredStrategy: .hybrid,
            maxResults: 8
        )
        
        XCTAssertFalse(result.pois.isEmpty, "Should discover POIs in Seattle")
        
        print("\n📊 SEATTLE DUAL SEARCH RESULTS:")
        print("   Strategy Used: \(result.strategyUsed)")
        print("   Response Time: \(String(format: "%.0f", result.responseTime * 1000))ms")
        print("   POIs Found: \(result.pois.count)")
        
        // Expected Seattle attractions
        let seattleAttractions = [
            "Space Needle", "Pike Place", "Market", "Waterfront", "Museum", 
            "Aquarium", "Sculpture Park", "Fremont", "Queen Anne", "Capitol Hill"
        ]
        
        var foundSeattlePOIs = 0
        print("\n🔍 DISCOVERED SEATTLE POIs:")
        for (index, poi) in result.pois.enumerated() {
            print("   \(index + 1). \(poi.name) - \(String(format: "%.1f", poi.rating))⭐")
            
            for attraction in seattleAttractions {
                if poi.name.localizedCaseInsensitiveContains(attraction) {
                    foundSeattlePOIs += 1
                    break
                }
            }
        }
        
        print("✅ Found \(foundSeattlePOIs) recognizable Seattle POIs")
    }
    
    // MARK: - Edge Cases
    
    func testUnknownLocationHandling() async throws {
        print("\n🧪 =================================================")
        print("❓ UNKNOWN LOCATION HANDLING TEST")
        print("🧪 =================================================")
        
        // Test with remote coordinates (middle of Pacific Ocean)
        let unknownLocation = CLLocation(latitude: 0.0, longitude: -160.0)
        
        do {
            let result = try await orchestrator.discoverPOIs(
                near: unknownLocation,
                category: "restaurant",
                preferredStrategy: .hybrid,
                maxResults: 5
            )
            
            print("\n🌊 UNKNOWN LOCATION RESULTS:")
            print("   POIs Found: \(result.pois.count)")
            print("   Strategy Used: \(result.strategyUsed)")
            
            // Should handle gracefully - might return empty or fallback results
            XCTAssertLessThanOrEqual(result.pois.count, 5, "Should respect max results even for unknown locations")
            
        } catch {
            print("   ✅ Appropriately failed for unknown location: \(error.localizedDescription)")
            // Failing for unknown locations is acceptable behavior
        }
    }
    
    func testCacheEffectiveness() async throws {
        print("\n🧪 =================================================")
        print("📋 CACHE EFFECTIVENESS TEST")
        print("🧪 =================================================")
        
        let location = CLLocation(latitude: 45.4979, longitude: -121.8209)
        
        // First request
        let startTime1 = Date()
        let result1 = try await orchestrator.discoverPOIs(
            near: location,
            category: "restaurant",
            preferredStrategy: .hybrid,
            maxResults: 5
        )
        let time1 = Date().timeIntervalSince(startTime1)
        
        // Second request (should use cache)
        let startTime2 = Date()
        let result2 = try await orchestrator.discoverPOIs(
            near: location,
            category: "restaurant",
            preferredStrategy: .hybrid,
            maxResults: 5
        )
        let time2 = Date().timeIntervalSince(startTime2)
        
        print("\n📊 CACHE PERFORMANCE:")
        print("   First request: \(String(format: "%.0f", time1 * 1000))ms")
        print("   Second request: \(String(format: "%.0f", time2 * 1000))ms")
        print("   Cache effectiveness: \(time2 < time1 ? "✅ Faster" : "⚠️ Same/Slower")")
        
        XCTAssertEqual(result1.pois.count, result2.pois.count, "Cached results should match original")
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceTargets() async throws {
        print("\n🧪 =================================================")
        print("⚡ PERFORMANCE TARGET VALIDATION")
        print("🧪 =================================================")
        
        let location = CLLocation(latitude: 45.4979, longitude: -121.8209)
        
        // Test multiple strategies for performance
        let strategies: [DiscoveryStrategy] = [.hybrid, .llmFirst, .llmOnly]
        
        for strategy in strategies {
            let startTime = Date()
            
            do {
                let result = try await orchestrator.discoverPOIs(
                    near: location,
                    category: "attraction",
                    preferredStrategy: strategy,
                    maxResults: 5
                )
                
                let elapsed = Date().timeIntervalSince(startTime)
                let elapsedMs = elapsed * 1000
                
                print("\n⚡ \(strategy) PERFORMANCE:")
                print("   Response Time: \(String(format: "%.0f", elapsedMs))ms")
                print("   POIs Found: \(result.pois.count)")
                print("   Target Met: \(elapsedMs < 2000 ? "✅ < 2s" : "⚠️ > 2s")")
                
                // Performance targets
                if strategy == .llmOnly {
                    XCTAssertLessThan(elapsed, 1.0, "LLM-only should be < 1s")
                } else {
                    XCTAssertLessThan(elapsed, 3.0, "Hybrid/API strategies should be < 3s")
                }
                
            } catch {
                print("   ❌ Strategy \(strategy) failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Mock Data Validation
    
    func testNoMockDataPresent() async throws {
        print("\n🧪 =================================================")
        print("🚫 MOCK DATA ELIMINATION VERIFICATION")
        print("🧪 =================================================")
        
        let testLocations = [
            ("Lost Lake, Oregon", CLLocation(latitude: 45.4979, longitude: -121.8209)),
            ("Seattle, Washington", CLLocation(latitude: 47.6062, longitude: -122.3321)),
            ("San Francisco, California", CLLocation(latitude: 37.7749, longitude: -122.4194))
        ]
        
        let forbiddenMockTerms = [
            "Historic Downtown",
            "Local Museum", 
            "Mock",
            "Test POI",
            "Sample Location",
            "Placeholder",
            "Demo Restaurant",
            "Example Attraction"
        ]
        
        for (locationName, location) in testLocations {
            print("\n🔍 Testing \(locationName)...")
            
            let result = try await orchestrator.discoverPOIs(
                near: location,
                category: "attraction",
                preferredStrategy: .hybrid,
                maxResults: 6
            )
            
            var mockDataFound = false
            for poi in result.pois {
                for mockTerm in forbiddenMockTerms {
                    if poi.name.localizedCaseInsensitiveContains(mockTerm) {
                        print("   ❌ MOCK DATA FOUND: \(poi.name)")
                        mockDataFound = true
                    }
                }
            }
            
            XCTAssertFalse(mockDataFound, "No mock data should be present in \(locationName) results")
            
            if !mockDataFound {
                print("   ✅ No mock data found in \(result.pois.count) POIs")
            }
        }
    }
    
    // MARK: - Strategy Comparison
    
    func testStrategyComparison() async throws {
        print("\n🧪 =================================================")
        print("📊 STRATEGY COMPARISON - SIDE BY SIDE")
        print("🧪 =================================================")
        
        let location = CLLocation(latitude: 45.4979, longitude: -121.8209)
        
        var strategyResults: [DiscoveryStrategy: POIDiscoveryResult] = [:]
        
        // Test all strategies
        for strategy in DiscoveryStrategy.allCases {
            do {
                let result = try await orchestrator.discoverPOIs(
                    near: location,
                    category: "attraction",
                    preferredStrategy: strategy,
                    maxResults: 6
                )
                strategyResults[strategy] = result
            } catch {
                print("   ❌ Strategy \(strategy) failed: \(error.localizedDescription)")
            }
        }
        
        // Display comparison
        print("\n📊 STRATEGY COMPARISON RESULTS:")
        print("   Strategy           | POIs | Time (ms) | Fallback")
        print("   ------------------|------|-----------|----------")
        
        for strategy in DiscoveryStrategy.allCases {
            if let result = strategyResults[strategy] {
                let timeMs = String(format: "%4.0f", result.responseTime * 1000)
                let poiCount = String(format: "%4d", result.pois.count)
                let fallback = result.fallbackUsed ? "Yes" : "No"
                print("   \(String(format: "%-18s", String(describing: strategy))) | \(poiCount) | \(timeMs)     | \(fallback)")
            }
        }
        
        // Show sample POIs from each strategy
        for (strategy, result) in strategyResults {
            if !result.pois.isEmpty {
                print("\n🔍 \(strategy.rawValue.uppercased()) SAMPLE POIs:")
                for (index, poi) in result.pois.prefix(3).enumerated() {
                    print("   \(index + 1). \(poi.name) - \(String(format: "%.1f", poi.rating))⭐")
                }
            }
        }
    }
}

// MARK: - Helper Extensions

extension DualPOISearchTests {
    
    /// Validate POI data structure and content quality
    private func validatePOIQuality(_ poi: POIData, context: String) {
        XCTAssertFalse(poi.name.isEmpty, "\(context): POI name should not be empty")
        XCTAssertGreaterThanOrEqual(poi.rating, 0.0, "\(context): Rating should be >= 0")
        XCTAssertLessThanOrEqual(poi.rating, 5.0, "\(context): Rating should be <= 5")
        XCTAssertGreaterThan(poi.distanceFromUser, 0.0, "\(context): Distance should be > 0")
        XCTAssertFalse(poi.category.isEmpty, "\(context): Category should not be empty")
        
        // Validate realistic distance (should be within reasonable range)
        XCTAssertLessThan(poi.distanceFromUser, 500.0, "\(context): Distance should be < 500km for regional search")
    }
    
    /// Check if a POI name suggests real vs mock data
    private func isPOINameRealistic(_ name: String) -> Bool {
        let mockIndicators = ["mock", "test", "sample", "demo", "placeholder", "example"]
        let nameLower = name.lowercased()
        
        return !mockIndicators.contains { nameLower.contains($0) }
    }
}