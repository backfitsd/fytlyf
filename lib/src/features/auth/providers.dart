import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/auth_service.dart';
import 'data/username_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final usernameServiceProvider = Provider<UsernameService>((ref) => UsernameService());

final authStateChangesProvider = StreamProvider<User?>((ref) => ref.watch(authServiceProvider).authStateChanges());
final authLoadingProvider = StateProvider<bool>((ref) => false);
final authErrorProvider = StateProvider<String?>((ref) => null);
