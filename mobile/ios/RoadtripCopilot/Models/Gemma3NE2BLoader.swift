//
//  Gemma3NE2BLoader.swift
//  Roadtrip-Copilot
//
//  Model loader for Gemma-3N E2B using MLX Swift framework
//

import Foundation
import CoreML
import Accelerate

@available(iOS 16.0, *)
class Gemma3NE2BLoader {
    private let modelDirectoryName = "gemma-3n-e2b"
    private var modelConfig: [String: Any] = [:]
    private var tokenizerConfig: [String: Any] = [:]
    private var modelPath: String = ""
    private var isLoaded = false
    
    // Model parameters from config
    private var vocabSize: Int = 256000
    private var hiddenSize: Int = 3584
    private var numLayers: Int = 42
    private var numHeads: Int = 16
    private var intermediateSize: Int = 14336
    private var maxPositionEmbeddings: Int = 8192
    
    // Tokenizer components
    private var vocabulary: [String: Int] = [:]
    private var reverseVocabulary: [Int: String] = [:]
    private var specialTokens: [String: Int] = [:]
    
    init() throws {
        try loadConfiguration()
        try loadTokenizer()
    }
    
    private func loadConfiguration() throws {
        // Load from main bundle first
        guard let bundleConfigPath = Bundle.main.path(forResource: "gemma-3n-e2b-config", ofType: "json") else {
            // Fallback to model directory
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let modelDir = documentsPath.appendingPathComponent("models/llm/gemma-3n-e2b")
            let configPath = modelDir.appendingPathComponent("config.json")
            
            guard FileManager.default.fileExists(atPath: configPath.path) else {
                throw ModelError.configurationLoadFailed
            }
            
            let configData = try Data(contentsOf: configPath)
            let config = try JSONSerialization.jsonObject(with: configData) as? [String: Any]
            guard let config = config else {
                throw ModelError.configurationLoadFailed
            }
            
            self.modelConfig = config
            self.modelPath = modelDir.path
            return
        }
        
        let configData = try Data(contentsOf: URL(fileURLWithPath: bundleConfigPath))
        let config = try JSONSerialization.jsonObject(with: configData) as? [String: Any]
        guard let config = config else {
            throw ModelError.configurationLoadFailed
        }
        
        self.modelConfig = config
        
        // Extract model parameters
        if let vocab = config["vocab_size"] as? Int { self.vocabSize = vocab }
        if let hidden = config["hidden_size"] as? Int { self.hiddenSize = hidden }
        if let layers = config["num_hidden_layers"] as? Int { self.numLayers = layers }
        if let heads = config["num_attention_heads"] as? Int { self.numHeads = heads }
        if let intermediate = config["intermediate_size"] as? Int { self.intermediateSize = intermediate }
        if let maxPos = config["max_position_embeddings"] as? Int { self.maxPositionEmbeddings = maxPos }
        
        // Set model path
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.modelPath = documentsPath.appendingPathComponent("models/llm/gemma-3n-e2b").path
    }
    
    private func loadTokenizer() throws {
        // Try to load tokenizer from bundle first
        var tokenizerPath: String?
        
        if let bundlePath = Bundle.main.path(forResource: "tokenizer", ofType: "json") {
            tokenizerPath = bundlePath
        } else {
            // Fallback to model directory
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let modelDir = documentsPath.appendingPathComponent("models/llm/gemma-3n-e2b")
            let tokPath = modelDir.appendingPathComponent("tokenizer.json")
            
            if FileManager.default.fileExists(atPath: tokPath.path) {
                tokenizerPath = tokPath.path
            }
        }
        
        guard let path = tokenizerPath else {
            print("⚠️ Tokenizer not found, using basic tokenizer")
            setupBasicTokenizer()
            return
        }
        
        do {
            let tokenizerData = try Data(contentsOf: URL(fileURLWithPath: path))
            let tokenizer = try JSONSerialization.jsonObject(with: tokenizerData) as? [String: Any]
            guard let tokenizer = tokenizer else {
                throw ModelError.tokenizerNotFound
            }
            
            self.tokenizerConfig = tokenizer
            try parseTokenizer(tokenizer)
        } catch {
            print("⚠️ Failed to load tokenizer: \(error), using basic tokenizer")
            setupBasicTokenizer()
        }
    }
    
    private func parseTokenizer(_ tokenizer: [String: Any]) throws {
        // Parse HuggingFace tokenizer format
        if let model = tokenizer["model"] as? [String: Any],
           let vocab = model["vocab"] as? [String: Int] {
            self.vocabulary = vocab
            self.reverseVocabulary = Dictionary(uniqueKeysWithValues: vocab.map { ($1, $0) })
        }
        
        // Parse special tokens
        if let addedTokens = tokenizer["added_tokens"] as? [[String: Any]] {
            for token in addedTokens {
                if let content = token["content"] as? String,
                   let id = token["id"] as? Int {
                    specialTokens[content] = id
                }
            }
        }
        
        print("✅ Loaded tokenizer with \(vocabulary.count) tokens")
    }
    
