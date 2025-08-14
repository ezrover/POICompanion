-- Roadtrip-Copilot Database Migration Manager
-- Provides safe, rollback-capable database migrations with validation

-- ============================================================================
-- MIGRATION MANAGEMENT FUNCTIONS
-- ============================================================================

-- Create migration manager schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS migration_manager;

-- Enhanced migration tracking table
CREATE TABLE IF NOT EXISTS migration_manager.migration_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version VARCHAR(50) UNIQUE NOT NULL,
    description TEXT NOT NULL,
    migration_sql TEXT NOT NULL,
    rollback_sql TEXT NOT NULL,
    checksum VARCHAR(64) NOT NULL,
    
    -- Execution tracking
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    applied_by VARCHAR(255) DEFAULT current_user,
    execution_time_ms INTEGER,
    
    -- Dependencies and ordering
    depends_on VARCHAR(50)[],
    migration_order INTEGER,
    
    -- Status and validation
    status VARCHAR(20) DEFAULT 'applied', -- 'applied', 'rolled_back', 'failed'
    validation_queries TEXT[],
    validation_results JSONB,
    
    -- Safety checks
    requires_backup BOOLEAN DEFAULT true,
    is_reversible BOOLEAN DEFAULT true,
    breaking_changes BOOLEAN DEFAULT false,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT valid_status CHECK (status IN ('applied', 'rolled_back', 'failed', 'pending'))
);

-- Migration execution function with safety checks
CREATE OR REPLACE FUNCTION migration_manager.apply_migration(
    p_version VARCHAR(50),
    p_description TEXT,
    p_migration_sql TEXT,
    p_rollback_sql TEXT,
    p_validation_queries TEXT[] DEFAULT NULL,
    p_requires_backup BOOLEAN DEFAULT true,
    p_breaking_changes BOOLEAN DEFAULT false
)
RETURNS JSONB AS $$
DECLARE
    v_start_time TIMESTAMP WITH TIME ZONE := NOW();
    v_execution_time INTEGER;
    v_checksum VARCHAR(64);
    v_validation_results JSONB := '[]'::JSONB;
    v_query TEXT;
    v_result RECORD;
BEGIN
    -- Check if migration already applied
    IF EXISTS (
        SELECT 1 FROM migration_manager.migration_history 
        WHERE version = p_version AND status = 'applied'
    ) THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Migration already applied',
            'version', p_version
        );
    END IF;
    
    -- Generate checksum for integrity verification
    v_checksum := encode(digest(p_migration_sql, 'sha256'), 'hex');
    
    -- Pre-migration backup warning
    IF p_requires_backup THEN
        RAISE NOTICE 'WARNING: This migration requires a database backup before proceeding';
        RAISE NOTICE 'Run: pg_dump -h host -U user -d database > backup_before_%.sql', p_version;
    END IF;
    
    -- Execute migration in transaction
    BEGIN
        -- Execute the migration SQL
        EXECUTE p_migration_sql;
        
        -- Run validation queries if provided
        IF p_validation_queries IS NOT NULL THEN
            FOR i IN 1..array_length(p_validation_queries, 1) LOOP
                v_query := p_validation_queries[i];
                EXECUTE v_query;
                
                v_validation_results := v_validation_results || jsonb_build_object(
                    'query', v_query,
                    'status', 'passed'
                );
            END LOOP;
        END IF;
        
        -- Calculate execution time
        v_execution_time := EXTRACT(EPOCH FROM (NOW() - v_start_time)) * 1000;
        
        -- Record successful migration
        INSERT INTO migration_manager.migration_history (
            version, description, migration_sql, rollback_sql, checksum,
            execution_time_ms, validation_queries, validation_results,
            requires_backup, is_reversible, breaking_changes,
            status
        ) VALUES (
            p_version, p_description, p_migration_sql, p_rollback_sql, v_checksum,
            v_execution_time, p_validation_queries, v_validation_results,
            p_requires_backup, true, p_breaking_changes,
            'applied'
        );
        
        RETURN jsonb_build_object(
            'success', true,
            'version', p_version,
            'execution_time_ms', v_execution_time,
            'checksum', v_checksum,
            'validation_results', v_validation_results
        );
        
    EXCEPTION WHEN OTHERS THEN
        -- Record failed migration
        INSERT INTO migration_manager.migration_history (
            version, description, migration_sql, rollback_sql, checksum,
            execution_time_ms, requires_backup, breaking_changes,
            status
        ) VALUES (
            p_version, p_description, p_migration_sql, p_rollback_sql, v_checksum,
            EXTRACT(EPOCH FROM (NOW() - v_start_time)) * 1000,
            p_requires_backup, p_breaking_changes,
            'failed'
        );
        
        RETURN jsonb_build_object(
            'success', false,
            'error', SQLERRM,
            'version', p_version,
            'execution_time_ms', EXTRACT(EPOCH FROM (NOW() - v_start_time)) * 1000
        );
    END;
