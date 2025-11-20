-- Enhanced Security Policies and Performance Optimization Migration
-- This migration improves RLS policies, adds performance indexes, and implements data integrity constraints

-- ===========================================
-- 1. DROP EXISTING POLICIES (to be recreated with improvements)
-- ===========================================

-- Drop existing policies to recreate them with better security
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Users can create own profile" ON public.users;

DROP POLICY IF EXISTS "Anyone can view teams" ON public.teams;
DROP POLICY IF EXISTS "Authenticated users can create teams" ON public.teams;
DROP POLICY IF EXISTS "Team owners can update their teams" ON public.teams;

DROP POLICY IF EXISTS "Team members can view team membership" ON public.team_members;
DROP POLICY IF EXISTS "Team owners can manage members" ON public.team_members;
DROP POLICY IF EXISTS "Users can join teams" ON public.team_members;

DROP POLICY IF EXISTS "Anyone can view matches" ON public.matches;
DROP POLICY IF EXISTS "Authenticated users can create matches" ON public.matches;
DROP POLICY IF EXISTS "Team owners can update matches" ON public.matches;

DROP POLICY IF EXISTS "Users can view match participants" ON public.match_participants;
DROP POLICY IF EXISTS "Users can join matches" ON public.match_participants;
DROP POLICY IF EXISTS "Users can update their participation" ON public.match_participants;

DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;

DROP POLICY IF EXISTS "Anyone can view cities" ON public.cities;

-- ===========================================
-- 2. ENHANCED RLS POLICIES
-- ===========================================

-- Users policies - Enhanced with admin access and profile visibility
CREATE POLICY "Users can view own profile and admins can view all" ON public.users
    FOR SELECT USING (
        auth.uid() = id OR
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "Users can update own profile, admins can update all" ON public.users
    FOR UPDATE USING (
        auth.uid() = id OR
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "Users can create own profile" ON public.users
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Admins can delete users" ON public.users
    FOR DELETE USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- Teams policies - Restricted access with proper team member visibility
CREATE POLICY "Team members and public recruiting teams can be viewed" ON public.teams
    FOR SELECT USING (
        is_recruiting = true OR
        owner_id = auth.uid() OR
        EXISTS (SELECT 1 FROM public.team_members WHERE team_id = id AND user_id = auth.uid())
    );

CREATE POLICY "Authenticated users can create teams" ON public.teams
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = owner_id);

CREATE POLICY "Team owners and captains can update teams" ON public.teams
    FOR UPDATE USING (
        owner_id = auth.uid() OR
        EXISTS (SELECT 1 FROM public.team_members WHERE team_id = id AND user_id = auth.uid() AND role IN ('captain', 'coach'))
    );

CREATE POLICY "Team owners can delete teams" ON public.teams
    FOR DELETE USING (owner_id = auth.uid());

-- Team members policies - Enhanced with role-based access
CREATE POLICY "Team members and owners can view membership" ON public.team_members
    FOR SELECT USING (
        user_id = auth.uid() OR
        EXISTS (SELECT 1 FROM public.teams WHERE id = team_id AND owner_id = auth.uid()) OR
        EXISTS (SELECT 1 FROM public.team_members WHERE team_id = team_id AND user_id = auth.uid())
    );

CREATE POLICY "Team owners and captains can manage members" ON public.team_members
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.teams WHERE id = team_id AND owner_id = auth.uid()) OR
        EXISTS (SELECT 1 FROM public.team_members WHERE team_id = team_id AND user_id = auth.uid() AND role IN ('captain', 'coach'))
    );

CREATE POLICY "Users can request to join teams" ON public.team_members
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Matches policies - Enhanced with participant visibility
CREATE POLICY "Matches can be viewed by participants and public" ON public.matches
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.match_participants WHERE match_id = id AND user_id = auth.uid()) OR
        EXISTS (SELECT 1 FROM public.teams WHERE id = team1_id AND owner_id = auth.uid()) OR
        EXISTS (SELECT 1 FROM public.teams WHERE id = team2_id AND owner_id = auth.uid()) OR
        status = 'open'
    );

