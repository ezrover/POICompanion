package com.roadtrip.copilot.ui.screens

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import com.roadtrip.copilot.design.DesignTokens
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.MapView
import com.google.android.gms.maps.model.*
import com.roadtrip.copilot.managers.*
import com.roadtrip.copilot.models.*
import kotlinx.coroutines.delay

// MARK: - Destination Step Content

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DestinationStepContent(
    searchQuery: String,
    onSearchQueryChange: (String) -> Unit,
    searchResults: List<DestinationSearchResult>,
    selectedDestination: DestinationSearchResult?,
    onDestinationSelected: (DestinationSearchResult) -> Unit,
    googleMap: GoogleMap?,
    onMapReady: (GoogleMap) -> Unit,
    speechManager: SpeechManager,
    onNext: () -> Unit
) {
    val isListening by speechManager.isListening.collectAsState()
    
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
            .padding(16.dp)
    ) {
        // Title
        Text(
            text = "Where would you like to go?",
            fontSize = 24.sp,
            fontWeight = FontWeight.Bold,
            color = Color.White,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth()
        )
        
        Spacer(modifier = Modifier.height(20.dp))
        
        // Search Row with Voice - Large buttons for automotive
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            OutlinedTextField(
                value = searchQuery,
                onValueChange = onSearchQueryChange,
                placeholder = { Text("Search for destination...") },
                leadingIcon = {
                    Icon(Icons.Default.Search, contentDescription = "Search")
                },
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                keyboardActions = KeyboardActions(
                    onSearch = {
                        // TODO: Implement destination search
                        println("Searching for: $searchQuery")
                    }
                ),
                modifier = Modifier.weight(1f),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedContainerColor = Color.White,
                    unfocusedContainerColor = Color.White
                )
            )
            
            // Large Voice Button for automotive use
            Button(
                onClick = {
                    if (isListening) {
                        speechManager.stopListening()
                    } else {
                        speechManager.startListening()
                    }
                },
                modifier = Modifier
                    .size(56.dp)
                    .scale(if (isListening) 1.1f else 1.0f),
                shape = RoundedCornerShape(DesignTokens.CornerRadius.lg),
                colors = ButtonDefaults.buttonColors(
                    containerColor = if (isListening) Color.Red else Color.Blue
                )
            ) {
                Icon(
                    imageVector = if (isListening) Icons.Default.MicOff else Icons.Default.Mic,
                    contentDescription = "Voice Input",
                    tint = Color.White,
                    modifier = Modifier.size(24.dp)
                )
            }
        }
        
        Spacer(modifier = Modifier.height(20.dp))
        
        // Map View - Optimized size for automotive display
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .height(300.dp),
            shape = RoundedCornerShape(16.dp)
        ) {
            AndroidView(
                factory = { context ->
                    MapView(context).apply {
                        onCreate(null)
                        getMapAsync { map ->
                            onMapReady(map)
                            map.uiSettings.isZoomControlsEnabled = true
                            
                            // Set default location
                            val defaultLocation = LatLng(37.7749, -122.4194)
                            map.moveCamera(CameraUpdateFactory.newLatLngZoom(defaultLocation, 10f))
                            
                            // Add markers for search results
                            searchResults.forEach { result ->
                                val location = LatLng(result.latitude, result.longitude)
                                map.addMarker(
                                    MarkerOptions()
                                        .position(location)
                                        .title(result.name)
                                        .snippet(result.address)
                                )
                            }
                        }
                    }
                },
                modifier = Modifier.fillMaxSize()
            )
        }
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Selected Destination Card
        AnimatedVisibility(
            visible = selectedDestination != null,
            enter = fadeIn() + slideInVertically(),
            exit = fadeOut() + slideOutVertically()
        ) {
            selectedDestination?.let { destination ->
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(
                        containerColor = Color.White.copy(alpha = 0.9f)
                    ),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp)
                    ) {
                        Text(
                            text = destination.name,
                            fontSize = 18.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color.Black
                        )
                        Text(
                            text = destination.address,
                            fontSize = 14.sp,
                            color = Color.Gray,
                            modifier = Modifier.padding(top = 4.dp)
                        )
                    }
                }
            }
        }
        
        Spacer(modifier = Modifier.weight(1f))
        
        // Next Button - Extra large for automotive use
        Button(
            onClick = onNext,
            enabled = selectedDestination != null,
            modifier = Modifier
                .fillMaxWidth()
                .height(56.dp),
            colors = ButtonDefaults.buttonColors(
                containerColor = if (selectedDestination != null) Color.Blue else Color.Gray
            ),
            shape = RoundedCornerShape(16.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text(
                    text = "Next: Set Search Radius",
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold
                )
                Icon(
                    Icons.Default.ArrowForward,
                    contentDescription = null,
                    modifier = Modifier.size(20.dp)
                )
            }
        }
    }
}

