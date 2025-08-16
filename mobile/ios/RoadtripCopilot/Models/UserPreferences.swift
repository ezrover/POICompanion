import Foundation

// MARK: - POI Categories

enum POICategory: String, CaseIterable, Identifiable, Codable {
    case restaurants = "restaurants"
    case gasstations = "gas_stations" 
    case attractions = "attractions"
    case lodging = "lodging"
    case shopping = "shopping"
    case parks = "parks"
    case museums = "museums"
    case entertainment = "entertainment"
    case beaches = "beaches"
    case viewpoints = "viewpoints"
    case historicsites = "historic_sites"
    case wineries = "wineries"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .restaurants: return "Restaurants"
        case .gasstations: return "Gas Stations"
        case .attractions: return "Tourist Attractions"
        case .lodging: return "Hotels & Lodging"
        case .shopping: return "Shopping"
        case .parks: return "Parks & Nature"
        case .museums: return "Museums"
        case .entertainment: return "Entertainment"
        case .beaches: return "Beaches"
        case .viewpoints: return "Scenic Viewpoints"
        case .historicsites: return "Historic Sites"
        case .wineries: return "Wineries & Breweries"
        }
    }
    
    var icon: String {
        switch self {
        case .restaurants: return "fork.knife"
        case .gasstations: return "fuelpump"
        case .attractions: return "camera"
        case .lodging: return "bed.double"
        case .shopping: return "bag"
        case .parks: return "tree"
        case .museums: return "building.columns"
        case .entertainment: return "theatermasks"
        case .beaches: return "beach.umbrella"
        case .viewpoints: return "mountain.2"
        case .historicsites: return "building.2"
        case .wineries: return "wineglass"
        }
    }
    
    var voiceAliases: [String] {
        switch self {
        case .restaurants: return ["restaurants", "food", "dining", "eat"]
        case .gasstations: return ["gas stations", "fuel", "gas", "petrol"]
        case .attractions: return ["attractions", "tourist", "sightseeing", "landmarks"]
        case .lodging: return ["hotels", "lodging", "accommodation", "stay"]
        case .shopping: return ["shopping", "stores", "retail", "mall"]
        case .parks: return ["parks", "nature", "outdoor", "recreation"]
        case .museums: return ["museums", "culture", "art", "history"]
        case .entertainment: return ["entertainment", "fun", "activities", "shows"]
        case .beaches: return ["beaches", "coast", "ocean", "seaside"]
        case .viewpoints: return ["viewpoints", "scenic", "views", "overlooks"]
        case .historicsites: return ["historic sites", "historical", "heritage", "monuments"]
        case .wineries: return ["wineries", "wine", "breweries", "vineyards"]
        }
    }
    
    var description: String {
        switch self {
        case .restaurants: return "Dining and restaurant options"
        case .gasstations: return "Fuel and service stations"
        case .attractions: return "Tourist attractions and landmarks"
        case .lodging: return "Hotels and accommodation"
        case .shopping: return "Shopping and retail locations"
        case .parks: return "Parks and natural areas"
        case .museums: return "Museums and cultural sites"
        case .entertainment: return "Entertainment venues"
        case .beaches: return "Beaches and coastal areas"
        case .viewpoints: return "Scenic viewpoints and vistas"
        case .historicsites: return "Historic sites and monuments"
        case .wineries: return "Wineries and breweries"
        }
    }
}

// MARK: - Distance Unit

enum DistanceUnit: String, CaseIterable {
    case miles = "miles"
    case kilometers = "kilometers"
    
    var shortName: String {
        switch self {
        case .miles: return "mi"
        case .kilometers: return "km"
        }
    }
    
    var displayName: String {
        switch self {
        case .miles: return "Miles"
        case .kilometers: return "Kilometers"
        }
    }
}

// MARK: - User Preferences Model