END;
$$ LANGUAGE plpgsql;

-- Migration rollback function
CREATE OR REPLACE FUNCTION migration_manager.rollback_migration(
    p_version VARCHAR(50),
    p_force BOOLEAN DEFAULT false
)
RETURNS JSONB AS $$
DECLARE
    v_migration RECORD;
    v_start_time TIMESTAMP WITH TIME ZONE := NOW();
    v_execution_time INTEGER;
BEGIN
    -- Get migration record
    SELECT * INTO v_migration
    FROM migration_manager.migration_history
    WHERE version = p_version AND status = 'applied';
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Migration not found or not applied',
            'version', p_version
        );
    END IF;
    
    -- Check if migration is reversible
    IF NOT v_migration.is_reversible AND NOT p_force THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Migration is not reversible. Use p_force = true to override.',
            'version', p_version
        );
    END IF;
    
    -- Check for breaking changes
    IF v_migration.breaking_changes AND NOT p_force THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Migration has breaking changes. Use p_force = true to override.',
            'version', p_version
        );
    END IF;
    
    BEGIN
        -- Execute rollback SQL
        EXECUTE v_migration.rollback_sql;
        
        -- Calculate execution time
        v_execution_time := EXTRACT(EPOCH FROM (NOW() - v_start_time)) * 1000;
        
        -- Update migration record
        UPDATE migration_manager.migration_history
        SET 
            status = 'rolled_back',
            execution_time_ms = v_execution_time
        WHERE version = p_version;
        
        RETURN jsonb_build_object(
            'success', true,
            'version', p_version,
            'execution_time_ms', v_execution_time
        );
        
    EXCEPTION WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', SQLERRM,
            'version', p_version,
            'execution_time_ms', EXTRACT(EPOCH FROM (NOW() - v_start_time)) * 1000
        );
    END;
END;
$$ LANGUAGE plpgsql;

-- Get migration status function
CREATE OR REPLACE FUNCTION migration_manager.get_migration_status()
RETURNS TABLE (
    version VARCHAR(50),
    description TEXT,
    status VARCHAR(20),
    applied_at TIMESTAMP WITH TIME ZONE,
    execution_time_ms INTEGER,
    breaking_changes BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        mh.version,
        mh.description,
        mh.status,
        mh.applied_at,
        mh.execution_time_ms,
        mh.breaking_changes
    FROM migration_manager.migration_history mh
    ORDER BY mh.applied_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Verify database integrity function
CREATE OR REPLACE FUNCTION migration_manager.verify_database_integrity()
RETURNS JSONB AS $$
DECLARE
    v_results JSONB := '[]'::JSONB;
    v_check RECORD;
BEGIN
    -- Check for orphaned records
    FOR v_check IN
        SELECT 
            'orphaned_discoveries' as check_name,
            COUNT(*) as count,
            'Discoveries without valid users' as description
        FROM discoveries d
        LEFT JOIN users u ON d.user_id = u.id
        WHERE u.id IS NULL
        
        UNION ALL
        
        SELECT 
            'orphaned_videos' as check_name,
            COUNT(*) as count,
            'Videos without valid discoveries' as description
        FROM videos v
        LEFT JOIN discoveries d ON v.discovery_id = d.id
        WHERE d.id IS NULL
        
        UNION ALL
        
        SELECT 
            'expired_sessions' as check_name,
            COUNT(*) as count,
            'Active roadtrip sessions past expiration' as description
        FROM roadtrip_sessions rs
        WHERE rs.status = 'active' AND rs.expires_at < NOW()
    LOOP
        v_results := v_results || jsonb_build_object(
            'check_name', v_check.check_name,
            'count', v_check.count,
            'description', v_check.description,
            'status', CASE WHEN v_check.count > 0 THEN 'warning' ELSE 'ok' END
        );
    END LOOP;
    
    -- Check for missing indexes on foreign keys
    WITH missing_indexes AS (
        SELECT 
            schemaname,
            tablename,
            attname,
            n_distinct,
            correlation
        FROM pg_stats
        WHERE schemaname = 'public'
        AND attname LIKE '%_id'
        AND n_distinct > 100 -- Only consider columns with many distinct values
        AND NOT EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE schemaname = pg_stats.schemaname 
            AND tablename = pg_stats.tablename 
            AND indexdef LIKE '%' || pg_stats.attname || '%'
        )
    )
    SELECT COUNT(*) INTO v_check
    FROM missing_indexes;
    
    v_results := v_results || jsonb_build_object(
        'check_name', 'missing_foreign_key_indexes',
        'count', v_check,
        'description', 'Foreign key columns without indexes',
        'status', CASE WHEN v_check > 0 THEN 'warning' ELSE 'ok' END
    );
    
    RETURN jsonb_build_object(
        'timestamp', NOW(),
        'overall_status', CASE 
            WHEN EXISTS (
                SELECT 1 FROM jsonb_array_elements(v_results) elem 
                WHERE elem->>'status' = 'warning'
            ) THEN 'warnings_found'
            ELSE 'healthy'
        END,
        'checks', v_results
    );
