-- Add team_member_removed and team_member_left notification types

-- First, clean up invalid notification types
UPDATE public.notifications
SET type = 'system'
WHERE type NOT IN (
  'match_invite',
  'team_invite', 
  'team_join_request',
  'team_join_approved',
  'team_join_rejected',
  'team_member_left',
  'team_member_removed',
  'match_created',
  'match_joined',
  'match_left',
  'match_reminder',
  'general',
  'system',
  'system_notification'
);

ALTER TABLE public.notifications 
DROP CONSTRAINT IF EXISTS notifications_type_check;

ALTER TABLE public.notifications 
ADD CONSTRAINT notifications_type_check 
CHECK (type IN (
  'match_invite',
  'team_invite', 
  'team_join_request',
  'team_join_approved',
  'team_join_rejected',
  'team_member_left',
  'team_member_removed',
  'match_created',
  'match_joined',
  'match_left',
  'match_reminder',
  'general',
  'system',
  'system_notification'
));
