# Roadtrip-Copilot Backend API Specification
## Version 2.0 - January 2025 (Gemma 3n Mobile-First)

**Base URL:** `https://api.Roadtrip-Copilot.com/v2`  
**Authentication:** Bearer Token (JWT)  
**Content-Type:** `application/json`  
**Mobile AI:** Receives pre-processed data from Gemma 3n on-device

---

## Authentication

### Login
```http
POST /auth/login
{
  "email": "user@example.com",
  "password": "password123"
}

Response:
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9...",
  "refresh_token": "refresh_token_here",
  "expires_in": 3600,
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "username": "traveler123"
  }
}
```

### Refresh Token
```http
POST /auth/refresh
{
  "refresh_token": "refresh_token_here"
}
```

---

## RAG Data Ingestion (Formerly Discovery Management)

### Ingest Pre-Processed Discovery
```http
POST /rag/ingest
Authorization: Bearer {token}

{
  "user_id_hash": "anonymized_mobile_hash",
  "discovery_data": {
    "poi_name": "Joe's Authentic BBQ",
    "city": "San Francisco, CA",  // City-level only (privacy-preserving)
    "category": "restaurant",
    "subcategory": "bbq", 
    "discovery_timestamp": "2025-01-01T15:30:00Z",
    
    // Pre-validated by mobile Gemma 3n
    "mobile_validation": {
      "is_new_discovery": true,
      "confidence_score": 0.91,
      "similarity_checked": true,
      "processed_by": "Gemma-3n-E2B"
    },
    
    // Generated conversation from mobile AI
    "conversation_script": "Alex: Whoa, Joe's Authentic BBQ! Sarah, this place looks incredible! Sarah: Family-owned since 1952, their pulled pork is legendary. Gets busy around dinner, but totally worth the wait. Alex: I can already smell that amazing BBQ from here!",
    
    // Voice podcast generated on mobile
    "voice_podcast": {
      "audio_url": "https://mobile-cdn.Roadtrip-Copilot.com/podcasts/abc123.mp3",
      "duration_seconds": 6.2,
      "quality_score": 0.88
    },
    
    // Revenue analysis from mobile
    "revenue_estimate": {
      "potential_earnings": 15.75,
      "estimated_roadtrips": 31,
      "confidence": 0.87,
      "category_multiplier": 1.2
    },
    
    // Curated visual content for video creation
    "visual_content": [
      {
        "photo_url": "https://mobile-cdn.Roadtrip-Copilot.com/photos/def456.jpg",
        "description": "Mouth-watering pulled pork sandwich with crispy fries",
        "quality_score": 0.94,
        "suitable_for_video": true
      }
    ]
  }
}

Response:
{
  "ingestion_id": "uuid", 
  "rag_indexed": true,
  "video_generation_queued": true,
  "revenue_tracking_enabled": true,
  "processing_time_ms": 120,  // Much faster with pre-processed data!
  "message": "Mobile-generated discovery successfully ingested. Video creation pipeline initiated."
}
```

### Get User Discoveries
```http
GET /discoveries/me?page=1&limit=20&status=validated

Response:
{
  "discoveries": [
    {
      "id": "uuid",
      "poi_name": "Joe's Authentic BBQ",
      "location": {
        "city": "San Francisco",
        "state": "CA"
      },
      "category": "restaurant",
      "discovery_date": "2024-12-01T15:30:00Z",
      "validation_status": "validated",
      "is_new": true,
      "could_earn_revenue": true,
      "videos_created": 3,
      "total_views": 15420,
      "total_revenue": 127.50,
      "user_share": 63.75,
      "roadtrips_earned": 127
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 45,
    "pages": 3
  }
}
```

### Get Discovery Details
```http
GET /discoveries/{discovery_id}

Response:
{
  "id": "uuid",
  "poi_data": { /* Full POI data */ },
  "discoverer": {
    "username": "traveler123",
    "avatar_url": "https://avatars.Roadtrip-Copilot.com/user123.jpg"
  },
  "validation": {
    "status": "validated",
    "validated_at": "2024-12-01T15:35:00Z",
    "similarity_score": 0.08,
    "is_new": true
  },
  "videos": [
    {
      "id": "uuid",
      "platform": "youtube",
      "video_url": "https://youtube.com/shorts/abc123",
      "title": "Hidden BBQ Gem in San Francisco!",
      "views": 8540,
      "revenue": 47.25,
      "created_at": "2024-12-01T16:00:00Z"
    }
  ],
  "earnings": {
    "total_revenue": 127.50,
    "user_share": 63.75,
    "roadtrips_earned": 127,
    "conversion_rate": 0.50
  }
}
```

---

## Video Management

