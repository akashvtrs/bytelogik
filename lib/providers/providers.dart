import 'package:bytelogik/services/counterservice.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart'; 
import '../state/auth_notifier.dart';
import '../state/counter_notifier.dart';
import '../state/auth_state.dart';

final authServiceProvider = Provider((ref) => AuthService());
final counterServiceProvider = Provider((ref) => CounterService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(authServiceProvider)),
);

final counterProvider = StateNotifierProvider.family<CounterNotifier, int, String>(
  (ref, userId) => CounterNotifier(ref.read(counterServiceProvider), userId),
);
