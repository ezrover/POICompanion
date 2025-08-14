//
//  ModelManager.swift
//  Roadtrip-Copilot
//
//  Singleton manager for Gemma-3N model lifecycle
//

import Foundation
import Combine

@available(iOS 16.0, *)
class ModelManager: ObservableObject {
    static let shared = ModelManager()
    
    @Published var gemmaLoader: Gemma3NE2BLoader?
    @Published var isModelLoaded = false
    @Published var modelLoadError: Error?
    
    private init() {}
    
    func loadModel() async throws {
        do {
            gemmaLoader = try Gemma3NE2BLoader()
            
            // Load the actual model
            try await gemmaLoader!.loadModel()
            
            // TEST: Verify model works with a simple question
            print("🧪 [ModelManager] Testing Gemma-3N with verification prompt...")
            let testResponse = try await gemmaLoader!.predict(input: "who are you?", maxTokens: 50)
            print("✅ [ModelManager] Model test response: '\(testResponse)'")
            
            await MainActor.run {
                self.isModelLoaded = true
                self.modelLoadError = nil
            }
        } catch {
            await MainActor.run {
                self.modelLoadError = error
                self.isModelLoaded = false
            }
            throw error
        }
    }
    
    func predict(input: String, maxTokens: Int = 100) async throws -> String {
        guard let loader = gemmaLoader else {
            throw ModelError.notInitialized
        }
        return try await loader.predict(input: input, maxTokens: maxTokens)
    }
    
    func resetModel() {
        gemmaLoader = nil
        isModelLoaded = false
        modelLoadError = nil
    }
}

enum ModelError: LocalizedError {
    case notInitialized
    case configurationLoadFailed
    case modelPathNotFound
    case tokenizerNotFound
    case notImplemented(String)
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Model not initialized. Please restart the app."
        case .configurationLoadFailed:
            return "Failed to load model configuration"
        case .modelPathNotFound:
            return "Model path not found in configuration"
        case .tokenizerNotFound:
            return "Tokenizer not found"
        case .notImplemented(let message):
            return "Not implemented: \(message)"
        }
    }
}

// Fallback for iOS 15 and below
class ModelManagerLegacy: ObservableObject {
    static let shared = ModelManagerLegacy()
    
    @Published var isModelLoaded = false
    
    private init() {}
    
    func loadModel() async throws {
        // Simulate loading for older iOS versions
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        await MainActor.run {
            self.isModelLoaded = true
        }
    }
    
    func predict(input: String, maxTokens: Int = 100) async throws -> String {
        // Return placeholder response for older iOS versions
        return "AI response placeholder for: \(input)"
    }
}