### Get Video Generation Status
```http
GET /videos/discovery/{discovery_id}/status

Response:
{
  "discovery_id": "uuid",
  "generation_status": "completed",
  "videos": [
    {
      "id": "uuid",
      "platform": "youtube",
      "status": "uploaded",
      "video_url": "https://youtube.com/shorts/abc123",
      "upload_date": "2024-12-01T16:00:00Z"
    },
    {
      "id": "uuid",
      "platform": "tiktok",
      "status": "processing",
      "estimated_completion": "2024-12-01T16:30:00Z"
    }
  ],
  "queue_position": 0,
  "estimated_completion": "2024-12-01T16:30:00Z"
}
```

### Get Video Performance
```http
GET /videos/{video_id}/analytics

Response:
{
  "video_id": "uuid",
  "platform": "youtube",
  "video_url": "https://youtube.com/shorts/abc123",
  "title": "Hidden BBQ Gem in San Francisco!",
  "analytics": {
    "views": 8540,
    "likes": 412,
    "shares": 67,
    "comments": 89,
    "watch_time_seconds": 89420,
    "engagement_rate": 0.067
  },
  "revenue": {
    "total_revenue": 47.25,
    "user_share": 23.63,
    "platform_share": 23.62,
    "last_updated": "2024-12-01T12:00:00Z"
  },
  "performance_rank": {
    "among_user_videos": 3,
    "among_category": 45,
    "among_all_videos": 1842
  }
}
```

### Request Video Regeneration
```http
POST /videos/{video_id}/regenerate
{
  "reason": "Low performance, want to try different hook",
  "preferences": {
    "style": "energetic",
    "duration": 25,
    "focus": "food_showcase"
  }
}

Response:
{
  "regeneration_id": "uuid",
  "status": "queued",
  "estimated_completion": "2024-12-01T17:00:00Z",
  "note": "Original video will remain active until new version is approved"
}
```

---

## Revenue & Credits

### Get User Earnings Summary
```http
GET /earnings/summary?period=30d

Response:
{
  "period": "30d",
  "summary": {
    "total_discoveries": 12,
    "new_discoveries": 8,
    "videos_created": 24,
    "total_views": 127420,
    "total_revenue": 487.50,
    "user_share": 243.75,
    "roadtrips_earned": 487,
    "current_balance": 423
  },
  "by_platform": {
    "youtube": {
      "videos": 8,
      "views": 67420,
      "revenue": 287.50,
      "user_share": 143.75
    },
    "tiktok": {
      "videos": 8,
      "views": 34500,
      "revenue": 125.00,
      "user_share": 62.50
    },
    "instagram": {
      "videos": 8,
      "views": 25500,
      "revenue": 75.00,
      "user_share": 37.50
    }
  },
  "top_performing_video": {
    "title": "Hidden BBQ Gem in San Francisco!",
    "platform": "youtube",
    "views": 15420,
    "revenue": 67.25,
    "user_share": 33.63
  }
}
```

### Get Earnings History
```http
GET /earnings/history?start_date=2024-11-01&end_date=2024-12-01&page=1&limit=50

Response:
{
  "earnings": [
    {
      "date": "2024-12-01",
      "video_id": "uuid",
      "video_title": "Hidden BBQ Gem in San Francisco!",
      "platform": "youtube",
      "views": 1542,
      "revenue": 8.75,
      "user_share": 4.37,
      "roadtrips_earned": 8,
      "discovery_name": "Joe's Authentic BBQ"
    }
  ],
  "daily_totals": [
    {
      "date": "2024-12-01",
      "total_revenue": 47.25,
      "user_share": 23.63,
      "roadtrips_earned": 47,
      "videos_earning": 3
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 50,
    "total": 234,
    "pages": 5
  }
}
```

### Get Credit Balance
```http
GET /credits/balance

Response:
{
  "user_id": "uuid",
  "current_balance": 423,
  "earned_credits": 487,
  "used_credits": 64,
  "promotional_credits": 7,  // Initial free credits
  "last_updated": "2024-12-01T16:30:00Z",
  "breakdown": {
    "from_discoveries": 487,
    "from_referrals": 0,
    "promotional": 7
  }
}
```

### Use Credits for Roadtrip
```http
POST /credits/use
{
  "amount": 1,
  "purpose": "roadtrip",
  "trip_details": {
    "destination": "Napa Valley, CA",
    "estimated_distance": 67,
    "planned_date": "2024-12-15"
  }
}

Response:
{
  "transaction_id": "uuid",
  "credits_used": 1,
  "remaining_balance": 422,
  "trip_activation_code": "RT-NK7P-M4X9",
  "expires_at": "2024-12-31T23:59:59Z"
}
```

### Get Credit Transaction History
```http
GET /credits/transactions?page=1&limit=20&type=earned

Response:
{
  "transactions": [
    {
      "id": "uuid",
      "type": "earned",
      "amount": 8,
      "source": "video_revenue",
      "description": "Earned from discovery video: Hidden BBQ Gem",
      "video_id": "uuid",
      "revenue_amount": 4.37,
      "created_at": "2024-12-01T16:30:00Z"
    }
  ],
  "summary": {
    "total_earned": 487,
    "total_used": 64,
    "total_promotional": 7
  }
}
```

