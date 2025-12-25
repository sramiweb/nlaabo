import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/api_service.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/team_repository.dart';
import '../repositories/match_repository.dart';
import '../services/team_service.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/localization_provider.dart';
import '../providers/home_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/team_provider.dart';
import '../providers/match_provider.dart';

List<SingleChildWidget> getAppProviders() {
  final supabase = Supabase.instance.client;

  return [
    // Repositories
    Provider<AuthRepository>(create: (_) => AuthRepository(supabase)),
    Provider<UserRepository>(create: (_) => UserRepository(supabase)),
    Provider<TeamRepository>(create: (_) => TeamRepository(supabase)),
    Provider<MatchRepository>(create: (_) => MatchRepository(supabase)),

    // Services
    Provider<ApiService>(
      create: (context) => ApiService(
        authRepository: context.read<AuthRepository>(),
        userRepository: context.read<UserRepository>(),
        teamRepository: context.read<TeamRepository>(),
        matchRepository: context.read<MatchRepository>(),
      ),
    ),
    Provider<TeamService>(
        create: (context) => TeamService(context.read<TeamRepository>())),

    // Providers
    ChangeNotifierProvider(
        create: (context) =>
            AuthProvider(apiService: context.read<ApiService>())),
    ChangeNotifierProvider(create: (_) {
      final provider = ThemeProvider();
      provider.loadThemePreference();
      return provider;
    }),
    ChangeNotifierProvider(create: (_) => LocalizationProvider()),
    ChangeNotifierProvider(
        create: (context) =>
            HomeProvider(apiService: context.read<ApiService>())),
    ChangeNotifierProvider(
        create: (context) => NotificationProvider(
            context.read<UserRepository>(), context.read<ApiService>())),
    ChangeNotifierProvider(
        create: (context) => TeamProvider(
            context.read<TeamRepository>(), context.read<ApiService>())),
    ChangeNotifierProvider(
        create: (context) => MatchProvider(
            context.read<MatchRepository>(), context.read<ApiService>())),
  ];
}
