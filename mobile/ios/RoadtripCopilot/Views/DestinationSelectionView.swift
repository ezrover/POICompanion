import SwiftUI
import MapKit

extension MKMapItem: @retroactive Identifiable {
    public var id: String {
        return "\(placemark.coordinate.latitude)-\(placemark.coordinate.longitude)-\(name ?? "unknown")"
    }
}
import CoreLocation

struct DestinationSelectionView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var speechManager = SpeechManager()
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var selectedDestination: MKMapItem?
    @State private var showingConfirmation = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // San Francisco default
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )
    
    let onDestinationSelected: (MKMapItem) -> Void
    
    var body: some View {
        ZStack {
            // Map View
            Map(coordinateRegion: $region, annotationItems: searchResults) { item in
                MapAnnotation(coordinate: item.placemark.coordinate) {
                    DestinationPin(
                        item: item,
                        isSelected: selectedDestination?.name == item.name
                    ) {
                        selectDestination(item)
                    }
                }
            }
            .ignoresSafeArea()
            
            // Overlay UI
            VStack {
                // Top Search Bar
                VStack(spacing: 16) {
                    Text("Where would you like to go?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search for destination...", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onSubmit {
                                searchForDestinations()
                            }
                        
                        Button(action: {
                            speechManager.startListening()
                        }) {
                            Image(systemName: speechManager.isListening ? "mic.fill" : "mic")
                                .font(.title2)
                                .foregroundColor(speechManager.isListening ? .red : .blue)
                                .scaleEffect(speechManager.isListening ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: speechManager.isListening)
                        }
                        .padding(.horizontal, 8)
                    }
                    .padding(.horizontal)
                }
                .background(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea(edges: .top)
                )
                
                Spacer()
                
                // Bottom Controls
                VStack(spacing: 16) {
                    // Voice Visualizer
                    if speechManager.isListening || speechManager.isSpeaking {
                        VStack {
                            if speechManager.isListening {
                                Text("Say your destination...")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            
                            if !speechManager.recognizedText.isEmpty {
                                Text("\"\(speechManager.recognizedText)\"")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                    .padding(.horizontal)
                            }
                            
                            DestinationVoiceVisualizerView(speechManager: speechManager)
                                .frame(height: 80)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                    
                    // Set Destination Button
                    Button(action: {
                        handleSetDestination()
                    }) {
                        HStack {
                            Image(systemName: "location.fill")
                                .font(.title2)
                            Text("Set Destination")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(selectedDestination != nil ? Color.blue : Color.gray)
                        )
                        .scaleEffect(selectedDestination != nil ? 1.0 : 0.95)
                        .animation(.easeInOut(duration: 0.2), value: selectedDestination != nil)
                    }
                    .disabled(selectedDestination == nil)
                    .padding(.horizontal)
                    
                    // Selected Destination Info
                    if let destination = selectedDestination {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(destination.name ?? "Selected Location")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            if let address = destination.placemark.title {
                                Text(address)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                .background(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea(edges: .bottom)
                )
            }
        }
        .onAppear {
            setupLocationAndSpeech()
        }
        .onChange(of: speechManager.recognizedText) { newText in
            if !newText.isEmpty {
                processVoiceInput(newText)
            }
        }
        .alert("Confirm Destination", isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) {
                selectedDestination = nil
            }
            Button("Start Roadtrip") {
                if let destination = selectedDestination {
                    onDestinationSelected(destination)
                }
            }
        } message: {
            if let destination = selectedDestination {
                Text("Ready to start your roadtrip to \(destination.name ?? "your destination")?")
            }
        }
    }
    
    private func setupLocationAndSpeech() {
        locationManager.startLocationUpdates()
        
        // Center map on current location when available
        if let location = locationManager.currentLocation {
            region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        }
        
        // Setup speech recognition for destination commands
        setupDestinationSpeechRecognition()
    }
    
    private func setupDestinationSpeechRecognition() {
        NotificationCenter.default.addObserver(
            forName: .voiceCommandReceived,
            object: nil,
            queue: .main
        ) { notification in
            if let command = notification.object as? String {
                processDestinationVoiceCommand(command)
            }
        }
    }
    
    private func processVoiceInput(_ input: String) {
        // Auto-search when voice input is recognized
        searchText = input
        searchForDestinations()
    }
    
    private func processDestinationVoiceCommand(_ command: String) {
        let lowercaseCommand = command.lowercased()
        
        if lowercaseCommand.contains("set destination") || 
           lowercaseCommand.contains("go to") ||
           lowercaseCommand.contains("navigate to") ||
           lowercaseCommand.contains("take me to") {
            
            // Extract destination from command
            let destinationQuery = extractDestinationFromCommand(command)
            if !destinationQuery.isEmpty {
                searchText = destinationQuery
                searchForDestinations()
                speechManager.speak("Searching for \(destinationQuery)")
            } else {
                speechManager.speak("Please say where you'd like to go")
                speechManager.startListening()
            }
        }
    }
    
    private func extractDestinationFromCommand(_ command: String) -> String {
        let lowercaseCommand = command.lowercased()
        
        let triggers = ["set destination to", "go to", "navigate to", "take me to", "drive to"]
        
        for trigger in triggers {
            if let range = lowercaseCommand.range(of: trigger) {
                let destination = String(command[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                return destination
            }
        }
        
        return ""
    }
    
    private func searchForDestinations() {
        guard !searchText.isEmpty else { return }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = region
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response, error == nil else {
                print("Search error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            DispatchQueue.main.async {
                self.searchResults = response.mapItems
                
                // Auto-select first result if we have results from voice
                if !self.searchResults.isEmpty && !speechManager.recognizedText.isEmpty {
                    selectDestination(self.searchResults[0])
                }
                
                // Update region to show results
                if let firstResult = self.searchResults.first {
                    self.region = MKCoordinateRegion(
                        center: firstResult.placemark.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                    )
                }
            }
        }
    }
    
    private func selectDestination(_ item: MKMapItem) {
        selectedDestination = item
        
        // Update region to center on selected destination
        region = MKCoordinateRegion(
            center: item.placemark.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        
        // Provide audio feedback
        speechManager.speak("Selected \(item.name ?? "destination")")
    }
    
    private func handleSetDestination() {
        guard selectedDestination != nil else { return }
        showingConfirmation = true
    }
}

// MARK: - Destination Pin Component
struct DestinationPin: View {
    let item: MKMapItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack {
                Image(systemName: isSelected ? "mappin.and.ellipse" : "mappin")
                    .font(.title)
                    .foregroundColor(isSelected ? .red : .blue)
                    .scaleEffect(isSelected ? 1.2 : 1.0)
                
                if isSelected {
                    Text(item.name ?? "Location")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.blue)
                        .cornerRadius(8)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isSelected)
    }
}

// MARK: - Simplified Voice Visualizer for Destination Screen
struct DestinationVoiceVisualizerView: View {
    @ObservedObject var speechManager: SpeechManager
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<8, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(speechManager.isListening ? Color.blue : Color.gray)
                    .frame(width: 4, height: speechManager.isListening ? CGFloat.random(in: 10...40) : 10)
                    .animation(.easeInOut(duration: 0.3).repeatForever(), value: speechManager.isListening)
            }
        }
        .frame(height: 50)
    }
}

#Preview {
    DestinationSelectionView { destination in
        print("Selected destination: \(destination.name ?? "Unknown")")
    }
}