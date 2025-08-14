// Practical Example: Travel Assistant App using Gemma 3n
// This demonstrates real-world usage with multiple tools and multimodal input

import SwiftUI
import CoreLocation
import MediaPipeTasksGenAI

// MARK: - Travel Assistant Agent
class TravelAssistantAgent: ObservableObject {
    private var model: LlmInference?
    private let tools = ToolsRegistry()
    
    @Published var isReady = false
    @Published var conversations: [TravelConversation] = []
    
    // Enhanced system prompt for travel context
    private let systemPrompt = """
    You are a helpful travel assistant with access to real-time information.
    
    AVAILABLE TOOLS:
    1. search_flights(from: string, to: string, date: string) - Search for flights
    2. search_hotels(location: string, checkin: string, checkout: string) - Find hotels
    3. get_weather(location: string, date: string) - Get weather forecast
    4. search_attractions(location: string) - Find tourist attractions
    5. search_restaurants(location: string, cuisine: string?) - Find restaurants
    6. get_travel_advisory(country: string) - Get safety/visa information
    7. search_general(query: string) - General internet search
    
    GUIDELINES:
    - Always use tools for current information (prices, availability, weather)
    - For visa requirements and travel advisories, ALWAYS use get_travel_advisory
    - When planning trips, gather information systematically
    - Consider user's budget and preferences when making recommendations
    
    To use a tool, respond ONLY with:
    {"name": "tool_name", "parameters": {...}}
    """
    
    init() {
        setupTools()
    }
    
    func initialize() async {
        do {
            // Load Gemma 3n model
            let modelPath = try await downloadModel()
            let options = LlmInference.Options(
                modelPath: modelPath,
                maxTokens: 2048,
                temperature: 0.7,
                topK: 40
            )
            
            model = try LlmInference(options: options)
            await MainActor.run { isReady = true }
        } catch {
            print("Initialization failed: \(error)")
        }
    }
    
    // Process travel queries with context awareness
    func askTravelQuestion(_ question: String, image: UIImage? = nil) async -> TravelResponse {
        guard let model = model else {
            return TravelResponse(text: "Assistant not ready", usedTools: [])
        }
        
        var usedTools: [String] = []
        var context = systemPrompt + "\n\nUser: \(question)"
        
        // Add image context if provided
        if let image = image {
            let imageData = image.jpegData(compressionQuality: 0.8)!
            let base64 = imageData.base64EncodedString()
            context = "<image>\(base64)</image>\n\n" + context
        }
        
        do {
            // Initial model response
            var response = try model.generateResponse(prompt: context)
            
            // Handle multiple tool calls in sequence
            var toolCallCount = 0
            while let functionCall = parseFunctionCall(response), toolCallCount < 5 {
                usedTools.append(functionCall.name)
                
                // Execute the tool
                let toolResult = try await executeToolCall(functionCall)
                
                // Add tool result to context
                context += "\n\nAssistant called: \(functionCall.name)"
                context += "\nResult: \(toolResult)"
                context += "\n\nPlease continue helping the user with this information."
                
                // Get next response
                response = try model.generateResponse(prompt: context)
                toolCallCount += 1
            }
            
            return TravelResponse(text: response, usedTools: usedTools)
        } catch {
            return TravelResponse(
                text: "Error: \(error.localizedDescription)",
                usedTools: usedTools
            )
        }
    }
    
