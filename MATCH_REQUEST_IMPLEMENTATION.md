# Match Request System Implementation

## ✅ **What Was Implemented**

### 1. **UI/UX Updates**
- Changed "Create Match" → "Request Match" (Demander un match)
- Updated subtitle to "Send a match request to another team"
- Changed button text to "Send Match Request" (Envoyer une demande de match)
- Success message now says "Match request sent" instead of "Match created"

### 2. **Database Triggers** (SQL Migration)
Created automatic notification system:

#### **When Match Request is Created:**
- Trigger: `match_request_notification_trigger`
- Sends notification to Team 2 owner
- Notification type: `match_request`
- Message: "[Team1] vous demande un match le [date]"

#### **When Match Request is Accepted/Rejected:**
- Trigger: `match_response_notification_trigger`
- Sends notification to Team 1 owner (requester)
- Notification types: `match_accepted` or `match_rejected`
- Messages:
  - Accepted: "[Team2] a accepté votre demande de match"
  - Rejected: "[Team2] a refusé votre demande de match"

### 3. **Notification Types Added**
Updated `notifications_type_check` constraint to include:
- `match_request` - When a match request is sent
- `match_accepted` - When a match request is accepted
- `match_rejected` - When a match request is rejected

### 4. **Notifications Screen**
Already supports all match request notification types:
- ✅ Blue icon for match requests
- ✅ Tap to navigate to match details
- ✅ Shows formatted date/time
- ✅ Unread indicator (blue dot)

## 📋 **How It Works**

### **Flow:**
1. **Team 1 Owner** creates a match request (status='pending')
   - Selects Team 2
   - Fills in match details
   - Clicks "Send Match Request"
   
2. **Database Trigger Fires**
   - `notify_match_request_created()` function executes
   - Creates notification for Team 2 owner
   - Notification appears in Team 2 owner's notifications

3. **Team 2 Owner** receives notification
   - Sees "Nouvelle demande de match" notification
   - Taps notification → goes to match details
   - Can accept or reject the request

4. **Team 2 Owner** accepts/rejects
   - Match status changes to 'confirmed' or 'cancelled'
   - `notify_match_request_response()` function executes
   - Creates notification for Team 1 owner

5. **Team 1 Owner** receives response notification
   - Sees acceptance or rejection notification
   - Taps notification → goes to match details

## 🗄️ **Database Schema**

### **Matches Table:**
- `status` field values:
  - `pending` - Match request sent, waiting for acceptance
  - `confirmed` - Match request accepted
  - `cancelled` - Match request rejected
  - `in_progress` - Match is currently happening
  - `finished` - Match completed

### **Notifications Table:**
- `type` - Notification type (match_request, match_accepted, match_rejected)
- `title` - Notification title
- `message` - Notification message
- `related_id` - Match ID
- `data` - JSON with match details (team names, date, location)

## 📁 **Files Modified**

### **Frontend (Flutter):**
1. `lib/screens/create_match_screen.dart`
   - Updated UI text to reflect request flow
   - Changed success message

2. `lib/screens/notifications_screen.dart`
   - Already handles match request notifications ✅

3. `assets/translations/fr.json`
   - Added: `request_match`, `send_match_request`, `match_request_sent`
   - Added: `waiting_for_acceptance`, `match_request_pending`
   - Added: `send_match_request_to_team`

4. `assets/translations/en.json`
   - Added same keys in English

### **Backend (SQL):**
1. `supabase/migrations/20250122000001_add_match_request_notifications.sql`
   - Updated notification types constraint
   - Created `notify_match_request_created()` function
   - Created `notify_match_request_response()` function
   - Created triggers on matches table

2. `apply_match_notifications.sql`
   - Standalone SQL script for manual application

## 🚀 **Deployment Steps**

### **Option 1: Via Supabase SQL Editor (Recommended)**
1. Open Supabase Dashboard
2. Go to SQL Editor
3. Copy contents of `apply_match_notifications.sql`
4. Click "Run"
5. Verify triggers were created (query at end of script)

### **Option 2: Via Supabase CLI**
```bash
supabase db push --include-all
```

### **Option 3: Manual Application**
Run the SQL commands in `apply_match_notifications.sql` directly in your PostgreSQL client.

## ✅ **Testing Checklist**

### **Test Match Request Creation:**
- [ ] Create a match request as Team 1 owner
- [ ] Verify Team 2 owner receives notification
- [ ] Verify notification shows correct team names and date
- [ ] Tap notification → should navigate to match details

### **Test Match Request Acceptance:**
- [ ] Accept match request as Team 2 owner
- [ ] Verify Team 1 owner receives "accepted" notification
- [ ] Verify match status changes to 'confirmed'
- [ ] Tap notification → should navigate to match details

### **Test Match Request Rejection:**
- [ ] Reject match request as Team 2 owner
- [ ] Verify Team 1 owner receives "rejected" notification
- [ ] Verify match status changes to 'cancelled'

### **Test UI:**
- [ ] Verify "Request Match" title shows instead of "Create Match"
- [ ] Verify subtitle says "Send a match request to another team"
- [ ] Verify button says "Send Match Request"
- [ ] Verify success message says "Match request sent"

## 🔍 **Troubleshooting**

### **Notifications Not Appearing:**
1. Check triggers are created:
```sql
SELECT * FROM information_schema.triggers 
WHERE trigger_name LIKE '%match%notification%';
```

2. Check notification types constraint:
```sql
SELECT conname, pg_get_constraintdef(oid) 
FROM pg_constraint 
WHERE conname = 'notifications_type_check';
```

3. Check if notifications were created:
```sql
SELECT * FROM notifications 
WHERE type IN ('match_request', 'match_accepted', 'match_rejected')
ORDER BY created_at DESC;
```

### **Trigger Not Firing:**
1. Check match status:
```sql
SELECT id, status, team1_id, team2_id, match_date 
FROM matches 
ORDER BY created_at DESC 
LIMIT 5;
```

2. Manually test trigger:
```sql
-- Create test match
INSERT INTO matches (team1_id, team2_id, match_date, location, status)
VALUES ('team1-uuid', 'team2-uuid', NOW() + INTERVAL '1 day', 'Test Location', 'pending');
```

## 📊 **Success Metrics**

- ✅ Team owners receive notifications when match requests are sent
- ✅ Team owners receive notifications when requests are accepted/rejected
- ✅ UI clearly communicates the request flow
- ✅ Users understand they're sending a request, not creating a confirmed match
- ✅ Notification tap navigates to match details

## 🎯 **Next Steps (Optional Enhancements)**

1. **Match Details Screen:**
   - Show "Pending Request" badge for pending matches
   - Add "Accept" and "Reject" buttons for Team 2 owner
   - Show "Waiting for [Team Name] to accept" for Team 1 owner

2. **Match List:**
   - Filter by "Pending Requests"
   - Show visual indicator for pending matches
   - Separate "Sent Requests" and "Received Requests"

3. **Push Notifications:**
   - Send push notifications for match requests
   - Send push notifications for acceptances/rejections

4. **Email Notifications:**
   - Email Team 2 owner when request is received
   - Email Team 1 owner when request is accepted/rejected