class UserPreferences: ObservableObject {
    @Published var searchRadius: Double = 5.0 // Default 5 miles/km
    @Published var distanceUnit: DistanceUnit = .miles
    @Published var selectedPOICategories: Set<POICategory> = Set(POICategory.allCases)
    @Published var hasCompletedOnboarding: Bool = false
    
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadPreferences()
    }
    
    // MARK: - Persistence
    
    func savePreferences() {
        userDefaults.set(searchRadius, forKey: "poi_search_radius")
        userDefaults.set(distanceUnit.rawValue, forKey: "distance_unit")
        userDefaults.set(hasCompletedOnboarding, forKey: "has_completed_onboarding")
        
        let categoryStrings = selectedPOICategories.map { $0.rawValue }
        userDefaults.set(categoryStrings, forKey: "selected_poi_categories")
        
        print("User preferences saved: \(searchRadius) \(distanceUnit.shortName), \(selectedPOICategories.count) categories")
    }
    
    private func loadPreferences() {
        searchRadius = userDefaults.double(forKey: "poi_search_radius")
        if searchRadius == 0 { searchRadius = 5.0 } // Default value
        
        if let unitString = userDefaults.string(forKey: "distance_unit"),
           let unit = DistanceUnit(rawValue: unitString) {
            distanceUnit = unit
        }
        
        hasCompletedOnboarding = userDefaults.bool(forKey: "has_completed_onboarding")
        
        if let categoryStrings = userDefaults.array(forKey: "selected_poi_categories") as? [String] {
            selectedPOICategories = Set(categoryStrings.compactMap { POICategory(rawValue: $0) })
        }
        
        // Ensure we have at least some categories selected
        if selectedPOICategories.isEmpty {
            selectedPOICategories = Set(POICategory.allCases)
        }
    }
    
    // MARK: - Validation
    
    var isRadiusValid: Bool {
        return searchRadius >= 1.0 && searchRadius <= 10.0
    }
    
    var hasCategoriesSelected: Bool {
        return !selectedPOICategories.isEmpty
    }
    
    var canProceed: Bool {
        return isRadiusValid && hasCategoriesSelected
    }
    
    // MARK: - Voice Command Processing
    
    func processRadiusVoiceCommand(_ command: String) -> Bool {
        let lowercaseCommand = command.lowercased()
        
        // Extract number from voice command
        let components = lowercaseCommand.components(separatedBy: .whitespaces)
        
        for (index, component) in components.enumerated() {
            if let radius = Double(component) {
                if radius >= 1.0 && radius <= 10.0 {
                    self.searchRadius = radius
                    
                    // Check for unit specification
                    if index + 1 < components.count {
                        let nextWord = components[index + 1]
                        if nextWord.contains("km") || nextWord.contains("kilometer") {
                            self.distanceUnit = .kilometers
                        } else if nextWord.contains("mi") || nextWord.contains("mile") {
                            self.distanceUnit = .miles
                        }
                    }
                    
                    return true
                }
            }
        }
        
        return false
    }
    
    func processCategoryVoiceCommand(_ command: String) -> Set<POICategory> {
        let lowercaseCommand = command.lowercased()
        var recognizedCategories: Set<POICategory> = []
        
        for category in POICategory.allCases {
            for alias in category.voiceAliases {
                if lowercaseCommand.contains(alias) {
                    recognizedCategories.insert(category)
                    break
                }
            }
        }
        
        return recognizedCategories
    }
    
    // MARK: - Helper Methods
    
    func toggleCategory(_ category: POICategory) {
        if selectedPOICategories.contains(category) {
            selectedPOICategories.remove(category)
        } else {
            selectedPOICategories.insert(category)
        }
    }
    
    func selectAllCategories() {
        selectedPOICategories = Set(POICategory.allCases)
    }
    
    func clearAllCategories() {
        selectedPOICategories.removeAll()
    }
    
    var searchRadiusText: String {
        return "\(Int(searchRadius)) \(distanceUnit.shortName)"
    }
}

// MARK: - Region-Based Defaults

extension UserPreferences {
    static func getDefaultDistanceUnit() -> DistanceUnit {
        // Use system locale to determine default unit
        let locale = Locale.current
        if let countryCode = locale.regionCode {
            // Countries that use kilometers
            let metricCountries = ["CA", "GB", "AU", "DE", "FR", "IT", "ES", "NL", "BE", "CH", "AT", "SE", "NO", "DK", "FI"]
            return metricCountries.contains(countryCode) ? .kilometers : .miles
        }
        return .miles // Default to miles
    }
    
    func setRegionBasedDefaults() {
        distanceUnit = Self.getDefaultDistanceUnit()
    }
}