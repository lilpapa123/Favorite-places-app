import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Firebase Auth instance. Override this in tests with a fake.
final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

/// The signed-in user, or null when signed out. Uses userChanges() (not
/// authStateChanges()) so profile edits like a new name also show up live.
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(firebaseAuthProvider).userChanges(),
);
