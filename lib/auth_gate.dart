import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

/// AuthGate listens to Firebase Auth state via a StreamBuilder.
/// - If a user is logged in  →  HomeScreen
/// - If no user              →  LoginScreen
/// - While checking          →  Full-screen loading indicator
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Still connecting to Firebase Auth
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFE62135),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.health_and_safety, color: Colors.white, size: 64),
                  SizedBox(height: 24),
                  CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                  SizedBox(height: 20),
                  Text(
                    'AidGo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // User is signed in
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        }

        // No user — show login
        return const LoginScreen();
      },
    );
  }
}
