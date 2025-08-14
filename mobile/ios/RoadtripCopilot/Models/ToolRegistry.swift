import Foundation
import MediaPipeTasksGenAI

// MARK: - Tool Registry for Function Calling
class ToolRegistry {
    private var tools: [String: Tool] = [:]
    
    init() {
        registerDefaultTools()
    }
    
    func register(_ tool: Tool) {
        tools[tool.name] = tool
    }
    
    func getTool(_ name: String) -> Tool? {
        return tools[name]
    }
    
    func getAllTools() -> [Tool] {
        return Array(tools.values)
    }
    
    private func registerDefaultTools() {
        // POI Search Tool
        register(Tool(
            name: "search_poi",
            description: "Search for points of interest near a location",
            parameters: [
                "location": "The location to search near (city name or coordinates)",
                "category": "Category of POI (restaurant, hotel, attraction, etc.)"
            ],
            execute: { params in
                let location = params["location"] as? String ?? ""
                let category = params["category"] as? String ?? "attraction"
                
                // Mock POI results for now - will be replaced with real API
                return """
                Found POIs near \(location):
                1. Historic Downtown (\(category)) - 4.5★ - 0.5 miles
                2. Local Museum (\(category)) - 4.7★ - 1.2 miles
                3. Scenic Overlook (\(category)) - 4.8★ - 2.3 miles
                4. Hidden Gem Cafe (\(category)) - 4.6★ - 0.8 miles
                5. Artisan Market (\(category)) - 4.4★ - 1.5 miles
                """
            }
        ))
        
        // POI Details Tool
        register(Tool(
            name: "get_poi_details",
            description: "Get detailed information about a specific POI",
            parameters: [
                "poi_name": "Name of the point of interest"
            ],
            execute: { params in
                let poiName = params["poi_name"] as? String ?? "Unknown POI"
                
                return """
                \(poiName) Details:
                - Rating: 4.6/5 (324 reviews)
                - Hours: 9 AM - 6 PM daily
                - Description: A must-visit local attraction with stunning views
                - Highlights: Photo opportunities, local history, gift shop
                - Admission: $12 adults, $8 children
                - Phone: (555) 123-4567
                - Website: www.example.com/\(poiName.lowercased().replacingOccurrences(of: " ", with: "-"))
                """
            }
        ))
        
        // Internet Search Tool
        register(Tool(
            name: "search_internet",
            description: "Search the internet for current information",
            parameters: [
                "query": "The search query"
            ],
            execute: { params in
                let query = params["query"] as? String ?? ""
                
                // Use DuckDuckGo instant answer API (no key required)
                return await self.performDuckDuckGoSearch(query: query)
            }
        ))
        
        // Directions Tool
        register(Tool(
            name: "get_directions",
            description: "Get navigation directions between two locations",
            parameters: [
                "from": "Starting location",
                "to": "Destination location"
            ],
            execute: { params in
                let from = params["from"] as? String ?? "Current Location"
                let to = params["to"] as? String ?? "Destination"
                
                return """
                Directions from \(from) to \(to):
                - Distance: 15.3 miles
                - Duration: 22 minutes
                - Route: Take Highway 101 North for 12 miles, exit at Main St
                - Traffic: Light traffic, no delays
                - Fuel stops: 2 gas stations along the route
                """
            }
        ))
    }
    
    private func performDuckDuckGoSearch(query: String) async -> String {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.duckduckgo.com/?q=\(encodedQuery)&format=json&no_html=1") else {
            return "Search failed: Invalid query"
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                var results = ""
                
                if let abstract = json["Abstract"] as? String, !abstract.isEmpty {
                    results += abstract + "\n"
                }
                
                if let answer = json["Answer"] as? String, !answer.isEmpty {
                    results += "Direct Answer: " + answer + "\n"
                }
                
                if let relatedTopics = json["RelatedTopics"] as? [[String: Any]] {
                    for (index, topic) in relatedTopics.prefix(3).enumerated() {
                        if let text = topic["Text"] as? String {
                            results += "\nRelated \(index + 1): \(text)\n"
                        }
                    }
                }
                
                return results.isEmpty ? "No specific results found for: \(query)" : results
            }
        } catch {
            return "Search error: \(error.localizedDescription)"
        }
        
        return "No results found"
    }
}

// MARK: - Tool Definition
struct Tool {
    let name: String
    let description: String
    let parameters: [String: String]
    let execute: ([String: Any]) async -> String
}

// MARK: - Function Call Parser
struct FunctionCall {
    let name: String
    let parameters: [String: Any]
    
    static func parse(from response: String) -> FunctionCall? {
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Look for JSON function call pattern
        guard let jsonStart = trimmed.range(of: "{"),
              let jsonEnd = trimmed.range(of: "}", options: .backwards),
              jsonStart.lowerBound <= jsonEnd.lowerBound else {
            return nil
        }
        
        let jsonString = String(trimmed[jsonStart.lowerBound...jsonEnd.upperBound])
        
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let name = json["name"] as? String,
              let parameters = json["parameters"] as? [String: Any] else {
            return nil
        }
        
        return FunctionCall(name: name, parameters: parameters)
    }
}