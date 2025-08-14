import SwiftUI
import AVFoundation
import Accelerate

struct VoiceVisualizerView: View {
    @ObservedObject var speechManager: SpeechManager
    @State private var waveformData: [Float] = Array(repeating: 0.3, count: 64)
    @State private var animationTimer: Timer?
    @State private var glowIntensity: Double = 0.5
    @State private var pulseScale: CGFloat = 1.0
    @State private var rotationAngle: Double = 0
    
    private let gradientColors = [
        Color.blue.opacity(0.8),
        Color.purple.opacity(0.6),
        Color.pink.opacity(0.4),
        Color.blue.opacity(0.8)
    ]
    
    var body: some View {
        ZStack {
            // Simplified background - no large circular shape for platform parity
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    RadialGradient(
                        colors: [
                            Color.black.opacity(0.7),
                            Color.blue.opacity(0.1),
                            Color.black.opacity(0.8)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .frame(width: 240, height: 160) // Smaller, more compact design
            
            // Outer glow rings
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.3),
                                Color.purple.opacity(0.2),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 200 + CGFloat(index * 20))
                    .opacity(speechManager.isListening || speechManager.isSpeaking ? 
                            (0.8 - Double(index) * 0.2) : 0.2)
                    .scaleEffect(pulseScale + CGFloat(index) * 0.05)
                    .animation(
                        .easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.3),
                        value: pulseScale
                    )
            }
            
            // Simplified central area - no large circular orb
            ZStack {
                
                // Dynamic waveform visualization
                if speechManager.isListening || speechManager.isSpeaking {
                    WaveformVisualizerView(
                        waveformData: $waveformData,
                        isListening: speechManager.isListening,
                        isSpeaking: speechManager.isSpeaking
                    )
                    .frame(width: 140, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 40))
                } else {
                    // Idle state with subtle pulse - smaller, no circle
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.blue.opacity(0.8),
                                    Color.blue.opacity(0.4)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 16, height: 16)
                        .scaleEffect(pulseScale)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                            value: pulseScale
                        )
                }
                
                // Microphone icon overlay (when listening)
                if speechManager.isListening {
                    Image(systemName: "mic.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .opacity(0.8)
                        .scaleEffect(1.2)
                        .offset(y: 60)
                }
            }
            .scaleEffect(speechManager.isListening || speechManager.isSpeaking ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: speechManager.isListening)
            .animation(.easeInOut(duration: 0.3), value: speechManager.isSpeaking)
            
            // Status text
            VStack {
                Spacer()
                
                if speechManager.isListening {
                    Text("Listening...")
                        .font(.headline)
                        .foregroundColor(.white)
                        .opacity(0.9)
                } else if speechManager.isSpeaking {
                    Text("Speaking...")
                        .font(.headline)
                        .foregroundColor(.white)
                        .opacity(0.9)
                } else {
                    Text("Tap to speak")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .opacity(0.7)
                }
                
                Spacer().frame(height: 40)
            }
        }
        .frame(width: 240, height: 160) // Smaller, more compact design
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
        .onChange(of: speechManager.isListening) { isListening in
            if isListening {
                startListeningAnimation()
            }
        }
        .onChange(of: speechManager.isSpeaking) { isSpeaking in
            if isSpeaking {
                startSpeakingAnimation()
            }
        }
        .onTapGesture {
            handleTap()
        }
    }
    
    private func startAnimation() {
        pulseScale = 1.0
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            updateWaveform()
            updateGlow()
        }
        
        // Start pulse animation
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.05
        }
    }
    
    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    private func startListeningAnimation() {
        // Simulate microphone input levels
        withAnimation(.easeInOut(duration: 0.1).repeatForever(autoreverses: false)) {
            updateWaveformForListening()
        }
    }
    
    private func startSpeakingAnimation() {
        // Simulate speech output levels
        withAnimation(.easeInOut(duration: 0.08).repeatForever(autoreverses: false)) {
            updateWaveformForSpeaking()
        }
    }
    
    private func updateWaveform() {
        let newData = waveformData.enumerated().map { index, _ in
            if speechManager.isListening {
                return Float.random(in: 0.2...0.9)
            } else if speechManager.isSpeaking {
                return Float.random(in: 0.3...1.0) * sin(Float(Date().timeIntervalSince1970 * 10 + Double(index)))
            } else {
                return Float.random(in: 0.1...0.3)
            }
        }
        
        waveformData = newData
    }
    
    private func updateWaveformForListening() {
        // Create more responsive listening animation
        for i in 0..<waveformData.count {
            waveformData[i] = Float.random(in: 0.2...0.8) * (1.0 + 0.3 * sin(Float(Date().timeIntervalSince1970 * 8 + Double(i) * 0.5)))
        }
    }
    
    private func updateWaveformForSpeaking() {
        // Create speaking animation with more variation
        let time = Date().timeIntervalSince1970
        for i in 0..<waveformData.count {
            let frequency = 5.0 + Double(i) * 0.1
            let amplitude = 0.5 + 0.4 * sin(time * 3 + Double(i) * 0.3)
            waveformData[i] = Float(0.3 + amplitude * sin(time * frequency))
        }
    }
    
    private func updateGlow() {
        let intensity = speechManager.isListening || speechManager.isSpeaking ? 1.0 : 0.3
        withAnimation(.easeInOut(duration: 0.5)) {
            glowIntensity = intensity + Double.random(in: -0.1...0.1)
        }
    }
    
    private func handleTap() {
        if speechManager.isListening {
            speechManager.stopListening()
        } else {
            speechManager.startListening()
        }
    }
}

