import Foundation
import Combine

/// Gemini API Service for complex language tasks
/// Uses Google's Gemini API as a fallback for tasks that require more sophisticated processing
/// such as distilling social media comments and extracting recommendations
class GeminiAPIService: ObservableObject {
    
    // MARK: - Properties
    static let shared = GeminiAPIService()
    
    @Published var isProcessing = false
    @Published var lastError: Error?
    
    private let apiKey = "AIzaSyCE-l9KGCpE6pR-q7csHCkzmS7ugcu_9DU"
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta"
    private let model = "gemini-pro" // Using Gemini Pro for best quality
    
    private var cancellables = Set<AnyCancellable>()
    private let session = URLSession.shared
    
    // MARK: - API Models
    struct GeminiRequest: Codable {
        let contents: [Content]
        let generationConfig: GenerationConfig?
        
        struct Content: Codable {
            let parts: [Part]
            let role: String
        }
        
        struct Part: Codable {
            let text: String
        }
        
        struct GenerationConfig: Codable {
            let temperature: Double?
            let topK: Int?
            let topP: Double?
            let maxOutputTokens: Int?
        }
    }
    
    struct GeminiResponse: Codable {
        let candidates: [Candidate]?
        let error: APIError?
        
        struct Candidate: Codable {
            let content: Content
            let finishReason: String?
            
            struct Content: Codable {
                let parts: [Part]
                let role: String
            }
            
            struct Part: Codable {
                let text: String
            }
        }
        
        struct APIError: Codable {
            let code: Int
            let message: String
            let status: String
        }
    }
    
    // MARK: - Complex Task Methods
    
    /// Distill social media comments to extract key insights and recommendations
    func distillSocialMediaComments(
        comments: [String],
        location: String,
        category: String? = nil
    ) async throws -> DistilledInsights {
        
        let prompt = """
        Analyze these social media comments about \(location) and extract:
        1. Top recommendations (restaurants, attractions, activities)
        2. Key insights about the location
        3. Common themes and sentiments
        4. Hidden gems or local secrets mentioned
        5. Practical tips for visitors
        
        Comments:
        \(comments.joined(separator: "\n---\n"))
        
        Provide a structured analysis with specific recommendations.
        """
        
        let response = try await sendRequest(prompt: prompt, temperature: 0.7)
        return parseDistilledInsights(from: response)
    }
    
    /// Extract POI recommendations from unstructured text
    func extractPOIRecommendations(
        text: String,
        location: String,
        preferences: [String] = []
    ) async throws -> [POIRecommendation] {
        
        let preferencesText = preferences.isEmpty ? "" : "User preferences: \(preferences.joined(separator: ", "))"
        
        let prompt = """
        Extract specific point of interest recommendations from this text about \(location).
        \(preferencesText)
        
        Text:
        \(text)
        
        For each POI, provide:
        - Name
        - Category (restaurant, attraction, hotel, etc.)
        - Why it's recommended
        - Best time to visit
        - Estimated cost
        - Any special tips
        
        Format as a clear list.
        """
        
        let response = try await sendRequest(prompt: prompt, temperature: 0.5)
        return parsePOIRecommendations(from: response)
    }
    
    /// Generate a personalized travel itinerary
    func generateItinerary(
        location: String,
        duration: String,
        interests: [String],
        budget: String? = nil
    ) async throws -> TravelItinerary {
        
        let budgetText = budget != nil ? "Budget: \(budget!)" : "Budget: Flexible"
        
        let prompt = """
        Create a detailed travel itinerary for \(location).
        Duration: \(duration)
        Interests: \(interests.joined(separator: ", "))
        \(budgetText)
        
        Include:
        - Day-by-day schedule
        - Specific POIs to visit with timings
        - Restaurant recommendations for each meal
        - Transportation tips
        - Estimated costs
        - Alternative options for bad weather
        
        Make it practical and actionable.
        """
        
        let response = try await sendRequest(prompt: prompt, temperature: 0.8, maxTokens: 2000)
        return parseItinerary(from: response)
    }
    
