-- Additional Performance Indexes and Constraints Migration
-- This migration adds more specialized indexes and constraints for optimal performance

-- ===========================================
-- 1. SPECIALIZED PERFORMANCE INDEXES
-- ===========================================

-- Geographic indexes for location-based queries
CREATE INDEX IF NOT EXISTS idx_users_location_gist ON public.users USING gist (point(longitude, latitude)) WHERE location IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_teams_location_gist ON public.teams USING gist (point(longitude, latitude)) WHERE location IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_matches_location_gist ON public.matches USING gist (point(longitude, latitude)) WHERE location IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_cities_location_gist ON public.cities USING gist (point(longitude, latitude));

-- Note: These require PostGIS extension. If not available, use text-based location indexes instead
-- CREATE INDEX IF NOT EXISTS idx_users_location_trgm ON public.users USING gin (location gin_trgm_ops);
-- CREATE INDEX IF NOT EXISTS idx_teams_location_trgm ON public.teams USING gin (location gin_trgm_ops);
-- CREATE INDEX IF NOT EXISTS idx_matches_location_trgm ON public.matches USING gin (location gin_trgm_ops);

-- Advanced text search indexes with weights
CREATE INDEX IF NOT EXISTS idx_users_weighted_search ON public.users USING gin (
    setweight(to_tsvector('english', COALESCE(name, '')), 'A') ||
    setweight(to_tsvector('english', COALESCE(bio, '')), 'B') ||
    setweight(to_tsvector('english', COALESCE(location, '')), 'C')
);

CREATE INDEX IF NOT EXISTS idx_teams_weighted_search ON public.teams USING gin (
    setweight(to_tsvector('english', COALESCE(name, '')), 'A') ||
    setweight(to_tsvector('english', COALESCE(description, '')), 'B') ||
    setweight(to_tsvector('english', COALESCE(location, '')), 'C')
);

-- Time-based indexes for analytics and reporting
CREATE INDEX IF NOT EXISTS idx_users_created_month ON public.users (date_trunc('month', created_at));
CREATE INDEX IF NOT EXISTS idx_teams_created_month ON public.teams (date_trunc('month', created_at));
CREATE INDEX IF NOT EXISTS idx_matches_created_month ON public.matches (date_trunc('month', created_at));
CREATE INDEX IF NOT EXISTS idx_matches_date_month ON public.matches (date_trunc('month', match_date));

-- Partial indexes for specific query patterns
CREATE INDEX IF NOT EXISTS idx_matches_today ON public.matches (match_date)
WHERE match_date >= CURRENT_DATE AND match_date < CURRENT_DATE + INTERVAL '1 day' AND status = 'open';

CREATE INDEX IF NOT EXISTS idx_matches_this_week ON public.matches (match_date)
WHERE match_date >= date_trunc('week', CURRENT_DATE) AND match_date < date_trunc('week', CURRENT_DATE) + INTERVAL '1 week' AND status = 'open';

CREATE INDEX IF NOT EXISTS idx_teams_recent_active ON public.teams (updated_at DESC)
WHERE updated_at > NOW() - INTERVAL '30 days';

CREATE INDEX IF NOT EXISTS idx_users_active ON public.users (updated_at DESC)
WHERE updated_at > NOW() - INTERVAL '90 days';

-- Covering indexes for common SELECT queries
CREATE INDEX IF NOT EXISTS idx_matches_list_covering ON public.matches (match_date, status, location, title, max_players)
WHERE status IN ('open', 'closed');

CREATE INDEX IF NOT EXISTS idx_teams_list_covering ON public.teams (is_recruiting, created_at DESC, name, location, max_players)
WHERE is_recruiting = true;

-- ===========================================
-- 2. ADDITIONAL DATA INTEGRITY CONSTRAINTS
-- ===========================================

-- Business rule constraints
ALTER TABLE public.team_members ADD CONSTRAINT check_team_member_roles
    CHECK (role IN ('member', 'captain', 'coach'));