    // Setup available tools
    private func setupTools() {
        // Flight search tool
        tools.register(Tool(
            name: "search_flights",
            execute: { params in
                let from = params["from"] as? String ?? ""
                let to = params["to"] as? String ?? ""
                let date = params["date"] as? String ?? ""
                
                // In production, use real flight API (Amadeus, Skyscanner, etc.)
                let mockResults = """
                Found 3 flights from \(from) to \(to) on \(date):
                1. United Airlines - Departs 8:00 AM, Arrives 2:30 PM - $450
                2. Delta Airlines - Departs 11:15 AM, Arrives 5:45 PM - $380
                3. Southwest - Departs 3:30 PM, Arrives 10:00 PM - $320
                All prices are economy class. Business class available at 2-3x price.
                """
                return mockResults
            }
        ))
        
        // Hotel search tool
        tools.register(Tool(
            name: "search_hotels",
            execute: { params in
                let location = params["location"] as? String ?? ""
                
                // Mock hotel results (use Booking.com or Hotels.com API in production)
                return """
                Top hotels in \(location):
                1. Grand Hyatt - 5★ - $280/night - Downtown, excellent reviews
                2. Marriott - 4★ - $180/night - Near airport, business friendly
                3. Holiday Inn - 3★ - $120/night - Good value, free breakfast
                4. Local Boutique Hotel - 4★ - $150/night - Cultural district
                """
            }
        ))
        
        // Weather tool
        tools.register(Tool(
            name: "get_weather",
            execute: { params in
                let location = params["location"] as? String ?? ""
                let date = params["date"] as? String ?? "today"
                
                // Use OpenWeatherMap or similar API in production
                return """
                Weather forecast for \(location) on \(date):
                Temperature: 22°C (72°F)
                Conditions: Partly cloudy
                Chance of rain: 20%
                Humidity: 65%
                Perfect for sightseeing!
                """
            }
        ))
        
        // Attractions tool
        tools.register(Tool(
            name: "search_attractions",
            execute: { params in
                let location = params["location"] as? String ?? ""
                
                // Use TripAdvisor or Google Places API in production
                return """
                Top attractions in \(location):
                1. Historical Museum - 4.5★ - History buffs must-see
                2. Central Park - 4.7★ - Beautiful gardens and walking paths
                3. Art Gallery - 4.6★ - Modern and classical art
                4. Local Market - 4.4★ - Authentic local experience
                5. Observation Tower - 4.8★ - Panoramic city views
                """
            }
        ))
        
        // Restaurant search tool
        tools.register(Tool(
            name: "search_restaurants",
            execute: { params in
                let location = params["location"] as? String ?? ""
                let cuisine = params["cuisine"] as? String ?? "local"
                
                return """
                Best \(cuisine) restaurants in \(location):
                1. The Local Table - 4.6★ - $$$ - Farm-to-table cuisine
                2. Street Food Alley - 4.4★ - $ - Authentic local dishes
                3. Seafood Paradise - 4.7★ - $$$ - Fresh daily catch
                4. Vegetarian Delight - 4.5★ - $$ - Plant-based options
                """
            }
        ))
        
        // Travel advisory tool
        tools.register(Tool(
            name: "get_travel_advisory",
            execute: { params in
                let country = params["country"] as? String ?? ""
                
                // Use government travel API in production
                return """
                Travel Advisory for \(country):
                - Safety Level: Generally Safe (Level 2)
                - Visa: Required for stays over 30 days
                - Vaccinations: Hepatitis A/B recommended
                - Currency: Local currency, USD widely accepted
                - Language: English spoken in tourist areas
                - Emergency: Dial 112
                Current as of: \(Date().formatted())
                """
            }
        ))
        
        // General search fallback
        tools.register(Tool(
            name: "search_general",
            execute: { params in
                let query = params["query"] as? String ?? ""
                
                // Use DuckDuckGo instant answer API
                return try await performDuckDuckGoSearch(query: query)
            }
        ))
    }
    
    private func executeToolCall(_ call: FunctionCall) async throws -> String {
        guard let tool = tools.getTool(call.name) else {
            throw TravelError.unknownTool(call.name)
        }
        
        return try await tool.execute(call.parameters)
    }
    
    private func parseFunctionCall(_ response: String) -> FunctionCall? {
        // Same implementation as before
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("{"),
              let data = trimmed.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let name = json["name"] as? String,
              let parameters = json["parameters"] as? [String: Any] else {
            return nil
        }
        
        return FunctionCall(name: name, parameters: parameters)
    }
}

// MARK: - Travel Planning View
struct TravelPlannerView: View {
    @StateObject private var assistant = TravelAssistantAgent()
    @State private var destination = ""
    @State private var travelDates = DateRange()
    @State private var budget = Budget.medium
    @State private var interests: Set<TravelInterest> = []
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var planningResults = ""
    @State private var isPlanning = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Trip Details") {
                    TextField("Destination", text: $destination)
                    
                    DatePicker("From", selection: $travelDates.start, displayedComponents: .date)
                    DatePicker("To", selection: $travelDates.end, displayedComponents: .date)
                    