---

## User Dashboard

### Get Dashboard Data
```http
GET /dashboard

Response:
{
  "overview": {
    "total_discoveries": 12,
    "new_discoveries": 8,
    "videos_created": 24,
    "roadtrip_balance": 423,
    "total_earned": 487,
    "rank": {
      "position": 147,
      "total_users": 25840,
      "percentile": 94
    }
  },
  "recent_activity": [
    {
      "type": "discovery_validated",
      "title": "Your discovery 'Mountain View Cafe' was validated!",
      "subtitle": "Video generation started",
      "timestamp": "2024-12-01T15:30:00Z",
      "discovery_id": "uuid"
    },
    {
      "type": "video_uploaded",
      "title": "Video uploaded to YouTube Shorts",
      "subtitle": "Hidden BBQ Gem in San Francisco!",
      "timestamp": "2024-12-01T16:00:00Z",
      "video_id": "uuid"
    },
    {
      "type": "credits_earned",
      "title": "Earned 8 roadtrip credits",
      "subtitle": "From video performance",
      "timestamp": "2024-12-01T16:30:00Z",
      "amount": 8
    }
  ],
  "performance_charts": {
    "earnings_last_30_days": [
      { "date": "2024-11-01", "amount": 12.50 },
      { "date": "2024-11-02", "amount": 8.75 }
      // ... more data points
    ],
    "discoveries_by_category": [
      { "category": "restaurant", "count": 5 },
      { "category": "scenic_spot", "count": 3 },
      { "category": "historic_site", "count": 2 }
    ],
    "platform_performance": [
      { "platform": "youtube", "views": 67420, "revenue": 143.75 },
      { "platform": "tiktok", "views": 34500, "revenue": 62.50 },
      { "platform": "instagram", "views": 25500, "revenue": 37.50 }
    ]
  },
  "achievements": [
    {
      "id": "first_discovery",
      "title": "First Discovery",
      "description": "Made your first POI discovery",
      "earned_at": "2024-11-15T10:00:00Z",
      "icon": "🎯"
    },
    {
      "id": "viral_video",
      "title": "Viral Video",
      "description": "Video reached 10k+ views",
      "earned_at": "2024-11-28T14:00:00Z",
      "icon": "🚀"
    }
  ]
}
```

### Get Leaderboard
```http
GET /leaderboard?period=monthly&category=all&page=1&limit=100

Response:
{
  "leaderboard": [
    {
      "rank": 1,
      "user": {
        "username": "roadtripking",
        "avatar_url": "https://avatars.Roadtrip-Copilot.com/user456.jpg",
        "badge": "Elite Discoverer"
      },
      "stats": {
        "discoveries": 47,
        "videos": 141,
        "total_views": 2347520,
        "roadtrips_earned": 2847,
        "favorite_category": "hidden_gems"
      }
    }
  ],
  "user_position": {
    "rank": 147,
    "percentile": 94,
    "stats": {
      "discoveries": 12,
      "videos": 24,
      "total_views": 127420,
      "roadtrips_earned": 487
    }
  }
}
```

---

## User Preferences

### Get User Preferences
```http
GET /preferences

Response:
{
  "tts_settings": {
    "primary_engine": "kitten_tts", // "kitten_tts", "kokoro_tts", "system_default"
    "preferred_voice": "voice_1", // 0-7 for Kitten TTS voices
    "speech_rate": 1.0, // 0.5-2.0
    "pitch_adjustment": 0.0, // -1.0 to 1.0
    "enable_premium_tts": true, // Allow Kokoro TTS downloads
    "auto_cache_voices": true, // Cache frequently used voices
    "quality_preference": "balanced" // "speed", "balanced", "quality"
  },
  "voice_interaction": {
    "response_timeout_ms": 350, // Target response time
    "enable_voice_commands": true,
    "carplay_voice_optimization": true,
    "android_auto_voice_optimization": true,
    "voice_feedback_enabled": true
  },
  "discovery_preferences": {
    "voice_explanations": true, // Explain earning potential via voice
    "earning_announcements": true, // Announce when credits are earned
    "discovery_confirmation_voice": true // Voice confirmation for discoveries
  },
  "audio_quality": {
    "preferred_sample_rate": 22050, // Hz
    "audio_compression": "auto", // "none", "auto", "high"
    "normalize_audio": true
  }
}
```

### Update User Preferences
```http
PUT /preferences
{
  "tts_settings": {
    "primary_engine": "kokoro_tts",
    "preferred_voice": "voice_3",
    "speech_rate": 1.2,
    "enable_premium_tts": true
  },
  "voice_interaction": {
    "response_timeout_ms": 300,
    "carplay_voice_optimization": true
  }
}

Response:
{
  "success": true,
  "message": "Preferences updated successfully",
  "sync_required": true, // Indicates mobile app should sync new settings
  "updated_at": "2024-12-01T16:30:00Z"
}
```

