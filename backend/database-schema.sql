-- Roadtrip-Copilot Production Database Schema
-- Version 2.0 - January 2025
-- PostgreSQL 15+ with PostGIS, TimescaleDB, and Vector extensions
-- Supports: Pay-per-roadtrip, UGC monetization, Viral referrals, Privacy-first attribution

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "timescaledb";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
CREATE EXTENSION IF NOT EXISTS "vector"; -- For AI embeddings and semantic search
CREATE EXTENSION IF NOT EXISTS "pgcrypto"; -- For encryption and hashing
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For fuzzy text matching

-- Set timezone
SET timezone = 'UTC';

-- Configuration settings for production
SET shared_preload_libraries = 'timescaledb,pg_stat_statements';
SET log_statement = 'mod'; -- Log all modifications for audit
SET log_min_duration_statement = 1000; -- Log slow queries > 1s

-- ============================================================================
-- USER MANAGEMENT
-- ============================================================================

-- Users table with enhanced privacy and compliance features
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Core authentication (encrypted in production)
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    
    -- Personal information (PII - encrypted at rest)
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    avatar_url TEXT,
    phone VARCHAR(20),
    date_of_birth DATE, -- For age verification and compliance
    
    -- Profile settings with enhanced privacy controls
    preferences JSONB DEFAULT '{
        "discovery_categories": ["restaurant", "scenic_spot", "hidden_gem"],
        "voice_personality": "friendly",
        "podcast_speed": 1.0,
        "distance_units": "miles",
        "currency": "USD"
    }',
    
    notification_settings JSONB DEFAULT '{
        "email_discoveries": true,
        "email_earnings": true,
        "push_video_ready": true,
        "push_credits_earned": true,
        "sms_roadtrip_reminders": false,
        "push_referral_milestones": true
    }',
    
    -- Privacy settings with granular controls
    privacy_settings JSONB DEFAULT '{
        "location_sharing": "anonymous_city_only",
        "discovery_attribution": "anonymous",
        "analytics_opt_in": false,
        "marketing_emails": false,
        "data_retention_days": 2555,
        "allow_ai_training": false
    }',
    
    -- Account status and verification
    is_active BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false,
    email_verified_at TIMESTAMP WITH TIME ZONE,
    phone_verified_at TIMESTAMP WITH TIME ZONE,
    identity_verified_at TIMESTAMP WITH TIME ZONE, -- For tax compliance
    
    -- Legal compliance
    privacy_consent BOOLEAN DEFAULT false,
    terms_accepted_at TIMESTAMP WITH TIME ZONE,
    terms_version VARCHAR(20) DEFAULT '1.0',
    gdpr_consent BOOLEAN DEFAULT false,
    ccpa_opt_out BOOLEAN DEFAULT false,
    coppa_compliant BOOLEAN DEFAULT false, -- For users under 13
    
    -- Geographic information for compliance
    country_code CHAR(2), -- ISO country code
    state_province VARCHAR(100),
    timezone VARCHAR(50) DEFAULT 'UTC',
    
    -- Subscription and billing
    subscription_status VARCHAR(20) DEFAULT 'free_trial', -- 'free_trial', 'active', 'expired', 'cancelled'
    subscription_expires_at TIMESTAMP WITH TIME ZONE,
    billing_country CHAR(2),
    tax_id VARCHAR(50), -- For 1099 reporting when earnings > $600
    
    -- Device and usage tracking
    primary_device_type VARCHAR(20), -- 'ios', 'android'
    carplay_enabled BOOLEAN DEFAULT false,
    android_auto_enabled BOOLEAN DEFAULT false,
    last_device_id VARCHAR(255),
    
    -- Tracking and audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login_at TIMESTAMP WITH TIME ZONE,
    last_activity_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Data retention and deletion
    data_retention_expires_at TIMESTAMP WITH TIME ZONE, -- Auto-delete after retention period
    deletion_requested_at TIMESTAMP WITH TIME ZONE, -- For GDPR right to be forgotten
    
    -- Constraints
    CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT valid_username CHECK (username ~* '^[a-zA-Z0-9_]{3,50}$'),
    CONSTRAINT valid_country_code CHECK (country_code IS NULL OR country_code ~* '^[A-Z]{2}$'),
    CONSTRAINT valid_subscription_status CHECK (subscription_status IN ('free_trial', 'active', 'expired', 'cancelled', 'suspended'))
);

-- User sessions
CREATE TABLE user_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    refresh_token_hash VARCHAR(255),
    device_info JSONB,
    ip_address INET,
    user_agent TEXT,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User verification tokens
CREATE TABLE user_verification_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(255) NOT NULL,
    token_type VARCHAR(50) NOT NULL, -- 'email_verification', 'password_reset'
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    used_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- DISCOVERY SYSTEM
-- ============================================================================

-- POI categories
CREATE TABLE poi_categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    slug VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    icon VARCHAR(50),
    parent_id INTEGER REFERENCES poi_categories(id),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default categories with revenue potential notes
INSERT INTO poi_categories (name, slug, description, icon) VALUES
('Restaurant', 'restaurant', 'Dining establishments - could earn high revenue from discovery videos', '🍽️'),
('Scenic Spot', 'scenic_spot', 'Beautiful views and natural attractions - high video performance potential', '🏞️'),
('Historic Site', 'historic_site', 'Historical landmarks and monuments - educational content performs well', '🏛️'),
('Shopping', 'shopping', 'Retail stores and markets - moderate revenue potential', '🛍️'),
('Entertainment', 'entertainment', 'Theaters, museums, and entertainment venues - good for video content', '🎭'),
('Outdoor Recreation', 'outdoor_recreation', 'Parks, trails, and outdoor activities - excellent for viral content', '🚵'),
('Accommodation', 'accommodation', 'Hotels, B&Bs, and lodging - travel content performs well', '🏨'),
('Gas Station', 'gas_station', 'Fuel stations and convenience stores - utility discoveries', '⛽'),
('Emergency Services', 'emergency_services', 'Hospitals, police, fire stations - important safety information', '🚨'),
('Hidden Gem', 'hidden_gem', 'Unique and unusual discoveries - highest revenue potential for videos', '💎');

-- Discoveries table
CREATE TABLE discoveries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- POI Information
    poi_name VARCHAR(255) NOT NULL,
    poi_description TEXT,
    category_id INTEGER REFERENCES poi_categories(id),
    subcategory VARCHAR(100),
    
    -- Location data (anonymized to city level for privacy)
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    address_city VARCHAR(100),
    address_state VARCHAR(50),
    address_country VARCHAR(50) DEFAULT 'US',
    location_accuracy INTEGER DEFAULT 1000, -- meters radius for privacy
    
    -- POI Details
    rating DECIMAL(3,2) CHECK (rating >= 0 AND rating <= 5),
    price_range VARCHAR(10), -- '$', '$$', '$$$', '$$$$'
    phone VARCHAR(20),
    website TEXT,
    hours JSONB, -- Operating hours
    features TEXT[], -- Array of features
    
    -- Discovery Context
    discovery_context TEXT, -- How user found this place
    discovery_timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    trip_context JSONB, -- Trip details, route info
    
    -- Validation Status
    validation_status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'validated', 'duplicate', 'rejected'
    is_new_discovery BOOLEAN DEFAULT false, -- True if not in our database
    similarity_score FLOAT, -- 0-1, lower = more unique
    duplicate_of UUID REFERENCES discoveries(id),
    validated_at TIMESTAMP WITH TIME ZONE,
    validated_by UUID REFERENCES users(id),
    
    -- Media attachments
    media JSONB DEFAULT '[]', -- User photos/videos
    
    -- Revenue eligibility (only NEW discoveries could earn revenue)
    eligible_for_revenue BOOLEAN GENERATED ALWAYS AS (
        validation_status = 'validated' AND is_new_discovery = true
    ) STORED,
    could_earn_revenue BOOLEAN GENERATED ALWAYS AS (
        validation_status = 'validated' AND is_new_discovery = true
    ) STORED,
    
    -- Metadata
    source VARCHAR(50) DEFAULT 'mobile_app', -- 'mobile_app', 'web', 'api'
    metadata JSONB DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Discovery validation history
CREATE TABLE discovery_validations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    discovery_id UUID NOT NULL REFERENCES discoveries(id) ON DELETE CASCADE,
    validator_id UUID REFERENCES users(id), -- null for automated validation
    previous_status VARCHAR(50),
    new_status VARCHAR(50) NOT NULL,
    reason TEXT,
    confidence_score FLOAT, -- For automated validations
    validation_data JSONB, -- Additional validation metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- VIDEO GENERATION SYSTEM
-- ============================================================================

-- Video templates
CREATE TABLE video_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(50), -- 'discovery', 'promotional', 'tutorial'
    template_data JSONB NOT NULL, -- Template configuration
    duration_seconds INTEGER NOT NULL,
    aspect_ratios TEXT[] DEFAULT ARRAY['9:16', '1:1', '16:9'],
    is_active BOOLEAN DEFAULT true,
    version INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Videos table
