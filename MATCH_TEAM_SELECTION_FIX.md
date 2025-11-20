# Match Team Selection - Smart Filtering

## Feature
When creating a match, Team 2 dropdown now shows only compatible teams based on:
1. **Same player count** as Team 1
2. **No scheduling conflict** at the selected match time

## Implementation

### API Methods Added (`lib/services/api_service.dart`)

#### 1. Get Team Member Counts
```dart
Future<Map<String, int>> getTeamMemberCounts(List<String> teamIds)
```
Returns a map of team IDs to their member counts.

#### 2. Check Team Availability
```dart
Future<bool> isTeamAvailableAtTime(String teamId, DateTime matchTime)
```
Checks if a team has no match scheduled within ±2 hours of the specified time.

### UI Changes (`lib/screens/create_match_screen.dart`)

#### State Added
- `Map<String, int> _teamMemberCounts` - Stores member count for each team

#### Method Added
```dart
Future<List<Team>> _getAvailableTeamsForTeam2()
```
Filters teams based on:
- Same member count as Team 1
- Available at selected match time
- Not the same as Team 1

#### Team 2 Dropdown
- Uses `FutureBuilder` to dynamically load available teams
- Shows member count next to team name: "Team Name (5)"
- Automatically filters when Team 1 or date/time changes

## User Experience

### Before
- Could select any two teams regardless of player count
- Could create matches with scheduling conflicts
- No indication of team sizes

### After
1. Select Team 1 → Shows all teams
2. Select Team 2 → Shows only teams with:
   - ✅ Same number of players as Team 1
   - ✅ No match at the selected time
   - ✅ Member count displayed: "Team A (5)"
3. Change date/time → Team 2 list updates automatically
4. Change Team 1 → Team 2 list updates automatically

## Example Scenarios

### Scenario 1: Player Count Matching
```
Team A: 5 members
Team B: 5 members ✅ (shown)
Team C: 7 members ❌ (hidden)
Team D: 5 members ✅ (shown)
```

### Scenario 2: Time Conflict
```
Match Time: Saturday 3:00 PM

Team A: Available ✅ (shown)
Team B: Has match at 2:00 PM ❌ (hidden - within 2 hour buffer)
Team C: Has match at 6:00 PM ✅ (shown - outside buffer)
```

### Scenario 3: Combined Filtering
```
Team 1 Selected: Team A (5 members)
Match Time: Saturday 3:00 PM

Available for Team 2:
- Team B (5 members, no conflict) ✅
- Team C (5 members, no conflict) ✅

Not Available:
- Team D (7 members) ❌ Different player count
- Team E (5 members, match at 2:30 PM) ❌ Time conflict
```

## Technical Details

### Time Conflict Detection
- Checks ±2 hours from match time
- Prevents back-to-back matches
- Allows reasonable travel/rest time

### Performance
- Member counts loaded once when screen opens
- Availability checked dynamically when filtering
- Uses FutureBuilder for smooth UI updates

## Files Modified
1. `lib/services/api_service.dart` - Added 2 new methods
2. `lib/screens/create_match_screen.dart` - Updated team selection logic

## Testing

Test these scenarios:
- [ ] Select Team 1 with 5 members → Team 2 shows only teams with 5 members
- [ ] Select Team 1 with 7 members → Team 2 shows only teams with 7 members
- [ ] Change match time → Team 2 list updates to exclude conflicting teams
- [ ] Team with match at 2:00 PM not shown for 3:00 PM match
- [ ] Team with match at 6:00 PM shown for 3:00 PM match
- [ ] Member counts display correctly next to team names
- [ ] Cannot select same team for both Team 1 and Team 2