// MARK: - Radius Step Content

@Composable
fun RadiusStepContent(
    userPreferences: UserPreferencesManager,
    speechManager: SpeechManager,
    onNext: () -> Unit,
    onBack: () -> Unit
) {
    val searchRadius by userPreferences.searchRadius.collectAsState()
    val distanceUnit by userPreferences.distanceUnit.collectAsState()
    
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
            .padding(16.dp)
    ) {
        // Title
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.fillMaxWidth()
        ) {
            Text(
                text = "Set your search radius",
                fontSize = 24.sp,
                fontWeight = FontWeight.Bold,
                color = Color.White,
                textAlign = TextAlign.Center
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Text(
                text = "How far should we search for interesting places?",
                fontSize = 16.sp,
                color = Color.Gray,
                textAlign = TextAlign.Center
            )
        }
        
        Spacer(modifier = Modifier.height(40.dp))
        
        // Large Radius Display - Automotive-friendly
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(20.dp),
            colors = CardDefaults.cardColors(
                containerColor = Color.White.copy(alpha = 0.1f)
            )
        ) {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.padding(30.dp)
            ) {
                Text(
                    text = "${searchRadius.toInt()}",
                    fontSize = 80.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.Blue
                )
                
                Text(
                    text = distanceUnit.displayName,
                    fontSize = 20.sp,
                    color = Color.White
                )
            }
        }
        
        Spacer(modifier = Modifier.height(30.dp))
        
        // Unit Toggle - Large buttons
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            DistanceUnit.values().forEach { unit ->
                Button(
                    onClick = { userPreferences.setDistanceUnit(unit) },
                    modifier = Modifier
                        .weight(1f)
                        .height(50.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = if (distanceUnit == unit) Color.Blue else Color.Transparent
                    ),
                    border = ButtonDefaults.outlinedButtonBorder.copy(
                        brush = Brush.linearGradient(listOf(Color.Blue, Color.Blue))
                    ),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Text(
                        text = unit.displayName,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = if (distanceUnit == unit) Color.White else Color.Blue
                    )
                }
            }
        }
        
        Spacer(modifier = Modifier.height(30.dp))
        
        // Slider with Voice Hint
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(
                containerColor = Color.White.copy(alpha = 0.1f)
            )
        ) {
            Column(
                modifier = Modifier.padding(20.dp)
            ) {
                Slider(
                    value = searchRadius.toFloat(),
                    onValueChange = { userPreferences.setSearchRadius(it.toDouble()) },
                    valueRange = 1f..10f,
                    steps = 8,
                    colors = SliderDefaults.colors(
                        thumbColor = Color.Blue,
                        activeTrackColor = Color.Blue,
                        inactiveTrackColor = Color.Gray
                    ),
                    modifier = Modifier.fillMaxWidth()
                )
                
                Spacer(modifier = Modifier.height(16.dp))
                
                // Voice hint
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.Center
                ) {
                    Icon(
                        Icons.Default.Mic,
                        contentDescription = null,
                        tint = Color.Blue,
                        modifier = Modifier.size(16.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "Say \"Set radius to 3 miles\"",
                        fontSize = 12.sp,
                        color = Color.Gray
                    )
                }
            }
        }
        
        Spacer(modifier = Modifier.height(20.dp))
        
        // Voice Button
        Button(
            onClick = { speechManager.startListening() },
            modifier = Modifier
                .fillMaxWidth()
                .height(50.dp),
            colors = ButtonDefaults.buttonColors(
                containerColor = Color.Blue
            ),
            shape = RoundedCornerShape(12.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Icon(
                    Icons.Default.Mic,
                    contentDescription = null,
                    modifier = Modifier.size(20.dp)
                )
                Text(
                    text = "Set by Voice",
                    fontSize = 16.sp,
                    fontWeight = FontWeight.SemiBold
                )
            }
        }
        
        Spacer(modifier = Modifier.weight(1f))
        
        // Navigation Buttons
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Button(
                onClick = onBack,
                modifier = Modifier
                    .weight(1f)
                    .height(50.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color.Transparent
                ),
                border = ButtonDefaults.outlinedButtonBorder,
                shape = RoundedCornerShape(12.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Icon(
                        Icons.Default.ArrowBack,
                        contentDescription = null,
                        tint = Color.Gray
                    )
                    Text("Back", color = Color.Gray)
                }
            }
            
            Button(
                onClick = onNext,
                modifier = Modifier
                    .weight(2f)
                    .height(50.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color.Blue
                ),
                shape = RoundedCornerShape(12.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Text(
                        text = "Next: Choose Interests",
                        fontWeight = FontWeight.SemiBold
                    )
                    Icon(
                        Icons.Default.ArrowForward,
                        contentDescription = null
                    )
                }
            }
        }
    }
}

