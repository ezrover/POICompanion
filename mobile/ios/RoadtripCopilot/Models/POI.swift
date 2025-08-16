import Foundation
import CoreLocation
import MapKit

/// Point of Interest model for Auto Discover feature
struct POI: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let location: CLLocationCoordinate2D
    let category: POICategory
    let rating: Double
    let imageURL: URL?
    let phoneNumber: String?
    let website: String?
    let address: String?
    
    // Auto Discover specific properties
    var distance: CLLocationDistance?
    
    init(id: String = UUID().uuidString,
         name: String,
         description: String,
         location: CLLocationCoordinate2D,
         category: POICategory,
         rating: Double = 0.0,
         imageURL: URL? = nil,
         phoneNumber: String? = nil,
         website: String? = nil,
         address: String? = nil,
         distance: CLLocationDistance? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.location = location
        self.category = category
        self.rating = rating
        self.imageURL = imageURL
        self.phoneNumber = phoneNumber
        self.website = website
        self.address = address
        self.distance = distance
    }
    
    // MARK: - Codable Implementation
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, category, rating
        case imageURL, phoneNumber, website, address, distance
        case latitude, longitude
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        category = try container.decode(POICategory.self, forKey: .category)
        rating = try container.decode(Double.self, forKey: .rating)
        imageURL = try container.decodeIfPresent(URL.self, forKey: .imageURL)
        phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
        website = try container.decodeIfPresent(String.self, forKey: .website)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        distance = try container.decodeIfPresent(CLLocationDistance.self, forKey: .distance)
        
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(category, forKey: .category)
        try container.encode(rating, forKey: .rating)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encodeIfPresent(phoneNumber, forKey: .phoneNumber)
        try container.encodeIfPresent(website, forKey: .website)
        try container.encodeIfPresent(address, forKey: .address)
        try container.encodeIfPresent(distance, forKey: .distance)
        try container.encode(location.latitude, forKey: .latitude)
        try container.encode(location.longitude, forKey: .longitude)
    }
    
    // MARK: - Equatable Implementation
    
    static func == (lhs: POI, rhs: POI) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MARK: - Computed Properties
    
    /// Formatted distance string
    var formattedDistance: String {
        guard let distance = distance else { return "Unknown distance" }
        
        let distanceInMiles = distance * 0.000621371
        
        if distanceInMiles < 0.1 {
            return "< 0.1 mi"
        } else if distanceInMiles < 1.0 {
            return String(format: "%.1f mi", distanceInMiles)
        } else {
            return String(format: "%.0f mi", distanceInMiles)
        }
    }
    
    /// Formatted rating string
    var formattedRating: String {
        if rating > 0 {
            return String(format: "%.1f ★", rating)
        } else {
            return "No rating"
        }
    }
    
    /// Category icon
    var categoryIcon: String {
        return category.icon
    }
    
    /// Category display name
    var categoryName: String {
        return category.displayName
    }
}

// MARK: - MapKit Integration

extension POI {
    /// Converts POI to MKMapItem for navigation
    var mapItem: MKMapItem {
        let placemark = MKPlacemark(coordinate: location)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = name
        mapItem.phoneNumber = phoneNumber
        mapItem.url = website
        return mapItem
    }
    
    /// Creates CLLocation from POI coordinates
    var clLocation: CLLocation {
        return CLLocation(latitude: location.latitude, longitude: location.longitude)
    }
}

// MARK: - Auto Discover Extensions

extension POI {
    /// Updates distance from a given location
    mutating func updateDistance(from location: CLLocation) {
        let poiLocation = CLLocation(latitude: self.location.latitude, longitude: self.location.longitude)
        self.distance = location.distance(from: poiLocation)
    }
    
