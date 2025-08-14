package com.roadtrip.copilot.ui.screens

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.ExperimentalAnimationApi
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.with
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.painter.Painter
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import coil.compose.AsyncImage
import coil.request.ImageRequest
import kotlinx.coroutines.launch
import android.util.Log

@OptIn(ExperimentalFoundationApi::class, ExperimentalAnimationApi::class)
@Composable
fun POICarouselScreen(
    pois: List<POIItem> = POICarouselViewModel.mockPOIs,
    viewModel: POICarouselViewModel = viewModel()
) {
    val pagerState = rememberPagerState(pageCount = { pois.size })
    val coroutineScope = rememberCoroutineScope()
    
    LaunchedEffect(pois) {
        viewModel.loadPOIs(pois)
        viewModel.startFetchingData()
    }
    
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.linearGradient(
                    colors = listOf(
                        MaterialTheme.colorScheme.primary.copy(alpha = 0.1f),
                        MaterialTheme.colorScheme.secondary.copy(alpha = 0.1f)
                    )
                )
            )
    ) {
        Column(
            modifier = Modifier.fillMaxSize()
        ) {
            // Header
            POICarouselHeader(
                location = "Lost Lake, Oregon",
                onReviewsClick = { /* Show reviews */ }
            )
            
            // POI Photo Carousel
            HorizontalPager(
                state = pagerState,
                modifier = Modifier.weight(1f)
            ) { page ->
                val poi = viewModel.pois.getOrNull(page)
                poi?.let {
                    POICard(
                        poi = it,
                        photo = viewModel.photos[it.id],
                        reviews = viewModel.reviews[it.id] ?: emptyList(),
                        modifier = Modifier.fillMaxSize()
                    )
                }
            }
            
            // Navigation Controls
            NavigationControls(
                currentIndex = pagerState.currentPage,
                totalCount = pois.size,
                onPrevious = {
                    coroutineScope.launch {
                        val targetPage = if (pagerState.currentPage > 0) {
                            pagerState.currentPage - 1
                        } else {
                            pois.size - 1 // Loop to last
                        }
                        pagerState.animateScrollToPage(targetPage)
                        viewModel.logNavigation(targetPage, "previous")
                    }
                },
                onNext = {
                    coroutineScope.launch {
                        val targetPage = if (pagerState.currentPage < pois.size - 1) {
                            pagerState.currentPage + 1
                        } else {
                            0 // Loop to first
                        }
                        pagerState.animateScrollToPage(targetPage)
                        viewModel.logNavigation(targetPage, "next")
                    }
                },
                onNavigate = {
                    viewModel.navigateToPOI(pagerState.currentPage)
                },
                onShare = {
                    viewModel.sharePOI(pagerState.currentPage)
                }
            )
            
            // Page Indicator
            PageIndicator(
                currentPage = pagerState.currentPage,
                pageCount = pois.size,
                modifier = Modifier.padding(bottom = 16.dp)
            )
        }
    }
}

@Composable
fun POICarouselHeader(
    location: String,
    onReviewsClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column {
            Text(
                text = "Discovering",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Text(
                text = location,
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold
            )
        }
        
        IconButton(onClick = onReviewsClick) {
            Icon(
                imageVector = Icons.Default.Chat,
                contentDescription = "Reviews",
                tint = MaterialTheme.colorScheme.primary
            )
        }
    }
}

