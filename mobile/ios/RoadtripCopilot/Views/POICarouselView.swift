import SwiftUI
import Combine

struct POICarouselView: View {
    @StateObject private var viewModel = POICarouselViewModel()
    @State private var currentIndex = 0
    @State private var dragOffset: CGSize = .zero
    @State private var showReviews = false
    
    let pois: [POIItem]
    
    init(pois: [POIItem] = POICarouselViewModel.mockPOIs) {
        self.pois = pois
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.green.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    // POI Photo Carousel
                    TabView(selection: $currentIndex) {
                        ForEach(0..<viewModel.pois.count, id: \.self) { index in
                            POICardView(
                                poi: viewModel.pois[index],
                                photo: viewModel.photos[viewModel.pois[index].id],
                                reviews: viewModel.reviews[viewModel.pois[index].id] ?? []
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentIndex)
                    
                    // Navigation Controls
                    navigationControls
                        .padding()
                    
                    // Page Indicator
                    pageIndicator
                        .padding(.bottom, 20)
                }
            }
        }
        .onAppear {
            viewModel.loadPOIs(pois)
            viewModel.startFetchingData()
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Discovering")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Lost Lake, Oregon")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            Button(action: { showReviews.toggle() }) {
                Image(systemName: "text.bubble.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
    }
    
    private var navigationControls: some View {
        HStack(spacing: 50) {
            // Previous button
            Button(action: previousPOI) {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(currentIndex > 0 ? .blue : .gray.opacity(0.3))
            }
            .disabled(viewModel.pois.isEmpty)
            
            // Action buttons
            HStack(spacing: 30) {
                Button(action: { viewModel.navigateToPOI(at: currentIndex) }) {
                    VStack {
                        Image(systemName: "location.fill")
                            .font(.title)
                        Text("Navigate")
                            .font(.caption)
                    }
                }
                .foregroundColor(.green)
                
                Button(action: { viewModel.sharePOI(at: currentIndex) }) {
                    VStack {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title)
                        Text("Share")
                            .font(.caption)
                    }
                }
                .foregroundColor(.blue)
            }
            
            // Next button
            Button(action: nextPOI) {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(currentIndex < viewModel.pois.count - 1 ? .blue : .gray.opacity(0.3))
            }
            .disabled(viewModel.pois.isEmpty)
        }
    }
    
    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<viewModel.pois.count, id: \.self) { index in
                Circle()
                    .fill(index == currentIndex ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .scaleEffect(index == currentIndex ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3), value: currentIndex)
            }
        }
    }
    
    private func previousPOI() {
        withAnimation {
            if currentIndex > 0 {
                currentIndex -= 1
            } else {
                // Loop to last
                currentIndex = viewModel.pois.count - 1
            }
        }
        viewModel.logNavigation(to: currentIndex, direction: "previous")
    }
    
    private func nextPOI() {
        withAnimation {
            if currentIndex < viewModel.pois.count - 1 {
                currentIndex += 1
            } else {
                // Loop to first
                currentIndex = 0
            }
        }
        viewModel.logNavigation(to: currentIndex, direction: "next")
    }
}

// MARK: - POI Card View
struct POICardView: View {
    let poi: POIItem
    let photo: UIImage?
    let reviews: [Review]
    
    @State private var imageLoading = true
    
    var body: some View {
        VStack(spacing: 0) {
            // POI Photo
            ZStack {
                if let photo = photo {
                    Image(uiImage: photo)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 400)
                        .clipped()
                        .overlay(
                            LinearGradient(
                                colors: [Color.clear, Color.black.opacity(0.7)],
                                startPoint: .center,
                                endPoint: .bottom
                            )
                        )
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 400)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(1.5)
                        )
                }
                
                // POI Info Overlay
                VStack(alignment: .leading, spacing: 8) {
                    Spacer()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(poi.name)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            HStack {
                                Image(systemName: "location.fill")
                                    .font(.caption)
                                Text("\(poi.distance, specifier: "%.1f") miles")
                                    .font(.caption)
                            }
                            .foregroundColor(.white.opacity(0.9))
                            
                            if let rating = poi.rating {
                                HStack(spacing: 4) {
                                    ForEach(0..<5) { star in
                                        Image(systemName: star < Int(rating) ? "star.fill" : "star")
                                            .font(.caption)
                                            .foregroundColor(.yellow)
                                    }
                                    Text("(\(reviews.count) reviews)")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                        }
                        
                        Spacer()
                        
                        VStack {
                            Image(systemName: poi.categoryIcon)
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                    }
                    .padding()
                }
            }
            .cornerRadius(16)
            
