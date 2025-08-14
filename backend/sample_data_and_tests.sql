-- Roadtrip-Copilot Sample Data and Performance Tests
-- Production database testing and validation queries
-- Version: 2.0

-- ============================================================================
-- SAMPLE DATA GENERATION FOR DEVELOPMENT AND TESTING
-- ============================================================================

-- Function to generate realistic test data
CREATE OR REPLACE FUNCTION generate_sample_data(
    p_num_users INTEGER DEFAULT 1000,
    p_num_discoveries INTEGER DEFAULT 5000,
    p_num_sessions INTEGER DEFAULT 2000
)
RETURNS JSONB AS $$
DECLARE
    v_start_time TIMESTAMP := NOW();
    v_user_ids UUID[];
    v_category_ids INTEGER[];
    v_result JSONB;
    i INTEGER;
BEGIN
    RAISE NOTICE 'Generating sample data: % users, % discoveries, % sessions', 
        p_num_users, p_num_discoveries, p_num_sessions;
    
    -- Generate sample users
    WITH user_inserts AS (
        INSERT INTO users (
            email, username, password_hash, first_name, last_name,
            country_code, privacy_settings, subscription_status,
            carplay_enabled, android_auto_enabled, is_active
        )
        SELECT 
            'user' || i || '@roadtrip-copilot.com',
            'user' || i,
            '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewhhZDHB4m0zcJoW',
            CASE (random() * 10)::int 
                WHEN 0 THEN 'Alex' WHEN 1 THEN 'Sarah' WHEN 2 THEN 'Mike'
                WHEN 3 THEN 'Emma' WHEN 4 THEN 'David' WHEN 5 THEN 'Lisa'
                ELSE 'User' || i 
            END,
            'LastName' || i,
            CASE (random() * 5)::int 
                WHEN 0 THEN 'US' WHEN 1 THEN 'CA' WHEN 2 THEN 'GB'
                WHEN 3 THEN 'AU' ELSE 'US' 
            END,
            '{"location_sharing": "anonymous_city_only", "analytics_opt_in": true}',
            CASE (random() * 3)::int 
                WHEN 0 THEN 'free_trial' WHEN 1 THEN 'active' ELSE 'free_trial'
            END,
            (random() > 0.3),
            (random() > 0.4),
            true
        FROM generate_series(1, p_num_users) i
        RETURNING id
    )
    SELECT array_agg(id) INTO v_user_ids FROM user_inserts;
    
    -- Get category IDs
    SELECT array_agg(id) INTO v_category_ids FROM poi_categories WHERE is_active = true;
    
    -- Generate sample roadtrip sessions
    INSERT INTO roadtrip_sessions (
        user_id, activation_code, session_token,
        origin_location, destination_location,
        origin_address, destination_address,
        estimated_distance_miles, estimated_duration_minutes,
        status, activated_at, expires_at,
        total_discoveries, new_discoveries, credits_consumed,
        device_type, app_version
    )
    SELECT 
        v_user_ids[(random() * (array_length(v_user_ids, 1) - 1))::int + 1],
        'TRIP' || LPAD(i::TEXT, 6, '0'),
        'jwt_token_' || md5(random()::text),
        -- Random locations across continental US
        ST_SetSRID(ST_Point(
            -125.0 + (random() * 50.0), -- Longitude: -125 to -75
            25.0 + (random() * 25.0)    -- Latitude: 25 to 50
        ), 4326)::geography,
        ST_SetSRID(ST_Point(
            -125.0 + (random() * 50.0),
            25.0 + (random() * 25.0)
        ), 4326)::geography,
        'Sample Origin ' || i,
        'Sample Destination ' || i,
        50 + (random() * 400)::int, -- 50-450 miles
        60 + (random() * 480)::int, -- 1-8 hours
        CASE (random() * 4)::int 
            WHEN 0 THEN 'active' WHEN 1 THEN 'completed' 
            WHEN 2 THEN 'cancelled' ELSE 'completed' 
        END,
        NOW() - (random() * INTERVAL '30 days'),
        NOW() + INTERVAL '24 hours',
        (random() * 10)::int, -- 0-10 discoveries
        (random() * 3)::int,  -- 0-3 new discoveries
        1 + (random() * 2)::int, -- 1-3 credits
        CASE (random() * 3)::int 
            WHEN 0 THEN 'ios_carplay' WHEN 1 THEN 'android_auto' ELSE 'mobile'
        END,
        '2.0.' || (random() * 10)::int
    FROM generate_series(1, p_num_sessions) i;
    
    -- Generate sample discoveries with realistic geographic distribution
    INSERT INTO discoveries (
        user_id, poi_name, poi_description, category_id,
        location, location_public,
        address_city, address_state, address_country,
        discovery_method, discovery_timestamp,
        validation_status, is_new_discovery,
        uniqueness_score, revenue_potential_score,
        quality_score, rating
    )
    SELECT 
        v_user_ids[(random() * (array_length(v_user_ids, 1) - 1))::int + 1],
        CASE (random() * 10)::int
            WHEN 0 THEN 'Joe''s Diner' WHEN 1 THEN 'Hidden Waterfall' 
            WHEN 2 THEN 'Vintage Gas Station' WHEN 3 THEN 'Scenic Overlook'
            WHEN 4 THEN 'Local Art Gallery' WHEN 5 THEN 'Roadside Market'
            ELSE 'Discovery POI ' || i
        END,
        'Amazing place discovered by user ' || i || '. Great for road trips and exploration.',
        v_category_ids[(random() * (array_length(v_category_ids, 1) - 1))::int + 1],
        -- Precise location
        ST_SetSRID(ST_Point(
            -125.0 + (random() * 50.0),
            25.0 + (random() * 25.0)
        ), 4326)::geography,
        -- Anonymized location (city center simulation)
        ST_SetSRID(ST_Point(
            -125.0 + (random() * 50.0) + (random() - 0.5) * 0.1, -- Add some noise
            25.0 + (random() * 25.0) + (random() - 0.5) * 0.1
        ), 4326)::geography,
        CASE (random() * 20)::int
            WHEN 0 THEN 'San Francisco' WHEN 1 THEN 'Los Angeles' WHEN 2 THEN 'Chicago'
            WHEN 3 THEN 'New York' WHEN 4 THEN 'Austin' WHEN 5 THEN 'Portland'
            WHEN 6 THEN 'Denver' WHEN 7 THEN 'Miami' WHEN 8 THEN 'Seattle'
            ELSE 'City ' || i
        END,
        CASE (random() * 10)::int
            WHEN 0 THEN 'CA' WHEN 1 THEN 'NY' WHEN 2 THEN 'TX'
            WHEN 3 THEN 'FL' WHEN 4 THEN 'WA' ELSE 'CA'
        END,
        'US',
        CASE (random() * 3)::int
            WHEN 0 THEN 'voice' WHEN 1 THEN 'manual' ELSE 'auto_detected'
        END,
        NOW() - (random() * INTERVAL '60 days'),
        CASE (random() * 5)::int
            WHEN 0 THEN 'pending' WHEN 1 THEN 'ai_validated' 
            WHEN 2 THEN 'community_validated' ELSE 'ai_validated'
        END,
        (random() > 0.7), -- 30% are new discoveries
        random()::decimal(4,3), -- Uniqueness score 0-1
        random()::decimal(4,3), -- Revenue potential 0-1
        5 + (random() * 5)::decimal(3,2), -- Quality score 5-10
        1 + (random() * 4)::decimal(3,2)  -- Rating 1-5
    FROM generate_series(1, p_num_discoveries) i;
    
    -- Generate sample AI processing cache entries
    INSERT INTO ai_processing_cache (
        cache_key, processing_type, input_hash,
        input_data, output_data,
        model_version, processing_time_ms, confidence_score,
        cache_hits, expires_at
    )
    SELECT 
        'cache_key_' || i,
        CASE (random() * 6)::int
            WHEN 0 THEN 'poi_analysis' WHEN 1 THEN 'script_generation'
            WHEN 2 THEN 'review_distillation' WHEN 3 THEN 'category_classification'
            ELSE 'similarity_analysis'
        END,
        md5('input_' || i),
        jsonb_build_object(
            'poi_name', 'Sample POI ' || i,
            'location', 'Sample Location',
            'reviews_count', (random() * 100)::int
        ),
        jsonb_build_object(
            'analysis_result', 'Sample analysis result',
            'confidence', random()::decimal(4,3),
            'recommendations', array['rec1', 'rec2', 'rec3']
        ),
        'gemma-3n-v1',
        (50 + random() * 500)::int, -- 50-550ms processing time
        random()::decimal(4,3),
        (random() * 20)::int, -- 0-20 cache hits
        NOW() + INTERVAL '1 hour' + (random() * INTERVAL '23 hours')
    FROM generate_series(1, 1000) i;
    
    -- Generate sample voice interactions
    INSERT INTO voice_interactions (
        user_id, interaction_type, user_input_text,
        ai_response_text, processing_time_ms, confidence_score,
        location_context, audio_data_retained
    )
    SELECT 
        v_user_ids[(random() * (array_length(v_user_ids, 1) - 1))::int + 1],
        CASE (random() * 6)::int
            WHEN 0 THEN 'question' WHEN 1 THEN 'command'
            WHEN 2 THEN 'feedback' ELSE 'question'
        END,
        CASE (random() * 10)::int
            WHEN 0 THEN 'What''s nearby?' WHEN 1 THEN 'Tell me more about this place'
            WHEN 2 THEN 'Skip this one' WHEN 3 THEN 'Bookmark this'
            ELSE 'Sample voice input ' || i
        END,
        CASE (random() * 5)::int
            WHEN 0 THEN 'I found 3 great restaurants nearby!' 
            WHEN 1 THEN 'This scenic overlook has amazing sunset views.'
            ELSE 'Sample AI response ' || i
        END,
        (100 + random() * 300)::int, -- 100-400ms response time
        random()::decimal(4,3),
        ST_SetSRID(ST_Point(
            -125.0 + (random() * 50.0),
            25.0 + (random() * 25.0)
        ), 4326)::geography,
        (random() < 0.1) -- Only 10% retain audio data
    FROM generate_series(1, 2000) i;
    
    -- Calculate generation time and return results
    v_result := jsonb_build_object(
        'success', true,
        'generation_time_seconds', EXTRACT(EPOCH FROM (NOW() - v_start_time)),
        'records_created', jsonb_build_object(
            'users', p_num_users,
            'roadtrip_sessions', p_num_sessions,
            'discoveries', p_num_discoveries,
            'ai_cache_entries', 1000,
            'voice_interactions', 2000
        ),
        'timestamp', NOW()
    );
    
    RAISE NOTICE 'Sample data generation completed in % seconds', 
        EXTRACT(EPOCH FROM (NOW() - v_start_time));
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- PERFORMANCE TESTING QUERIES
-- ============================================================================

