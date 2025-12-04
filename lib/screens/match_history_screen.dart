import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/match.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../widgets/directional_icon.dart';

class MatchHistoryScreen extends StatefulWidget {
  const MatchHistoryScreen({super.key});

  @override
  State<MatchHistoryScreen> createState() => _MatchHistoryScreenState();
}

class _MatchHistoryScreenState extends State<MatchHistoryScreen> {
  final ApiService _apiService = ApiService();
  List<Match> _matches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() => _isLoading = true);
    try {
      final matches = await _apiService.getMyMatches();
      if (mounted) {
        setState(() {
          _matches = matches.where((m) => m.matchDate.isBefore(DateTime.now())).toList();
          _matches.sort((a, b) => b.matchDate.compareTo(a.matchDate));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load matches: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationService().translate('match_history')),
        leading: IconButton(
          icon: const DirectionalIcon(icon: Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _matches.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(LocalizationService().translate('no_match_history'), style: Theme.of(context).textTheme.titleLarge),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMatches,
                  child: ListView.builder(
                    itemCount: _matches.length,
                    itemBuilder: (context, index) {
                      final match = _matches[index];
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          title: Text('${match.team1Name ?? "Team 1"} vs ${match.team2Name ?? "Team 2"}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Date: ${match.matchDate.toLocal().toString().split('.')[0]}'),
                              Text('Location: ${match.location}'),
                              Text('Status: ${match.status}'),
                            ],
                          ),
                          onTap: () => context.push('/match/${match.id}'),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
