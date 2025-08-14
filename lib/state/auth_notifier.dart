import 'package:bytelogik/services/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; 
import 'auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _service;

  AuthNotifier(this._service) : super(AuthState());

  Future<void> signUp(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _service.signUp(email, password);
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _service.signIn(email, password);
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void signOut() => state = AuthState();
}
