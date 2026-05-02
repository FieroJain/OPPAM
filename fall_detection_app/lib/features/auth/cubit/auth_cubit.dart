import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final String? role;
  final String? userId;

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.role,
    this.userId,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    String? role,
    String? userId,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      role: role ?? this.role,
      userId: userId ?? this.userId,
    );
  }

  bool get isPatient => role == 'Patient';
  bool get isCaregiver => role != 'Patient';
}

class AuthCubit extends Cubit<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  AuthCubit() : super(const AuthState()) {
    // Auto-login if already signed in
    final user = _auth.currentUser;
    if (user != null) {
      _loadRoleAndEmit(user.uid);
    }
  }

  Future<void> _loadRoleAndEmit(String uid) async {
    try {
      final snapshot = await _db.child('users/$uid/role').get();
      final role = snapshot.exists ? snapshot.value.toString() : 'Caregiver';
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        role: role,
        userId: uid,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        role: 'Caregiver',
        userId: uid,
      ));
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _loadRoleAndEmit(credential.user!.uid);
    } on FirebaseAuthException catch (e) {
      String msg = 'Login failed';
      if (e.code == 'user-not-found') msg = 'No account found for this email';
      if (e.code == 'wrong-password') msg = 'Wrong password';
      if (e.code == 'invalid-email') msg = 'Invalid email address';
      if (e.code == 'invalid-credential') msg = 'Invalid email or password';
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: msg,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String role,
  }) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user!.uid;
      await _db.child('users/$uid').set({
        'email': email.trim(),
        'role': role,
        'createdAt': DateTime.now().toIso8601String(),
      });
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        role: role,
        userId: uid,
      ));
    } on FirebaseAuthException catch (e) {
      String msg = 'Sign up failed';
      if (e.code == 'weak-password') msg = 'Password must be at least 6 characters';
      if (e.code == 'email-already-in-use') msg = 'Account already exists for this email';
      if (e.code == 'invalid-email') msg = 'Invalid email address';
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: msg,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  void skipAuth() {
    emit(state.copyWith(
      status: AuthStatus.authenticated,
      role: 'Caregiver',
    ));
  }
}