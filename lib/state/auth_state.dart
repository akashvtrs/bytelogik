import '../models/user.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null;

  AuthState copyWith({User? user, bool? isLoading, String? error}) =>
      AuthState(user: user ?? this.user, isLoading: isLoading ?? this.isLoading, error: error);
}
