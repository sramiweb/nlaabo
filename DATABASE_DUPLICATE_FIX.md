# Database Duplicate Match Issue - Root Cause & Fix

## Root Cause

The three match cards showing identical data ("today match", "Nador", "1/11 18:00", "22 players") is caused by:

**Duplicate test records in the database** - The same match was created multiple times with identical information.

## Evidence

From `api_service.dart` line ~1150:
```dart
Future<List<Match>> getMatches({int? limit, int? offset}) async {
  var query = _supabase
      .from('matches')
      .select('*')
      .order('match_date');
  // ... returns ALL matches without deduplication
}
```

The query fetches all matches from the database. If there are 3 identical records, all 3 will be displayed.

## Solutions

### Option 1: Clean Database (Recommended)
Delete duplicate test matches from Supabase:

```sql
-- Find duplicates
SELECT title, location, match_date, COUNT(*) as count
FROM matches
GROUP BY title, location, match_date
HAVING COUNT(*) > 1;

-- Delete duplicates, keeping only one
DELETE FROM matches
WHERE id NOT IN (
  SELECT MIN(id)
  FROM matches
  GROUP BY title, location, match_date
);
```

### Option 2: Add Deduplication in Code
Modify the `_filterContent()` method in `home_provider.dart`:

```dart
void _filterContent() {
  if (_searchQuery.isEmpty) {
    // Remove duplicates based on match key properties
    final seen = <String>{};
    _featuredMatches = _allMatches.where((match) {
      final key = '${match.displayTitle}_${match.location}_${match.formattedDate}';
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).take(HomeConstants.featuredItemsCount).toList();
    
    _featuredTeams = _allTeams.take(HomeConstants.featuredItemsCount).toList();
  } else {
    // ... existing search logic
  }
}
```

### Option 3: Create Better Test Data
Instead of creating identical matches, create varied test data:

```sql
-- Delete existing test matches
DELETE FROM matches WHERE title = 'today match';

-- Insert varied test matches
INSERT INTO matches (team_id, match_date, location, title, status, max_players)
VALUES
  ('team-id-1', '2025-01-11 18:00:00', 'Nador Stadium', 'FC Nador vs AS Berkane', 'open', 22),
  ('team-id-2', '2025-01-12 20:00:00', 'Casablanca Arena', 'Raja vs Wydad Derby', 'open', 22),
  ('team-id-3', '2025-01-13 16:00:00', 'Rabat Sports Complex', 'FUS Rabat vs FAR', 'open', 22);
```

## Recommended Action

1. **Immediate**: Clean the database using Option 1
2. **Long-term**: Add validation to prevent duplicate match creation
3. **Testing**: Use Option 3 to create better test data

## Prevention

Add unique constraint to prevent duplicates:

```sql
-- Add unique constraint (optional, may be too restrictive)
ALTER TABLE matches
ADD CONSTRAINT unique_match
UNIQUE (team_id, match_date, location);
```

Or add application-level validation before creating matches.