                    Picker("Budget", selection: $budget) {
                        ForEach(Budget.allCases) { budget in
                            Text(budget.rawValue).tag(budget)
                        }
                    }
                }
                
                Section("Interests") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                        ForEach(TravelInterest.allCases) { interest in
                            InterestChip(
                                interest: interest,
                                isSelected: interests.contains(interest)
                            ) {
                                if interests.contains(interest) {
                                    interests.remove(interest)
                                } else {
                                    interests.insert(interest)
                                }
                            }
                        }
                    }
                }
                
                Section("Inspiration Photo") {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                    }
                    
                    Button("Add Photo") {
                        showingImagePicker = true
                    }
                }
                
                Section {
                    Button(action: planTrip) {
                        if isPlanning {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Plan My Trip")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!assistant.isReady || destination.isEmpty || isPlanning)
                }
                
                if !planningResults.isEmpty {
                    Section("Your Travel Plan") {
                        Text(planningResults)
                            .font(.system(.body, design: .serif))
                    }
                }
            }
            .navigationTitle("Travel Planner")
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .onAppear {
                Task { await assistant.initialize() }
            }
        }
    }
    
    private func planTrip() {
        isPlanning = true
        
        Task {
            let query = buildTravelQuery()
            let response = await assistant.askTravelQuestion(query, image: selectedImage)
            
            await MainActor.run {
                planningResults = response.text
                isPlanning = false
            }
        }
    }
    
    private func buildTravelQuery() -> String {
        var query = "Plan a trip to \(destination) "
        query += "from \(travelDates.start.formatted(date: .abbreviated, time: .omitted)) "
        query += "to \(travelDates.end.formatted(date: .abbreviated, time: .omitted)). "
        query += "My budget is \(budget.rawValue). "
        
        if !interests.isEmpty {
            let interestList = interests.map { $0.rawValue }.joined(separator: ", ")
            query += "I'm interested in \(interestList). "
        }
        
        if selectedImage != nil {
            query += "The attached photo shows the kind of experience I'm looking for. "
        }
        
        query += "Please search for flights, suggest hotels, check the weather, "
        query += "recommend attractions and restaurants, and provide travel advisories."
        
        return query
    }
}

// MARK: - Supporting Types
struct TravelResponse {
    let text: String
    let usedTools: [String]
}

struct DateRange {
    var start = Date()
    var end = Date().addingTimeInterval(7 * 24 * 60 * 60) // 7 days later
}

enum Budget: String, CaseIterable, Identifiable {
    case budget = "Budget-conscious"
    case medium = "Moderate"
    case luxury = "Luxury"
    
    var id: String { rawValue }
}

enum TravelInterest: String, CaseIterable, Identifiable {
    case culture = "Culture"
    case food = "Food"
    case nature = "Nature"
    case adventure = "Adventure"
    case relaxation = "Relaxation"
    case shopping = "Shopping"
    case nightlife = "Nightlife"
    case history = "History"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .culture: return "🎭"
        case .food: return "🍽️"
        case .nature: return "🌿"
        case .adventure: return "🎯"
        case .relaxation: return "🧘"
        case .shopping: return "🛍️"
        case .nightlife: return "🌃"
        case .history: return "🏛️"
        }
    }
}

struct InterestChip: View {
    let interest: TravelInterest
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(interest.icon)
                Text(interest.rawValue)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

// MARK: - Conversation History
struct TravelConversation: Identifiable {
    let id = UUID()
    let query: String
    let response: String
    let toolsUsed: [String]
    let timestamp = Date()
}

// MARK: - Tools Registry
class ToolsRegistry {
    private var tools: [String: Tool] = [:]
    
    func register(_ tool: Tool) {
        tools[tool.name] = tool
    }
    
    func getTool(_ name: String) -> Tool? {
        return tools[name]
    }
}

struct Tool {
    let name: String
    let execute: ([String: Any]) async throws -> String
}

// MARK: - Error Types
enum TravelError: LocalizedError {
    case unknownTool(String)
    case networkError
    case modelError(String)
    
    var errorDescription: String? {
        switch self {
        case .unknownTool(let name):
            return "Unknown tool: \(name)"
        case .networkError:
            return "Network request failed"
        case .modelError(let error):
            return "Model error: \(error)"
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - DuckDuckGo Search Implementation
func performDuckDuckGoSearch(query: String) async throws -> String {
    let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    let url = URL(string: "https://api.duckduckgo.com/?q=\(encoded)&format=json&no_html=1")!
    
    let (data, _) = try await URLSession.shared.data(from: url)
    
    // Parse response and format results
    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
        var results = ""
        
        if let abstract = json["Abstract"] as? String, !abstract.isEmpty {
            results += abstract + "\n"
        }
        
        if let answer = json["Answer"] as? String, !answer.isEmpty {
            results += "Answer: " + answer + "\n"
        }
        
        return results.isEmpty ? "No specific results found." : results
    }
    
    return "Search failed"
}