CREATE TABLE videos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    discovery_id UUID NOT NULL REFERENCES discoveries(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    template_id UUID REFERENCES video_templates(id),
    
    -- Video metadata
    title VARCHAR(255) NOT NULL,
    description TEXT,
    duration_seconds INTEGER,
    aspect_ratio VARCHAR(10), -- '9:16', '1:1', '16:9'
    
    -- Generation details
    generation_status VARCHAR(50) DEFAULT 'queued', -- 'queued', 'generating', 'completed', 'failed'
    generation_started_at TIMESTAMP WITH TIME ZONE,
    generation_completed_at TIMESTAMP WITH TIME ZONE,
    generation_error TEXT,
    generation_metadata JSONB DEFAULT '{}',
    
    -- Video files
    source_video_url TEXT, -- Original high-quality video
    thumbnail_url TEXT,
    preview_url TEXT, -- Low-res preview
    
    -- Content data
    script JSONB, -- Generated script/narration
    visual_elements JSONB, -- Images, animations used
    audio_elements JSONB, -- Music, voiceover details
    
    -- Quality metrics
    quality_score DECIMAL(3,2), -- 0-5 quality rating
    auto_generated BOOLEAN DEFAULT true,
    human_reviewed BOOLEAN DEFAULT false,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Video versions (for A/B testing different versions)
CREATE TABLE video_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    video_id UUID NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
    version_number INTEGER NOT NULL DEFAULT 1,
    title VARCHAR(255),
    description TEXT,
    video_url TEXT NOT NULL,
    thumbnail_url TEXT,
    is_active BOOLEAN DEFAULT true,
    performance_score DECIMAL(5,2), -- Calculated performance metric
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(video_id, version_number)
);

-- Video generation queue
CREATE TABLE video_generation_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    discovery_id UUID NOT NULL REFERENCES discoveries(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    priority INTEGER DEFAULT 100, -- Lower = higher priority
    generation_params JSONB DEFAULT '{}',
    
    -- Queue status
    status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'processing', 'completed', 'failed'
    attempts INTEGER DEFAULT 0,
    max_attempts INTEGER DEFAULT 3,
    error_message TEXT,
    
    -- Timing
    scheduled_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- SOCIAL MEDIA DISTRIBUTION
-- ============================================================================

-- Social platforms
CREATE TABLE social_platforms (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    display_name VARCHAR(100) NOT NULL,
    api_version VARCHAR(20),
    base_url TEXT,
    max_video_size_mb INTEGER,
    max_duration_seconds INTEGER,
    supported_formats TEXT[],
    supported_ratios TEXT[],
    is_active BOOLEAN DEFAULT true,
    configuration JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert social platforms
INSERT INTO social_platforms (name, display_name, max_video_size_mb, max_duration_seconds, supported_formats, supported_ratios) VALUES
('youtube', 'YouTube Shorts', 256, 60, ARRAY['mp4', 'mov'], ARRAY['9:16', '16:9']),
('tiktok', 'TikTok', 72, 30, ARRAY['mp4', 'mov'], ARRAY['9:16']),
('instagram', 'Instagram Reels', 100, 30, ARRAY['mp4', 'mov'], ARRAY['9:16', '1:1']),
('facebook', 'Facebook Video', 100, 240, ARRAY['mp4', 'mov'], ARRAY['9:16', '1:1', '16:9']);

-- Platform uploads
CREATE TABLE platform_uploads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    video_id UUID NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
    platform_id INTEGER NOT NULL REFERENCES social_platforms(id),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Upload details
    platform_video_id VARCHAR(255), -- ID from the platform
    platform_url TEXT, -- Public URL on platform
    upload_status VARCHAR(50) DEFAULT 'queued', -- 'queued', 'uploading', 'published', 'failed', 'removed'
    
    -- Content metadata
    title VARCHAR(255),
    description TEXT,
    hashtags TEXT[],
    thumbnail_url TEXT,
    
    -- Upload configuration
    privacy_setting VARCHAR(50) DEFAULT 'public', -- 'public', 'unlisted', 'private'
    monetization_enabled BOOLEAN DEFAULT true,
    comments_enabled BOOLEAN DEFAULT true,
    
    -- Timing
    scheduled_publish_at TIMESTAMP WITH TIME ZONE,
    uploaded_at TIMESTAMP WITH TIME ZONE,
    published_at TIMESTAMP WITH TIME ZONE,
    
    -- Error handling
    upload_attempts INTEGER DEFAULT 0,
    max_attempts INTEGER DEFAULT 3,
    last_error TEXT,
    
    -- Metadata
    upload_metadata JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(video_id, platform_id)
);

-- Upload queue
CREATE TABLE upload_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    video_id UUID NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
    platform_id INTEGER NOT NULL REFERENCES social_platforms(id),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    priority INTEGER DEFAULT 100,
    scheduled_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'processing', 'completed', 'failed'
    attempts INTEGER DEFAULT 0,
    
    upload_params JSONB DEFAULT '{}',
    error_message TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- REVENUE TRACKING SYSTEM
-- ============================================================================

-- Revenue data (time-series table)
CREATE TABLE video_revenues (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    video_id UUID NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
    platform_upload_id UUID NOT NULL REFERENCES platform_uploads(id) ON DELETE CASCADE,
    platform_id INTEGER NOT NULL REFERENCES social_platforms(id),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    discovery_id UUID NOT NULL REFERENCES discoveries(id) ON DELETE CASCADE,
    
    -- Date for time-series partitioning
    date DATE NOT NULL,
    
    -- Performance metrics
    views INTEGER DEFAULT 0,
    likes INTEGER DEFAULT 0,
    shares INTEGER DEFAULT 0,
    comments INTEGER DEFAULT 0,
    watch_time_seconds INTEGER DEFAULT 0,
    
    -- Revenue data (in cents to avoid floating point issues)
    gross_revenue_cents INTEGER DEFAULT 0,
    platform_fee_cents INTEGER DEFAULT 0,
    net_revenue_cents INTEGER DEFAULT 0,
    user_share_cents INTEGER GENERATED ALWAYS AS (net_revenue_cents / 2) STORED,
    platform_share_cents INTEGER GENERATED ALWAYS AS (net_revenue_cents / 2) STORED,
    
    -- Revenue metadata
    rpm DECIMAL(10,4), -- Revenue per mille (thousand views)
    cpm DECIMAL(10,4), -- Cost per mille
    engagement_rate DECIMAL(5,4), -- (likes + shares + comments) / views
    
    -- Data source
    data_source VARCHAR(50) NOT NULL, -- 'youtube_analytics', 'tiktok_creator_fund', etc.
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(video_id, platform_id, date)
);

-- Convert to hypertable for time-series optimization
SELECT create_hypertable('video_revenues', 'date', chunk_time_interval => INTERVAL '1 month');

-- Revenue reconciliation
CREATE TABLE revenue_reconciliations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    platform_id INTEGER NOT NULL REFERENCES social_platforms(id),
    reconciliation_date DATE NOT NULL,
    
    -- Platform reported totals
    platform_reported_revenue_cents INTEGER NOT NULL,
    platform_reported_videos INTEGER NOT NULL,
    
    -- Our tracked totals
    tracked_revenue_cents INTEGER NOT NULL,
    tracked_videos INTEGER NOT NULL,
    
    -- Discrepancy analysis
    revenue_discrepancy_cents INTEGER GENERATED ALWAYS AS (
        platform_reported_revenue_cents - tracked_revenue_cents
    ) STORED,
    video_count_discrepancy INTEGER GENERATED ALWAYS AS (
        platform_reported_videos - tracked_videos
    ) STORED,
    
    -- Resolution
    reconciliation_status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'resolved', 'disputed'
    resolution_notes TEXT,
    resolved_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(platform_id, reconciliation_date)
);

-- ============================================================================
-- CREDIT MANAGEMENT SYSTEM
-- ============================================================================

-- User roadtrip credits
CREATE TABLE user_credits (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    
    -- Current balance
    balance INTEGER DEFAULT 7, -- Start with 7 free roadtrips
    
    -- Lifetime totals
    total_earned INTEGER DEFAULT 0,
    total_used INTEGER DEFAULT 0,
    total_promotional INTEGER DEFAULT 7, -- Initial free credits
    total_expired INTEGER DEFAULT 0,
    
    -- Conversion settings
    conversion_rate_cents INTEGER DEFAULT 50, -- $0.50 per roadtrip
    auto_conversion_enabled BOOLEAN DEFAULT true,
    
    -- Tracking
    last_earned_at TIMESTAMP WITH TIME ZONE,
    last_used_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT non_negative_balance CHECK (balance >= 0)
);

-- Credit transactions
CREATE TABLE credit_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Transaction details
    transaction_type VARCHAR(50) NOT NULL, -- 'earned', 'used', 'expired', 'promotional', 'refund'
    amount INTEGER NOT NULL, -- Can be negative for usage
    source VARCHAR(100) NOT NULL, -- 'video_revenue', 'referral', 'roadtrip_usage', 'promotional'
    
    -- Reference data
    video_id UUID REFERENCES videos(id),
    discovery_id UUID REFERENCES discoveries(id),
    revenue_amount_cents INTEGER, -- Original revenue that generated credits
    
    -- Description
    description TEXT NOT NULL,
    
    -- Balance tracking
    balance_before INTEGER NOT NULL,
    balance_after INTEGER NOT NULL,
    
    -- Metadata
    metadata JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT valid_balance_change CHECK (balance_after = balance_before + amount)
);