CREATE POLICY "Team owners and captains can create matches" ON public.matches
    FOR INSERT WITH CHECK (
        auth.uid() IS NOT NULL AND (
            EXISTS (SELECT 1 FROM public.teams WHERE id = team1_id AND owner_id = auth.uid()) OR
            EXISTS (SELECT 1 FROM public.team_members WHERE team_id = team1_id AND user_id = auth.uid() AND role IN ('captain', 'coach')) OR
            EXISTS (SELECT 1 FROM public.teams WHERE id = team2_id AND owner_id = auth.uid()) OR
            EXISTS (SELECT 1 FROM public.team_members WHERE team_id = team2_id AND user_id = auth.uid() AND role IN ('captain', 'coach'))
        )
    );

CREATE POLICY "Match organizers can update matches" ON public.matches
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM public.teams WHERE id = team1_id AND owner_id = auth.uid()) OR
        EXISTS (SELECT 1 FROM public.team_members WHERE team_id = team1_id AND user_id = auth.uid() AND role IN ('captain', 'coach')) OR
        EXISTS (SELECT 1 FROM public.teams WHERE id = team2_id AND owner_id = auth.uid()) OR
        EXISTS (SELECT 1 FROM public.team_members WHERE team_id = team2_id AND user_id = auth.uid() AND role IN ('captain', 'coach'))
    );

CREATE POLICY "Match organizers can delete matches" ON public.matches
    FOR DELETE USING (
        EXISTS (SELECT 1 FROM public.teams WHERE id = team1_id AND owner_id = auth.uid()) OR
        EXISTS (SELECT 1 FROM public.team_members WHERE team_id = team1_id AND user_id = auth.uid() AND role IN ('captain', 'coach')) OR
        EXISTS (SELECT 1 FROM public.teams WHERE id = team2_id AND owner_id = auth.uid()) OR
        EXISTS (SELECT 1 FROM public.team_members WHERE team_id = team2_id AND user_id = auth.uid() AND role IN ('captain', 'coach'))
    );

-- Match participants policies - Enhanced with team-based access
CREATE POLICY "Participants and organizers can view match participation" ON public.match_participants
    FOR SELECT USING (
        user_id = auth.uid() OR
        EXISTS (SELECT 1 FROM public.matches WHERE id = match_id AND (
            EXISTS (SELECT 1 FROM public.teams WHERE id = team1_id AND owner_id = auth.uid()) OR
            EXISTS (SELECT 1 FROM public.teams WHERE id = team2_id AND owner_id = auth.uid())
        )) OR
        EXISTS (SELECT 1 FROM public.match_participants WHERE match_id = match_id AND user_id = auth.uid())
    );

CREATE POLICY "Users can join matches, organizers can add participants" ON public.match_participants
    FOR INSERT WITH CHECK (
        auth.uid() = user_id OR
        EXISTS (SELECT 1 FROM public.matches WHERE id = match_id AND (
            EXISTS (SELECT 1 FROM public.teams WHERE id = team1_id AND owner_id = auth.uid()) OR
            EXISTS (SELECT 1 FROM public.teams WHERE id = team2_id AND owner_id = auth.uid())
        ))
    );

CREATE POLICY "Users can update own participation, organizers can update all" ON public.match_participants
    FOR UPDATE USING (
        auth.uid() = user_id OR
        EXISTS (SELECT 1 FROM public.matches WHERE id = match_id AND (
            EXISTS (SELECT 1 FROM public.teams WHERE id = team1_id AND owner_id = auth.uid()) OR
            EXISTS (SELECT 1 FROM public.teams WHERE id = team2_id AND owner_id = auth.uid())
        ))
    );

CREATE POLICY "Users can leave matches, organizers can remove participants" ON public.match_participants
    FOR DELETE USING (
        auth.uid() = user_id OR
        EXISTS (SELECT 1 FROM public.matches WHERE id = match_id AND (
            EXISTS (SELECT 1 FROM public.teams WHERE id = team1_id AND owner_id = auth.uid()) OR
            EXISTS (SELECT 1 FROM public.teams WHERE id = team2_id AND owner_id = auth.uid())
        ))
    );

