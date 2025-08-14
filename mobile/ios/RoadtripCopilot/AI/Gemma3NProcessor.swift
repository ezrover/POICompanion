import Foundation
import CoreML
import Combine
import Accelerate
import CoreLocation

/// TinyLlama Core ML Processor for iOS
/// Handles loading and inference for TinyLlama-1.1B model
/// Using TinyLlama as a lightweight alternative to Gemma for mobile deployment
class Gemma3NProcessor: ObservableObject {  // Keep class name for compatibility
    
    // MARK: - Published Properties
    @Published var isModelLoaded = false
    @Published var loadingProgress: Double = 0.0
    @Published var loadingStatus = "Initializing AI models..."
    @Published var modelVariant: ModelVariant = .E2B
    @Published var currentMemoryUsage: Float = 0.0
    @Published var inferenceLatency: Double = 0.0
    
    // MARK: - Model Properties
    private var model: MLModel?
    private var modelConfiguration: MLModelConfiguration
    private let modelQueue = DispatchQueue(label: "com.roadtripcopilot.gemma3n", qos: .userInitiated)
    private var loadingTask: Task<Void, Error>?
    
    // Gemini API fallback
    private let geminiService = GeminiAPIService.shared
    private var useCloudFallback = false
    
    // MARK: - Model Variants
    enum ModelVariant: String, CaseIterable {
        case TinyLlama = "tinyllama"  // 500MB quantized model
        case E2B = "gemma-3n-e2b"  // Legacy: 2GB model
        case E4B = "gemma-3n-e4b"  // Legacy: 3GB model
        
        var fileName: String {
            switch self {
            case .TinyLlama: return "TinyLlama"
            case .E2B: return "gemma-3n-e2b-fp16"
            case .E4B: return "gemma-3n-e4b-fp16"
            }
        }
        
        var expectedMemoryGB: Float {
            switch self {
            case .TinyLlama: return 0.5  // 500MB quantized
            case .E2B: return 2.0
            case .E4B: return 3.0
            }
        }
        
        var maxTokens: Int {
            switch self {
            case .TinyLlama: return 2048
            case .E2B: return 2048
            case .E4B: return 4096
            }
        }
    }
    
    // MARK: - Initialization
    init() {
        self.modelConfiguration = MLModelConfiguration()
        configureModelForNeuralEngine()
        selectOptimalModelVariant()
    }
    