END;
$$ LANGUAGE plpgsql;

-- Database health monitoring function
CREATE OR REPLACE FUNCTION migration_manager.get_database_health()
RETURNS JSONB AS $$
DECLARE
    v_stats JSONB;
    v_table_stats RECORD;
    v_results JSONB := '[]'::JSONB;
BEGIN
    -- Get overall database statistics
    SELECT jsonb_build_object(
        'database_size', pg_size_pretty(pg_database_size(current_database())),
        'total_connections', (SELECT count(*) FROM pg_stat_activity),
        'active_connections', (SELECT count(*) FROM pg_stat_activity WHERE state = 'active'),
        'total_tables', (SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public')
    ) INTO v_stats;
    
    -- Get table-specific statistics
    FOR v_table_stats IN
        SELECT 
            schemaname,
            tablename,
            n_tup_ins as inserts,
            n_tup_upd as updates,
            n_tup_del as deletes,
            n_live_tup as live_rows,
            n_dead_tup as dead_rows,
            last_vacuum,
            last_autovacuum,
            last_analyze,
            last_autoanalyze
        FROM pg_stat_user_tables
        WHERE schemaname = 'public'
        ORDER BY n_live_tup DESC
        LIMIT 10
    LOOP
        v_results := v_results || jsonb_build_object(
            'table', v_table_stats.tablename,
            'live_rows', v_table_stats.live_rows,
            'dead_rows', v_table_stats.dead_rows,
            'dead_row_ratio', CASE 
                WHEN v_table_stats.live_rows > 0 
                THEN ROUND(v_table_stats.dead_rows::DECIMAL / v_table_stats.live_rows, 4)
                ELSE 0 
            END,
            'last_vacuum', v_table_stats.last_vacuum,
            'last_analyze', v_table_stats.last_analyze
        );
    END LOOP;
    
    RETURN jsonb_build_object(
        'timestamp', NOW(),
        'database_stats', v_stats,
        'table_stats', v_results,
        'integrity_check', migration_manager.verify_database_integrity()
    );
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
GRANT USAGE ON SCHEMA migration_manager TO PUBLIC;
GRANT SELECT ON migration_manager.migration_history TO PUBLIC;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA migration_manager TO PUBLIC;

-- Final setup message
DO $$
BEGIN
    RAISE NOTICE 'Migration Manager installed successfully!';
    RAISE NOTICE '';
    RAISE NOTICE 'Usage:';
    RAISE NOTICE '1. Apply migration: SELECT migration_manager.apply_migration(''version'', ''description'', ''sql'', ''rollback_sql'');';
    RAISE NOTICE '2. Check status: SELECT * FROM migration_manager.get_migration_status();';
    RAISE NOTICE '3. Rollback: SELECT migration_manager.rollback_migration(''version'');';
    RAISE NOTICE '4. Health check: SELECT migration_manager.get_database_health();';
END $$;