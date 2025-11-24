import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nlaabo/providers/auth_provider.dart';
import 'package:nlaabo/providers/theme_provider.dart';
import 'package:nlaabo/providers/home_provider.dart';
import 'package:nlaabo/providers/notification_provider.dart';
import 'package:nlaabo/providers/team_provider.dart';
import 'package:nlaabo/providers/match_provider.dart';
import 'package:nlaabo/providers/localization_provider.dart';
import 'package:nlaabo/repositories/user_repository.dart';
import 'package:nlaabo/repositories/team_repository.dart';
import 'package:nlaabo/repositories/match_repository.dart';
import 'package:nlaabo/services/api_service.dart';
import 'package:nlaabo/services/team_service.dart';
import 'package:nlaabo/screens/auth_landing_screen.dart';
import 'package:nlaabo/screens/home_screen.dart';
import 'package:nlaabo/screens/profile_screen.dart';
import 'package:nlaabo/screens/edit_profile_screen.dart';
import 'package:nlaabo/screens/create_match_screen.dart';
import 'package:nlaabo/screens/create_team_screen.dart';
import 'package:nlaabo/screens/admin_dashboard_screen.dart';
import 'package:nlaabo/screens/settings_screen.dart';
import 'package:nlaabo/screens/notifications_screen.dart';
import 'package:nlaabo/screens/match_details_screen.dart';
import 'package:nlaabo/screens/teams_screen.dart';
import 'package:nlaabo/screens/team_details_screen.dart';
import 'package:nlaabo/screens/team_management_screen.dart';
import 'package:nlaabo/screens/matches_screen.dart';
import 'package:nlaabo/screens/auth_callback_screen.dart';
import 'package:nlaabo/screens/login_screen.dart';
import 'package:nlaabo/screens/signup_screen.dart';
import 'package:nlaabo/screens/forgot_password_screen.dart';
import 'package:nlaabo/screens/forgot_password_confirmation_screen.dart';
import 'package:nlaabo/screens/reset_password_screen.dart';
import 'package:nlaabo/screens/my_matches_screen.dart';
import 'package:nlaabo/screens/match_requests_screen.dart';
import 'package:nlaabo/screens/team_members_management_screen.dart';
import 'package:nlaabo/screens/match_history_screen.dart';
import 'package:nlaabo/screens/advanced_search_screen.dart';
import 'package:nlaabo/screens/onboarding_screen.dart';
import 'package:nlaabo/services/onboarding_service.dart';
import 'package:nlaabo/widgets/main_layout.dart';
import 'package:nlaabo/widgets/smart_error_boundary.dart';
import 'package:nlaabo/widgets/directional_icon.dart';
import 'package:nlaabo/widgets/animations.dart';
import 'package:nlaabo/services/error_reporting_service.dart';
import 'package:nlaabo/services/robust_supabase_client.dart';
import 'package:nlaabo/services/connectivity_service.dart';
import 'package:nlaabo/services/secure_credential_service.dart';
import 'package:nlaabo/utils/app_initialization_utils.dart';
import 'package:nlaabo/config/app_config.dart';
import 'package:nlaabo/config/build_config.dart';
import 'package:nlaabo/config/web_config.dart';

enum AppInitializationError {
  configurationMissing,
  configurationInvalid,
  networkUnavailable,
  supabaseUnreachable,
  unknown,
}

