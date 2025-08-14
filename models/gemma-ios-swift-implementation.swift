// Complete iOS Swift implementation of Gemma 3n with Internet Search capability
// Requires iOS 15.0+ for async/await support

import SwiftUI
import Foundation
import Combine
import MediaPipeTasksGenAI  // Google AI Edge SDK for iOS

// MARK: - Main View for Gemma Chat Interface
struct GemmaSearchAgentView: View {
    @StateObject private var viewModel = GemmaSearchViewModel()
    @State private var inputText = ""
    @State private var isProcessing = false
    
    var body: some View {
        VStack {
            // Chat messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        if isProcessing {
                            TypingIndicator()
                        }
                    }
                    .padding()
                    .onChange(of: viewModel.messages.count) { _ in
                        withAnimation {
                            proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input field
            HStack {
                TextField("Ask anything...", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(isProcessing)
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                }
                .disabled(inputText.isEmpty || isProcessing)
            }
            .padding()
        }
        .navigationTitle("Gemma Search Agent")
        .onAppear {
            viewModel.initialize()
        }
    }
    
    private func sendMessage() {
        let query = inputText
        inputText = ""
        isProcessing = true
        
        Task {
            await viewModel.processQuery(query)
            isProcessing = false
        }
    }
}

// MARK: - View Model
@MainActor
class GemmaSearchViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    private var gemmaAgent: GemmaSearchAgent?
    
    func initialize() {
        Task {
            do {
                gemmaAgent = try await GemmaSearchAgent()
                messages.append(ChatMessage(
                    role: .system,
                    content: "Gemma 3n initialized. I can search the internet for current information!"
                ))
            } catch {
                messages.append(ChatMessage(
                    role: .error,
                    content: "Failed to initialize: \(error.localizedDescription)"
                ))
            }
        }
    }
    
    func processQuery(_ query: String) async {
        messages.append(ChatMessage(role: .user, content: query))
        
        do {
            guard let agent = gemmaAgent else {
                throw GemmaError.notInitialized
            }
            
            let response = try await agent.processWithTools(userQuery: query)
            messages.append(ChatMessage(role: .assistant, content: response))
        } catch {
            messages.append(ChatMessage(
                role: .error,
                content: "Error: \(error.localizedDescription)"
            ))
        }
    }
}

// MARK: - Core Gemma Search Agent
class GemmaSearchAgent {
    private let model: LlmInference
    private let searchTool = InternetSearchTool()
    private let functionRegistry = FunctionRegistry()
    
    // System prompt for function calling
    private let systemPrompt = """
    You are a helpful AI assistant with access to real-time internet search.
    
    AVAILABLE TOOLS:
    - search_internet(query: string): Search for current information online
    
    TOOL USE INSTRUCTIONS:
    1. For current events, news, or post-2023 information: ALWAYS use search_internet
    2. For established facts or pre-2023 information: Answer directly
    3. When using a tool, respond ONLY with the JSON function call
    4. Format: {"name": "search_internet", "parameters": {"query": "search terms"}}
    
    DECISION FRAMEWORK:
    - User asks about "latest" or "current" → Use search
    - User asks about events after 2023 → Use search
    - User needs real-time data (weather, stocks, news) → Use search
    - User asks about established facts → Answer directly
    - When uncertain → Use search to verify
    
    Remember: Keep search queries concise (2-6 words) for best results.
    """
    
    init() async throws {
        // Initialize Gemma model
        model = try await initializeModel()
        registerFunctions()
    }
    
    private func initializeModel() async throws -> LlmInference {
        // Download model if needed
        let modelPath = try await downloadModelIfNeeded()
        
        // Configure model options
        let options = LlmInference.Options(
            modelPath: modelPath,
            maxTokens: 2048,
            temperature: 0.7,
            topK: 40,
            randomSeed: 42
        )
        
        return try LlmInference(options: options)
    }
    
    private func downloadModelIfNeeded() async throws -> String {
        let modelName = "gemma-3n-e2b-it-int4.task"
        let documentsPath = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        let modelPath = documentsPath.appendingPathComponent(modelName)
        
        // Check if model exists
        if !FileManager.default.fileExists(atPath: modelPath.path) {
            // Download from HuggingFace
            let modelURL = URL(string: "https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/\(modelName)")!
            
            let (tempURL, _) = try await URLSession.shared.download(from: modelURL)
            try FileManager.default.moveItem(at: tempURL, to: modelPath)
        }
        
        return modelPath.path
    }
    
    private func registerFunctions() {
        functionRegistry.register(
            FunctionDeclaration(
                name: "search_internet",
                description: "Search the internet for current information",
                parameters: FunctionParameters(
                    type: "object",
                    properties: [
                        "query": PropertySchema(
                            type: "string",
                            description: "The search query"
                        )
                    ],
                    required: ["query"]
                )
            )
        )
    }
    
