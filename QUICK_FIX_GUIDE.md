# 🚀 Quick Fix Guide - PGRST204 Error

## ⚡ 3-Minute Fix

### Step 1: Run SQL (2 minutes)
1. Open [Supabase Dashboard](https://app.supabase.com)
2. Go to **SQL Editor**
3. Copy this SQL and click **Run**:

```sql
-- Add missing columns
ALTER TABLE users ADD COLUMN IF NOT EXISTS position TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS location TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS skill_level TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS bio TEXT;

-- Refresh cache
NOTIFY pgrst, 'reload schema';
```

### Step 2: Restart App (1 minute)
```bash
# In your terminal
flutter clean
flutter run
```

### Step 3: Test
1. Go to "Modifier le profil"
2. Fill all dropdowns
3. Click "Enregistrer"
4. ✅ Should save without error!

---

## 📋 What This Fixes

| Issue | Solution |
|-------|----------|
| ❌ PGRST204 error | ✅ Adds missing `position` column |
| ❌ Can't save profile | ✅ Adds `location`, `skill_level`, `bio` |
| ❌ Dropdowns show "..." | ✅ Fixed in Flutter code |
| ❌ Fields not in profile view | ✅ Updated profile_screen.dart |

---

## 🔍 Verify Success

Run this in SQL Editor:
```sql
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name IN ('position', 'location', 'skill_level', 'bio');
```

Should return 4 rows.

---

## 📞 Still Having Issues?

1. **Clear browser cache**: Ctrl+Shift+Delete
2. **Wait 30 seconds** for PostgREST to reload
3. **Check Supabase Dashboard** → Settings → API (should be "Active")
4. **See full guide**: `DATABASE_COLUMN_VERIFICATION.md`

---

## 🎯 Files Created

- ✅ `fix_user_profile_columns.sql` - Complete SQL migration
- ✅ `DATABASE_COLUMN_VERIFICATION.md` - Full troubleshooting guide
- ✅ `20250122000000_add_missing_user_profile_columns.sql` - Timestamped migration

---

## ✨ Done!

Your profile edit form should now work perfectly. All fields will save and display correctly.
