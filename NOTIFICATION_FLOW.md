# Complete Notification Flow

## Overview
The app has a complete bidirectional notification system for team and match interactions.

## Notification Flows

### 🔵 Team Join Request Flow

```
Player (User B)                    Owner (User A)
     |                                  |
     |  1. Send Join Request            |
     |--------------------------------->|
     |                                  |
     |                    2. Receives Notification
     |                    "New Join Request"
     |                    "User B wants to join Team X"
     |                                  |
     |                    3. Accept/Reject
     |                                  |
     |  4. Receives Notification        |
     |  "Join Request Approved/Rejected"|
     |<---------------------------------|
     |                                  |
```

**Notification Types:**
- `team_join_request` → Sent to team owner when request is created
- `team_join_approved` → Sent to player when request is accepted
- `team_join_rejected` → Sent to player when request is rejected

### ⚽ Match Join Flow

```
Player (User B)                    Creator (User A)
     |                                  |
     |  1. Join Match                   |
     |--------------------------------->|
     |                                  |
     |                    2. Receives Notification
     |                    "New Player Joined"
     |                    "User B joined your match"
     |                                  |
```

**Notification Types:**
- `match_joined` → Sent to match creator when someone joins

## Implementation Status

| Feature | Status | File |
|---------|--------|------|
| Team owner receives join request notification | ✅ Implemented | `api_service.dart:1637-1647` |
| Player receives approval notification | ✅ Implemented | `api_service.dart:1719-1726` |
| Player receives rejection notification | ✅ Implemented | `api_service.dart:1727-1732` |
| Match creator receives join notification | ✅ Implemented | `api_service.dart:1336-1343` |
| Notifications screen displays all types | ✅ Implemented | `notifications_screen.dart` |
| Database constraint allows all types | ⚠️ **Needs Migration** | `20250113000000_add_notification_types.sql` |

## How to Enable

Run the database migration:
```bash
supabase db push
```

This updates the `notifications` table constraint to allow all notification types.

## Notification Details

### Icons & Colors
- **Team Join Request** (purple) - `Icons.group_add`
- **Team Join Approved** (blue) - `Icons.check_circle`
- **Team Join Rejected** (red) - `Icons.cancel`
- **Match Joined** (green) - `Icons.person_add`

### Navigation
Tapping any notification navigates to:
- Team notifications → Team details page
- Match notifications → Match details page

### Read Status
- Unread notifications show a blue dot indicator
- Tapping marks as read automatically
- Bold text for unread, normal text for read

## User Experience

### For Team Owners
1. Receive instant notification when someone wants to join
2. Tap notification to go to team management
3. Accept or reject from team management screen

### For Players
1. Send join request from team details
2. Receive notification when owner responds
3. Tap notification to see team details

### For Match Creators
1. Receive notification when players join
2. Tap to see match details and participants

## Database Schema

```sql
CREATE TABLE notifications (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN (
    'team_join_request',    -- Owner receives when request sent
    'team_join_approved',   -- Player receives when accepted
    'team_join_rejected',   -- Player receives when rejected
    'match_joined',         -- Creator receives when player joins
    'match_created',
    'match_left',
    'match_reminder',
    'match_invite',
    'team_invite',
    'general',
    'system',
    'system_notification'
  )),
  related_id UUID,          -- Team ID or Match ID
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW()
);
```

## Testing Checklist

- [ ] Apply migration: `supabase db push`
- [ ] Test team join request (owner receives notification)
- [ ] Test team join approval (player receives notification)
- [ ] Test team join rejection (player receives notification)
- [ ] Test match join (creator receives notification)
- [ ] Verify notifications appear in Notifications screen
- [ ] Verify tapping navigates to correct page
- [ ] Verify read/unread status works
- [ ] Verify notification icons and colors are correct
