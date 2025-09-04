import 'package:flutter/material.dart';
import 'package:lets_build_planner/theme.dart';
import 'package:lets_build_planner/screens/auth_page.dart';
import 'package:lets_build_planner/screens/home_page.dart';
import 'package:lets_build_planner/screens/shared_view_page.dart';
import 'package:lets_build_planner/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Supabase with error handling
    await SupabaseConfig.initialize();
  } catch (e) {
    debugPrint('Error initializing Supabase: $e');
    // Continue running the app even if Supabase fails to initialize
    // The app will work in offline/demo mode
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Content Planner',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
      routes: {
        '/auth': (context) => const AuthPage(),
        '/home': (context) => const HomePage(),
      },
      onGenerateRoute: (settings) {
        // Handle shared view routes like /shared/{userId}
        if (settings.name != null && settings.name!.startsWith('/shared/')) {
          final userId = settings.name!.substring('/shared/'.length);
          return MaterialPageRoute(
            builder: (context) => SharedViewPage(userId: userId),
          );
        }
        return null;
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    _checkAuthState();
  }

  void _initDeepLinks() async {
    try {
      _appLinks = AppLinks();

      // Check if app was launched from a deep link
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }

      // Listen for incoming deep links while app is running
      _linkSubscription = _appLinks.uriLinkStream.listen(
        _handleDeepLink,
        onError: (err) {
          debugPrint('Deep link error: $err');
        },
      );
    } catch (e) {
      debugPrint('Error initializing deep links: $e');
      // Continue without deep links if initialization fails
    }
  }

  void _handleDeepLink(Uri uri) async {
    debugPrint('Received deep link: $uri');
    
    // Handle Supabase auth callback
    if (uri.scheme == 'io.supabase.letsplan' && uri.host == 'login-callback') {
      final success = await SupabaseAuth.handleDeepLink(uri.toString());
      if (success) {
        debugPrint('Successfully handled Supabase auth deep link');
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email confirmed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        debugPrint('Failed to handle Supabase auth deep link');
      }
    }
  }

  void _checkAuthState() {
    try {
      SupabaseAuth.authStateChanges.listen((AuthState state) {
        if (mounted) {
          setState(() {});
        }
      });
    } catch (e) {
      debugPrint('Error setting up auth state listener: $e');
      // Continue without auth state monitoring if it fails
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Always start with HomePage - authentication is handled within the page
    return const HomePage();
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();

    // Navigate to AuthWrapper after delay
    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: SizedBox(
                height: 200,
                width: 150,
                child: Image.network(
                  "https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/open-router-library-ry2ta7/assets/1vva4juqfxr3/v0-vert.png",
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.calendar_month,
                      size: 120,
                      color: Theme.of(context).colorScheme.primary,
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