### Get Available TTS Voices
```http
GET /preferences/tts/voices

Response:
{
  "engines": {
    "kitten_tts": {
      "size_mb": 24.8,
      "always_available": true,
      "quality": "high",
      "languages": ["en"],
      "voices": [
        {
          "id": "voice_0",
          "name": "Emma",
          "gender": "female",
          "description": "Warm, friendly female voice",
          "preview_url": "https://api.Roadtrip-Copilot.com/voice-previews/kitten_emma.mp3"
        },
        {
          "id": "voice_1", 
          "name": "Alex",
          "gender": "male",
          "description": "Clear, professional male voice",
          "preview_url": "https://api.Roadtrip-Copilot.com/voice-previews/kitten_alex.mp3"
        },
        // ... 6 more voices
      ]
    },
    "kokoro_tts": {
      "size_mb": 330.0,
      "requires_download": true,
      "quality": "excellent",
      "languages": ["en", "fr", "ko", "ja", "zh"],
      "voices": [
        {
          "id": "kokoro_en_female_1",
          "name": "Sophia",
          "gender": "female", 
          "language": "en",
          "description": "Premium quality English female voice",
          "preview_url": "https://api.Roadtrip-Copilot.com/voice-previews/kokoro_sophia.mp3"
        }
        // ... more premium voices
      ]
    }
  },
  "user_downloaded": ["kokoro_en_female_1"], // Which premium voices user has downloaded
  "recommendations": {
    "for_driving": "voice_1", // Recommended for CarPlay/Android Auto
    "for_content": "kokoro_en_female_1", // Recommended for video creation
    "battery_optimized": "voice_0" // Most battery-efficient option
  }
}
```

---

## Admin APIs

### System Metrics
```http
GET /admin/metrics
Authorization: Bearer {admin_token}

Response:
{
  "system_health": {
    "status": "healthy",
    "uptime": 2587320,  // seconds
    "version": "1.0.5"
  },
  "discovery_metrics": {
    "total_discoveries": 45782,
    "new_discoveries_today": 127,
    "validation_success_rate": 0.847,
    "avg_validation_time_ms": 340
  },
  "video_metrics": {
    "total_videos": 137346,
    "videos_created_today": 381,
    "generation_success_rate": 0.983,
    "avg_generation_time_min": 4.2,
    "current_queue_depth": 23
  },
  "revenue_metrics": {
    "total_platform_revenue": 1847520.00,
    "total_user_payouts": 923760.00,
    "revenue_share_rate": 0.50,
    "avg_revenue_per_video": 13.44
  },
  "user_metrics": {
    "total_users": 25840,
    "active_discoverers": 8472,
    "avg_discoveries_per_user": 1.77,
    "top_category": "restaurants"
  }
}
```

### Content Moderation Queue
```http
GET /admin/moderation/queue?status=pending&page=1&limit=50

Response:
{
  "queue": [
    {
      "id": "uuid",
      "type": "discovery",
      "content": {
        "poi_name": "Joe's Authentic BBQ",
        "description": "Amazing pulled pork...",
        "submitter": "traveler123"
      },
      "flags": [
        {
          "type": "inappropriate_content",
          "confidence": 0.23,
          "source": "automated"
        }
      ],
      "submitted_at": "2024-12-01T15:30:00Z",
      "priority": "medium"
    }
  ],
  "stats": {
    "pending": 47,
    "approved_today": 234,
    "rejected_today": 12,
    "avg_review_time": "2.3 hours"
  }
}
```

### Revenue Reconciliation
```http
GET /admin/revenue/reconciliation?date=2024-12-01

Response:
{
  "date": "2024-12-01",
  "platform_reports": {
    "youtube": {
      "reported_revenue": 2847.50,
      "tracked_revenue": 2847.50,
      "discrepancy": 0.00,
      "videos_processed": 1247
    },
    "tiktok": {
      "reported_revenue": 1524.75,
      "tracked_revenue": 1521.80,
      "discrepancy": 2.95,
      "videos_processed": 847
    }
  },
  "user_payouts": {
    "total_earned": 2186.12,
    "total_credited": 2186.12,
    "users_paid": 1847,
    "roadtrips_granted": 4372
  },
  "reconciliation_status": "completed",
  "discrepancies": [
    {
      "platform": "tiktok",
      "amount": 2.95,
      "reason": "API delay in reporting",
      "resolution": "Will correct in next batch"
    }
  ]
}
```

---

## Referral System

