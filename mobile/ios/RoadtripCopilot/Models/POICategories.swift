import Foundation
import SwiftUI

/**
 * POI Categories configuration loaded from shared JSON
 * This ensures platform parity across iOS, CarPlay, Android, and Android Auto
 */
class POICategories {
    
    static let shared = POICategories()
    private var categoriesConfig: POICategoriesConfig?
    
    private init() {
        loadCategories()
    }
    
    private func loadCategories() {
        guard let path = Bundle.main.path(forResource: "poi-categories", ofType: "json"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            print("Failed to load poi-categories.json, using default categories")
            categoriesConfig = getDefaultCategories()
            return
        }
        
        do {
            categoriesConfig = try JSONDecoder().fromJSON(data, POICategoriesConfig.self)
        } catch {
            print("Failed to decode poi-categories.json: \(error)")
            categoriesConfig = getDefaultCategories()
        }
    }
    
    func getCategoryDisplayName(_ categoryId: String) -> String {
        guard let config = categoriesConfig else { return categoryId.capitalized }
        
        // Check main categories first
        for (_, category) in config.categories {
            if category.id.lowercased() == categoryId.lowercased() {
                return category.name
            }
            
            // Check subcategories
            for subcategory in category.subcategories {
                if subcategory.id.lowercased() == categoryId.lowercased() {
                    return subcategory.name
                }
            }
        }
        
        return categoryId.capitalized
    }
    
    func getCategoryIcon(_ categoryId: String) -> String {
        guard let config = categoriesConfig else { return "📍" }
        
        for (_, category) in config.categories {
            if category.id.lowercased() == categoryId.lowercased() {
                return category.icon
            }
            
            for subcategory in category.subcategories {
                if subcategory.id.lowercased() == categoryId.lowercased() {
                    return subcategory.icon
                }
            }
        }
        
        return "📍" // Default POI icon
    }
    
    func getEssentialCategories() -> [String] {
        guard let config = categoriesConfig else { return ["food"] }
        return config.filters.essentialCategories
    }
    
    func getHighDiscoveryValueCategories() -> [String] {
        guard let config = categoriesConfig else { return ["food"] }
        return config.filters.highDiscoveryValue
    }
    
    func getAutomotivePriorityCategories() -> [String] {
        guard let config = categoriesConfig else { return ["restaurant"] }
        return config.filters.automotivePriority
    }
    
    func getAppleMapKitTypes(_ categoryId: String) -> [String] {
        guard let config = categoriesConfig else { return [] }
        
        for (_, category) in config.categories {
            for subcategory in category.subcategories {
                if subcategory.id.lowercased() == categoryId.lowercased() {
                    return [subcategory.mapKitType]
                }
            }
        }
        
        return []
    }
    
    func getDiscoveryWeight(_ categoryId: String) -> Int {
        guard let config = categoriesConfig else { return 35 }
        
        for (_, category) in config.categories {
            if category.id.lowercased() == categoryId.lowercased() ||
               category.subcategories.contains(where: { $0.id.lowercased() == categoryId.lowercased() }) {
                return category.discoveryWeight
            }
        }
        
        return 35 // Default weight
    }
    
    func matchCategoryFromVoiceKeywords(_ query: String) -> String? {
        guard let config = categoriesConfig else { return nil }
        let lowercaseQuery = query.lowercased()
        
        for (categoryType, keywords) in config.voiceRecognitionKeywords {
            if keywords.contains(where: { keyword in lowercaseQuery.contains(keyword) }) {
                // Map voice category to actual category ID
                switch categoryType {
                case "food_related": return "food"
                case "nature_related": return "nature"
                case "accommodation_related": return "accommodation"
                case "services_related": return "services"
                case "attraction_related": return "attractions"
                case "shopping_related": return "shopping"
                case "emergency_related": return "services"
                default: return nil
                }
            }
        }
        
        return nil
    }
    
    func getBaseEarningPotential(_ categoryId: String) -> Int {
        guard let config = categoriesConfig else { return 35 }
        return config.discoveryScoring.baseEarningPotential[categoryId.lowercased()] ?? 35
    }
    
    private func getDefaultCategories() -> POICategoriesConfig {
        // Fallback minimal configuration
        return POICategoriesConfig(
            version: "1.0",
            lastUpdated: "2025-01-11",
            description: "Fallback POI categories",
            categories: [
                "food": POICategory(
                    id: "food",
                    name: "Food & Dining",
                    icon: "🍔",
                    description: "Restaurants and food",
                    priority: 1,
                    discoveryWeight: 45,
                    subcategories: [
                        POISubcategory(
                            id: "restaurant",
                            name: "Restaurants",
                            icon: "🍽️",
                            mapKitType: "restaurant",
                            googlePlaceTypes: ["restaurant"],
                            keywords: ["restaurant"]
                        )
                    ]
                )
            ],
            filters: POIFilters(
                essentialCategories: ["food"],
                highDiscoveryValue: ["food"],
                automotivePriority: ["restaurant"],
                safetyCategories: ["restaurant"],
                contentCreationPriority: ["food"]
            ),
            platformMappings: POIPlatformMappings(
                appleMapkit: [:],
                googlePlaces: [:]
            ),
            discoveryScoring: POIDiscoveryScoring(
                baseEarningPotential: [:],
                uniquenessMultipliers: [:]
            ),
            voiceRecognitionKeywords: [:]
        )
    }
}

// MARK: - Data Models

struct POICategoriesConfig: Codable {
    let version: String
    let lastUpdated: String
    let description: String
    let categories: [String: POICategory]
    let filters: POIFilters
    let platformMappings: POIPlatformMappings
    let discoveryScoring: POIDiscoveryScoring
    let voiceRecognitionKeywords: [String: [String]]
}

struct POICategory: Codable {
    let id: String
    let name: String
    let icon: String
    let description: String
    let priority: Int
    let discoveryWeight: Int
    let subcategories: [POISubcategory]
}

struct POISubcategory: Codable {
    let id: String
    let name: String
    let icon: String
    let mapKitType: String
    let googlePlaceTypes: [String]
    let keywords: [String]
}

struct POIFilters: Codable {
    let essentialCategories: [String]
    let highDiscoveryValue: [String]
    let automotivePriority: [String]
    let safetyCategories: [String]
    let contentCreationPriority: [String]
}

struct POIPlatformMappings: Codable {
    let appleMapkit: [String: [String]]
    let googlePlaces: [String: [String]]
}

struct POIDiscoveryScoring: Codable {
    let baseEarningPotential: [String: Int]
    let uniquenessMultipliers: [String: Double]
}

// MARK: - JSONDecoder Extension

extension JSONDecoder {
    func fromJSON<T: Decodable>(_ data: Data, _ type: T.Type) throws -> T {
        return try decode(type, from: data)
    }
}