-- Test 1: POI Discovery Query (Target: <50ms)
-- This simulates the core discovery functionality
CREATE OR REPLACE FUNCTION test_poi_discovery_performance(
    p_test_location GEOGRAPHY DEFAULT ST_SetSRID(ST_Point(-122.4194, 37.7749), 4326)::geography,
    p_radius_meters INTEGER DEFAULT 5000,
    p_limit INTEGER DEFAULT 20
)
RETURNS JSONB AS $$
DECLARE
    v_start_time TIMESTAMP := clock_timestamp();
    v_end_time TIMESTAMP;
    v_results RECORD;
    v_execution_time_ms INTEGER;
BEGIN
    -- Core POI discovery query with all optimizations
    SELECT 
        COUNT(*) as poi_count,
        AVG(ST_Distance(location, p_test_location)) as avg_distance,
        MIN(ST_Distance(location, p_test_location)) as min_distance,
        MAX(ST_Distance(location, p_test_location)) as max_distance
    INTO v_results
    FROM discoveries d
    JOIN poi_categories pc ON d.category_id = pc.id
    WHERE 
        ST_DWithin(d.location_public, p_test_location, p_radius_meters)
        AND d.validation_status IN ('ai_validated', 'community_validated')
        AND pc.is_active = true
    ORDER BY 
        -- Primary sort: revenue potential for monetization
        d.revenue_potential_score DESC,
        -- Secondary sort: proximity
        ST_Distance(d.location_public, p_test_location)
    LIMIT p_limit;
    
    v_end_time := clock_timestamp();
    v_execution_time_ms := EXTRACT(EPOCH FROM (v_end_time - v_start_time)) * 1000;
    
    RETURN jsonb_build_object(
        'test_name', 'POI Discovery Performance',
        'execution_time_ms', v_execution_time_ms,
        'target_time_ms', 50,
        'performance_rating', CASE 
            WHEN v_execution_time_ms <= 50 THEN 'excellent'
            WHEN v_execution_time_ms <= 100 THEN 'good'
            WHEN v_execution_time_ms <= 200 THEN 'acceptable'
            ELSE 'needs_optimization'
        END,
        'results', jsonb_build_object(
            'poi_count', v_results.poi_count,
            'avg_distance_meters', ROUND(v_results.avg_distance, 2),
            'min_distance_meters', ROUND(v_results.min_distance, 2),
            'max_distance_meters', ROUND(v_results.max_distance, 2)
        )
    );