    func processWithTools(userQuery: String) async throws -> String {
        // Step 1: Initial query to model
        let fullPrompt = "\(systemPrompt)\n\nUser: \(userQuery)"
        let initialResponse = try model.generateResponse(prompt: fullPrompt)
        
        // Step 2: Check if response is a function call
        if let functionCall = parseFunctionCall(from: initialResponse) {
            // Step 3: Execute the function
            let searchResults = try await executeFunction(functionCall)
            
            // Step 4: Generate final response with search results
            let resultPrompt = """
            \(systemPrompt)
            
            User: \(userQuery)
            Assistant: I'll search for that information.
            Search results for "\(functionCall.parameters["query"] ?? "")":
            \(searchResults)
            
            Based on these search results, here's what I found:
            """
            
            return try model.generateResponse(prompt: resultPrompt)
        } else {
            // No function call needed
            return initialResponse
        }
    }
    
    private func parseFunctionCall(from response: String) -> FunctionCall? {
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
    
    private func executeFunction(_ call: FunctionCall) async throws -> String {
        switch call.name {
        case "search_internet":
            guard let query = call.parameters["query"] as? String else {
                throw GemmaError.invalidParameters
            }
            return try await searchTool.search(query: query)
            
        default:
            throw GemmaError.unknownFunction(call.name)
        }
    }
}

// MARK: - Internet Search Tool
class InternetSearchTool {
    private let serperAPIKey = ProcessInfo.processInfo.environment["SERPER_API_KEY"] ?? ""
    private let session = URLSession.shared
    
    func search(query: String) async throws -> String {
        // Try Serper API first
        do {
            let results = try await performSerperSearch(query: query)
            return formatSearchResults(results)
        } catch {
            // Fallback to DuckDuckGo instant answer API (no key required)
            return try await performDuckDuckGoSearch(query: query)
        }
    }
    
    private func performSerperSearch(query: String) async throws -> SerperResponse {
        var request = URLRequest(url: URL(string: "https://google.serper.dev/search")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(serperAPIKey, forHTTPHeaderField: "X-API-KEY")
        
        let body = ["q": query, "num": 5]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SearchError.apiError
        }
        
        return try JSONDecoder().decode(SerperResponse.self, from: data)
    }
    
    private func performDuckDuckGoSearch(query: String) async throws -> String {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let url = URL(string: "https://api.duckduckgo.com/?q=\(encodedQuery)&format=json&no_html=1")!
        
        let (data, _) = try await session.data(from: url)
        let response = try JSONDecoder().decode(DuckDuckGoResponse.self, from: data)
        
        var results = ""
        
        if let abstract = response.abstract, !abstract.isEmpty {
            results += "Summary: \(abstract)\n"
            if let source = response.abstractSource {
                results += "Source: \(source)\n"
            }
        }
        
        if let answer = response.answer, !answer.isEmpty {
            results += "\nDirect Answer: \(answer)\n"
        }
        
        response.relatedTopics.prefix(3).forEach { topic in
            if let text = topic.text {
                results += "\nRelated: \(text)\n"
            }
        }
        
        return results.isEmpty ? "No specific results found. The model will use its training data." : results
    }
    
    private func formatSearchResults(_ response: SerperResponse) -> String {
        var formatted = ""
        
        // Add answer box if available
        if let answerBox = response.answerBox {
            formatted += "Quick Answer: \(answerBox.answer)\n\n"
        }
        
        // Add organic results
        response.organic.prefix(3).forEach { result in
            formatted += "Title: \(result.title)\n"
            formatted += "Source: \(result.link)\n"
            formatted += "Summary: \(result.snippet)\n\n"
        }
        
        // Add knowledge graph
        if let knowledgeGraph = response.knowledgeGraph {
            formatted += "Additional Info: \(knowledgeGraph.description ?? "")\n"
        }
        
        return formatted
    }
}

// MARK: - ReAct Agent for Multi-Step Reasoning
class ReActAgent {
    private let model: LlmInference
    private let tools: ToolRegistry
    
    init(model: LlmInference, tools: ToolRegistry) {
        self.model = model
        self.tools = tools
    }
    
    func solve(query: String, maxSteps: Int = 5) async throws -> String {
        var trajectory: [ReActStep] = []
        var context = "Task: \(query)\n\n"
        
        for step in 1...maxSteps {
            // Generate thought
            let thoughtPrompt = "\(context)Thought \(step): "
            let thought = try model.generateResponse(prompt: thoughtPrompt)
            trajectory.append(.thought(thought))
            context += "Thought \(step): \(thought)\n"
            
            // Check if thought contains search intent
            if thought.lowercased().contains("search") {
                let searchQuery = extractSearchQuery(from: thought)
                let action = "search_internet(\"\(searchQuery)\")"
                context += "Action \(step): \(action)\n"
                trajectory.append(.action(action))
                
                // Execute search
                let searchTool = InternetSearchTool()
                let results = try await searchTool.search(query: searchQuery)
                let observation = "Search returned: \(results)"
                trajectory.append(.observation(observation))
                context += "Observation \(step): \(observation)\n"
            }
            
            // Check if ready to answer
            if thought.lowercased().contains("answer:") {
                let answer = thought.components(separatedBy: "answer:").last?.trimmingCharacters(in: .whitespaces) ?? ""
                return answer.isEmpty ? try generateFinalAnswer(context: context) : answer
            }
        }
        
        // Generate final answer if max steps reached
        return try generateFinalAnswer(context: context)
    }
    