// MARK: - Category Step Content

@Composable
fun CategoryStepContent(
    userPreferences: UserPreferencesManager,
    speechManager: SpeechManager,
    onNext: () -> Unit,
    onBack: () -> Unit
) {
    val selectedCategories by userPreferences.selectedPOICategories.collectAsState()
    
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
            .padding(16.dp)
    ) {
        // Title
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.fillMaxWidth()
        ) {
            Text(
                text = "Choose your interests",
                fontSize = 24.sp,
                fontWeight = FontWeight.Bold,
                color = Color.White,
                textAlign = TextAlign.Center
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Text(
                text = "What kinds of places interest you?",
                fontSize = 16.sp,
                color = Color.Gray,
                textAlign = TextAlign.Center
            )
        }
        
        Spacer(modifier = Modifier.height(20.dp))
        
        // Quick Actions
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Button(
                onClick = { userPreferences.selectAllCategories() },
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color.Blue
                ),
                shape = RoundedCornerShape(20.dp)
            ) {
                Text("All", fontWeight = FontWeight.Medium)
            }
            
            Button(
                onClick = { userPreferences.clearAllCategories() },
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color.Transparent
                ),
                border = ButtonDefaults.outlinedButtonBorder,
                shape = RoundedCornerShape(20.dp)
            ) {
                Text("Clear", color = Color.Gray)
            }
            
            Spacer(modifier = Modifier.weight(1f))
            
            Button(
                onClick = { speechManager.startListening() },
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color.Blue
                ),
                shape = RoundedCornerShape(16.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Icon(
                        Icons.Default.Mic,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp)
                    )
                    Text("Voice", fontSize = 12.sp)
                }
            }
        }
        
        Spacer(modifier = Modifier.height(20.dp))
        
        // Categories Grid - Large touch targets for automotive
        LazyVerticalGrid(
            columns = GridCells.Fixed(2),
            verticalArrangement = Arrangement.spacedBy(12.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            modifier = Modifier.weight(1f)
        ) {
            items(POICategory.values()) { category ->
                CategoryButton(
                    category = category,
                    isSelected = selectedCategories.contains(category),
                    onClick = { userPreferences.toggleCategory(category) }
                )
            }
        }
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Selected Count
        Text(
            text = "${selectedCategories.size} categories selected",
            fontSize = 14.sp,
            color = Color.Gray,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth()
        )
        
        Spacer(modifier = Modifier.height(20.dp))
        
        // Navigation Buttons
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Button(
                onClick = onBack,
                modifier = Modifier
                    .weight(1f)
                    .height(50.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color.Transparent
                ),
                border = ButtonDefaults.outlinedButtonBorder,
                shape = RoundedCornerShape(12.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Icon(
                        Icons.Default.ArrowBack,
                        contentDescription = null,
                        tint = Color.Gray
                    )
                    Text("Back", color = Color.Gray)
                }
            }
            
            Button(
                onClick = onNext,
                enabled = selectedCategories.isNotEmpty(),
                modifier = Modifier
                    .weight(2f)
                    .height(50.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = if (selectedCategories.isNotEmpty()) Color.Blue else Color.Gray
                ),
                shape = RoundedCornerShape(12.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Text(
                        text = "Review Settings",
                        fontWeight = FontWeight.SemiBold
                    )
                    Icon(
                        Icons.Default.ArrowForward,
                        contentDescription = null
                    )
                }
            }
        }
    }
}