### Get User Referral Code
```http
GET /referrals/me

Response:
{
  "referral_code": "ROAD-NK7P-M4X9",
  "referral_link": "https://Roadtrip-Copilot.com/download?ref=ROAD-NK7P-M4X9",
  "qr_code_url": "https://api.Roadtrip-Copilot.com/qr/ROAD-NK7P-M4X9",
  "stats": {
    "friends_invited": 12,
    "friends_joined": 5,
    "roadtrips_earned": 5,
    "total_earnings_cents": 250
  },
  "recent_activity": [
    {
      "type": "friend_joined",
      "friend_name": "Sarah M.",
      "timestamp": "2024-12-01T15:30:00Z",
      "credits_earned": 1
    },
    {
      "type": "friend_signup",
      "friend_name": "Mike R.",
      "timestamp": "2024-11-29T10:15:00Z",
      "status": "pending_first_trip"
    }
  ]
}
```

### Send Referral Invitation
```http
POST /referrals/invite
{
  "method": "sms", // "sms", "email", "social", "link"
  "recipients": [
    {
      "name": "John Doe",
      "contact": "+1234567890" // phone for SMS, email for email
    }
  ],
  "personal_message": "Check out this amazing app I've been using for road trips!"
}

Response:
{
  "invitations_sent": 1,
  "referral_link": "https://Roadtrip-Copilot.com/download?ref=ROAD-NK7P-M4X9",
  "tracking_ids": ["inv_abc123"],
  "message": "Invitation sent successfully!"
}
```

### Check Referral Eligibility (10th Trip Trigger)
```http
POST /referrals/check-milestone
{
  "event": "trip_completed",
  "trip_number": 10
}

Response:
{
  "show_referral_popup": true,
  "milestone": "tenth_trip",
  "popup_config": {
    "title": "🎉 You've completed 10 roadtrips!",
    "message": "Love discovering amazing places? Share Roadtrip-Copilot with friends and you could both earn FREE roadtrips!",
    "incentive": "You could get 1 FREE roadtrip for each friend who signs up",
    "delay_seconds": 2
  }
}
```

### Track Referral Events
```http
POST /referrals/track
{
  "event": "popup_shown", // "popup_shown", "popup_dismissed", "share_clicked", "link_copied"
  "milestone": "tenth_trip",
  "metadata": {
    "share_method": "native_share",
    "user_action": "share_with_friends"
  }
}

Response:
{
  "tracked": true,
  "next_reminder": "2024-12-15T12:00:00Z" // When to show next reminder
}
```

### Get Referral Analytics
```http
GET /referrals/analytics?period=30d

Response:
{
  "period": "30d",
  "conversion_funnel": {
    "invitations_sent": 25,
    "links_clicked": 18,
    "apps_downloaded": 12,
    "signups_completed": 8,
    "first_trips_taken": 5
  },
  "performance_metrics": {
    "click_through_rate": 0.72,
    "conversion_rate": 0.44,
    "referral_value": 250, // cents earned
    "average_time_to_signup": "2.3 days"
  },
  "top_performing_channels": [
    {"method": "sms", "conversions": 3, "rate": 0.60},
    {"method": "social", "conversions": 2, "rate": 0.40}
  ]
}
```

---

## Webhooks

### Platform Revenue Updates
```http
POST {webhook_url}/revenue-update
{
  "event": "revenue_update",
  "platform": "youtube",
  "video_id": "abc123",
  "date": "2024-12-01",
  "revenue": 47.25,
  "views": 8540,
  "metadata": {
    "watch_time": 89420,
    "subscriber_views": 2341
  }
}
```

### Video Upload Confirmation
```http
POST {webhook_url}/video-uploaded
{
  "event": "video_uploaded",
  "video_id": "uuid",
  "platform": "tiktok",
  "platform_video_id": "tiktok123",
  "status": "published",
  "url": "https://tiktok.com/@Roadtrip-Copilot/video/123",
  "upload_time": "2024-12-01T16:00:00Z"
}
```

---

## Error Responses

### Standard Error Format
```json
{
  "error": {
    "code": "DISCOVERY_NOT_FOUND",
    "message": "Discovery with ID 'uuid' not found",
    "details": {
      "user_id": "uuid",
      "requested_id": "invalid-uuid"
    },
    "timestamp": "2024-12-01T16:30:00Z",
    "request_id": "req_abc123"
  }
}
```

### Common Error Codes

- `UNAUTHORIZED` (401) - Invalid or expired token
- `FORBIDDEN` (403) - Insufficient permissions
- `NOT_FOUND` (404) - Resource not found
- `VALIDATION_ERROR` (422) - Invalid request data
- `RATE_LIMITED` (429) - Too many requests
- `SERVER_ERROR` (500) - Internal server error

### Discovery-Specific Errors

- `DUPLICATE_DISCOVERY` (409) - POI already exists in database
- `INVALID_LOCATION` (422) - Location coordinates invalid
- `GENERATION_FAILED` (500) - Video generation failed
- `UPLOAD_FAILED` (500) - Social media upload failed

---

## Rate Limits

### Default Limits
- **Authentication**: 10 requests/minute
- **Discovery submissions**: 20 requests/hour
- **Dashboard/Analytics**: 100 requests/minute
- **Admin APIs**: 1000 requests/minute