    private func extractSearchQuery(from thought: String) -> String {
        // Pattern matching for search queries
        let patterns = [
            #"search for "([^"]+)""#,
            #"search about ([^.]+)"#,
            #"look up ([^.]+)"#,
            #"find information on ([^.]+)"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: thought, range: NSRange(thought.startIndex..., in: thought)),
               match.numberOfRanges > 1,
               let range = Range(match.range(at: 1), in: thought) {
                return String(thought[range]).trimmingCharacters(in: .whitespaces)
            }
        }
        
        // Fallback: extract key terms
        return thought.split(separator: " ")
            .filter { $0.count > 3 }
            .prefix(4)
            .joined(separator: " ")
    }
    
    private func generateFinalAnswer(context: String) throws -> String {
        let finalPrompt = "\(context)Based on my analysis, the answer is: "
        return try model.generateResponse(prompt: finalPrompt)
    }
}

// MARK: - Multimodal Support
class MultimodalAgent {
    private let model: LlmInference
    
    init(model: LlmInference) {
        self.model = model
    }
    
    func processImageQuery(text: String, image: UIImage) async throws -> String {
        // Convert UIImage to base64
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw GemmaError.imageProcessingFailed
        }
        let base64String = imageData.base64EncodedString()
        
        // Create multimodal prompt
        let multimodalPrompt = """
        <image>\(base64String)</image>
        
        User question about the image: \(text)
        
        Please analyze the image and answer the question. If you need current information about what's shown in the image, use the search_internet function.
        """
        
        return try model.generateResponse(prompt: multimodalPrompt)
    }
}

// MARK: - Supporting Types
struct ChatMessage: Identifiable {
    let id = UUID()
    let role: MessageRole
    let content: String
    let timestamp = Date()
    
    enum MessageRole {
        case user, assistant, system, error
    }
}

struct FunctionCall {
    let name: String
    let parameters: [String: Any]
}

struct FunctionDeclaration {
    let name: String
    let description: String
    let parameters: FunctionParameters
}

struct FunctionParameters {
    let type: String
    let properties: [String: PropertySchema]
    let required: [String]
}

struct PropertySchema {
    let type: String
    let description: String
}

// MARK: - Error Types
enum GemmaError: LocalizedError {
    case notInitialized
    case invalidParameters
    case unknownFunction(String)
    case imageProcessingFailed
    case modelLoadFailed
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Gemma model not initialized"
        case .invalidParameters:
            return "Invalid function parameters"
        case .unknownFunction(let name):
            return "Unknown function: \(name)"
        case .imageProcessingFailed:
            return "Failed to process image"
        case .modelLoadFailed:
            return "Failed to load model"
        }
    }
}

enum SearchError: LocalizedError {
    case apiError
    case noResults
    
    var errorDescription: String? {
        switch self {
        case .apiError:
            return "Search API error"
        case .noResults:
            return "No search results found"
        }
    }
}

// MARK: - Response Models
struct SerperResponse: Codable {
    let organic: [OrganicResult]
    let answerBox: AnswerBox?
    let knowledgeGraph: KnowledgeGraph?
}

struct OrganicResult: Codable {
    let title: String
    let link: String
    let snippet: String
}

struct AnswerBox: Codable {
    let answer: String
}

struct KnowledgeGraph: Codable {
    let title: String?
    let description: String?
}

struct DuckDuckGoResponse: Codable {
    let abstract: String?
    let abstractSource: String?
    let answer: String?
    let relatedTopics: [Topic]
    
    struct Topic: Codable {
        let text: String?
        
        private enum CodingKeys: String, CodingKey {
            case text = "Text"
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case abstract = "Abstract"
        case abstractSource = "AbstractSource"
        case answer = "Answer"
        case relatedTopics = "RelatedTopics"
    }
}

// MARK: - ReAct Step Types
enum ReActStep {
    case thought(String)
    case action(String)
    case observation(String)
}

// MARK: - UI Components
struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading) {
                Text(message.content)
                    .padding(12)
                    .background(backgroundColor)
                    .foregroundColor(textColor)
                    .cornerRadius(16)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            if message.role != .user {
                Spacer()
            }
        }
    }
    
    private var backgroundColor: Color {
        switch message.role {
        case .user:
            return .blue
        case .assistant:
            return Color(.systemGray5)
        case .system:
            return .green.opacity(0.2)
        case .error:
            return .red.opacity(0.2)
        }
    }
    
    private var textColor: Color {
        switch message.role {
        case .user:
            return .white
        default:
            return .primary
        }
    }
}

struct TypingIndicator: View {
    @State private var animationAmount = 0.0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.gray)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animationAmount)
                    .opacity(animationAmount)
                    .animation(
                        Animation.easeInOut(duration: 0.5)
                            .repeatForever()
                            .delay(Double(index) * 0.1),
                        value: animationAmount
                    )
            }
        }
        .onAppear {
            animationAmount = 1.0
        }
    }
}

// MARK: - App Entry Point
@main
struct GemmaSearchApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationView {
                GemmaSearchAgentView()
            }
        }
    }
}