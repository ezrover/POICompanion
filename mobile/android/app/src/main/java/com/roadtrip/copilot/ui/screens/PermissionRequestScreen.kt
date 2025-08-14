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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import androidx.compose.ui.platform.LocalConfiguration
import android.content.res.Configuration

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PermissionRequestScreen(
    onAllPermissionsGranted: () -> Unit
) {
    val context = LocalContext.current
    val configuration = LocalConfiguration.current
    val isLandscape = configuration.orientation == Configuration.ORIENTATION_LANDSCAPE
    
    var currentPermissionStep by remember { mutableStateOf(PermissionStep.MICROPHONE) }
    var showPermissionRationale by remember { mutableStateOf(false) }
    var showSettingsDialog by remember { mutableStateOf(false) }
    var permanentlyDeniedPermissions by remember { mutableStateOf<List<String>>(emptyList()) }
    
    // Microphone permission launcher
    val microphonePermissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission()
    ) { granted ->
        if (granted) {
            // Move to location permissions
            currentPermissionStep = PermissionStep.LOCATION
        } else {
            // Check if permanently denied
            val shouldShowRationale = (context as Activity).shouldShowRequestPermissionRationale(
                Manifest.permission.RECORD_AUDIO
            )
            if (!shouldShowRationale) {
                permanentlyDeniedPermissions = permanentlyDeniedPermissions + Manifest.permission.RECORD_AUDIO
                showSettingsDialog = true
            } else {
                showPermissionRationale = true
            }
        }
    }
    
    // Location permissions launcher
    val locationPermissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        val fineLocationGranted = permissions[Manifest.permission.ACCESS_FINE_LOCATION] ?: false
        val coarseLocationGranted = permissions[Manifest.permission.ACCESS_COARSE_LOCATION] ?: false
        
        if (fineLocationGranted || coarseLocationGranted) {
            // Move to phone permission (required for calling POIs)
            currentPermissionStep = PermissionStep.PHONE
        } else {
            // Check if permanently denied
            val shouldShowRationale = (context as Activity).shouldShowRequestPermissionRationale(
                Manifest.permission.ACCESS_FINE_LOCATION
            )
            if (!shouldShowRationale) {
                permanentlyDeniedPermissions = permanentlyDeniedPermissions + 
                    listOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION)
                showSettingsDialog = true
            } else {
                showPermissionRationale = true
            }
        }
    }
    
    // Phone permission launcher
    val phonePermissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission()
    ) { granted ->
        if (granted) {
            // Check if we need notification permission (Android 13+)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                currentPermissionStep = PermissionStep.NOTIFICATION
            } else {
                // All required permissions granted
                onAllPermissionsGranted()
            }
        } else {
            // Phone permission is important but not critical - continue without it
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                currentPermissionStep = PermissionStep.NOTIFICATION
            } else {
                onAllPermissionsGranted()
            }
        }
    }
    
    // Notification permission launcher (Android 13+)
    val notificationPermissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission()
    ) { granted ->
        // Notification permission granted or not - continue to optional background location
        currentPermissionStep = PermissionStep.BACKGROUND_LOCATION
    }
    
    // Background location permission launcher (optional)
    val backgroundLocationLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission()
    ) { granted ->
        // All permissions handled - proceed to app
        onAllPermissionsGranted()
    }
    
    // Check current permissions and start with the first missing one
    LaunchedEffect(Unit) {
        when {
            !hasMicrophonePermission(context) -> {
                currentPermissionStep = PermissionStep.MICROPHONE
            }
            !hasLocationPermission(context) -> {
                currentPermissionStep = PermissionStep.LOCATION
            }
            !hasPhonePermission(context) -> {
                currentPermissionStep = PermissionStep.PHONE
            }
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && !hasNotificationPermission(context) -> {
                currentPermissionStep = PermissionStep.NOTIFICATION
            }
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && !hasBackgroundLocationPermission(context) -> {
                currentPermissionStep = PermissionStep.BACKGROUND_LOCATION
            }
            else -> {
                // All permissions already granted
                onAllPermissionsGranted()
            }
        }
    }
    
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            
            // Permission Step Card
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.surface
                )
            ) {
                if (isLandscape) {
                    // Landscape layout: text on left, buttons on right
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(24.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        // Left side: Text content
                        Column(
                            modifier = Modifier
                                .weight(1f)
                                .padding(end = 24.dp),
                            horizontalAlignment = Alignment.Start
                        ) {
                            // Permission Icon and Title in a row
                            Row(
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(
                                    imageVector = getCurrentPermissionIcon(currentPermissionStep),
                                    contentDescription = null,
                                    modifier = Modifier.size(48.dp),
                                    tint = MaterialTheme.colorScheme.primary
                                )
                                Spacer(modifier = Modifier.width(16.dp))
                                Text(
                                    text = getCurrentPermissionTitle(currentPermissionStep),
                                    fontSize = 20.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = MaterialTheme.colorScheme.onSurface
                                )
                            }
                            
                            Spacer(modifier = Modifier.height(16.dp))
                            
                            // Permission Description
                            Text(
                                text = getCurrentPermissionDescription(currentPermissionStep),
                                fontSize = 14.sp,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                lineHeight = 20.sp
                            )
                            
                            // Critical warning for required permissions
                            if (isPermissionCritical(currentPermissionStep)) {
                                Spacer(modifier = Modifier.height(8.dp))
                                Text(
                                    text = "⚠️ This permission is required for the app to function",
                                    fontSize = 12.sp,
                                    color = MaterialTheme.colorScheme.error,
                                    fontWeight = FontWeight.Medium
                                )
                            }
                            
                            Spacer(modifier = Modifier.height(8.dp))
                            
                            // Instructions
                            Text(
                                text = "Tap 'Allow' when the system permission dialog appears",
                                fontSize = 11.sp,
                                color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f)
                            )
                        }
                        
                        // Right side: Buttons
                        Column(
                            modifier = Modifier.width(240.dp),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            // Grant Permission Button
                            Button(
                                onClick = {
                                    when (currentPermissionStep) {
                                        PermissionStep.MICROPHONE -> {
                                            microphonePermissionLauncher.launch(Manifest.permission.RECORD_AUDIO)
                                        }
                                        PermissionStep.LOCATION -> {
                                            locationPermissionLauncher.launch(arrayOf(
                                                Manifest.permission.ACCESS_FINE_LOCATION,
                                                Manifest.permission.ACCESS_COARSE_LOCATION
                                            ))
                                        }
                                        PermissionStep.PHONE -> {
                                            phonePermissionLauncher.launch(Manifest.permission.CALL_PHONE)
                                        }
                                        PermissionStep.NOTIFICATION -> {
                                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                                notificationPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                                            }
                                        }
                                        PermissionStep.BACKGROUND_LOCATION -> {
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
                                        imageVector = getCurrentPermissionIcon(currentPermissionStep),
                                        contentDescription = null,
                                        modifier = Modifier.size(18.dp)
                                    )
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Text(
                                        text = getCurrentPermissionButtonText(currentPermissionStep),
                                        fontSize = 14.sp,
                                        fontWeight = FontWeight.SemiBold
                                    )
                                }
                            }
                            
                            // Skip button for optional permissions
                            if (!isPermissionCritical(currentPermissionStep)) {
                                Spacer(modifier = Modifier.height(8.dp))
                                TextButton(
                                    onClick = {
                                        when (currentPermissionStep) {
                                            PermissionStep.PHONE -> {
                                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                                    currentPermissionStep = PermissionStep.NOTIFICATION
                                                } else {
                                                    onAllPermissionsGranted()
                                                }
                                            }
                                            PermissionStep.NOTIFICATION -> {
                                                currentPermissionStep = PermissionStep.BACKGROUND_LOCATION
                                            }
                                            PermissionStep.BACKGROUND_LOCATION -> {
                                                onAllPermissionsGranted()
                                            }
                                            else -> { /* Critical permissions cannot be skipped */ }
                                        }
                                    }
                                ) {
                                    Text("Skip for now", fontSize = 14.sp)
                                }
                            }
                        }
                    }
                } else {
                    // Portrait layout: original vertical layout
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(24.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        
                        // Permission Icon
                        Icon(
                            imageVector = getCurrentPermissionIcon(currentPermissionStep),
                            contentDescription = null,
                            modifier = Modifier.size(80.dp),
                            tint = MaterialTheme.colorScheme.primary
                        )
                        
                        Spacer(modifier = Modifier.height(24.dp))
                        
                        // Permission Title
                        Text(
                            text = getCurrentPermissionTitle(currentPermissionStep),
                            fontSize = 24.sp,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onSurface,
                            textAlign = TextAlign.Center
                        )
                        
                        Spacer(modifier = Modifier.height(16.dp))
                        
                        // Permission Description
                        Text(
                            text = getCurrentPermissionDescription(currentPermissionStep),
                            fontSize = 16.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            textAlign = TextAlign.Center,
                            lineHeight = 24.sp
                        )
                        
                        Spacer(modifier = Modifier.height(8.dp))
                        
                        // Critical warning for required permissions
                        if (isPermissionCritical(currentPermissionStep)) {
                            Text(
                                text = "⚠️ This permission is required for the app to function",
                                fontSize = 14.sp,
                                color = MaterialTheme.colorScheme.error,
                                textAlign = TextAlign.Center,
                                fontWeight = FontWeight.Medium
                            )
                        }
                        
                        Spacer(modifier = Modifier.height(32.dp))
                        
                        // Grant Permission Button
                        Button(
                            onClick = {
                                when (currentPermissionStep) {
                                    PermissionStep.MICROPHONE -> {
                                        microphonePermissionLauncher.launch(Manifest.permission.RECORD_AUDIO)
                                    }
                                    PermissionStep.LOCATION -> {
                                        locationPermissionLauncher.launch(arrayOf(
                                            Manifest.permission.ACCESS_FINE_LOCATION,
                                            Manifest.permission.ACCESS_COARSE_LOCATION
                                        ))
                                    }
                                    PermissionStep.PHONE -> {
                                        phonePermissionLauncher.launch(Manifest.permission.CALL_PHONE)
                                    }
                                    PermissionStep.NOTIFICATION -> {
                                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                            notificationPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                                        }
                                    }
                                    PermissionStep.BACKGROUND_LOCATION -> {
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
                                    imageVector = getCurrentPermissionIcon(currentPermissionStep),
                                    contentDescription = null,
                                    modifier = Modifier.size(20.dp)
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(
                                    text = getCurrentPermissionButtonText(currentPermissionStep),
                                    fontSize = 16.sp,
                                    fontWeight = FontWeight.SemiBold
                                )
                            }
                        }
                        
                        // Skip button for optional permissions
                        if (!isPermissionCritical(currentPermissionStep)) {
                            Spacer(modifier = Modifier.height(12.dp))
                            
                            TextButton(
                                onClick = {
                                    when (currentPermissionStep) {
                                        PermissionStep.PHONE -> {
                                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                                currentPermissionStep = PermissionStep.NOTIFICATION
                                            } else {
                                                onAllPermissionsGranted()
                                            }
                                        }
                                        PermissionStep.NOTIFICATION -> {
                                            currentPermissionStep = PermissionStep.BACKGROUND_LOCATION
                                        }
                                        PermissionStep.BACKGROUND_LOCATION -> {
                                            onAllPermissionsGranted()
                                        }
                                        else -> { /* Critical permissions cannot be skipped */ }
                                    }
                                }
                            ) {
                                Text("Skip for now")
                            }
                        }
                        
                        Spacer(modifier = Modifier.height(16.dp))
                        
                        // Instructions
                        Text(
                            text = "Tap 'Allow' when the system permission dialog appears",
                            fontSize = 12.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f),
                            textAlign = TextAlign.Center
                        )
                    }
                }
            }
        }
    }
    
    // Permission rationale dialog
    if (showPermissionRationale) {
        AlertDialog(
            onDismissRequest = { /* Cannot dismiss */ },
            title = {
                Text("Permission Required")
            },
            text = {
                Text(
                    getCurrentPermissionRationaleText(currentPermissionStep)
                )
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        showPermissionRationale = false
                        // Retry the permission request
                        when (currentPermissionStep) {
                            PermissionStep.MICROPHONE -> {
                                microphonePermissionLauncher.launch(Manifest.permission.RECORD_AUDIO)
                            }
                            PermissionStep.LOCATION -> {
                                locationPermissionLauncher.launch(arrayOf(
                                    Manifest.permission.ACCESS_FINE_LOCATION,
                                    Manifest.permission.ACCESS_COARSE_LOCATION
                                ))
                            }
                            else -> { /* Other permissions handled above */ }
                        }
                    }
                ) {
                    Text("Try Again")
                }
            }
        )
    }
    
    // Settings dialog for permanently denied permissions
    if (showSettingsDialog) {
        AlertDialog(
            onDismissRequest = { /* Cannot dismiss */ },
            title = {
                Text("Permissions Required")
            },
            text = {
                Text(
                    "Required permissions were denied. Please enable them in Settings to continue using the app.\n\n" +
                    "Go to: Settings > Apps > Roadtrip-Copilot > Permissions"
                )
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
            }
        )
    }
}