### Headers
```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1638360000
X-RateLimit-Type: user
```

---

## SDK Examples

### JavaScript/TypeScript
```typescript
import { Roadtrip-CopilotAPI } from '@Roadtrip-Copilot/sdk';

const api = new Roadtrip-CopilotAPI({
  apiKey: 'your-api-key',
  baseURL: 'https://api.Roadtrip-Copilot.com/v1'
});

// Submit discovery
const discovery = await api.discoveries.create({
  poi_data: {
    name: "Joe's BBQ",
    location: { lat: 37.7749, lng: -122.4194 },
    category: "restaurant"
  }
});

// Get earnings
const earnings = await api.earnings.getSummary({ period: '30d' });
```

### Python
```python
from poi_companion import Roadtrip-CopilotClient

client = Roadtrip-CopilotClient(api_key='your-api-key')

# Submit discovery
discovery = client.discoveries.create({
    'poi_data': {
        'name': "Joe's BBQ",
        'location': {'lat': 37.7749, 'lng': -122.4194},
        'category': 'restaurant'
    }
})

# Get dashboard data
dashboard = client.dashboard.get()
```

---

## POI-Discovery Crowdsourcing APIs

### Chrome Extension Integration

#### Submit POI for Validation
```http
POST /crowdsourcing/submit
Authorization: Bearer {token}

{
  "poi_data": {
    "name": "Joe's Authentic BBQ",
    "category": "restaurant",
    "subcategory": "bbq",
    "coordinates": {
      "lat": 37.7749,
      "lng": -122.4194
    },
    "address": "123 Main St, San Francisco, CA 94102",
    "description": "Family-owned BBQ joint serving incredible pulled pork since 1952. Famous for their smoky ribs and homemade sauces.",
    "photos": [
      {
        "url": "https://example.com/photo1.jpg",
        "description": "Exterior view showing vintage neon sign"
      },
      {
        "url": "https://example.com/photo2.jpg", 
        "description": "Signature pulled pork sandwich with fries"
      }
    ],
    "source_platform": "google_maps",
    "source_urls": [
      "https://maps.google.com/place/joes-bbq/..."
    ],
    "operating_hours": {
      "monday": "11:00-21:00",
      "tuesday": "11:00-21:00",
      "wednesday": "11:00-21:00",
      "thursday": "11:00-21:00",
      "friday": "11:00-22:00",
      "saturday": "11:00-22:00",
      "sunday": "12:00-20:00"
    }
  },
  "submission_metadata": {
    "discovery_method": "chrome_extension_v1",
    "user_location": "US-CA",
    "submission_confidence": 0.89
  }
}

Response:
{
  "submission_id": "uuid",
  "status": "pending_validation", // pending_validation, under_review, approved, rejected
  "validation_result": {
    "uniqueness_check": {
      "is_unique": true,
      "confidence": 0.92,
      "similar_pois_found": 0
    },
    "ai_quality_assessment": {
      "total_score": 8.7,
      "breakdown": {
        "uniqueness": 2.8,
        "completeness": 1.9,
        "photo_quality": 1.8,
        "accuracy": 1.7,
        "cultural_value": 0.5
      },
      "feedback": "Excellent submission with comprehensive details and high-quality photos.",
      "recommendation": "approve_for_review"
    }
  },
  "estimated_reward": {
    "base_amount": 0.10,
    "quality_multiplier": 1.5,
    "currency_multiplier": 1.0,
    "final_amount": 0.15,
    "currency": "USD"
  },
  "review_timeline": {
    "estimated_completion": "2024-12-01T20:00:00Z",
    "review_type": "community", // ai_only, community, expert_review
    "reviewers_assigned": 3
  }
}
```

#### Check POI Uniqueness (Pre-submission)
```http
POST /crowdsourcing/check-uniqueness
Authorization: Bearer {token}

{
  "name": "Joe's BBQ",
  "coordinates": {
    "lat": 37.7749,
    "lng": -122.4194
  },
  "category": "restaurant"
}

Response:
{
  "is_unique": false,
  "confidence": 0.95,
  "similar_pois": [
    {
      "id": "existing-poi-uuid",
      "name": "Joe's Authentic BBQ",
      "distance_meters": 15,
      "similarity_score": 0.97,
      "status": "already_exists"
    }
  ],
  "recommendation": "duplicate_detected",
  "message": "A very similar POI already exists in our database."
}
```

#### Get Submission Status
```http
GET /crowdsourcing/submissions/{submission_id}

Response:
{
  "id": "uuid",
  "status": "under_review",
  "poi_name": "Joe's Authentic BBQ",
  "submitted_at": "2024-12-01T15:30:00Z",
  "review_progress": {
    "ai_assessment": {
      "completed": true,
      "score": 8.7,
      "passed": true
    },
    "community_review": {
      "completed": false,
      "reviews_received": 2,
      "reviews_needed": 3,
      "current_average": 8.5
    }
  },
  "estimated_reward": {
    "current_estimate": 0.15,
    "currency": "USD",
    "factors": {
      "quality_bonus": true,
      "uniqueness_bonus": false,
      "category_multiplier": 1.0
    }
  },
  "timeline": {
    "estimated_completion": "2024-12-01T20:00:00Z",
    "reviews_deadline": "2024-12-01T18:00:00Z"
  }
}
```

