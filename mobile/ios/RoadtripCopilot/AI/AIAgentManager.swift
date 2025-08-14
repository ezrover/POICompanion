import Foundation
import CoreLocation
import Combine

// MARK: - Temporary Core Definitions (should be moved to AICore.swift when added to project)

// MARK: - AI Agent Protocol

protocol AIAgent: AnyObject {
    var isRunning: Bool { get set }
    func start()
    func stop()
}

// MARK: - Agent Communication System

class AgentCommunicator {
    private var subscriptions: [AgentMessageType: [(AgentMessage) -> Void]] = [:]
    private let messageQueue = DispatchQueue(label: "com.roadtrip.agent-messages", qos: .userInitiated)
    
    func send(_ message: AgentMessage) {
        messageQueue.async { [weak self] in
            if let handlers = self?.subscriptions[message.type] {
                for handler in handlers {
                    handler(message)
                }
            }
        }
    }
    
    func subscribe(_ messageType: AgentMessageType, handler: @escaping (AgentMessage) -> Void) {
        messageQueue.async { [weak self] in
            if self?.subscriptions[messageType] == nil {
                self?.subscriptions[messageType] = []
            }
            self?.subscriptions[messageType]?.append(handler)
        }
    }
}

// MARK: - Message Types

enum AgentMessageType: CaseIterable {
    case poiDiscovered
    case reviewsProcessed
    case contentGenerated
    case locationAnalysisComplete
    case voiceCommandProcessed
    case userPreferenceUpdated
    case revenueTracked
    case referralTriggered
    case poiReadyForDisplay
}

struct AgentMessage {
    let type: AgentMessageType
    let source: String
    let data: Any
    let timestamp: Date = Date()
}

// MARK: - POI Data Model (imported from AppState.swift)

// MARK: - User Interaction Types

enum UserInteractionType {
    case favorite
    case like
    case dislike
    case skip
    case navigate
}

// MARK: - Location Analysis Data

struct LocationAnalysisData {
    let location: CLLocation
    let speed: Double
    let heading: Double
    let nearbyCategories: [String]
    let timeOfDay: String
    let weatherCondition: String?
    
    init(location: CLLocation, speed: Double = 0.0, heading: Double = 0.0, 
         nearbyCategories: [String] = [], timeOfDay: String = "day", 
         weatherCondition: String? = nil) {
        self.location = location
        self.speed = speed
        self.heading = heading
        self.nearbyCategories = nearbyCategories
        self.timeOfDay = timeOfDay
        self.weatherCondition = weatherCondition
    }
}

// MARK: - Generated Content Data

struct GeneratedContentData {
    let poiID: UUID
    let videoScript: String
    let audioContent: Data?
    let socialMediaPosts: [String: String]
    let estimatedRevenue: Double
    
    init(poiID: UUID, videoScript: String, audioContent: Data? = nil, 
         socialMediaPosts: [String: String] = [:], estimatedRevenue: Double = 0.0) {
        self.poiID = poiID
        self.videoScript = videoScript
        self.audioContent = audioContent
        self.socialMediaPosts = socialMediaPosts
        self.estimatedRevenue = estimatedRevenue
    }
}

// MARK: - Voice Command Data

struct VoiceCommandData {
    let command: String
    let intent: VoiceIntent
    let confidence: Double
    let parameters: [String: Any]
    
    init(command: String, intent: VoiceIntent = .unknown, confidence: Double = 0.0, 
         parameters: [String: Any] = [:]) {
        self.command = command
        self.intent = intent
        self.confidence = confidence
        self.parameters = parameters
    }
}

enum VoiceIntent {
    case favorite
    case like
    case dislike
    case skip
    case navigate
    case findCategory(String)
    case unknown
}

protocol ReviewDistillationAgent: AIAgent {
    func processReviews(for poi: POIData)
}

protocol ContentGenerationAgent: AIAgent {
    func generateContent(for poi: POIData)
}