final GoRouter router = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: false,
  restorationScopeId: 'app_router',
  redirect: (context, state) {
    // Check if AuthProvider is available in the context
    AuthProvider? authProvider;
    try {
      authProvider = Provider.of<AuthProvider>(context, listen: false);
    } catch (e) {
      // Provider not available yet during app initialization
      return null; // No redirect until providers are ready
    }

    try {
      // Public routes that don't require authentication
      final publicRoutes = ['/auth', '/auth-callback', '/login', '/signup', '/forgot-password', '/forgot-password-confirmation', '/reset-password', '/onboarding'];

      // Get the current location
      final currentLocation = state.uri.path;
  
      // Validate route exists
      if (currentLocation != '/' && !_isValidRoute(currentLocation)) {
        return '/';
      }
  
      // If user is not authenticated and trying to access protected route
      if (!authProvider.isAuthenticated &&
          !publicRoutes.contains(currentLocation) &&
          currentLocation != '/') {
        return '/auth';
      }

      // If user is authenticated and trying to access auth routes, redirect to home
      if (authProvider.isAuthenticated &&
          publicRoutes.contains(currentLocation) &&
          currentLocation != '/onboarding') {
        return '/home';
      }

      // Admin route protection
      if (currentLocation == '/admin' && authProvider.user?.role != 'admin') {
        return '/home';
      }

      return null; // No redirect needed
    } catch (e) {
      // Fallback - no redirect on errors to prevent loops
      debugPrint('Router redirect error: $e');
      return null;
    }
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const AuthWrapper()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const OnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return PageTransitions.fadeTransition(
            context: context,
            animation: animation,
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthLandingScreen(),
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AuthLandingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return PageTransitions.fadeTransition(
            context: context,
            animation: animation,
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/auth-callback',
      builder: (context, state) => const AuthCallbackScreen(),
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AuthCallbackScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return PageTransitions.fadeTransition(
            context: context,
            animation: animation,
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return PageTransitions.slideFadeTransition(
            context: context,
            animation: animation,
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SignupScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return PageTransitions.slideFadeTransition(
            context: context,
            animation: animation,
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const ForgotPasswordScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return PageTransitions.slideFadeTransition(
            context: context,
            animation: animation,
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/forgot-password-confirmation',
      builder: (context, state) {
        final email = state.extra as String? ?? '';
        return ForgotPasswordConfirmationScreen(email: email);
      },
      pageBuilder: (context, state) {
        final email = state.extra as String? ?? '';
        return CustomTransitionPage(
          key: state.pageKey,
          child: ForgotPasswordConfirmationScreen(email: email),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return PageTransitions.slideFadeTransition(
              context: context,
              animation: animation,
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) => const ResetPasswordScreen(),
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const ResetPasswordScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return PageTransitions.slideFadeTransition(
            context: context,
            animation: animation,
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const MainLayout(child: HomeScreen()),
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const MainLayout(child: HomeScreen()),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return PageTransitions.slideFadeTransition(
            context: context,
            animation: animation,
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const MainLayout(child: ProfileScreen()),
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const MainLayout(child: ProfileScreen()),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return PageTransitions.slideFadeTransition(
            context: context,
            animation: animation,
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) => const MainLayout(child: EditProfileScreen()),
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const MainLayout(child: EditProfileScreen()),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return PageTransitions.slideFadeTransition(
            context: context,
            animation: animation,
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/create-match',
      builder: (context, state) => MainLayout(
        child: CreateMatchScreen(
          preselectedTeam1Id: state.uri.queryParameters['team1'],
        ),
      ),
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: MainLayout(
          child: CreateMatchScreen(
            preselectedTeam1Id: state.uri.queryParameters['team1'],
          ),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return PageTransitions.slideFadeTransition(
            context: context,
            animation: animation,
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/create-team',
      builder: (context, state) => const MainLayout(child: CreateTeamScreen()),
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const MainLayout(child: CreateTeamScreen()),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return PageTransitions.slideFadeTransition(
            context: context,
            animation: animation,
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/teams',
      builder: (context, state) => const MainLayout(child: TeamsScreen()),
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const MainLayout(child: TeamsScreen()),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return PageTransitions.slideFadeTransition(
            context: context,
            animation: animation,
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/matches',
      builder: (context, state) => const MainLayout(child: MatchesScreen()),
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const MainLayout(child: MatchesScreen()),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return PageTransitions.slideFadeTransition(
            context: context,
            animation: animation,
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/my-matches',
      builder: (context, state) => const MainLayout(child: MyMatchesScreen()),
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const MainLayout(child: MyMatchesScreen()),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return PageTransitions.slideFadeTransition(
            context: context,
            animation: animation,
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) =>
          const MainLayout(child: AdminDashboardScreen()),
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const MainLayout(child: AdminDashboardScreen()),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return PageTransitions.slideFadeTransition(
            context: context,
            animation: animation,
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const MainLayout(child: SettingsScreen()),
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const MainLayout(child: SettingsScreen()),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return PageTransitions.slideFadeTransition(
            context: context,
            animation: animation,
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) =>
          const MainLayout(child: NotificationsScreen()),
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const MainLayout(child: NotificationsScreen()),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return PageTransitions.slideFadeTransition(
            context: context,
            animation: animation,
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/match-requests',
      builder: (context, state) => const MainLayout(child: MatchRequestsScreen()),
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const MainLayout(child: MatchRequestsScreen()),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return PageTransitions.slideFadeTransition(
            context: context,
            animation: animation,
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/team/:id/members',
      builder: (context, state) {
        final teamId = state.pathParameters['id'];
        if (teamId == null || teamId.isEmpty) {
          return MainLayout(
            child: Scaffold(
              body: const Center(child: Text('Invalid team ID')),
              floatingActionButton: FloatingActionButton(
                onPressed: () => context.go('/teams'),
                child: const DirectionalIcon(icon: Icons.arrow_back),
              ),
            ),
          );
        }
        return MainLayout(child: TeamMembersManagementScreen(teamId: teamId));
      },
      pageBuilder: (context, state) {
        final teamId = state.pathParameters['id'];
        if (teamId == null || teamId.isEmpty) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: MainLayout(
              child: Scaffold(
                body: const Center(child: Text('Invalid team ID')),
                floatingActionButton: FloatingActionButton(
                  onPressed: () => context.go('/teams'),
                  child: const DirectionalIcon(icon: Icons.arrow_back),
                ),
              ),
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return PageTransitions.slideFadeTransition(
                context: context,
                animation: animation,
                child: child,
              );
            },
          );
        }
        return CustomTransitionPage(
          key: state.pageKey,
          child: MainLayout(child: TeamMembersManagementScreen(teamId: teamId)),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return PageTransitions.slideFadeTransition(
              context: context,
              animation: animation,
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/match-history',
      builder: (context, state) => const MainLayout(child: MatchHistoryScreen()),
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const MainLayout(child: MatchHistoryScreen()),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return PageTransitions.slideFadeTransition(
            context: context,
            animation: animation,
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const MainLayout(child: AdvancedSearchScreen()),
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const MainLayout(child: AdvancedSearchScreen()),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return PageTransitions.slideFadeTransition(
            context: context,
            animation: animation,
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/match/:id',
      builder: (context, state) {
        final matchId = state.pathParameters['id'];
        if (matchId == null || matchId.isEmpty) {
          return MainLayout(
            child: Scaffold(
              body: const Center(child: Text('Invalid match ID')),
              floatingActionButton: FloatingActionButton(
                onPressed: () => context.go('/home'),
                child: const Icon(Icons.home),
              ),
            ),
          );
        }
        return MainLayout(child: MatchDetailsScreen(matchId: matchId));
      },
      pageBuilder: (context, state) {
        final matchId = state.pathParameters['id'];
        if (matchId == null || matchId.isEmpty) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: MainLayout(
              child: Scaffold(
                body: const Center(child: Text('Invalid match ID')),
                floatingActionButton: FloatingActionButton(
                  onPressed: () => context.go('/home'),
                  child: const Icon(Icons.home),
                ),
              ),
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return PageTransitions.slideFadeTransition(
                context: context,
                animation: animation,
                child: child,
              );
            },
          );
        }
        return CustomTransitionPage(
          key: state.pageKey,
          child: MainLayout(child: MatchDetailsScreen(matchId: matchId)),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return PageTransitions.slideFadeTransition(
              context: context,
              animation: animation,
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/teams/:id',
      builder: (context, state) {
        final teamId = state.pathParameters['id'];
        if (teamId == null || teamId.isEmpty) {
          return MainLayout(
            child: Scaffold(
              body: const Center(child: Text('Invalid team ID')),
              floatingActionButton: FloatingActionButton(
                onPressed: () => context.go('/teams'),
                child: const DirectionalIcon(icon: Icons.arrow_back),
              ),
            ),
          );
        }
        return MainLayout(child: TeamDetailsScreen(teamId: teamId));
      },
      pageBuilder: (context, state) {
        final teamId = state.pathParameters['id'];
        if (teamId == null || teamId.isEmpty) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: MainLayout(
              child: Scaffold(
                body: const Center(child: Text('Invalid team ID')),
                floatingActionButton: FloatingActionButton(
                  onPressed: () => context.go('/teams'),
                  child: const DirectionalIcon(icon: Icons.arrow_back),
                ),
              ),
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return PageTransitions.slideFadeTransition(
                context: context,
                animation: animation,
                child: child,
              );
            },
          );
        }
        return CustomTransitionPage(
          key: state.pageKey,
          child: MainLayout(child: TeamDetailsScreen(teamId: teamId)),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return PageTransitions.slideFadeTransition(
              context: context,
              animation: animation,
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/teams/:id/manage',
      builder: (context, state) {
        final teamId = state.pathParameters['id'];
        if (teamId == null || teamId.isEmpty) {
          return MainLayout(
            child: Scaffold(
              body: const Center(child: Text('Invalid team ID')),
              floatingActionButton: FloatingActionButton(
                onPressed: () => context.go('/teams'),
                child: const DirectionalIcon(icon: Icons.arrow_back),
              ),
            ),
          );
        }
        return MainLayout(child: TeamManagementScreen(teamId: teamId));
      },
      pageBuilder: (context, state) {
        final teamId = state.pathParameters['id'];
        if (teamId == null || teamId.isEmpty) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: MainLayout(
              child: Scaffold(
                body: const Center(child: Text('Invalid team ID')),
                floatingActionButton: FloatingActionButton(
                  onPressed: () => context.go('/teams'),
                  child: const DirectionalIcon(icon: Icons.arrow_back),
                ),
              ),
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return PageTransitions.slideFadeTransition(
                context: context,
                animation: animation,
                child: child,
              );
            },
          );
        }
        return CustomTransitionPage(
          key: state.pageKey,
          child: MainLayout(child: TeamManagementScreen(teamId: teamId)),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return PageTransitions.slideFadeTransition(
              context: context,
              animation: animation,
              child: child,
            );
          },
        );
      },
    ),
  ],
);

// Helper function to validate routes
bool _isValidRoute(String path) {
 const validRoutes = [
   '/',
   '/onboarding',
   '/auth',
   '/auth-callback',
   '/login',
   '/signup',
   '/forgot-password',
   '/forgot-password-confirmation',
   '/reset-password',
   '/home',
   '/profile',
   '/edit-profile',
   '/create-match',
   '/create-team',
   '/teams',
   '/matches',
   '/my-matches',
   '/admin',
   '/settings',
   '/notifications',
   '/match-requests',
   '/match-history',
   '/search'
 ];
 return validRoutes.contains(path) ||
        path.startsWith('/match/') ||
        path.startsWith('/teams/');
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isCheckingOnboarding = true;
  bool _hasSeenOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    try {
      final hasSeenOnboarding = await OnboardingService.hasSeenOnboarding();
      if (mounted) {
        setState(() {
          _hasSeenOnboarding = hasSeenOnboarding;
          _isCheckingOnboarding = false;
        });
      }
    } catch (e) {
      // If SharedPreferences fails, assume onboarding hasn't been seen
      debugPrint('Error checking onboarding status: $e');
      if (mounted) {
        setState(() {
          _hasSeenOnboarding = false;
          _isCheckingOnboarding = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingOnboarding) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    try {
      final authProvider = context.watch<AuthProvider>();

      if (authProvider.isLoading) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      if (authProvider.isAuthenticated) {
        return const MainLayout(child: HomeScreen());
      } else {
        // Show onboarding for first-time users
        if (!_hasSeenOnboarding) {
          return const OnboardingScreen();
        }
        return const AuthLandingScreen();
      }
    } catch (e) {
      // Handle provider errors gracefully
      debugPrint('AuthWrapper error: $e');
      return const AuthLandingScreen();
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NlaaboBootstrap());
}

class NlaaboBootstrap extends StatefulWidget {
  const NlaaboBootstrap({super.key});

  @override
  State<NlaaboBootstrap> createState() => _NlaaboBootstrapState();
}

class _NlaaboBootstrapState extends State<NlaaboBootstrap> {
  bool _isInitializing = true;
  AppInitializationError? _errorType;
  bool _canRetry = false;
  bool _showDiagnostics = false;
  bool _isRunningDiagnostics = false;
  String? _diagnosticsResult;
  bool _diagnosticsHasError = false;
  String? _diagnosticsErrorMessage;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    setState(() {
      _isInitializing = true;
      _errorType = null;
      _canRetry = false;
      _showDiagnostics = false;
      _diagnosticsResult = null;
      _diagnosticsHasError = false;
      _diagnosticsErrorMessage = null;
    });

    try {
      // Load .env file first with better error handling
      try {
        await dotenv.load(fileName: '.env');
        debugPrint('Successfully loaded .env file');
      } catch (e) {
        debugPrint('Failed to load .env file: $e');
        throw Exception('Failed to load .env file: $e');
      }

      // Check if credentials are initialized in secure storage
      final credentialsInitialized = await SecureCredentialService.areCredentialsInitialized();

      if (!credentialsInitialized) {
        // Initialize with credentials from .env
        final url = dotenv.env['SUPABASE_URL'];
        final key = dotenv.env['SUPABASE_ANON_KEY'];

        if (url != null && url.isNotEmpty && key != null && key.isNotEmpty) {
          await SecureCredentialService.initializeCredentials(
            supabaseUrl: url,
            supabaseAnonKey: key,
          );
          debugPrint('Initialized credentials from .env to secure storage');
        } else {
          throw Exception('No credentials found in .env file. SUPABASE_URL and SUPABASE_ANON_KEY must be set.');
        }
      }

      // Validate credentials in secure storage
      final validationResult = await SecureCredentialService.validateCredentials();
      if (!validationResult.isValid) {
        throw Exception('Invalid Supabase credentials: ${validationResult.error}');
      }

      // Initialize AppConfig
      await AppConfig.initialize(environment: BuildConfig.environment);

      // Initialize web-specific configuration if running on web
      if (kIsWeb) {
        await WebConfig.initialize();
      }

      // Initialize error reporting service
      final errorReportingService = ErrorReportingService();
      await errorReportingService.initialize();

      // Initialize Supabase with robust client (consolidated)
      await RobustSupabaseClient.initialize();

      // Initialize localization service
      await AppInitializationUtils.loadInitialLanguage();

      // Success - show main app
      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      debugPrint('App initialization failed: $e');
      final errorMessage = e.toString();
      final errorType = _classifyError(errorMessage);

      setState(() {
        _isInitializing = false;
        _errorType = errorType;
        _canRetry = true;
      });
    }
  }

  AppInitializationError _classifyError(String errorMessage) {
    debugPrint('Classifying error: $errorMessage');

    if (errorMessage.contains('Failed to load .env file') || errorMessage.contains('FileNotFoundError')) {
      return AppInitializationError.configurationMissing;
    }
    if (errorMessage.contains('SUPABASE_URL') || errorMessage.contains('SUPABASE_ANON_KEY')) {
      return AppInitializationError.configurationMissing;
    }
    if (errorMessage.contains('Configuration') || errorMessage.contains('AppConfig') || errorMessage.contains('validation failed')) {
      return AppInitializationError.configurationInvalid;
    }
    if (errorMessage.contains('network') || errorMessage.contains('connection') || errorMessage.contains('internet')) {
      return AppInitializationError.networkUnavailable;
    }
    if (errorMessage.contains('Supabase') || errorMessage.contains('server')) {
      return AppInitializationError.supabaseUnreachable;
    }
    return AppInitializationError.unknown;
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isRunningDiagnostics = true;
      _diagnosticsResult = null;
      _diagnosticsHasError = false;
      _diagnosticsErrorMessage = null;
    });

    try {
      final result = await ConnectivityService.runDiagnostics();
      setState(() {
        _isRunningDiagnostics = false;
        _diagnosticsResult = result.details;
        _diagnosticsHasError = !result.success;
        _showDiagnostics = true;
      });
    } catch (e) {
      setState(() {
        _isRunningDiagnostics = false;
        _diagnosticsHasError = true;
        _diagnosticsErrorMessage = e.toString();
        _showDiagnostics = true;
      });
    }
  }

  Widget _getActionableFeedback(String result) {
    final suggestions = <String>[];

    if (result.contains('❌ SUPABASE_URL is empty')) {
      suggestions.add('• Check your .env file and ensure SUPABASE_URL is set');
    }
    if (result.contains('❌ SUPABASE_ANON_KEY is empty')) {
      suggestions.add('• Check your .env file and ensure SUPABASE_ANON_KEY is set');
    }
    if (result.contains('❌ No internet connection')) {
      suggestions.add('• Verify your internet connection and try again');
    }
    if (result.contains('❌ DNS resolution failed')) {
      suggestions.add('• Check DNS settings or try using a different network');
    }
    if (result.contains('❌ Supabase connection failed')) {
      suggestions.add('• Verify Supabase URL and API key are correct');
      suggestions.add('• Check if Supabase service is operational');
    }
    if (result.contains('✅') && !result.contains('❌')) {
      suggestions.add('• All checks passed! The issue may be temporary. Try restarting the app.');
    }

    if (suggestions.isEmpty) {
      suggestions.add('• Review the diagnostic results above for any warnings or errors.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: suggestions.map((s) => Text(s)).toList(),
    );
  }

  IconData _getErrorIcon(AppInitializationError errorType) {
    switch (errorType) {
      case AppInitializationError.configurationMissing:
      case AppInitializationError.configurationInvalid:
        return Icons.settings;
      case AppInitializationError.networkUnavailable:
        return Icons.wifi_off;
      case AppInitializationError.supabaseUnreachable:
        return Icons.cloud_off;
      case AppInitializationError.unknown:
        return Icons.error;
    }
  }

  Color _getErrorColor(AppInitializationError errorType) {
    switch (errorType) {
      case AppInitializationError.configurationMissing:
      case AppInitializationError.configurationInvalid:
        return Colors.red;
      case AppInitializationError.networkUnavailable:
        return Colors.orange;
      case AppInitializationError.supabaseUnreachable:
        return Colors.blue;
      case AppInitializationError.unknown:
        return Colors.grey;
    }
  }

  String _getErrorTitle(AppInitializationError errorType) {
    switch (errorType) {
      case AppInitializationError.configurationMissing:
        return 'Configuration Missing';
      case AppInitializationError.configurationInvalid:
        return 'Configuration Error';
      case AppInitializationError.networkUnavailable:
        return 'Network Unavailable';
      case AppInitializationError.supabaseUnreachable:
        return 'Server Unreachable';
      case AppInitializationError.unknown:
        return 'Initialization Error';
    }
  }

  String _getErrorMessage(AppInitializationError errorType) {
    switch (errorType) {
      case AppInitializationError.configurationMissing:
        return 'Required configuration is missing.\nPlease check your .env file exists and contains SUPABASE_URL and SUPABASE_ANON_KEY variables.';
      case AppInitializationError.configurationInvalid:
        return 'Configuration is invalid.\nPlease verify your settings and try again.';
      case AppInitializationError.networkUnavailable:
        return 'Network connection is unavailable.\nPlease check your internet connection and try again.';
      case AppInitializationError.supabaseUnreachable:
        return 'Cannot connect to Nlaabo servers.\nThe service may be temporarily unavailable.';
      case AppInitializationError.unknown:
        return 'An unexpected error occurred during initialization.\nPlease try again or contact support.';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Initializing Nlaabo...'),
              ],
            ),
          ),
        ),
      );
    }

    if (_errorType != null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getErrorIcon(_errorType!),
                      size: 64,
                      color: _getErrorColor(_errorType!),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _getErrorTitle(_errorType!),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getErrorMessage(_errorType!),
                      textAlign: TextAlign.center,
                    ),
                    if (kDebugMode) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Debug Info:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      Text(
                        'Error Type: ${_errorType.toString()}',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (_canRetry)
                      ElevatedButton(
                        onPressed: _initializeApp,
                        child: const Text('Retry'),
                      ),
                    const SizedBox(height: 8),
                    if (!_showDiagnostics)
                      TextButton(
                        onPressed: _runDiagnostics,
                        child: const Text('Show Details'),
                      )
                    else if (_isRunningDiagnostics)
                      const Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 8),
                          Text('Running diagnostics...'),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          const Text(
                            'Network Diagnostics:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          if (_diagnosticsHasError)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Diagnostics failed to run:',
                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(_diagnosticsErrorMessage ?? 'Unknown error'),
                                const SizedBox(height: 16),
                                const Text('Troubleshooting steps:'),
                                const Text('• Check your internet connection'),
                                const Text('• Verify .env file is properly configured'),
                                const Text('• Ensure Supabase credentials are valid'),
                              ],
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_diagnosticsResult ?? 'No results available'),
                                const SizedBox(height: 16),
                                const Text(
                                  'Actionable Feedback:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                _getActionableFeedback(_diagnosticsResult!),
                              ],
                            ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _showDiagnostics = false;
                              });
                            },
                            child: const Text('Hide Details'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Success - show main app
    return SmartErrorBoundary(
      enableReporting: true,
      enableAutoRecovery: true,
      context: 'NlaaboApp',
      child: MultiProvider(
        providers: [
          Provider<ApiService>(create: (_) => ApiService()),
          Provider<UserRepository>(create: (context) => UserRepository(context.read<ApiService>())),
          Provider<TeamRepository>(create: (context) => TeamRepository(context.read<ApiService>())),
          Provider<MatchRepository>(create: (context) => MatchRepository(context.read<ApiService>())),
          Provider<TeamService>(create: (context) => TeamService(context.read<TeamRepository>())),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) {
            final provider = ThemeProvider();
            // Load theme preference asynchronously after provider creation
            provider.loadThemePreference();
            return provider;
          }),
          ChangeNotifierProvider(create: (_) => LocalizationProvider()),
          ChangeNotifierProvider(create: (_) => HomeProvider()),
          ChangeNotifierProvider(create: (context) => NotificationProvider(context.read<UserRepository>(), context.read<ApiService>())),
          ChangeNotifierProvider(create: (context) => TeamProvider(context.read<TeamRepository>(), context.read<ApiService>())),
          ChangeNotifierProvider(create: (context) => MatchProvider(context.read<MatchRepository>(), context.read<ApiService>())),
        ],
        child: const NlaaboApp(),
      ),
    );
  }
}

class NlaaboApp extends StatelessWidget {
  const NlaaboApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localizationProvider = context.watch<LocalizationProvider>();

    return MaterialApp.router(
      key: ValueKey(localizationProvider.currentLanguage),
      title: 'Nlaabo',
      debugShowCheckedModeBanner: false,

      locale: localizationProvider.locale,
      supportedLocales: const [
        Locale('en'),
        Locale('fr'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(clampDouble(
              MediaQuery.of(context).textScaler.scale(1.0),
              0.8,
              1.2,
            )),
          ),
          child: Directionality(
            textDirection: localizationProvider.textDirection,
            child: child!,
          ),
        );
      },
      theme: context.watch<ThemeProvider>().themeData,
      darkTheme: context.watch<ThemeProvider>().themeData,
      themeMode: context.watch<ThemeProvider>().themeMode,
      routerConfig: router,
    );
  }
}

class ConnectivityDiagnosticsScreen extends StatefulWidget {
  const ConnectivityDiagnosticsScreen({super.key});

  @override
  State<ConnectivityDiagnosticsScreen> createState() => _ConnectivityDiagnosticsScreenState();
}

class _ConnectivityDiagnosticsScreenState extends State<ConnectivityDiagnosticsScreen> {
  bool _isLoading = true;
  String? _diagnosticsResult;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    try {
      final result = await ConnectivityService.runDiagnostics();
      setState(() {
        _isLoading = false;
        _diagnosticsResult = result.details;
        _hasError = !result.success;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Diagnostics'),
        leading: IconButton(
          icon: const DirectionalIcon(icon: Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Running diagnostics...'),
                  ],
                ),
              )
            : _hasError
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Diagnostics failed to run:',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(_errorMessage ?? 'Unknown error'),
                      const SizedBox(height: 16),
                      const Text('Troubleshooting steps:'),
                      const Text('• Check your internet connection'),
                      const Text('• Verify .env file is properly configured'),
                      const Text('• Ensure Supabase credentials are valid'),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_diagnosticsResult ?? 'No results available'),
                        const SizedBox(height: 16),
                        const Text(
                          'Actionable Feedback:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        _getActionableFeedback(_diagnosticsResult!),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _getActionableFeedback(String result) {
    final suggestions = <String>[];

    if (result.contains('❌ SUPABASE_URL is empty')) {
      suggestions.add('• Check your .env file and ensure SUPABASE_URL is set');
    }
    if (result.contains('❌ SUPABASE_ANON_KEY is empty')) {
      suggestions.add('• Check your .env file and ensure SUPABASE_ANON_KEY is set');
    }
    if (result.contains('❌ No internet connection')) {
      suggestions.add('• Verify your internet connection and try again');
    }
    if (result.contains('❌ DNS resolution failed')) {
      suggestions.add('• Check DNS settings or try using a different network');
    }
    if (result.contains('❌ Supabase connection failed')) {
      suggestions.add('• Verify Supabase URL and API key are correct');
      suggestions.add('• Check if Supabase service is operational');
    }
    if (result.contains('✅') && !result.contains('❌')) {
      suggestions.add('• All checks passed! The issue may be temporary. Try restarting the app.');
    }

    if (suggestions.isEmpty) {
      suggestions.add('• Review the diagnostic results above for any warnings or errors.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: suggestions.map((s) => Text(s)).toList(),
    );
  }
}
