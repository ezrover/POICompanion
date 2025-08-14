package com.roadtrip.copilot.ui.screens

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import androidx.compose.ui.platform.LocalConfiguration
import android.content.res.Configuration
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LocationAuthorizationScreen(
    onLocationGranted: () -> Unit
) {
    val context = LocalContext.current
    val configuration = LocalConfiguration.current
    val isLandscape = configuration.orientation == Configuration.ORIENTATION_LANDSCAPE
    
    var showPermissionDialog by remember { mutableStateOf(false) }
    var showSettingsDialog by remember { mutableStateOf(false) }
    var showNotificationPermissionDialog by remember { mutableStateOf(false) }
    var showBackgroundLocationDialog by remember { mutableStateOf(false) }
    var permissionStep by remember { mutableStateOf(LocationPermissionStep.FOREGROUND_LOCATION) }
    
    // Foreground location permission launcher
    val foregroundLocationLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        val fineLocationGranted = permissions[Manifest.permission.ACCESS_FINE_LOCATION] ?: false
        val coarseLocationGranted = permissions[Manifest.permission.ACCESS_COARSE_LOCATION] ?: false
        
        if (fineLocationGranted || coarseLocationGranted) {
            // Check if we need notification permission for Android 13+
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                if (!hasNotificationPermission(context)) {
                    permissionStep = LocationPermissionStep.NOTIFICATION
                    showNotificationPermissionDialog = true
                    return@rememberLauncherForActivityResult
                }
            }
            
            // Check if we need background location for automotive features
            if (!hasBackgroundLocationPermission(context) && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                permissionStep = LocationPermissionStep.BACKGROUND_LOCATION
                showBackgroundLocationDialog = true
            } else {
                onLocationGranted()
            }
        } else {
            // Check if user selected "Don't ask again"
            val shouldShowRationale = (context as Activity).shouldShowRequestPermissionRationale(
                Manifest.permission.ACCESS_FINE_LOCATION
            )
            
            if (!shouldShowRationale) {
                showSettingsDialog = true
            } else {
                showPermissionDialog = true
            }
        }
    }
    
    // Notification permission launcher (Android 13+)
    val notificationLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission()
    ) { granted ->
        if (granted) {
            // Check if we need background location
            if (!hasBackgroundLocationPermission(context) && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                permissionStep = LocationPermissionStep.BACKGROUND_LOCATION
                showBackgroundLocationDialog = true
            } else {
                onLocationGranted()
            }
        } else {
            // Continue without notification permission but warn user
            if (!hasBackgroundLocationPermission(context) && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                permissionStep = LocationPermissionStep.BACKGROUND_LOCATION
                showBackgroundLocationDialog = true
            } else {
                onLocationGranted()
            }
        }
    }
    
    // Background location permission launcher
    val backgroundLocationLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission()
    ) { granted ->
        // Background location is optional for basic functionality
        onLocationGranted()
    }
    
    // Check current permission status
    LaunchedEffect(Unit) {
        when {
            !hasLocationPermission(context) -> {
                // Request foreground location permission first
                permissionStep = LocationPermissionStep.FOREGROUND_LOCATION
                requestLocationPermission(foregroundLocationLauncher)
            }
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && !hasNotificationPermission(context) -> {
                // Need notification permission for Android 13+
                permissionStep = LocationPermissionStep.NOTIFICATION
                showNotificationPermissionDialog = true
            }
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && !hasBackgroundLocationPermission(context) -> {
                // Need background location for full automotive features
                permissionStep = LocationPermissionStep.BACKGROUND_LOCATION
                showBackgroundLocationDialog = true
            }
            else -> {
                onLocationGranted()
            }
        }
    }
    
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
    ) {
        if (isLandscape) {
            // Landscape layout: content on left, buttons on right
            Row(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(24.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Left side: Location information
                Column(
                    modifier = Modifier
                        .weight(1f)
                        .padding(end = 24.dp)
                        .verticalScroll(rememberScrollState()),
                    verticalArrangement = Arrangement.Center
                ) {
                    // Icon and Title in a row
                    Row(
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Default.LocationOn,
                            contentDescription = "Location Icon",
                            modifier = Modifier.size(48.dp),
                            tint = MaterialTheme.colorScheme.primary
                        )
                        Spacer(modifier = Modifier.width(16.dp))
                        Text(
                            text = "Location Access Required",
                            fontSize = 20.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color.White
                        )
                    }
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    // Description
                    Text(
                        text = "Roadtrip-Copilot needs location access to discover points of interest and provide navigation assistance along your journey.",
                        fontSize = 14.sp,
                        color = Color.White.copy(alpha = 0.8f),
                        lineHeight = 20.sp
                    )
                    
                    Spacer(modifier = Modifier.height(12.dp))
                    
                    // Warning
                    Text(
                        text = "⚠️ This app cannot function without location permissions.",
                        fontSize = 12.sp,
                        color = MaterialTheme.colorScheme.error,
                        fontWeight = FontWeight.Medium
                    )
                    
                    Spacer(modifier = Modifier.height(12.dp))
                    
                    // Instructions
                    Text(
                        text = "Tap 'Allow' when the system permission dialog appears",
                        fontSize = 11.sp,
                        color = Color.White.copy(alpha = 0.6f)
                    )
                }
                
                // Right side: Buttons
                Column(
                    modifier = Modifier
                        .width(280.dp)
                        .verticalScroll(rememberScrollState()),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center
                ) {
                    // Enable Location Button
                    Button(
                        onClick = {
                            when (permissionStep) {
                                LocationPermissionStep.FOREGROUND_LOCATION -> {
                                    if (hasLocationPermission(context)) {
                                        onLocationGranted()
                                    } else {
                                        requestLocationPermission(foregroundLocationLauncher)
                                    }
                                }
                                LocationPermissionStep.NOTIFICATION -> {
                                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                        notificationLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                                    }
                                }
                                LocationPermissionStep.BACKGROUND_LOCATION -> {
                                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                        backgroundLocationLauncher.launch(Manifest.permission.ACCESS_BACKGROUND_LOCATION)
                                    }
                                }
                            }
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(48.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = MaterialTheme.colorScheme.primary
                        )
                    ) {
                        Row(
                            horizontalArrangement = Arrangement.Center,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                imageVector = when (permissionStep) {
                                    LocationPermissionStep.NOTIFICATION -> Icons.Default.Notifications
                                    else -> Icons.Default.LocationOn
                                },
                                contentDescription = null,
                                modifier = Modifier.size(18.dp)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = when (permissionStep) {
                                    LocationPermissionStep.FOREGROUND_LOCATION -> "Enable Location Access"
                                    LocationPermissionStep.NOTIFICATION -> "Enable Notifications"
                                    LocationPermissionStep.BACKGROUND_LOCATION -> "Enable Background Location"
                                },
                                fontSize = 14.sp,
                                fontWeight = FontWeight.SemiBold
                            )
                        }
                    }
                    
                    // Additional info based on permission step
                    if (permissionStep == LocationPermissionStep.BACKGROUND_LOCATION) {
                        Spacer(modifier = Modifier.height(12.dp))
                        Text(
                            text = "Choose 'Allow all the time' for best experience",
                            fontSize = 12.sp,
                            color = Color.White.copy(alpha = 0.7f),
                            textAlign = TextAlign.Center
                        )
                    }
                }
            }
        } else {
            // Portrait layout: original vertical layout
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(32.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                // App Icon
                Icon(
                    imageVector = Icons.Default.LocationOn,
                    contentDescription = "Location Icon",
                    modifier = Modifier.size(80.dp),
                    tint = MaterialTheme.colorScheme.primary
                )
                
                Spacer(modifier = Modifier.height(32.dp))
                
                // Title
                Text(
                    text = "Location Access Required",
                    fontSize = 24.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.White,
                    textAlign = TextAlign.Center
                )
                
                Spacer(modifier = Modifier.height(16.dp))
                
                // Description
                Text(
                    text = "Roadtrip-Copilot needs location access to discover points of interest and provide navigation assistance along your journey.",
                    fontSize = 16.sp,
                    color = Color.White.copy(alpha = 0.8f),
                    textAlign = TextAlign.Center,
                    lineHeight = 24.sp
                )
                
                Spacer(modifier = Modifier.height(16.dp))
                
                // Warning
                Text(
                    text = "This app cannot function without location permissions.",
                    fontSize = 14.sp,
                    color = MaterialTheme.colorScheme.error,
                    textAlign = TextAlign.Center,
                    fontWeight = FontWeight.Medium
                )
                
                Spacer(modifier = Modifier.height(48.dp))
                
                // Enable Location Button
                Button(
                    onClick = {
                        when (permissionStep) {
                            LocationPermissionStep.FOREGROUND_LOCATION -> {
                                if (hasLocationPermission(context)) {
                                    onLocationGranted()
                                } else {
                                    requestLocationPermission(foregroundLocationLauncher)
                                }
                            }
                            LocationPermissionStep.NOTIFICATION -> {
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                    notificationLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                                }
                            }
                            LocationPermissionStep.BACKGROUND_LOCATION -> {
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                    backgroundLocationLauncher.launch(Manifest.permission.ACCESS_BACKGROUND_LOCATION)
                                }
                            }
                        }
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(56.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = MaterialTheme.colorScheme.primary
                    )
                ) {
                    Row(
                        horizontalArrangement = Arrangement.Center,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Default.LocationOn,
                            contentDescription = null,
                            modifier = Modifier.size(20.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = when (permissionStep) {
                                LocationPermissionStep.FOREGROUND_LOCATION -> "Enable Location Access"
                                LocationPermissionStep.NOTIFICATION -> "Enable Notifications"
                                LocationPermissionStep.BACKGROUND_LOCATION -> "Enable Background Location"
                            },
                            fontSize = 16.sp,
                            fontWeight = FontWeight.SemiBold
                        )
                    }
                }
                
                Spacer(modifier = Modifier.height(16.dp))
                
                Text(
                    text = "Tap 'Allow' when prompted",
                    fontSize = 12.sp,
                    color = Color.White.copy(alpha = 0.6f),
                    textAlign = TextAlign.Center
                )
            }
        }
    }
    
    // Permission required dialog
    if (showPermissionDialog) {
        AlertDialog(
            onDismissRequest = { },
            title = {
                Text("Location Authorization Required")
            },
            text = {
                Text("Location authorization is required for this application to function. Please grant location access to continue.")
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        showPermissionDialog = false
                        requestLocationPermission(foregroundLocationLauncher)
                    }
                ) {
                    Text("OK")
                }
            },
            dismissButton = null // Force user to tap OK
        )
    }
    
    // Settings dialog when permission permanently denied
    if (showSettingsDialog) {
        AlertDialog(
            onDismissRequest = { },
            title = {
                Text("Location Authorization Required")
            },
            text = {
                Text("Location permission was denied. Please enable it in Settings to continue using the app.")
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        showSettingsDialog = false
                        openAppSettings(context)
                    }
                ) {
                    Text("Open Settings")
                }
            },
            dismissButton = null // Force user to take action
        )
    }
    
    // Notification permission dialog
    if (showNotificationPermissionDialog) {
        AlertDialog(
            onDismissRequest = { },
            icon = {
                Icon(
                    imageVector = Icons.Default.Notifications,
                    contentDescription = "Notifications",
                    tint = MaterialTheme.colorScheme.primary
                )
            },
            title = {
                Text("Notification Permission")
            },
            text = {
                Text("Notification access is required for location services to work properly in the background and provide trip updates.")
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        showNotificationPermissionDialog = false
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            notificationLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                        }
                    }
                ) {
                    Text("Allow")
                }
            },
            dismissButton = {
                TextButton(
                    onClick = {
                        showNotificationPermissionDialog = false
                        // Continue without notification permission
                        if (!hasBackgroundLocationPermission(context) && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            permissionStep = LocationPermissionStep.BACKGROUND_LOCATION
                            showBackgroundLocationDialog = true
                        } else {
                            onLocationGranted()
                        }
                    }
                ) {
                    Text("Skip")
                }
            }
        )
    }
    
    // Background location permission dialog
    if (showBackgroundLocationDialog) {
        AlertDialog(
            onDismissRequest = { },
            icon = {
                Icon(
                    imageVector = Icons.Default.LocationOn,
                    contentDescription = "Background Location",
                    tint = MaterialTheme.colorScheme.primary
                )
            },
            title = {
                Text("Background Location Access")
            },
            text = {
                Text("For the best roadtrip experience, allow location access 'All the time' to discover points of interest even when the app is in the background. You can choose 'While using app' for basic functionality.")
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        showBackgroundLocationDialog = false
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            backgroundLocationLauncher.launch(Manifest.permission.ACCESS_BACKGROUND_LOCATION)
                        }
                    }
                ) {
                    Text("Allow All Time")
                }
            },
            dismissButton = {
                TextButton(
                    onClick = {
                        showBackgroundLocationDialog = false
                        // Continue with foreground-only location
                        onLocationGranted()
                    }
                ) {
                    Text("While Using App")
                }
            }
        )
    }
}

