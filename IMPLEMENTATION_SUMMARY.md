# Team & Match Logic Implementation Summary

## ✅ What Was Implemented

### 1. Team Ownership Constraints
- ✅ Users can create maximum **2 teams**
- ✅ Automatic ownership assignment on team creation
- ✅ Database trigger enforces the limit
- ✅ Clear error message when limit exceeded

### 2. Match Creation Constraints
- ✅ Users can create only **1 active match** at a time
- ✅ Users must have a team to create matches
- ✅ Team 1 automatically set to creator's team
- ✅ Database trigger enforces the limit

### 3. Match Request System
- ✅ Matches created with 'pending' status
- ✅ Team 2 owner receives notification
- ✅ Team 2 owner can accept/reject requests
- ✅ Status changes to 'confirmed' on acceptance
- ✅ Status changes to 'cancelled' on rejection
- ✅ Automatic notifications for all actions

## 📁 Files Created/Modified

### New Files
1. `supabase/migrations/20250115000000_team_match_constraints.sql` - Database migration
2. `TEAM_MATCH_LOGIC_IMPLEMENTATION.md` - Complete implementation guide
3. `IMPLEMENTATION_SUMMARY.md` - This file

### Modified Files
1. `lib/models/match.dart` - Added pending/confirmed status support
2. `lib/services/match_service.dart` - Added match request methods
3. `lib/services/api_service.dart` - Added API endpoints for match requests
4. `lib/repositories/match_repository.dart` - Added repository methods

## 🚀 How to Deploy

### Step 1: Run Database Migration
```bash
cd supabase
supabase db push
```

This will:
- Add team ownership limit (max 2 teams)
- Add match creation limit (1 active match)
- Add match request system
- Add notification triggers
- Update match status constraints

### Step 2: Verify Migration
```sql
-- Check triggers
SELECT tgname FROM pg_trigger 
WHERE tgname IN ('enforce_team_ownership_limit', 'enforce_match_creation_limit', 'send_match_request_notification');

-- Check notification types
SELECT DISTINCT type FROM notifications;
```

### Step 3: Test Constraints
1. Try creating 3 teams (should fail on 3rd)
2. Try creating 2 matches (should fail on 2nd)
3. Create a match and verify notification sent
4. Accept/reject match request

## 📱 UI Implementation Needed

### 1. Create Match Screen Updates
```dart
// Add team ownership check
if (userTeams.isEmpty) {
  showError('Create a team first to organize matches');
  return;
}

// Add active match check
if (hasActiveMatch) {
  showError('You already have an active match. Complete or cancel it first.');
  return;
}

// Auto-select Team 1
final team1 = userTeams.first; // or let user choose from their teams

// Show Team 2 selector (other teams only)
final team2 = await showTeamPicker(excludeTeams: [team1.id]);

// Create match request
await matchService.createMatch(
  team1Id: team1.id,
  team2Id: team2.id,
  matchDate: selectedDate,
  location: location,
);

showSuccess('Match request sent!');
```

### 2. Match Requests Screen (New)
Create a new screen to show pending match requests:

```dart
class MatchRequestsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Match Requests')),
      body: FutureBuilder<List<Match>>(
        future: matchService.getPendingMatchRequests(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();
          
          final requests = snapshot.data!;
          if (requests.isEmpty) {
            return Center(child: Text('No pending requests'));
          }
          
          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final match = requests[index];
              return MatchRequestCard(
                match: match,
                onAccept: () => _acceptRequest(match.id),
                onReject: () => _rejectRequest(match.id),
              );
            },
          );
        },
      ),
    );
  }
  
  Future<void> _acceptRequest(String matchId) async {
    await matchService.acceptMatchRequest(matchId);
    // Refresh list
  }
  
  Future<void> _rejectRequest(String matchId) async {
    await matchService.rejectMatchRequest(matchId);
    // Refresh list
  }
}
```

### 3. Create Team Screen Updates
```dart
// Check team limit before showing form
final myTeams = await teamService.getMyTeams();
if (myTeams.length >= 2) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Team Limit Reached'),
      content: Text('You can only own 2 teams. Delete a team to create a new one.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('OK'),
        ),
      ],
    ),
  );
  return;
}

// Show create team form
```

### 4. Notifications Screen Updates
Add handlers for new notification types:
- `match_request` - Navigate to match requests screen
- `match_accepted` - Navigate to match details
- `match_rejected` - Show rejection message

## 🔔 Notification Flow

### When Match Request Created
1. Team 1 owner creates match
2. System creates match with status='pending'
3. System sends notification to Team 2 owner
4. Team 2 owner sees notification badge

### When Match Request Accepted
1. Team 2 owner clicks "Accept"
2. Match status changes to 'confirmed'
3. System sends notification to Team 1 owner
4. Both teams can now see the match in their schedule

### When Match Request Rejected
1. Team 2 owner clicks "Reject"
2. Match status changes to 'cancelled'
3. System sends notification to Team 1 owner
4. Team 1 owner can create a new match request