END;
$$ LANGUAGE plpgsql;

-- Test 2: User Dashboard Load (Target: <100ms)
-- This tests the user dashboard aggregation performance
CREATE OR REPLACE FUNCTION test_user_dashboard_performance(
    p_user_id UUID DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_start_time TIMESTAMP := clock_timestamp();
    v_end_time TIMESTAMP;
    v_test_user_id UUID;
    v_execution_time_ms INTEGER;
    v_dashboard_data RECORD;
BEGIN
    -- Get a random user ID if not provided
    IF p_user_id IS NULL THEN
        SELECT id INTO v_test_user_id FROM users ORDER BY random() LIMIT 1;
    ELSE
        v_test_user_id := p_user_id;
    END IF;
    
    -- Complex dashboard query with multiple joins and aggregations
    SELECT 
        u.username,
        u.created_at as user_since,
        COALESCE(uc.balance, 7) as credit_balance,
        COALESCE(discovery_stats.total_discoveries, 0) as total_discoveries,
        COALESCE(discovery_stats.new_discoveries, 0) as new_discoveries,
        COALESCE(discovery_stats.revenue_eligible, 0) as revenue_eligible_discoveries,
        COALESCE(session_stats.total_sessions, 0) as total_roadtrips,
        COALESCE(session_stats.completed_sessions, 0) as completed_roadtrips,
        COALESCE(revenue_stats.total_revenue_cents, 0) as total_revenue_cents,
        COALESCE(revenue_stats.total_user_share_cents, 0) as total_earnings_cents
    INTO v_dashboard_data
    FROM users u
    LEFT JOIN user_credits uc ON uc.user_id = u.id
    LEFT JOIN (
        SELECT 
            user_id,
            COUNT(*) as total_discoveries,
            COUNT(*) FILTER (WHERE is_new_discovery = true) as new_discoveries,
            COUNT(*) FILTER (WHERE eligible_for_revenue = true) as revenue_eligible
        FROM discoveries 
        WHERE user_id = v_test_user_id
        GROUP BY user_id
    ) discovery_stats ON discovery_stats.user_id = u.id
    LEFT JOIN (
        SELECT 
            user_id,
            COUNT(*) as total_sessions,
            COUNT(*) FILTER (WHERE status = 'completed') as completed_sessions
        FROM roadtrip_sessions 
        WHERE user_id = v_test_user_id
        GROUP BY user_id
    ) session_stats ON session_stats.user_id = u.id
    LEFT JOIN (
        SELECT 
            user_id,
            SUM(net_revenue_cents) as total_revenue_cents,
            SUM(user_share_cents) as total_user_share_cents
        FROM video_revenues 
        WHERE user_id = v_test_user_id
          AND date >= NOW() - INTERVAL '1 year'
        GROUP BY user_id
    ) revenue_stats ON revenue_stats.user_id = u.id
    WHERE u.id = v_test_user_id;
    
    v_end_time := clock_timestamp();
    v_execution_time_ms := EXTRACT(EPOCH FROM (v_end_time - v_start_time)) * 1000;
    
    RETURN jsonb_build_object(
        'test_name', 'User Dashboard Performance',
        'execution_time_ms', v_execution_time_ms,
        'target_time_ms', 100,
        'performance_rating', CASE 
            WHEN v_execution_time_ms <= 100 THEN 'excellent'
            WHEN v_execution_time_ms <= 200 THEN 'good'
            WHEN v_execution_time_ms <= 500 THEN 'acceptable'
            ELSE 'needs_optimization'
        END,
        'user_id', v_test_user_id,
        'dashboard_data', row_to_json(v_dashboard_data)
    );
END;
$$ LANGUAGE plpgsql;

-- Test 3: AI Cache Hit Performance (Target: <10ms)
-- This tests the AI processing cache lookup speed
CREATE OR REPLACE FUNCTION test_ai_cache_performance()
RETURNS JSONB AS $$
DECLARE
    v_start_time TIMESTAMP := clock_timestamp();
    v_end_time TIMESTAMP;
    v_execution_time_ms INTEGER;
    v_cache_stats RECORD;
BEGIN
    -- Test cache lookup performance
    SELECT 
        COUNT(*) as total_entries,
        COUNT(*) FILTER (WHERE cache_hits > 0) as entries_with_hits,
        AVG(cache_hits) as avg_cache_hits,
        COUNT(*) FILTER (WHERE expires_at > NOW()) as active_entries
    INTO v_cache_stats
    FROM ai_processing_cache
    WHERE processing_type = 'poi_analysis'
      AND expires_at > NOW()
    ORDER BY cache_hits DESC, last_accessed_at DESC
    LIMIT 100;
    
    v_end_time := clock_timestamp();
    v_execution_time_ms := EXTRACT(EPOCH FROM (v_end_time - v_start_time)) * 1000;
    
    RETURN jsonb_build_object(
        'test_name', 'AI Cache Performance',
        'execution_time_ms', v_execution_time_ms,
        'target_time_ms', 10,
        'performance_rating', CASE 
            WHEN v_execution_time_ms <= 10 THEN 'excellent'
            WHEN v_execution_time_ms <= 25 THEN 'good'
            WHEN v_execution_time_ms <= 50 THEN 'acceptable'
            ELSE 'needs_optimization'
        END,
        'cache_stats', row_to_json(v_cache_stats)
    );
END;
$$ LANGUAGE plpgsql;

-- Test 4: Voice Interaction Response (Target: <200ms)
-- This tests the voice interaction logging and retrieval
CREATE OR REPLACE FUNCTION test_voice_interaction_performance()
RETURNS JSONB AS $$
DECLARE
    v_start_time TIMESTAMP := clock_timestamp();
    v_end_time TIMESTAMP;
    v_execution_time_ms INTEGER;
    v_interaction_stats RECORD;
BEGIN
    -- Test voice interaction query performance
    SELECT 
        COUNT(*) as total_interactions,
        AVG(processing_time_ms) as avg_processing_time,
        AVG(confidence_score) as avg_confidence,
        COUNT(*) FILTER (WHERE confidence_score > 0.8) as high_confidence_count
    INTO v_interaction_stats
    FROM voice_interactions
    WHERE created_at >= NOW() - INTERVAL '7 days'
      AND interaction_type IN ('question', 'command')
    ORDER BY created_at DESC
    LIMIT 1000;
    
    v_end_time := clock_timestamp();
    v_execution_time_ms := EXTRACT(EPOCH FROM (v_end_time - v_start_time)) * 1000;
    
    RETURN jsonb_build_object(
        'test_name', 'Voice Interaction Performance',
        'execution_time_ms', v_execution_time_ms,
        'target_time_ms', 200,
        'performance_rating', CASE 
            WHEN v_execution_time_ms <= 200 THEN 'excellent'
            WHEN v_execution_time_ms <= 400 THEN 'good'
            WHEN v_execution_time_ms <= 800 THEN 'acceptable'
            ELSE 'needs_optimization'
        END,
        'interaction_stats', row_to_json(v_interaction_stats)
    );
END;
$$ LANGUAGE plpgsql;

-- Comprehensive Performance Test Suite
CREATE OR REPLACE FUNCTION run_comprehensive_performance_tests()
RETURNS JSONB AS $$
DECLARE
    v_test_results JSONB := '[]'::JSONB;
    v_overall_start TIMESTAMP := clock_timestamp();
    v_test_result JSONB;
BEGIN
    RAISE NOTICE 'Running comprehensive database performance tests...';
    
    -- Test 1: POI Discovery
    SELECT test_poi_discovery_performance() INTO v_test_result;
    v_test_results := v_test_results || v_test_result;
    RAISE NOTICE 'POI Discovery Test: %ms (target: 50ms)', v_test_result->>'execution_time_ms';
    
    -- Test 2: User Dashboard
    SELECT test_user_dashboard_performance() INTO v_test_result;
    v_test_results := v_test_results || v_test_result;
    RAISE NOTICE 'User Dashboard Test: %ms (target: 100ms)', v_test_result->>'execution_time_ms';
    
    -- Test 3: AI Cache
    SELECT test_ai_cache_performance() INTO v_test_result;
    v_test_results := v_test_results || v_test_result;
    RAISE NOTICE 'AI Cache Test: %ms (target: 10ms)', v_test_result->>'execution_time_ms';
    
    -- Test 4: Voice Interaction
    SELECT test_voice_interaction_performance() INTO v_test_result;
    v_test_results := v_test_results || v_test_result;
    RAISE NOTICE 'Voice Interaction Test: %ms (target: 200ms)', v_test_result->>'execution_time_ms';
    
    RETURN jsonb_build_object(
        'test_suite', 'Comprehensive Performance Tests',
        'total_execution_time_ms', EXTRACT(EPOCH FROM (clock_timestamp() - v_overall_start)) * 1000,
        'tests_run', jsonb_array_length(v_test_results),
        'timestamp', NOW(),
        'results', v_test_results,
        'overall_performance', CASE 
            WHEN NOT EXISTS (
                SELECT 1 FROM jsonb_array_elements(v_test_results) elem 
                WHERE elem->>'performance_rating' IN ('needs_optimization')
            ) THEN 'excellent'
            WHEN EXISTS (
                SELECT 1 FROM jsonb_array_elements(v_test_results) elem 
                WHERE elem->>'performance_rating' IN ('good', 'excellent')
            ) THEN 'good'
            ELSE 'needs_optimization'
        END
    );
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- DATABASE VALIDATION AND INTEGRITY TESTS
-- ============================================================================

-- Validate referential integrity
CREATE OR REPLACE FUNCTION validate_referential_integrity()
RETURNS JSONB AS $$
DECLARE
    v_issues JSONB := '[]'::JSONB;
    v_issue_count INTEGER := 0;
BEGIN
    -- Check for orphaned discoveries
    IF EXISTS (
        SELECT 1 FROM discoveries d 
        LEFT JOIN users u ON d.user_id = u.id 
        WHERE u.id IS NULL
    ) THEN
        v_issues := v_issues || jsonb_build_object(
            'issue', 'orphaned_discoveries',
            'description', 'Discoveries exist without valid users'
        );
        v_issue_count := v_issue_count + 1;
    END IF;
    
    -- Check for invalid roadtrip sessions
    IF EXISTS (
        SELECT 1 FROM roadtrip_sessions rs
        WHERE rs.status = 'active' AND rs.expires_at < NOW()
    ) THEN
        v_issues := v_issues || jsonb_build_object(
            'issue', 'expired_active_sessions',
            'description', 'Active roadtrip sessions past expiration time'
        );
        v_issue_count := v_issue_count + 1;
    END IF;
    
    -- Check for invalid credit balances
    IF EXISTS (
        SELECT 1 FROM user_credits 
        WHERE balance < 0 OR total_earned < 0 OR total_used < 0
    ) THEN
        v_issues := v_issues || jsonb_build_object(
            'issue', 'invalid_credit_balances',
            'description', 'Negative credit balances detected'
        );
        v_issue_count := v_issue_count + 1;
    END IF;
    
    RETURN jsonb_build_object(
        'validation', 'referential_integrity',
        'status', CASE WHEN v_issue_count = 0 THEN 'passed' ELSE 'failed' END,
        'issues_found', v_issue_count,
        'issues', v_issues,
        'timestamp', NOW()
    );
END;
$$ LANGUAGE plpgsql;

-- Quick database health check
CREATE OR REPLACE FUNCTION quick_health_check()
RETURNS JSONB AS $$
DECLARE
    v_stats JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_users', (SELECT COUNT(*) FROM users WHERE is_active = true),
        'total_discoveries', (SELECT COUNT(*) FROM discoveries),
        'active_roadtrip_sessions', (SELECT COUNT(*) FROM roadtrip_sessions WHERE status = 'active'),
        'ai_cache_entries', (SELECT COUNT(*) FROM ai_processing_cache WHERE expires_at > NOW()),
        'recent_voice_interactions', (SELECT COUNT(*) FROM voice_interactions WHERE created_at >= NOW() - INTERVAL '24 hours'),
        'database_size', pg_size_pretty(pg_database_size(current_database())),
        'active_connections', (SELECT count(*) FROM pg_stat_activity WHERE state = 'active')
    ) INTO v_stats;
    
    RETURN jsonb_build_object(
        'health_check', 'quick_stats',
        'status', 'healthy',
        'timestamp', NOW(),
        'stats', v_stats
    );