### Community Review System

#### Get Review Assignments
```http
GET /crowdsourcing/reviews/assigned?status=pending&page=1&limit=10

Response:
{
  "reviews": [
    {
      "id": "review-uuid",
      "submission_id": "submission-uuid",
      "poi_data": {
        "name": "Mountain View Cafe",
        "category": "restaurant",
        "coordinates": { "lat": 37.7749, "lng": -122.4194 },
        "description": "Cozy cafe with mountain views...",
        "photos": ["url1", "url2"]
      },
      "assigned_at": "2024-12-01T15:30:00Z",
      "deadline": "2024-12-02T15:30:00Z",
      "compensation": 0.25,
      "review_criteria": {
        "focus_areas": ["uniqueness", "photo_quality"],
        "regional_expertise": true,
        "category_knowledge": "restaurants"
      }
    }
  ],
  "summary": {
    "total_assigned": 5,
    "pending_reviews": 3,
    "completed_today": 2,
    "earnings_today": 0.50
  }
}
```

#### Submit Review
```http
POST /crowdsourcing/reviews
Authorization: Bearer {token}

{
  "submission_id": "uuid",
  "scores": {
    "uniqueness": 3,        // 0-3 points
    "completeness": 2,      // 0-2 points
    "photo_quality": 2,     // 0-2 points
    "accuracy": 2,          // 0-2 points
    "cultural_value": 1     // 0-1 points
  },
  "feedback": "Excellent submission! The photos clearly show the unique mountain views and the description provides helpful details about atmosphere and specialties. Location accuracy verified through Street View.",
  "recommendation": "approve", // approve, reject, needs_improvement
  "review_time_minutes": 8
}

Response:
{
  "review_id": "uuid",
  "status": "submitted",
  "compensation_earned": 0.25,
  "total_score": 10,
  "submission_update": {
    "total_reviews": 3,
    "average_score": 8.7,
    "consensus_reached": true,
    "final_status": "approved"
  }
}
```

### User Earnings & Analytics

#### Get Crowdsourcing Dashboard
```http
GET /crowdsourcing/dashboard?period=30d

Response:
{
  "overview": {
    "total_submissions": 24,
    "approved_submissions": 18,
    "pending_submissions": 4,
    "rejected_submissions": 2,
    "total_earned": 3.75,
    "reviews_completed": 45,
    "review_earnings": 11.25
  },
  "performance_metrics": {
    "approval_rate": 0.75,
    "average_quality_score": 8.2,
    "average_earnings_per_submission": 0.21,
    "ranking": {
      "position": 47,
      "total_submitters": 2847,
      "percentile": 98
    }
  },
  "recent_activity": [
    {
      "type": "submission_approved",
      "poi_name": "Hidden Falls Trail",
      "earned": 0.25,
      "timestamp": "2024-12-01T14:30:00Z"
    },
    {
      "type": "review_completed",
      "poi_name": "Local Art Gallery",
      "earned": 0.25,
      "timestamp": "2024-12-01T13:15:00Z"
    }
  ],
  "category_performance": [
    {
      "category": "natural_attractions",
      "submissions": 8,
      "approved": 7,
      "avg_reward": 0.18,
      "total_earned": 1.26
    },
    {
      "category": "restaurants", 
      "submissions": 12,
      "approved": 9,
      "avg_reward": 0.12,
      "total_earned": 1.08
    }
  ]
}
```

#### Get Top Earners Leaderboard
```http
GET /crowdsourcing/leaderboard?period=monthly&region=global&limit=100

Response:
{
  "leaderboard": [
    {
      "rank": 1,
      "user": {
        "username": "poi_hunter_2024",
        "country_code": "IN",
        "badge": "Elite Discoverer"
      },
      "stats": {
        "submissions": 147,
        "approved": 134,
        "total_earned": 28.50,
        "avg_quality": 8.9,
        "specialties": ["cultural_sites", "hidden_gems"]
      }
    }
  ],
  "user_rank": {
    "position": 47,
    "percentile": 98,
    "stats": {
      "submissions": 24,
      "approved": 18,
      "total_earned": 3.75
    }
  },
  "regional_breakdown": [
    {
      "country": "India",
      "active_users": 847,
      "total_submissions": 12458,
      "avg_earning": 2.34
    },
    {
      "country": "Philippines", 
      "active_users": 523,
      "total_submissions": 7832,
      "avg_earning": 3.12
    }
  ]
}
```

### Payment Management

