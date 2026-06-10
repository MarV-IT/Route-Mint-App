import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/auth/auth_service.dart';
import '../../core/localization/app_strings.dart';
import 'auth_screen.dart';

/// Routes to [child] when the user is authenticated or has chosen guest mode.
/// Routes to [AuthScreen] otherwise.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.strings, required this.child});

  final AppStrings strings;
  final Widget child;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _authService = AuthService();
  bool _guestMode = false;
  bool _isRestoringSession = true;
  bool _sessionExpected = false;
  Timer? _sessionRestorePoller;
  StreamSubscription? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = _authService.authStateChanges().listen((user) {
      if (user != null) _authService.markSessionExpected();
      if (mounted) setState(() {});
    });
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    _sessionExpected =
        await _authService.isSessionExpected() ||
        _authService.currentUser != null;
    await _authService.restoredUser();
    if (!mounted) return;
    if (_authService.currentUser != null) {
      await _authService.markSessionExpected();
    }
    setState(() => _isRestoringSession = false);
    _startSessionRestorePoller();
  }

  void _startSessionRestorePoller() {
    _sessionRestorePoller?.cancel();
    if (!_sessionExpected || _authService.currentUser != null) return;

    _sessionRestorePoller = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_guestMode || _authService.currentUser != null) {
        _sessionRestorePoller?.cancel();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _sessionRestorePoller?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_guestMode) return widget.child;

    if (_authService.currentUser != null) {
      _sessionRestorePoller?.cancel();
      return widget.child;
    }

    if (_isRestoringSession) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder(
      stream: _authService.authStateChanges(),
      initialData: _authService.currentUser,
      builder: (context, snapshot) {
        if (snapshot.data != null) {
          _authService.markSessionExpected();
          return widget.child;
        }
        return AuthScreen(
          strings: widget.strings,
          onAuthenticated: () => setState(() {}),
          onContinueAsGuest: () => setState(() => _guestMode = true),
        );
      },
    );
  }
}
