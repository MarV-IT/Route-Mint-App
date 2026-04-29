import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/auth/auth_service.dart';
import '../../core/localization/app_strings.dart';
import 'auth_screen.dart';

/// Routes to [child] when the user is authenticated or has chosen guest mode.
/// Routes to [AuthScreen] otherwise.
class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.strings,
    required this.child,
  });

  final AppStrings strings;
  final Widget child;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _guestMode = false;

  @override
  Widget build(BuildContext context) {
    if (_guestMode) return widget.child;

    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data != null) return widget.child;
        return AuthScreen(
          strings: widget.strings,
          onContinueAsGuest: () => setState(() => _guestMode = true),
        );
      },
    );
  }
}
