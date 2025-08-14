# API Specifications
## Roadtrip-Copilot Technical API Reference

**Version:** 1.0  
**Last Updated:** August 2025  
**Purpose:** Comprehensive API documentation for all platform integrations and services

---

## Table of Contents

1. [POI Discovery APIs](#poi-discovery-apis)
2. [Backend Service APIs](#backend-service-apis)
3. [Mobile Platform APIs](#mobile-platform-apis)
4. [Integration Requirements](#integration-requirements)
5. [Authentication & Security](#authentication--security)

---

## POI Discovery APIs

### Native Platform Integration

#### iOS - Apple MapKit & Places API

**Core Capabilities:**
- **Background Processing**: Continuous POI fetching while app is active
- **Geographic Coverage**: 5-mile radius scanning around user location
- **Discovery Validation**: Cross-reference with internal database for NEW discoveries
- **Privacy Compliance**: Location processing stays on-device
- **Battery Efficiency**: Optimized for minimal battery impact

```swift
import MapKit
import CoreLocation

class POIFetcher {
    // Categories covered by Apple MapKit:
    // - Restaurants & Food (.restaurant, .foodMarket, .bakery, .brewery, .cafe)
    // - Entertainment (.movieTheater, .museum, .nightlife, .amusementPark)
    // - Travel (.hotel, .gasStation, .evCharger, .airport, .publicTransport)
    // - Shopping (.store, .mall)
    // - Services (.hospital, .pharmacy, .bank, .postOffice)
    // - Recreation (.park, .beach, .campground, .fitnessCenter)
    // - Education (.school, .university, .library)
    
    func fetchNearbyPOIs(location: CLLocation, radius: Double = 8000) async throws -> [POI] {
        let request = MKLocalSearch.Request()
        request.region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: radius,
            longitudinalMeters: radius
        )
        request.resultTypes = [.pointOfInterest]
        
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        
        return response.mapItems.compactMap { mapItem in
            guard let name = mapItem.name,
                  let category = mapItem.pointOfInterestCategory else { return nil }
            
            return POI(
                id: UUID().uuidString,
                name: name,
                coordinate: mapItem.placemark.coordinate,
                category: category.rawValue,
                phoneNumber: mapItem.phoneNumber,
                url: mapItem.url,
                source: .appleMaps
            )
        }
    }
}
```

#### Android - Google Places API

```kotlin
import com.google.android.libraries.places.api.Places
import com.google.android.libraries.places.api.model.Place
import com.google.android.libraries.places.api.net.SearchNearbyRequest

class AndroidPOIFetcher {
    private val placesClient = Places.createClient(context)
    
    suspend fun fetchNearbyPOIs(
        location: LatLng, 
        radius: Double = 8000.0
    ): List<POI> = withContext(Dispatchers.IO) {
        
        val searchRequest = SearchNearbyRequest.builder(
            location,
            radius
        ).setPlaceFields(
            listOf(
                Place.Field.ID,
                Place.Field.NAME,
                Place.Field.LAT_LNG,
                Place.Field.PLACE_TYPES,
                Place.Field.PHONE_NUMBER,
                Place.Field.WEBSITE_URI,
                Place.Field.RATING,
                Place.Field.USER_RATINGS_TOTAL
            )
        ).build()
        
        val response = placesClient.searchNearby(searchRequest).await()
        
        response.places.map { place ->
            POI(
                id = place.id ?: UUID.randomUUID().toString(),
                name = place.name ?: "Unknown",
                coordinate = place.latLng,
                category = place.placeTypes?.firstOrNull()?.name ?: "Unknown",
                phoneNumber = place.phoneNumber,
                websiteUrl = place.websiteUri,
                rating = place.rating,
                userRatingsTotal = place.userRatingsTotal,
                source = POISource.GOOGLE_PLACES
            )
        }
    }
}
```

### Discovery Validation API

```typescript
interface DiscoveryValidationAPI {
    // Validate if POI is a new discovery
    validateDiscovery(candidate: POICandidate): Promise<ValidationResult>
    
    // Check similarity against existing database
    checkSimilarity(poi: POI, threshold: number = 0.85): Promise<SimilarityResult>
    
    // Cross-reference multiple data sources
    crossReference(poi: POI): Promise<CrossReferenceResult>
}

interface ValidationResult {
    isNewDiscovery: boolean
    confidence: number // 0-1 scale
    similarPOIs: POI[]
    validationReasons: string[]
    estimatedRevenue: RevenueEstimate
}
```

---

## Backend Service APIs

### Core REST Endpoints

#### Authentication Endpoints
```typescript
POST /auth/login
POST /auth/refresh
POST /auth/logout
GET  /auth/profile
PUT  /auth/profile
```

#### Discovery Management
```typescript
// POI Discovery
GET    /discoveries                 // List user discoveries
POST   /discoveries                 // Submit new discovery
GET    /discoveries/{id}            // Get discovery details
PUT    /discoveries/{id}            // Update discovery
DELETE /discoveries/{id}            // Remove discovery

// Discovery Validation
POST   /discoveries/validate        // Validate POI candidate
POST   /discoveries/claim           // Claim discovery ownership
GET    /discoveries/status/{id}     // Check validation status
```

#### Revenue Tracking
```typescript
// Earnings Management
GET  /earnings                      // User earnings summary
GET  /earnings/history             // Detailed earnings history
GET  /earnings/projections         // Revenue projections
POST /earnings/payout              // Request payout

// Content Performance
GET  /content/{id}/performance     // Content metrics
GET  /content/{id}/revenue         // Revenue attribution
POST /content/monetization         // Enable monetization
```

#### Content Generation
```typescript
// AI Content Creation
POST /content/generate             // Generate 6-second script
POST /content/podcast              // Create podcast episode
POST /content/video               // Generate video content
GET  /content/{id}/status         // Check generation status
```

### WebSocket Real-time APIs

```typescript
// Real-time Discovery Updates
ws://api.roadtrip-copilot.com/ws/discoveries

// Message Types
interface DiscoveryUpdate {
    type: 'discovery_validated' | 'revenue_update' | 'content_ready'
    discoveryId: string
    data: any
    timestamp: string
}

// Revenue Stream Updates
ws://api.roadtrip-copilot.com/ws/revenue

interface RevenueUpdate {
    type: 'earning_credited' | 'payout_processed' | 'milestone_reached'
    amount: number
    source: string
    timestamp: string
}
```

---

## Mobile Platform APIs

### iOS Platform Integrations

#### Core Location Framework
```swift
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    func requestLocationPermission() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization() // For background discovery
    }
    
    func startContinuousLocationUpdates() {
        locationManager.startUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges()
    }
}
```

#### Speech Framework Integration
```swift
import Speech

class VoiceRecognitionManager {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    
    func startVoiceRecognition() throws {
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        speechRecognizer?.recognitionTask(with: request) { result, error in
            // Handle recognition results
        }
    }
}
```

#### CarPlay Integration
```swift
import CarPlay

class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        let mapTemplate = CPMapTemplate()
        mapTemplate.automaticallyHidesNavigationBar = false
        
        // Add discovery monitoring
        mapTemplate.leadingNavigationBarButtons = [
            CPBarButton(type: .text, handler: { _ in
                // Start discovery mode
            })
        ]
        
        interfaceController.setRootTemplate(mapTemplate, animated: true)
    }
}
```

### Android Platform Integrations

#### Location Services
```kotlin
import com.google.android.gms.location.*

class AndroidLocationManager(private val context: Context) {
    private val fusedLocationClient = LocationServices.getFusedLocationProviderClient(context)
    
    fun startLocationUpdates() {
        val locationRequest = LocationRequest.create().apply {
            interval = 10000 // 10 seconds
            fastestInterval = 5000 // 5 seconds
            priority = LocationRequest.PRIORITY_HIGH_ACCURACY
        }
        
        fusedLocationClient.requestLocationUpdates(
            locationRequest,
            locationCallback,
            Looper.getMainLooper()
        )
    }
    
    private val locationCallback = object : LocationCallback() {
        override fun onLocationResult(locationResult: LocationResult) {
            locationResult.locations.forEach { location ->
                // Process location update for POI discovery
            }
        }
    }
}
```

#### Speech Recognition
```kotlin
import android.speech.SpeechRecognizer
import android.speech.RecognitionListener

class AndroidVoiceManager(private val context: Context) {
    private val speechRecognizer = SpeechRecognizer.createSpeechRecognizer(context)
    
    fun startVoiceRecognition() {
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, "en-US")
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
        }
        
        speechRecognizer.setRecognitionListener(object : RecognitionListener {
            override fun onResults(results: Bundle) {
                val matches = results.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                // Process voice recognition results
            }
        })
        
        speechRecognizer.startListening(intent)
    }
}
```

#### Android Auto Integration
```kotlin
import androidx.car.app.CarContext
import androidx.car.app.model.*

class AndroidAutoService : CarAppService() {
    override fun createHostValidator(): HostValidator {
        return HostValidator.ALLOW_ALL_HOSTS_VALIDATOR
    }
    
    override fun onCreateSession(): Session {
        return RoadtripSession()
    }
}

class RoadtripSession : Session() {
    override fun onCreateScreen(intent: Intent): Screen {
        return MapScreen(carContext)
    }
}

class MapScreen(carContext: CarContext) : Screen(carContext) {
    override fun onGetTemplate(): Template {
        return NavigationTemplate.Builder()
            .setActionStrip(
                ActionStrip.Builder()
                    .addAction(
                        Action.Builder()
                            .setTitle("Start Discovery")
                            .setOnClickListener { startDiscoveryMode() }
                            .build()
                    )
                    .build()
            )
            .build()
    }
    
    private fun startDiscoveryMode() {
        // Initialize discovery monitoring
    }
}
```

---

## Integration Requirements

### Real-time Data Synchronization

#### Requirements
- **Latency**: <200ms for critical updates
- **Reliability**: 99.9% uptime for real-time services
- **Scalability**: Support 100K+ concurrent connections
- **Data Consistency**: Eventual consistency with conflict resolution

#### Implementation
```typescript
// Real-time sync architecture
interface SyncManager {
    // Subscribe to real-time updates
    subscribe(channels: string[]): Promise<WebSocket>
    
    // Publish state changes
    publish(channel: string, data: any): Promise<void>
    
    // Handle conflict resolution
    resolveConflict(localState: any, remoteState: any): any
    
    // Offline queue management
    queueOfflineChanges(changes: any[]): void
    syncOfflineChanges(): Promise<SyncResult>
}
```

### Cross-Platform Data Exchange

```typescript
// Unified data models for cross-platform consistency
interface CrossPlatformPOI {
    id: string
    name: string
    coordinates: {
        latitude: number
        longitude: number
    }
    category: POICategory
    metadata: Record<string, any>
    source: 'apple_maps' | 'google_places' | 'user_generated'
    discoveryStatus: 'new' | 'existing' | 'validated' | 'earning'
    confidence: number
}

interface UnifiedAPIResponse<T> {
    data: T
    success: boolean
    error?: {
        code: string
        message: string
        details?: any
    }
    metadata: {
        timestamp: string
        platform: 'ios' | 'android' | 'web'
        version: string
    }
}
```

---

## Authentication & Security

### OAuth 2.0 + JWT Implementation

```typescript
// Authentication flow
interface AuthenticationAPI {
    // Social authentication
    loginWithApple(idToken: string): Promise<AuthResult>
    loginWithGoogle(idToken: string): Promise<AuthResult>
    
    // JWT token management
    refreshToken(refreshToken: string): Promise<TokenResponse>
    validateToken(accessToken: string): Promise<ValidationResult>
    
    // Session management
    createSession(userId: string): Promise<SessionInfo>
    invalidateSession(sessionId: string): Promise<void>
}

interface AuthResult {
    accessToken: string
    refreshToken: string
    expiresIn: number
    user: UserProfile
}
```

### API Security Headers

```typescript
// Required security headers for all API requests
const securityHeaders = {
    'Content-Security-Policy': "default-src 'self'",
    'X-Frame-Options': 'DENY',
    'X-Content-Type-Options': 'nosniff',
    'Referrer-Policy': 'no-referrer-when-downgrade',
    'Permissions-Policy': 'geolocation=(self)',
    'Strict-Transport-Security': 'max-age=31536000; includeSubDomains'
}
```

### Rate Limiting & Throttling

```typescript
// API rate limiting configuration
interface RateLimitConfig {
    anonymous: {
        requests: 100
        windowMs: 900000 // 15 minutes
    }
    authenticated: {
        requests: 1000
        windowMs: 900000 // 15 minutes
    }
    premium: {
        requests: 5000
        windowMs: 900000 // 15 minutes
    }
}
```

---

## Error Handling & Status Codes

### Standard HTTP Status Codes

| Code | Description | Usage |
|------|-------------|-------|
| 200 | OK | Successful request |
| 201 | Created | Resource created successfully |
| 400 | Bad Request | Invalid request parameters |
| 401 | Unauthorized | Authentication required |
| 403 | Forbidden | Access denied |
| 404 | Not Found | Resource not found |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Server error |
| 503 | Service Unavailable | Service temporarily unavailable |

### Error Response Format

```typescript
interface APIError {
    error: {
        code: string
        message: string
        details?: any
        timestamp: string
        requestId: string
    }
}

// Example error responses
const errors = {
    DISCOVERY_NOT_FOUND: {
        code: 'DISCOVERY_NOT_FOUND',
        message: 'The requested discovery could not be found'
    },
    INSUFFICIENT_PERMISSIONS: {
        code: 'INSUFFICIENT_PERMISSIONS',
        message: 'User does not have permission to perform this action'
    },
    VALIDATION_FAILED: {
        code: 'VALIDATION_FAILED',
        message: 'POI validation failed due to insufficient data'
    }
}
```

This comprehensive API specification provides developers with clear documentation for implementing all platform integrations and backend services while maintaining consistency across iOS, Android, CarPlay, and Android Auto platforms.