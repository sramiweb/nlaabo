# Quick Fix: Enable Notifications

## Problem
Notifications are not working for team/match requests.

## Solution
Run ONE command:

```bash
supabase db push
```

## What This Fixes

✅ **Team Owner** receives notification when someone requests to join  
✅ **Player** receives notification when request is accepted  
✅ **Player** receives notification when request is rejected  
✅ **Match Creator** receives notification when someone joins  

## That's It!

All the code is already implemented. The database just needs to allow these notification types.

## Verify It Works

1. **Test Team Join:**
   - User A creates a team
   - User B requests to join
   - User A sees notification ✅
   - User A accepts/rejects
   - User B sees notification ✅

2. **Test Match Join:**
   - User A creates a match
   - User B joins match
   - User A sees notification ✅

## Files
- Migration: `supabase/migrations/20250113000000_add_notification_types.sql`
- Full docs: `NOTIFICATION_FLOW.md`
