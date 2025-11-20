-- QUICK FIX: Run this in Supabase SQL Editor to fix match creation error
-- This updates the notifications constraint to allow match_request types

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

-- Verify the constraint was updated
SELECT conname, pg_get_constraintdef(oid) 
FROM pg_constraint 
WHERE conname = 'notifications_type_check';
