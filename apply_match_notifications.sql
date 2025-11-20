-- Run this in Supabase SQL Editor to add match request notifications

BEGIN;

-- Update notification types to include match_request, match_accepted, match_rejected
ALTER TABLE public.notifications 
DROP CONSTRAINT IF EXISTS notifications_type_check;

ALTER TABLE public.notifications 
ADD CONSTRAINT notifications_type_check 
CHECK (type IN (
  'match_invite',
  'match_request',
  'match_accepted',
  'match_rejected',
  'team_invite', 
  'team_join_request',
  'team_join_approved',
  'team_join_rejected',
  'match_created',
  'match_joined',
  'match_left',
  'match_reminder',
  'team_member_left',
  'general',
  'system',
  'system_notification'
));

-- Create function to notify team2 owner when match request is created
CREATE OR REPLACE FUNCTION notify_match_request_created()
RETURNS TRIGGER AS $$
DECLARE
  team2_owner_id UUID;
  team1_name TEXT;
  team2_name TEXT;
BEGIN
  -- Only send notification for new pending matches
  IF NEW.status = 'pending' AND (TG_OP = 'INSERT' OR OLD.status != 'pending') THEN
    -- Get team2 owner ID
    SELECT owner_id INTO team2_owner_id
    FROM teams
    WHERE id = NEW.team2_id;
    
    -- Get team names
    SELECT name INTO team1_name FROM teams WHERE id = NEW.team1_id;
    SELECT name INTO team2_name FROM teams WHERE id = NEW.team2_id;
    
    -- Create notification for team2 owner
    IF team2_owner_id IS NOT NULL THEN
      INSERT INTO notifications (
        user_id,
        type,
        title,
        message,
        related_id,
        data
      ) VALUES (
        team2_owner_id,
        'match_request',
        'Nouvelle demande de match',
        team1_name || ' vous demande un match le ' || TO_CHAR(NEW.match_date, 'DD/MM/YYYY à HH24:MI'),
        NEW.id,
        jsonb_build_object(
          'match_id', NEW.id,
          'team1_id', NEW.team1_id,
          'team1_name', team1_name,
          'team2_id', NEW.team2_id,
          'team2_name', team2_name,
          'match_date', NEW.match_date,
          'location', NEW.location
        )
      );
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for match request notifications
DROP TRIGGER IF EXISTS match_request_notification_trigger ON matches;
CREATE TRIGGER match_request_notification_trigger
  AFTER INSERT OR UPDATE ON matches
  FOR EACH ROW
  EXECUTE FUNCTION notify_match_request_created();

-- Create function to notify when match request is accepted/rejected
CREATE OR REPLACE FUNCTION notify_match_request_response()
RETURNS TRIGGER AS $$
DECLARE
  team1_owner_id UUID;
  team1_name TEXT;
  team2_name TEXT;
  notification_type TEXT;
  notification_title TEXT;
  notification_message TEXT;
BEGIN
  -- Only send notification when status changes from pending to confirmed/cancelled
  IF OLD.status = 'pending' AND NEW.status IN ('confirmed', 'cancelled') THEN
    -- Get team1 owner ID (the one who sent the request)
    SELECT owner_id INTO team1_owner_id
    FROM teams
    WHERE id = NEW.team1_id;
    
    -- Get team names
    SELECT name INTO team1_name FROM teams WHERE id = NEW.team1_id;
    SELECT name INTO team2_name FROM teams WHERE id = NEW.team2_id;
    
    -- Determine notification type and message
    IF NEW.status = 'confirmed' THEN
      notification_type := 'match_accepted';
      notification_title := 'Demande de match acceptée';
      notification_message := team2_name || ' a accepté votre demande de match pour le ' || TO_CHAR(NEW.match_date, 'DD/MM/YYYY à HH24:MI');
    ELSE
      notification_type := 'match_rejected';
      notification_title := 'Demande de match refusée';
      notification_message := team2_name || ' a refusé votre demande de match';
    END IF;
    
    -- Create notification for team1 owner
    IF team1_owner_id IS NOT NULL THEN
      INSERT INTO notifications (
        user_id,
        type,
        title,
        message,
        related_id,
        data
      ) VALUES (
        team1_owner_id,
        notification_type,
        notification_title,
        notification_message,
        NEW.id,
        jsonb_build_object(
          'match_id', NEW.id,
          'team1_id', NEW.team1_id,
          'team1_name', team1_name,
          'team2_id', NEW.team2_id,
          'team2_name', team2_name,
          'match_date', NEW.match_date,
          'location', NEW.location,
          'status', NEW.status
        )
      );
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for match response notifications
DROP TRIGGER IF EXISTS match_response_notification_trigger ON matches;
CREATE TRIGGER match_response_notification_trigger
  AFTER UPDATE ON matches
  FOR EACH ROW
  EXECUTE FUNCTION notify_match_request_response();

COMMIT;

-- Verify triggers were created
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE trigger_name IN ('match_request_notification_trigger', 'match_response_notification_trigger');
