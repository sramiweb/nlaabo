import 'package:flutter/material.dart';
import '../models/match.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../constants/translation_keys.dart';

class MatchRequestsScreen extends StatefulWidget {
  const MatchRequestsScreen({super.key});

  @override
  State<MatchRequestsScreen> createState() => _MatchRequestsScreenState();
}

class _MatchRequestsScreenState extends State<MatchRequestsScreen> {
  final ApiService _apiService = ApiService();
  List<Match> _pendingRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingRequests();
  }

  Future<void> _loadPendingRequests() async {
    setState(() => _isLoading = true);
    try {
      final requests = await _apiService.getMyPendingMatchRequests();
      setState(() {
        _pendingRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocalizationService().translate(TranslationKeys.errorLoadingRequests))),
        );
      }
    }
  }

  Future<void> _handleAccept(Match match) async {
    try {
      await _apiService.acceptMatchRequest(match.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match request accepted!')),
        );
        _loadPendingRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocalizationService().translate(TranslationKeys.errorAcceptingRequest))),
        );
      }
    }
  }

  Future<void> _handleReject(Match match) async {
    try {
      await _apiService.rejectMatchRequest(match.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match request declined')),
        );
        _loadPendingRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocalizationService().translate(TranslationKeys.errorRejectingRequest))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Requests'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingRequests.isEmpty
              ? const Center(child: Text('No pending match requests'))
              : ListView.builder(
                  itemCount: _pendingRequests.length,
                  itemBuilder: (context, index) {
                    final match = _pendingRequests[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text('Match vs ${match.team1Name ?? "Unknown Team"}'),
                        subtitle: Text(
                          'Date: ${match.matchDate.toLocal()}\nLocation: ${match.location}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () => _handleAccept(match),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => _handleReject(match),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}