protocol LocationAnalysisAgent: AIAgent {
    func processLocation(_ location: CLLocation)
}

protocol UserPreferenceAgent: AIAgent {
    func updatePreferences(from commandData: VoiceCommandData)
    func markAsFavorite(_ poi: POIData)
    func markAsLiked(_ poi: POIData)
    func markAsDisliked(_ poi: POIData)
}

protocol RevenueTrackingAgent: AIAgent {
    func trackContent(_ contentData: GeneratedContentData)
    func trackInteraction(_ interaction: UserInteractionType, for poi: POIData)
}

protocol ReferralAgent: AIAgent {}

protocol VoiceInteractionAgent: AIAgent {
    func processCommand(_ command: String)
}

class StubReviewDistillationAgent: ReviewDistillationAgent {
    var isRunning = false
    
    func start() {
        isRunning = true
        print("ReviewDistillationAgent started (stub)")
    }
    
    func stop() {
        isRunning = false
        print("ReviewDistillationAgent stopped (stub)")
    }
    
    func processReviews(for poi: POIData) {
        print("Processing reviews for \(poi.name) (stub)")
    }
}

class StubContentGenerationAgent: ContentGenerationAgent {
    var isRunning = false
    
    func start() {
        isRunning = true
        print("ContentGenerationAgent started (stub)")
    }
    
    func stop() {
        isRunning = false
        print("ContentGenerationAgent stopped (stub)")
    }
    
    func generateContent(for poi: POIData) {
        print("Generating content for \(poi.name) (stub)")
    }
}

class StubLocationAnalysisAgent: LocationAnalysisAgent {
    var isRunning = false
    
    func start() {
        isRunning = true
        print("LocationAnalysisAgent started (stub)")
    }
    
    func stop() {
        isRunning = false
        print("LocationAnalysisAgent stopped (stub)")
    }
    
    func processLocation(_ location: CLLocation) {
        print("Processing location: \(location.coordinate.latitude), \(location.coordinate.longitude) (stub)")
    }
}

class StubUserPreferenceAgent: UserPreferenceAgent {
    var isRunning = false
    
    func start() {
        isRunning = true
        print("UserPreferenceAgent started (stub)")
    }
    
    func stop() {
        isRunning = false
        print("UserPreferenceAgent stopped (stub)")
    }
    
    func updatePreferences(from commandData: VoiceCommandData) {
        print("Updating preferences from voice command: \(commandData.command) (stub)")
    }
    
    func markAsFavorite(_ poi: POIData) {
        print("Marking as favorite: \(poi.name) (stub)")
    }
    
    func markAsLiked(_ poi: POIData) {
        print("Marking as liked: \(poi.name) (stub)")
    }
    
    func markAsDisliked(_ poi: POIData) {
        print("Marking as disliked: \(poi.name) (stub)")
    }
}

class StubRevenueTrackingAgent: RevenueTrackingAgent {
    var isRunning = false
    
    func start() {
        isRunning = true
        print("RevenueTrackingAgent started (stub)")
    }
    
    func stop() {
        isRunning = false
        print("RevenueTrackingAgent stopped (stub)")
    }
    
    func trackContent(_ contentData: GeneratedContentData) {
        print("Tracking content for POI: \(contentData.poiID) (stub)")
    }
    
    func trackInteraction(_ interaction: UserInteractionType, for poi: POIData) {
        print("Tracking interaction \(interaction) for \(poi.name) (stub)")
    }
}

class StubReferralAgent: ReferralAgent {
    var isRunning = false
    
    func start() {
        isRunning = true
        print("ReferralAgent started (stub)")
    }
    
    func stop() {
        isRunning = false
        print("ReferralAgent stopped (stub)")
    }
}

class StubVoiceInteractionAgent: VoiceInteractionAgent {
    var isRunning = false
    
    func start() {
        isRunning = true
        print("VoiceInteractionAgent started (stub)")
    }
    
