import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:nucleus/pages/homepage.dart';
import 'package:nucleus/pages/login_screen.dart';
import 'package:nucleus/pages/settings_page.dart';
import 'package:nucleus/pages/profile_page.dart';
import 'package:nucleus/pages/product_detail_page.dart';
import 'package:nucleus/pages/product_edit_page.dart';
import 'package:nucleus/pages/forgot_password_page.dart';
import 'package:nucleus/pages/welcome_page.dart';

import 'theme/app_theme.dart';
import 'firebase_options.dart';

// Global controller so tests can call MyApp() without passing one.
final _globalThemeController = ThemeController();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // You can pass a controller explicitly or rely on the global default.
  runApp(MyApp(controller: _globalThemeController));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, ThemeController? controller})
      : _controller = controller;

  // If null, we fall back to a shared global controller.
  final ThemeController? _controller;

  ThemeController get _resolvedController =>
      _controller ?? _globalThemeController;

  @override
  Widget build(BuildContext context) {
    final controller = _resolvedController;

    return ThemeControllerScope(
      controller: controller,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return MaterialApp(
            title: 'Nucleus',
            debugShowCheckedModeBanner: false,

            // Themes
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: controller.mode, // live toggle

            // Routes
            initialRoute: '/welcome',
            routes: {
              '/welcome': (_) => const WelcomePage(),
              '/': (_) => const AuthGate(),
              '/home': (_) => const HomePage(),
              '/settings': (_) => const SettingsPage(),
              '/profile': (_) => const ProfilePage(),
              '/login': (_) => const LoginPage(),
              '/forgot': (_) => const ForgotPasswordPage(),
            },

            // Routes that need arguments
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/product': {
                  final arg = settings.arguments;
                  final String? productId = arg is String
                      ? arg
                      : (arg is Map ? arg['productId'] as String? : null);
                  if (productId == null) {
                    return MaterialPageRoute(
                      builder: (_) => const Scaffold(
                        body: Center(child: Text('Missing productId')),
                      ),
                      settings: settings,
                    );
                  }
                  return MaterialPageRoute(
                    builder: (_) => ProductDetailPage(productId: productId),
                    settings: settings,
                  );
                }
                case '/product/edit': {
                  final arg = settings.arguments;
                  final String? productId = arg is String
                      ? arg
                      : (arg is Map ? arg['productId'] as String? : null);
                  return MaterialPageRoute(
                    builder: (_) => ProductEditPage(productId: productId),
                    settings: settings,
                  );
                }
              }
              return null;
            },
          );
        },
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.data != null) {
          return const HomePage();
        }
        return const LoginPage();
      },
    );
  }
}
