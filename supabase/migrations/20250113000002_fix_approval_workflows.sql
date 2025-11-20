-- ============================================================================
-- PHASE 1: Database Functions for Safe Member Addition
-- ============================================================================

-- Drop existing functions if they exist
DROP FUNCTION IF EXISTS add_team_member_safe(UUID, UUID, TEXT);

-- Function: Safely add team member with duplicate check
CREATE OR REPLACE FUNCTION add_team_member_safe(
    p_team_id UUID,
    p_user_id UUID,
    p_role TEXT DEFAULT 'member'
)
RETURNS TABLE(success BOOLEAN, message TEXT, member_id UUID) AS $$
DECLARE
    v_member_id UUID;
    v_max_players INTEGER;
    v_current_count INTEGER;
    v_team_name TEXT;
BEGIN
    -- Check if member already exists
    SELECT id INTO v_member_id
    FROM public.team_members
    WHERE team_id = p_team_id AND user_id = p_user_id;
    
    IF v_member_id IS NOT NULL THEN
        RETURN QUERY SELECT FALSE, 'Member already exists in team', v_member_id;
        RETURN;
    END IF;
    
    -- Get team capacity
    SELECT max_players, name INTO v_max_players, v_team_name
    FROM public.teams
    WHERE id = p_team_id;
    
    -- Check current team size
    SELECT COUNT(*) INTO v_current_count
    FROM public.team_members
    WHERE team_id = p_team_id;
    
    -- Validate capacity
    IF v_current_count >= v_max_players THEN
        RETURN QUERY SELECT FALSE, 
            format('Team %s is full (%s/%s players)', v_team_name, v_current_count, v_max_players),
            NULL::UUID;
        RETURN;
    END IF;
    
    -- Insert new member
    INSERT INTO public.team_members (team_id, user_id, role, joined_at)
    VALUES (p_team_id, p_user_id, p_role, NOW())
    RETURNING id INTO v_member_id;
    
    RETURN QUERY SELECT TRUE, 'Member added successfully', v_member_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP FUNCTION IF EXISTS add_match_participant_safe(UUID, UUID, UUID, TEXT);

-- Function: Safely add match participant with validation
CREATE OR REPLACE FUNCTION add_match_participant_safe(
    p_match_id UUID,
    p_user_id UUID,
    p_team_id UUID DEFAULT NULL,
    p_status TEXT DEFAULT 'confirmed'
)
RETURNS TABLE(success BOOLEAN, message TEXT, participant_id UUID) AS $$
DECLARE
    v_participant_id UUID;
    v_max_players INTEGER;
    v_current_count INTEGER;
    v_match_status TEXT;
BEGIN
    -- Check if participant already exists
    SELECT id INTO v_participant_id
    FROM public.match_participants
    WHERE match_id = p_match_id AND user_id = p_user_id;
    
    IF v_participant_id IS NOT NULL THEN
        RETURN QUERY SELECT FALSE, 'Already joined this match', v_participant_id;
        RETURN;
    END IF;
    
    -- Get match details
    SELECT max_players, status INTO v_max_players, v_match_status
    FROM public.matches
    WHERE id = p_match_id;
    
    -- Check match status
    IF v_match_status NOT IN ('open', 'confirmed') THEN
        RETURN QUERY SELECT FALSE, 
            format('Match is %s and not accepting players', v_match_status),
            NULL::UUID;
        RETURN;
    END IF;
    
    -- Check current participant count
    SELECT COUNT(*) INTO v_current_count
    FROM public.match_participants
    WHERE match_id = p_match_id AND status = 'confirmed';
    
    -- Validate capacity
    IF v_current_count >= v_max_players THEN
        RETURN QUERY SELECT FALSE, 
            format('Match is full (%s/%s players)', v_current_count, v_max_players),
            NULL::UUID;
        RETURN;
    END IF;
    
    -- Insert new participant
    INSERT INTO public.match_participants (match_id, user_id, team_id, status, joined_at)
    VALUES (p_match_id, p_user_id, p_team_id, p_status, NOW())
    RETURNING id INTO v_participant_id;
    
    RETURN QUERY SELECT TRUE, 'Participant added successfully', v_participant_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- PHASE 2: Notification Helper Functions
-- ============================================================================

DROP FUNCTION IF EXISTS create_notification_safe(UUID, TEXT, TEXT, TEXT, UUID, JSONB);

-- Function: Create notification with translation key support
CREATE OR REPLACE FUNCTION create_notification_safe(
    p_user_id UUID,
    p_title_key TEXT,
    p_message_key TEXT,
    p_type TEXT,
    p_related_id UUID DEFAULT NULL,
    p_metadata JSONB DEFAULT '{}'::JSONB
)
RETURNS UUID AS $$
DECLARE
    v_notification_id UUID;