ALTER TABLE public.match_participants ADD CONSTRAINT check_participant_status
    CHECK (status IN ('confirmed', 'pending', 'declined'));

ALTER TABLE public.notifications ADD CONSTRAINT check_notification_type
    CHECK (type IN ('match_invite', 'team_invite', 'general', 'system'));

-- Prevent duplicate team ownership
ALTER TABLE public.teams ADD CONSTRAINT unique_team_owner_name
    EXCLUDE (owner_id WITH =, lower(trim(name)) WITH =)
    WHERE (owner_id IS NOT NULL);

-- Ensure match participants don't exceed max_players
ALTER TABLE public.match_participants ADD CONSTRAINT check_match_capacity
    CHECK (
        (SELECT COUNT(*) FROM public.match_participants mp WHERE mp.match_id = match_id AND mp.status = 'confirmed') <=
        (SELECT max_players FROM public.matches WHERE id = match_id)
    );

-- ===========================================
-- 3. ADDITIONAL UTILITY FUNCTIONS
-- ===========================================

-- Function to get nearby users (requires PostGIS or can be adapted for text-based search)
CREATE OR REPLACE FUNCTION get_nearby_users(
    user_lat DECIMAL,
    user_lng DECIMAL,
    radius_km INTEGER DEFAULT 50,
    limit_count INTEGER DEFAULT 50
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    location TEXT,
    distance_km DECIMAL
) AS $$
BEGIN
    -- This function requires PostGIS extension for accurate geographic calculations
    -- For now, return users with similar location text (basic implementation)
    RETURN QUERY
    SELECT
        u.id,
        u.name,
        u.location,
        0::DECIMAL as distance_km -- Placeholder for distance calculation
    FROM public.users u
    WHERE u.location IS NOT NULL
    AND u.id != auth.uid()
    ORDER BY u.updated_at DESC
    LIMIT limit_count;

    -- TODO: Implement proper geographic distance calculation with PostGIS:
    -- ST_Distance(ST_MakePoint(user_lng, user_lat)::geography, ST_MakePoint(longitude, latitude)::geography) / 1000 as distance_km
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get team statistics
CREATE OR REPLACE FUNCTION get_team_stats(team_id_param UUID)
RETURNS TABLE (
    total_members BIGINT,
    active_members BIGINT,
    matches_played BIGINT,
    matches_won BIGINT,
    matches_lost BIGINT,
    matches_drawn BIGINT,
    upcoming_matches BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(DISTINCT tm.user_id) as total_members,
        COUNT(DISTINCT CASE WHEN tm.joined_at > NOW() - INTERVAL '30 days' THEN tm.user_id END) as active_members,
        COUNT(DISTINCT CASE WHEN m.status = 'completed' THEN m.id END) as matches_played,
        0::BIGINT as matches_won, -- Would need match results table
        0::BIGINT as matches_lost, -- Would need match results table
        0::BIGINT as matches_drawn, -- Would need match results table
        COUNT(DISTINCT CASE WHEN m.status = 'open' AND m.match_date > NOW() THEN m.id END) as upcoming_matches
    FROM public.teams t
    LEFT JOIN public.team_members tm ON t.id = tm.team_id
    LEFT JOIN public.matches m ON (t.id = m.team1_id OR t.id = m.team2_id)
    WHERE t.id = team_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user activity summary
CREATE OR REPLACE FUNCTION get_user_activity_summary(user_id_param UUID)
RETURNS TABLE (
    teams_joined BIGINT,
    matches_participated BIGINT,
    matches_organized BIGINT,
    notifications_unread BIGINT,
    last_activity TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(DISTINCT tm.team_id) as teams_joined,
        COUNT(DISTINCT mp.match_id) as matches_participated,
        COUNT(DISTINCT m.id) as matches_organized,
        COUNT(DISTINCT n.id) FILTER (WHERE n.is_read = false) as notifications_unread,
        GREATEST(
            MAX(tm.joined_at),
            MAX(mp.joined_at),
            MAX(m.created_at),
            MAX(u.updated_at)
        ) as last_activity
    FROM public.users u
    LEFT JOIN public.team_members tm ON u.id = tm.user_id
    LEFT JOIN public.match_participants mp ON u.id = mp.user_id
    LEFT JOIN public.matches m ON u.id = (SELECT owner_id FROM public.teams WHERE id = m.team1_id OR id = m.team2_id)
    LEFT JOIN public.notifications n ON u.id = n.user_id
    WHERE u.id = user_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- 4. PERFORMANCE MONITORING FUNCTIONS
-- ===========================================

-- Function to analyze query performance (for development/debugging)
CREATE OR REPLACE FUNCTION analyze_table_performance()
RETURNS TABLE (
    table_name TEXT,
    total_rows BIGINT,
    index_count BIGINT,
    total_size TEXT,
    index_size TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        schemaname || '.' || tablename as table_name,
        n_tup_ins + n_tup_upd + n_tup_del as total_rows,
        pg_stat_user_indexes.idx_scan as index_count,
        pg_size_pretty(pg_total_relation_size(schemaname || '.' || tablename)) as total_size,
        pg_size_pretty(pg_indexes_size(schemaname || '.' || tablename)) as index_size
    FROM pg_stat_user_tables
    LEFT JOIN pg_stat_user_indexes ON pg_stat_user_tables.relid = pg_stat_user_indexes.relid
    WHERE schemaname = 'public'
    AND tablename IN ('users', 'teams', 'matches', 'team_members', 'match_participants', 'notifications', 'cities')
    ORDER BY total_rows DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- 5. CLEANUP AND MAINTENANCE FUNCTIONS
-- ===========================================

-- Function to clean up orphaned records
CREATE OR REPLACE FUNCTION cleanup_orphaned_records()
RETURNS TABLE (
    table_name TEXT,
    records_deleted BIGINT
) AS $$
DECLARE
    deleted_count BIGINT;
BEGIN
    -- Clean up match participants for deleted matches
    DELETE FROM public.match_participants
    WHERE match_id NOT IN (SELECT id FROM public.matches);
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN QUERY SELECT 'match_participants'::TEXT, deleted_count;

    -- Clean up team members for deleted teams
    DELETE FROM public.team_members
    WHERE team_id NOT IN (SELECT id FROM public.teams);
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN QUERY SELECT 'team_members'::TEXT, deleted_count;

    -- Clean up notifications for deleted users
    DELETE FROM public.notifications
    WHERE user_id NOT IN (SELECT id FROM public.users);
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN QUERY SELECT 'notifications'::TEXT, deleted_count;

    -- Clean up old audit logs (keep last 6 months)
    DELETE FROM public.audit_log
    WHERE created_at < NOW() - INTERVAL '6 months';
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN QUERY SELECT 'audit_log'::TEXT, deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- 6. MIGRATION COMPLETION MESSAGE
-- ===========================================

DO $$
BEGIN
    RAISE NOTICE 'Additional Performance Indexes and Constraints Migration completed successfully!';
    RAISE NOTICE '';
    RAISE NOTICE 'Key additions:';
    RAISE NOTICE '✓ Advanced geographic and text search indexes';
    RAISE NOTICE '✓ Time-based analytics indexes';
    RAISE NOTICE '✓ Partial indexes for specific query patterns';
    RAISE NOTICE '✓ Covering indexes for common SELECT queries';
    RAISE NOTICE '✓ Additional business rule constraints';
    RAISE NOTICE '✓ Utility functions for nearby users, team stats, and user activity';
    RAISE NOTICE '✓ Performance monitoring functions';
    RAISE NOTICE '✓ Database cleanup and maintenance functions';
    RAISE NOTICE '';
    RAISE NOTICE 'Optional next steps:';
    RAISE NOTICE '1. Install PostGIS extension for advanced geographic queries';
    RAISE NOTICE '2. Install pg_trgm extension for better text search';
    RAISE NOTICE '3. Set up automated cleanup jobs for orphaned records';
    RAISE NOTICE '4. Monitor index usage with pg_stat_user_indexes';
END $$;