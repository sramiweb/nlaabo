# Database Column Verification Checklist

## Problem Summary
**Error**: `PGRST204 - Could not find the 'position' column of 'users' in the schema cache`

**Root Cause**: Missing columns in the `users` table that the application expects.

---

## Solution Steps

### 1. Apply SQL Migration

**Option A: Via Supabase SQL Editor (RECOMMENDED)**
1. Go to your Supabase Dashboard
2. Navigate to SQL Editor
3. Copy and paste the contents of `fix_user_profile_columns.sql`
4. Click "Run" to execute
5. Verify success message: "All columns added successfully!"

**Option B: Via Supabase CLI**
```bash
supabase db push
```

---

### 2. Refresh PostgREST Schema Cache

The migration automatically sends `NOTIFY pgrst, 'reload schema'`, but you can also:

**Manual Refresh Options:**

1. **Restart PostgREST** (if self-hosted):
   ```bash
   systemctl restart postgrest
   ```

2. **Via Supabase Dashboard**:
   - Go to Settings → API
   - Click "Restart API" button

3. **Wait 30 seconds**: PostgREST auto-reloads schema periodically

---

### 3. Verify All Form Fields Have Database Columns

Run this query in Supabase SQL Editor:

```sql
-- Check all required columns exist
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'name') THEN '✅'
        ELSE '❌'
    END AS name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'email') THEN '✅'
        ELSE '❌'
    END AS email,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'bio') THEN '✅'
        ELSE '❌'
    END AS bio,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'phone') THEN '✅'
        ELSE '❌'
    END AS phone,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'age') THEN '✅'
        ELSE '❌'
    END AS age,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'location') THEN '✅'
        ELSE '❌'
    END AS location,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'position') THEN '✅'
        ELSE '❌'
    END AS position,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'skill_level') THEN '✅'
        ELSE '❌'
    END AS skill_level,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'gender') THEN '✅'
        ELSE '❌'
    END AS gender;
```

**Expected Result**: All fields should show ✅

---

### 4. Form Field to Database Column Mapping

| Form Field (French) | Database Column | Data Type | Required | Notes |
|---------------------|-----------------|-----------|----------|-------|
| Nom complet | `name` | TEXT | ✅ Yes | Full name |
| Email | `email` | TEXT | ✅ Yes | Read-only in edit form |
| Bio | `bio` | TEXT | ❌ No | Max 200 characters |
| Téléphone | `phone` | TEXT | ❌ No | Format: +212XXXXXXXXX |
| Âge | `age` | INTEGER | ❌ No | Range: 13-100 |
| Emplacement | `location` | TEXT | ❌ No | City dropdown |
| Position | `position` | TEXT | ❌ No | Football position |
| Niveau de compétence | `skill_level` | TEXT | ❌ No | beginner/intermediate/advanced |
| Genre | `gender` | TEXT | ✅ Yes | male/female |

---

### 5. Test Profile Update

After applying the migration:

1. **Clear browser cache** (Ctrl+Shift+Delete)
2. **Reload the application** (F5)
3. Go to "Modifier le profil" (Edit Profile)
4. Fill in the form:
   - Select a value for "Emplacement" (Location)
   - Select a value for "Position"
   - Select a value for "Niveau de compétence" (Skill Level)
   - Select a value for "Genre" (Gender)
5. Click "Enregistrer" (Save)
6. **Expected**: Success message, no PGRST204 error
7. **Verify**: Go back to profile view and confirm all fields display

---

### 6. Prevent Future PGRST204 Errors

#### Best Practices:

1. **Always create migrations before adding UI fields**:
   ```bash
   # Create migration first
   supabase migration new add_user_field_xyz
   
   # Then add UI field in Flutter
   ```

2. **Use TypeScript types** (if using Supabase client):
   ```typescript
   // Generate types from database
   supabase gen types typescript --local > types/database.ts
   ```

3. **Add column existence checks** in your API service:
   ```dart
   // Before updating, verify column exists
   final columns = await _supabase
       .from('users')
       .select()
       .limit(1);
   ```

4. **Monitor PostgREST logs** for schema cache issues

5. **Document all database changes** in migration files

---

### 7. Troubleshooting

#### If error persists after migration:

1. **Check migration was applied**:
   ```sql
   SELECT * FROM supabase_migrations.schema_migrations 
   WHERE name LIKE '%user_profile%';
   ```

2. **Manually verify columns**:
   ```sql
   SELECT column_name FROM information_schema.columns 
   WHERE table_name = 'users';
   ```

3. **Check PostgREST is running**:
   - Supabase Dashboard → Settings → API
   - Status should be "Active"

4. **Clear Flutter app cache**:
   ```bash
   flutter clean
   flutter pub get
   ```

5. **Restart the app completely**

---

### 8. Additional Recommendations

#### Add RLS Policies for New Columns

```sql
-- Allow users to update their own profile fields
CREATE POLICY "Users can update own profile"
ON users FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);
```

#### Add Validation Constraints

```sql
-- Limit bio length
ALTER TABLE users 
ADD CONSTRAINT bio_length_check 
CHECK (LENGTH(bio) <= 200 OR bio IS NULL);

-- Validate phone format
ALTER TABLE users 
ADD CONSTRAINT phone_format_check 
CHECK (phone ~ '^\+[0-9]{10,15}$' OR phone IS NULL);
```

---

## Success Criteria

- ✅ All 9 form fields have corresponding database columns
- ✅ Profile update saves without PGRST204 error
- ✅ All fields display correctly in profile view
- ✅ Dropdowns show selected values or hints
- ✅ No console errors in browser or Flutter

---

## Support

If issues persist:
1. Check Supabase logs in Dashboard → Logs
2. Check Flutter console for detailed error messages
3. Verify PostgREST version compatibility
4. Contact Supabase support with error details
