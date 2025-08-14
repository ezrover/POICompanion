package com.roadtrip.copilot.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.roadtrip.copilot.models.DestinationInfo
import com.roadtrip.copilot.models.DestinationSearchResult

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EnhancedDestinationSelectionScreen(
    onComplete: (DestinationSearchResult) -> Unit
) {
    var destinationText by remember { mutableStateOf("") }
    var isLoading by remember { mutableStateOf(false) }
    
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        // Title
        Text(
            text = "Where would you like to go?",
            fontSize = 28.sp,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.primary,
            modifier = Modifier.padding(bottom = 32.dp)
        )
        
        // Destination input
        OutlinedTextField(
            value = destinationText,
            onValueChange = { destinationText = it },
            label = { Text("Enter destination") },
            placeholder = { Text("e.g., Los Angeles, CA") },
            leadingIcon = {
                Icon(
                    imageVector = Icons.Default.LocationOn,
                    contentDescription = "Location"
                )
            },
            trailingIcon = {
                if (isLoading) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(20.dp),
                        strokeWidth = 2.dp
                    )
                } else {
                    Icon(
                        imageVector = Icons.Default.Search,
                        contentDescription = "Search"
                    )
                }
            },
            keyboardOptions = KeyboardOptions.Default.copy(
                imeAction = ImeAction.Done
            ),
            keyboardActions = KeyboardActions(
                onDone = {
                    if (destinationText.isNotBlank() && !isLoading) {
                        startRoadtrip(destinationText, onComplete) { isLoading = it }
                    }
                }
            ),
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 24.dp),
            enabled = !isLoading
        )
        
        // Start button
        Button(
            onClick = {
                if (destinationText.isNotBlank() && !isLoading) {
                    startRoadtrip(destinationText, onComplete) { isLoading = it }
                }
            },
            enabled = destinationText.isNotBlank() && !isLoading,
            modifier = Modifier
                .fillMaxWidth()
                .height(56.dp)
        ) {
            if (isLoading) {
                CircularProgressIndicator(
                    modifier = Modifier.size(20.dp),
                    color = MaterialTheme.colorScheme.onPrimary,
                    strokeWidth = 2.dp
                )
                Spacer(modifier = Modifier.width(8.dp))
            }
            Text(
                text = if (isLoading) "Setting up your trip..." else "Start Roadtrip",
                fontSize = 16.sp,
                fontWeight = FontWeight.Medium
            )
        }
        
        // Example destinations
        Spacer(modifier = Modifier.height(32.dp))
        Text(
            text = "Popular destinations:",
            fontSize = 14.sp,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(bottom = 8.dp)
        )
        
        val exampleDestinations = listOf(
            "Big Sur, CA",
            "Yellowstone National Park",
            "Route 66",
            "Blue Ridge Parkway"
        )
        
        exampleDestinations.forEach { destination ->
            TextButton(
                onClick = {
                    destinationText = destination
                },
                enabled = !isLoading
            ) {
                Text(
                    text = destination,
                    fontSize = 12.sp
                )
            }
        }
    }
}

private fun startRoadtrip(
    destinationText: String,
    onComplete: (DestinationSearchResult) -> Unit,
    setLoading: (Boolean) -> Unit
) {
    setLoading(true)
    
    // Simulate destination search and setup
    android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
        // Create a mock destination result
        val destinationResult = DestinationSearchResult(
            name = destinationText,
            latitude = 37.7749 + (Math.random() - 0.5) * 10, // Random location around SF
            longitude = -122.4194 + (Math.random() - 0.5) * 10,
            address = "$destinationText, USA"
        )
        
        setLoading(false)
        onComplete(destinationResult)
        
        println("Started roadtrip to: $destinationText")
    }, 2000) // 2 second delay to simulate loading
}