// Helper functions for permission step information
private fun getCurrentPermissionIcon(step: PermissionStep): ImageVector {
    return when (step) {
        PermissionStep.MICROPHONE -> Icons.Default.Mic
        PermissionStep.LOCATION -> Icons.Default.LocationOn
        PermissionStep.PHONE -> Icons.Default.Phone
        PermissionStep.NOTIFICATION -> Icons.Default.Notifications
        PermissionStep.BACKGROUND_LOCATION -> Icons.Default.MyLocation
    }
}

private fun getCurrentPermissionTitle(step: PermissionStep): String {
    return when (step) {
        PermissionStep.MICROPHONE -> "Microphone Access"
        PermissionStep.LOCATION -> "Location Access"
        PermissionStep.PHONE -> "Phone Access"
        PermissionStep.NOTIFICATION -> "Notifications"
        PermissionStep.BACKGROUND_LOCATION -> "Background Location"
    }
}

private fun getCurrentPermissionDescription(step: PermissionStep): String {
    return when (step) {
        PermissionStep.MICROPHONE -> "Roadtrip-Copilot needs microphone access to listen to your voice commands and provide hands-free operation while driving."
        PermissionStep.LOCATION -> "Location access is required to discover points of interest and provide navigation assistance along your journey."
        PermissionStep.PHONE -> "Phone access allows you to call businesses and services at points of interest directly from the app."
        PermissionStep.NOTIFICATION -> "Notifications provide trip updates and location alerts even when the app is in the background."
        PermissionStep.BACKGROUND_LOCATION -> "Background location enables continuous discovery of points of interest even when the app is not actively in use."
    }
}

