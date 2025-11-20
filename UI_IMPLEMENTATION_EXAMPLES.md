# UI Implementation Examples

## 📱 Complete UI Code Examples

### 1. Create Match Screen (Updated)

```dart
import 'package:flutter/material.dart';
import '../services/match_service.dart';
import '../services/team_service.dart';
import '../models/team.dart';

class CreateMatchScreen extends StatefulWidget {
  @override
  _CreateMatchScreenState createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends State<CreateMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _matchService = MatchService(/* dependencies */);
  final _teamService = TeamService(/* dependencies */);
  
  List<Team> _myTeams = [];
  Team? _selectedTeam1;
  Team? _selectedTeam2;
  DateTime? _matchDate;
  String _location = '';
  bool _isLoading = false;
  bool _canCreateMatch = false;
  String? _blockReason;

  @override
  void initState() {
    super.initState();
    _checkEligibility();
  }

  Future<void> _checkEligibility() async {
    setState(() => _isLoading = true);
    
    try {
      // Check if user has teams
      _myTeams = await _teamService.getMyTeams();
      
      if (_myTeams.isEmpty) {
        setState(() {
          _canCreateMatch = false;
          _blockReason = 'You must create a team first to organize matches';
        });
        return;
      }
      
      // Check if user already has an active match
      final matches = await _matchService.getMatches();
      final userId = /* get current user id */;
      final hasActiveMatch = matches.any((m) => 
        m.createdBy == userId && 
        m.status != 'cancelled' && 
        m.status != 'completed'
      );
      
      if (hasActiveMatch) {
        setState(() {
          _canCreateMatch = false;
          _blockReason = 'You already have an active match. Complete or cancel it first.';
        });
        return;
      }
      
      // User can create match
      setState(() {
        _canCreateMatch = true;
        _selectedTeam1 = _myTeams.first; // Auto-select first team
      });
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking eligibility: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createMatch() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTeam1 == null || _selectedTeam2 == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      await _matchService.createMatch(
        team1Id: _selectedTeam1!.id,
        team2Id: _selectedTeam2!.id,
        matchDate: _matchDate!,
        location: _location,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Match request sent to ${_selectedTeam2!.name}!'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating match: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Create Match')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (!_canCreateMatch) {
      return Scaffold(
        appBar: AppBar(title: Text('Create Match')),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.block, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  _blockReason ?? 'Cannot create match',
                  style: TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                if (_myTeams.isEmpty)
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/create-team'),
                    child: Text('Create a Team'),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(title: Text('Create Match')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Team 1 (Your Team)
            Text('Your Team', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<Team>(
              value: _selectedTeam1,
              items: _myTeams.map((team) => DropdownMenuItem(
                value: team,
                child: Text(team.name),
              )).toList(),
              onChanged: (team) => setState(() => _selectedTeam1 = team),
              decoration: InputDecoration(
                hintText: 'Select your team',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            
            // Team 2 (Opponent)
            Text('Opponent Team', style: TextStyle(fontWeight: FontWeight.bold)),
            FutureBuilder<List<Team>>(
              future: _teamService.getAllTeams(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return CircularProgressIndicator();
                }
                
                // Exclude user's teams
                final availableTeams = snapshot.data!
                    .where((t) => !_myTeams.any((mt) => mt.id == t.id))
                    .toList();
                
                return DropdownButtonFormField<Team>(
                  value: _selectedTeam2,
                  items: availableTeams.map((team) => DropdownMenuItem(
                    value: team,
                    child: Text(team.name),
                  )).toList(),
                  onChanged: (team) => setState(() => _selectedTeam2 = team),
                  decoration: InputDecoration(
                    hintText: 'Select opponent team',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null) return 'Please select opponent team';
                    if (value.id == _selectedTeam1?.id) {
                      return 'Cannot play against your own team';
                    }
                    return null;
                  },
                );
              },
            ),
            SizedBox(height: 16),
            
            // Match Date
            Text('Match Date', style: TextStyle(fontWeight: FontWeight.bold)),
            ListTile(
              title: Text(_matchDate == null 
                ? 'Select date' 
                : _matchDate!.toString().split(' ')[0]
              ),
              trailing: Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(Duration(days: 7)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _matchDate = date);
                }
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey),
              ),
            ),
            SizedBox(height: 16),
            
            // Location
            Text('Location', style: TextStyle(fontWeight: FontWeight.bold)),
            TextFormField(
              decoration: InputDecoration(
                hintText: 'Enter match location',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter location';
                }
                return null;
              },
              onChanged: (value) => _location = value,
            ),
            SizedBox(height: 24),
            
            // Info Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Match Request',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your match request will be sent to ${_selectedTeam2?.name ?? "the opponent team"}. '
                      'They must accept before the match is confirmed.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            
            // Submit Button
            ElevatedButton(
              onPressed: _isLoading ? null : _createMatch,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Send Match Request',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 2. Match Requests Screen (New)

```dart
import 'package:flutter/material.dart';
import '../services/match_service.dart';
import '../models/match.dart';

class MatchRequestsScreen extends StatefulWidget {
  @override
  _MatchRequestsScreenState createState() => _MatchRequestsScreenState();
}

