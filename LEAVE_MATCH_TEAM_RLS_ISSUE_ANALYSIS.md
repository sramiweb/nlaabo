# Leave Match/Team RLS Policy Issue - Root Cause Analysis

## Problem
Players cannot leave matches or teams. The API calls succeed (no errors), but the delete operations are blocked by Row Level Security (RLS) policies.

## Root Cause: RLS DELETE Policies Missing

### Match Participants Table
**File**: `supabase/migrations/20251025100000_enhanced_security_policies.sql`

**Current DELETE Policy**:
```sql
CREATE POLICY "Users can leave matches, organizers can remove participants" ON public.match_participants
    FOR DELETE USING (
        auth.uid() = user_id OR
        EXISTS (SELECT 1 FROM public.matches WHERE id = match_id AND (
            EXISTS (SELECT 1 FROM public.teams WHERE id = team1_id AND owner_id = auth.uid()) OR
            EXISTS (SELECT 1 FROM public.teams WHERE id = team2_id AND owner_id = auth.uid())
        ))
    );
```

**Issue**: This policy looks correct, but let's verify the API call is using the right user context.

### Team Members Table
**File**: `supabase/migrations/20251025100000_enhanced_security_policies.sql`

**Current DELETE Policy**:
```sql
CREATE POLICY "Team owners and captains can manage members" ON public.team_members
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.teams WHERE id = team_id AND owner_id = auth.uid()) OR
        EXISTS (SELECT 1 FROM public.team_members WHERE team_id = team_id AND user_id = auth.uid() AND role IN ('captain', 'coach'))
    );
```

**Issue**: The `FOR ALL` policy doesn't explicitly allow members to delete themselves! It only allows:
1. Team owners to delete any member
2. Captains/coaches to delete any member
3. **BUT NOT regular members to delete themselves**

## Detailed Analysis

### 1. Match Leave - Likely Working
The match_participants DELETE policy explicitly allows `auth.uid() = user_id`, so users should be able to leave matches.

**API Method** (`lib/services/api_service.dart`):
```dart
Future<void> leaveMatch(String matchId) async {
  return ErrorHandler.withRetry(
    () async {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw AuthError('No authenticated user');
      }

      await _supabase
          .from('match_participants')
          .delete()
          .eq('match_id', matchId)
          .eq('user_id', user.id);
    },
    config: _defaultRetryConfig,
    context: 'ApiService.leaveMatch',
  );
}
```

**Potential Issue**: If the error is silent, check if:
- The user is authenticated (`auth.uid()` is set)
- The delete query has both `match_id` and `user_id` filters

### 2. Team Leave - **BROKEN** ❌
The team_members DELETE policy does NOT allow regular members to delete themselves!

**API Method** (`lib/services/api_service.dart`):
```dart
Future<void> leaveTeam(String teamId) async {
  return ErrorHandler.withRetry(
    () async {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw AuthError('No authenticated user');
      }

      await _supabase
          .from('team_members')
          .delete()
          .eq('team_id', teamId)
          .eq('user_id', user.id);
    },
    config: _defaultRetryConfig,
    context: 'ApiService.leaveTeam',
  );
}
```

**Problem**: The RLS policy checks:
```sql
EXISTS (SELECT 1 FROM public.teams WHERE id = team_id AND owner_id = auth.uid())
```
This only returns true if the current user is the team owner, NOT if they're a regular member trying to leave.

## Solution

### Fix Team Members DELETE Policy

Replace the current policy with one that explicitly allows members to delete themselves:

```sql
-- Drop the existing policy
DROP POLICY IF EXISTS "Team owners and captains can manage members" ON public.team_members;

-- Create separate policies for better clarity
CREATE POLICY "Team owners and captains can manage all members" ON public.team_members
    FOR DELETE USING (
        EXISTS (SELECT 1 FROM public.teams WHERE id = team_id AND owner_id = auth.uid()) OR
        EXISTS (SELECT 1 FROM public.team_members WHERE team_id = team_id AND user_id = auth.uid() AND role IN ('captain', 'coach'))
    );

CREATE POLICY "Members can leave teams" ON public.team_members
    FOR DELETE USING (auth.uid() = user_id);
```

### Alternative: Update Existing Policy

Modify the existing policy to include self-deletion:

```sql
DROP POLICY IF EXISTS "Team owners and captains can manage members" ON public.team_members;

CREATE POLICY "Team owners and captains can manage members" ON public.team_members
    FOR ALL USING (
        auth.uid() = user_id OR  -- Allow members to delete themselves
        EXISTS (SELECT 1 FROM public.teams WHERE id = team_id AND owner_id = auth.uid()) OR
        EXISTS (SELECT 1 FROM public.team_members WHERE team_id = team_id AND user_id = auth.uid() AND role IN ('captain', 'coach'))
    );
```

## Testing Checklist

After applying the fix:

### Match Leave
- [ ] Regular member can leave match
- [ ] Match organizer can remove participants
- [ ] User cannot delete other users' participations
- [ ] Verify optimistic UI update works

### Team Leave
- [ ] Regular member can leave team
- [ ] Team owner can remove members
- [ ] Captain/coach can remove members
- [ ] User cannot delete other users' memberships
- [ ] Team owner cannot leave their own team (should transfer ownership first)
- [ ] Verify optimistic UI update works

## Migration File to Create

Create: `supabase/migrations/YYYYMMDD_fix_team_leave_policy.sql`

```sql
-- Fix team members DELETE policy to allow members to leave teams
-- This migration fixes the issue where regular members cannot leave teams

-- Drop the existing policy
DROP POLICY IF EXISTS "Team owners and captains can manage members" ON public.team_members;

-- Create updated policy that allows members to delete themselves
CREATE POLICY "Team owners and captains can manage members" ON public.team_members
    FOR ALL USING (
        auth.uid() = user_id OR  -- ✅ Allow members to delete themselves
        EXISTS (SELECT 1 FROM public.teams WHERE id = team_id AND owner_id = auth.uid()) OR
        EXISTS (SELECT 1 FROM public.team_members WHERE team_id = team_id AND user_id = auth.uid() AND role IN ('captain', 'coach'))
    );

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Team leave policy fixed successfully!';
    RAISE NOTICE 'Members can now leave teams.';
END $$;
```

## Additional Considerations

### 1. Prevent Team Owner from Leaving
Add a check constraint or trigger to prevent team owners from leaving their own team:

```sql
CREATE OR REPLACE FUNCTION prevent_owner_leave()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM public.teams 
        WHERE id = OLD.team_id 
        AND owner_id = OLD.user_id
    ) THEN
        RAISE EXCEPTION 'Team owner cannot leave the team. Transfer ownership first.';
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER prevent_owner_leave_trigger
    BEFORE DELETE ON public.team_members
    FOR EACH ROW
    EXECUTE FUNCTION prevent_owner_leave();
```

### 2. Verify Match Leave Policy
If match leave is also not working, check:
- Authentication state
- Error handling in the UI
- Network connectivity
- Supabase client initialization

## Priority
**CRITICAL** - This blocks core functionality

## Estimated Fix Time
- Migration creation: 5 minutes
- Testing: 10 minutes
- Deployment: 5 minutes
**Total: 20 minutes**

---

**Status**: IDENTIFIED - Ready to fix
**Date**: 2025
