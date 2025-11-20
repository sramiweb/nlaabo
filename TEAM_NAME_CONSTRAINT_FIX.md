# Team Name Constraint Fix

## Issue
Users were getting "You already have a team with this name" error when creating teams, even when they didn't have any team with that name.

## Root Cause
There were **two conflicting constraints** on team names:

1. **Global Unique Constraint** (from migration `20251025040000_fix_unique_team_name.sql`):
   ```sql
   ALTER TABLE teams ADD CONSTRAINT unique_team_name UNIQUE (name);
   ```
   - ❌ Prevented ANY two teams from having the same name
   - ❌ Even if owned by different users
   - ❌ Too restrictive

2. **Per-Owner Constraint** (from migration `20251025110000_additional_indexes_constraints.sql`):
   ```sql
   ALTER TABLE teams ADD CONSTRAINT unique_team_owner_name
       EXCLUDE (owner_id WITH =, lower(trim(name)) WITH =)
       WHERE (owner_id IS NOT NULL);
   ```
   - ✅ Prevents same owner from having duplicate team names
   - ✅ Allows different owners to use same team name
   - ✅ Case-insensitive comparison
   - ✅ Correct behavior

## The Problem
The global constraint was blocking team creation when:
- User A creates "Warriors"
- User B tries to create "Warriors" → ❌ ERROR (blocked by global constraint)

This is wrong because different users should be able to use the same team name.

## Solution
Remove the global unique constraint and keep only the per-owner constraint.

### Migration: `20250114000000_fix_team_name_constraint.sql`
```sql
-- Remove global constraint
ALTER TABLE public.teams DROP CONSTRAINT IF EXISTS unique_team_name;

-- Keep per-owner constraint (already exists)
-- Ensures: same owner cannot have duplicate team names
-- Allows: different owners to have teams with same name
```

## After Fix

### ✅ Allowed
- User A creates "Warriors"
- User B creates "Warriors" ✅ (different owner)
- User C creates "Warriors" ✅ (different owner)

### ❌ Blocked
- User A creates "Warriors"
- User A tries to create "Warriors" again ❌ (same owner, same name)
- User A tries to create "WARRIORS" ❌ (case-insensitive match)
- User A tries to create " Warriors " ❌ (trimmed match)

## How to Apply
```bash
supabase db push
```

## Testing
1. User A creates team "Eagles" → ✅ Success
2. User B creates team "Eagles" → ✅ Success (different owner)
3. User A tries to create "Eagles" again → ❌ Error (duplicate for same owner)
4. User A tries to create "EAGLES" → ❌ Error (case-insensitive)
5. User A creates team "Lions" → ✅ Success (different name)

## Files
- Migration: `supabase/migrations/20250114000000_fix_team_name_constraint.sql`
- Documentation: `TEAM_NAME_CONSTRAINT_FIX.md`