BEGIN
    INSERT INTO public.notifications (
        user_id,
        title,
        message,
        type,
        related_id,
        metadata,
        is_read,
        created_at
    )
    VALUES (
        p_user_id,
        p_title_key,  -- Store translation key
        p_message_key, -- Store translation key
        p_type,
        p_related_id,
        p_metadata,
        FALSE,
        NOW()
    )
    RETURNING id INTO v_notification_id;
    
    RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- PHASE 3: Trigger for Automatic Member Addition on Approval
-- ============================================================================

DROP FUNCTION IF EXISTS handle_team_join_approval();

-- Function: Handle team join request approval
CREATE OR REPLACE FUNCTION handle_team_join_approval()
RETURNS TRIGGER AS $$
DECLARE
    v_result RECORD;
    v_team_name TEXT;
    v_user_name TEXT;
BEGIN
    -- Only process when status changes to 'approved'
    IF NEW.status = 'approved' AND (OLD.status IS NULL OR OLD.status != 'approved') THEN
        
        -- Get team and user names for notifications
        SELECT name INTO v_team_name FROM public.teams WHERE id = NEW.team_id;
        SELECT name INTO v_user_name FROM public.users WHERE id = NEW.user_id;
        
        -- Add member to team using safe function
        SELECT * INTO v_result FROM add_team_member_safe(
            NEW.team_id,
            NEW.user_id,
            'member'
        );
        
        -- Create notification for the user (approved)
        IF v_result.success THEN
            PERFORM create_notification_safe(
                NEW.user_id,
                'notification.team_join_approved.title',
                'notification.team_join_approved.message',
                'team_join_approved',
                NEW.team_id,
                jsonb_build_object(
                    'team_name', v_team_name,
                    'request_id', NEW.id
                )
            );
        ELSE
            -- Member addition failed, log error
            RAISE WARNING 'Failed to add member to team: %', v_result.message;
            
            -- Still notify user but with error context
            PERFORM create_notification_safe(
                NEW.user_id,
                'notification.team_join_approved_error.title',
                'notification.team_join_approved_error.message',
                'system',
                NEW.team_id,
                jsonb_build_object(
                    'team_name', v_team_name,
                    'error', v_result.message,
                    'request_id', NEW.id
                )
            );
        END IF;
        
    -- Handle rejection
    ELSIF NEW.status = 'rejected' AND (OLD.status IS NULL OR OLD.status != 'rejected') THEN
        
        SELECT name INTO v_team_name FROM public.teams WHERE id = NEW.team_id;
        
        -- Create notification for the user (rejected)
        PERFORM create_notification_safe(
            NEW.user_id,
            'notification.team_join_rejected.title',
            'notification.team_join_rejected.message',
            'team_join_rejected',
            NEW.team_id,
            jsonb_build_object(
                'team_name', v_team_name,
                'request_id', NEW.id
            )
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
DROP TRIGGER IF EXISTS team_join_request_status_change ON public.team_join_requests;
CREATE TRIGGER team_join_request_status_change
    AFTER UPDATE OF status ON public.team_join_requests
    FOR EACH ROW
    EXECUTE FUNCTION handle_team_join_approval();

-- ============================================================================
-- PHASE 4: Match Request Bidirectional Notification System
-- ============================================================================

DROP FUNCTION IF EXISTS notify_match_request_created();

-- Function: Notify team2 owner when match is created
CREATE OR REPLACE FUNCTION notify_match_request_created()
RETURNS TRIGGER AS $$
DECLARE
    v_team1_name TEXT;
    v_team2_owner UUID;
BEGIN
    -- Only send notification for pending matches
    IF NEW.status = 'pending' AND NEW.team2_id IS NOT NULL THEN
        
        -- Get team1 name
        SELECT name INTO v_team1_name FROM public.teams WHERE id = NEW.team1_id;
        
        -- Get team2 owner
        SELECT owner_id INTO v_team2_owner FROM public.teams WHERE id = NEW.team2_id;
        
        -- Create notification for team2 owner
        PERFORM create_notification_safe(
            v_team2_owner,
            'notification.match_request_received.title',
            'notification.match_request_received.message',
            'match_request',
            NEW.id,
            jsonb_build_object(
                'team1_name', v_team1_name,
                'match_date', NEW.match_date,
                'location', NEW.location
            )
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP FUNCTION IF EXISTS notify_match_request_response();

-- Function: Notify team1 owner when match is accepted/rejected
CREATE OR REPLACE FUNCTION notify_match_request_response()
RETURNS TRIGGER AS $$
DECLARE
    v_team1_owner UUID;
    v_team2_name TEXT;
BEGIN
    -- Status changed from pending to confirmed or cancelled
    IF OLD.status = 'pending' AND NEW.status IN ('confirmed', 'cancelled') THEN
        
        -- Get team1 owner
        SELECT owner_id INTO v_team1_owner FROM public.teams WHERE id = NEW.team1_id;
        
        -- Get team2 name
        SELECT name INTO v_team2_name FROM public.teams WHERE id = NEW.team2_id;
        
        -- Create notification based on new status
        IF NEW.status = 'confirmed' THEN
            PERFORM create_notification_safe(
                v_team1_owner,
                'notification.match_request_accepted.title',
                'notification.match_request_accepted.message',
                'match_accepted',
                NEW.id,
                jsonb_build_object(
                    'team2_name', v_team2_name,
                    'match_date', NEW.match_date,
                    'location', NEW.location
                )
            );
        ELSIF NEW.status = 'cancelled' THEN
            PERFORM create_notification_safe(
                v_team1_owner,
                'notification.match_request_rejected.title',
                'notification.match_request_rejected.message',
                'match_rejected',
                NEW.id,
                jsonb_build_object(
                    'team2_name', v_team2_name,
                    'match_date', NEW.match_date
                )
            );
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create triggers
DROP TRIGGER IF EXISTS match_request_created_notification ON public.matches;
CREATE TRIGGER match_request_created_notification
    AFTER INSERT ON public.matches
    FOR EACH ROW
    EXECUTE FUNCTION notify_match_request_created();

DROP TRIGGER IF EXISTS match_request_response_notification ON public.matches;
CREATE TRIGGER match_request_response_notification
    AFTER UPDATE OF status ON public.matches
    FOR EACH ROW
    EXECUTE FUNCTION notify_match_request_response();

-- ============================================================================
-- PHASE 5: Edge Case Constraints
-- ============================================================================

-- Add metadata column to notifications for extensibility
ALTER TABLE public.notifications 
ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'::JSONB;

-- Create index on metadata for better query performance
CREATE INDEX IF NOT EXISTS idx_notifications_metadata ON public.notifications USING gin(metadata);

-- Prevent duplicate pending requests
CREATE UNIQUE INDEX IF NOT EXISTS idx_team_join_requests_unique_pending
ON public.team_join_requests(team_id, user_id)
WHERE status = 'pending';

-- Add request expiration (optional, can be enforced in application layer)
ALTER TABLE public.team_join_requests
ADD COLUMN IF NOT EXISTS expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '30 days');

CREATE INDEX IF NOT EXISTS idx_team_join_requests_expires
ON public.team_join_requests(expires_at) WHERE status = 'pending';

-- ============================================================================
-- PHASE 6: Update Notification Types
-- ============================================================================

-- First, clean up invalid notification types
UPDATE public.notifications
SET type = 'system'
WHERE type NOT IN (
    'match_invite',
    'match_request',
    'match_accepted',
    'match_rejected',
    'match_joined',
    'team_invite',
    'team_join_request',
    'team_join_approved',
    'team_join_rejected',
    'general',
    'system'
);

-- Update notification type constraint
ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_type_check;
ALTER TABLE public.notifications
ADD CONSTRAINT notifications_type_check
CHECK (type IN (
    'match_invite',
    'match_request',
    'match_accepted',
    'match_rejected',
    'match_joined',
    'team_invite',
    'team_join_request',
    'team_join_approved',
    'team_join_rejected',
    'general',
    'system'
));

-- ============================================================================
-- PHASE 7: Grant Permissions
-- ============================================================================

-- Grant execute permissions on functions to authenticated users
GRANT EXECUTE ON FUNCTION add_team_member_safe TO authenticated;
GRANT EXECUTE ON FUNCTION add_match_participant_safe TO authenticated;
GRANT EXECUTE ON FUNCTION create_notification_safe TO authenticated;

-- ============================================================================
-- Success Message
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '✅ Request-Approval Workflow Migration Complete!';
    RAISE NOTICE '';
    RAISE NOTICE 'Created Functions:';
    RAISE NOTICE '  - add_team_member_safe()';
    RAISE NOTICE '  - add_match_participant_safe()';
    RAISE NOTICE '  - create_notification_safe()';
    RAISE NOTICE '  - handle_team_join_approval()';
    RAISE NOTICE '  - notify_match_request_created()';
    RAISE NOTICE '  - notify_match_request_response()';
    RAISE NOTICE '';
    RAISE NOTICE 'Created Triggers:';
    RAISE NOTICE '  - team_join_request_status_change';
    RAISE NOTICE '  - match_request_created_notification';
    RAISE NOTICE '  - match_request_response_notification';
    RAISE NOTICE '';
    RAISE NOTICE 'Next Steps:';
    RAISE NOTICE '  1. Update translation files with new notification keys';
    RAISE NOTICE '  2. Update frontend to handle new notification types';
    RAISE NOTICE '  3. Test all approval workflows end-to-end';
END $$;