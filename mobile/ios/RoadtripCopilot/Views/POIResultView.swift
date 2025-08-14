//
//  POIResultView.swift
//  RoadtripCopilot
//
//  Created by Claude Code on 2025-08-14
//  Platform Parity: iOS implementation matching Android POIResultScreen
//

import SwiftUI
import MapKit
import Foundation

struct POIResultView: View {
    let destination: MKMapItem
    let gemmaResponse: String
    let onComplete: () -> Void
    
    @StateObject private var ttsManager = EnhancedTTSManager()
    @State private var isReading = false
    @State private var hasSpokenResponse = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header with destination info
                    VStack(alignment: .leading, spacing: 12) {
                        Text(destination.name ?? "Destination")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        if let address = destination.placemark.title {
                            Text(address)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    )
                    
                    // AI Response Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .font(.title2)
                                .foregroundColor(.blue)
                            
                            Text("AI Information")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            // Audio indicator
                            if isReading {
                                HStack(spacing: 4) {
                                    ForEach(0..<3) { index in
                                        Circle()
                                            .fill(Color.blue)
                                            .frame(width: 6, height: 6)
                                            .scaleEffect(isReading ? 1.0 : 0.5)
                                            .animation(
                                                .easeInOut(duration: 0.5)
                                                .repeatForever()
                                                .delay(Double(index) * 0.2),
                                                value: isReading
                                            )
                                    }
                                }
                            }
                        }
                        
                        Text(gemmaResponse)
                            .font(.body)
                            .lineSpacing(4)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        // Audio Controls
                        HStack {
                            Button(action: {
                                if isReading {
                                    stopReading()
                                } else {
                                    startReading()
                                }
                            }) {
                                HStack {
                                    Image(systemName: isReading ? "pause.fill" : "play.fill")
                                        .font(.system(size: 16, weight: .medium))
                                    
                                    Text(isReading ? "Pause" : "Play Again")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.blue)
                                )
                            }
                            
                            Spacer()
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                    )
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            // Navigate to this destination
                            openInMaps()
                        }) {
                            HStack {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 18, weight: .medium))
                                
                                Text("Get Directions")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue)
                            )
                        }
                        
                        Button(action: onComplete) {
                            Text("Back to Search")
                                .font(.headline)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding()
                                // BORDERLESS DESIGN: Remove stroke border to comply with BORDERLESS BUTTON ENFORCEMENT
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Destination Info")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        onComplete()
                    }
                }
            }
        }
        .onAppear {
            // Auto-speak the response when screen loads
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if !hasSpokenResponse {
                    startReading()
                    hasSpokenResponse = true
                }
            }
        }
        .onDisappear {
            stopReading()
        }
        .onChange(of: ttsManager.isSpeaking) { speaking in
            isReading = speaking
        }
    }
    
    private func startReading() {
        ttsManager.speak(gemmaResponse, priority: .normal, context: .poiAnnouncement)
    }
    
    private func stopReading() {
        ttsManager.stopSpeaking()
    }
    
    private func openInMaps() {
        // Open destination in Apple Maps
        let mapItem = destination
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

#Preview {
    POIResultView(
        destination: MKMapItem(),
        gemmaResponse: "This is a beautiful destination with rich history and stunning views. Perfect for a family outing or romantic getaway.",
        onComplete: {}
    )
}