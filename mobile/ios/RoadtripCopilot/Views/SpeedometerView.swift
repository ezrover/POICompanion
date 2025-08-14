import SwiftUI
import CoreLocation

// MARK: - Speedometer View Component

struct SpeedometerView: View {
    @ObservedObject var locationManager = LocationManager.shared
    @State private var speedUnit: SpeedUnit = .mph
    @State private var animationAmount: Double = 0.0
    
    // Animation and visual properties
    private let maxDisplaySpeed: Double = 120 // Maximum speed for gauge (mph)
    private let gaugeSize: CGSize = CGSize(width: 120, height: 120)
    
    var body: some View {
        VStack(spacing: 8) {
            // Main speedometer gauge
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    .frame(width: gaugeSize.width, height: gaugeSize.height)
                
                // Speed arc
                Circle()
                    .trim(from: 0, to: speedProgress)
                    .stroke(speedColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: gaugeSize.width, height: gaugeSize.height)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: speedProgress)
                
                // Center content
                VStack(spacing: 2) {
                    Text("\(Int(displaySpeed))")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.3), value: displaySpeed)
                    
                    Text(speedUnit.displayName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .onTapGesture {
                toggleSpeedUnit()
            }
            
            // Speed status indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(locationManager.isMoving ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.3), value: locationManager.isMoving)
                
                Text(locationManager.isMoving ? "Moving" : "Stationary")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Speed: \(locationManager.getFormattedSpeed(unit: speedUnit)), \(locationManager.isMoving ? "Moving" : "Stationary")")
        .accessibilityHint("Tap to change speed unit")
    }
    
    // MARK: - Computed Properties
    
    private var displaySpeed: Double {
        switch speedUnit {
        case .mph:
            return locationManager.currentSpeedMPH
        case .kmh:
            return locationManager.currentSpeedKMH
        case .mps:
            return locationManager.currentSpeed
        }
    }
    
    private var speedProgress: Double {
        let maxSpeed = speedUnit == .kmh ? maxDisplaySpeed * 1.6 : maxDisplaySpeed
        return min(displaySpeed / maxSpeed, 1.0)
    }
    
    private var speedColor: Color {
        let progress = speedProgress
        
        if progress < 0.3 {
            return .green
        } else if progress < 0.7 {
            return .orange
        } else {
            return .red
        }
    }
    
    // MARK: - Actions
    
    private func toggleSpeedUnit() {
        switch speedUnit {
        case .mph:
            speedUnit = .kmh
        case .kmh:
            speedUnit = .mps
        case .mps:
            speedUnit = .mph
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Compact Speedometer View

struct CompactSpeedometerView: View {
    @ObservedObject var locationManager = LocationManager.shared
    @State private var speedUnit: SpeedUnit = .mph
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "speedometer")
                .font(.caption)
                .foregroundColor(speedColor)
            
            Text("\(Int(displaySpeed))")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.3), value: displaySpeed)
            
            Text(speedUnit.displayName)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemBackground).opacity(0.8))
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .onTapGesture {
            toggleSpeedUnit()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Speed: \(locationManager.getFormattedSpeed(unit: speedUnit))")
        .accessibilityHint("Tap to change speed unit")
    }
    
    private var displaySpeed: Double {
        switch speedUnit {
        case .mph:
            return locationManager.currentSpeedMPH
        case .kmh:
            return locationManager.currentSpeedKMH
        case .mps:
            return locationManager.currentSpeed
        }
    }
    
    private var speedColor: Color {
        let speed = locationManager.currentSpeedMPH
        
        if speed < 25 {
            return .green
        } else if speed < 55 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func toggleSpeedUnit() {
        switch speedUnit {
        case .mph:
            speedUnit = .kmh
        case .kmh:
            speedUnit = .mps
        case .mps:
            speedUnit = .mph
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Speed Stats View

struct SpeedStatsView: View {
    @ObservedObject var locationManager = LocationManager.shared
    @State private var speedUnit: SpeedUnit = .mph
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Speed Stats")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(speedUnit.displayName) {
                    toggleSpeedUnit()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            VStack(spacing: 6) {
                SpeedStatRow(
                    title: "Current",
                    value: locationManager.getFormattedSpeed(unit: speedUnit),
                    color: .blue
                )
                
                SpeedStatRow(
                    title: "Average",
                    value: locationManager.getFormattedAverageSpeed(unit: speedUnit),
                    color: .green
                )
                
                SpeedStatRow(
                    title: "Maximum",
                    value: locationManager.getFormattedMaxSpeed(unit: speedUnit),
                    color: .red
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func toggleSpeedUnit() {
        switch speedUnit {
        case .mph:
            speedUnit = .kmh
        case .kmh:
            speedUnit = .mps
        case .mps:
            speedUnit = .mph
        }
    }
}

// MARK: - Speed Stat Row Component

private struct SpeedStatRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Preview

#Preview("Speedometer") {
    VStack(spacing: 20) {
        SpeedometerView()
        CompactSpeedometerView()
        SpeedStatsView()
    }
    .padding()
}

#Preview("Compact Speed Display") {
    CompactSpeedometerView()
        .padding()
}