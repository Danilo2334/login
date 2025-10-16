import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.child});

  final Widget child;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final SupabaseClient _client;
  Session? _session;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _client = Supabase.instance.client;
    _session = _client.auth.currentSession;
    _authSub = _client.auth.onAuthStateChange.listen((AuthState data) {
      setState(() => _session = data.session);
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null) {
      return const AuthPage();
    }
    return widget.child;
  }
}
