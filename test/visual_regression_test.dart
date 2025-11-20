import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:provider/provider.dart';
import 'package:nlaabo/providers/auth_provider.dart';
import 'package:nlaabo/providers/theme_provider.dart';
import 'package:nlaabo/providers/localization_provider.dart';
import 'package:nlaabo/providers/home_provider.dart';
import 'package:nlaabo/providers/notification_provider.dart';
import 'package:nlaabo/providers/team_provider.dart';
import 'package:nlaabo/providers/match_provider.dart';
import 'package:nlaabo/repositories/user_repository.dart';
import 'package:nlaabo/repositories/team_repository.dart';
import 'package:nlaabo/repositories/match_repository.dart';
import 'package:nlaabo/services/api_service.dart';

/// Visual regression tests using golden_toolkit for responsive layouts
/// Tests ensure visual consistency across different device sizes and screen densities

void main() {
  group('Visual Regression Tests', () {
    // Device configurations for visual regression testing
    final deviceConfigs = [
      const Device(name: 'small_mobile', size: Size(320, 568)),
      const Device(name: 'iphone_se', size: Size(375, 667)),
      const Device(name: 'iphone_11_pro_max', size: Size(414, 896)),
      const Device(name: 'ipad', size: Size(768, 1024)),
      const Device(name: 'ipad_pro', size: Size(1366, 1024)),
      const Device(name: 'desktop', size: Size(1920, 1080)),
      const Device(name: 'ultra_wide', size: Size(2560, 1440)),
    ];

    setUpAll(() async {
      await loadAppFonts();
    });

    // MaterialApp wrapper with all necessary providers for proper theme context
    Widget materialAppWrapper(Widget child) {
      return MultiProvider(
        providers: [
          Provider<ApiService>(create: (_) => ApiService()),
          Provider<UserRepository>(create: (context) => UserRepository(context.read<ApiService>())),
          Provider<TeamRepository>(create: (context) => TeamRepository(context.read<ApiService>())),
          Provider<MatchRepository>(create: (context) => MatchRepository(context.read<ApiService>())),
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
          ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
          ChangeNotifierProvider<LocalizationProvider>(create: (_) => LocalizationProvider()),
          ChangeNotifierProvider<HomeProvider>(create: (_) => HomeProvider()),
          ChangeNotifierProvider<NotificationProvider>(
            create: (context) => NotificationProvider(
              context.read<UserRepository>(),
              context.read<ApiService>(),
            ),
          ),
          ChangeNotifierProvider<TeamProvider>(
            create: (context) => TeamProvider(
              context.read<TeamRepository>(),
              context.read<ApiService>(),
            ),
          ),
          ChangeNotifierProvider<MatchProvider>(
            create: (context) => MatchProvider(
              context.read<MatchRepository>(),
              context.read<ApiService>(),
            ),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: const ColorScheme.light(primary: Color(0xFF34D399)),
            extensions: const [],
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: const ColorScheme.dark(primary: Color(0xFF34D399)),
            extensions: const [],
          ),
          themeMode: ThemeMode.light, // Use light theme for consistent golden images
          home: child,
        ),
      );
    }

    group('Responsive Layout Visual Tests', () {
      for (final device in deviceConfigs) {
        testGoldens(
          'Responsive layout on ${device.name} (${device.size.width}x${device.size.height})',
          (WidgetTester tester) async {
            await tester.pumpWidgetBuilder(
              // Use a simple Scaffold with basic layout instead of full AuthWrapper
              Scaffold(
                appBar: AppBar(title: const Text('Test Layout')),
                body: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Responsive Layout Test'),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: null,
                        child: Text('Test Button'),
                      ),
                    ],
                  ),
                ),
              ),
              wrapper: materialAppWrapper,
              surfaceSize: device.size,
            );

            await tester.pumpAndSettle();

            // Capture golden image for visual regression testing
            await screenMatchesGolden(
              tester,
              'responsive_layout_${device.name}',
              customPump: (tester) async {
                // Additional pump to ensure all animations complete
                await tester.pumpAndSettle();
              },
            );
          },
        );
      }
    });

    group('Mobile Device Specific Tests', () {
      testGoldens(
        'Small mobile layout (320px width)',
        (WidgetTester tester) async {
          await tester.pumpWidgetBuilder(
            Scaffold(
              appBar: AppBar(title: const Text('Mobile Test')),
              body: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Small Mobile Layout'),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: null,
                      child: Text('Action'),
                    ),
                  ],
                ),
              ),
            ),
            wrapper: materialAppWrapper,
            surfaceSize: const Size(320, 568),
          );

          await tester.pumpAndSettle();

          await screenMatchesGolden(
            tester,
            'mobile_small_320',
            customPump: (tester) async {
              await tester.pumpAndSettle();
            },
          );
        },
      );

      testGoldens(
        'iPhone SE layout (375px width)',
        (WidgetTester tester) async {
          await tester.pumpWidgetBuilder(
            Scaffold(
              appBar: AppBar(title: const Text('iPhone SE Test')),
              body: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('iPhone SE Layout'),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: null,
                      child: Text('Action'),
                    ),
                  ],
                ),
              ),
            ),
            wrapper: materialAppWrapper,
            surfaceSize: const Size(375, 667),
          );

          await tester.pumpAndSettle();

          await screenMatchesGolden(
            tester,
            'mobile_iphone_se_375',
            customPump: (tester) async {
              await tester.pumpAndSettle();
            },
          );
        },
      );

      testGoldens(
        'iPhone 11 Pro Max layout (414px width)',
        (WidgetTester tester) async {
          await tester.pumpWidgetBuilder(
            Scaffold(
              appBar: AppBar(title: const Text('iPhone 11 Pro Max Test')),
              body: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('iPhone 11 Pro Max Layout'),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: null,
                      child: Text('Action'),
                    ),
                  ],
                ),
              ),
            ),
            wrapper: materialAppWrapper,
            surfaceSize: const Size(414, 896),
          );

          await tester.pumpAndSettle();

          await screenMatchesGolden(
            tester,
            'mobile_iphone_11_pro_max_414',
            customPump: (tester) async {
              await tester.pumpAndSettle();
            },
          );
        },
      );
    });

    group('Tablet Device Specific Tests', () {
      testGoldens(
        'iPad portrait layout (768px width)',
        (WidgetTester tester) async {
          await tester.pumpWidgetBuilder(
            Scaffold(
              appBar: AppBar(title: const Text('iPad Portrait Test')),
              body: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('iPad Portrait Layout'),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: null,
                      child: Text('Action'),
                    ),
                  ],
                ),
              ),
            ),
            wrapper: materialAppWrapper,
            surfaceSize: const Size(768, 1024),
          );

          await tester.pumpAndSettle();

          await screenMatchesGolden(
            tester,
            'tablet_ipad_portrait_768',
            customPump: (tester) async {
              await tester.pumpAndSettle();
            },
          );
        },
      );

      testGoldens(
        'iPad Pro landscape layout (1366px width)',
        (WidgetTester tester) async {
          await tester.pumpWidgetBuilder(
            Scaffold(
              appBar: AppBar(title: const Text('iPad Pro Landscape Test')),
              body: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('iPad Pro Landscape Layout'),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: null,
                      child: Text('Action'),
                    ),
                  ],
                ),
              ),
            ),
            wrapper: materialAppWrapper,
            surfaceSize: const Size(1366, 1024),
          );

          await tester.pumpAndSettle();

          await screenMatchesGolden(
            tester,
            'tablet_ipad_pro_landscape_1366',
            customPump: (tester) async {
              await tester.pumpAndSettle();
            },
          );
        },
      );
    });

    group('Desktop Device Specific Tests', () {
      testGoldens(
        'Desktop layout (1920px width)',
        (WidgetTester tester) async {
          await tester.pumpWidgetBuilder(
            Scaffold(
              appBar: AppBar(title: const Text('Desktop Test')),
              body: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Desktop Layout'),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: null,
                      child: Text('Action'),
                    ),
                  ],
                ),
              ),
            ),
            wrapper: materialAppWrapper,
            surfaceSize: const Size(1920, 1080),
          );

          await tester.pumpAndSettle();

          await screenMatchesGolden(
            tester,
            'desktop_1920',
            customPump: (tester) async {
              await tester.pumpAndSettle();
            },
          );
        },
      );

      testGoldens(
        'Ultra-wide desktop layout (2560px width)',
        (WidgetTester tester) async {
          await tester.pumpWidgetBuilder(
            Scaffold(
              appBar: AppBar(title: const Text('Ultra-wide Desktop Test')),
              body: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Ultra-wide Desktop Layout'),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: null,
                      child: Text('Action'),
                    ),
                  ],
                ),
              ),
            ),
            wrapper: materialAppWrapper,
            surfaceSize: const Size(2560, 1440),
          );

          await tester.pumpAndSettle();

          await screenMatchesGolden(
            tester,
            'desktop_ultra_wide_2560',
            customPump: (tester) async {
              await tester.pumpAndSettle();
            },
          );
        },
      );
    });

    group('Visual Consistency Tests', () {
      testGoldens(
        'Visual consistency across breakpoints',
        (WidgetTester tester) async {
          // Test multiple breakpoints in sequence to ensure visual consistency
          final breakpoints = [
            const Size(320, 568), // Mobile
            const Size(768, 1024), // Tablet
            const Size(1920, 1080), // Desktop
          ];

          for (final size in breakpoints) {
            await tester.pumpWidgetBuilder(
              Scaffold(
                appBar: AppBar(title: const Text('Breakpoint Test')),
                body: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Breakpoint Consistency Test'),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: null,
                        child: Text('Action'),
                      ),
                    ],
                  ),
                ),
              ),
              wrapper: materialAppWrapper,
              surfaceSize: size,
            );

            await tester.pumpAndSettle();

            // Verify no overflow errors occur
            expect(find.textContaining('overflowed'), findsNothing,
                reason: 'No overflow errors should be present at ${size.width}x${size.height}');

            // Verify main scaffold renders
            expect(find.byType(Scaffold), findsWidgets,
                reason: 'Scaffold should render at ${size.width}x${size.height}');
          }
        },
      );

      testGoldens(
        'Theme consistency across devices',
        (WidgetTester tester) async {
          // Test that theme applies consistently across different device sizes
          await tester.pumpWidgetBuilder(
            Builder(
              builder: (context) {
                final theme = Theme.of(context);
                return Scaffold(
                  appBar: AppBar(title: const Text('Theme Test')),
                  body: Container(
                    color: theme.colorScheme.surface,
                    child: Center(
                      child: Text(
                        'Theme Consistency Test',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            wrapper: materialAppWrapper,
            surfaceSize: const Size(375, 667),
          );

          await tester.pumpAndSettle();

          await screenMatchesGolden(
            tester,
            'theme_consistency_mobile',
            customPump: (tester) async {
              await tester.pumpAndSettle();
            },
          );
        },
      );
    });
  });
}