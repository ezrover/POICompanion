import SwiftUI
import UIKit
import CarPlay

// Main App with UIApplicationDelegate support for CarPlay
@main
struct RoadtripCopilotApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appStateManager = AppStateManager()
    @StateObject private var roadtripSession = RoadtripSession()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appStateManager)
                .environmentObject(roadtripSession)
        }
    }
}

// SceneDelegate for main app window
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        print("SceneDelegate: Main app scene connecting")
        
        // Create the SwiftUI view that provides the window contents
        let appStateManager = AppStateManager()
        let roadtripSession = RoadtripSession()
        
        let contentView = RootView()
            .environmentObject(appStateManager)
            .environmentObject(roadtripSession)

        // Use a UIHostingController as window root view controller
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
}

// AppDelegate for scene configuration
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        print("AppDelegate: Application did finish launching")
        
        // CRITICAL FIX: Check if CarPlay is already connected when app launches
        checkForExistingCarPlayConnection()
        
        return true
    }
    
    // MARK: - CarPlay Auto-Connection Fix
    
    private func checkForExistingCarPlayConnection() {
        print("AppDelegate: Checking for existing CarPlay connection")
        
        // Check if CarPlay scene is already active
        for scene in UIApplication.shared.connectedScenes {
            if scene.session.role == .carTemplateApplication {
                print("AppDelegate: Found existing CarPlay scene - posting connection notification")
                
                // Post notification that CarPlay is already connected
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .carPlayConnected, object: nil)
                    NotificationCenter.default.post(name: .carPlayAlreadyConnected, object: scene)
                }
                return
            }
        }
        
        print("AppDelegate: No existing CarPlay connection found")
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        print("AppDelegate: Configuring scene for role: \(connectingSceneSession.role.rawValue)")
        
        if (connectingSceneSession.role == UISceneSession.Role.carTemplateApplication) {
            print("AppDelegate: Creating CarPlay scene")
            
            // Post notification that CarPlay is connecting
            NotificationCenter.default.post(name: .carPlayConnected, object: nil)
            
            let scene = UISceneConfiguration(name: "CarPlay", sessionRole: connectingSceneSession.role)
            scene.delegateClass = CarPlaySceneDelegate.self
            return scene
        } else {
            print("AppDelegate: Creating Phone scene")
            let scene = UISceneConfiguration(name: "Phone", sessionRole: connectingSceneSession.role)
            scene.delegateClass = SceneDelegate.self
            return scene
        }
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        print("AppDelegate: Did discard scene sessions")
    }
}

struct RootView: View {
    @EnvironmentObject var appStateManager: AppStateManager
    @EnvironmentObject var roadtripSession: RoadtripSession
    @StateObject private var userPreferences = UserPreferences()
    @ObservedObject var locationManager = LocationManager.shared
    @State private var isLocationAuthorized = false
    
    var body: some View {
        Group {
            if !isLocationAuthorized {
                LocationAuthorizationView(isLocationAuthorized: $isLocationAuthorized)
            } else {
                switch appStateManager.currentScreen {
                case .loading:
                    SplashScreenView(onLoadingComplete: {
                        // Called when LLM is fully loaded
                        appStateManager.onLoadingComplete()
                    })
                case .destinationSelection:
                    EnhancedDestinationSelectionView(
                        savedDestinationName: nil // Always start fresh, no saved destinations
                    ) { selectedDestination, preferences in
                        appStateManager.startRoadtrip(to: selectedDestination)
                        
                        // Resume existing session or start new one
                        if roadtripSession.startTime != nil {
                            roadtripSession.resumeSession()
                        } else {
                            roadtripSession.startSession()
                        }
                        
                        // Store user preferences globally
                        userPreferences.searchRadius = preferences.searchRadius
                        userPreferences.distanceUnit = preferences.distanceUnit
                        userPreferences.selectedPOICategories = preferences.selectedPOICategories
                        userPreferences.savePreferences()
                    }
                    
                case .mainDashboard:
                    MainDashboardView()
                        .environmentObject(userPreferences)
                }
            }
        }
        .onAppear {
            // Check initial location authorization status
            checkLocationAuthorization()
            // NO simulation - SplashScreenView will handle real LLM loading
            // NO saved destination restoration - always start fresh
        }
        .onChange(of: locationManager.authorizationStatus) { status in
            checkLocationAuthorization()
        }
    }
    
    private func checkLocationAuthorization() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            isLocationAuthorized = true
        case .denied, .restricted, .notDetermined:
            isLocationAuthorized = false
        @unknown default:
            isLocationAuthorized = false
        }
    }
}