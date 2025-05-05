import 'package:weibao/models/user_model.dart';

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? uid;
  final String? phoneNumber;
  final UserModel? userModel;
  final String? error;
  
  AuthState({
    required this.isLoading,
    required this.isAuthenticated,
    this.uid,
    this.phoneNumber,
    this.userModel,
    this.error,
  });
  
  // Initial state factory
  factory AuthState.initial() => AuthState(
    isLoading: false,
    isAuthenticated: false,
  );
  
  // Copy with method for immutability
  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? uid,
    String? phoneNumber,
    UserModel? userModel,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      uid: uid ?? this.uid,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userModel: userModel ?? this.userModel,
      error: error ?? this.error,
    );
  }
  
  @override
  String toString() {
    return 'AuthState(isLoading: $isLoading, isAuthenticated: $isAuthenticated, uid: $uid, phoneNumber: $phoneNumber, userModel: ${userModel?.name}, error: $error)';
  }
}