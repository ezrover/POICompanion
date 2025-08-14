import SwiftUI
import MapKit

// MARK: - Destination Step

struct DestinationStepView: View {
    @Binding var searchText: String
    @Binding var searchResults: [MKMapItem]
    @Binding var selectedDestination: MKMapItem?
    @Binding var region: MKCoordinateRegion
    
    @ObservedObject var speechManager: SpeechManager
    @ObservedObject var locationManager: LocationManager
    
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("Where would you like to go?")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Map View
            Map(coordinateRegion: $region, annotationItems: searchResults) { item in
                MapAnnotation(coordinate: item.placemark.coordinate) {
                    DestinationPin(
                        item: item,
                        isSelected: selectedDestination?.name == item.name
                    ) {
                        selectedDestination = item
                        region = MKCoordinateRegion(
                            center: item.placemark.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        )
                    }
                }
            }
            .frame(height: 300)
            .cornerRadius(16)
            .padding(.horizontal)
            
            // Search Bar
            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search for destination...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Voice Button - Large for automotive use
                Button(action: {
                    if speechManager.isListening {
                        speechManager.stopListening()
                    } else {
                        speechManager.startListening()
                    }
                }) {
                    Image(systemName: speechManager.isListening ? "mic.fill" : "mic")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(speechManager.isListening ? Color.red : Color.blue)
                        )
                        .scaleEffect(speechManager.isListening ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: speechManager.isListening)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
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
                .background(Color(.systemBackground).opacity(0.9))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            
            // Next Button - Large for automotive use
            Button(action: onNext) {
                HStack {
                    Text("Next: Set Search Radius")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(selectedDestination != nil ? Color.blue : Color.gray)
                )
            }
            .disabled(selectedDestination == nil)
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Radius Step

struct RadiusStepView: View {
    @ObservedObject var userPreferences: UserPreferences
    @ObservedObject var speechManager: SpeechManager
    
    let onNext: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 16) {
                Text("Set your search radius")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("How far should we search for interesting places?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Current Selection Display - Large for automotive visibility
            VStack(spacing: 16) {
                Text("\(Int(userPreferences.searchRadius))")
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
                
                Text(userPreferences.distanceUnit.displayName)
                    .font(.title2)
                    .foregroundColor(.white)
            }
            .padding(.vertical, 30)
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground).opacity(0.9))
            .cornerRadius(20)
            .padding(.horizontal)
            
            // Distance Unit Toggle - Large buttons for automotive use
            HStack(spacing: 16) {
                ForEach(DistanceUnit.allCases, id: \.self) { unit in
                    Button(action: {
                        userPreferences.distanceUnit = unit
                    }) {
                        Text(unit.displayName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(userPreferences.distanceUnit == unit ? .white : .secondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(userPreferences.distanceUnit == unit ? Color.blue : Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.blue, lineWidth: 2)
                                    )
                            )
                    }
                }
            }
            .padding(.horizontal)
            
            // Radius Slider - Optimized for automotive use
            VStack(spacing: 16) {
                Slider(
                    value: $userPreferences.searchRadius,
                    in: 1...10,
                    step: 1
                ) {
                    Text("Search Radius")
                } minimumValueLabel: {
                    Text("1")
                        .font(.headline)
                        .foregroundColor(.white)
                } maximumValueLabel: {
                    Text("10")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .accentColor(.blue)
                .padding(.horizontal, 20)
                
                // Voice Input Hint
                HStack {
                    Image(systemName: "mic")
                        .foregroundColor(.blue)
                    Text("Say \"Set radius to 3 miles\" or tap and drag")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground).opacity(0.9))
            .cornerRadius(16)
            .padding(.horizontal)
            
            // Voice Button
            Button(action: {
                speechManager.startListening()
            }) {
                HStack {
                    Image(systemName: "mic")
                        .font(.title2)
                    Text("Set by Voice")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Navigation Buttons
            HStack(spacing: 16) {
                Button(action: onBack) {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("Back")
                    }
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(.systemBackground).opacity(0.9))
                    .cornerRadius(12)
                }
                
                Button(action: onNext) {
                    HStack {
                        Text("Next: Choose Interests")
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Category Step

struct CategoryStepView: View {
    @ObservedObject var userPreferences: UserPreferences
    @ObservedObject var speechManager: SpeechManager
    
    let onNext: () -> Void
    let onBack: () -> Void
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                Text("Choose your interests")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("What kinds of places interest you?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            
            // Quick Actions
            HStack(spacing: 12) {
                Button(action: userPreferences.selectAllCategories) {
                    Text("All")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(20)
                }
                
                Button(action: userPreferences.clearAllCategories) {
                    Text("Clear")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(.systemBackground).opacity(0.9))
                        .cornerRadius(20)
                }
                
                Spacer()
                
                Button(action: {
                    speechManager.startListening()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "mic")
                            .font(.caption)
                        Text("Voice")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .cornerRadius(16)
                }
            }
            .padding(.horizontal)
            
            // Categories Grid - Optimized for automotive touch targets
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(POICategory.allCases) { category in
                        CategoryButton(
                            category: category,
                            isSelected: userPreferences.selectedPOICategories.contains(category)
                        ) {
                            userPreferences.toggleCategory(category)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Selected Count
            Text("\(userPreferences.selectedPOICategories.count) categories selected")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            // Navigation Buttons
            HStack(spacing: 16) {
                Button(action: onBack) {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("Back")
                    }
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(.systemBackground).opacity(0.9))
                    .cornerRadius(12)
                }
                
                Button(action: onNext) {
                    HStack {
                        Text("Review Settings")
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(userPreferences.hasCategoriesSelected ? Color.blue : Color.gray)
                    .cornerRadius(12)
                }
                .disabled(!userPreferences.hasCategoriesSelected)
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Category Button Component

struct CategoryButton: View {
    let category: POICategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .secondary)
                
                Text(category.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color(.systemBackground).opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: isSelected ? 0 : 1)
                    )
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Confirmation Step

struct ConfirmationStepView: View {
    let selectedDestination: MKMapItem?
    @ObservedObject var userPreferences: UserPreferences
    
    let onConfirm: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Ready for your roadtrip?")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            // Settings Summary - Large cards for automotive visibility
            VStack(spacing: 20) {
                // Destination
                SettingsSummaryCard(
                    icon: "location.fill",
                    title: "Destination",
                    value: selectedDestination?.name ?? "Unknown",
                    color: .blue
                )
                
                // Search Radius
                SettingsSummaryCard(
                    icon: "circle",
                    title: "Search Radius",
                    value: userPreferences.searchRadiusText,
                    color: .green
                )
                
                // Categories
                SettingsSummaryCard(
                    icon: "list.bullet",
                    title: "Interests",
                    value: "\(userPreferences.selectedPOICategories.count) categories",
                    color: .purple
                )
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Action Buttons - Extra large for automotive use
            VStack(spacing: 16) {
                Button(action: onConfirm) {
                    HStack {
                        Image(systemName: "car")
                            .font(.title2)
                        Text("Start My Roadtrip!")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.blue)
                    )
                }
                
                Button(action: onBack) {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("Back to Categories")
                    }
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(.systemBackground).opacity(0.9))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Settings Summary Card

struct SettingsSummaryCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.2))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.9))
        .cornerRadius(16)
    }
}