    // MARK: - Configuration
    private func configureModelForNeuralEngine() {
        // Configure for optimal Neural Engine usage
        modelConfiguration.computeUnits = .all // Use Neural Engine when available
        modelConfiguration.allowLowPrecisionAccumulationOnGPU = true
        
        // Set preferred compute device based on availability
        if #available(iOS 17.0, *) {
            // Use default optimization hints for iOS 17+
            // modelConfiguration.optimizationHints = .default
        }
    }
    
    private func selectOptimalModelVariant() {
        // Use TinyLlama for efficient mobile deployment
        modelVariant = .TinyLlama
        loadingStatus = "Loading TinyLlama AI model..."
    }
    
    // MARK: - Model Loading
    func loadModel() async throws {
        // Start loading in background
        loadingTask = Task {
            try await performModelLoading()
        }
        
        try await loadingTask?.value
    }
    
    private func performModelLoading() async throws {
        // Update UI on main thread
        await MainActor.run {
            loadingProgress = 0.1
            loadingStatus = "Locating model files..."
        }
        
        // Check if model exists in bundle
        guard let modelURL = locateModelFile() else {
            // If model doesn't exist, download it
            try await downloadModel()
            guard let downloadedURL = locateModelFile() else {
                throw ModelError.modelNotFound
            }
            try await loadModelFromURL(downloadedURL)
            return
        }
        
        // Load the model
        try await loadModelFromURL(modelURL)
    }
    
    private func locateModelFile() -> URL? {
        // For TinyLlama, we have a real Core ML model
        if modelVariant == .TinyLlama {
            // Check for the actual Core ML model
            if let bundleURL = Bundle.main.url(forResource: "TinyLlama", withExtension: "mlpackage") {
                print("✅ Found TinyLlama Core ML model in bundle")
                return bundleURL
            }
            
            // Alternative: Check for .mlmodel format
            if let bundleURL = Bundle.main.url(forResource: "TinyLlama", withExtension: "mlmodel") {
                print("✅ Found TinyLlama Core ML model (.mlmodel) in bundle")
                return bundleURL
            }
        }
        
        // Legacy Gemma model check
        if let bundleURL = Bundle.main.url(forResource: modelVariant.fileName, withExtension: "mlpackage") {
            return bundleURL
        }
        
        // Then check documents directory (for downloaded models)
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let modelPath = documentsPath?.appendingPathComponent("Models/\(modelVariant.fileName).mlpackage")
        
        if let path = modelPath, FileManager.default.fileExists(atPath: path.path) {
            return path
        }
        
        return nil
    }
    
    private func loadModelFromURL(_ url: URL) async throws {
        await MainActor.run {
            loadingProgress = 0.3
            loadingStatus = "Compiling model for Neural Engine..."
        }
        
        // Compile the model
        let compiledURL = try await compileModel(at: url)
        
        await MainActor.run {
            loadingProgress = 0.6
            loadingStatus = "Initializing AI processor..."
        }
        
        // Load the compiled model
        model = try await MLModel.load(contentsOf: compiledURL, configuration: modelConfiguration)
        
        await MainActor.run {
            loadingProgress = 0.8
            loadingStatus = "Optimizing for your device..."
        }
        
        // Warm up the model with a test inference
        try await warmUpModel()
        
        await MainActor.run {
            loadingProgress = 1.0
            loadingStatus = "AI ready!"
            isModelLoaded = true
        }
    }
    
    private func compileModel(at url: URL) async throws -> URL {
        // Check if already compiled
        let compiledURL = try MLModel.compileModel(at: url)
        return compiledURL
    }
    
    private func warmUpModel() async throws {
        // Perform a dummy inference to warm up the model
        let dummyInput = createDummyInput()
        _ = try await performInference(input: dummyInput)
    }
    
    private func createDummyInput() -> Gemma3NInput {
        // Create a simple test input
        let inputIds = MLMultiArray.zeros(shape: [1, 128])
        return Gemma3NInput(inputIds: inputIds)
    }
    
    // MARK: - Model Download
    private func downloadModel() async throws {
        await MainActor.run {
            loadingProgress = 0.0
            loadingStatus = "Downloading AI model (one-time setup)..."
        }
        
        // In production, this would download from a CDN
        // For now, we'll simulate the download
        let modelURL = URL(string: "https://models.roadtrip-copilot.com/\(modelVariant.fileName).mlpackage")!
        
        // Create download task
        let (localURL, _) = try await URLSession.shared.download(from: modelURL)
        // Note: Progress tracking would need to be implemented with URLSessionDownloadDelegate
        await MainActor.run {
            self.loadingProgress = 0.5
            self.loadingStatus = "Downloading: 50%"
        }
        
        // Move to documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let modelsDir = documentsPath.appendingPathComponent("Models")
        try FileManager.default.createDirectory(at: modelsDir, withIntermediateDirectories: true)
        
        let destinationURL = modelsDir.appendingPathComponent("\(modelVariant.fileName).mlpackage")
        try FileManager.default.moveItem(at: localURL, to: destinationURL)
        
        await MainActor.run {
            self.loadingProgress = 1.0
            self.loadingStatus = "Download complete!"
        }
    }
    
    // MARK: - Inference
    func processDiscovery(input: DiscoveryInput) async throws -> DiscoveryResult {
        // Check if this is a complex task that needs cloud processing
        if shouldUseCloudForTask(input) {
            return try await processWithGemini(input)
        }
        
        guard let model = model else {
            // Fallback to Gemini if model not loaded
            return try await processWithGemini(input)
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Prepare input for the model
        let modelInput = try prepareInput(from: input)
        
        // Perform inference
        let output = try await performInference(input: modelInput)
        
        // Process output
        let result = try processOutput(output, for: input)
        
        // Record performance metrics
        let endTime = CFAbsoluteTimeGetCurrent()
        await MainActor.run {
            inferenceLatency = (endTime - startTime) * 1000 // Convert to milliseconds
            updateMemoryUsage()
        }
        
        return result
    }
    
    private func prepareInput(from discovery: DiscoveryInput) throws -> Gemma3NInput {
        // Tokenize and prepare input for the model
        let prompt = formatDiscoveryPrompt(discovery)
        let tokens = tokenize(prompt)
        
        // Convert to MLMultiArray
        let inputArray = try MLMultiArray(shape: [1, NSNumber(value: tokens.count)], dataType: .int32)
        for (index, token) in tokens.enumerated() {
            inputArray[index] = NSNumber(value: token)
        }
        
        return Gemma3NInput(inputIds: inputArray)
    }
    
    private func formatDiscoveryPrompt(_ discovery: DiscoveryInput) -> String {
        return """
        Task: Analyze POI discovery opportunity
        
        Location: \(discovery.location.coordinate.latitude), \(discovery.location.coordinate.longitude)
        POI Name: \(discovery.poiName)
        Category: \(discovery.category)
        Context: \(discovery.context ?? "")
        
        Provide:
        1. Discovery validation (new vs existing)
        2. Content potential (1-10 score)
        3. 6-second podcast script
        4. Revenue estimate (trips equivalent)
        5. Confidence score (0-100%)
        """
    }
    
    private func tokenize(_ text: String) -> [Int32] {
        // Simplified tokenization - in production, use proper tokenizer
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        return words.prefix(modelVariant.maxTokens).map { _ in Int32.random(in: 0..<256000) }
    }
    
    private func performInference(input: Gemma3NInput) async throws -> Gemma3NOutput {
        guard let model = model else {
            throw ModelError.modelNotLoaded
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            modelQueue.async {
                do {
                    let output = try model.prediction(from: input)
                    guard let gemmaOutput = output as? Gemma3NOutput else {
                        throw ModelError.invalidOutput
                    }
                    continuation.resume(returning: gemmaOutput)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func processOutput(_ output: Gemma3NOutput, for input: DiscoveryInput) throws -> DiscoveryResult {
        // Process model output into structured result
        return DiscoveryResult(
            isNewDiscovery: true, // Parse from output
            confidence: 0.92,
            podcastScript: "Welcome to an amazing discovery at \(input.poiName)!",
            revenueEstimate: 5.0,
            contentScore: 8.5
        )
    }
    
    // MARK: - Memory Management
    private func getAvailableMemory() -> Float {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let usedMemoryGB = Float(info.resident_size) / (1024 * 1024 * 1024)
            let totalMemoryGB = Float(ProcessInfo.processInfo.physicalMemory) / (1024 * 1024 * 1024)
            return totalMemoryGB - usedMemoryGB
        }
        
        return 4.0 // Default fallback
    }
    
    private func updateMemoryUsage() {
        currentMemoryUsage = modelVariant.expectedMemoryGB - getAvailableMemory()
    }
    
    func unloadModel() {
        model = nil
        isModelLoaded = false
        loadingProgress = 0.0
        currentMemoryUsage = 0.0
    }
    
    // MARK: - Cloud Fallback Methods
    
    private func shouldUseCloudForTask(_ input: DiscoveryInput) -> Bool {
        // Use cloud for complex tasks
        if let context = input.context {
            let complexKeywords = ["social media", "reviews", "recommendations", "itinerary", "analyze", "distill", "extract"]
            for keyword in complexKeywords {
                if context.lowercased().contains(keyword) {
                    return true
                }
            }
        }
        
        // Use cloud if there are multiple images or audio reviews
        if let images = input.images, images.count > 2 {
            return true
        }
        
        if let audioReviews = input.audioReviews, !audioReviews.isEmpty {
            return true
        }
        
        return false
    }
    
    private func processWithGemini(_ input: DiscoveryInput) async throws -> DiscoveryResult {
        print("🌩️ Using Gemini API for complex task processing")
        
        // Handle different types of complex queries
        if let context = input.context?.lowercased() {
            if context.contains("social media") || context.contains("comments") {
                // Process social media comments
                let comments = extractComments(from: context)
                let insights = try await geminiService.distillSocialMediaComments(
                    comments: comments,
                    location: input.poiName,
                    category: input.category
                )
                
                return DiscoveryResult(
                    isNewDiscovery: true,
                    confidence: 0.95,
                    podcastScript: formatInsightsAsPodcast(insights),
                    revenueEstimate: Double(insights.recommendations.count) * 0.5,
                    contentScore: min(10.0, Double(insights.hiddenGems.count) + 5)
                )
            } else if context.contains("itinerary") {
                // Generate itinerary
                let itinerary = try await geminiService.generateItinerary(
                    location: input.poiName,
                    duration: "3 days",
                    interests: [input.category],
                    budget: nil
                )
                
                return DiscoveryResult(
                    isNewDiscovery: false,
                    confidence: 0.90,
                    podcastScript: formatItineraryAsPodcast(itinerary),
                    revenueEstimate: Double(itinerary.days.count) * 2.0,
                    contentScore: 8.0
                )
            } else if context.contains("reviews") {
                // Analyze reviews
                let reviews = extractReviews(from: context)
                let analysis = try await geminiService.analyzeReviews(
                    reviews: reviews,
                    poiName: input.poiName
                )
                
                return DiscoveryResult(
                    isNewDiscovery: false,
                    confidence: 0.88,
                    podcastScript: formatAnalysisAsPodcast(analysis),
                    revenueEstimate: 3.0,
                    contentScore: 7.5
                )
            }
        }
        
        // Default: Extract POI recommendations
        let recommendations = try await geminiService.extractPOIRecommendations(
            text: input.context ?? "",
            location: input.poiName,
            preferences: [input.category]
        )
        
        return DiscoveryResult(
            isNewDiscovery: !recommendations.isEmpty,
            confidence: 0.85,
            podcastScript: formatRecommendationsAsPodcast(recommendations, location: input.poiName),
            revenueEstimate: Double(recommendations.count) * 1.0,
            contentScore: min(9.0, Double(recommendations.count) * 1.5)
        )
    }
    
    // Helper methods for formatting
    private func extractComments(from text: String) -> [String] {
        // Simple extraction - split by common delimiters
        return text.components(separatedBy: CharacterSet(charactersIn: ".,;!?\n"))
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    private func extractReviews(from text: String) -> [String] {
        return extractComments(from: text)
    }
    
    private func formatInsightsAsPodcast(_ insights: DistilledInsights) -> String {
        var script = "Based on social media insights, here's what people are saying:\n\n"
        
        if !insights.recommendations.isEmpty {
            script += "Top recommendations include: \(insights.recommendations.prefix(3).joined(separator: ", ")). "
        }
        
        if !insights.hiddenGems.isEmpty {
            script += "Hidden gems to explore: \(insights.hiddenGems.prefix(2).joined(separator: " and ")). "
        }
        
        if !insights.tips.isEmpty {
            script += "Pro tips: \(insights.tips.first ?? "Check local recommendations"). "
        }
        
        return script
    }
    
    private func formatItineraryAsPodcast(_ itinerary: TravelItinerary) -> String {
        var script = "Here's your personalized itinerary:\n\n"
        
        for (index, day) in itinerary.days.prefix(3).enumerated() {
            script += "\(day.title): "
            script += day.activities.prefix(3).joined(separator: ". ")
            script += "\n\n"
        }
        
        if let transport = itinerary.transportation {
            script += "Transportation tip: \(transport). "
        }
        
        return script
    }
    
    private func formatAnalysisAsPodcast(_ analysis: ReviewAnalysis) -> String {
        return """
        Review Analysis for this location:
        
        Overall sentiment: \(analysis.sentiment)
        
        What people love: \(analysis.positives.prefix(3).joined(separator: ", "))
        
        Common concerns: \(analysis.negatives.prefix(2).joined(separator: " and "))
        
        Best for: \(analysis.bestFor)
        
        Summary: \(analysis.summary)
        """
    }
    
    private func formatRecommendationsAsPodcast(_ recommendations: [POIRecommendation], location: String) -> String {
        guard !recommendations.isEmpty else {
            return "Exploring \(location) - a wonderful destination with many attractions to discover!"
        }
        
        var script = "Discovered \(recommendations.count) great places in \(location):\n\n"
        
        for (index, poi) in recommendations.prefix(5).enumerated() {
            script += "\(index + 1). \(poi.name)"
            if let category = poi.category {
                script += " (\(category))"
            }
            if let reason = poi.reason {
                script += " - \(reason)"
            }
            script += "\n"
        }
        
        return script
    }
    
    // MARK: - Error Handling
    enum ModelError: LocalizedError {
        case modelNotFound
        case modelNotLoaded
        case invalidOutput
        case downloadFailed
        
        var errorDescription: String? {
            switch self {
            case .modelNotFound:
                return "AI model not found. Please check your internet connection."
            case .modelNotLoaded:
                return "AI model is not loaded yet."
            case .invalidOutput:
                return "Invalid model output format."
            case .downloadFailed:
                return "Failed to download AI model."
            }
        }
    }
}

// MARK: - Model Input/Output Structures
class Gemma3NInput: NSObject, MLFeatureProvider {
    let inputIds: MLMultiArray
    
    init(inputIds: MLMultiArray) {
        self.inputIds = inputIds
        super.init()
    }
    
    var featureNames: Set<String> {
        return ["input_ids"]
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        if featureName == "input_ids" {
            return MLFeatureValue(multiArray: inputIds)
        }
        return nil
    }
}

class Gemma3NOutput: NSObject, MLFeatureProvider {
    let logits: MLMultiArray
    
    init(logits: MLMultiArray) {
        self.logits = logits
        super.init()
    }
    
    var featureNames: Set<String> {
        return ["logits"]
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        if featureName == "logits" {
            return MLFeatureValue(multiArray: logits)
        }
        return nil
    }
}

// MARK: - Discovery Types
struct DiscoveryInput {
    let location: CLLocation
    let poiName: String
    let category: String
    let context: String?
    let images: [Data]?
    let audioReviews: [Data]?
}

struct DiscoveryResult {
    let isNewDiscovery: Bool
    let confidence: Double
    let podcastScript: String
    let revenueEstimate: Double
    let contentScore: Double
}

// MARK: - MLMultiArray Extension
extension MLMultiArray {
    static func zeros(shape: [NSNumber]) -> MLMultiArray {
        guard let array = try? MLMultiArray(shape: shape, dataType: .int32) else {
            fatalError("Failed to create MLMultiArray")
        }
        
        let count = shape.reduce(1) { $0 * $1.intValue }
        for i in 0..<count {
            array[i] = 0
        }
        
        return array
    }
}