    func stop() {
        isRunning = false
        print("VoiceInteractionAgent stopped (stub)")
    }
    
    func processCommand(_ command: String) {
        print("Processing voice command: \(command) (stub)")
    }
}

// MARK: - AI Agent Manager
class AIAgentManager: ObservableObject {
    // Current POI state
    @Published var currentPOI: POIData?
    @Published var discoveredPOIs: [POIData] = []
    @Published var isDiscovering = false
    
    // Agent instances
    private let poiDiscoveryAgent: POIDiscoveryAgent
    private let reviewDistillationAgent: StubReviewDistillationAgent
    private let contentGenerationAgent: StubContentGenerationAgent
    private let locationAnalysisAgent: StubLocationAnalysisAgent
    private let userPreferenceAgent: StubUserPreferenceAgent
    private let revenueTrackingAgent: StubRevenueTrackingAgent
    private let referralAgent: StubReferralAgent
    private let voiceInteractionAgent: StubVoiceInteractionAgent
    
    // Agent communication system
    private let agentCommunicator = AgentCommunicator()
    private var cancellables = Set<AnyCancellable>()
    
    // Background queue for agent processing
    private let agentQueue = DispatchQueue(label: "com.roadtrip.agents", qos: .userInitiated)
    
    init() {
        // Initialize available agents
        self.poiDiscoveryAgent = POIDiscoveryAgent(communicator: agentCommunicator)
        self.reviewDistillationAgent = StubReviewDistillationAgent()
        self.contentGenerationAgent = StubContentGenerationAgent()
        self.locationAnalysisAgent = StubLocationAnalysisAgent()
        self.userPreferenceAgent = StubUserPreferenceAgent()
        self.revenueTrackingAgent = StubRevenueTrackingAgent()
        self.referralAgent = StubReferralAgent()
        self.voiceInteractionAgent = StubVoiceInteractionAgent()
        
        setupAgentCommunication()
        observeSystemEvents()
    }
    
    func startBackgroundAgents() {
        agentQueue.async { [weak self] in
            self?.poiDiscoveryAgent.start()
            self?.reviewDistillationAgent.start()
            self?.contentGenerationAgent.start()
            self?.locationAnalysisAgent.start()
            self?.userPreferenceAgent.start()
            self?.revenueTrackingAgent.start()
            self?.referralAgent.start()
            self?.voiceInteractionAgent.start()
            
            print("All AI agents started")
        }
    }
    
    func stopBackgroundAgents() {
        agentQueue.async { [weak self] in
            self?.poiDiscoveryAgent.stop()
            self?.reviewDistillationAgent.stop()
            self?.contentGenerationAgent.stop()
            self?.locationAnalysisAgent.stop()
            self?.userPreferenceAgent.stop()
            self?.revenueTrackingAgent.stop()
            self?.referralAgent.stop()
            self?.voiceInteractionAgent.stop()
            
            print("All AI agents stopped")
        }
    }
    
    // MARK: - Agent Communication Setup
    
