# Gender & Age Filtering Implementation

## Overview
Teams and matches are filtered by gender and age to ensure fair play and appropriate matchups.

## Business Rules

### Gender Filtering
- **Male teams**: Only visible to male users
- **Female teams**: Only visible to female users  
- **Mixed teams**: Visible to all users

### Age Filtering
- Teams can set age ranges (e.g., 18-25, 30-40)
- Users see teams matching their age
- No age restriction if not set

## Database Changes

### New Fields in `teams` table
```sql
gender TEXT DEFAULT 'mixed' CHECK (gender IN ('male', 'female', 'mixed'))
min_age INTEGER
max_age INTEGER
```

### Constraints
- Age range: 13-100 years
- min_age must be ≤ max_age
- Both min_age and max_age must be set together or both null

## Usage

### Create Team with Gender/Age
```dart
await teamService.createTeam(
  name: 'Team Name',
  location: 'City',
  gender: 'male',      // 'male', 'female', or 'mixed'
  minAge: 18,          // Optional
  maxAge: 30,          // Optional
);
```

### Filtering Logic
```dart
// Teams are automatically filtered based on:
// 1. User's gender (if set)
// 2. User's age (if team has age range)

final teams = await teamService.getAllTeams();
// Returns only teams user can see
```

## UI Implementation

### Create Team Form
```dart
// Gender selector
DropdownButtonFormField<String>(
  value: _gender,
  items: [
    DropdownMenuItem(value: 'mixed', child: Text('Mixed')),
    DropdownMenuItem(value: 'male', child: Text('Male')),
    DropdownMenuItem(value: 'female', child: Text('Female')),
  ],
  onChanged: (value) => setState(() => _gender = value),
);

// Age range (optional)
Row(
  children: [
    Expanded(
      child: TextFormField(
        decoration: InputDecoration(labelText: 'Min Age'),
        keyboardType: TextInputType.number,
        onChanged: (value) => _minAge = int.tryParse(value),
      ),
    ),
    SizedBox(width: 16),
    Expanded(
      child: TextFormField(
        decoration: InputDecoration(labelText: 'Max Age'),
        keyboardType: TextInputType.number,
        onChanged: (value) => _maxAge = int.tryParse(value),
      ),
    ),
  ],
)
```

## Migration

Run the migration:
```bash
supabase db push
```

This will:
- Add gender and age fields to teams
- Set existing teams to 'mixed'
- Create filtering functions
- Add indexes for performance

## Examples

### Male-only team (18-25)
```dart
Team(
  name: 'Young Lions',
  gender: 'male',
  minAge: 18,
  maxAge: 25,
)
// Only visible to males aged 18-25
```

### Female-only team (no age limit)
```dart
Team(
  name: 'Lady Warriors',
  gender: 'female',
  minAge: null,
  maxAge: null,
)
// Visible to all females
```

### Mixed team (30+)
```dart
Team(
  name: 'Veterans United',
  gender: 'mixed',
  minAge: 30,
  maxAge: 100,
)
// Visible to all users aged 30+
```

## Testing

1. Create male team → Only males see it
2. Create female team → Only females see it
3. Create mixed team → Everyone sees it
4. Set age range → Only matching ages see it
5. No age range → All ages see it