    /// Creates POI from Google Places API response
    static func fromGooglePlace(place: [String: Any], location: CLLocationCoordinate2D) -> POI? {
        guard let name = place["name"] as? String,
              let geometry = place["geometry"] as? [String: Any],
              let poiLocation = geometry["location"] as? [String: Double],
              let latitude = poiLocation["lat"],
              let longitude = poiLocation["lng"] else {
            return nil
        }
        
        let description = place["formatted_address"] as? String ?? ""
        let rating = place["rating"] as? Double ?? 0.0
        let phoneNumber = place["formatted_phone_number"] as? String
        let website = place["website"] as? String
        let address = place["formatted_address"] as? String
        
        // Determine category from Google Places types
        let types = place["types"] as? [String] ?? []
        let category = mapGoogleTypesToCategory(types)
        
        // Get photo URL if available
        var imageURL: URL?
        if let photos = place["photos"] as? [[String: Any]],
           let firstPhoto = photos.first,
           let photoReference = firstPhoto["photo_reference"] as? String {
            // In a full implementation, this would construct the Google Places Photo API URL
            imageURL = URL(string: "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=\(photoReference)")
        }
        
        let poiCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        return POI(
            name: name,
            description: description,
            location: poiCoordinate,
            category: category,
            rating: rating,
            imageURL: imageURL,
            phoneNumber: phoneNumber,
            website: website.flatMap { URL(string: $0)?.absoluteString },
            address: address
        )
    }
    
    /// Maps Google Places types to POICategory
    private static func mapGoogleTypesToCategory(_ types: [String]) -> POICategory {
        // Priority mapping based on most specific types first
        for type in types {
            switch type.lowercased() {
            case "restaurant", "food", "meal_takeaway", "meal_delivery":
                return .restaurants
            case "gas_station":
                return .gasstations
            case "tourist_attraction", "amusement_park", "zoo":
                return .attractions
            case "lodging", "rv_park":
                return .lodging
            case "shopping_mall", "store", "clothing_store":
                return .shopping
            case "park", "national_park", "campground":
                return .parks
            case "museum":
                return .museums
            case "movie_theater", "bowling_alley", "casino":
                return .entertainment
            case "natural_feature" where types.contains("beach"):
                return .beaches
            case "scenic_overlook", "natural_feature":
                return .viewpoints
            case "cemetery", "church", "synagogue", "mosque":
                return .historicsites
            case "liquor_store" where types.contains("establishment"):
                return .wineries
            default:
                continue
            }
        }
        
        // Default to attractions if no specific mapping found
        return .attractions
    }
}

// MARK: - Sample Data for Testing

extension POI {
    static let samplePOIs: [POI] = [
        POI(
            name: "Lost Lake",
            description: "A pristine mountain lake surrounded by old-growth forest, perfect for hiking and photography.",
            location: CLLocationCoordinate2D(latitude: 45.4968, longitude: -121.8197),
            category: .parks,
            rating: 4.8,
            imageURL: URL(string: "https://example.com/lost-lake.jpg"),
            address: "Lost Lake Road, Hood River, OR 97041"
        ),
        POI(
            name: "Multnomah Falls",
            description: "Oregon's most visited natural recreation site, featuring a spectacular 620-foot waterfall.",
            location: CLLocationCoordinate2D(latitude: 45.5762, longitude: -122.1158),
            category: .attractions,
            rating: 4.6,
            imageURL: URL(string: "https://example.com/multnomah-falls.jpg"),
            address: "53000 E Historic Columbia River Hwy, Corbett, OR 97019"
        ),
        POI(
            name: "Timberline Lodge",
            description: "Historic mountain lodge on Mount Hood, featuring rustic architecture and stunning views.",
            location: CLLocationCoordinate2D(latitude: 45.3311, longitude: -121.7113),
            category: .lodging,
            rating: 4.4,
            imageURL: URL(string: "https://example.com/timberline-lodge.jpg"),
            phoneNumber: "(503) 272-3311",
            address: "27500 E Timberline Rd, Government Camp, OR 97028"
        )
    ]
}