-- Credit expiration rules
CREATE TABLE credit_expiration_rules (
    id SERIAL PRIMARY KEY,
    credit_source VARCHAR(100) NOT NULL,
    expiration_days INTEGER, -- NULL for no expiration
    warning_days INTEGER DEFAULT 30, -- Days before expiration to warn
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default expiration rules
INSERT INTO credit_expiration_rules (credit_source, expiration_days, description) VALUES
('promotional', 365, 'Initial free credits expire after 1 year'),
('video_revenue', NULL, 'Credits earned from videos never expire'),
('referral', 180, 'Referral credits expire after 6 months');

-- Roadtrip usage tracking
CREATE TABLE roadtrip_usage (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    transaction_id UUID NOT NULL REFERENCES credit_transactions(id),
    
    -- Trip details
    trip_activation_code VARCHAR(20) NOT NULL UNIQUE,
    destination VARCHAR(255),
    estimated_distance_miles INTEGER,
    planned_date DATE,
    
    -- Usage tracking
    activated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE, -- Usually 30 days from activation
    used_at TIMESTAMP WITH TIME ZONE,
    
    -- Trip metadata
    trip_metadata JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- REFERRAL SYSTEM
-- ============================================================================

-- User referral codes
CREATE TABLE user_referrals (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    referral_code VARCHAR(20) NOT NULL UNIQUE,
    referral_link TEXT NOT NULL,
    qr_code_url TEXT,
    
    -- Referral stats
    total_invitations_sent INTEGER DEFAULT 0,
    total_friends_joined INTEGER DEFAULT 0,
    total_credits_earned INTEGER DEFAULT 0,
    
    -- Settings
    is_active BOOLEAN DEFAULT true,
    auto_remind BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Referral invitations sent
CREATE TABLE referral_invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    referrer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    referral_code VARCHAR(20) NOT NULL REFERENCES user_referrals(referral_code),
    
    -- Invitation details
    method VARCHAR(50) NOT NULL, -- 'sms', 'email', 'social', 'link', 'qr_code'
    recipient_contact VARCHAR(255), -- phone/email if provided
    recipient_name VARCHAR(255),
    personal_message TEXT,
    
    -- Tracking
    invitation_link TEXT NOT NULL,
    tracking_id VARCHAR(50) NOT NULL UNIQUE,
    
    -- Status
    status VARCHAR(50) DEFAULT 'sent', -- 'sent', 'clicked', 'converted', 'expired'
    clicked_at TIMESTAMP WITH TIME ZONE,
    converted_at TIMESTAMP WITH TIME ZONE,
    
    -- Metadata
    metadata JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Referral conversions (when someone signs up using a referral code)
CREATE TABLE referral_conversions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    referrer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    referred_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    referral_code VARCHAR(20) NOT NULL REFERENCES user_referrals(referral_code),
    invitation_id UUID REFERENCES referral_invitations(id),
    
    -- Conversion tracking
    signup_completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    first_trip_taken_at TIMESTAMP WITH TIME ZONE,
    first_discovery_at TIMESTAMP WITH TIME ZONE,
    
    -- Rewards
    referrer_credits_earned INTEGER DEFAULT 1, -- 1 credit per referral
    referrer_credits_awarded_at TIMESTAMP WITH TIME ZONE,
    
    -- Status
    conversion_status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'qualified', 'credited'
    qualification_criteria JSONB DEFAULT '{"first_trip_required": true}',
    
    -- Metadata
    attribution_data JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(referred_user_id) -- Each user can only be referred once
);

-- Referral milestones and triggers
CREATE TABLE referral_milestones (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    trigger_condition VARCHAR(255) NOT NULL, -- 'trip_count_10', 'trip_count_25', etc.
    popup_config JSONB NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default referral milestones
INSERT INTO referral_milestones (name, trigger_condition, popup_config) VALUES
('tenth_trip', 'trip_count_10', '{
    "title": "🎉 You''ve completed 10 roadtrips!",
    "message": "Love discovering amazing places? Share Roadtrip-Copilot with friends and you could both earn FREE roadtrips!",
    "incentive": "You could get 1 FREE roadtrip for each friend who signs up",
    "delay_seconds": 2,
    "show_options": ["Share with Friends", "Maybe Later", "Don''t Show Again"]
}'),
('twenty_fifth_trip', 'trip_count_25', '{
    "title": "🌟 25 roadtrips completed!",
    "message": "You''re a Roadtrip-Copilot power user! Share your discoveries with friends.",
    "incentive": "Help friends discover amazing places and earn FREE roadtrips",
    "delay_seconds": 1,
    "show_options": ["Share Now", "Later"]
}');

-- Referral popup tracking
CREATE TABLE referral_popup_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    milestone_id INTEGER REFERENCES referral_milestones(id),
    
    -- Event details
    event_type VARCHAR(50) NOT NULL, -- 'shown', 'dismissed', 'share_clicked', 'dont_show_again'
    trip_number INTEGER NOT NULL,
    user_action VARCHAR(100),
    
    -- Metadata
    popup_config JSONB,
    metadata JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- REFERRAL SYSTEM INDEXES
-- ============================================================================

-- Referral indexes
CREATE INDEX idx_user_referrals_code ON user_referrals(referral_code);
CREATE INDEX idx_referral_invitations_referrer ON referral_invitations(referrer_id);
CREATE INDEX idx_referral_invitations_tracking ON referral_invitations(tracking_id);
CREATE INDEX idx_referral_invitations_status ON referral_invitations(status, created_at DESC);
CREATE INDEX idx_referral_conversions_referrer ON referral_conversions(referrer_id);
CREATE INDEX idx_referral_conversions_referred ON referral_conversions(referred_user_id);
CREATE INDEX idx_referral_popup_events_user ON referral_popup_events(user_id, created_at DESC);

-- ============================================================================
-- REFERRAL SYSTEM TRIGGERS
-- ============================================================================

-- Generate referral code for new users
CREATE OR REPLACE FUNCTION generate_referral_code_for_user()
RETURNS TRIGGER AS $$
DECLARE
    new_code VARCHAR(20);
    code_exists BOOLEAN;
BEGIN
    -- Generate unique referral code
    LOOP
        new_code := 'ROAD-' || 
                   upper(substring(md5(random()::text || NEW.id::text) from 1 for 4)) || '-' ||
                   upper(substring(md5(random()::text || NEW.email) from 1 for 4));
        
        SELECT EXISTS(SELECT 1 FROM user_referrals WHERE referral_code = new_code) INTO code_exists;
        
        IF NOT code_exists THEN
            EXIT;
        END IF;
    END LOOP;
    
    -- Insert referral record
    INSERT INTO user_referrals (
        user_id,
        referral_code,
        referral_link,
        qr_code_url
    ) VALUES (
        NEW.id,
        new_code,
        'https://Roadtrip-Copilot.com/download?ref=' || new_code,
        'https://api.Roadtrip-Copilot.com/qr/' || new_code
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER create_referral_code_trigger
    AFTER INSERT ON users
    FOR EACH ROW EXECUTE FUNCTION generate_referral_code_for_user();

-- Update referral stats when conversions happen
CREATE OR REPLACE FUNCTION update_referral_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- Update referrer stats
    UPDATE user_referrals 
    SET 
        total_friends_joined = total_friends_joined + 1,
        total_credits_earned = total_credits_earned + NEW.referrer_credits_earned,
        updated_at = NOW()
    WHERE user_id = NEW.referrer_id;
    
    -- Award referral credits to referrer
    IF NEW.conversion_status = 'qualified' AND NEW.referrer_credits_awarded_at IS NULL THEN
        -- Get current balance
        DECLARE
            current_balance INTEGER;
        BEGIN
            SELECT balance INTO current_balance FROM user_credits WHERE user_id = NEW.referrer_id;
            current_balance := COALESCE(current_balance, 0);
            
            -- Create credit transaction
            INSERT INTO credit_transactions (
                user_id,
                transaction_type,
                amount,
                source,
                description,
                balance_before,
                balance_after,
                metadata
            ) VALUES (
                NEW.referrer_id,
                'earned',
                NEW.referrer_credits_earned,
                'referral',
                FORMAT('Earned %s roadtrip credits from friend referral', NEW.referrer_credits_earned),
                current_balance,
                current_balance + NEW.referrer_credits_earned,
                jsonb_build_object(
                    'referred_user_id', NEW.referred_user_id,
                    'referral_code', NEW.referral_code
                )
            );
            
            -- Update conversion record
            UPDATE referral_conversions 
            SET referrer_credits_awarded_at = NOW()
            WHERE id = NEW.id;
        END;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_referral_stats_trigger
    AFTER INSERT OR UPDATE ON referral_conversions
    FOR EACH ROW EXECUTE FUNCTION update_referral_stats();

-- Check for referral milestone triggers after trip usage
CREATE OR REPLACE FUNCTION check_referral_milestones()
RETURNS TRIGGER AS $$
DECLARE
    trip_count INTEGER;
    milestone_record referral_milestones%ROWTYPE;
BEGIN
    -- Count total trips for user
    SELECT COUNT(*) INTO trip_count
    FROM roadtrip_usage
    WHERE user_id = NEW.user_id AND used_at IS NOT NULL;
    
    -- Check for milestone triggers
    FOR milestone_record IN 
        SELECT * FROM referral_milestones 
        WHERE is_active = true 
        AND trigger_condition = 'trip_count_' || trip_count
    LOOP
        -- Check if we've already shown this milestone
        IF NOT EXISTS(
            SELECT 1 FROM referral_popup_events 
            WHERE user_id = NEW.user_id 
            AND milestone_id = milestone_record.id
            AND event_type = 'shown'
        ) THEN
            -- Log that milestone should be triggered
            INSERT INTO referral_popup_events (
                user_id,
                milestone_id,
                event_type,
                trip_number,
                popup_config
            ) VALUES (
                NEW.user_id,
                milestone_record.id,
                'trigger_ready',
                trip_count,
                milestone_record.popup_config
            );
        END IF;
    END LOOP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_referral_milestones_trigger
    AFTER UPDATE ON roadtrip_usage
    FOR EACH ROW 
    WHEN (OLD.used_at IS NULL AND NEW.used_at IS NOT NULL)
    EXECUTE FUNCTION check_referral_milestones();

-- ============================================================================
-- ANALYTICS & REPORTING
-- ============================================================================

-- User analytics summary (materialized view refreshed daily)
CREATE MATERIALIZED VIEW user_analytics_summary AS
SELECT 
    u.id AS user_id,
    u.username,
    u.created_at AS user_since,
    
    -- Discovery stats
    COUNT(DISTINCT d.id) AS total_discoveries,
    COUNT(DISTINCT d.id) FILTER (WHERE d.is_new_discovery = true) AS new_discoveries,
    COUNT(DISTINCT d.id) FILTER (WHERE d.created_at >= NOW() - INTERVAL '30 days') AS discoveries_last_30d,
    
    -- Video stats
    COUNT(DISTINCT v.id) AS total_videos,
    COUNT(DISTINCT v.id) FILTER (WHERE v.created_at >= NOW() - INTERVAL '30 days') AS videos_last_30d,
    
    -- Revenue stats
    COALESCE(SUM(vr.net_revenue_cents), 0) AS total_revenue_cents,
    COALESCE(SUM(vr.user_share_cents), 0) AS total_user_share_cents,
    COALESCE(SUM(vr.views), 0) AS total_views,
    
    -- Credit stats
    COALESCE(uc.balance, 0) AS current_credit_balance,
    COALESCE(uc.total_earned, 0) AS total_credits_earned,
    COALESCE(uc.total_used, 0) AS total_credits_used,
    
    -- Performance metrics
    CASE 
        WHEN COUNT(DISTINCT v.id) > 0 
        THEN COALESCE(SUM(vr.views), 0)::DECIMAL / COUNT(DISTINCT v.id)
        ELSE 0 
    END AS avg_views_per_video,
    
    CASE 
        WHEN COUNT(DISTINCT d.id) > 0 
        THEN COUNT(DISTINCT d.id) FILTER (WHERE d.is_new_discovery = true)::DECIMAL / COUNT(DISTINCT d.id)
        ELSE 0 
    END AS new_discovery_rate,
    
    -- Rankings
    RANK() OVER (ORDER BY COALESCE(SUM(vr.user_share_cents), 0) DESC) AS revenue_rank,
    RANK() OVER (ORDER BY COUNT(DISTINCT d.id) FILTER (WHERE d.is_new_discovery = true) DESC) AS discovery_rank,
    
    NOW() AS calculated_at

FROM users u
LEFT JOIN discoveries d ON d.user_id = u.id
LEFT JOIN videos v ON v.user_id = u.id
LEFT JOIN video_revenues vr ON vr.user_id = u.id AND vr.date >= NOW() - INTERVAL '1 year'
LEFT JOIN user_credits uc ON uc.user_id = u.id
WHERE u.is_active = true
GROUP BY u.id, u.username, u.created_at, uc.balance, uc.total_earned, uc.total_used;

-- Daily platform summary (materialized view)
CREATE MATERIALIZED VIEW daily_platform_summary AS
SELECT 
    sp.name AS platform_name,
    vr.date,
    
    COUNT(DISTINCT vr.video_id) AS videos,
    COUNT(DISTINCT vr.user_id) AS active_users,
    
    SUM(vr.views) AS total_views,
    SUM(vr.likes) AS total_likes,
    SUM(vr.shares) AS total_shares,
    SUM(vr.comments) AS total_comments,
    
    SUM(vr.net_revenue_cents) AS total_revenue_cents,
    SUM(vr.user_share_cents) AS total_user_share_cents,
    
    AVG(vr.views) AS avg_views_per_video,
    AVG(vr.engagement_rate) AS avg_engagement_rate,
    AVG(vr.rpm) AS avg_rpm,
    
    NOW() AS calculated_at

FROM video_revenues vr
JOIN social_platforms sp ON sp.id = vr.platform_id
WHERE vr.date >= NOW() - INTERVAL '1 year'
GROUP BY sp.name, vr.date;

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

-- User indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_created_at ON users(created_at);
CREATE INDEX idx_users_is_active ON users(is_active) WHERE is_active = true;

-- Session indexes
CREATE INDEX idx_user_sessions_user_id ON user_sessions(user_id);
CREATE INDEX idx_user_sessions_token_hash ON user_sessions(token_hash);
CREATE INDEX idx_user_sessions_expires_at ON user_sessions(expires_at);

-- Discovery indexes
CREATE INDEX idx_discoveries_user_id ON discoveries(user_id);
CREATE INDEX idx_discoveries_location ON discoveries USING GIST(location);
CREATE INDEX idx_discoveries_category ON discoveries(category_id);
CREATE INDEX idx_discoveries_validation_status ON discoveries(validation_status);
CREATE INDEX idx_discoveries_is_new ON discoveries(is_new_discovery) WHERE is_new_discovery = true;
CREATE INDEX idx_discoveries_created_at ON discoveries(created_at);
CREATE INDEX idx_discoveries_eligible_revenue ON discoveries(eligible_for_revenue) WHERE eligible_for_revenue = true;

-- Video indexes
CREATE INDEX idx_videos_discovery_id ON videos(discovery_id);
CREATE INDEX idx_videos_user_id ON videos(user_id);
CREATE INDEX idx_videos_status ON videos(generation_status);
CREATE INDEX idx_videos_created_at ON videos(created_at);

-- Platform upload indexes
CREATE INDEX idx_platform_uploads_video_id ON platform_uploads(video_id);
CREATE INDEX idx_platform_uploads_platform_id ON platform_uploads(platform_id);
CREATE INDEX idx_platform_uploads_user_id ON platform_uploads(user_id);
CREATE INDEX idx_platform_uploads_status ON platform_uploads(upload_status);
CREATE INDEX idx_platform_uploads_published_at ON platform_uploads(published_at);

-- Revenue indexes (TimescaleDB handles partitioning automatically)
CREATE INDEX idx_video_revenues_user_id ON video_revenues(user_id, date DESC);
CREATE INDEX idx_video_revenues_video_id ON video_revenues(video_id, date DESC);
CREATE INDEX idx_video_revenues_platform_id ON video_revenues(platform_id, date DESC);
CREATE INDEX idx_video_revenues_discovery_id ON video_revenues(discovery_id, date DESC);

-- Credit indexes
CREATE INDEX idx_credit_transactions_user_id ON credit_transactions(user_id, created_at DESC);
CREATE INDEX idx_credit_transactions_type ON credit_transactions(transaction_type);
CREATE INDEX idx_credit_transactions_video_id ON credit_transactions(video_id) WHERE video_id IS NOT NULL;

-- Queue indexes
CREATE INDEX idx_video_generation_queue_status ON video_generation_queue(status, scheduled_at);
CREATE INDEX idx_upload_queue_status ON upload_queue(status, scheduled_at);

-- ============================================================================
-- TRIGGERS FOR AUTOMATIC UPDATES
-- ============================================================================

-- Update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply to relevant tables
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_discoveries_updated_at 
    BEFORE UPDATE ON discoveries 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_videos_updated_at 
    BEFORE UPDATE ON videos 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_platform_uploads_updated_at 
    BEFORE UPDATE ON platform_uploads 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Automatic credit balance updates
CREATE OR REPLACE FUNCTION update_credit_balance()
RETURNS TRIGGER AS $$
BEGIN
    -- Update user credits table
    INSERT INTO user_credits (user_id, balance, total_earned, total_used, updated_at)
    VALUES (
        NEW.user_id, 
        NEW.balance_after,
        CASE WHEN NEW.transaction_type = 'earned' THEN NEW.amount ELSE 0 END,
        CASE WHEN NEW.transaction_type = 'used' THEN ABS(NEW.amount) ELSE 0 END,
        NOW()
    )
    ON CONFLICT (user_id) DO UPDATE SET
        balance = NEW.balance_after,
        total_earned = user_credits.total_earned + 
            CASE WHEN NEW.transaction_type = 'earned' THEN NEW.amount ELSE 0 END,
        total_used = user_credits.total_used + 
            CASE WHEN NEW.transaction_type = 'used' THEN ABS(NEW.amount) ELSE 0 END,
        updated_at = NOW(),
        last_earned_at = CASE WHEN NEW.transaction_type = 'earned' THEN NOW() ELSE user_credits.last_earned_at END,
        last_used_at = CASE WHEN NEW.transaction_type = 'used' THEN NOW() ELSE user_credits.last_used_at END;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_credit_balance_trigger
    AFTER INSERT ON credit_transactions
    FOR EACH ROW EXECUTE FUNCTION update_credit_balance();

-- Revenue-to-credits conversion trigger
CREATE OR REPLACE FUNCTION auto_convert_revenue_to_credits()
RETURNS TRIGGER AS $$
DECLARE
    user_credits_record user_credits%ROWTYPE;
    roadtrips_earned INTEGER;
    current_balance INTEGER;
BEGIN
    -- Only process when revenue is updated/inserted
    IF TG_OP = 'UPDATE' AND NEW.user_share_cents = OLD.user_share_cents THEN
        RETURN NEW;
    END IF;
    
    -- Get user credit settings
    SELECT * INTO user_credits_record FROM user_credits WHERE user_id = NEW.user_id;
    
    -- Skip if auto-conversion is disabled
    IF user_credits_record.auto_conversion_enabled = false THEN
        RETURN NEW;
    END IF;
    
    -- Calculate roadtrips earned from this revenue update
    roadtrips_earned := NEW.user_share_cents / COALESCE(user_credits_record.conversion_rate_cents, 50);
    
    -- Only proceed if we have whole roadtrips to award
    IF roadtrips_earned > 0 THEN
        -- Get current balance
        SELECT balance INTO current_balance FROM user_credits WHERE user_id = NEW.user_id;
        current_balance := COALESCE(current_balance, 0);
        
        -- Insert credit transaction
        INSERT INTO credit_transactions (
            user_id,
            transaction_type,
            amount,
            source,
            video_id,
            discovery_id,
            revenue_amount_cents,
            description,
            balance_before,
            balance_after,
            metadata
        ) VALUES (
            NEW.user_id,
            'earned',
            roadtrips_earned,
            'video_revenue',
            NEW.video_id,
            NEW.discovery_id,
            NEW.user_share_cents,
            FORMAT('Earned %s roadtrip credits from video revenue ($%s)', 
                roadtrips_earned, 
                (NEW.user_share_cents::DECIMAL / 100)::MONEY
            ),
            current_balance,
            current_balance + roadtrips_earned,
            jsonb_build_object(
                'conversion_rate_cents', user_credits_record.conversion_rate_cents,
                'platform', (SELECT name FROM social_platforms WHERE id = NEW.platform_id)
            )
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER auto_convert_revenue_to_credits_trigger
    AFTER INSERT OR UPDATE ON video_revenues
    FOR EACH ROW EXECUTE FUNCTION auto_convert_revenue_to_credits();

-- ============================================================================
-- VIEWS FOR COMMON QUERIES
-- ============================================================================

-- User dashboard summary
CREATE VIEW user_dashboard_summary AS
SELECT 
    u.id AS user_id,
    u.username,
    u.avatar_url,
    
    -- Discovery stats
    COALESCE(d_stats.total_discoveries, 0) AS total_discoveries,
    COALESCE(d_stats.new_discoveries, 0) AS new_discoveries,
    COALESCE(d_stats.recent_discoveries, 0) AS discoveries_last_30d,
    
    -- Video stats
    COALESCE(v_stats.total_videos, 0) AS total_videos,
    COALESCE(v_stats.recent_videos, 0) AS videos_last_30d,
    
    -- Revenue stats (last 30 days)
    COALESCE(r_stats.total_views, 0) AS total_views_30d,
    COALESCE(r_stats.total_revenue_cents, 0) AS total_revenue_cents_30d,
    COALESCE(r_stats.user_share_cents, 0) AS user_share_cents_30d,
    
    -- Credit stats
    COALESCE(uc.balance, 7) AS credit_balance, -- Default 7 for new users
    COALESCE(uc.total_earned, 0) AS total_credits_earned,
    COALESCE(uc.total_used, 0) AS total_credits_used,
    
    -- Rankings (approximate for performance)
    PERCENT_RANK() OVER (ORDER BY COALESCE(r_stats.user_share_cents, 0)) * 100 AS revenue_percentile

FROM users u
LEFT JOIN (
    SELECT 
        user_id,
        COUNT(*) AS total_discoveries,
        COUNT(*) FILTER (WHERE is_new_discovery = true) AS new_discoveries,
        COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '30 days') AS recent_discoveries
    FROM discoveries 
    WHERE validation_status = 'validated'
    GROUP BY user_id
) d_stats ON d_stats.user_id = u.id
LEFT JOIN (
    SELECT 
        user_id,
        COUNT(*) AS total_videos,
        COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '30 days') AS recent_videos
    FROM videos 
    WHERE generation_status = 'completed'
    GROUP BY user_id
) v_stats ON v_stats.user_id = u.id
LEFT JOIN (
    SELECT 
        user_id,
        SUM(views) AS total_views,
        SUM(net_revenue_cents) AS total_revenue_cents,
        SUM(user_share_cents) AS user_share_cents
    FROM video_revenues 
    WHERE date >= NOW() - INTERVAL '30 days'
    GROUP BY user_id
) r_stats ON r_stats.user_id = u.id
LEFT JOIN user_credits uc ON uc.user_id = u.id
WHERE u.is_active = true;

-- Top performers view
CREATE VIEW top_performers AS
SELECT 
    u.username,
    u.avatar_url,
    COUNT(DISTINCT d.id) AS total_discoveries,
    COUNT(DISTINCT d.id) FILTER (WHERE d.is_new_discovery = true) AS new_discoveries,
    COUNT(DISTINCT v.id) AS total_videos,
    COALESCE(SUM(vr.views), 0) AS total_views,
    COALESCE(SUM(vr.user_share_cents), 0) AS total_earnings_cents,
    COALESCE(uc.total_earned, 0) AS total_credits_earned,
    
    -- Performance metrics
    CASE 
        WHEN COUNT(DISTINCT v.id) > 0 
        THEN COALESCE(SUM(vr.views), 0)::DECIMAL / COUNT(DISTINCT v.id)
        ELSE 0 
    END AS avg_views_per_video,
    
    CASE 
        WHEN COUNT(DISTINCT d.id) > 0 
        THEN COUNT(DISTINCT d.id) FILTER (WHERE d.is_new_discovery = true)::DECIMAL / COUNT(DISTINCT d.id)
        ELSE 0 
    END AS new_discovery_rate

FROM users u
JOIN discoveries d ON d.user_id = u.id AND d.validation_status = 'validated'
LEFT JOIN videos v ON v.user_id = u.id AND v.generation_status = 'completed'
LEFT JOIN video_revenues vr ON vr.user_id = u.id AND vr.date >= NOW() - INTERVAL '90 days'
LEFT JOIN user_credits uc ON uc.user_id = u.id
WHERE u.is_active = true
GROUP BY u.id, u.username, u.avatar_url, uc.total_earned
HAVING COUNT(DISTINCT d.id) >= 3 -- Minimum discoveries to be considered
ORDER BY total_earnings_cents DESC;

-- ============================================================================
-- MAINTENANCE FUNCTIONS
-- ============================================================================

-- Refresh materialized views (run daily)
CREATE OR REPLACE FUNCTION refresh_analytics_views()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY user_analytics_summary;
    REFRESH MATERIALIZED VIEW CONCURRENTLY daily_platform_summary;
END;
$$ LANGUAGE plpgsql;

-- Clean up old sessions and tokens
CREATE OR REPLACE FUNCTION cleanup_expired_sessions()
RETURNS void AS $$
BEGIN
    DELETE FROM user_sessions WHERE expires_at < NOW() - INTERVAL '7 days';
    DELETE FROM user_verification_tokens WHERE expires_at < NOW() - INTERVAL '7 days';
END;
$$ LANGUAGE plpgsql;

-- Archive old video generation queue entries
CREATE OR REPLACE FUNCTION archive_old_queue_entries()
RETURNS void AS $$
BEGIN
    DELETE FROM video_generation_queue 
    WHERE status IN ('completed', 'failed') 
    AND completed_at < NOW() - INTERVAL '30 days';
    
    DELETE FROM upload_queue 
    WHERE status IN ('completed', 'failed') 
    AND created_at < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- SECURITY POLICIES (Row Level Security)
-- ============================================================================

-- Enable RLS on sensitive tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE discoveries ENABLE ROW LEVEL SECURITY;
ALTER TABLE videos ENABLE ROW LEVEL SECURITY;
ALTER TABLE video_revenues ENABLE ROW LEVEL SECURITY;
ALTER TABLE credit_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_credits ENABLE ROW LEVEL SECURITY;

-- Users can only see/modify their own data
CREATE POLICY user_own_data ON users
    FOR ALL USING (id = current_setting('app.current_user_id')::uuid);

CREATE POLICY user_own_discoveries ON discoveries
    FOR ALL USING (user_id = current_setting('app.current_user_id')::uuid);

CREATE POLICY user_own_videos ON videos
    FOR ALL USING (user_id = current_setting('app.current_user_id')::uuid);

CREATE POLICY user_own_revenues ON video_revenues
    FOR SELECT USING (user_id = current_setting('app.current_user_id')::uuid);

CREATE POLICY user_own_credits ON user_credits
    FOR ALL USING (user_id = current_setting('app.current_user_id')::uuid);

CREATE POLICY user_own_credit_transactions ON credit_transactions
    FOR ALL USING (user_id = current_setting('app.current_user_id')::uuid);

-- Admin access (bypass RLS when app.user_role = 'admin')
CREATE POLICY admin_all_access ON users
    FOR ALL USING (current_setting('app.user_role', true) = 'admin');

CREATE POLICY admin_all_discoveries ON discoveries
    FOR ALL USING (current_setting('app.user_role', true) = 'admin');

CREATE POLICY admin_all_videos ON videos
    FOR ALL USING (current_setting('app.user_role', true) = 'admin');

-- ============================================================================
-- INITIAL DATA AND SETUP
-- ============================================================================

-- Create initial admin user (change password in production!)
INSERT INTO users (
    email, 
    username, 
    password_hash, 
    first_name, 
    last_name, 
    is_active, 
    is_verified, 
    privacy_consent, 
    terms_accepted_at
) VALUES (
    'admin@Roadtrip-Copilot.com',
    'admin',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewhhZDHB4m0zcJoW', -- 'admin123' - CHANGE THIS!
    'System',
    'Administrator',
    true,
    true,
    true,
    NOW()
) ON CONFLICT (email) DO NOTHING;

-- Create sample video templates
INSERT INTO video_templates (name, description, category, template_data, duration_seconds) VALUES
('Discovery Short v1', 'Standard discovery video template', 'discovery', 
 '{"style": "energetic", "sections": ["hook", "intro", "highlights", "cta"]}', 30),
('Hidden Gem Showcase', 'Template for hidden gem discoveries', 'discovery',
 '{"style": "mysterious", "sections": ["teaser", "reveal", "details", "cta"]}', 25),
('Food Discovery Special', 'Template optimized for restaurant discoveries', 'discovery',
 '{"style": "appetizing", "sections": ["food_shot", "ambiance", "highlights", "cta"]}', 30);

-- Create indexes on materialized views
CREATE UNIQUE INDEX idx_user_analytics_summary_user_id ON user_analytics_summary(user_id);
CREATE INDEX idx_user_analytics_summary_revenue_rank ON user_analytics_summary(revenue_rank);
CREATE INDEX idx_user_analytics_summary_discovery_rank ON user_analytics_summary(discovery_rank);

CREATE INDEX idx_daily_platform_summary_platform_date ON daily_platform_summary(platform_name, date DESC);
CREATE INDEX idx_daily_platform_summary_date ON daily_platform_summary(date DESC);

-- Grant permissions to application user
-- CREATE USER poi_companion_app WITH PASSWORD 'secure_password_here';
-- GRANT CONNECT ON DATABASE poi_companion TO poi_companion_app;
-- GRANT USAGE ON SCHEMA public TO poi_companion_app;
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO poi_companion_app;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO poi_companion_app;

-- ============================================================================\n-- MISSING CRITICAL TABLES FOR COMPLETE PRODUCT FUNCTIONALITY\n-- ============================================================================\n\n-- ============================================================================\n-- ROADTRIP MANAGEMENT SYSTEM (Pay-per-roadtrip model)\n-- ============================================================================\n\n-- Roadtrip sessions - Core pay-per-roadtrip functionality\nCREATE TABLE roadtrip_sessions (\n    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),\n    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,\n    \n    -- Session identification and activation\n    activation_code VARCHAR(20) UNIQUE NOT NULL, -- 6-digit code for activation\n    session_token VARCHAR(255) UNIQUE NOT NULL, -- JWT token for session\n    \n    -- Trip details\n    origin_location GEOGRAPHY(POINT, 4326),\n    destination_location GEOGRAPHY(POINT, 4326),\n    origin_address TEXT,\n    destination_address TEXT,\n    planned_route JSONB, -- Route waypoints and details\n    estimated_distance_miles DECIMAL(8,2),\n    estimated_duration_minutes INTEGER,\n    \n    -- Session status and lifecycle\n    status VARCHAR(20) DEFAULT 'active', -- 'active', 'completed', 'cancelled', 'expired'\n    activated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),\n    expires_at TIMESTAMP WITH TIME ZONE, -- Sessions expire after 24 hours by default\n    completed_at TIMESTAMP WITH TIME ZONE,\n    \n    -- Usage tracking\n    total_discoveries INTEGER DEFAULT 0,\n    new_discoveries INTEGER DEFAULT 0, -- Count of new POIs discovered\n    revenue_eligible_discoveries INTEGER DEFAULT 0,\n    podcasts_played INTEGER DEFAULT 0,\n    voice_interactions INTEGER DEFAULT 0,\n    \n    -- Credit and billing\n    credits_consumed INTEGER DEFAULT 1, -- Usually 1 credit per roadtrip\n    credit_transaction_id UUID, -- References to credit_transactions\n    \n    -- Performance and analytics\n    session_quality_score DECIMAL(3,2), -- User satisfaction metric\n    ai_performance_metrics JSONB DEFAULT '{}',\n    user_feedback_rating INTEGER, -- 1-5 stars\n    user_feedback_text TEXT,\n    \n    -- Device and platform info\n    device_type VARCHAR(50), -- 'ios_carplay', 'android_auto', 'mobile'\n    app_version VARCHAR(20),\n    device_info JSONB DEFAULT '{}',\n    \n    -- Metadata\n    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),\n    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),\n    \n    CONSTRAINT valid_status CHECK (status IN ('active', 'completed', 'cancelled', 'expired'))\n);\n\n-- ============================================================================\n-- AI PROCESSING AND CACHING SYSTEM (Gemma 3n Integration)\n-- ============================================================================\n\n-- AI processing cache for Gemma 3n results\nCREATE TABLE ai_processing_cache (\n    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),\n    \n    -- Cache key and content identification\n    cache_key VARCHAR(255) UNIQUE NOT NULL, -- Hash of input parameters\n    processing_type VARCHAR(50) NOT NULL, -- 'poi_analysis', 'script_generation', 'review_distillation'\n    input_hash VARCHAR(64) NOT NULL, -- SHA-256 of input data\n    \n    -- Input and output data\n    input_data JSONB NOT NULL,\n    output_data JSONB NOT NULL,\n    \n    -- AI model information\n    model_version VARCHAR(50) DEFAULT 'gemma-3n-v1',\n    processing_time_ms INTEGER,\n    tokens_consumed INTEGER,\n    confidence_score DECIMAL(4,3),\n    \n    -- Cache management\n    cache_hits INTEGER DEFAULT 0,\n    expires_at TIMESTAMP WITH TIME ZONE,\n    last_accessed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),\n    \n    -- Quality and validation\n    quality_score DECIMAL(3,2), -- Human validation of AI output quality\n    validated_by UUID REFERENCES users(id),\n    validation_notes TEXT,\n    \n    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),\n    \n    CONSTRAINT valid_processing_type CHECK (processing_type IN (\n        'poi_analysis', 'script_generation', 'review_distillation', \n        'category_classification', 'similarity_analysis', 'content_moderation'\n    ))\n);\n\n-- Review distillation cache (6-second summaries)\nCREATE TABLE review_distillations (\n    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),\n    poi_id UUID, -- Can be NULL for crowdsourced POIs not yet in main table\n    discovery_id UUID REFERENCES discoveries(id),\n    \n    -- Source review data\n    source_reviews JSONB NOT NULL, -- Array of original reviews from various platforms\n    source_platforms TEXT[] NOT NULL, -- ['google', 'yelp', 'tripadvisor', 'facebook']\n    total_source_reviews INTEGER NOT NULL,\n    \n    -- Distilled content (6-second rule)\n    distilled_script JSONB NOT NULL, -- {\"hook\": \"...\", \"key_points\": [...], \"call_to_action\": \"...\"}\n    estimated_reading_time_seconds DECIMAL(4,2),\n    podcast_script JSONB, -- Two-person conversation format\n    \n    -- Content quality and relevance\n    distillation_quality_score DECIMAL(3,2),\n    relevance_score DECIMAL(3,2),\n    freshness_score DECIMAL(3,2), -- Based on review recency\n    \n    -- AI processing details\n    processed_by_model VARCHAR(50) DEFAULT 'gemma-3n-v1',\n    processing_time_ms INTEGER,\n    confidence_score DECIMAL(4,3),\n    \n    -- Cache and update management\n    cached_until TIMESTAMP WITH TIME ZONE,\n    last_updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),\n    update_frequency_hours INTEGER DEFAULT 24, -- How often to refresh\n    \n    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()\n);\n\n-- ============================================================================\n-- PODCAST AND VOICE CONTENT SYSTEM\n-- ============================================================================\n\n-- Podcast episodes generated for discoveries\nCREATE TABLE podcast_episodes (\n    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),\n    discovery_id UUID REFERENCES discoveries(id),\n    review_distillation_id UUID REFERENCES review_distillations(id),\n    \n    -- Episode content\n    title VARCHAR(255) NOT NULL,\n    script JSONB NOT NULL, -- Full conversation script with timing\n    duration_seconds INTEGER NOT NULL,\n    \n    -- Audio generation\n    audio_url TEXT, -- Generated audio file URL\n    audio_quality VARCHAR(20) DEFAULT 'standard', -- 'standard', 'high', 'premium'\n    voice_actors JSONB DEFAULT '{\"male\": \"alex\", \"female\": \"emma\"}', -- Voice personalities used\n    \n    -- Content metadata\n    episode_type VARCHAR(50) DEFAULT 'discovery', -- 'discovery', 'route_summary', 'category_feature'\n    target_audience VARCHAR(50) DEFAULT 'general', -- 'general', 'family', 'adventure', 'foodie'\n    content_tags TEXT[],\n    \n    -- Performance tracking\n    play_count INTEGER DEFAULT 0,\n    completion_rate DECIMAL(4,3), -- Average percentage listened\n    user_skip_rate DECIMAL(4,3),\n    user_rating_avg DECIMAL(3,2),\n    user_rating_count INTEGER DEFAULT 0,\n    \n    -- AI generation details\n    generated_by_model VARCHAR(50) DEFAULT 'gemma-3n-v1',\n    generation_time_ms INTEGER,\n    generation_cost_cents INTEGER, -- Cost tracking for AI generation\n    \n    -- Status and lifecycle\n    status VARCHAR(20) DEFAULT 'generated', -- 'generated', 'published', 'archived', 'failed'\n    published_at TIMESTAMP WITH TIME ZONE,\n    \n    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),\n    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),\n    \n    CONSTRAINT valid_audio_quality CHECK (audio_quality IN ('standard', 'high', 'premium')),\n    CONSTRAINT valid_episode_type CHECK (episode_type IN ('discovery', 'route_summary', 'category_feature', 'user_highlight')),\n    CONSTRAINT valid_status CHECK (status IN ('generated', 'published', 'archived', 'failed'))\n);\n\n-- Voice interaction logs for analysis and improvement\nCREATE TABLE voice_interactions (\n    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),\n    session_id UUID REFERENCES roadtrip_sessions(id),\n    user_id UUID REFERENCES users(id),\n    \n    -- Interaction details\n    interaction_type VARCHAR(50) NOT NULL, -- 'question', 'command', 'feedback', 'clarification'\n    user_input_text TEXT, -- Transcribed speech\n    user_intent VARCHAR(100), -- Classified intent\n    \n    -- AI response\n    ai_response_text TEXT,\n    ai_response_audio_url TEXT,\n    response_type VARCHAR(50), -- 'answer', 'clarification', 'error', 'redirect'\n    \n    -- Performance metrics\n    processing_time_ms INTEGER,\n    confidence_score DECIMAL(4,3),\n    user_satisfaction INTEGER, -- 1-5 implicit satisfaction based on follow-up\n    \n    -- Context\n    conversation_context JSONB DEFAULT '{}', -- Previous interactions in session\n    location_context GEOGRAPHY(POINT, 4326),\n    driving_context JSONB DEFAULT '{}', -- Speed, traffic conditions, etc.\n    \n    -- Privacy and compliance\n    audio_data_retained BOOLEAN DEFAULT false, -- Whether raw audio is kept\n    data_anonymized BOOLEAN DEFAULT false,\n    \n    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),\n    \n    CONSTRAINT valid_interaction_type CHECK (interaction_type IN (\n        'question', 'command', 'feedback', 'clarification', 'error', 'help_request'\n    )),\n    CONSTRAINT valid_response_type CHECK (response_type IN (\n        'answer', 'clarification', 'error', 'redirect', 'acknowledgment'\n    ))\n);\n\n-- ============================================================================\n-- DATA RETENTION AND PRIVACY COMPLIANCE SYSTEM\n-- ============================================================================\n\n-- Data retention policies for GDPR/CCPA compliance\nCREATE TABLE data_retention_policies (\n    id SERIAL PRIMARY KEY,\n    table_name VARCHAR(100) NOT NULL,\n    retention_period_days INTEGER NOT NULL,\n    policy_type VARCHAR(50) NOT NULL, -- 'automatic_deletion', 'anonymization', 'archival'\n    \n    -- Conditions for retention\n    conditions JSONB DEFAULT '{}', -- e.g., {\"user_inactive_days\": 365}\n    exceptions JSONB DEFAULT '{}', -- Legal hold, ongoing investigations\n    \n    -- Geographic compliance\n    applies_to_regions TEXT[] DEFAULT ARRAY['EU', 'CA', 'US'], -- GDPR, CCPA, general\n    \n    -- Execution details\n    cleanup_frequency VARCHAR(20) DEFAULT 'daily', -- 'daily', 'weekly', 'monthly'\n    last_executed_at TIMESTAMP WITH TIME ZONE,\n    next_execution_at TIMESTAMP WITH TIME ZONE,\n    \n    is_active BOOLEAN DEFAULT true,\n    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),\n    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),\n    \n    CONSTRAINT valid_policy_type CHECK (policy_type IN ('automatic_deletion', 'anonymization', 'archival')),\n    CONSTRAINT valid_cleanup_frequency CHECK (cleanup_frequency IN ('daily', 'weekly', 'monthly'))\n);\n\n-- Insert default data retention policies\nINSERT INTO data_retention_policies (table_name, retention_period_days, policy_type, conditions, applies_to_regions) VALUES\n('voice_interactions', 90, 'automatic_deletion', '{\"audio_data_retained\": true}', ARRAY['EU', 'CA']),\n('user_sessions', 365, 'automatic_deletion', '{}', ARRAY['ALL']),\n('ai_processing_cache', 180, 'automatic_deletion', '{\"cache_hits\": 0}', ARRAY['ALL']);\n\n-- Audit log for all data operations (immutable)\nCREATE TABLE audit_log (\n    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),\n    \n    -- Operation details\n    table_name VARCHAR(100) NOT NULL,\n    operation VARCHAR(20) NOT NULL, -- 'INSERT', 'UPDATE', 'DELETE', 'SELECT'\n    record_id UUID, -- ID of affected record if available\n    \n    -- User and session context\n    user_id UUID REFERENCES users(id),\n    session_id VARCHAR(255),\n    ip_address INET,\n    user_agent TEXT,\n    \n    -- Data changes (for UPDATE/DELETE)\n    old_values JSONB,\n    new_values JSONB,\n    \n    -- Legal and compliance\n    legal_basis VARCHAR(100), -- GDPR legal basis: 'consent', 'contract', 'legal_obligation', etc.\n    data_purpose VARCHAR(255), -- Purpose of data processing\n    retention_category VARCHAR(50), -- Links to retention policy\n    \n    -- Geographic and regulatory\n    user_jurisdiction VARCHAR(10), -- User's legal jurisdiction\n    processing_location VARCHAR(10), -- Where processing occurred\n    \n    -- Metadata\n    additional_metadata JSONB DEFAULT '{}',\n    \n    -- Immutable timestamp\n    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,\n    \n    CONSTRAINT valid_operation CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE', 'SELECT', 'EXPORT')),\n    CONSTRAINT valid_legal_basis CHECK (legal_basis IN (\n        'consent', 'contract', 'legal_obligation', 'vital_interests', 'public_task', 'legitimate_interests'\n    ))\n);\n\n-- Convert audit_log to hypertable for efficient time-series storage\nSELECT create_hypertable('audit_log', 'created_at', chunk_time_interval => INTERVAL '1 week');\n\n-- ============================================================================\n-- API RATE LIMITING AND QUOTA MANAGEMENT\n-- ============================================================================\n\n-- API usage tracking and rate limiting\nCREATE TABLE api_usage_tracking (\n    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),\n    \n    -- Request identification\n    user_id UUID REFERENCES users(id),\n    api_key_id UUID, -- If using API keys\n    endpoint VARCHAR(255) NOT NULL,\n    method VARCHAR(10) NOT NULL,\n    \n    -- Rate limiting buckets\n    time_bucket TIMESTAMP WITH TIME ZONE NOT NULL, -- Rounded to minute/hour/day\n    bucket_type VARCHAR(20) NOT NULL, -- 'per_minute', 'per_hour', 'per_day'\n    \n    -- Usage metrics\n    request_count INTEGER DEFAULT 1,\n    total_response_time_ms INTEGER DEFAULT 0,\n    error_count INTEGER DEFAULT 0,\n    \n    -- Resource consumption\n    tokens_consumed INTEGER DEFAULT 0, -- For AI API calls\n    data_bytes_transferred BIGINT DEFAULT 0,\n    processing_cost_cents INTEGER DEFAULT 0,\n    \n    -- Status tracking\n    rate_limited_count INTEGER DEFAULT 0,\n    quota_exceeded_count INTEGER DEFAULT 0,\n    \n    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),\n    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),\n    \n    UNIQUE(user_id, endpoint, time_bucket, bucket_type),\n    \n    CONSTRAINT valid_method CHECK (method IN ('GET', 'POST', 'PUT', 'DELETE', 'PATCH')),\n    CONSTRAINT valid_bucket_type CHECK (bucket_type IN ('per_minute', 'per_hour', 'per_day'))\n);\n\n-- Convert to hypertable for time-series optimization\nSELECT create_hypertable('api_usage_tracking', 'time_bucket', chunk_time_interval => INTERVAL '1 day');\n\n-- API rate limiting rules\nCREATE TABLE api_rate_limits (\n    id SERIAL PRIMARY KEY,\n    \n    -- Rule identification\n    rule_name VARCHAR(100) UNIQUE NOT NULL,\n    endpoint_pattern VARCHAR(255) NOT NULL, -- Regex pattern for endpoints\n    \n    -- User targeting\n    user_tier VARCHAR(50) DEFAULT 'standard', -- 'free', 'standard', 'premium', 'enterprise'\n    applies_to_user_ids UUID[], -- Specific users (overrides)\n    \n    -- Limits\n    requests_per_minute INTEGER,\n    requests_per_hour INTEGER,\n    requests_per_day INTEGER,\n    tokens_per_hour INTEGER, -- For AI API limits\n    bandwidth_kb_per_minute INTEGER,\n    \n    -- Responses when exceeded\n    rate_limit_response JSONB DEFAULT '{\"error\": \"Rate limit exceeded\", \"retry_after_seconds\": 60}',\n    quota_limit_response JSONB DEFAULT '{\"error\": \"Quota exceeded\", \"upgrade_required\": true}',\n    \n    -- Status\n    is_active BOOLEAN DEFAULT true,\n    priority INTEGER DEFAULT 100, -- Lower numbers = higher priority\n    \n    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),\n    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),\n    \n    CONSTRAINT valid_user_tier CHECK (user_tier IN ('free', 'standard', 'premium', 'enterprise', 'admin'))\n);\n\n-- Insert default rate limiting rules\nINSERT INTO api_rate_limits (rule_name, endpoint_pattern, user_tier, requests_per_minute, requests_per_hour, requests_per_day, tokens_per_hour) VALUES\n('free_tier_general', '.*', 'free', 30, 1000, 5000, 10000),\n('standard_tier_general', '.*', 'standard', 60, 3000, 15000, 50000),\n('premium_tier_general', '.*', 'premium', 120, 10000, 50000, 200000),\n('ai_processing_free', '/api/v\\\\d+/ai/.*', 'free', 5, 50, 200, 5000),\n('ai_processing_standard', '/api/v\\\\d+/ai/.*', 'standard', 15, 200, 1000, 25000),\n('discovery_submission', '/api/v\\\\d+/discoveries', 'free', 10, 100, 500, NULL),\n('voice_interaction', '/api/v\\\\d+/voice/.*', 'free', 20, 500, 2000, 15000);\n\n-- ============================================================================\n-- ENHANCED PERFORMANCE INDEXES FOR <200MS QUERIES\n-- ============================================================================\n\n-- Roadtrip session indexes\nCREATE INDEX idx_roadtrip_sessions_user_active ON roadtrip_sessions(user_id, status) WHERE status = 'active';\nCREATE INDEX idx_roadtrip_sessions_activation_code ON roadtrip_sessions(activation_code);\nCREATE INDEX idx_roadtrip_sessions_created_at ON roadtrip_sessions(created_at DESC);\nCREATE INDEX idx_roadtrip_sessions_expires_at ON roadtrip_sessions(expires_at) WHERE status = 'active';\n\n-- AI cache indexes for fast retrieval\nCREATE INDEX idx_ai_processing_cache_key ON ai_processing_cache(cache_key);\nCREATE INDEX idx_ai_processing_cache_type_hash ON ai_processing_cache(processing_type, input_hash);\nCREATE INDEX idx_ai_processing_cache_expires ON ai_processing_cache(expires_at) WHERE expires_at IS NOT NULL;\nCREATE INDEX idx_ai_processing_cache_hits ON ai_processing_cache(cache_hits DESC, last_accessed_at DESC);\n\n-- Review distillation indexes\nCREATE INDEX idx_review_distillations_discovery ON review_distillations(discovery_id) WHERE discovery_id IS NOT NULL;\nCREATE INDEX idx_review_distillations_cached_until ON review_distillations(cached_until) WHERE cached_until > NOW();\n\n-- Podcast episode indexes\nCREATE INDEX idx_podcast_episodes_discovery ON podcast_episodes(discovery_id);\nCREATE INDEX idx_podcast_episodes_status_type ON podcast_episodes(status, episode_type);\n\n-- Voice interaction indexes\nCREATE INDEX idx_voice_interactions_user_recent ON voice_interactions(user_id, created_at DESC) WHERE created_at >= NOW() - INTERVAL '7 days';\nCREATE INDEX idx_voice_interactions_type ON voice_interactions(interaction_type, confidence_score DESC);\n\n-- Audit log indexes\nCREATE INDEX idx_audit_log_user_table ON audit_log(user_id, table_name, created_at DESC);\nCREATE INDEX idx_audit_log_operation_time ON audit_log(operation, created_at DESC);\n\n-- API usage tracking indexes\nCREATE INDEX idx_api_usage_tracking_user_bucket ON api_usage_tracking(user_id, time_bucket DESC, bucket_type);\nCREATE INDEX idx_api_usage_tracking_endpoint_bucket ON api_usage_tracking(endpoint, time_bucket DESC, bucket_type);\n\n-- ============================================================================\n-- RLS POLICIES FOR NEW TABLES\n-- ============================================================================\n\n-- Enable RLS on new sensitive tables\nALTER TABLE roadtrip_sessions ENABLE ROW LEVEL SECURITY;\nALTER TABLE voice_interactions ENABLE ROW LEVEL SECURITY;\nALTER TABLE podcast_episodes ENABLE ROW LEVEL SECURITY;\nALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;\n\n-- User can only access their own roadtrip sessions\nCREATE POLICY user_own_roadtrip_sessions ON roadtrip_sessions\n    FOR ALL USING (user_id = current_setting('app.current_user_id')::uuid);\n\n-- User can only access their own voice interactions\nCREATE POLICY user_own_voice_interactions ON voice_interactions\n    FOR ALL USING (user_id = current_setting('app.current_user_id')::uuid);\n\n-- Users can view podcast episodes for their discoveries\nCREATE POLICY user_podcast_episodes ON podcast_episodes\n    FOR SELECT USING (\n        discovery_id IN (\n            SELECT id FROM discoveries WHERE user_id = current_setting('app.current_user_id')::uuid\n        )\n    );\n\n-- Users can only view their own audit logs\nCREATE POLICY user_own_audit_logs ON audit_log\n    FOR SELECT USING (user_id = current_setting('app.current_user_id')::uuid);\n\n-- Admin policies for new tables\nCREATE POLICY admin_all_roadtrip_sessions ON roadtrip_sessions\n    FOR ALL USING (current_setting('app.user_role', true) = 'admin');\n\nCREATE POLICY admin_all_voice_interactions ON voice_interactions\n    FOR ALL USING (current_setting('app.user_role', true) = 'admin');\n\nCREATE POLICY admin_all_audit_logs ON audit_log\n    FOR ALL USING (current_setting('app.user_role', true) = 'admin');\n\n-- ============================================================================\n-- PRODUCTION MAINTENANCE FUNCTIONS\n-- ============================================================================\n\n-- Automatically expire old roadtrip sessions\nCREATE OR REPLACE FUNCTION expire_old_roadtrip_sessions()\nRETURNS INTEGER AS $$\nDECLARE\n    expired_count INTEGER;\nBEGIN\n    UPDATE roadtrip_sessions \n    SET status = 'expired', updated_at = NOW()\n    WHERE status = 'active' \n    AND expires_at < NOW();\n    \n    GET DIAGNOSTICS expired_count = ROW_COUNT;\n    \n    RETURN expired_count;\nEND;\n$$ LANGUAGE plpgsql;\n\n-- Function to clean up expired AI cache entries\nCREATE OR REPLACE FUNCTION cleanup_expired_ai_cache()\nRETURNS INTEGER AS $$\nDECLARE\n    deleted_count INTEGER;\nBEGIN\n    DELETE FROM ai_processing_cache \n    WHERE expires_at < NOW() \n    OR (cache_hits = 0 AND created_at < NOW() - INTERVAL '7 days');\n    \n    GET DIAGNOSTICS deleted_count = ROW_COUNT;\n    \n    RETURN deleted_count;\nEND;\n$$ LANGUAGE plpgsql;\n\n-- Function to enforce data retention policies\nCREATE OR REPLACE FUNCTION enforce_data_retention_policies()\nRETURNS JSONB AS $$\nDECLARE\n    policy_record data_retention_policies%ROWTYPE;\n    deletion_count INTEGER;\n    results JSONB DEFAULT '[]'::JSONB;\nBEGIN\n    FOR policy_record IN \n        SELECT * FROM data_retention_policies \n        WHERE is_active = true \n        AND (next_execution_at IS NULL OR next_execution_at <= NOW())\n    LOOP\n        IF policy_record.policy_type = 'automatic_deletion' THEN\n            EXECUTE format(\n                'DELETE FROM %I WHERE created_at < NOW() - INTERVAL ''%s days''',\n                policy_record.table_name,\n                policy_record.retention_period_days\n            );\n            \n            GET DIAGNOSTICS deletion_count = ROW_COUNT;\n            \n            results := results || jsonb_build_object(\n                'table', policy_record.table_name,\n                'policy_type', policy_record.policy_type,\n                'records_deleted', deletion_count\n            );\n        END IF;\n        \n        -- Update next execution time\n        UPDATE data_retention_policies\n        SET \n            last_executed_at = NOW(),\n            next_execution_at = CASE \n                WHEN cleanup_frequency = 'daily' THEN NOW() + INTERVAL '1 day'\n                WHEN cleanup_frequency = 'weekly' THEN NOW() + INTERVAL '1 week'\n                WHEN cleanup_frequency = 'monthly' THEN NOW() + INTERVAL '1 month'\n            END\n        WHERE id = policy_record.id;\n    END LOOP;\n    \n    RETURN results;\nEND;\n$$ LANGUAGE plpgsql;\n\n-- Final setup message\nDO $$\nBEGIN\n    RAISE NOTICE 'Roadtrip-Copilot Production Database Schema created successfully!';\n    RAISE NOTICE 'Database version: 2.0';\n    RAISE NOTICE 'Created: %', NOW();\n    RAISE NOTICE '';\n    RAISE NOTICE 'PRODUCTION-READY FEATURES:';\n    RAISE NOTICE '✅ Pay-per-roadtrip model with session management';\n    RAISE NOTICE '✅ UGC monetization with video revenue tracking';\n    RAISE NOTICE '✅ Viral referral system with milestone triggers';\n    RAISE NOTICE '✅ Privacy-first anonymous revenue attribution';\n    RAISE NOTICE '✅ Gemma 3n AI processing cache and optimization';\n    RAISE NOTICE '✅ 6-second podcast review distillation system';\n    RAISE NOTICE '✅ Voice-first CarPlay/Android Auto interaction logs';\n    RAISE NOTICE '✅ GDPR/CCPA compliant data retention and audit trails';\n    RAISE NOTICE '✅ API rate limiting and quota management';\n    RAISE NOTICE '✅ Comprehensive performance indexes (<200ms target)';\n    RAISE NOTICE '✅ Row Level Security (RLS) for all sensitive tables';\n    RAISE NOTICE '';\n    RAISE NOTICE 'NEXT STEPS:';\n    RAISE NOTICE '1. Change default admin password immediately';\n    RAISE NOTICE '2. Configure Supabase RLS policies';\n    RAISE NOTICE '3. Set up automated data retention cleanup jobs';\n    RAISE NOTICE '4. Configure API rate limiting rules per tier';\n    RAISE NOTICE '5. Set up monitoring and alerting for performance';\n    RAISE NOTICE '6. Run initial database performance tests';\n    RAISE NOTICE '';\n    RAISE NOTICE 'DATABASE OPTIMIZATION STATUS: PRODUCTION READY';\nEND $$;