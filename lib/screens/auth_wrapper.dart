import 'package:bytelogik/screens/authscreen.dart';
import 'package:bytelogik/screens/counterscreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart'; 

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    return auth.isAuthenticated
        ? CounterScreen(user: auth.user!)
        : const AuthScreen();
  }
}
