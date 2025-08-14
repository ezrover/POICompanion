package com.roadtrip.copilot.managers

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.os.Build
import android.os.Looper
import androidx.core.content.ContextCompat
import androidx.lifecycle.ViewModel
import com.google.android.gms.location.*
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject

@HiltViewModel
class LocationManager @Inject constructor(
    @ApplicationContext private val context: Context
) : ViewModel() {
    
    private val fusedLocationClient: FusedLocationProviderClient = LocationServices.getFusedLocationProviderClient(context)
    
    private val _currentLocation = MutableStateFlow<Location?>(null)
    val currentLocation: StateFlow<Location?> = _currentLocation.asStateFlow()
    
    private val _currentCity = MutableStateFlow<String?>(null)
    val currentCity: StateFlow<String?> = _currentCity.asStateFlow()
    
    private val _currentState = MutableStateFlow<String?>(null)
    val currentState: StateFlow<String?> = _currentState.asStateFlow()
    
    private val _isLocationEnabled = MutableStateFlow(false)
    val isLocationEnabled: StateFlow<Boolean> = _isLocationEnabled.asStateFlow()
    
    private val _isBackgroundLocationEnabled = MutableStateFlow(false)
    val isBackgroundLocationEnabled: StateFlow<Boolean> = _isBackgroundLocationEnabled.asStateFlow()
    
    private val _locationError = MutableStateFlow<String?>(null)
    val locationError: StateFlow<String?> = _locationError.asStateFlow()
    
    private var locationCallback: LocationCallback? = null
    private var locationRequest: LocationRequest? = null
    
    init {
        setupLocationRequest()
    }
    
    
    private fun setupLocationRequest() {
        locationRequest = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, 5000L)
            .setMinUpdateIntervalMillis(2000L)
            .setMaxUpdateAgeMillis(10000L)
            .build()
        
        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                locationResult.lastLocation?.let { location ->
                    _currentLocation.value = location
                    _locationError.value = null // Clear any previous errors
                    updateLocationInfo(location)
                    println("✅ Location updated: ${location.latitude}, ${location.longitude}")
                }
            }
            
            override fun onLocationAvailability(locationAvailability: LocationAvailability) {
                val isAvailable = locationAvailability.isLocationAvailable
                _isLocationEnabled.value = isAvailable
                
                if (!isAvailable) {
                    _locationError.value = "Location services are not available. Please enable GPS and try again."
                    println("❌ Location services unavailable")
                } else {
                    _locationError.value = null
                    println("✅ Location services available")
                }
            }
        }
    }
    
    private fun updateLocationInfo(location: Location) {
        // In a real app, you would use Geocoder to get city and state
        // For now, we'll simulate this with placeholder data
        _currentCity.value = "Current City"
        _currentState.value = "CA"
    }
    
    fun startLocationUpdates() {
        if (hasLocationPermission()) {
            try {
                locationRequest?.let { request ->
                    locationCallback?.let { callback ->
                        fusedLocationClient.requestLocationUpdates(
                            request,
                            callback,
                            Looper.getMainLooper()
                        )
                        _isLocationEnabled.value = true
                        println("Location updates started successfully")
                        
                        // Get initial location
                        getCurrentLocation()
                    }
                }
            } catch (securityException: SecurityException) {
                _locationError.value = "Location permission not granted. Please enable location access in settings."
                _isLocationEnabled.value = false
                println("❌ Location permission not granted: ${securityException.message}")
            }
        } else {
            _locationError.value = "Location permission required. Please grant location access to continue."
            _isLocationEnabled.value = false
            println("❌ Location permission not granted - cannot start location updates")
        }
    }
    
    fun stopLocationUpdates() {
        locationCallback?.let { callback ->
            fusedLocationClient.removeLocationUpdates(callback)
            _isLocationEnabled.value = false
            println("Location updates stopped")
        }
    }
    
    fun enableBackgroundLocationUpdates() {
        if (hasBackgroundLocationPermission()) {
            _isBackgroundLocationEnabled.value = true
            println("✅ Background location updates enabled")
        } else {
            println("❌ Background location permission not granted")
        }
    }
    
    fun clearLocationError() {
        _locationError.value = null
    }
    
    fun checkAndRequestLocationUpdates() {
        if (hasLocationPermission()) {
            startLocationUpdates()
        } else {
            _locationError.value = "Location permission required. Please grant location access."
        }
    }
    
    fun disableBackgroundLocationUpdates() {
        _isBackgroundLocationEnabled.value = false
        println("Background location updates disabled")
    }
    
    fun getCurrentLocation() {
        if (hasLocationPermission()) {
            try {
                fusedLocationClient.lastLocation
                    .addOnSuccessListener { location ->
                        location?.let {
                            _currentLocation.value = it
                            updateLocationInfo(it)
                            println("Got last known location: ${it.latitude}, ${it.longitude}")
                        }
                    }
                    .addOnFailureListener { exception ->
                        println("Failed to get location: ${exception.message}")
                    }
            } catch (securityException: SecurityException) {
                println("Location permission not granted: ${securityException.message}")
            }
        }
    }
    
    private fun hasLocationPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED || ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_COARSE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
    }
    
    private fun hasBackgroundLocationPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_BACKGROUND_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
    }
    
    fun getDistanceTo(latitude: Double, longitude: Double): Float? {
        return _currentLocation.value?.let { current ->
            val destination = Location("destination").apply {
                this.latitude = latitude
                this.longitude = longitude
            }
            current.distanceTo(destination)
        }
    }
    
    override fun onCleared() {
        super.onCleared()
        stopLocationUpdates()
    }
}