#### Get Payment Information
```http
GET /crowdsourcing/payment-info

Response:
{
  "payment_setup": {
    "status": "active", // pending, active, verification_needed
    "stripe_account_id": "acct_123456789",
    "country_code": "IN",
    "preferred_method": "bank_transfer",
    "minimum_payout": 5.00
  },
  "current_balance": {
    "total_earned": 15.25,
    "pending_payout": 12.50,
    "last_payout": {
      "amount": 2.75,
      "date": "2024-11-25T10:00:00Z",
      "method": "bank_transfer"
    }
  },
  "payout_schedule": {
    "frequency": "weekly", // weekly, bi_weekly, monthly
    "next_payout_date": "2024-12-08T10:00:00Z",
    "estimated_amount": 12.50
  }
}
```

#### Setup Payment Account
```http
POST /crowdsourcing/payment-setup
Authorization: Bearer {token}

{
  "country_code": "IN",
  "currency_preference": "USD",
  "payment_method": "bank_transfer",
  "bank_details": {
    "account_holder_name": "Student Name",
    "routing_number": "123456789",
    "account_number": "987654321",
    "bank_name": "State Bank of India"
  },
  "identity_verification": {
    "government_id_type": "passport",
    "document_url": "https://secure-uploads.Roadtrip-Copilot.com/id123.jpg"
  }
}

Response:
{
  "setup_status": "verification_pending",
  "stripe_account_id": "acct_123456789",
  "onboarding_url": "https://connect.stripe.com/setup/s/acct_123456789",
  "requirements": [
    "identity_verification",
    "bank_account_verification"
  ],
  "estimated_verification_time": "2-5 business days"
}
```

#### Request Manual Payout
```http
POST /crowdsourcing/request-payout
Authorization: Bearer {token}

{
  "amount": 10.00, // Must be >= minimum_payout_amount
  "currency": "USD"
}

Response:
{
  "payout_id": "payout_123456789",
  "status": "processing", // processing, completed, failed
  "amount": 10.00,
  "estimated_arrival": "2024-12-03T10:00:00Z",
  "fees": {
    "stripe_fee": 0.25,
    "net_amount": 9.75
  }
}
```

### Admin & Moderation APIs

#### Get Crowdsourcing Analytics
```http
GET /admin/crowdsourcing/analytics?period=7d
Authorization: Bearer {admin_token}

Response:
{
  "submission_metrics": {
    "total_submissions": 1247,
    "submissions_today": 89,
    "approval_rate": 0.73,
    "avg_processing_time_hours": 4.2,
    "quality_score_distribution": {
      "excellent_9_10": 234,
      "good_8_9": 567,
      "fair_7_8": 289,
      "poor_below_7": 157
    }
  },
  "user_metrics": {
    "active_submitters": 847,
    "new_users_this_week": 67,
    "top_countries": [
      {"country": "IN", "users": 234, "submissions": 456},
      {"country": "PH", "users": 123, "submissions": 267},
      {"country": "VN", "users": 98, "submissions": 189}
    ]
  },
  "financial_metrics": {
    "total_rewards_paid": 1247.50,
    "average_reward": 0.18,
    "pending_payouts": 2847.25,
    "platform_roi": {
      "cost_per_poi": 0.18,
      "estimated_value_per_poi": 2.50,
      "roi_multiple": 13.9
    }
  }
}
```

#### Moderate Submissions
```http
GET /admin/crowdsourcing/moderation/queue?status=flagged&priority=high

Response:
{
  "queue": [
    {
      "submission_id": "uuid",
      "poi_name": "Questionable Location",
      "submitter": "user123",
      "flags": [
        {
          "type": "inappropriate_content",
          "confidence": 0.85,
          "details": "Potential adult content in photos"
        },
        {
          "type": "duplicate_submission",
          "confidence": 0.72,
          "similar_poi_id": "uuid-similar"
        }
      ],
      "community_reports": 2,
      "priority": "high",
      "submitted_at": "2024-12-01T15:30:00Z"
    }
  ],
  "queue_stats": {
    "total_flagged": 23,
    "high_priority": 5,
    "avg_resolution_time": "2.3 hours"
  }
}
```

#### Approve/Reject Submissions
```http
POST /admin/crowdsourcing/moderation/decision
Authorization: Bearer {admin_token}

{
  "submission_id": "uuid",
  "decision": "approve", // approve, reject, request_changes
  "admin_notes": "High-quality submission with excellent photos and comprehensive details.",
  "reward_adjustment": {
    "modified_amount": 0.20,
    "reason": "Bonus for exceptional quality"
  }
}

Response:
{
  "decision_id": "uuid",
  "status": "approved",
  "reward_processed": true,
  "user_notified": true,
  "rag_integration_queued": true
}
```

This comprehensive crowdsourcing API enables the POI-Discovery platform to manage the entire lifecycle of user-submitted POIs, from initial validation through community review to final payment processing, while providing robust analytics and moderation capabilities for administrators.</parameter>
</invoke>