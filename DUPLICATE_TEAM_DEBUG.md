# Duplicate Team Name Error - Web Version

## Issue
Getting "You already have a team with this name" error when creating team "GROUPENIYA1" on web version.

## Possible Causes

### 1. Previous Failed Creation
The team might have been partially created in a previous attempt:
- Team record exists in database
- But user doesn't see it in the UI
- Subsequent attempts fail due to constraint

### 2. Case-Insensitive Constraint
The constraint uses `lower(trim(name))`:
```sql
EXCLUDE (owner_id WITH =, lower(trim(name)) WITH =)
```
So "GROUPENIYA1", "groupeniya1", "GroupeNiya1" are all considered duplicates.

### 3. Whitespace Issues
The constraint trims whitespace, so " GROUPENIYA1 " = "GROUPENIYA1"

## Debug Steps

### Step 1: Check if team already exists
Run this query in Supabase SQL Editor:
```sql
SELECT id, name, owner_id, created_at 
FROM teams 
WHERE LOWER(TRIM(name)) = LOWER(TRIM('GROUPENIYA1'));
```

### Step 2: Check current user's teams
```sql
SELECT id, name, owner_id, created_at 
FROM teams 
WHERE owner_id = (SELECT auth.uid());
```

### Step 3: If team exists but not visible, check team_members
```sql
SELECT tm.*, t.name as team_name
FROM team_members tm
JOIN teams t ON tm.team_id = t.id
WHERE tm.user_id = (SELECT auth.uid());
```

## Solutions

### Solution 1: Delete the orphaned team
If the team exists but isn't visible:
```sql
DELETE FROM teams 
WHERE LOWER(TRIM(name)) = LOWER(TRIM('GROUPENIYA1'))
AND owner_id = (SELECT auth.uid());
```

### Solution 2: Use a different name
Try creating the team with a slightly different name:
- "GROUPENIYA1_NEW"
- "GROUPENIYA_1"
- "GROUPENIYA01"

### Solution 3: Clear browser cache
For web version specifically:
1. Open browser DevTools (F12)
2. Go to Application/Storage tab
3. Clear all site data
4. Refresh page
5. Try again

## Verification

After applying solution, verify:
1. Team appears in Teams list
2. User is listed as owner in team_members table
3. Can create another team with different name
4. Cannot create another team with same name (correct behavior)