class _MatchRequestsScreenState extends State<MatchRequestsScreen> {
  final _matchService = MatchService(/* dependencies */);
  List<Match> _pendingRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    
    try {
      final requests = await _matchService.getPendingMatchRequests();
      setState(() {
        _pendingRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading requests: $e')),
      );
    }
  }

  Future<void> _acceptRequest(Match match) async {
    try {
      await _matchService.acceptMatchRequest(match.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Match accepted! ${match.team1Name} has been notified.'),
          backgroundColor: Colors.green,
        ),
      );
      
      _loadRequests(); // Refresh list
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accepting match: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectRequest(Match match) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject Match Request'),
        content: Text('Are you sure you want to reject this match request from ${match.team1Name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      await _matchService.rejectMatchRequest(match.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Match rejected. ${match.team1Name} has been notified.'),
        ),
      );
      
      _loadRequests(); // Refresh list
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting match: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Match Requests'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadRequests,
          ),
        ],
      ),
      body: _isLoading
        ? Center(child: CircularProgressIndicator())
        : _pendingRequests.isEmpty
          ? _buildEmptyState()
          : _buildRequestsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No pending match requests',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'When teams want to play with you,\ntheir requests will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList() {
    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _pendingRequests.length,
        itemBuilder: (context, index) {
          final match = _pendingRequests[index];
          return _buildRequestCard(match);
        },
      ),
    );
  }

  Widget _buildRequestCard(Match match) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.sports_soccer, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Match Request',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text('PENDING'),
                  backgroundColor: Colors.orange.shade100,
                  labelStyle: TextStyle(
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Divider(height: 24),
            
            // Teams
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        match.team1Name ?? 'Team 1',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                      Text('Challenger', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'VS',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        match.team2Name ?? 'Team 2',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                      Text('Your Team', style: TextStyle(color: Colors.blue)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Match Details
            _buildDetailRow(Icons.calendar_today, 'Date', match.formattedDate),
            SizedBox(height: 8),
            _buildDetailRow(Icons.location_on, 'Location', match.location),
            SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectRequest(match),
                    icon: Icon(Icons.close),
                    label: Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red),
                      padding: EdgeInsets.all(12),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _acceptRequest(match),
                    icon: Icon(Icons.check),
                    label: Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.all(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}
```

### 3. Create Team Screen (Updated)

```dart
import 'package:flutter/material.dart';
import '../services/team_service.dart';

class CreateTeamScreen extends StatefulWidget {
  @override
  _CreateTeamScreenState createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teamService = TeamService(/* dependencies */);
  
  String _teamName = '';
  String _location = '';
  int _numberOfPlayers = 11;
  bool _isLoading = false;
  bool _canCreateTeam = true;
  int _currentTeamCount = 0;

  @override
  void initState() {
    super.initState();
    _checkTeamLimit();
  }

  Future<void> _checkTeamLimit() async {
    try {
      final teams = await _teamService.getMyTeams();
      setState(() {
        _currentTeamCount = teams.length;
        _canCreateTeam = teams.length < 2;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking team limit: $e')),
      );
    }
  }

  Future<void> _createTeam() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      await _teamService.createTeam(
        name: _teamName,
        location: _location,
        numberOfPlayers: _numberOfPlayers,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Team created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating team: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_canCreateTeam) {
      return Scaffold(
        appBar: AppBar(title: Text('Create Team')),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.block, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Team Limit Reached',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'You can only own 2 teams maximum.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  'Current teams: $_currentTeamCount/2',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Team'),
        actions: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                'Teams: $_currentTeamCount/2',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Team Name
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Team Name',
                hintText: 'Enter team name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter team name';
                }
                if (value.length < 3) {
                  return 'Team name must be at least 3 characters';
                }
                return null;
              },
              onChanged: (value) => _teamName = value,
            ),
            SizedBox(height: 16),
            
            // Location
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Location',
                hintText: 'Enter team location',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter location';
                }
                return null;
              },
              onChanged: (value) => _location = value,
            ),
            SizedBox(height: 16),
            
            // Number of Players
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Number of Players',
                hintText: 'Enter number of players',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              initialValue: '11',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter number of players';
                }
                final number = int.tryParse(value);
                if (number == null || number < 1 || number > 50) {
                  return 'Number must be between 1 and 50';
                }
                return null;
              },
              onChanged: (value) {
                final number = int.tryParse(value);
                if (number != null) {
                  _numberOfPlayers = number;
                }
              },
            ),
            SizedBox(height: 24),
            
            // Info Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Team Ownership',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• You will automatically become the team owner\n'
                      '• You can create up to 2 teams\n'
                      '• You can manage team members and settings',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            
            // Submit Button
            ElevatedButton(
              onPressed: _isLoading ? null : _createTeam,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Create Team',
                      style: TextStyle(fontSize: 16),
                    ),
              ),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 4. Home Screen Badge (Match Requests)

```dart
// Add to your home screen navigation
ListTile(
  leading: Stack(
    children: [
      Icon(Icons.mail),
      if (_pendingRequestCount > 0)
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$_pendingRequestCount',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
    ],
  ),
  title: Text('Match Requests'),
  onTap: () => Navigator.pushNamed(context, '/match-requests'),
)
```

---

**UI Examples Version**: 1.0  
**Last Updated**: 2025-01-15  
**Note**: Adjust styling and dependencies according to your app's design system