private fun getCurrentPermissionButtonText(step: PermissionStep): String {
    return when (step) {
        PermissionStep.MICROPHONE -> "Enable Microphone"
        PermissionStep.LOCATION -> "Enable Location"
        PermissionStep.PHONE -> "Enable Phone Access"
        PermissionStep.NOTIFICATION -> "Enable Notifications"
        PermissionStep.BACKGROUND_LOCATION -> "Enable Background Location"
    }
}

private fun getCurrentPermissionRationaleText(step: PermissionStep): String {
    return when (step) {
        PermissionStep.MICROPHONE -> "Microphone permission is essential for voice commands and hands-free operation. Without it, you won't be able to use voice features while driving safely."
        PermissionStep.LOCATION -> "Location permission is required for the app to function. We need to know your location to discover nearby points of interest and provide navigation assistance."
        PermissionStep.PHONE -> "Phone permission allows you to call businesses directly from the app. This is optional but recommended for the full experience."
        PermissionStep.NOTIFICATION -> "Notification permission allows the app to provide trip updates and location alerts in the background."
        PermissionStep.BACKGROUND_LOCATION -> "Background location permission enables continuous discovery even when the app is not active. This is optional but provides the best experience."
    }
}

private fun isPermissionCritical(step: PermissionStep): Boolean {
    return when (step) {
        PermissionStep.MICROPHONE -> true  // Critical for voice functionality
        PermissionStep.LOCATION -> true    // Critical for core functionality
        PermissionStep.PHONE -> false      // Optional
        PermissionStep.NOTIFICATION -> false  // Optional
        PermissionStep.BACKGROUND_LOCATION -> false  // Optional
    }
}

// Permission checking functions
private fun hasMicrophonePermission(context: Context): Boolean {
    return ContextCompat.checkSelfPermission(
        context,
        Manifest.permission.RECORD_AUDIO
    ) == PackageManager.PERMISSION_GRANTED
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

private fun hasPhonePermission(context: Context): Boolean {
    return ContextCompat.checkSelfPermission(
        context,
        Manifest.permission.CALL_PHONE
    ) == PackageManager.PERMISSION_GRANTED
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

private fun openAppSettings(context: Context) {
    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
        data = Uri.fromParts("package", context.packageName, null)
    }
    context.startActivity(intent)
}

enum class PermissionStep {
    MICROPHONE,
    LOCATION,
    PHONE,
    NOTIFICATION,
    BACKGROUND_LOCATION
}