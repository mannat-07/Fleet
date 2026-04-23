import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _db   = FirebaseFirestore.instance;

  static User? get currentUser       => _auth.currentUser;
  static Stream<User?> get authState => _auth.authStateChanges();

  // ── Sign up ─────────────────────────────────────────────────────────────────
  static Future<UserProfile> signUp({
    required String name,
    required String email,
    required String password,
    String company = '',
    String phone   = '',
    String role    = 'owner',
  }) async {
    // Auth — 15 s hard timeout so it never hangs forever
    final cred = await _auth
        .createUserWithEmailAndPassword(
          email:    email.trim(),
          password: password,
        )
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw FirebaseAuthException(
            code:    'network-request-failed',
            message: 'Request timed out. Check your connection.',
          ),
        );

    // Best-effort display name update — don't let it block
    try { await cred.user!.updateDisplayName(name.trim()); } catch (_) {}

    // Map role to display label
    final roleLabel = role == 'driver'
        ? 'Driver'
        : role == 'organization'
            ? 'Organization'
            : 'Fleet Owner';

    final profile = UserProfile(
      uid:            cred.user!.uid,
      name:           name.trim(),
      email:          email.trim().toLowerCase(),
      phone:          phone,
      company:        company,
      role:           roleLabel,
      avatarInitials: AppStore.initials(name),
    );

    // Best-effort Firestore write — don't let it block or crash auth
    _writeProfileToFirestore(profile, firestoreRole: role);

    AppStore.profile = profile;
    return profile;
  }

  // ── Sign in ─────────────────────────────────────────────────────────────────
  static Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth
        .signInWithEmailAndPassword(
          email:    email.trim(),
          password: password,
        )
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw FirebaseAuthException(
            code:    'network-request-failed',
            message: 'Request timed out. Check your connection.',
          ),
        );

    // Build profile from Auth first (instant, no network needed)
    UserProfile profile = _profileFromAuthUser(cred.user!, email);

    // Try to load role from Firestore — await so routing gets the correct role
    try {
      final firestoreProfile = await _loadProfileFromFirestore(cred.user!.uid, email)
          .timeout(const Duration(seconds: 8));
      if (firestoreProfile != null) {
        profile = firestoreProfile;
      }
    } catch (_) {
      // Fall back to default 'Fleet Owner' role if Firestore is unreachable
    }

    AppStore.profile = profile;
    return profile;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  static Future<UserProfile?> _loadProfileFromFirestore(
      String uid, String email) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      final d = doc.data()!;
      final rawRole = d['role'] as String? ?? 'owner';
      // Map stored role key to display label
      final roleLabel = rawRole == 'driver'
          ? 'Driver'
          : rawRole == 'organization'
              ? 'Organization'
              : 'Fleet Owner';
      return UserProfile(
        uid:            d['uid']            as String? ?? uid,
        name:           d['name']           as String? ?? email.split('@').first,
        email:          d['email']          as String? ?? email,
        phone:          d['phone']          as String? ?? '',
        company:        d['company']        as String? ?? '',
        role:           roleLabel,
        avatarInitials: d['avatarInitials'] as String? ?? AppStore.initials(d['name'] as String? ?? email),
      );
    } catch (_) {
      return null;
    }
  }

  static void _writeProfileToFirestore(UserProfile p, {String firestoreRole = 'owner'}) {
    _db.collection('users').doc(p.uid).set({
      'uid':            p.uid,
      'name':           p.name,
      'email':          p.email,
      'phone':          p.phone,
      'company':        p.company,
      'role':           firestoreRole,
      'avatarInitials': p.avatarInitials,
      'createdAt':      FieldValue.serverTimestamp(),
    }).catchError((_) {}); // fire-and-forget
  }

  static UserProfile _profileFromAuthUser(User user, String email) {
    final displayName = user.displayName ?? email.split('@').first;
    return UserProfile(
      uid:            user.uid,
      name:           displayName,
      email:          email.trim().toLowerCase(),
      phone:          '',
      company:        '',
      role:           'Fleet Owner',
      avatarInitials: AppStore.initials(displayName),
    );
  }

  // ── Sign out ────────────────────────────────────────────────────────────────
  static Future<void> signOut() => _auth.signOut();

  // ── Password reset ──────────────────────────────────────────────────────────
  static Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  // ── Error mapping ────────────────────────────────────────────────────────────
  static String friendlyError(dynamic e) {
    // Handle both FirebaseAuthException and generic errors
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
        case 'INVALID_LOGIN_CREDENTIALS':
          return 'Invalid email or password.';
        case 'email-already-in-use':
          return 'An account with this email already exists.';
        case 'weak-password':
          return 'Password must be at least 6 characters.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'network-request-failed':
          return e.message ?? 'Network error. Check your connection.';
        case 'operation-not-allowed':
          return 'Email/password sign-in is not enabled in Firebase Console.';
        default:
          return e.message ?? 'Authentication failed (${e.code}).';
      }
    }
    // Timeout or other
    final msg = e.toString();
    if (msg.contains('timed out') || msg.contains('TimeoutException')) {
      return 'Request timed out. Check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
