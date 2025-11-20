-- Add missing notification types for team join requests
-- This allows the application to create notifications when join requests are approved/rejected

-- Drop the existing constraint
ALTER TABLE public.notifications 
DROP CONSTRAINT IF EXISTS notifications_type_check;

-- Add updated constraint with all notification types
ALTER TABLE public.notifications 
ADD CONSTRAINT notifications_type_check 
CHECK (type IN (
  'match_invite',
  'team_invite', 
  'team_join_request',
  'team_join_approved',
  'team_join_rejected',
  'match_created',
  'match_joined',
  'match_left',
  'match_reminder',
  'general',
  'system',
  'system_notification'
));

-- Add policy to allow system to insert notifications
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'notifications' 
        AND policyname = 'System can insert notifications'
    ) THEN
        CREATE POLICY "System can insert notifications" ON public.notifications
          FOR INSERT WITH CHECK (true);
    END IF;
END $$;
