import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth_landing_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/create_match_screen.dart';
import '../screens/create_team_screen.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/match_details_screen.dart';
import '../screens/teams_screen.dart';
import '../screens/team_details_screen.dart';
import '../screens/team_management_screen.dart';
import '../screens/matches_screen.dart';
import '../screens/auth_callback_screen.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/forgot_password_confirmation_screen.dart';
import '../screens/reset_password_screen.dart';
import '../screens/my_matches_screen.dart';
import '../screens/match_requests_screen.dart';
import '../screens/team_members_management_screen.dart';
import '../screens/match_history_screen.dart';
import '../screens/advanced_search_screen.dart';
import '../screens/onboarding_screen.dart';
import '../widgets/main_layout.dart';
import '../widgets/directional_icon.dart';
import '../widgets/animations.dart';
import '../services/onboarding_service.dart';

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
      final publicRoutes = [
        '/auth',
        '/auth-callback',
        '/login',
        '/signup',
        '/forgot-password',
        '/forgot-password-confirmation',
        '/reset-password',
        '/onboarding'
      ];

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
      builder: (context, state) =>
          const MainLayout(child: MatchRequestsScreen()),
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
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
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
      builder: (context, state) =>
          const MainLayout(child: MatchHistoryScreen()),
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
      builder: (context, state) =>
          const MainLayout(child: AdvancedSearchScreen()),
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
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
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
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
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
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
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
      path.startsWith('/teams/') ||
      path.startsWith('/team/');
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