    /// Analyze reviews and ratings to provide summary
    func analyzeReviews(
        reviews: [String],
        poiName: String
    ) async throws -> ReviewAnalysis {
        
        let prompt = """
        Analyze these reviews for \(poiName) and provide:
        
        1. Overall sentiment (positive/neutral/negative with percentage)
        2. Top 3 things people love
        3. Top 3 common complaints
        4. Unique features mentioned
        5. Best for what type of visitor
        6. Summary recommendation
        
        Reviews:
        \(reviews.joined(separator: "\n---\n"))
        """
        
        let response = try await sendRequest(prompt: prompt, temperature: 0.6)
        return parseReviewAnalysis(from: response)
    }
    
    // MARK: - Core API Method
    
    private func sendRequest(
        prompt: String,
        temperature: Double = 0.7,
        maxTokens: Int = 1000
    ) async throws -> String {
        
        isProcessing = true
        defer { isProcessing = false }
        
        // Build request
        let endpoint = "\(baseURL)/models/\(model):generateContent?key=\(apiKey)"
        
        guard let url = URL(string: endpoint) else {
            throw APIError.invalidURL
        }
        
        let requestBody = GeminiRequest(
            contents: [
                GeminiRequest.Content(
                    parts: [GeminiRequest.Part(text: prompt)],
                    role: "user"
                )
            ],
            generationConfig: GeminiRequest.GenerationConfig(
                temperature: temperature,
                topK: 40,
                topP: 0.95,
                maxOutputTokens: maxTokens
            )
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        // Send request
        let (data, response) = try await session.data(for: request)
        
        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            // Try to parse error
            if let geminiResponse = try? JSONDecoder().decode(GeminiResponse.self, from: data),
               let error = geminiResponse.error {
                throw APIError.apiError(code: error.code, message: error.message)
            }
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // Parse response
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        
        guard let candidates = geminiResponse.candidates,
              let firstCandidate = candidates.first,
              let text = firstCandidate.content.parts.first?.text else {
            throw APIError.noContent
        }
        
        return text
    }
    
    // MARK: - Response Parsing
    
    private func parseDistilledInsights(from response: String) -> DistilledInsights {
        // Simple parsing - in production, use more sophisticated parsing
        return DistilledInsights(
            recommendations: extractListItems(from: response, section: "recommendations"),
            insights: extractListItems(from: response, section: "insights"),
            themes: extractListItems(from: response, section: "themes"),
            hiddenGems: extractListItems(from: response, section: "hidden gems"),
            tips: extractListItems(from: response, section: "tips"),
            rawResponse: response
        )
    }
    
    private func parsePOIRecommendations(from response: String) -> [POIRecommendation] {
        // Parse structured POI data from response
        var recommendations: [POIRecommendation] = []
        
        // Simple line-based parsing
        let lines = response.components(separatedBy: "\n")
        var currentPOI: POIRecommendation?
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmed.hasPrefix("Name:") || trimmed.hasPrefix("- ") {
                if let poi = currentPOI {
                    recommendations.append(poi)
                }
                let name = trimmed.replacingOccurrences(of: "Name:", with: "")
                    .replacingOccurrences(of: "- ", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                currentPOI = POIRecommendation(name: name)
            } else if let poi = currentPOI {
                if trimmed.hasPrefix("Category:") {
                    currentPOI?.category = trimmed.replacingOccurrences(of: "Category:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                } else if trimmed.hasPrefix("Why:") || trimmed.hasPrefix("Reason:") {
                    currentPOI?.reason = trimmed.replacingOccurrences(of: "Why:", with: "")
                        .replacingOccurrences(of: "Reason:", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        
        if let poi = currentPOI {
            recommendations.append(poi)
        }
        
        return recommendations
    }
    
    private func parseItinerary(from response: String) -> TravelItinerary {
        return TravelItinerary(
            days: extractDays(from: response),
            transportation: extractSection(from: response, section: "Transportation"),
            estimatedCost: extractSection(from: response, section: "Cost"),
            alternativeOptions: extractListItems(from: response, section: "Alternative"),
            rawItinerary: response
        )
    }
    
    private func parseReviewAnalysis(from response: String) -> ReviewAnalysis {
        return ReviewAnalysis(
            sentiment: extractSection(from: response, section: "sentiment") ?? "Neutral",
            positives: extractListItems(from: response, section: "love"),
            negatives: extractListItems(from: response, section: "complaints"),
            uniqueFeatures: extractListItems(from: response, section: "unique"),
            bestFor: extractSection(from: response, section: "best for") ?? "General visitors",
            summary: extractSection(from: response, section: "summary") ?? response
        )
    }
    
    // MARK: - Helper Methods
    
    private func extractListItems(from text: String, section: String) -> [String] {
        // Simple extraction - looks for lines after section heading
        let lines = text.components(separatedBy: "\n")
        var items: [String] = []
        var inSection = false
        
        for line in lines {
            let lower = line.lowercased()
            if lower.contains(section.lowercased()) {
                inSection = true
                continue
            }
            
            if inSection {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.hasPrefix("-") || trimmed.hasPrefix("•") || trimmed.hasPrefix("*") {
                    let item = trimmed.dropFirst().trimmingCharacters(in: .whitespacesAndNewlines)
                    if !item.isEmpty {
                        items.append(String(item))
                    }
                } else if trimmed.isEmpty || trimmed.contains(":") {
                    // End of section
                    if !items.isEmpty {
                        break
                    }
                }
            }
        }
        
        return items
    }
    
    private func extractSection(from text: String, section: String) -> String? {
        let lines = text.components(separatedBy: "\n")
        for line in lines {
            if line.lowercased().contains(section.lowercased()) {
                let parts = line.components(separatedBy: ":")
                if parts.count > 1 {
                    return parts.dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        return nil
    }
    
    private func extractDays(from text: String) -> [ItineraryDay] {
        // Extract day-by-day itinerary
        var days: [ItineraryDay] = []
        let lines = text.components(separatedBy: "\n")
        var currentDay: ItineraryDay?
        
        for line in lines {
            if line.lowercased().contains("day ") {
                if let day = currentDay {
                    days.append(day)
                }
                currentDay = ItineraryDay(title: line, activities: [])
            } else if let _ = currentDay {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty && (trimmed.hasPrefix("-") || trimmed.hasPrefix("•")) {
                    currentDay?.activities.append(trimmed)
                }
            }
        }
        
        if let day = currentDay {
            days.append(day)
        }
        
        return days
    }
}

// MARK: - Data Models

struct DistilledInsights {
    let recommendations: [String]
    let insights: [String]
    let themes: [String]
    let hiddenGems: [String]
    let tips: [String]
    let rawResponse: String
}

struct POIRecommendation {
    var name: String
    var category: String?
    var reason: String?
    var bestTime: String?
    var estimatedCost: String?
    var tips: String?
}

struct TravelItinerary {
    let days: [ItineraryDay]
    let transportation: String?
    let estimatedCost: String?
    let alternativeOptions: [String]
    let rawItinerary: String
}

struct ItineraryDay {
    let title: String
    var activities: [String]
}

struct ReviewAnalysis {
    let sentiment: String
    let positives: [String]
    let negatives: [String]
    let uniqueFeatures: [String]
    let bestFor: String
    let summary: String
}

// MARK: - Error Handling

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case noContent
    case httpError(statusCode: Int)
    case apiError(code: Int, message: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .noContent:
            return "No content in response"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .apiError(_, let message):
            return "API error: \(message)"
        }
    }
}