    private func setupAgentCommunication() {
        // POI Discovery -> Review Distillation
        agentCommunicator.subscribe(.poiDiscovered) { [weak self] message in
            if let poiData = message.data as? POIData {
                self?.reviewDistillationAgent.processReviews(for: poiData)
            }
        }
        
        // Review Distillation -> Content Generation
        agentCommunicator.subscribe(.reviewsProcessed) { [weak self] message in
            if let poiData = message.data as? POIData {
                self?.contentGenerationAgent.generateContent(for: poiData)
            }
        }
        
        // Location Analysis -> POI Discovery
        agentCommunicator.subscribe(.locationAnalysisComplete) { [weak self] message in
            if let analysisData = message.data as? LocationAnalysisData {
                self?.poiDiscoveryAgent.updateSearchCriteria(analysisData)
            }
        }
        
        // Content Generation -> Revenue Tracking
        agentCommunicator.subscribe(.contentGenerated) { [weak self] message in
            if let contentData = message.data as? GeneratedContentData {
                self?.revenueTrackingAgent.trackContent(contentData)
            }
        }
        
        // Voice Interaction -> User Preference
        agentCommunicator.subscribe(.voiceCommandProcessed) { [weak self] message in
            if let commandData = message.data as? VoiceCommandData {
                self?.userPreferenceAgent.updatePreferences(from: commandData)
            }
        }
        
        // Final POI ready for display
        agentCommunicator.subscribe(.poiReadyForDisplay) { [weak self] message in
            DispatchQueue.main.async {
                if let poiData = message.data as? POIData {
                    self?.currentPOI = poiData
                    
                    // Notify CarPlay of POI change
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(
                            name: .currentPOIChanged, 
                            object: poiData
                        )
                    }
                    self?.discoveredPOIs.append(poiData)
                }
            }
        }
    }
    
    // MARK: - System Event Observers
    
    private func observeSystemEvents() {
        // Location updates
        NotificationCenter.default.publisher(for: .locationDidUpdate)
            .compactMap { $0.object as? CLLocation }
            .sink { [weak self] location in
                self?.locationAnalysisAgent.processLocation(location)
            }
            .store(in: &cancellables)
        
        // Voice commands
        NotificationCenter.default.publisher(for: .voiceCommandReceived)
            .compactMap { $0.object as? String }
            .sink { [weak self] command in
                self?.voiceInteractionAgent.processCommand(command)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - User Interaction Methods
    
    func favoriteCurrentPOI() {
        guard let poi = currentPOI else { return }
        
        agentQueue.async { [weak self] in
            self?.userPreferenceAgent.markAsFavorite(poi)
            self?.revenueTrackingAgent.trackInteraction(.favorite, for: poi)
        }
        
        print("Favorited POI: \(poi.name)")
    }
    
    func likeCurrentPOI() {
        guard let poi = currentPOI else { return }
        
        agentQueue.async { [weak self] in
            self?.userPreferenceAgent.markAsLiked(poi)
            self?.revenueTrackingAgent.trackInteraction(.like, for: poi)
        }
        
        print("Liked POI: \(poi.name)")
    }
    
    func dislikeCurrentPOI() {
        guard let poi = currentPOI else { return }
        
        agentQueue.async { [weak self] in
            self?.userPreferenceAgent.markAsDisliked(poi)
            self?.revenueTrackingAgent.trackInteraction(.dislike, for: poi)
        }
        
        print("Disliked POI: \(poi.name)")
        nextPOI() // Automatically move to next POI
    }
    
    func previousPOI() {
        guard !discoveredPOIs.isEmpty,
              let currentIndex = discoveredPOIs.firstIndex(where: { $0.id == currentPOI?.id }),
              currentIndex > 0 else { return }
        
        DispatchQueue.main.async {
            self.currentPOI = self.discoveredPOIs[currentIndex - 1]
            
            // Notify CarPlay
            NotificationCenter.default.post(
                name: .currentPOIChanged, 
                object: self.currentPOI
            )
        }
        
        print("Moved to previous POI")
    }
    
    func nextPOI() {
        guard !discoveredPOIs.isEmpty,
              let currentIndex = discoveredPOIs.firstIndex(where: { $0.id == currentPOI?.id }),
              currentIndex < discoveredPOIs.count - 1 else {
            
            // Request discovery of more POIs
            agentQueue.async { [weak self] in
                self?.poiDiscoveryAgent.discoverMorePOIs()
            }
            return
        }
        
        DispatchQueue.main.async {
            self.currentPOI = self.discoveredPOIs[currentIndex + 1]
            
            // Notify CarPlay
            NotificationCenter.default.post(
                name: .currentPOIChanged, 
                object: self.currentPOI
            )
        }
        
        print("Moved to next POI")
    }
    
    func processLocation(_ location: CLLocation) {
        agentQueue.async { [weak self] in
            self?.locationAnalysisAgent.processLocation(location)
        }
    }
}