struct WaveformVisualizerView: View {
    @Binding var waveformData: [Float]
    let isListening: Bool
    let isSpeaking: Bool
    
    private let barCount = 32
    private let barSpacing: CGFloat = 2
    
    var body: some View {
        HStack(alignment: .center, spacing: barSpacing) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: getBarColors(for: index),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 3, height: getBarHeight(for: index))
                    .animation(
                        .easeInOut(duration: 0.1)
                        .delay(Double(index) * 0.01),
                        value: waveformData[min(index, waveformData.count - 1)]
                    )
            }
        }
    }
    
    private func getBarHeight(for index: Int) -> CGFloat {
        let dataIndex = min(index * waveformData.count / barCount, waveformData.count - 1)
        let amplitude = CGFloat(waveformData[dataIndex])
        
        let baseHeight: CGFloat = 4
        let maxHeight: CGFloat = 60
        
        return baseHeight + (maxHeight - baseHeight) * amplitude
    }
    
    private func getBarColors(for index: Int) -> [Color] {
        let intensity = CGFloat(waveformData[min(index * waveformData.count / barCount, waveformData.count - 1)])
        
        if isListening {
            return [
                Color.blue.opacity(0.6 + intensity * 0.4),
                Color.cyan.opacity(0.8 + intensity * 0.2),
                Color.white.opacity(intensity)
            ]
        } else if isSpeaking {
            return [
                Color.purple.opacity(0.6 + intensity * 0.4),
                Color.pink.opacity(0.8 + intensity * 0.2),
                Color.white.opacity(intensity)
            ]
        } else {
            return [
                Color.gray.opacity(0.3),
                Color.gray.opacity(0.5),
                Color.gray.opacity(0.2)
            ]
        }
    }
}

// Usage in ContentView - replace the existing SpeechControlView
struct EnhancedSpeechControlView: View {
    @ObservedObject var speechManager: SpeechManager
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.8)
                .frame(width: 320, height: 320)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .blur(radius: 20)
            
            VoiceVisualizerView(speechManager: speechManager)
        }
    }
}

#Preview {
    VoiceVisualizerView(speechManager: SpeechManager())
        .preferredColorScheme(.dark)
}