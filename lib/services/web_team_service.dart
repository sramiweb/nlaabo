import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/team.dart';

class WebTeamService {
  static Future<Team> createTeamWeb({
    required String name,
    String? location,
    int? numberOfPlayers,
    String? description,
    bool? isRecruiting,
    String? gender,
    int? minAge,
    int? maxAge,
  }) async {
    // Allow usage on any platform but optimize for web
    // Remove strict web-only restriction to allow cross-platform usage

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    
    if (user == null) {
      throw Exception('No authenticated user');
    }

    // Force session refresh for web
    try {
      await supabase.auth.refreshSession();
      debugPrint('Web session refreshed successfully');
    } catch (e) {
      debugPrint('Session refresh failed: $e');
      throw Exception('Session expired. Please refresh the page and try again.');
    }

    // Verify session is still valid
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('Authentication lost. Please refresh the page and login again.');
    }

    final teamData = {
      'name': name,
      'owner_id': currentUser.id,
      'location': location,
      'description': description,
      'max_players': numberOfPlayers ?? 11,
      'is_recruiting': isRecruiting ?? false,
      'gender': gender ?? 'mixed',
      'min_age': minAge,
      'max_age': maxAge,
    };

    try {
      final response = await supabase
          .from('teams')
          .insert(teamData)
          .select()
          .single();

      final team = Team.fromJson(response);

      // Wait for database trigger to add owner as team member
      await Future.delayed(const Duration(milliseconds: 300));

      return team;
    } catch (e) {
      debugPrint('Web team creation error: $e');
      if (e.toString().contains('JWT') || e.toString().contains('expired')) {
        throw Exception('Session expired. Please refresh the page and try again.');
      }
      rethrow;
    }
  }
}