@Composable
fun POICard(
    poi: POIItem,
    photo: String?,
    reviews: List<Review>,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.padding(horizontal = 16.dp, vertical = 8.dp),
        shape = RoundedCornerShape(20.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 8.dp)
    ) {
        Column {
            // POI Photo
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(400.dp)
            ) {
                if (photo != null) {
                    AsyncImage(
                        model = ImageRequest.Builder(LocalContext.current)
                            .data(photo)
                            .crossfade(true)
                            .build(),
                        contentDescription = poi.name,
                        contentScale = ContentScale.Crop,
                        modifier = Modifier.fillMaxSize()
                    )
                } else {
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .background(MaterialTheme.colorScheme.surfaceVariant),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator()
                    }
                }
                
                // Gradient overlay
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(
                            Brush.verticalGradient(
                                colors = listOf(
                                    Color.Transparent,
                                    Color.Black.copy(alpha = 0.7f)
                                ),
                                startY = 200f
                            )
                        )
                )
                
                // POI Info Overlay
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .align(Alignment.BottomStart)
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = poi.name,
                            style = MaterialTheme.typography.headlineMedium,
                            fontWeight = FontWeight.Bold,
                            color = Color.White
                        )
                        
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(
                                imageVector = Icons.Default.LocationOn,
                                contentDescription = null,
                                tint = Color.White.copy(alpha = 0.9f),
                                modifier = Modifier.size(16.dp)
                            )
                            Text(
                                text = "${poi.distance} miles",
                                style = MaterialTheme.typography.bodySmall,
                                color = Color.White.copy(alpha = 0.9f)
                            )
                        }
                        
                        poi.rating?.let { rating ->
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                repeat(5) { index ->
                                    Icon(
                                        imageVector = if (index < rating.toInt()) 
                                            Icons.Default.Star else Icons.Default.StarBorder,
                                        contentDescription = null,
                                        tint = Color.Yellow,
                                        modifier = Modifier.size(16.dp)
                                    )
                                }
                                Text(
                                    text = "(${reviews.size} reviews)",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = Color.White.copy(alpha = 0.8f),
                                    modifier = Modifier.padding(start = 4.dp)
                                )
                            }
                        }
                    }
                    
                    Box(
                        modifier = Modifier
                            .size(48.dp)
                            .background(
                                Color.Black.copy(alpha = 0.3f),
                                CircleShape
                            ),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = poi.categoryIcon,
                            contentDescription = poi.category,
                            tint = Color.White,
                            modifier = Modifier.size(24.dp)
                        )
                    }
                }
            }
            
            // POI Details
            Column(
                modifier = Modifier.padding(16.dp)
            ) {
                Text(
                    text = poi.description,
                    style = MaterialTheme.typography.bodyMedium,
                    maxLines = 3,
                    overflow = TextOverflow.Ellipsis
                )
                
                // Top Review
                reviews.firstOrNull()?.let { topReview ->
                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 8.dp),
                        colors = CardDefaults.cardColors(
                            containerColor = MaterialTheme.colorScheme.surfaceVariant
                        )
                    ) {
                        Column(
                            modifier = Modifier.padding(12.dp)
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(
                                    imageVector = Icons.Default.FormatQuote,
                                    contentDescription = null,
                                    tint = MaterialTheme.colorScheme.primary,
                                    modifier = Modifier.size(16.dp)
                                )
                                Text(
                                    text = "Top Review",
                                    style = MaterialTheme.typography.labelMedium,
                                    color = MaterialTheme.colorScheme.primary,
                                    modifier = Modifier.padding(start = 4.dp)
                                )
                            }
                            
                            Text(
                                text = "\"${topReview.text}\"",
                                style = MaterialTheme.typography.bodySmall,
                                fontStyle = androidx.compose.ui.text.font.FontStyle.Italic,
                                maxLines = 2,
                                overflow = TextOverflow.Ellipsis,
                                modifier = Modifier.padding(vertical = 4.dp)
                            )
                            
                            Text(
                                text = "- ${topReview.author}",
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
                
                // Tags
                LazyRow(
                    modifier = Modifier.padding(top = 8.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(poi.tags.size) { index ->
                        AssistChip(
                            onClick = { },
                            label = {
                                Text(
                                    text = poi.tags[index],
                                    style = MaterialTheme.typography.labelSmall
                                )
                            }
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun NavigationControls(
    currentIndex: Int,
    totalCount: Int,
    onPrevious: () -> Unit,
    onNext: () -> Unit,
    onNavigate: () -> Unit,
    onShare: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp),
        horizontalArrangement = Arrangement.SpaceEvenly,
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Previous button
        FilledIconButton(
            onClick = onPrevious,
            enabled = totalCount > 0,
            modifier = Modifier.size(48.dp)
        ) {
            Icon(
                imageVector = Icons.Default.ChevronLeft,
                contentDescription = "Previous"
            )
        }
        
        // Action buttons
        Row(
            horizontalArrangement = Arrangement.spacedBy(24.dp)
        ) {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                IconButton(
                    onClick = onNavigate,
                    modifier = Modifier.size(48.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Navigation,
                        contentDescription = "Navigate",
                        tint = MaterialTheme.colorScheme.primary
                    )
                }
                Text(
                    text = "Navigate",
                    style = MaterialTheme.typography.labelSmall
                )
            }
            
            Column(
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                IconButton(
                    onClick = onShare,
                    modifier = Modifier.size(48.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Share,
                        contentDescription = "Share",
                        tint = MaterialTheme.colorScheme.secondary
                    )
                }
                Text(
                    text = "Share",
                    style = MaterialTheme.typography.labelSmall
                )
            }
        }
        
        // Next button
        FilledIconButton(
            onClick = onNext,
            enabled = totalCount > 0,
            modifier = Modifier.size(48.dp)
        ) {
            Icon(
                imageVector = Icons.Default.ChevronRight,
                contentDescription = "Next"
            )
        }
    }
}

@Composable
fun PageIndicator(
    currentPage: Int,
    pageCount: Int,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically
    ) {
        repeat(pageCount) { index ->
            Box(
                modifier = Modifier
                    .padding(horizontal = 4.dp)
                    .size(if (index == currentPage) 10.dp else 8.dp)
                    .clip(CircleShape)
                    .background(
                        if (index == currentPage)
                            MaterialTheme.colorScheme.primary
                        else
                            MaterialTheme.colorScheme.onSurface.copy(alpha = 0.3f)
                    )
            )
        }
    }
}

// Data Models
data class POIItem(
    val id: String,
    val name: String,
    val category: String,
    val distance: Double,
    val rating: Double? = null,
    val description: String,
    val tags: List<String>
) {
    val categoryIcon: ImageVector
        get() = when (category.lowercase()) {
            "hiking" -> Icons.Default.DirectionsWalk
            "lodging" -> Icons.Default.Hotel
            "restaurant" -> Icons.Default.Restaurant
            "camping" -> Icons.Default.Landscape
            "viewpoint" -> Icons.Default.RemoveRedEye
            else -> Icons.Default.Place
        }
}

data class Review(
    val author: String,
    val rating: Double,
    val text: String,
    val date: String,
    val source: String
)