-- Notifications policies - Enhanced with system notification access
CREATE POLICY "Users can view own notifications and admins can view all" ON public.notifications
    FOR SELECT USING (
        auth.uid() = user_id OR
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "Users can update own notifications, system can create notifications" ON public.notifications
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "System can create notifications for users" ON public.notifications
    FOR INSERT WITH CHECK (true); -- Allow system to create notifications

CREATE POLICY "Admins can delete notifications" ON public.notifications
    FOR DELETE USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- Cities policies - Public read access
CREATE POLICY "Anyone can view cities" ON public.cities FOR SELECT USING (true);

-- ===========================================
-- 3. PERFORMANCE OPTIMIZATION INDEXES
-- ===========================================

-- Additional composite indexes for complex queries
CREATE INDEX IF NOT EXISTS idx_teams_owner_recruiting ON public.teams(owner_id, is_recruiting);
CREATE INDEX IF NOT EXISTS idx_teams_location_recruiting ON public.teams(location, is_recruiting) WHERE is_recruiting = true;

CREATE INDEX IF NOT EXISTS idx_matches_date_location ON public.matches(match_date, location);
CREATE INDEX IF NOT EXISTS idx_matches_status_date ON public.matches(status, match_date);
CREATE INDEX IF NOT EXISTS idx_matches_type_date ON public.matches(match_type, match_date DESC);
CREATE INDEX IF NOT EXISTS idx_matches_teams_date ON public.matches(team1_id, team2_id, match_date);

CREATE INDEX IF NOT EXISTS idx_match_participants_team_match ON public.match_participants(team_id, match_id);
CREATE INDEX IF NOT EXISTS idx_match_participants_status_date ON public.match_participants(status, joined_at DESC);

CREATE INDEX IF NOT EXISTS idx_team_members_role_joined ON public.team_members(role, joined_at DESC);
CREATE INDEX IF NOT EXISTS idx_team_members_team_role ON public.team_members(team_id, role);

-- Partial indexes for active/open records
CREATE INDEX IF NOT EXISTS idx_matches_open ON public.matches(match_date) WHERE status = 'open';
CREATE INDEX IF NOT EXISTS idx_matches_upcoming ON public.matches(match_date) WHERE match_date > NOW() AND status = 'open';
CREATE INDEX IF NOT EXISTS idx_teams_recruiting_active ON public.teams(created_at DESC) WHERE is_recruiting = true;

-- Text search optimization
CREATE INDEX IF NOT EXISTS idx_users_name_search ON public.users USING gin(to_tsvector('english', name));
CREATE INDEX IF NOT EXISTS idx_users_bio_search ON public.users USING gin(to_tsvector('english', COALESCE(bio, '')));
CREATE INDEX IF NOT EXISTS idx_teams_description_search ON public.teams USING gin(to_tsvector('english', COALESCE(description, '')));

-- ===========================================
-- 4. DATA INTEGRITY CONSTRAINTS
-- ===========================================

-- Additional check constraints for business rules
ALTER TABLE public.matches ADD CONSTRAINT check_match_date_future
    CHECK (match_date > NOW() - INTERVAL '1 hour'); -- Allow matches in the past hour for flexibility

ALTER TABLE public.matches ADD CONSTRAINT check_team1_not_equal_team2
    CHECK (team1_id != team2_id);

ALTER TABLE public.matches ADD CONSTRAINT check_max_players_reasonable
    CHECK (max_players >= 2 AND max_players <= 50);

ALTER TABLE public.teams ADD CONSTRAINT check_team_name_length
    CHECK (length(trim(name)) >= 2 AND length(trim(name)) <= 100);

ALTER TABLE public.users ADD CONSTRAINT check_user_name_length
    CHECK (length(trim(name)) >= 2 AND length(trim(name)) <= 100);

-- ===========================================
-- 5. AUDIT AND CLEANUP TRIGGERS
-- ===========================================

-- Create audit log table for sensitive operations
CREATE TABLE IF NOT EXISTS public.audit_log (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    table_name TEXT NOT NULL,
    operation TEXT NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    user_id UUID REFERENCES auth.users(id),
    record_id UUID NOT NULL,
    old_values JSONB,
    new_values JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on audit log
ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;

-- Audit log policies - only admins can view
CREATE POLICY "Admins can view audit logs" ON public.audit_log
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- Function to create audit triggers
CREATE OR REPLACE FUNCTION audit_sensitive_operations()
RETURNS TRIGGER AS $$
DECLARE
    audit_table_name TEXT;
    audit_operation TEXT;
BEGIN
    -- Determine table name and operation
    audit_table_name := TG_TABLE_NAME;
    audit_operation := TG_OP;

    -- Only audit sensitive tables
    IF audit_table_name IN ('users', 'teams', 'matches', 'team_members') THEN
        INSERT INTO public.audit_log (table_name, operation, user_id, record_id, old_values, new_values)
        VALUES (
            audit_table_name,
            audit_operation,
            auth.uid(),
            COALESCE(NEW.id, OLD.id),
            CASE WHEN audit_operation != 'INSERT' THEN row_to_json(OLD)::JSONB ELSE NULL END,
            CASE WHEN audit_operation != 'DELETE' THEN row_to_json(NEW)::JSONB ELSE NULL END
        );
    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Apply audit triggers to sensitive tables
CREATE TRIGGER audit_users_changes AFTER INSERT OR UPDATE OR DELETE ON public.users
    FOR EACH ROW EXECUTE FUNCTION audit_sensitive_operations();

CREATE TRIGGER audit_teams_changes AFTER INSERT OR UPDATE OR DELETE ON public.teams
    FOR EACH ROW EXECUTE FUNCTION audit_sensitive_operations();

CREATE TRIGGER audit_matches_changes AFTER INSERT OR UPDATE OR DELETE ON public.matches
    FOR EACH ROW EXECUTE FUNCTION audit_sensitive_operations();

CREATE TRIGGER audit_team_members_changes AFTER INSERT OR UPDATE OR DELETE ON public.team_members
    FOR EACH ROW EXECUTE FUNCTION audit_sensitive_operations();

-- Function to clean up old notifications (keep last 1000 per user)
CREATE OR REPLACE FUNCTION cleanup_old_notifications()
RETURNS TRIGGER AS $$
BEGIN
    -- Delete old notifications, keeping only the most recent 1000 per user
    DELETE FROM public.notifications
    WHERE id IN (
        SELECT id FROM (
            SELECT id,
                   ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at DESC) as rn
            FROM public.notifications
            WHERE user_id = NEW.user_id
        ) ranked
        WHERE ranked.rn > 1000
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply cleanup trigger to notifications
CREATE TRIGGER cleanup_notifications_trigger AFTER INSERT ON public.notifications
    FOR EACH ROW EXECUTE FUNCTION cleanup_old_notifications();

-- Function to automatically update match status based on date
CREATE OR REPLACE FUNCTION update_match_status_on_date()
RETURNS TRIGGER AS $$
BEGIN
    -- If match date has passed and status is still 'open', mark as 'completed'
    IF NEW.match_date < NOW() - INTERVAL '2 hours' AND NEW.status = 'open' THEN
        NEW.status := 'completed';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to matches table
CREATE TRIGGER update_match_status_trigger BEFORE UPDATE ON public.matches
    FOR EACH ROW EXECUTE FUNCTION update_match_status_on_date();

-- ===========================================
-- 6. ADDITIONAL UTILITY FUNCTIONS
-- ===========================================

-- Function to get user permissions for a team
CREATE OR REPLACE FUNCTION get_user_team_permissions(team_id_param UUID, user_id_param UUID)
RETURNS TABLE (
    is_owner BOOLEAN,
    is_member BOOLEAN,
    member_role TEXT,
    can_manage_members BOOLEAN,
    can_update_team BOOLEAN,
    can_create_matches BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        t.owner_id = user_id_param as is_owner,
        tm.user_id IS NOT NULL as is_member,
        COALESCE(tm.role, 'none') as member_role,
        (t.owner_id = user_id_param OR tm.role IN ('captain', 'coach')) as can_manage_members,
        (t.owner_id = user_id_param OR tm.role IN ('captain', 'coach')) as can_update_team,
        (t.owner_id = user_id_param OR tm.role IN ('captain', 'coach')) as can_create_matches
    FROM public.teams t
    LEFT JOIN public.team_members tm ON t.id = tm.team_id AND tm.user_id = user_id_param
    WHERE t.id = team_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user permissions for a match
CREATE OR REPLACE FUNCTION get_user_match_permissions(match_id_param UUID, user_id_param UUID)
RETURNS TABLE (
    can_view BOOLEAN,
    can_update BOOLEAN,
    can_delete BOOLEAN,
    can_manage_participants BOOLEAN,
    is_participant BOOLEAN,
    participant_status TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        (mp.user_id IS NOT NULL OR
         t1.owner_id = user_id_param OR t1_captain.user_id IS NOT NULL OR
         t2.owner_id = user_id_param OR t2_captain.user_id IS NOT NULL OR
         m.status = 'open') as can_view,
        (t1.owner_id = user_id_param OR t1_captain.user_id IS NOT NULL OR
         t2.owner_id = user_id_param OR t2_captain.user_id IS NOT NULL) as can_update,
        (t1.owner_id = user_id_param OR t1_captain.user_id IS NOT NULL OR
         t2.owner_id = user_id_param OR t2_captain.user_id IS NOT NULL) as can_delete,
        (t1.owner_id = user_id_param OR t1_captain.user_id IS NOT NULL OR
         t2.owner_id = user_id_param OR t2_captain.user_id IS NOT NULL) as can_manage_participants,
        mp.user_id IS NOT NULL as is_participant,
        COALESCE(mp.status, 'not_participating') as participant_status
    FROM public.matches m
    LEFT JOIN public.match_participants mp ON m.id = mp.match_id AND mp.user_id = user_id_param
    LEFT JOIN public.teams t1 ON m.team1_id = t1.id
    LEFT JOIN public.teams t2 ON m.team2_id = t2.id
    LEFT JOIN public.team_members t1_captain ON t1.id = t1_captain.team_id AND t1_captain.user_id = user_id_param AND t1_captain.role IN ('captain', 'coach')
    LEFT JOIN public.team_members t2_captain ON t2.id = t2_captain.team_id AND t2_captain.user_id = user_id_param AND t2_captain.role IN ('captain', 'coach')
    WHERE m.id = match_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- 7. MIGRATION COMPLETION MESSAGE
-- ===========================================

DO $$
BEGIN
    RAISE NOTICE 'Enhanced Security Policies and Performance Optimization Migration completed successfully!';
    RAISE NOTICE '';
    RAISE NOTICE 'Key improvements:';
    RAISE NOTICE '✓ Enhanced RLS policies with proper access controls';
    RAISE NOTICE '✓ Added admin-only operation policies';
    RAISE NOTICE '✓ Implemented team owner vs member permission distinctions';
    RAISE NOTICE '✓ Added match organizer permission controls';
    RAISE NOTICE '✓ Enhanced notification access controls';
    RAISE NOTICE '✓ Added comprehensive performance indexes';
    RAISE NOTICE '✓ Implemented data integrity constraints';
    RAISE NOTICE '✓ Added audit triggers for sensitive operations';
    RAISE NOTICE '✓ Created automatic cleanup triggers';
    RAISE NOTICE '✓ Added utility functions for permission checking';
    RAISE NOTICE '';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '1. Test all policies with different user roles';
    RAISE NOTICE '2. Monitor query performance improvements';
    RAISE NOTICE '3. Review audit logs for security monitoring';
    RAISE NOTICE '4. Update application code to handle new permission checks';
END $$;