// MARK: - Category Button

@Composable
fun CategoryButton(
    category: POICategory,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .height(80.dp)
            .clickable { onClick() }
            .scale(if (isSelected) 1.05f else 1.0f),
        colors = CardDefaults.cardColors(
            containerColor = if (isSelected) Color.Blue else Color.White.copy(alpha = 0.1f)
        ),
        border = if (!isSelected) CardDefaults.outlinedCardBorder() else null,
        shape = RoundedCornerShape(12.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(8.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            // Icon placeholder - would use actual icons in production
            Box(
                modifier = Modifier
                    .size(24.dp)
                    .background(
                        color = if (isSelected) Color.White.copy(alpha = 0.3f) else Color.Blue.copy(alpha = 0.3f),
                        shape = RoundedCornerShape(DesignTokens.CornerRadius.lg)
                    )
            )
            
            Spacer(modifier = Modifier.height(4.dp))
            
            Text(
                text = category.displayName,
                fontSize = 10.sp,
                fontWeight = FontWeight.Medium,
                color = if (isSelected) Color.White else Color.White.copy(alpha = 0.8f),
                textAlign = TextAlign.Center,
                maxLines = 2
            )
        }
    }
}

// MARK: - Confirmation Step Content

@Composable
fun ConfirmationStepContent(
    selectedDestination: DestinationSearchResult?,
    userPreferences: UserPreferencesManager,
    onConfirm: () -> Unit,
    onBack: () -> Unit
) {
    val selectedCategories by userPreferences.selectedPOICategories.collectAsState()
    
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
            .padding(16.dp)
    ) {
        Text(
            text = "Ready for your roadtrip?",
            fontSize = 24.sp,
            fontWeight = FontWeight.Bold,
            color = Color.White,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth()
        )
        
        Spacer(modifier = Modifier.height(40.dp))
        
        // Settings Summary Cards
        Column(
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Destination Card
            SettingsSummaryCard(
                icon = Icons.Default.LocationOn,
                title = "Destination",
                value = selectedDestination?.name ?: "Unknown",
                color = Color.Blue
            )
            
            // Radius Card
            SettingsSummaryCard(
                icon = Icons.Default.Search,
                title = "Search Radius",
                value = userPreferences.getSearchRadiusText(),
                color = Color.Green
            )
            
            // Categories Card
            SettingsSummaryCard(
                icon = Icons.Default.List,
                title = "Interests",
                value = "${selectedCategories.size} categories",
                color = Color(0xFF9C27B0) // Purple color
            )
        }
        
        Spacer(modifier = Modifier.weight(1f))
        
        // Action Buttons - Extra large for automotive
        Column(
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Button(
                onClick = onConfirm,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(60.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color.Blue
                ),
                shape = RoundedCornerShape(16.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Icon(
                        Icons.Default.DriveEta,
                        contentDescription = null,
                        modifier = Modifier.size(24.dp)
                    )
                    Text(
                        text = "Start My Roadtrip!",
                        fontSize = 20.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
            
            Button(
                onClick = onBack,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(50.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color.Transparent
                ),
                border = ButtonDefaults.outlinedButtonBorder,
                shape = RoundedCornerShape(12.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Icon(
                        Icons.Default.ArrowBack,
                        contentDescription = null,
                        tint = Color.Gray
                    )
                    Text("Back to Categories", color = Color.Gray)
                }
            }
        }
    }
}

// MARK: - Settings Summary Card

@Composable
fun SettingsSummaryCard(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String,
    value: String,
    color: Color
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = Color.White.copy(alpha = 0.1f)
        ),
        shape = RoundedCornerShape(16.dp)
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .background(color = color.copy(alpha = 0.2f), shape = RoundedCornerShape(DesignTokens.CornerRadius.lg)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = color,
                    modifier = Modifier.size(20.dp)
                )
            }
            
            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = title,
                    fontSize = 12.sp,
                    color = Color.Gray
                )
                Text(
                    text = value,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = Color.White
                )
            }
        }
    }
}