import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/home/home_screen.dart';
import 'features/savings/screens/add_savings_screen.dart';
import 'features/savings/screens/manage_savings_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BAGASSPACXE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const _SplashRouter(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/home': (_) => const HomeScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/add-savings') {
          final userId = settings.arguments as int?;
          if (userId != null) {
            return MaterialPageRoute(
              builder: (_) => AddSavingsScreen(userId: userId),
            );
          }
        }
        if (settings.name == '/manage') {
          final savingsId = settings.arguments as int?;
          if (savingsId != null) {
            return MaterialPageRoute(
              builder: (_) => ManageSavingsScreen(savingsId: savingsId),
            );
          }
        }
        return null;
      },
    );
  }
}

class _SplashRouter extends StatefulWidget {
  const _SplashRouter();

  @override
  State<_SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<_SplashRouter> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final user = await AuthRepository().getCurrentUser();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, user != null ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
