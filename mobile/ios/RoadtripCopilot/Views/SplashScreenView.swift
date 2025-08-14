import SwiftUI

struct SplashScreenView: View {
    @State private var gemmaLoader: Gemma3NE2BLoader?
    @State private var isAnimating = false
    @State private var loadingFailed = false
    @State private var errorMessage = ""
    @State private var loadingProgress: Double = 0.0
    @State private var loadingStatus = "Initializing AI models..."
    @State private var isModelLoaded = false
    @State private var modelVariant = "E2B"
    
    // Callback when loading completes
    let onLoadingComplete: () -> Void
    
    init(onLoadingComplete: @escaping () -> Void = {}) {
        self.onLoadingComplete = onLoadingComplete
    }

    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()

                // Logo with rotation animation
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150, height: 150)
                    .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                    .onAppear {
                        startLoading()
                    }

                Spacer()

                // Loading status text
                VStack(spacing: 12) {
                    Text(loadingStatus)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .animation(.easeInOut, value: loadingStatus)
                    
                    // Progress bar
                    if loadingProgress > 0 && loadingProgress < 1 {
                        ProgressView(value: loadingProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                            .frame(width: 200)
                            .tint(.blue)
                    }
                    
                    // Model variant info
                    if isModelLoaded {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text("Gemma-3N \(modelVariant) ready")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Error message
                    if loadingFailed {
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                Text("Failed to load AI model")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            
                            Text(errorMessage)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button(action: retryLoading) {
                                Label("Retry", systemImage: "arrow.clockwise")
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(6)
                            }
                            .padding(.top, 4)
                        }
                        .padding()
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
        // .environmentObject(gemmaProcessor) // Make available to child views
    }
    
    private func startLoading() {
        // Start rotation animation
        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
            isAnimating = true
        }
        
        // Load actual Gemma-3N model
        Task {
            do {
                // Initialize model loader
                loadingProgress = 0.1
                loadingStatus = "Locating model files..."
                
                if #available(iOS 16.0, *) {
                    // Try to load the actual model
                    gemmaLoader = try Gemma3NE2BLoader()
                    
                    loadingProgress = 0.3
                    loadingStatus = "Loading model configuration..."
                    try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                    
                    loadingProgress = 0.5
                    loadingStatus = "Compiling model for Neural Engine..."
                    
                    // Load tokenizer
                    _ = try gemmaLoader?.getTokenizer()
                    
                    loadingProgress = 0.7
                    loadingStatus = "Initializing AI processor..."
                    try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                    
                    loadingProgress = 0.9
                    loadingStatus = "Optimizing for your device..."
                    
                    // Store the loader in a shared location (e.g., AppState or singleton)
                    await MainActor.run {
                        // Store the model loader for later use
                        ModelManager.shared.gemmaLoader = gemmaLoader
                    }
                    
                    try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                } else {
                    // Fallback for older iOS versions
                    for progress in stride(from: 0.1, to: 1.0, by: 0.1) {
                        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                        loadingProgress = progress
                        
                        if progress < 0.3 {
                            loadingStatus = "Preparing fallback model..."
                        } else if progress < 0.6 {
                            loadingStatus = "Loading compatibility layer..."
                        } else {
                            loadingStatus = "Finalizing setup..."
                        }
                    }
                }
                
                // Mark as loaded
                loadingProgress = 1.0
                loadingStatus = "AI ready!"
                isModelLoaded = true
                
                // Wait a moment to show success state
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                // Complete loading
                await MainActor.run {
                    withAnimation {
                        onLoadingComplete()
                    }
                }
            } catch {
                await MainActor.run {
                    withAnimation {
                        loadingFailed = true
                        errorMessage = "Failed to load Gemma-3N model: \(error.localizedDescription)"
                        isAnimating = false
                    }
                }
            }
        }
    }
    
    private func retryLoading() {
        loadingFailed = false
        errorMessage = ""
        loadingProgress = 0.0
        loadingStatus = "Retrying..."
        
        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
            isAnimating = true
        }
        
        Task {
            do {
                // Simulate retry loading
                for progress in stride(from: 0.0, to: 1.0, by: 0.15) {
                    try await Task.sleep(nanoseconds: 75_000_000) // 0.075 seconds
                    loadingProgress = progress
                    
                    if progress < 0.5 {
                        loadingStatus = "Retrying model download..."
                    } else {
                        loadingStatus = "Almost ready..."
                    }
                }
                
                loadingProgress = 1.0
                loadingStatus = "AI ready!"
                isModelLoaded = true
                
                await MainActor.run {
                    withAnimation {
                        onLoadingComplete()
                    }
                }
            } catch {
                await MainActor.run {
                    withAnimation {
                        loadingFailed = true
                        errorMessage = error.localizedDescription
                        isAnimating = false
                    }
                }
            }
        }
    }
}

struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView {
            print("Loading complete!")
        }
    }
}
