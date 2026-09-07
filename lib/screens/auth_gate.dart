import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sifir_atik/screens/home_page.dart';
import 'package:sifir_atik/screens/login_page.dart';
import 'package:sifir_atik/services/session_preferences.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _sessionPreferences = const SessionPreferences();

  late final Future<bool> _rememberMeFuture = _prepareSession();

  Future<bool> _prepareSession() async {
    if (Firebase.apps.isEmpty) return false;

    final rememberMe = await _sessionPreferences.getRememberMe();
    if (!rememberMe && FirebaseAuth.instance.currentUser != null) {
      await FirebaseAuth.instance.signOut();
    }

    return rememberMe;
  }

  @override
  Widget build(BuildContext context) {
    if (Firebase.apps.isEmpty) {
      return const LoginPage();
    }

    return FutureBuilder<bool>(
      future: _rememberMeFuture,
      builder: (context, rememberSnapshot) {
        if (rememberSnapshot.connectionState != ConnectionState.done) {
          return const _AuthLoadingView();
        }

        final rememberMe = rememberSnapshot.data ?? false;
        if (!rememberMe) {
          return const LoginPage();
        }

        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, authSnapshot) {
            if (authSnapshot.connectionState == ConnectionState.waiting) {
              return const _AuthLoadingView();
            }

            return authSnapshot.data == null
                ? const LoginPage()
                : const HomePage();
          },
        );
      },
    );
  }
}

class _AuthLoadingView extends StatelessWidget {
  const _AuthLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