END;
$$ LANGUAGE plpgsql;

-- Usage examples and instructions
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=== Roadtrip-Copilot Database Testing Suite ===';
    RAISE NOTICE '';
    RAISE NOTICE 'Sample Data Generation:';
    RAISE NOTICE '  SELECT generate_sample_data(1000, 5000, 2000);  -- Generate test data';
    RAISE NOTICE '';
    RAISE NOTICE 'Performance Testing:';
    RAISE NOTICE '  SELECT run_comprehensive_performance_tests();   -- Run all performance tests';
    RAISE NOTICE '  SELECT test_poi_discovery_performance();        -- Test POI discovery';
    RAISE NOTICE '  SELECT test_user_dashboard_performance();       -- Test dashboard load';
    RAISE NOTICE '';
    RAISE NOTICE 'Health and Validation:';
    RAISE NOTICE '  SELECT quick_health_check();                    -- Quick database stats';
    RAISE NOTICE '  SELECT validate_referential_integrity();       -- Check data integrity';
    RAISE NOTICE '  SELECT migration_manager.get_database_health(); -- Full health report';
    RAISE NOTICE '';
    RAISE NOTICE 'Target Performance Metrics:';
    RAISE NOTICE '  • POI Discovery: <50ms';
    RAISE NOTICE '  • User Dashboard: <100ms';
    RAISE NOTICE '  • AI Cache Lookup: <10ms';
    RAISE NOTICE '  • Voice Interaction: <200ms';
    RAISE NOTICE '';
END $$;