## 🧪 Testing Scenarios

### Scenario 1: Team Creation Limit
1. User creates Team A ✅
2. User creates Team B ✅
3. User tries to create Team C ❌ Error: "User can own maximum 2 teams"

### Scenario 2: Match Creation Limit
1. User creates Match 1 ✅ (status='pending')
2. User tries to create Match 2 ❌ Error: "User can create only one active match at a time"
3. Match 1 is accepted (status='confirmed')
4. User tries to create Match 2 ❌ Still blocked (Match 1 is active)
5. Match 1 is completed (status='completed')
6. User creates Match 2 ✅ Now allowed

### Scenario 3: Match Request Flow
1. User A creates match request (Team A vs Team B)
2. Match created with status='pending' ✅
3. User B (Team B owner) receives notification ✅
4. User B views match request ✅
5. User B accepts request ✅
6. Match status changes to 'confirmed' ✅
7. User A receives acceptance notification ✅
8. Both users see match in their schedule ✅

### Scenario 4: Match Request Rejection
1. User A creates match request (Team A vs Team B)
2. User B receives notification ✅
3. User B rejects request ✅
4. Match status changes to 'cancelled' ✅
5. User A receives rejection notification ✅
6. User A can create new match request ✅

## 📊 Database Schema Changes

### New Columns
```sql
-- matches table
created_by UUID REFERENCES users(id)  -- Track who created the match
status TEXT DEFAULT 'pending'          -- pending, confirmed, open, closed, completed, cancelled
team2_confirmed BOOLEAN DEFAULT false  -- Track if team2 accepted
```

### New Triggers
```sql
-- Enforce team ownership limit (max 2 teams)
CREATE TRIGGER enforce_team_ownership_limit
  BEFORE INSERT ON teams
  FOR EACH ROW
  EXECUTE FUNCTION check_team_ownership_limit();

-- Enforce match creation limit (1 active match)
CREATE TRIGGER enforce_match_creation_limit
  BEFORE INSERT ON matches
  FOR EACH ROW
  EXECUTE FUNCTION check_match_creation_limit();

-- Send notification on match request
CREATE TRIGGER send_match_request_notification
  AFTER INSERT ON matches
  FOR EACH ROW
  EXECUTE FUNCTION notify_match_request();
```

### New Notification Types
- `match_request` - Match request created
- `match_accepted` - Match request accepted
- `match_rejected` - Match request rejected

## 🎯 Business Logic Summary

### Team Rules
1. User can own **maximum 2 teams**
2. User automatically becomes **owner** when creating team
3. Team owner can **manage members** and **delete team**
4. Team name must be **unique**

### Match Rules
1. User must **have a team** to create matches
2. User can create **only 1 active match** at a time
3. **Team 1** is automatically set to creator's team
4. **Team 2** must be a different team
5. Match requires **approval** from Team 2 owner

### Match Status Flow
```
pending → confirmed → open → in_progress → completed
   ↓
cancelled (if rejected)
```

## 🔐 Security Considerations

### RLS Policies
- ✅ Team owners can update their teams
- ✅ Match creators can update pending matches
- ✅ Team 2 owners can accept/reject requests
- ✅ Users can only see their own notifications

### Validation
- ✅ Team name uniqueness enforced
- ✅ Match date must be in future
- ✅ Team 1 ≠ Team 2
- ✅ User authentication required for all operations

## 📝 Next Steps

1. **Run Migration**: Execute the database migration
2. **Update UI**: Implement the UI changes described above
3. **Test**: Run through all testing scenarios
4. **Deploy**: Deploy to production after testing
5. **Monitor**: Watch for any constraint violations in logs

## 🆘 Troubleshooting

### Error: "User can own maximum 2 teams"
- **Cause**: User trying to create 3rd team
- **Solution**: Delete an existing team first

### Error: "User can create only one active match at a time"
- **Cause**: User already has an active match
- **Solution**: Complete or cancel existing match first

### Match request not received
- **Check**: Notification trigger is active
- **Check**: Team 2 owner ID is correct
- **Check**: Notifications table has entry

### Cannot accept match request
- **Check**: User is Team 2 owner
- **Check**: Match status is 'pending'
- **Check**: RLS policies allow update

## 📚 Additional Resources

- [TEAM_MATCH_LOGIC_IMPLEMENTATION.md](./TEAM_MATCH_LOGIC_IMPLEMENTATION.md) - Detailed implementation guide
- [Database Migration](./supabase/migrations/20250115000000_team_match_constraints.sql) - SQL migration file
- [Supabase Documentation](https://supabase.com/docs) - Official docs

## ✨ Summary

This implementation adds robust constraints to prevent abuse while maintaining a smooth user experience:

- **Team Limit**: Prevents users from creating unlimited teams
- **Match Limit**: Ensures users focus on one match at a time
- **Request System**: Requires mutual agreement before matches are official
- **Notifications**: Keeps all parties informed of match status

All constraints are enforced at the database level for maximum security and reliability.