private fun hasLocationPermission(context: Context): Boolean {
    return ContextCompat.checkSelfPermission(
        context,
        Manifest.permission.ACCESS_FINE_LOCATION
    ) == PackageManager.PERMISSION_GRANTED ||
    ContextCompat.checkSelfPermission(
        context,
        Manifest.permission.ACCESS_COARSE_LOCATION
    ) == PackageManager.PERMISSION_GRANTED
}

private fun requestLocationPermission(
    permissionLauncher: androidx.activity.result.ActivityResultLauncher<Array<String>>
) {
    permissionLauncher.launch(
        arrayOf(
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION
        )
    )
}

private fun openAppSettings(context: Context) {
    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
        data = Uri.fromParts("package", context.packageName, null)
    }
    context.startActivity(intent)
}

private fun hasNotificationPermission(context: Context): Boolean {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
        ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.POST_NOTIFICATIONS
        ) == PackageManager.PERMISSION_GRANTED
    } else {
        true // Not required for Android < 13
    }
}

private fun hasBackgroundLocationPermission(context: Context): Boolean {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
        ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_BACKGROUND_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
    } else {
        true // Background location bundled with foreground on Android < 10
    }
}

enum class LocationPermissionStep {
    FOREGROUND_LOCATION,
    NOTIFICATION,
    BACKGROUND_LOCATION
}