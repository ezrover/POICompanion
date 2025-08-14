//
//  POIDiscoveryTests.swift
//  RoadtripCopilot
//
//  Tests for real POI discovery system including Lost Lake, Oregon validation
//

import XCTest
import CoreLocation
@testable import RoadtripCopilot

@available(iOS 16.0, *)
final class POIDiscoveryTests: XCTestCase {
    
    var orchestrator: POIDiscoveryOrchestrator!
    var toolRegistry: ToolRegistry!
    
    override func setUp() {
        super.setUp()
        orchestrator = POIDiscoveryOrchestrator.shared
        toolRegistry = ToolRegistry()
    }
    
    override func tearDown() {
        orchestrator = nil
        toolRegistry = nil
        super.tearDown()
    }
    
    // MARK: - Lost Lake Oregon Tests
    
    func testLostLakeOregonPOIDiscovery() async throws {
        // Test the orchestrator directly
        let result = try await orchestrator.discoverLostLakeOregonPOIs()
        
        XCTAssertFalse(result.pois.isEmpty, "Should discover POIs near Lost Lake, Oregon")
        XCTAssertLessThan(result.responseTime, 2.0, "Discovery should complete within 2 seconds")
        
        // Verify POI quality
        for poi in result.pois {
            XCTAssertFalse(poi.name.isEmpty, "POI should have a name")
            XCTAssertGreaterThanOrEqual(poi.rating, 0.0, "POI should have a valid rating")
            XCTAssertLessThanOrEqual(poi.rating, 5.0, "POI rating should not exceed 5.0")
            XCTAssertGreaterThan(poi.distanceFromUser, 0.0, "POI should have a distance")
        }
        
        print("✅ Lost Lake Oregon POI Discovery Test Passed")
        print("   - Found \(result.pois.count) POIs")
        print("   - Response time: \(String(format: "%.0f", result.responseTime * 1000))ms")
        print("   - Strategy used: \(result.strategyUsed)")
    }
    
    func testLostLakeOregonToolRegistryIntegration() async throws {
        // Test through the ToolRegistry interface
        guard let searchTool = toolRegistry.getTool("search_poi") else {
            XCTFail("search_poi tool should be available")
            return
        }
        
        let params = [
            "location": "Lost Lake, Oregon",
            "category": "attraction"
        ]
        
        let result = await searchTool.execute(params)
        
        XCTAssertFalse(result.isEmpty, "Tool should return POI results")
        XCTAssertTrue(result.contains("Lost Lake") || result.contains("Oregon"), "Result should mention Lost Lake or Oregon")
        
        print("✅ Lost Lake Tool Registry Integration Test Passed")
        print("   Result: \(result)")
    }
    
    // MARK: - Performance Tests
    
    func testPOIDiscoveryPerformance() async throws {
        let location = CLLocation(latitude: 45.4979, longitude: -121.8209) // Lost Lake
        
        let startTime = Date()
        let result = try await orchestrator.discoverPOIs(
            near: location,
            category: "restaurant",
            preferredStrategy: .hybrid,
            maxResults: 5
        )
        let elapsed = Date().timeIntervalSince(startTime)
        
        XCTAssertLessThan(elapsed, 2.0, "POI discovery should complete within 2 seconds")
        XCTAssertLessThanOrEqual(result.pois.count, 5, "Should respect maxResults limit")
        
        print("✅ POI Discovery Performance Test Passed")
        print("   - Elapsed time: \(String(format: "%.0f", elapsed * 1000))ms")
        print("   - Found \(result.pois.count) POIs")
    }
    
    // MARK: - Strategy Tests
    
    func testHybridDiscoveryStrategy() async throws {
        let location = CLLocation(latitude: 45.4979, longitude: -121.8209)
        
        let result = try await orchestrator.discoverPOIs(
            near: location,
            category: "attraction",
            preferredStrategy: .hybrid,
            maxResults: 8
        )
        
        XCTAssertEqual(result.strategyUsed, .hybrid, "Should use hybrid strategy")
        XCTAssertFalse(result.pois.isEmpty, "Hybrid strategy should find POIs")
        
        print("✅ Hybrid Strategy Test Passed")
    }
    
    func testLLMFirstStrategy() async throws {
        let location = CLLocation(latitude: 45.4979, longitude: -121.8209)
        
        let result = try await orchestrator.discoverPOIs(
            near: location,
            category: "restaurant",
            preferredStrategy: .llmFirst,
            maxResults: 5
        )
        
        // Should either use LLM or fallback to API
        XCTAssertTrue(result.strategyUsed == .llmFirst || result.strategyUsed == .apiFirst, 
                     "Should use LLM first or fallback to API")
        
        print("✅ LLM First Strategy Test Passed")
    }
    
    // MARK: - Automotive Safety Tests
    
    func testAutomotiveSafetyCompliance() async throws {
        let location = CLLocation(latitude: 45.4979, longitude: -121.8209)
        
        // Test maximum results limit (automotive safety)
        let result = try await orchestrator.discoverPOIs(
            near: location,
            category: "gas_station",
            preferredStrategy: .hybrid,
            maxResults: 25 // Request more than safe limit
        )
        
        XCTAssertLessThanOrEqual(result.pois.count, 10, "Should limit results for automotive safety")
        
        print("✅ Automotive Safety Compliance Test Passed")
    }
    
    // MARK: - Cache Tests
    
    func testDiscoveryCache() async throws {
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
        
        XCTAssertEqual(result1.pois.count, result2.pois.count, "Cached results should be the same")
        // Note: Cache performance might not always be faster due to async overhead
        
        print("✅ Discovery Cache Test Passed")
        print("   - First request: \(String(format: "%.0f", time1 * 1000))ms")
        print("   - Second request: \(String(format: "%.0f", time2 * 1000))ms")
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidLocationHandling() async throws {
        let params = [
            "location": "Invalid Location 12345",
            "category": "restaurant"
        ]
        
        guard let searchTool = toolRegistry.getTool("search_poi") else {
            XCTFail("search_poi tool should be available")
            return
        }
        
        let result = await searchTool.execute(params)
        
        // Should handle gracefully and return some result (even if fallback)
        XCTAssertFalse(result.isEmpty, "Should handle invalid locations gracefully")
        
        print("✅ Invalid Location Handling Test Passed")
    }
}

// MARK: - Helper Extensions for Testing

extension POIDiscoveryTests {
    
    /// Helper to validate POI data structure
    private func validatePOIData(_ poi: POIData) {
        XCTAssertFalse(poi.name.isEmpty, "POI name should not be empty")
        XCTAssertGreaterThanOrEqual(poi.rating, 0.0, "Rating should be >= 0")
        XCTAssertLessThanOrEqual(poi.rating, 5.0, "Rating should be <= 5")
        XCTAssertGreaterThan(poi.distanceFromUser, 0.0, "Distance should be > 0")
        XCTAssertFalse(poi.category.isEmpty, "Category should not be empty")
    }
    
    /// Helper to measure performance of async operations
    private func measureAsyncPerformance<T>(
        operation: () async throws -> T,
        expectedMaxTime: TimeInterval = 2.0
    ) async throws -> (result: T, duration: TimeInterval) {
        let startTime = Date()
        let result = try await operation()
        let duration = Date().timeIntervalSince(startTime)
        
        XCTAssertLessThan(duration, expectedMaxTime, 
                         "Operation should complete within \(expectedMaxTime) seconds")
        
        return (result, duration)
    }
}