-- Quick fix: Update notification type constraint
-- Run this directly in Supabase SQL Editor

-- Step 1: Find and fix invalid notification types
UPDATE public.notifications 
SET type = 'general' 
WHERE type NOT IN (
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
);

-- Step 2: Drop old constraint
ALTER TABLE public.notifications 
DROP CONSTRAINT IF EXISTS notifications_type_check;

-- Step 3: Add new constraint with additional types
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