            // POI Details
            VStack(alignment: .leading, spacing: 12) {
                Text(poi.description)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(3)
                
                // Top Review
                if let topReview = reviews.first {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "text.bubble.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                            Text("Top Review")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                        
                        Text(""\(topReview.text)"")
                            .font(.caption)
                            .italic()
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                        
                        Text("- \(topReview.author)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Tags
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(poi.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(16)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 10)
        .padding(.horizontal)
    }
}

// MARK: - View Model
class POICarouselViewModel: ObservableObject {
    @Published var pois: [POIItem] = []
    @Published var photos: [String: UIImage] = [:]
    @Published var reviews: [String: [Review]] = [:]
    @Published var isLoading = false
    
    private let toolRegistry = EnhancedToolRegistry()
    private var cancellables = Set<AnyCancellable>()
    
    func loadPOIs(_ items: [POIItem]) {
        self.pois = items
        print("📍 Loaded \(items.count) POIs for carousel")
    }
    
    func startFetchingData() {
        Task {
            await fetchPhotosAndReviews()
        }
    }
    
    @MainActor
    private func fetchPhotosAndReviews() async {
        isLoading = true
        
        for poi in pois {
            // Fetch photo
            if let photoTool = toolRegistry.getTool("fetch_poi_photo") {
                do {
                    let photoResult = try await photoTool.execute(parameters: [
                        "poi_name": poi.name,
                        "location": "Lost Lake, Oregon"
                    ])
                    
                    print("📸 Photo fetch result for \(poi.name): \(photoResult["status"] ?? "unknown")")
                    
                    // Mock photo loading
                    if let cachedPath = photoResult["cached_path"] as? String {
                        // In production, load actual image from cache
                        photos[poi.id] = UIImage(systemName: "photo.fill")
                    }
                } catch {
                    print("❌ Failed to fetch photo for \(poi.name): \(error)")
                }
            }
            
            // Fetch reviews
            if let reviewTool = toolRegistry.getTool("fetch_social_reviews") {
                do {
                    let reviewResult = try await reviewTool.execute(parameters: [
                        "poi_name": poi.name,
                        "location": "Lost Lake, Oregon",
                        "sources": ["tripadvisor", "yelp", "google"]
                    ])
                    
                    if let selectedReviews = reviewResult["selected_reviews"] as? [[String: Any]] {
                        let mappedReviews = selectedReviews.compactMap { Review(from: $0) }
                        reviews[poi.id] = mappedReviews
                        
                        print("📝 Fetched \(mappedReviews.count) reviews for \(poi.name)")
                        print("   Average rating: \(reviewResult["average_rating"] ?? 0)")
                    }
                } catch {
                    print("❌ Failed to fetch reviews for \(poi.name): \(error)")
                }
            }
        }
        
        isLoading = false
    }
    
    func navigateToPOI(at index: Int) {
        guard index < pois.count else { return }
        let poi = pois[index]
        print("🗺️ Navigating to: \(poi.name)")
        // Trigger navigation
    }
    
    func sharePOI(at index: Int) {
        guard index < pois.count else { return }
        let poi = pois[index]
        print("📤 Sharing: \(poi.name)")
        // Trigger share sheet
    }
    
    func logNavigation(to index: Int, direction: String) {
        guard index < pois.count else { return }
        let poi = pois[index]
        print("🔄 Navigated \(direction) to: \(poi.name) (index: \(index))")
    }
    
    // Mock data for testing
    static let mockPOIs: [POIItem] = [
        POIItem(
            id: "1",
            name: "Lost Lake Trail",
            category: "Hiking",
            distance: 0.1,
            rating: 4.5,
            description: "A scenic 3.4-mile loop trail around Lost Lake with stunning views of Mount Hood.",
            tags: ["Easy-Moderate", "Dog-Friendly", "Lake Views", "Photography"]
        ),
        POIItem(
            id: "2",
            name: "Lost Lake Resort",
            category: "Lodging",
            distance: 0.2,
            rating: 4.3,
            description: "Peaceful lakeside resort offering rustic cabins, boat rentals, and a general store.",
            tags: ["Cabins", "Boat Rental", "Restaurant", "WiFi"]
        ),
        POIItem(
            id: "3",
            name: "Tamanawas Falls Trail",
            category: "Hiking",
            distance: 8.7,
            rating: 4.7,
            description: "Moderate 3.6-mile hike to a spectacular 100-foot waterfall through old-growth forest.",
            tags: ["Waterfall", "Moderate", "Forest", "Photography"]
        )
    ]
}

// MARK: - Data Models
struct POIItem: Identifiable {
    let id: String
    let name: String
    let category: String
    let distance: Double
    let rating: Double?
    let description: String
    let tags: [String]
    
    var categoryIcon: String {
        switch category.lowercased() {
        case "hiking": return "figure.hiking"
        case "lodging": return "bed.double.fill"
        case "restaurant": return "fork.knife"
        case "camping": return "tent.fill"
        case "viewpoint": return "binoculars.fill"
        default: return "mappin.circle.fill"
        }
    }
}

struct Review {
    let author: String
    let rating: Double
    let text: String
    let date: String
    let source: String
    
    init?(from dictionary: [String: Any]) {
        guard let author = dictionary["author"] as? String,
              let rating = dictionary["rating"] as? Double,
              let text = dictionary["text"] as? String else {
            return nil
        }
        
        self.author = author
        self.rating = rating
        self.text = text
        self.date = dictionary["date"] as? String ?? ""
        self.source = dictionary["source"] as? String ?? ""
    }
}