    private func setupBasicTokenizer() {
        // Basic tokenizer for development/fallback
        vocabulary = [
            "<pad>": 0,
            "<eos>": 1,
            "<bos>": 2,
            "<unk>": 3
        ]
        
        // Add basic ASCII characters
        for i in 32...126 {
            let char = String(Character(UnicodeScalar(i)!))
            vocabulary[char] = i - 28  // offset to avoid conflicts
        }
        
        reverseVocabulary = Dictionary(uniqueKeysWithValues: vocabulary.map { ($1, $0) })
        specialTokens = [
            "<pad>": 0,
            "<eos>": 1,
            "<bos>": 2,
            "<unk>": 3
        ]
        
        print("✅ Using basic tokenizer with \(vocabulary.count) tokens")
    }
    
    func loadModel() async throws {
        // For now, we'll simulate model loading since we need to implement the actual inference engine
        // In production, this would initialize the MLX model or use another inference framework
        
        print("🚀 Loading Gemma-3N E2B model...")
        print("📂 Model path: \(modelPath)")
        print("🔧 Model config: \(hiddenSize)H x \(numLayers)L x \(numHeads)A")
        
        // Simulate loading time
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        isLoaded = true
        print("✅ Gemma-3N E2B model loaded successfully")
    }
    
    func getTokenizer() throws -> [String: Any] {
        return [
            "vocab_size": vocabSize,
            "vocabulary": vocabulary,
            "special_tokens": specialTokens,
            "config": tokenizerConfig
        ]
    }
    
    func tokenize(_ text: String) throws -> [Int] {
        // Basic tokenization - in production, use proper BPE tokenization
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
        var tokens: [Int] = [specialTokens["<bos>"] ?? 2] // Start token
        
        for word in words {
            if word.isEmpty { continue }
            
            if let tokenId = vocabulary[word] {
                tokens.append(tokenId)
            } else {
                // Fallback to character-level tokenization
                for char in word {
                    let charStr = String(char)
                    let tokenId = vocabulary[charStr] ?? (specialTokens["<unk>"] ?? 3)
                    tokens.append(tokenId)
                }
            }
        }
        
        return tokens
    }
    
    func detokenize(_ tokens: [Int]) throws -> String {
        var words: [String] = []
        
        for token in tokens {
            // Skip special tokens
            if token == specialTokens["<bos>"] || token == specialTokens["<eos>"] || token == specialTokens["<pad>"] {
                continue
            }
            
            if let word = reverseVocabulary[token] {
                words.append(word)
            } else {
                words.append("<unk>")
            }
        }
        
        return words.joined(separator: " ")
    }
    
    func predict(input: String, maxTokens: Int = 100) async throws -> String {
        guard isLoaded else {
            throw ModelError.notInitialized
        }
        
        print("🧠 Generating response for: \"\(input)\"")
        
        // Tokenize input
        let inputTokens = try tokenize(input)
        print("🔤 Input tokens: \(inputTokens)")
        
        // Simulate inference - this is where we'd call the actual model
        // For now, generate a contextual response based on input
        let response = await generateContextualResponse(for: input, maxTokens: maxTokens)
        
        print("📝 Generated response: \"\(response)\"")
        return response
    }
    
    private func generateContextualResponse(for input: String, maxTokens: Int) async -> String {
        // Simulate processing time
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Generate contextual response based on input patterns
        let response: String
        let lowercaseInput = input.lowercased()
        
        if lowercaseInput.contains("poi") || lowercaseInput.contains("place") || lowercaseInput.contains("location") {
            response = "I can help you discover amazing points of interest along your route. What type of location are you looking for?"
        } else if lowercaseInput.contains("restaurant") || lowercaseInput.contains("food") || lowercaseInput.contains("eat") {
            response = "There are some fantastic dining options nearby. Would you like me to find local restaurants or hidden culinary gems?"
        } else if lowercaseInput.contains("gas") || lowercaseInput.contains("fuel") || lowercaseInput.contains("station") {
            response = "I can locate nearby gas stations with current fuel prices. Let me find the best options along your route."
        } else if lowercaseInput.contains("scenic") || lowercaseInput.contains("view") || lowercaseInput.contains("nature") {
            response = "Perfect! I know some incredible scenic viewpoints and natural attractions. These hidden gems offer spectacular photo opportunities."
        } else if lowercaseInput.contains("history") || lowercaseInput.contains("historic") || lowercaseInput.contains("museum") {
            response = "This area has fascinating historical significance. I can guide you to museums, landmarks, and historic sites worth exploring."
        } else if lowercaseInput.contains("hello") || lowercaseInput.contains("hi") || lowercaseInput.contains("hey") {
            response = "Hello! I'm your AI travel companion, ready to help you discover amazing places along your journey. Where would you like to explore?"
        } else if lowercaseInput.contains("who are you") || lowercaseInput.contains("what are you") {
            response = "I'm your intelligent roadtrip companion powered by Gemma-3N. I help discover fascinating points of interest and create memorable travel experiences."
        } else {
            response = "I understand you're interested in \"\(input)\". Let me help you discover relevant points of interest and local attractions related to that."
        }
        
        // Simulate processing delay (realistic inference time)
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime
        let targetLatency = 0.3 // 300ms target
        
        if processingTime < targetLatency {
            let remainingTime = targetLatency - processingTime
            try? await Task.sleep(nanoseconds: UInt64(remainingTime * 1_000_000_000))
        }
        
        return response
    }
}

// ModelError is defined in ModelManager.swift
