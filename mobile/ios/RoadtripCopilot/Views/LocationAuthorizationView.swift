import SwiftUI
import CoreLocation

struct LocationAuthorizationView: View {
    @ObservedObject var locationManager = LocationManager.shared
    @Binding var isLocationAuthorized: Bool
    @State private var showingAlert = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // App Icon/Logo
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                VStack(spacing: 20) {
                    Text("Location Access Required")
                        .font(.title.weight(.bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Roadtrip-Copilot needs location access to discover points of interest and provide navigation assistance along your journey.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Text("This app cannot function without location permissions.")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Authorization Button
                Button(action: {
                    requestLocationPermission()
                }) {
                    HStack {
                        Image(systemName: "location.fill")
                        Text("Enable Location Access")
                    }
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                
                Text("Tap 'Allow' when prompted")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
        }
        .onAppear {
            checkLocationAuthorizationStatus()
        }
        .onChange(of: locationManager.authorizationStatus) { status in
            checkLocationAuthorizationStatus()
        }
        .alert("Location Access Required", isPresented: $showingAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Settings") {
                openAppSettings()
            }
        } message: {
            Text("Location access was denied. Please enable location permissions in Settings to use this app.")
        }
    }
    
    private func checkLocationAuthorizationStatus() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            isLocationAuthorized = true
        case .denied, .restricted:
            showingAlert = true
            isLocationAuthorized = false
        case .notDetermined:
            isLocationAuthorized = false
        @unknown default:
            isLocationAuthorized = false
        }
    }
    
    private func requestLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestLocationPermissions()
        case .denied, .restricted:
            // Show alert to go to settings
            showSettingsAlert()
        case .authorizedWhenInUse, .authorizedAlways:
            isLocationAuthorized = true
        @unknown default:
            showingAlert = true
        }
    }
    
    private func showSettingsAlert() {
        DispatchQueue.main.async {
            showingAlert = true
        }
    }
    
    private func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl, completionHandler: { success in
                print("Settings opened: \(success)")
            })
        }
    }
}

#Preview {
    LocationAuthorizationView(isLocationAuthorized: .constant(false))
}