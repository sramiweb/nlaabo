import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../widgets/directional_icon.dart';

class TeamMembersManagementScreen extends StatefulWidget {
  final String teamId;

  const TeamMembersManagementScreen({super.key, required this.teamId});

  @override
  State<TeamMembersManagementScreen> createState() => _TeamMembersManagementScreenState();
}

class _TeamMembersManagementScreenState extends State<TeamMembersManagementScreen> {
  final ApiService _apiService = ApiService();
  List<User> _members = [];
  bool _isLoading = true;
  final Map<String, bool> _removingIds = {};

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    try {
      final members = await _apiService.getTeamMembers(widget.teamId);
      if (mounted) {
        setState(() {
          _members = members;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load members: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _removeMember(User member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Remove ${member.name} from the team?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _removingIds[member.id] = true);
    try {
      await _apiService.removeTeamMember(widget.teamId, member.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member removed'), backgroundColor: Colors.green),
        );
        _loadMembers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove member: $e'), backgroundColor: Colors.red),
        );
        setState(() => _removingIds[member.id] = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Members'),
        leading: IconButton(
          icon: const DirectionalIcon(icon: Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _members.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No members yet', style: Theme.of(context).textTheme.titleLarge),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMembers,
                  child: ListView.builder(
                    itemCount: _members.length,
                    itemBuilder: (context, index) {
                      final member = _members[index];
                      final isRemoving = _removingIds[member.id] ?? false;
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: member.imageUrl != null ? NetworkImage(member.imageUrl!) : null,
                          child: member.imageUrl == null ? Text(member.name[0]) : null,
                        ),
                        title: Text(member.name),
                        subtitle: Text(member.email),
                        trailing: isRemoving
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                            : IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeMember(member),
                              ),
                      );
                    },
                  ),
                ),
    );
  }
}
